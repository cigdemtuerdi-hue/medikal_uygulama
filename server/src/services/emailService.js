const nodemailer = require('nodemailer');
const { buildPasswordResetEmail } = require('../templates/passwordResetEmail');
const { safeInfo, safeError, maskEmail } = require('../utils/safeLog');

/**
 * Nodemailer transport for MedGift US transactional mail.
 * All SMTP settings come from environment variables — never hard-code secrets.
 *
 * Required env (unless EMAIL_DRY_RUN=true):
 *   EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS
 * Optional:
 *   FROM_EMAIL (default: info@medgift.us)
 *   EMAIL_SECURE ("true" for port 465 / implicit TLS)
 *   EMAIL_DRY_RUN ("true" → log redacted metadata, skip SMTP — local/dev)
 */

let cachedTransporter = null;

function isDryRun() {
  return String(process.env.EMAIL_DRY_RUN || '').toLowerCase() === 'true';
}

function fromAddress() {
  const from = (process.env.FROM_EMAIL || 'info@medgift.us').trim();
  return `Medgift LLC <${from}>`;
}

function readSmtpConfig() {
  const host = (process.env.EMAIL_HOST || '').trim();
  const port = Number(process.env.EMAIL_PORT);
  const user = (process.env.EMAIL_USER || '').trim();
  const pass = process.env.EMAIL_PASS || '';
  const secure =
    String(process.env.EMAIL_SECURE || '').toLowerCase() === 'true' ||
    port === 465;

  const missing = [];
  if (!host) missing.push('EMAIL_HOST');
  if (!Number.isFinite(port) || port <= 0) missing.push('EMAIL_PORT');
  if (!user) missing.push('EMAIL_USER');
  if (!pass) missing.push('EMAIL_PASS');

  if (missing.length > 0) {
    const err = new Error(
      `E-posta yapılandırması eksik: ${missing.join(', ')}`,
    );
    err.code = 'EMAIL_CONFIG_MISSING';
    err.status = 503;
    throw err;
  }

  return { host, port, user, pass, secure };
}

function getTransporter() {
  if (cachedTransporter) return cachedTransporter;

  const { host, port, user, pass, secure } = readSmtpConfig();

  cachedTransporter = nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });

  return cachedTransporter;
}

/**
 * Send the password-reset message to the user.
 *
 * @param {{ to: string, resetUrl: string }} opts
 */
async function sendPasswordResetEmail({ to, resetUrl }) {
  if (!to || !resetUrl) {
    const err = new Error('E-posta alıcısı veya sıfırlama bağlantısı eksik.');
    err.code = 'EMAIL_INVALID_ARGS';
    err.status = 500;
    throw err;
  }

  const { subject, html, text } = buildPasswordResetEmail({
    resetUrl,
    recipientEmail: to,
  });

  // Local/dev: skip SMTP — never print full email or reset token URL.
  if (isDryRun()) {
    safeInfo('[email:dry-run] Password-reset (not sent via SMTP)', {
      to,
      subject,
      resetUrl,
    });
    return {
      messageId: `dry-run-${Date.now()}`,
      accepted: [maskEmail(to)],
      dryRun: true,
    };
  }

  const transporter = getTransporter();

  try {
    const info = await transporter.sendMail({
      from: fromAddress(),
      to,
      subject,
      text,
      html,
    });

    safeInfo('[email] Password-reset sent', {
      to,
      messageId: info.messageId,
    });

    return info;
  } catch (cause) {
    safeError('[email] Password-reset send failed:', cause);

    const responseCode = cause?.responseCode;
    const isAuth =
      cause?.code === 'EAUTH' ||
      responseCode === 535 ||
      /auth/i.test(String(cause?.message || ''));

    const err = new Error(
      isAuth
        ? 'E-posta sunucusu şifreyi reddetti. info@medgift.us SMTP şifresini güncelleyin.'
        : 'Şifre sıfırlama e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.',
    );
    err.code = isAuth ? 'EMAIL_AUTH_FAILED' : 'EMAIL_SEND_FAILED';
    err.status = isAuth ? 503 : 502;
    err.cause = cause;
    throw err;
  }
}

module.exports = {
  sendPasswordResetEmail,
  fromAddress,
  getTransporter,
  isDryRun,
};
