const { verifySessionToken } = require('../utils/sessionToken');
const { normalizeRole } = require('./rbac');

function readBearerToken(req) {
  const header = String(req.headers.authorization || '');
  const match = /^Bearer\s+(.+)$/i.exec(header);
  return match ? match[1].trim() : '';
}

/**
 * Resolves req.user from a signed session token when present.
 * Never rejects — use for endpoints that behave differently when signed in.
 */
function attachUser(req, _res, next) {
  const claims = verifySessionToken(readBearerToken(req));
  req.user = claims
    ? { ...claims, role: normalizeRole(claims.role) }
    : null;
  return next();
}

/**
 * Rejects the request unless a valid session token is present.
 *
 * The older X-User-Id / X-User-Role headers are deliberately not accepted here:
 * they are client-supplied and would let any caller read another account's
 * listings.
 */
function requireUser(req, res, next) {
  const claims = verifySessionToken(readBearerToken(req));
  if (!claims) {
    return res.status(401).json({
      success: false,
      message: 'Oturum gerekli. Lütfen tekrar giriş yapın.',
      code: 'SESSION_REQUIRED',
    });
  }
  req.user = { ...claims, role: normalizeRole(claims.role) };
  return next();
}

module.exports = {
  attachUser,
  requireUser,
  readBearerToken,
};
