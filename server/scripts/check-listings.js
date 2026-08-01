/**
 * End-to-end smoke test for the listing + admin surface against a locally
 * booted server in memory mode.
 *
 * Usage: USE_MEMORY_DB=true ADMIN_PASSWORD=... node scripts/check-listings.js
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
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  let json = null;
  try {
    json = await res.json();
  } catch (_) {
    json = null;
  }
  return { status: res.status, json };
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

  console.log('\nauth');
  const donorToken = await signUp(`donor.${Date.now()}@example.com`, 'donor');
  const recipientToken = await signUp(
    `recipient.${Date.now()}@example.com`,
    'recipient',
  );
  check('register returns a session token for donor', Boolean(donorToken));
  check('register returns a session token for recipient', Boolean(recipientToken));

  console.log('\nlistings require a session');
  const anon = await call('GET', '/api/listings/browse');
  check('browse without token is rejected', anon.status === 401, `got ${anon.status}`);

  const spoofed = await fetch(`${BASE}/api/listings/browse`, {
    headers: { 'X-User-Id': 'someone-else', 'X-User-Role': 'donor' },
  });
  check(
    'spoofed X-User headers are not accepted',
    spoofed.status === 401,
    `got ${spoofed.status}`,
  );

  console.log('\npublishing');
  const offer = await call('POST', '/api/listings', {
    token: donorToken,
    body: {
      title: 'Lightweight folding wheelchair',
      category: 'wheelchair',
      condition: 'good',
      sizeNote: '18 inch seat',
      city: 'Austin',
      state: 'TX',
      postalCode: '78701',
    },
  });
  check('donor can publish an offer', offer.status === 201, `got ${offer.status}`);

  const badKind = await call('POST', '/api/listings', {
    token: donorToken,
    body: { kind: 'request', title: 'Need a bed', category: 'hospitalBed' },
  });
  check(
    'donor cannot publish a request',
    badKind.status === 403,
    `got ${badKind.status}`,
  );

  const request = await call('POST', '/api/listings', {
    token: recipientToken,
    body: {
      title: 'Need a wheelchair for my mother',
      category: 'wheelchair',
      sizeNote: '18 inch seat',
      urgency: 'high',
      city: 'Austin',
      state: 'TX',
      postalCode: '78704',
    },
  });
  check(
    'recipient can publish a request',
    request.status === 201,
    `got ${request.status}`,
  );

  console.log('\nprivacy');
  const browse = await call('GET', '/api/listings/browse', {
    token: donorToken,
  });
  const seen = browse.json?.listings || [];
  check('donor browsing sees requests', browse.json?.kind === 'request');
  check('donor sees the recipient request', seen.length >= 1);
  const sample = seen[0] || {};
  check('no ownerEmail leaked', !('ownerEmail' in sample));
  check('no ownerUserId leaked', !('ownerUserId' in sample));
  check('no exact postalCode leaked', !('postalCode' in sample));
  check('postal prefix is exposed', sample.postalPrefix === '787');
  check('city is exposed', sample.city === 'Austin');

  const ownListings = await call('GET', '/api/listings/browse', {
    token: recipientToken,
  });
  check(
    'recipient browsing sees offers',
    ownListings.json?.kind === 'offer',
  );
  check(
    'own listing is excluded from browse',
    (ownListings.json?.listings || []).every((l) => l.title !== request.json?.listing?.title),
  );

  console.log('\nmatching');
  const offerId = offer.json?.listing?.id;
  const matches = await call('GET', `/api/listings/${offerId}/matches`, {
    token: donorToken,
  });
  const top = matches.json?.matches?.[0];
  check('offer gets at least one match', Boolean(top));
  check(
    'match scores category + size + nearby + urgency',
    top && top.matchScore >= 80,
    top ? `score ${top.matchScore} reasons ${top.matchReasons}` : 'no match',
  );

  const foreignMatches = await call('GET', `/api/listings/${offerId}/matches`, {
    token: recipientToken,
  });
  check(
    'matches on someone else listing are rejected',
    foreignMatches.status === 403,
    `got ${foreignMatches.status}`,
  );

  console.log('\nreservation');
  const reserved = await call('POST', `/api/listings/${offerId}/reserve`, {
    token: recipientToken,
  });
  check('recipient can reserve an offer', reserved.status === 200);
  check('reservation sets a deadline', Boolean(reserved.json?.listing?.reservedUntil));

  const selfReserve = await call('POST', `/api/listings/${offerId}/reserve`, {
    token: donorToken,
  });
  check(
    'owner cannot reserve their own listing',
    selfReserve.status === 400,
    `got ${selfReserve.status}`,
  );

  console.log('\nadmin');
  const adminLogin = await call('POST', '/api/auth/admin-login', {
    body: {
      email: process.env.ADMIN_EMAIL || 'info@medgift.us',
      password: process.env.ADMIN_PASSWORD || '',
    },
  });
  const adminToken = adminLogin.json?.token;
  check('admin can log in', Boolean(adminToken), `status ${adminLogin.status}`);

  if (adminToken) {
    const users = await call('GET', '/api/admin/users', { token: adminToken });
    check('admin lists registered users', (users.json?.users || []).length >= 2);
    check(
      'admin user rows carry role and createdAt',
      users.json?.users?.[0]?.role != null &&
        users.json?.users?.[0]?.createdAt != null,
    );
    check(
      'admin never sees raw phone',
      (users.json?.users || []).every((u) => !('phone' in u)),
    );

    const adminListings = await call('GET', '/api/admin/listings', {
      token: adminToken,
    });
    check(
      'admin lists published listings',
      (adminListings.json?.listings || []).length >= 2,
    );
    check(
      'admin sees the owner email',
      Boolean(adminListings.json?.listings?.[0]?.ownerEmail),
    );

    const summary = await call('GET', '/api/admin/overview', {
      token: adminToken,
    });
    check('overview counts offers and requests', summary.json?.listings?.offers >= 1);
    check('overview counts users by role', summary.json?.users?.byRole?.donor >= 1);
  }

  const unauth = await call('GET', '/api/admin/users');
  check('admin routes reject anonymous callers', unauth.status === 401);

  console.log(`\n${failures === 0 ? 'PASS' : `${failures} FAILURE(S)`}`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
