const {
  findListingById,
  updateListing,
} = require('../models/listingStore');
const {
  createOrder,
  findOrderById,
  findOrderBySessionId,
  findOrderByPaypalOrderId,
  updateOrder,
} = require('../models/orderStore');
const { COMMISSION_RATE } = require('./listingController');
const {
  isStripeConfigured,
  getStripe,
  appOrigin,
} = require('../services/stripeService');
const paypal = require('../services/paypalService');

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
    paidAt: row.paidAt || null,
    createdAt: row.createdAt,
  };
}

async function loadSaleListingForCheckout(req, res) {
  const listing = await findListingById(req.params.id);
  if (!listing || listing.hidden || listing.kind !== 'sale') {
    res.status(404).json({
      success: false,
      message: 'Satış ilanı bulunamadı.',
      code: 'LISTING_NOT_FOUND',
    });
    return null;
  }
  if (listing.ownerUserId === req.user.userId) {
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

    const updated = await markOrderPaid(order, {
      paymentProvider: 'paypal',
      paypalCaptureId: captureId,
    });

    return res.status(200).json({
      success: true,
      order: toOrderJson(updated),
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
      const orderId = session.metadata?.orderId;
      let order = orderId ? await findOrderById(orderId) : null;
      if (!order && session.id) {
        order = await findOrderBySessionId(session.id);
      }
      if (order) {
        await markOrderPaid(order, {
          paymentProvider: 'stripe',
          stripePaymentIntentId:
            typeof session.payment_intent === 'string'
              ? session.payment_intent
              : session.payment_intent?.id,
        });
      }
    }

    if (event.type === 'checkout.session.expired') {
      const session = event.data.object;
      const order =
        (await findOrderBySessionId(session.id)) ||
        (session.metadata?.orderId
          ? await findOrderById(session.metadata.orderId)
          : null);
      if (order) await releasePendingOrder(order);
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
      if (!order && paypalOrderId) {
        // For capture events, resource.id is capture id; try related order id.
        if (eventType === 'PAYMENT.CAPTURE.COMPLETED') {
          paypalOrderId =
            resource.supplementary_data?.related_ids?.order_id || null;
        }
        if (paypalOrderId) {
          order = await findOrderByPaypalOrderId(paypalOrderId);
        }
      }

      if (order && order.status !== 'paid') {
        if (eventType === 'CHECKOUT.ORDER.APPROVED' && paypalOrderId) {
          try {
            const captured = await paypal.captureOrder(paypalOrderId);
            const captureId = paypal.extractCaptureId(captured);
            await markOrderPaid(order, {
              paymentProvider: 'paypal',
              paypalCaptureId: captureId || resource.id,
            });
          } catch (capErr) {
            console.error('[paypal] webhook capture:', capErr.message);
          }
        } else {
          await markOrderPaid(order, {
            paymentProvider: 'paypal',
            paypalCaptureId: resource.id || order.paypalCaptureId,
          });
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
  getOrder,
  getOrderBySession,
  capturePayPalOrder,
  stripeWebhook,
  paypalWebhook,
  toOrderJson,
  markOrderPaid,
};
