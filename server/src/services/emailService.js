const nodemailer = require('nodemailer');
const { buildPasswordResetEmail } = require('../templates/passwordResetEmail');

/**
 * Nodemailer transport for MedGift US transactional mail.
 * All SMTP settings come from environment variables — never hard-code secrets.
 *
 * Required env (unless EMAIL_DRY_RUN=true):
 *   EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS
 * Optional:
 *   FROM_EMAIL (default: info@medgift.us)
 *   EMAIL_SECURE ("true" for port 465 / implicit TLS)
 *   EMAIL_DRY_RUN ("true" → log reset URL, skip SMTP — local/dev)
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

  // Local/dev: skip SMTP and print the link so QA can open it directly.
  if (isDryRun()) {
    console.info('[email:dry-run] Password-reset (not sent via SMTP)');
    console.info('[email:dry-run] to=', to);
    console.info('[email:dry-run] subject=', subject);
    console.info('[email:dry-run] resetUrl=', resetUrl);
    return {
      messageId: `dry-run-${Date.now()}`,
      accepted: [to],
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

    console.info(
      '[email] Password-reset sent',
      JSON.stringify({
        to,
        messageId: info.messageId,
        accepted: info.accepted,
      }),
    );

    return info;
  } catch (cause) {
    console.error('[email] Password-reset send failed:', cause);

    const err = new Error(
      'Şifre sıfırlama e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.',
    );
    err.code = 'EMAIL_SEND_FAILED';
    err.status = 502;
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
