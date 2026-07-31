/**
 * Log helpers that never print emails, phones, tokens, or reset URLs in full.
 */

function maskEmail(email) {
  const s = String(email || '').trim().toLowerCase();
  const at = s.indexOf('@');
  if (at < 1) return '[redacted]';
  const user = s.slice(0, at);
  const domain = s.slice(at + 1);
  const keep = user.slice(0, Math.min(2, user.length));
  return `${keep}***@${domain}`;
}

function maskPhone(phone) {
  const digits = String(phone || '').replace(/\D/g, '');
  if (digits.length < 4) return '[redacted]';
  return `***${digits.slice(-4)}`;
}

function redactUrl(url) {
  try {
    const u = new URL(String(url));
    if (u.pathname.includes('reset-password')) {
      u.pathname = u.pathname.replace(
        /\/reset-password\/[^/]+/i,
        '/reset-password/[redacted]',
      );
    }
    u.search = '';
    u.hash = '';
    return u.toString();
  } catch (_) {
    return '[redacted-url]';
  }
}

function safeInfo(message, meta = {}) {
  const clean = { ...meta };
  if (clean.to) clean.to = maskEmail(clean.to);
  if (clean.email) clean.email = maskEmail(clean.email);
  if (clean.phone) clean.phone = maskPhone(clean.phone);
  if (clean.resetUrl) clean.resetUrl = redactUrl(clean.resetUrl);
  if (clean.token) clean.token = '[redacted]';
  console.info(message, Object.keys(clean).length ? JSON.stringify(clean) : '');
}

function safeWarn(message, meta = {}) {
  const clean = { ...meta };
  if (clean.to) clean.to = maskEmail(clean.to);
  if (clean.email) clean.email = maskEmail(clean.email);
  console.warn(message, Object.keys(clean).length ? JSON.stringify(clean) : '');
}

function safeError(message, err) {
  console.error(message, err?.code || err?.name || '', err?.message || err);
}

module.exports = {
  maskEmail,
  maskPhone,
  redactUrl,
  safeInfo,
  safeWarn,
  safeError,
};
