const {
  findListingById,
  updateListing,
} = require('../models/listingStore');
const {
  createOrder,
  findOrderById,
  findOrderBySessionId,
  findOrdersBySessionId,
  findOrderByPaypalOrderId,
  findOrdersByPaypalOrderId,
  findOrdersByCartCheckoutId,
  updateOrder,
} = require('../models/orderStore');
const { COMMISSION_RATE } = require('./listingController');
const {
  isStripeConfigured,
  getStripe,
  appOrigin,
} = require('../services/stripeService');
const paypal = require('../services/paypalService');
const crypto = require('crypto');

const RESERVATION_WINDOW_MS = 48 * 60 * 60 * 1000;

function toOrderJson(row) {
  if (!row) return null;
  return {
    id: row.id,
    listingId: row.listingId,
    title: row.title,
    priceCents: row.priceCents,
    commissionRate: row.commissionRate,
    commissionCents: row.commissionCents,
    sellerNetCents: row.sellerNetCents,
    currency: row.currency || 'USD',
    status: row.status,
    paymentProvider: row.paymentProvider || null,
    cartCheckoutId: row.cartCheckoutId || null,
    paidAt: row.paidAt || null,
    createdAt: row.createdAt,
  };
}

async function validateSaleListingForBuyer(listing, userId, res) {
  if (!listing || listing.hidden || listing.kind !== 'sale') {
    res.status(404).json({
      success: false,
      message: 'Satış ilanı bulunamadı.',
      code: 'LISTING_NOT_FOUND',
    });
    return null;
  }
  if (listing.ownerUserId === userId) {
    res.status(400).json({
      success: false,
      message: 'Kendi satış ilanınızı satın alamazsınız.',
      code: 'SELF_PURCHASE',
    });
    return null;
  }
  if (listing.status !== 'active') {
    res.status(409).json({
      success: false,
      message: 'Bu ürün şu anda satışa açık değil.',
      code: 'NOT_AVAILABLE',
    });
    return null;
  }

  const priceCents = Math.round(Number(listing.priceCents));
  if (!Number.isFinite(priceCents) || priceCents < 100) {
    res.status(400).json({
      success: false,
      message: 'İlanda geçerli bir fiyat yok.',
      code: 'PRICE_INVALID',
    });
    return null;
  }

  return { listing, priceCents };
}

async function loadSaleListingForCheckout(req, res) {
  const listing = await findListingById(req.params.id);
  return validateSaleListingForBuyer(listing, req.user.userId, res);
}

function resolveProvider(req) {
  const raw =
    typeof req.body?.provider === 'string'
      ? req.body.provider.trim().toLowerCase()
      : typeof req.query?.provider === 'string'
        ? req.query.provider.trim().toLowerCase()
        : '';
  if (raw === 'paypal' || raw === 'stripe') return raw;
  // Prefer Stripe when both configured (existing clients); else PayPal.
  if (isStripeConfigured()) return 'stripe';
  if (paypal.isPayPalConfigured()) return 'paypal';
  return null;
}

/**
 * POST /api/listings/:id/checkout
 * Body: { provider?: 'stripe' | 'paypal' }
 */
async function createCheckout(req, res, next) {
  try {
    const provider = resolveProvider(req);
    if (!provider) {
      return res.status(503).json({
        success: false,
        message:
          'Online ödeme henüz yapılandırılmadı. Satın alma talebi ile devam edebilirsiniz.',
        code: 'PAYMENT_NOT_CONFIGURED',
      });
    }

    if (provider === 'stripe' && !isStripeConfigured()) {
      return res.status(503).json({
        success: false,
        message:
          'Stripe henüz yapılandırılmadı. PayPal ile deneyebilir veya satın alma talebi gönderebilirsiniz.',
        code: 'STRIPE_NOT_CONFIGURED',
      });
    }

    if (provider === 'paypal' && !paypal.isPayPalConfigured()) {
      return res.status(503).json({
        success: false,
        message:
          'PayPal henüz yapılandırılmadı. Stripe ile deneyebilir veya satın alma talebi gönderebilirsiniz.',
        code: 'PAYPAL_NOT_CONFIGURED',
      });
    }

    const loaded = await loadSaleListingForCheckout(req, res);
    if (!loaded) return;

    const { listing, priceCents } = loaded;
    const rate =
      typeof listing.commissionRate === 'number'
        ? listing.commissionRate
        : COMMISSION_RATE;
    const commissionCents = Math.round(priceCents * rate);
    const sellerNetCents = priceCents - commissionCents;

    const order = await createOrder({
      listingId: listing.id,
      buyerUserId: req.user.userId,
      buyerEmail: req.user.email,
      sellerUserId: listing.ownerUserId,
      sellerEmail: listing.ownerEmail,
      title: listing.title,
      priceCents,
      commissionRate: rate,
      commissionCents,
      sellerNetCents,
      currency: listing.currency || 'USD',
      status: 'pending',
      paymentProvider: provider,
    });

    if (provider === 'paypal') {
      return createPayPalCheckout({
        req,
        res,
        order,
        listing,
        priceCents,
      });
    }

    return createStripeCheckout({
      req,
      res,
      order,
      listing,
      priceCents,
      rate,
      commissionCents,
      sellerNetCents,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/orders/cart/checkout
 * Body: { listingIds: string[], provider?: 'stripe' | 'paypal' }
 */
async function createCartCheckout(req, res, next) {
  try {
    const provider = resolveProvider(req);
    if (!provider) {
      return res.status(503).json({
        success: false,
        message:
          'Online ödeme henüz yapılandırılmadı. Satın alma talebi ile devam edebilirsiniz.',
        code: 'PAYMENT_NOT_CONFIGURED',
      });
    }

    if (provider === 'stripe' && !isStripeConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'Stripe henüz yapılandırılmadı.',
        code: 'STRIPE_NOT_CONFIGURED',
      });
    }

    if (provider === 'paypal' && !paypal.isPayPalConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'PayPal henüz yapılandırılmadı.',
        code: 'PAYPAL_NOT_CONFIGURED',
      });
    }

    const rawIds = Array.isArray(req.body?.listingIds)
      ? req.body.listingIds
      : [];
    const listingIds = [
      ...new Set(
        rawIds
          .map((id) => String(id || '').trim())
          .filter((id) => id.length > 0),
      ),
    ];

    if (listingIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Sepet boş.',
        code: 'CART_EMPTY',
      });
    }
    if (listingIds.length > 10) {
      return res.status(400).json({
        success: false,
        message: 'Sepette en fazla 10 ürün olabilir.',
        code: 'CART_TOO_LARGE',
      });
    }

    const loaded = [];
    for (const listingId of listingIds) {
      const listing = await findListingById(listingId);
      const validated = await validateSaleListingForBuyer(
        listing,
        req.user.userId,
        res,
      );
      if (!validated) return;
      loaded.push(validated);
    }

    const cartCheckoutId = crypto.randomBytes(12).toString('hex');
    const orders = [];

    for (const { listing, priceCents } of loaded) {
      const rate =
        typeof listing.commissionRate === 'number'
          ? listing.commissionRate
          : COMMISSION_RATE;
      const commissionCents = Math.round(priceCents * rate);
      const sellerNetCents = priceCents - commissionCents;
      const order = await createOrder({
        listingId: listing.id,
        buyerUserId: req.user.userId,
        buyerEmail: req.user.email,
        sellerUserId: listing.ownerUserId,
        sellerEmail: listing.ownerEmail,
        title: listing.title,
        priceCents,
        commissionRate: rate,
        commissionCents,
        sellerNetCents,
        currency: listing.currency || 'USD',
        status: 'pending',
        paymentProvider: provider,
        cartCheckoutId,
      });
      orders.push({ order, listing, priceCents, rate, commissionCents, sellerNetCents });
    }

    if (provider === 'paypal') {
      return createPayPalCartCheckout({ req, res, cartCheckoutId, orders });
    }

    return createStripeCartCheckout({ req, res, cartCheckoutId, orders });
  } catch (err) {
    return next(err);
  }
}

async function createStripeCartCheckout({ req, res, cartCheckoutId, orders }) {
  const stripe = getStripe();
  const origin = appOrigin();
  const first = orders[0];
  const orderIds = orders.map((row) => row.order.id).join(',');

  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    customer_email: req.user.email,
    line_items: orders.map(({ listing, priceCents, rate }) => ({
      quantity: 1,
      price_data: {
        currency: (listing.currency || 'usd').toLowerCase(),
        unit_amount: priceCents,
        product_data: {
          name: listing.title.slice(0, 120),
          description: `MedGift marketplace · ${rate * 100}% platform fee included in settlement`,
        },
      },
    })),
    metadata: {
      cartCheckoutId,
      orderId: first.order.id,
      orderIds: orderIds.slice(0, 500),
      buyerUserId: req.user.userId,
      itemCount: String(orders.length),
    },
    success_url: `${origin}/shop/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origin}/shop/cancel?cart_id=${encodeURIComponent(cartCheckoutId)}`,
  });

  for (const { order, listing } of orders) {
    await updateOrder(order.id, {
      stripeCheckoutSessionId: session.id,
      paymentProvider: 'stripe',
    });
    await updateListing(listing.id, {
      status: 'reserved',
      reservedByUserId: req.user.userId,
      reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
    });
  }

  return res.status(201).json({
    success: true,
    provider: 'stripe',
    checkoutUrl: session.url,
    cartCheckoutId,
    orders: orders.map(({ order }) =>
      toOrderJson({
        ...order,
        paymentProvider: 'stripe',
        stripeCheckoutSessionId: session.id,
        cartCheckoutId,
      }),
    ),
  });
}

async function createPayPalCartCheckout({ req, res, cartCheckoutId, orders }) {
  try {
    const created = await paypal.createCheckoutOrder({
      orderId: cartCheckoutId,
      listingId: orders.map((row) => row.listing.id).join(','),
      title:
        orders.length === 1
          ? orders[0].listing.title
          : `MedGift cart (${orders.length} items)`,
      priceCents: orders.reduce((sum, row) => sum + row.priceCents, 0),
      currency: orders[0].listing.currency || 'USD',
      buyerEmail: req.user.email,
      items: orders.map(({ listing, priceCents }) => ({
        name: listing.title,
        priceCents,
        quantity: 1,
      })),
      cancelOrderId: orders[0].order.id,
    });

    for (const { order, listing } of orders) {
      await updateOrder(order.id, {
        paypalOrderId: created.paypalOrderId,
        paymentProvider: 'paypal',
      });
      await updateListing(listing.id, {
        status: 'reserved',
        reservedByUserId: req.user.userId,
        reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
      });
    }

    return res.status(201).json({
      success: true,
      provider: 'paypal',
      checkoutUrl: created.checkoutUrl,
      paypalOrderId: created.paypalOrderId,
      merchantEmail: created.merchantEmail,
      cartCheckoutId,
      orders: orders.map(({ order }) =>
        toOrderJson({
          ...order,
          paymentProvider: 'paypal',
          paypalOrderId: created.paypalOrderId,
          cartCheckoutId,
        }),
      ),
    });
  } catch (err) {
    for (const { order } of orders) {
      await updateOrder(order.id, { status: 'canceled' });
    }
    console.error('[paypal] cart checkout failed:', err.message);
    return res.status(err.status || 502).json({
      success: false,
      message: err.message || 'PayPal oturumu açılamadı.',
      code: err.code || 'PAYPAL_CREATE_FAILED',
    });
  }
}

async function createStripeCheckout({
  req,
  res,
  order,
  listing,
  priceCents,
  rate,
  commissionCents,
  sellerNetCents,
}) {
  const stripe = getStripe();
  const origin = appOrigin();
  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    customer_email: req.user.email,
    line_items: [
      {
        quantity: 1,
        price_data: {
          currency: (listing.currency || 'usd').toLowerCase(),
          unit_amount: priceCents,
          product_data: {
            name: listing.title.slice(0, 120),
            description: `MedGift marketplace · ${rate * 100}% platform fee included in settlement`,
          },
        },
      },
    ],
    metadata: {
      orderId: order.id,
      listingId: listing.id,
      buyerUserId: req.user.userId,
      sellerUserId: listing.ownerUserId,
      commissionCents: String(commissionCents),
      sellerNetCents: String(sellerNetCents),
    },
    success_url: `${origin}/shop/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origin}/shop/cancel?order_id=${order.id}`,
  });

  await updateOrder(order.id, {
    stripeCheckoutSessionId: session.id,
    paymentProvider: 'stripe',
  });

  await updateListing(listing.id, {
    status: 'reserved',
    reservedByUserId: req.user.userId,
    reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
  });

  return res.status(201).json({
    success: true,
    provider: 'stripe',
    checkoutUrl: session.url,
    order: toOrderJson({
      ...order,
      paymentProvider: 'stripe',
      stripeCheckoutSessionId: session.id,
    }),
  });
}

async function createPayPalCheckout({
  req,
  res,
  order,
  listing,
  priceCents,
}) {
  try {
    const created = await paypal.createCheckoutOrder({
      orderId: order.id,
      listingId: listing.id,
      title: listing.title,
      priceCents,
      currency: listing.currency || 'USD',
      buyerEmail: req.user.email,
    });

    await updateOrder(order.id, {
      paypalOrderId: created.paypalOrderId,
      paymentProvider: 'paypal',
    });

    await updateListing(listing.id, {
      status: 'reserved',
      reservedByUserId: req.user.userId,
      reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
    });

    return res.status(201).json({
      success: true,
      provider: 'paypal',
      checkoutUrl: created.checkoutUrl,
      paypalOrderId: created.paypalOrderId,
      merchantEmail: created.merchantEmail,
      order: toOrderJson({
        ...order,
        paymentProvider: 'paypal',
        paypalOrderId: created.paypalOrderId,
      }),
    });
  } catch (err) {
    await updateOrder(order.id, { status: 'canceled' });
    console.error('[paypal] create checkout failed:', err.message);
    return res.status(err.status || 502).json({
      success: false,
      message: err.message || 'PayPal oturumu açılamadı.',
      code: err.code || 'PAYPAL_CREATE_FAILED',
    });
  }
}

/**
 * GET /api/orders/:id — buyer or seller may read their own order.
 */
async function getOrder(req, res, next) {
  try {
    const order = await findOrderById(req.params.id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Sipariş bulunamadı.',
        code: 'ORDER_NOT_FOUND',
      });
    }
    const uid = req.user.userId;
    if (order.buyerUserId !== uid && order.sellerUserId !== uid) {
      return res.status(403).json({
        success: false,
        message: 'Bu siparişe erişemezsiniz.',
        code: 'FORBIDDEN',
      });
    }
    return res.status(200).json({ success: true, order: toOrderJson(order) });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/orders/by-session/:sessionId — Stripe success screen.
 */
async function getOrderBySession(req, res, next) {
  try {
    const order = await findOrderBySessionId(req.params.sessionId);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Sipariş bulunamadı.',
        code: 'ORDER_NOT_FOUND',
      });
    }
    if (order.buyerUserId !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Bu siparişe erişemezsiniz.',
        code: 'FORBIDDEN',
      });
    }
    return res.status(200).json({ success: true, order: toOrderJson(order) });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/payments/paypal/capture
 * Body: { paypalOrderId } — called after PayPal return redirect.
 */
async function capturePayPalOrder(req, res, next) {
  try {
    if (!paypal.isPayPalConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'PayPal yapılandırılmadı.',
        code: 'PAYPAL_NOT_CONFIGURED',
      });
    }

    const paypalOrderId = String(
      req.body?.paypalOrderId || req.body?.token || '',
    ).trim();
    if (!paypalOrderId) {
      return res.status(400).json({
        success: false,
        message: 'PayPal sipariş kimliği gerekli.',
        code: 'PAYPAL_ORDER_REQUIRED',
      });
    }

    let order = await findOrderByPaypalOrderId(paypalOrderId);
    if (!order) {
      // Fallback: read custom_id from PayPal then look up.
      try {
        const remote = await paypal.getOrder(paypalOrderId);
        const customId = paypal.extractCustomOrderId(remote);
        if (customId) order = await findOrderById(customId);
      } catch (_) {
        /* ignore */
      }
    }

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Sipariş bulunamadı.',
        code: 'ORDER_NOT_FOUND',
      });
    }

    if (order.buyerUserId !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Bu siparişe erişemezsiniz.',
        code: 'FORBIDDEN',
      });
    }

    if (order.status === 'paid') {
      return res.status(200).json({
        success: true,
        order: toOrderJson(order),
        alreadyPaid: true,
      });
    }

    const captured = await paypal.captureOrder(paypalOrderId);
    const captureId = paypal.extractCaptureId(captured);
    const status = String(captured.status || '').toUpperCase();
    if (status !== 'COMPLETED' && !captureId) {
      return res.status(409).json({
        success: false,
        message: 'PayPal ödemesi henüz tamamlanmadı.',
        code: 'PAYPAL_NOT_COMPLETED',
        paypalStatus: captured.status,
      });
    }

    const relatedByPaypal = await findOrdersByPaypalOrderId(paypalOrderId);
    const related =
      relatedByPaypal.length > 0
        ? relatedByPaypal
        : order.cartCheckoutId
          ? await findOrdersByCartCheckoutId(order.cartCheckoutId)
          : [order];

    let updated = order;
    for (const row of related) {
      const paid = await markOrderPaid(row, {
        paymentProvider: 'paypal',
        paypalCaptureId: captureId,
      });
      if (row.id === order.id) updated = paid;
    }

    return res.status(200).json({
      success: true,
      order: toOrderJson(updated),
      orders: related.map((row) => toOrderJson(row)),
    });
  } catch (err) {
    console.error('[paypal] capture failed:', err.message);
    return res.status(err.status || 500).json({
      success: false,
      message: err.message || 'PayPal yakalama başarısız.',
      code: err.code || 'PAYPAL_CAPTURE_FAILED',
    });
  }
}

async function markOrderPaid(order, extras = {}) {
  if (!order || order.status === 'paid') return order;

  const patch = {
    status: 'paid',
    paidAt: new Date(),
    ...extras,
  };
  if (extras.stripePaymentIntentId || extras.paymentIntentId) {
    patch.stripePaymentIntentId =
      extras.stripePaymentIntentId || extras.paymentIntentId;
  }

  const updated = await updateOrder(order.id, patch);

  await updateListing(order.listingId, {
    status: 'fulfilled',
    reservedByUserId: order.buyerUserId,
    reservedUntil: null,
  });

  return updated;
}

async function releasePendingOrder(order) {
  if (!order || order.status !== 'pending') return;
  await updateOrder(order.id, { status: 'canceled' });
  const listing = await findListingById(order.listingId);
  if (
    listing &&
    listing.status === 'reserved' &&
    listing.reservedByUserId === order.buyerUserId
  ) {
    await updateListing(listing.id, {
      status: 'active',
      reservedByUserId: null,
      reservedUntil: null,
    });
  }
}

/**
 * POST /api/payments/webhook — Stripe signed events (raw body).
 */
async function stripeWebhook(req, res) {
  if (!isStripeConfigured()) {
    return res.status(503).send('Stripe not configured');
  }

  const stripe = getStripe();
  const secret = (process.env.STRIPE_WEBHOOK_SECRET || '').trim();
  let event;

  try {
    if (secret) {
      const signature = req.headers['stripe-signature'];
      event = stripe.webhooks.constructEvent(req.body, signature, secret);
    } else {
      event =
        typeof req.body === 'string' || Buffer.isBuffer(req.body)
          ? JSON.parse(req.body.toString('utf8'))
          : req.body;
      console.warn(
        '[stripe] STRIPE_WEBHOOK_SECRET unset — accepting unsigned event',
      );
    }
  } catch (err) {
    console.error('[stripe] webhook signature failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const paymentIntentId =
        typeof session.payment_intent === 'string'
          ? session.payment_intent
          : session.payment_intent?.id;

      let orders = session.id
        ? await findOrdersBySessionId(session.id)
        : [];
      if (orders.length === 0 && session.metadata?.cartCheckoutId) {
        orders = await findOrdersByCartCheckoutId(
          session.metadata.cartCheckoutId,
        );
      }
      if (orders.length === 0 && session.metadata?.orderId) {
        const one = await findOrderById(session.metadata.orderId);
        if (one) orders = [one];
      }
      if (orders.length === 0 && session.metadata?.orderIds) {
        const ids = String(session.metadata.orderIds)
          .split(',')
          .map((id) => id.trim())
          .filter(Boolean);
        for (const id of ids) {
          const one = await findOrderById(id);
          if (one) orders.push(one);
        }
      }

      for (const order of orders) {
        await markOrderPaid(order, {
          paymentProvider: 'stripe',
          stripePaymentIntentId: paymentIntentId,
        });
      }
    }

    if (event.type === 'checkout.session.expired') {
      const session = event.data.object;
      let orders = session.id
        ? await findOrdersBySessionId(session.id)
        : [];
      if (orders.length === 0 && session.metadata?.cartCheckoutId) {
        orders = await findOrdersByCartCheckoutId(
          session.metadata.cartCheckoutId,
        );
      }
      if (orders.length === 0 && session.metadata?.orderId) {
        const one = await findOrderById(session.metadata.orderId);
        if (one) orders = [one];
      }
      for (const order of orders) {
        await releasePendingOrder(order);
      }
    }
  } catch (err) {
    console.error('[stripe] webhook handler error:', err.message);
    return res.status(500).json({ success: false });
  }

  return res.status(200).json({ received: true });
}

/**
 * POST /api/payments/paypal/webhook — PayPal webhook events (JSON body).
 */
async function paypalWebhook(req, res) {
  if (!paypal.isPayPalConfigured()) {
    return res.status(503).send('PayPal not configured');
  }

  const webhookId = (process.env.PAYPAL_WEBHOOK_ID || '').trim();
  let event = req.body;
  try {
    if (typeof event === 'string' || Buffer.isBuffer(event)) {
      event = JSON.parse(event.toString('utf8'));
    }

    const verified = await paypal.verifyWebhookSignature({
      headers: req.headers,
      body: event,
      webhookId,
    });
    if (!verified) {
      return res.status(400).send('PayPal webhook signature invalid');
    }
  } catch (err) {
    console.error('[paypal] webhook verify failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    const eventType = event.event_type || event.eventType;
    if (
      eventType === 'PAYMENT.CAPTURE.COMPLETED' ||
      eventType === 'CHECKOUT.ORDER.APPROVED'
    ) {
      const resource = event.resource || {};
      let paypalOrderId =
        resource.supplementary_data?.related_ids?.order_id ||
        resource.id ||
        null;

      // CAPTURE events use capture id as resource.id — custom_id may be on resource.
      const customId =
        resource.custom_id ||
        resource.purchase_units?.[0]?.custom_id ||
        null;

      let order = customId ? await findOrderById(customId) : null;
      let orders = [];
      if (!order && customId) {
        orders = await findOrdersByCartCheckoutId(customId);
        order = orders[0] || null;
      }
      if (!order && paypalOrderId) {
        // For capture events, resource.id is capture id; try related order id.
        if (eventType === 'PAYMENT.CAPTURE.COMPLETED') {
          paypalOrderId =
            resource.supplementary_data?.related_ids?.order_id || null;
        }
        if (paypalOrderId) {
          orders = await findOrdersByPaypalOrderId(paypalOrderId);
          order = orders[0] || null;
        }
      }
      if (orders.length === 0 && order) {
        if (order.cartCheckoutId) {
          orders = await findOrdersByCartCheckoutId(order.cartCheckoutId);
        } else if (order.paypalOrderId) {
          orders = await findOrdersByPaypalOrderId(order.paypalOrderId);
        } else {
          orders = [order];
        }
      }

      if (orders.length > 0) {
        if (eventType === 'CHECKOUT.ORDER.APPROVED' && paypalOrderId) {
          try {
            const captured = await paypal.captureOrder(paypalOrderId);
            const captureId = paypal.extractCaptureId(captured);
            for (const row of orders) {
              if (row.status === 'paid') continue;
              await markOrderPaid(row, {
                paymentProvider: 'paypal',
                paypalCaptureId: captureId || resource.id,
              });
            }
          } catch (capErr) {
            console.error('[paypal] webhook capture:', capErr.message);
          }
        } else {
          for (const row of orders) {
            if (row.status === 'paid') continue;
            await markOrderPaid(row, {
              paymentProvider: 'paypal',
              paypalCaptureId: resource.id || row.paypalCaptureId,
            });
          }
        }
      }
    }
  } catch (err) {
    console.error('[paypal] webhook handler error:', err.message);
    return res.status(500).json({ success: false });
  }

  return res.status(200).json({ received: true });
}

module.exports = {
  createCheckout,
  createCartCheckout,
  getOrder,
  getOrderBySession,
  capturePayPalOrder,
  stripeWebhook,
  paypalWebhook,
  toOrderJson,
  markOrderPaid,
};
