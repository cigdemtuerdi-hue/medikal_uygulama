/**
 * PayPal Orders v2 (Checkout) — payments settle to the Business account that
 * owns PAYPAL_CLIENT_ID / PAYPAL_CLIENT_SECRET (info@medgift.us).
 *
 * Without credentials the API stays up; checkout reports PAYPAL_NOT_CONFIGURED.
 */

const DEFAULT_MERCHANT_EMAIL = 'info@medgift.us';

let cachedToken = null;
let cachedTokenExpiresAt = 0;

function paypalMode() {
  const raw = (process.env.PAYPAL_MODE || 'live').trim().toLowerCase();
  return raw === 'sandbox' ? 'sandbox' : 'live';
}

function paypalBaseUrl() {
  return paypalMode() === 'sandbox'
    ? 'https://api-m.sandbox.paypal.com'
    : 'https://api-m.paypal.com';
}

function paypalClientId() {
  return (process.env.PAYPAL_CLIENT_ID || '').trim();
}

function paypalClientSecret() {
  return (process.env.PAYPAL_CLIENT_SECRET || '').trim();
}

function paypalMerchantEmail() {
  return (
    (process.env.PAYPAL_MERCHANT_EMAIL || '').trim().toLowerCase() ||
    DEFAULT_MERCHANT_EMAIL
  );
}

function isPayPalConfigured() {
  return Boolean(paypalClientId() && paypalClientSecret());
}

function appOrigin() {
  return (process.env.APP_ORIGIN || 'https://medgift.us').replace(/\/$/, '');
}

async function getAccessToken() {
  if (!isPayPalConfigured()) {
    throw Object.assign(new Error('PayPal not configured'), {
      code: 'PAYPAL_NOT_CONFIGURED',
      status: 503,
    });
  }

  const now = Date.now();
  if (cachedToken && now < cachedTokenExpiresAt - 30_000) {
    return cachedToken;
  }

  const auth = Buffer.from(
    `${paypalClientId()}:${paypalClientSecret()}`,
  ).toString('base64');

  const res = await fetch(`${paypalBaseUrl()}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  const json = await res.json().catch(() => ({}));
  if (!res.ok || !json.access_token) {
    const detail = json.error_description || json.error || res.statusText;
    throw Object.assign(new Error(`PayPal OAuth failed: ${detail}`), {
      status: 502,
      code: 'PAYPAL_OAUTH_FAILED',
    });
  }

  cachedToken = json.access_token;
  const expiresIn = Number(json.expires_in) || 300;
  cachedTokenExpiresAt = now + expiresIn * 1000;
  return cachedToken;
}

async function paypalFetch(path, { method = 'GET', body } = {}) {
  const token = await getAccessToken();
  const res = await fetch(`${paypalBaseUrl()}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, ok: res.ok, json };
}

/**
 * Create a PayPal Checkout order and return the buyer approval URL.
 */
async function createCheckoutOrder({
  orderId,
  listingId,
  title,
  priceCents,
  currency = 'USD',
  buyerEmail,
}) {
  const origin = appOrigin();
  const amount = (Number(priceCents) / 100).toFixed(2);
  const merchantEmail = paypalMerchantEmail();

  const purchaseUnit = {
    reference_id: String(orderId).slice(0, 127),
    custom_id: String(orderId).slice(0, 127),
    description: String(title || 'MedGift purchase').slice(0, 127),
    amount: {
      currency_code: String(currency || 'USD').toUpperCase(),
      value: amount,
    },
    payee: {
      email_address: merchantEmail,
    },
  };

  const body = {
    intent: 'CAPTURE',
    purchase_units: [purchaseUnit],
    application_context: {
      brand_name: 'MedGift US',
      landing_page: 'NO_PREFERENCE',
      user_action: 'PAY_NOW',
      shipping_preference: 'NO_SHIPPING',
      // PayPal appends ?token=<ORDER_ID> on return.
      return_url: `${origin}/shop/success?provider=paypal`,
      cancel_url: `${origin}/shop/cancel?order_id=${encodeURIComponent(orderId)}`,
    },
  };

  if (buyerEmail) {
    body.payer = { email_address: String(buyerEmail).slice(0, 254) };
  }

  const { ok, status, json } = await paypalFetch('/v2/checkout/orders', {
    method: 'POST',
    body,
  });

  if (!ok || !json.id) {
    const detail =
      json?.message ||
      json?.details?.[0]?.description ||
      json?.name ||
      `HTTP ${status}`;
    throw Object.assign(new Error(`PayPal create order failed: ${detail}`), {
      status: 502,
      code: 'PAYPAL_CREATE_FAILED',
      paypal: json,
    });
  }

  const approve = (json.links || []).find((l) => l.rel === 'approve');
  if (!approve?.href) {
    throw Object.assign(new Error('PayPal approve link missing'), {
      status: 502,
      code: 'PAYPAL_APPROVE_MISSING',
    });
  }

  return {
    paypalOrderId: json.id,
    checkoutUrl: approve.href,
    merchantEmail,
    status: json.status,
  };
}

async function captureOrder(paypalOrderId) {
  const { ok, status, json } = await paypalFetch(
    `/v2/checkout/orders/${encodeURIComponent(paypalOrderId)}/capture`,
    { method: 'POST', body: {} },
  );

  // ORDER_ALREADY_CAPTURED → treat as success and read details
  if (!ok) {
    const issue = json?.details?.[0]?.issue;
    if (issue === 'ORDER_ALREADY_CAPTURED') {
      return getOrder(paypalOrderId);
    }
    const detail =
      json?.message ||
      json?.details?.[0]?.description ||
      json?.name ||
      `HTTP ${status}`;
    throw Object.assign(new Error(`PayPal capture failed: ${detail}`), {
      status: 502,
      code: 'PAYPAL_CAPTURE_FAILED',
      paypal: json,
    });
  }

  return json;
}

async function getOrder(paypalOrderId) {
  const { ok, status, json } = await paypalFetch(
    `/v2/checkout/orders/${encodeURIComponent(paypalOrderId)}`,
  );
  if (!ok) {
    throw Object.assign(new Error(`PayPal get order failed: HTTP ${status}`), {
      status: 502,
      code: 'PAYPAL_GET_FAILED',
      paypal: json,
    });
  }
  return json;
}

function extractCaptureId(captureResponse) {
  const units = captureResponse?.purchase_units || [];
  for (const unit of units) {
    const captures = unit?.payments?.captures || [];
    if (captures[0]?.id) return captures[0].id;
  }
  return null;
}

function extractCustomOrderId(paypalOrder) {
  const fromUnit = paypalOrder?.purchase_units?.[0]?.custom_id;
  if (fromUnit) return String(fromUnit);
  const fromRef = paypalOrder?.purchase_units?.[0]?.reference_id;
  if (fromRef) return String(fromRef);
  return null;
}

/**
 * Verify webhook signature when PAYPAL_WEBHOOK_ID is set.
 * Without it (local smoke), events are accepted but logged.
 */
async function verifyWebhookSignature({
  headers,
  body,
  webhookId,
}) {
  if (!webhookId) {
    console.warn(
      '[paypal] PAYPAL_WEBHOOK_ID unset — accepting unsigned webhook',
    );
    return true;
  }

  const transmissionId = headers['paypal-transmission-id'];
  const transmissionTime = headers['paypal-transmission-time'];
  const certUrl = headers['paypal-cert-url'];
  const authAlgo = headers['paypal-auth-algo'];
  const transmissionSig = headers['paypal-transmission-sig'];

  if (
    !transmissionId ||
    !transmissionTime ||
    !certUrl ||
    !authAlgo ||
    !transmissionSig
  ) {
    return false;
  }

  const webhookEvent =
    typeof body === 'string' || Buffer.isBuffer(body)
      ? JSON.parse(body.toString('utf8'))
      : body;

  const { ok, json } = await paypalFetch(
    '/v1/notifications/verify-webhook-signature',
    {
      method: 'POST',
      body: {
        auth_algo: authAlgo,
        cert_url: certUrl,
        transmission_id: transmissionId,
        transmission_sig: transmissionSig,
        transmission_time: transmissionTime,
        webhook_id: webhookId,
        webhook_event: webhookEvent,
      },
    },
  );

  return ok && json.verification_status === 'SUCCESS';
}

module.exports = {
  isPayPalConfigured,
  paypalMerchantEmail,
  paypalMode,
  createCheckoutOrder,
  captureOrder,
  getOrder,
  extractCaptureId,
  extractCustomOrderId,
  verifyWebhookSignature,
  appOrigin,
  DEFAULT_MERCHANT_EMAIL,
};
