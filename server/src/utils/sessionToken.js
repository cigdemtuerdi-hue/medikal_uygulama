const crypto = require('crypto');

/**
 * HMAC-SHA256 signed session tokens for end users.
 *
 * Format: base64url(payloadJson).base64url(signature)
 *
 * Kept dependency-free on purpose: Render deploys this server straight from
 * package.json and the auth surface is small enough that a signed payload plus
 * an expiry covers what we need. Rotate by setting SESSION_TOKEN_SECRET.
 */

const TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60;

function resolveSecret() {
  const raw = (
    process.env.SESSION_TOKEN_SECRET ||
    process.env.PHI_ENCRYPTION_SECRET ||
    process.env.ADMIN_PASSWORD ||
    'medgift-dev-session-secret'
  ).toString();
  return crypto.createHash('sha256').update(`medgift-session-v1:${raw}`).digest();
}

function base64url(buffer) {
  return Buffer.from(buffer)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function fromBase64url(value) {
  const padded = String(value).replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(padded, 'base64');
}

function sign(payloadB64) {
  return base64url(
    crypto.createHmac('sha256', resolveSecret()).update(payloadB64).digest(),
  );
}

/**
 * @param {{ userId: string, email: string, role: string|null }} user
 * @returns {{ token: string, expiresAt: Date, expiresInSeconds: number }}
 */
function issueSessionToken({ userId, email, role }) {
  const expiresInSeconds = TOKEN_TTL_SECONDS;
  const exp = Math.floor(Date.now() / 1000) + expiresInSeconds;
  const payloadB64 = base64url(
    JSON.stringify({
      uid: String(userId),
      email: String(email || '').toLowerCase(),
      role: role || null,
      exp,
    }),
  );
  return {
    token: `${payloadB64}.${sign(payloadB64)}`,
    expiresAt: new Date(exp * 1000),
    expiresInSeconds,
  };
}

/**
 * @returns {{ userId: string, email: string, role: string|null }|null}
 */
function verifySessionToken(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [payloadB64, signature] = token.split('.');
  if (!payloadB64 || !signature) return null;

  const expected = sign(payloadB64);
  const givenBuf = Buffer.from(signature);
  const expectedBuf = Buffer.from(expected);
  if (
    givenBuf.length !== expectedBuf.length ||
    !crypto.timingSafeEqual(givenBuf, expectedBuf)
  ) {
    return null;
  }

  let payload;
  try {
    payload = JSON.parse(fromBase64url(payloadB64).toString('utf8'));
  } catch (_) {
    return null;
  }

  if (!payload?.uid || !payload?.exp) return null;
  if (Number(payload.exp) * 1000 <= Date.now()) return null;

  return {
    userId: String(payload.uid),
    email: String(payload.email || ''),
    role: payload.role || null,
  };
}

module.exports = {
  issueSessionToken,
  verifySessionToken,
  TOKEN_TTL_SECONDS,
};
