const mongoose = require('mongoose');

/**
 * A marketplace purchase against a `sale` listing.
 *
 * Money lands on MedGift's Stripe or PayPal account first; `commissionCents`
 * is our take and `sellerNetCents` is what we owe the seller (payouts later).
 */
const orderSchema = new mongoose.Schema(
  {
    listingId: { type: String, required: true, index: true },
    buyerUserId: { type: String, required: true, index: true },
    buyerEmail: { type: String, required: true, lowercase: true, trim: true },
    sellerUserId: { type: String, required: true, index: true },
    sellerEmail: { type: String, required: true, lowercase: true, trim: true },
    title: { type: String, required: true, trim: true, maxlength: 160 },
    priceCents: { type: Number, required: true, min: 100 },
    commissionRate: { type: Number, required: true, default: 0.17 },
    commissionCents: { type: Number, required: true, min: 0 },
    sellerNetCents: { type: Number, required: true, min: 0 },
    currency: { type: String, default: 'USD', uppercase: true },
    /** pending | paid | failed | canceled | refunded */
    status: { type: String, default: 'pending', index: true },
    /** stripe | paypal | null (hold) */
    paymentProvider: { type: String, default: null, index: true },
    stripeCheckoutSessionId: { type: String, default: null, index: true },
    stripePaymentIntentId: { type: String, default: null },
    paypalOrderId: { type: String, default: null, index: true },
    paypalCaptureId: { type: String, default: null },
    paidAt: { type: Date, default: null },
  },
  { timestamps: true },
);

module.exports =
  mongoose.models.Order || mongoose.model('Order', orderSchema);
