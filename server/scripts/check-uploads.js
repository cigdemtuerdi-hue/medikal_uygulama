/**
 * End-to-end smoke test for listing photo uploads against a locally booted
 * server in memory mode.
 *
 * Covers the parts that are easy to get wrong and expensive to find in
 * production: auth on the write path, the magic-number check that stops a
 * disguised HTML payload from being served back from our own origin, the
 * five-photo cap, and rejection of photo paths the caller did not upload.
 *
 * Usage: USE_MEMORY_DB=true node scripts/check-uploads.js
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

/** Smallest structurally valid JPEG: SOI, APP0/JFIF, EOI. */
function fakeJpeg(padding = 64) {
  return Buffer.concat([
    Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]),
    Buffer.from('JFIF\0'),
    Buffer.alloc(padding, 0x20),
    Buffer.from([0xff, 0xd9]),
  ]);
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

async function upload(token, buffer, contentType = 'image/jpeg') {
  const res = await fetch(`${BASE}/api/uploads`, {
    method: 'POST',
    headers: {
      'Content-Type': contentType,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: buffer,
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

  const donorToken = await signUp(`donor.up.${Date.now()}@example.com`, 'donor');
  const recipientToken = await signUp(
    `recipient.up.${Date.now()}@example.com`,
    'recipient',
  );

  console.log('\nupload auth');
  const anon = await upload(null, fakeJpeg());
  check('upload without a session is rejected', anon.status === 401, `got ${anon.status}`);

  console.log('\nupload validation');
  const empty = await upload(donorToken, Buffer.alloc(0));
  check('empty body is rejected', empty.status === 400, `got ${empty.status}`);

  const html = Buffer.from('<html><script>alert(1)</script></html>');
  const disguised = await upload(donorToken, html, 'image/png');
  check(
    'HTML mislabelled as image/png is rejected',
    disguised.status === 415,
    `got ${disguised.status}`,
  );

  const svg = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>');
  const svgRes = await upload(donorToken, svg, 'image/svg+xml');
  check('SVG is rejected', svgRes.status === 415, `got ${svgRes.status}`);

  const huge = Buffer.concat([fakeJpeg(), Buffer.alloc(3 * 1024 * 1024)]);
  const hugeRes = await upload(donorToken, huge);
  check('oversized upload is rejected', hugeRes.status === 413, `got ${hugeRes.status}`);

  console.log('\nupload + serve');
  const uploaded = [];
  for (let i = 0; i < 6; i += 1) {
    const res = await upload(donorToken, fakeJpeg(64 + i));
    if (res.status === 201) uploaded.push(res.json.url);
  }
  check('six uploads succeed', uploaded.length === 6, `got ${uploaded.length}`);
  check(
    'upload returns an /api/uploads path',
    /^\/api\/uploads\/[a-f0-9]{24}$/.test(uploaded[0] || ''),
    uploaded[0],
  );

  const fetched = await fetch(`${BASE}${uploaded[0]}`);
  const fetchedBody = Buffer.from(await fetched.arrayBuffer());
  check('stored image is served publicly', fetched.status === 200, `got ${fetched.status}`);
  check(
    'served with the sniffed content type',
    fetched.headers.get('content-type') === 'image/jpeg',
    fetched.headers.get('content-type'),
  );
  check(
    'served with nosniff',
    fetched.headers.get('x-content-type-options') === 'nosniff',
  );
  check(
    'served bytes round-trip intact',
    fetchedBody.equals(fakeJpeg(64)),
    `${fetchedBody.length} bytes`,
  );

  const missing = await fetch(`${BASE}/api/uploads/ffffffffffffffffffffffff`);
  check('unknown id returns 404', missing.status === 404, `got ${missing.status}`);

  console.log('\nlisting photos');
  const created = await call('POST', '/api/listings', {
    token: donorToken,
    body: {
      title: 'Tekerlekli sandalye',
      category: 'wheelchair',
      city: 'Austin',
      state: 'TX',
      postalCode: '78701',
      photos: uploaded,
    },
  });
  check('listing is created', created.status === 201, `got ${created.status}`);
  check(
    'photos are capped at five',
    created.json?.listing?.photos?.length === 5,
    `got ${created.json?.listing?.photos?.length}`,
  );
  check(
    'cover mirrors the first photo',
    created.json?.listing?.photoUrl === uploaded[0],
    created.json?.listing?.photoUrl,
  );

  const forged = await call('POST', '/api/listings', {
    token: donorToken,
    body: {
      title: 'Sahte görselli ilan',
      category: 'walker',
      photos: [
        'https://evil.example.com/tracker.gif',
        'javascript:alert(1)',
        '/api/uploads/ffffffffffffffffffffffff',
      ],
    },
  });
  check(
    'external and unknown photo paths are dropped',
    forged.json?.listing?.photos?.length === 0,
    JSON.stringify(forged.json?.listing?.photos),
  );

  console.log('\nduplicates');
  const deduped = await call('POST', '/api/listings', {
    token: donorToken,
    body: {
      title: 'Aynı görsel iki kez',
      category: 'walker',
      photos: [uploaded[0], uploaded[0], uploaded[1]],
    },
  });
  check(
    'duplicate photos collapse',
    deduped.json?.listing?.photos?.length === 2,
    JSON.stringify(deduped.json?.listing?.photos),
  );

  console.log('\ncounterpart view');
  const browsed = await call('GET', '/api/listings/browse', {
    token: recipientToken,
  });
  const withPhotos = (browsed.json?.listings || []).find(
    (l) => l.photos?.length > 0,
  );
  check('counterpart sees listing photos', Boolean(withPhotos));
  check(
    'counterpart still cannot see the owner email',
    withPhotos ? withPhotos.ownerEmail === undefined : false,
  );

  console.log(
    failures === 0
      ? '\nAll upload checks passed.'
      : `\n${failures} check(s) failed.`,
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Smoke test crashed:', err);
  process.exit(1);
});
