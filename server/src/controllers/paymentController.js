const {
  findListingById,
  updateListing,
} = require('../models/listingStore');
const {
  createOrder,
  findOrderById,
  findOrderBySessionId,
  updateOrder,
} = require('../models/orderStore');
const { COMMISSION_RATE } = require('./listingController');
const {
  isStripeConfigured,
  getStripe,
  appOrigin,
} = require('../services/stripeService');

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
    paidAt: row.paidAt || null,
    createdAt: row.createdAt,
  };
}

/**
 * POST /api/listings/:id/checkout
 * Creates a Stripe Checkout Session for an active sale listing.
 */
async function createCheckout(req, res, next) {
  try {
    if (!isStripeConfigured()) {
      return res.status(503).json({
        success: false,
        message:
          'Online ödeme henüz yapılandırılmadı. Satın alma talebi ile devam edebilirsiniz.',
        code: 'STRIPE_NOT_CONFIGURED',
      });
    }

    const listing = await findListingById(req.params.id);
    if (!listing || listing.hidden || listing.kind !== 'sale') {
      return res.status(404).json({
        success: false,
        message: 'Satış ilanı bulunamadı.',
        code: 'LISTING_NOT_FOUND',
      });
    }
    if (listing.ownerUserId === req.user.userId) {
      return res.status(400).json({
        success: false,
        message: 'Kendi satış ilanınızı satın alamazsınız.',
        code: 'SELF_PURCHASE',
      });
    }
    if (listing.status !== 'active') {
      return res.status(409).json({
        success: false,
        message: 'Bu ürün şu anda satışa açık değil.',
        code: 'NOT_AVAILABLE',
      });
    }

    const priceCents = Math.round(Number(listing.priceCents));
    if (!Number.isFinite(priceCents) || priceCents < 100) {
      return res.status(400).json({
        success: false,
        message: 'İlanda geçerli bir fiyat yok.',
        code: 'PRICE_INVALID',
      });
    }

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
    });

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
    });

    // Soft-hold so two buyers cannot open parallel checkouts on the same item.
    await updateListing(listing.id, {
      status: 'reserved',
      reservedByUserId: req.user.userId,
      reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
    });

    return res.status(201).json({
      success: true,
      checkoutUrl: session.url,
      order: toOrderJson({ ...order, stripeCheckoutSessionId: session.id }),
    });
  } catch (err) {
    return next(err);
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
 * GET /api/orders/by-session/:sessionId — used by the success screen.
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

async function markOrderPaid(order, paymentIntentId) {
  if (!order || order.status === 'paid') return order;

  const updated = await updateOrder(order.id, {
    status: 'paid',
    stripePaymentIntentId: paymentIntentId || order.stripePaymentIntentId,
    paidAt: new Date(),
  });

  await updateListing(order.listingId, {
    status: 'fulfilled',
    reservedByUserId: order.buyerUserId,
    reservedUntil: null,
  });

  return updated;
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
      // Local smoke tests may skip signature verification.
      event = typeof req.body === 'string' || Buffer.isBuffer(req.body)
        ? JSON.parse(req.body.toString('utf8'))
        : req.body;
      console.warn('[stripe] STRIPE_WEBHOOK_SECRET unset — accepting unsigned event');
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
        await markOrderPaid(
          order,
          typeof session.payment_intent === 'string'
            ? session.payment_intent
            : session.payment_intent?.id,
        );
      }
    }

    if (event.type === 'checkout.session.expired') {
      const session = event.data.object;
      const order =
        (await findOrderBySessionId(session.id)) ||
        (session.metadata?.orderId
          ? await findOrderById(session.metadata.orderId)
          : null);
      if (order && order.status === 'pending') {
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
    }
  } catch (err) {
    console.error('[stripe] webhook handler error:', err.message);
    return res.status(500).json({ success: false });
  }

  return res.status(200).json({ received: true });
}

module.exports = {
  createCheckout,
  getOrder,
  getOrderBySession,
  stripeWebhook,
  toOrderJson,
  markOrderPaid,
};
