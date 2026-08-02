/**
 * Smoke test for the paid sales marketplace.
 *
 * Usage:
 *   USE_MEMORY_DB=1 PORT=3099 node src/index.js &
 *   API_BASE=http://127.0.0.1:3099 node scripts/check-sales.js
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

async function call(method, path, { token, body } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = null;
  }
  return { status: res.status, json };
}

async function register(role) {
  const stamp = Date.now() + Math.random().toString(16).slice(2, 6);
  const email = `${role}.${stamp}@example.com`;
  const password = 'TestSalePass1!';
  const res = await call('POST', '/api/auth/register', {
    body: {
      email,
      password,
      role,
      hipaaConsentAccepted: true,
      hipaaConsentVersion: 'hipaa-npp-2026.07',
    },
  });
  return {
    email,
    token: res.json?.token,
    status: res.status,
    json: res.json,
  };
}

async function main() {
  console.log(`Testing ${BASE}\n`);

  console.log('accounts');
  const seller = await register('donor');
  const buyer = await register('recipient');
  check('seller registered', Boolean(seller.token), String(seller.status));
  check('buyer registered', Boolean(buyer.token), String(buyer.status));
  if (!seller.token || !buyer.token) process.exit(1);

  console.log('\ncreate sale');
  const created = await call('POST', '/api/listings', {
    token: seller.token,
    body: {
      kind: 'sale',
      title: 'Used Invacare wheelchair',
      category: 'wheelchair',
      condition: 'good',
      description: 'Clean, working brakes.',
      priceCents: 10000,
      city: 'Austin',
      state: 'TX',
      postalCode: '78701',
    },
  });
  check('sale created', created.status === 201, String(created.status));
  const listing = created.json?.listing;
  check('kind is sale', listing?.kind === 'sale');
  check('price stored', listing?.priceCents === 10000);
  check('commission 17%', listing?.commissionCents === 1700, listing?.commissionCents);
  check('seller net 83%', listing?.sellerNetCents === 8300, listing?.sellerNetCents);

  const noPrice = await call('POST', '/api/listings', {
    token: seller.token,
    body: {
      kind: 'sale',
      title: 'No price',
      category: 'walker',
    },
  });
  check('price required', noPrice.status === 400, String(noPrice.status));

  console.log('\nshop browse');
  const shop = await call('GET', '/api/listings/shop', { token: buyer.token });
  check('shop lists sales', shop.status === 200);
  check(
    'buyer sees the sale',
    (shop.json?.listings || []).some((l) => l.id === listing.id),
  );
  check(
    'buyer cannot see seller email',
    !(shop.json?.listings || []).some((l) => l.ownerEmail),
  );

  const sellerShop = await call('GET', '/api/listings/shop', {
    token: seller.token,
  });
  check(
    'seller does not see own listing in shop',
    !(sellerShop.json?.listings || []).some((l) => l.id === listing.id),
  );

  console.log('\npurchase');
  const bought = await call('POST', `/api/listings/${listing.id}/purchase`, {
    token: buyer.token,
  });
  check('purchase succeeds', bought.status === 200, String(bought.status));
  check('status reserved', bought.json?.listing?.status === 'reserved');

  const selfBuy = await call('POST', `/api/listings/${listing.id}/purchase`, {
    token: seller.token,
  });
  // Already reserved / not found / self — any rejection is fine as long as not 200
  // Create a fresh sale for self-purchase check.
  const own = await call('POST', '/api/listings', {
    token: seller.token,
    body: {
      kind: 'sale',
      title: 'Self buy test',
      category: 'walker',
      priceCents: 5000,
    },
  });
  const self = await call('POST', `/api/listings/${own.json?.listing?.id}/purchase`, {
    token: seller.token,
  });
  check('self purchase rejected', self.status === 400, String(self.status));
  void selfBuy;

  console.log(
    failures === 0
      ? '\nAll sales checks passed.'
      : `\n${failures} sales check(s) failed.`,
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Smoke test crashed:', err);
  process.exit(1);
});
