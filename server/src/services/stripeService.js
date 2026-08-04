/**
 * Thin Stripe wrapper so controllers stay free of SDK init details.
 *
 * Without a valid STRIPE_SECRET_KEY (`sk_test_` / `sk_live_`) the API stays
 * up and sale listings still work — checkout reports STRIPE_NOT_CONFIGURED
 * so the client can fall back to a hold request.
 *
 * A common misconfig is putting the webhook signing secret (`whsec_…`) into
 * STRIPE_SECRET_KEY; Stripe then rejects checkout with "Invalid API Key".
 */

let stripeClient = null;
let warnedMisconfig = false;

function stripeSecretKey() {
  return (process.env.STRIPE_SECRET_KEY || '').trim();
}

function isValidStripeSecretKey(key) {
  return key.startsWith('sk_test_') || key.startsWith('sk_live_');
}

/**
 * Non-null when STRIPE_SECRET_KEY is set but is not a usable API secret.
 * Safe for logs / health (no raw key).
 */
function stripeSecretMisconfig() {
  const key = stripeSecretKey();
  if (!key) return null;
  if (isValidStripeSecretKey(key)) return null;
  if (key.startsWith('whsec_')) {
    return 'webhook_secret_in_api_key_slot';
  }
  if (key.startsWith('pk_')) {
    return 'publishable_key_in_secret_slot';
  }
  return 'invalid_secret_key_format';
}

function isStripeConfigured() {
  return isValidStripeSecretKey(stripeSecretKey());
}

function getStripe() {
  if (!isStripeConfigured()) {
    const reason = stripeSecretMisconfig();
    if (reason && !warnedMisconfig) {
      warnedMisconfig = true;
      console.error(
        `[stripe] STRIPE_SECRET_KEY is misconfigured (${reason}). ` +
          'Use sk_test_… / sk_live_… from Stripe → Developers → API keys. ' +
          'Put whsec_… only in STRIPE_WEBHOOK_SECRET.',
      );
    }
    return null;
  }
  if (!stripeClient) {
    // Lazy require keeps memory-mode boots cheap when Stripe is unset.
    // eslint-disable-next-line global-require
    const Stripe = require('stripe');
    stripeClient = new Stripe(stripeSecretKey());
  }
  return stripeClient;
}

function appOrigin() {
  return (process.env.APP_ORIGIN || 'https://medgift.us').replace(/\/$/, '');
}

module.exports = {
  isStripeConfigured,
  stripeSecretMisconfig,
  getStripe,
  appOrigin,
};
