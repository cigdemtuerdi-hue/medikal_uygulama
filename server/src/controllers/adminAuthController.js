const crypto = require('crypto');
const bcrypt = require('bcrypt');

/**
 * Owner-only admin auth (email + password from env).
 * Sessions are in-memory tokens (12h) — fine for single-operator console.
 */

const sessions = new Map();

const SESSION_TTL_MS = 12 * 60 * 60 * 1000;

/** Fallback when Render ADMIN_PASSWORD secret is not set yet (owner bootstrap). */
const BOOTSTRAP_ADMIN_EMAIL = 'info@medgift.us';
const BOOTSTRAP_ADMIN_PASSWORD_HASH =
  '$2b$10$cNwGob4rQR42hKvHYhhPgu.dRPAokNW2jEsUkd0czQhiDrCpk6sJi';

function adminEmail() {
  return (process.env.ADMIN_EMAIL || process.env.ADMIN_NOTIFY_EMAIL || BOOTSTRAP_ADMIN_EMAIL)
    .trim()
    .toLowerCase();
}

function adminPassword() {
  return (process.env.ADMIN_PASSWORD || process.env.ADMIN_PIN || '').trim();
}

function isAdminConfigured() {
  // Always true: env password OR bootstrap hash for the owner mailbox.
  return Boolean(adminEmail());
}

function purgeExpiredSessions() {
  const now = Date.now();
  for (const [token, session] of sessions.entries()) {
    if (!session || session.expiresAt <= now) sessions.delete(token);
  }
}

function createSession(email) {
  purgeExpiredSessions();
  const token = crypto.randomBytes(32).toString('hex');
  sessions.set(token, {
    email,
    expiresAt: Date.now() + SESSION_TTL_MS,
  });
  return token;
}

function readBearerToken(req) {
  const header = String(req.headers.authorization || '');
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (match) return match[1].trim();
  const bodyToken = req.body?.token;
  if (typeof bodyToken === 'string' && bodyToken.trim()) return bodyToken.trim();
  const queryToken = req.query?.token;
  if (typeof queryToken === 'string' && queryToken.trim()) {
    return queryToken.trim();
  }
  return '';
}

function getValidSession(token) {
  if (!token) return null;
  purgeExpiredSessions();
  const session = sessions.get(token);
  if (!session) return null;
  if (session.expiresAt <= Date.now()) {
    sessions.delete(token);
    return null;
  }
  return session;
}

async function passwordMatches(password, expectedEmail) {
  const configured = adminPassword();
  if (configured) {
    const passBuf = Buffer.from(password);
    const expectedBuf = Buffer.from(configured);
    return (
      passBuf.length === expectedBuf.length &&
      crypto.timingSafeEqual(passBuf, expectedBuf)
    );
  }

  // Bootstrap path: only for the owner mailbox until ADMIN_PASSWORD is set on Render.
  if (expectedEmail !== BOOTSTRAP_ADMIN_EMAIL) return false;
  try {
    return await bcrypt.compare(password, BOOTSTRAP_ADMIN_PASSWORD_HASH);
  } catch (_) {
    return false;
  }
}

/**
 * POST /api/auth/admin-login
 * Body: { email, password }
 */
async function adminLogin(req, res) {
  const email = String(req.body?.email || '')
    .trim()
    .toLowerCase();
  const password = String(req.body?.password || '');

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'E-posta ve şifre gerekli.',
      code: 'CREDENTIALS_REQUIRED',
    });
  }

  const expectedEmail = adminEmail();
  const emailOk = email === expectedEmail;
  const passOk = emailOk ? await passwordMatches(password, expectedEmail) : false;

  if (!emailOk || !passOk) {
    return res.status(401).json({
      success: false,
      message: 'Admin e-posta veya şifre hatalı.',
      code: 'INVALID_ADMIN_CREDENTIALS',
    });
  }

  const token = createSession(email);
  return res.status(200).json({
    success: true,
    message: 'Admin girişi başarılı.',
    token,
    email,
    expiresInSeconds: Math.floor(SESSION_TTL_MS / 1000),
  });
}

/**
 * GET /api/auth/admin-session
 * Authorization: Bearer <token>
 */
function adminSession(req, res) {
  const token = readBearerToken(req);
  const session = getValidSession(token);
  if (!session) {
    return res.status(401).json({
      success: false,
      message: 'Admin oturumu geçersiz veya süresi dolmuş.',
      code: 'ADMIN_SESSION_INVALID',
    });
  }
  return res.status(200).json({
    success: true,
    email: session.email,
    expiresAt: new Date(session.expiresAt).toISOString(),
  });
}

/**
 * POST /api/auth/admin-logout
 * Authorization: Bearer <token>
 */
function adminLogout(req, res) {
  const token = readBearerToken(req);
  if (token) sessions.delete(token);
  return res.status(200).json({
    success: true,
    message: 'Admin oturumu kapatıldı.',
  });
}

/**
 * Express middleware — requires a valid admin bearer token.
 */
function requireAdmin(req, res, next) {
  const token = readBearerToken(req);
  const session = getValidSession(token);
  if (!session) {
    return res.status(401).json({
      success: false,
      message: 'Admin yetkisi gerekli.',
      code: 'ADMIN_REQUIRED',
    });
  }
  req.admin = session;
  return next();
}

module.exports = {
  adminLogin,
  adminSession,
  adminLogout,
  requireAdmin,
  isAdminConfigured,
};
