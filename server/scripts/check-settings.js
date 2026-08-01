/**
 * Smoke test for the Admin CMS settings surface.
 *
 * Covers public read, admin auth on write, round-trip persistence of a
 * home.title override, and the /api/admin/settings alias.
 *
 * Usage (memory mode):
 *   USE_MEMORY_DB=1 PORT=3099 node src/index.js &
 *   API_BASE=http://127.0.0.1:3099 node scripts/check-settings.js
 */

const BASE = process.env.API_BASE || 'http://127.0.0.1:3001';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'info@medgift.us';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'MedGiftAdmin2026!';

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

async function main() {
  console.log(`Testing ${BASE}\n`);

  console.log('public read');
  const pub = await call('GET', '/api/settings/public');
  check('GET /api/settings/public succeeds', pub.status === 200);
  check('public payload has settings', Boolean(pub.json?.settings?.flags));
  check(
    'persistence reported',
    pub.json?.persistence === 'mongo' || pub.json?.persistence === 'memory',
    String(pub.json?.persistence),
  );

  console.log('\nadmin auth');
  const denied = await call('PUT', '/api/settings/admin', {
    body: { home: { title: 'should-fail' } },
  });
  check(
    'PUT without token is rejected',
    denied.status === 401 || denied.status === 403,
    `got ${denied.status}`,
  );

  const login = await call('POST', '/api/auth/admin-login', {
    body: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
  });
  const token = login.json?.token;
  check('admin login succeeds', login.status === 200 && Boolean(token));
  if (!token) {
    console.log('\nCannot continue without admin token.');
    process.exit(1);
  }

  console.log('\nround-trip via /api/settings/admin');
  const marker = `CMS-check-${Date.now()}`;
  const put = await call('PUT', '/api/settings/admin', {
    token,
    body: { home: { title: marker } },
  });
  check('PUT /api/settings/admin succeeds', put.status === 200);
  check(
    'PUT echoes the new title',
    put.json?.settings?.home?.title === marker,
    put.json?.settings?.home?.title,
  );

  const after = await call('GET', '/api/settings/public');
  check(
    'public read sees the new title',
    after.json?.settings?.home?.title === marker,
    after.json?.settings?.home?.title,
  );

  console.log('\nalias /api/admin/settings');
  const aliasGet = await call('GET', '/api/admin/settings', { token });
  check('GET /api/admin/settings succeeds', aliasGet.status === 200);
  check(
    'alias returns the saved title',
    aliasGet.json?.settings?.home?.title === marker,
    aliasGet.json?.settings?.home?.title,
  );

  const aliasPut = await call('PUT', '/api/admin/settings', {
    token,
    body: { home: { title: '' } },
  });
  check('PUT /api/admin/settings clears title', aliasPut.status === 200);
  const cleared = await call('GET', '/api/settings/public');
  check(
    'public title cleared (l10n fallback)',
    (cleared.json?.settings?.home?.title || '') === '',
    cleared.json?.settings?.home?.title,
  );

  console.log(
    failures === 0
      ? '\nAll settings checks passed.'
      : `\n${failures} settings check(s) failed.`,
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Smoke test crashed:', err);
  process.exit(1);
});
