const nodemailer = require('nodemailer');
const { buildPasswordResetEmail } = require('../templates/passwordResetEmail');
const { safeInfo, safeError, maskEmail } = require('../utils/safeLog');

/**
 * Transactional mail for MedGift US.
 *
 * Preferred on Render: Resend HTTP API (RESEND_API_KEY) — SMTP is often blocked.
 * Fallback: GoDaddy / generic SMTP via EMAIL_HOST + EMAIL_USER + EMAIL_PASS.
 */

let cachedTransporter = null;

function isDryRun() {
  return String(process.env.EMAIL_DRY_RUN || '').toLowerCase() === 'true';
}

function resendApiKey() {
  return (process.env.RESEND_API_KEY || '').trim();
}

function usesResend() {
  return Boolean(resendApiKey());
}

function isEmailConfigured() {
  if (isDryRun()) return true;
  if (usesResend()) return true;
  return Boolean(
    (process.env.EMAIL_HOST || '').trim() &&
      (process.env.EMAIL_USER || '').trim() &&
      (process.env.EMAIL_PASS || '').trim(),
  );
}

function fromAddress() {
  // Prefer explicit RESEND_FROM. When using Resend without a verified
  // domain, never fall back to info@medgift.us (Resend rejects it).
  const raw = (
    process.env.RESEND_FROM ||
    (usesResend()
      ? 'Medgift LLC <onboarding@resend.dev>'
      : process.env.FROM_EMAIL || 'info@medgift.us')
  ).trim();
  if (raw.includes('<')) return raw;
  return `Medgift LLC <${raw}>`;
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
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 20000,
  });

  return cachedTransporter;
}

async function sendViaResend({ to, subject, html, text }) {
  const key = resendApiKey();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 20000);

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromAddress(),
        to: [to],
        subject,
        html,
        text,
      }),
      signal: controller.signal,
    });

    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      const msg =
        body?.message ||
        body?.error?.message ||
        `Resend HTTP ${response.status}`;
      const err = new Error(msg);
      err.code =
        response.status === 401 || response.status === 403
          ? 'EMAIL_AUTH_FAILED'
          : 'EMAIL_SEND_FAILED';
      err.status = response.status === 401 || response.status === 403 ? 503 : 502;
      err.cause = body;
      throw err;
    }

    return {
      messageId: body.id || `resend-${Date.now()}`,
      accepted: [maskEmail(to)],
      provider: 'resend',
    };
  } finally {
    clearTimeout(timer);
  }
}

async function sendViaSmtp({ to, subject, html, text }) {
  const transporter = getTransporter();
  const info = await transporter.sendMail({
    from: fromAddress(),
    to,
    subject,
    text,
    html,
  });
  return {
    messageId: info.messageId,
    accepted: info.accepted,
    provider: 'smtp',
  };
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

  if (isDryRun()) {
    safeInfo('[email:dry-run] Password-reset (not sent)', {
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

  if (!isEmailConfigured()) {
    const err = new Error(
      'E-posta yapılandırması eksik: RESEND_API_KEY veya EMAIL_HOST/USER/PASS.',
    );
    err.code = 'EMAIL_CONFIG_MISSING';
    err.status = 503;
    throw err;
  }

  try {
    const info = usesResend()
      ? await sendViaResend({ to, subject, html, text })
      : await sendViaSmtp({ to, subject, html, text });

    safeInfo('[email] Password-reset sent', {
      to,
      messageId: info.messageId,
      provider: info.provider,
    });
    return info;
  } catch (cause) {
    safeError('[email] Password-reset send failed:', cause);

    if (cause?.code === 'EMAIL_AUTH_FAILED' || cause?.code === 'EMAIL_SEND_FAILED') {
      throw cause;
    }

    const responseCode = cause?.responseCode;
    const isAuth =
      cause?.code === 'EAUTH' ||
      responseCode === 535 ||
      /auth|unauthorized|invalid api key/i.test(String(cause?.message || ''));

    const err = new Error(
      isAuth
        ? 'E-posta kimlik doğrulaması başarısız. RESEND_API_KEY veya SMTP şifresini kontrol edin.'
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
  usesResend,
  isEmailConfigured,
};
