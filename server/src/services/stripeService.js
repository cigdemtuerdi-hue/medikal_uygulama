/**
 * Thin Stripe wrapper so controllers stay free of SDK init details.
 *
 * Without STRIPE_SECRET_KEY the API stays up and sale listings still work —
 * checkout simply reports STRIPE_NOT_CONFIGURED so the client can fall back
 * to a hold request.
 */

let stripeClient = null;

function isStripeConfigured() {
  return Boolean((process.env.STRIPE_SECRET_KEY || '').trim());
}

function getStripe() {
  if (!isStripeConfigured()) return null;
  if (!stripeClient) {
    // Lazy require keeps memory-mode boots cheap when Stripe is unset.
    // eslint-disable-next-line global-require
    const Stripe = require('stripe');
    stripeClient = new Stripe(process.env.STRIPE_SECRET_KEY.trim());
  }
  return stripeClient;
}

function appOrigin() {
  return (process.env.APP_ORIGIN || 'https://medgift.us').replace(/\/$/, '');
}

module.exports = {
  isStripeConfigured,
  getStripe,
  appOrigin,
};
