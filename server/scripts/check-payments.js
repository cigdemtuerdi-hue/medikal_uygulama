/**
 * Smoke test for sale checkout / hold fallback (no Stripe key required).
 *
 * Usage:
 *   USE_MEMORY_DB=true npm start   # other terminal
 *   npm run check:payments
 */

const BASE = process.env.API_BASE || 'http://127.0.0.1:3001';

let failures = 0;

function check(label, condition, detail) {
  if (condition) {
    console.log(`  ok   ${label}`);
  } else {
    failures += 1;
    console.log(`  FAIL ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

async function call(method, path, { token, body, raw } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      ...(raw ? { 'Content-Type': 'application/json' } : { 'Content-Type': 'application/json' }),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body !== undefined
      ? { body: typeof body === 'string' ? body : JSON.stringify(body) }
      : {}),
  });
  let json = null;
  const text = await res.text();
  try {
    json = JSON.parse(text);
  } catch (_) {
    json = null;
  }
  return { status: res.status, json, text };
}

async function signUp(email, role) {
  const res = await call('POST', '/api/auth/register', {
    body: {
      email,
      password: 'MedGiftTest1!',
      role,
      hipaaConsentAccepted: true,
      hipaaConsentVersion: 'hipaa-npp-2026.07',
    },
  });
  return res.json?.token;
}

async function main() {
  console.log(`Testing ${BASE}`);

  const health = await call('GET', '/api/health');
  check('health ok', health.status === 200 && health.json?.ok === true);
  const stripeOn = Boolean(health.json?.payments?.stripeConfigured);
  console.log(`  info stripeConfigured=${stripeOn}`);

  const sellerToken = await signUp(`seller.pay.${Date.now()}@example.com`, 'donor');
  const buyerToken = await signUp(`buyer.pay.${Date.now()}@example.com`, 'recipient');
  check('seller signed up', Boolean(sellerToken));
  check('buyer signed up', Boolean(buyerToken));

  const photoRes = await fetch(`${BASE}/api/uploads`, {
    method: 'POST',
    headers: {
      'Content-Type': 'image/jpeg',
      Authorization: `Bearer ${sellerToken}`,
    },
    body: Buffer.concat([
      Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]),
      Buffer.from('JFIF\0'),
      Buffer.alloc(64, 0x20),
      Buffer.from([0xff, 0xd9]),
    ]),
  });
  const photoJson = await photoRes.json().catch(() => null);
  const sellerPhoto = photoJson?.url || null;
  check('seller uploaded a photo', Boolean(sellerPhoto), sellerPhoto);

  const created = await call('POST', '/api/listings', {
    token: sellerToken,
    body: {
      kind: 'sale',
      title: 'Test walker for checkout',
      category: 'walker',
      condition: 'good',
      priceCents: 12500,
      city: 'Austin',
      state: 'TX',
      postalCode: '78701',
      description: 'Smoke-test sale listing',
      photos: [sellerPhoto],
    },
  });
  check('sale listing created', created.status === 201, `got ${created.status}`);
  const listingId = created.json?.listing?.id;
  check('listing id present', Boolean(listingId), listingId);

  console.log('\ncheckout');
  const checkout = await call('POST', `/api/listings/${listingId}/checkout`, {
    token: buyerToken,
  });

  if (stripeOn) {
    check(
      'checkout creates a session',
      checkout.status === 201 && Boolean(checkout.json?.checkoutUrl),
      `got ${checkout.status} ${checkout.json?.code || ''}`,
    );
  } else {
    check(
      'checkout reports STRIPE_NOT_CONFIGURED',
      checkout.status === 503 && checkout.json?.code === 'STRIPE_NOT_CONFIGURED',
      `got ${checkout.status} ${checkout.json?.code}`,
    );

    console.log('\nhold fallback');
    const purchase = await call('POST', `/api/listings/${listingId}/purchase`, {
      token: buyerToken,
    });
    check('purchase hold succeeds', purchase.status === 200, `got ${purchase.status}`);
    check(
      'listing becomes reserved',
      purchase.json?.listing?.status === 'reserved',
      purchase.json?.listing?.status,
    );
  }

  console.log('\nwebhook');
  const webhook = await call('POST', '/api/payments/webhook', {
    body: JSON.stringify({
      type: 'checkout.session.completed',
      data: { object: { id: 'cs_test_smoke', metadata: {} } },
    }),
  });
  if (stripeOn) {
    check(
      'webhook accepts or rejects with Stripe configured',
      webhook.status === 200 || webhook.status === 400,
      `got ${webhook.status}`,
    );
  } else {
    check(
      'webhook unavailable without Stripe',
      webhook.status === 503,
      `got ${webhook.status}`,
    );
  }

  console.log(
    failures === 0
      ? '\nAll payment checks passed.'
      : `\n${failures} check(s) failed.`,
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Smoke test crashed:', err);
  process.exit(1);
});
