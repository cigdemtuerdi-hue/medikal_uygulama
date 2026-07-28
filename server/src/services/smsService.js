/**
 * SMS delivery for password-reset OTP codes.
 *
 * Set SMS_DRY_RUN=true (default locally) to log the message instead of
 * calling a real provider (Twilio, etc.).
 *
 * Optional production env (when SMS_DRY_RUN=false):
 *   SMS_PROVIDER=console|twilio  (console = log only)
 *   TWILIO_ACCOUNT_SID, TWILIO_FROM_NUMBER
 *   + TWILIO_API_KEY + TWILIO_API_SECRET  (preferred)
 *   or TWILIO_AUTH_TOKEN
 */

function isDryRun() {
  // Explicit opt-in only — missing/empty means REAL SMS (fail if Twilio unset).
  return String(process.env.SMS_DRY_RUN || '').toLowerCase() === 'true';
}

/**
 * Mask a phone for UI/logs: +1******4567
 */
function maskPhone(phone) {
  const digits = String(phone || '').replace(/\D/g, '');
  if (digits.length < 4) return '****';
  return `***${digits.slice(-4)}`;
}

/**
 * @param {{ to: string, code: string }} opts
 */
async function sendPasswordResetSms({ to, code }) {
  if (!to || !code) {
    const err = new Error('Telefon numarası veya kod eksik.');
    err.code = 'SMS_INVALID_ARGS';
    err.status = 500;
    throw err;
  }

  const body =
    `MedGift: Sifre sifirlama kodunuz ${code}. ` +
    `Bu kod 10 dakika gecerlidir. Kimseyle paylasmayin.`;

  if (isDryRun()) {
    console.info('[sms:dry-run] Password-reset OTP (not sent via provider)');
    console.info('[sms:dry-run] to=', to, `(masked ${maskPhone(to)})`);
    console.info('[sms:dry-run] code=', code);
    console.info('[sms:dry-run] body=', body);
    return { dryRun: true, to, code };
  }

  const provider = (process.env.SMS_PROVIDER || 'console').toLowerCase();

  if (provider === 'console') {
    console.info('[sms] to=', to, 'body=', body);
    return { provider: 'console', to };
  }

  if (provider === 'twilio') {
    // Lazy require so local dry-run does not need the Twilio package.
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const apiKey = (process.env.TWILIO_API_KEY || '').trim();
    const apiSecret = (process.env.TWILIO_API_SECRET || '').trim();
    const authToken = (process.env.TWILIO_AUTH_TOKEN || '').trim();
    const from = process.env.TWILIO_FROM_NUMBER;
    const hasApiKey = Boolean(apiKey && apiSecret);
    const hasAuthToken = Boolean(authToken);
    if (!accountSid || !from || (!hasApiKey && !hasAuthToken)) {
      const err = new Error('Twilio yapılandırması eksik.');
      err.code = 'SMS_CONFIG_MISSING';
      err.status = 503;
      throw err;
    }

    // Prefer Account SID + Auth Token when set (Twilio Console curl style).
    const twilio = hasAuthToken
      ? require('twilio')(accountSid, authToken)
      : require('twilio')(apiKey, apiSecret, { accountSid });
    try {
      const msg = await twilio.messages.create({
        to,
        from,
        body,
      });
      console.info('[sms] Twilio sent', msg.sid);
      return { provider: 'twilio', sid: msg.sid };
    } catch (cause) {
      console.error('[sms] Twilio send failed:', cause);
      const err = new Error(
        'SMS gönderilemedi. Lütfen daha sonra tekrar deneyin.',
      );
      err.code = 'SMS_SEND_FAILED';
      err.status = 502;
      err.cause = cause;
      throw err;
    }
  }

  const err = new Error(`Bilinmeyen SMS sağlayıcısı: ${provider}`);
  err.code = 'SMS_PROVIDER_UNKNOWN';
  err.status = 503;
  throw err;
}

module.exports = {
  sendPasswordResetSms,
  maskPhone,
  isDryRun,
};
