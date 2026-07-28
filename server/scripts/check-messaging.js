/**
 * Local diagnostic for email SMTP.
 * Does not print secrets. Run: npm run check:messaging
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const nodemailer = require('nodemailer');

function present(name) {
  const v = process.env[name];
  return Boolean(v && String(v).trim());
}

function meta(name) {
  const v = String(process.env[name] || '');
  return {
    set: v.length > 0,
    length: v.length,
    hasHash: v.includes('#'),
  };
}

async function checkSmtp() {
  if (String(process.env.EMAIL_DRY_RUN || '').toLowerCase() === 'true') {
    return { ok: false, reason: 'EMAIL_DRY_RUN=true (mail intentionally not sent)' };
  }
  if (!present('EMAIL_HOST') || !present('EMAIL_USER') || !present('EMAIL_PASS')) {
    return { ok: false, reason: 'Missing EMAIL_HOST / EMAIL_USER / EMAIL_PASS' };
  }
  const port = Number(process.env.EMAIL_PORT || 587);
  const secure =
    String(process.env.EMAIL_SECURE || '').toLowerCase() === 'true' || port === 465;
  try {
    const transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST,
      port,
      secure,
      requireTLS: !secure && port === 587,
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
      connectionTimeout: 15000,
    });
    await transporter.verify();
    return { ok: true, host: process.env.EMAIL_HOST, port, user: process.env.EMAIL_USER };
  } catch (err) {
    return {
      ok: false,
      reason: err.message,
      code: err.code,
      responseCode: err.responseCode,
    };
  }
}

(async () => {
  console.log('MedGift email diagnostic (SMS disabled)');
  console.log('EMAIL_PASS', meta('EMAIL_PASS'));
  console.log('---');
  const email = await checkSmtp();
  console.log('SMTP', email);
  console.log('---');
  if (!email.ok) {
    console.log(
      'FIX EMAIL: Reset the mailbox password for info@medgift.us in GoDaddy, put the full password in EMAIL_PASS wrapped in double quotes if it contains #, then copy the same value into Render → Environment → EMAIL_PASS.',
    );
  }
  process.exit(email.ok ? 0 : 1);
})();
