/**
 * Production transport security: refuse cleartext API calls behind a proxy
 * that advertises X-Forwarded-Proto (Render / Cloudflare / etc.).
 * Localhost is always allowed for Flutter web debug.
 */
function enforceTls(req, res, next) {
  if (String(process.env.NODE_ENV || '').toLowerCase() !== 'production') {
    return next();
  }
  if (String(process.env.ALLOW_INSECURE_HTTP || '').toLowerCase() === 'true') {
    return next();
  }

  const host = String(req.hostname || '');
  if (host === 'localhost' || host === '127.0.0.1') {
    return next();
  }

  const proto = String(
    req.headers['x-forwarded-proto'] || req.protocol || '',
  )
    .split(',')[0]
    .trim()
    .toLowerCase();

  if (proto && proto !== 'https') {
    return res.status(403).json({
      success: false,
      message: 'HTTPS / TLS required. Cleartext health-data transport is blocked.',
      code: 'TLS_REQUIRED',
    });
  }

  // HSTS for browsers that hit the API origin directly.
  res.setHeader(
    'Strict-Transport-Security',
    'max-age=31536000; includeSubDomains',
  );
  return next();
}

module.exports = { enforceTls };
