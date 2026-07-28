/**
 * Local diagnostic for email + SMS providers.
 * Does not print secrets. Run: node scripts/check-messaging.js
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

async function checkTwilio() {
  if (String(process.env.SMS_DRY_RUN || '').toLowerCase() === 'true') {
    return { ok: false, reason: 'SMS_DRY_RUN=true (SMS intentionally not sent)' };
  }
  if ((process.env.SMS_PROVIDER || 'console').toLowerCase() !== 'twilio') {
    return {
      ok: false,
      reason: `SMS_PROVIDER=${process.env.SMS_PROVIDER || 'console'} (not twilio)`,
    };
  }
  if (!present('TWILIO_ACCOUNT_SID') || !present('TWILIO_FROM_NUMBER')) {
    return { ok: false, reason: 'Missing TWILIO_ACCOUNT_SID or TWILIO_FROM_NUMBER' };
  }
  if (!present('TWILIO_AUTH_TOKEN') && !(present('TWILIO_API_KEY') && present('TWILIO_API_SECRET'))) {
    return { ok: false, reason: 'Missing TWILIO_AUTH_TOKEN (or API key pair)' };
  }

  const twilio = require('twilio');
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = (process.env.TWILIO_AUTH_TOKEN || '').trim();
  const client = authToken
    ? twilio(accountSid, authToken)
    : twilio(process.env.TWILIO_API_KEY, process.env.TWILIO_API_SECRET, { accountSid });

  const from = process.env.TWILIO_FROM_NUMBER;
  try {
    const owned = await client.incomingPhoneNumbers.list({ limit: 20 });
    const numbers = owned.map((n) => n.phoneNumber);
    const fromOwned = numbers.includes(from);
    return {
      ok: fromOwned,
      from,
      fromOwned,
      accountNumbers: numbers,
      reason: fromOwned
        ? undefined
        : 'TWILIO_FROM_NUMBER is not an Incoming Phone Number on this Twilio account. Buy/assign a number in Twilio Console.',
    };
  } catch (err) {
    return { ok: false, reason: err.message, code: err.code || err.status };
  }
}

(async () => {
  console.log('MedGift messaging diagnostic');
  console.log('EMAIL_PASS', meta('EMAIL_PASS'));
  console.log('TWILIO_AUTH_TOKEN', meta('TWILIO_AUTH_TOKEN'));
  console.log('TWILIO_FROM_NUMBER set=', present('TWILIO_FROM_NUMBER'));
  console.log('---');
  const email = await checkSmtp();
  console.log('SMTP', email);
  const sms = await checkTwilio();
  console.log('TWILIO', sms);
  console.log('---');
  if (!email.ok) {
    console.log(
      'FIX EMAIL: Reset the mailbox password for info@medgift.us in GoDaddy, put the full password in EMAIL_PASS wrapped in double quotes if it contains #, then copy the same value into Render → Environment → EMAIL_PASS.',
    );
  }
  if (!sms.ok) {
    console.log(
      'FIX SMS: In Twilio Console buy a US number, set TWILIO_FROM_NUMBER to that E.164 number, and copy SID/token/from into Render Environment.',
    );
  }
  process.exit(email.ok && sms.ok ? 0 : 1);
})();
