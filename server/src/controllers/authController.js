const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { getUserModel } = require('../models/userModel');
const { sendPasswordResetEmail } = require('../services/emailService');
const { sendPasswordResetSms, maskPhone, isDryRun } = require('../services/smsService');

/** bcrypt cost factor — balance security vs latency on modest hosts. */
const BCRYPT_ROUNDS = 12;

/** Minimum accepted password length (matches Flutter client). */
const MIN_PASSWORD_LENGTH = 8;

/** SMS OTP lifetime. */
const SMS_OTP_TTL_MS = 10 * 60 * 1000;

const FORGOT_EMAIL_SUCCESS_MESSAGE =
  'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';

const FORGOT_SMS_SUCCESS_MESSAGE =
  'Doğrulama kodu telefonunuza SMS ile gönderildi.';

const RESET_TOKEN_INVALID_MESSAGE =
  'Sıfırlama bağlantısının süresi dolmuş veya geçersiz.';

const RESET_SMS_INVALID_MESSAGE =
  'SMS kodu geçersiz veya süresi dolmuş.';

function appOrigin() {
  const raw = (process.env.APP_ORIGIN || 'https://medgift.us').trim();
  return raw.replace(/\/$/, '');
}

function hashResetToken(rawToken) {
  return crypto.createHash('sha256').update(rawToken).digest('hex');
}

function hashSmsCode(code) {
  return crypto.createHash('sha256').update(String(code)).digest('hex');
}

/** Cryptographically strong 4-digit OTP: 1000–9999. */
function generateFourDigitCode() {
  return String(crypto.randomInt(1000, 10000));
}

function phoneDigits(value) {
  return String(value || '').replace(/\D/g, '');
}

/**
 * Normalize to +E.164-ish for storage (digits with leading +).
 * Accepts 10–15 digits.
 */
function normalizePhone(value) {
  if (typeof value !== 'string') return '';
  const digits = phoneDigits(value);
  if (digits.length < 10 || digits.length > 15) return '';
  return `+${digits}`;
}

function isValidPhoneFormat(phone) {
  return normalizePhone(phone).length >= 11; // + plus at least 10 digits
}

/**
 * Find user by email or by phone digits (memory + mongo).
 */
async function findUserByEmailOrPhone({ email, phone }) {
  const User = getUserModel();
  if (email) {
    const byEmail = await User.findOne({ email });
    if (byEmail) return byEmail;
  }
  if (phone && typeof User.findOneByPhoneDigits === 'function') {
    return User.findOneByPhoneDigits(phoneDigits(phone));
  }
  if (phone) {
    // Mongo / simple stores: try exact normalized match first.
    const normalized = normalizePhone(phone);
    if (normalized) {
      const exact = await User.findOne({ phone: normalized });
      if (exact) return exact;
    }
  }
  return null;
}

function sanitizeEmail(value) {
  if (typeof value !== 'string') return '';
  return value.trim().toLowerCase();
}

function isValidEmailFormat(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function sanitizePassword(value) {
  return typeof value === 'string' ? value : '';
}

function sanitizeToken(value) {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim();
  if (!/^[a-fA-F0-9]{16,128}$/.test(trimmed)) return '';
  return trimmed;
}

function sanitizeMethod(value) {
  const m = typeof value === 'string' ? value.trim().toLowerCase() : 'email';
  if (m === 'sms' || m === 'phone') return 'sms';
  return 'email';
}

function sanitizeSmsCode(value) {
  if (typeof value !== 'string' && typeof value !== 'number') return '';
  const digits = String(value).replace(/\D/g, '');
  return digits.length === 4 ? digits : '';
}

async function clearResetToken(user) {
  user.resetPasswordToken = null;
  user.resetPasswordExpires = null;
  await user.save();
}

async function clearSmsCode(user) {
  user.resetSmsCodeHash = null;
  user.resetSmsExpires = null;
  await user.save();
}

/**
 * POST /api/auth/forgot-password
 * Body:
 *   method=email → { email }
 *   method=sms   → { phone } (email optional)
 */
async function forgotPassword(req, res, next) {
  try {
    const method = sanitizeMethod(req.body?.method);
    const email = sanitizeEmail(req.body?.email);
    const phoneRaw =
      typeof req.body?.phone === 'string' ? req.body.phone.trim() : '';
    const phone = normalizePhone(phoneRaw);

    if (method === 'sms') {
      if (!phone || !isValidPhoneFormat(phoneRaw)) {
        return res.status(400).json({
          success: false,
          message: 'Geçerli bir telefon numarası girin.',
        });
      }

      const user = await findUserByEmailOrPhone({ email, phone });
      if (!user) {
        return res.status(200).json({
          success: true,
          message: FORGOT_SMS_SUCCESS_MESSAGE,
          method: 'sms',
          phoneHint: maskPhone(phone),
        });
      }

      // Prefer the number the user just typed for delivery.
      return forgotPasswordViaSms(user, phone, res);
    }

    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir e-posta adresi girin.',
      });
    }

    const user = await findUserByEmailOrPhone({ email });
    if (!user) {
      return res.status(200).json({
        success: true,
        message: FORGOT_EMAIL_SUCCESS_MESSAGE,
        method: 'email',
      });
    }

    return forgotPasswordViaEmail(user, res);
  } catch (err) {
    return next(err);
  }
}

async function forgotPasswordViaEmail(user, res) {
  const resetToken = crypto.randomBytes(32).toString('hex');
  const hashedToken = hashResetToken(resetToken);

  user.resetPasswordToken = hashedToken;
  user.resetPasswordExpires = new Date(Date.now() + 60 * 60 * 1000);
  // Prefer a single active channel — clear SMS OTP if any.
  user.resetSmsCodeHash = null;
  user.resetSmsExpires = null;
  await user.save();

  const resetUrl = `${appOrigin()}/reset-password/${resetToken}`;

  try {
    await sendPasswordResetEmail({ to: user.email, resetUrl });
  } catch (emailErr) {
    try {
      await clearResetToken(user);
    } catch (clearErr) {
      console.error('[forgot-password] Failed to clear reset token:', clearErr);
    }
    console.error('[forgot-password] Email send failed:', emailErr);
    return res.status(502).json({
      success: false,
      message: 'İstek işlenemedi. Lütfen daha sonra tekrar deneyin.',
      code: 'REQUEST_FAILED',
    });
  }

  return res.status(200).json({
    success: true,
    message: FORGOT_EMAIL_SUCCESS_MESSAGE,
    method: 'email',
  });
}

async function forgotPasswordViaSms(user, deliveryPhone, res) {
  const to = normalizePhone(deliveryPhone) || normalizePhone(user.phone);
  if (!to) {
    return res.status(200).json({
      success: true,
      message: FORGOT_SMS_SUCCESS_MESSAGE,
      method: 'sms',
    });
  }

  // Keep profile phone in sync with the number used for this reset.
  if (!user.phone || phoneDigits(user.phone) !== phoneDigits(to)) {
    user.phone = to;
  }

  const code = generateFourDigitCode();
  user.resetSmsCodeHash = hashSmsCode(code);
  user.resetSmsExpires = new Date(Date.now() + SMS_OTP_TTL_MS);
  user.resetPasswordToken = null;
  user.resetPasswordExpires = null;
  await user.save();

  try {
    await sendPasswordResetSms({ to, code });
  } catch (smsErr) {
    try {
      await clearSmsCode(user);
    } catch (clearErr) {
      console.error('[forgot-password] Failed to clear SMS code:', clearErr);
    }
    console.error('[forgot-password] SMS send failed:', smsErr);
    return res.status(502).json({
      success: false,
      message: 'İstek işlenemedi. Lütfen daha sonra tekrar deneyin.',
      code: 'REQUEST_FAILED',
    });
  }

  return res.status(200).json({
    success: true,
    message: FORGOT_SMS_SUCCESS_MESSAGE,
    method: 'sms',
    phoneHint: maskPhone(to),
    // Only exposed in local dry-run — never in production SMS delivery.
    ...(isDryRun() ? { devCode: code, dryRun: true } : {}),
  });
}

/**
 * POST /api/auth/reset-password/:token
 * Body: { newPassword: string }
 */
async function resetPassword(req, res, next) {
  try {
    const token = sanitizeToken(req.params?.token);
    const newPassword = sanitizePassword(req.body?.newPassword);

    if (!token) {
      return res.status(400).json({
        success: false,
        message: RESET_TOKEN_INVALID_MESSAGE,
        code: 'RESET_TOKEN_INVALID',
      });
    }

    if (newPassword.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        success: false,
        message: 'Şifre en az 8 karakter olmalıdır.',
        code: 'PASSWORD_TOO_SHORT',
      });
    }

    const hashedToken = hashResetToken(token);
    const User = getUserModel();
    const user = await User.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: RESET_TOKEN_INVALID_MESSAGE,
        code: 'RESET_TOKEN_INVALID',
      });
    }

    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    user.resetPasswordToken = null;
    user.resetPasswordExpires = null;
    user.resetSmsCodeHash = null;
    user.resetSmsExpires = null;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Şifreniz başarıyla güncellendi.',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/auth/reset-password-sms
 * Body: { phone, code, newPassword }  (email optional)
 */
async function resetPasswordSms(req, res, next) {
  try {
    const email = sanitizeEmail(req.body?.email);
    const phoneRaw =
      typeof req.body?.phone === 'string' ? req.body.phone.trim() : '';
    const phone = normalizePhone(phoneRaw);
    const code = sanitizeSmsCode(req.body?.code);
    const newPassword = sanitizePassword(req.body?.newPassword);

    if (!phone && (!email || !isValidEmailFormat(email))) {
      return res.status(400).json({
        success: false,
        message: 'Telefon numarası veya e-posta gerekli.',
      });
    }

    if (phoneRaw && !isValidPhoneFormat(phoneRaw)) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir telefon numarası girin.',
      });
    }

    if (!code) {
      return res.status(400).json({
        success: false,
        message: '4 haneli doğrulama kodunu girin.',
        code: 'SMS_CODE_INVALID',
      });
    }

    if (newPassword.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        success: false,
        message: 'Şifre en az 8 karakter olmalıdır.',
        code: 'PASSWORD_TOO_SHORT',
      });
    }

    const user = await findUserByEmailOrPhone({ email, phone });
    const codeOk =
      user &&
      user.resetSmsCodeHash === hashSmsCode(code) &&
      user.resetSmsExpires &&
      new Date(user.resetSmsExpires).getTime() > Date.now();

    if (!codeOk) {
      return res.status(400).json({
        success: false,
        message: RESET_SMS_INVALID_MESSAGE,
        code: 'SMS_CODE_INVALID',
      });
    }

    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    user.resetSmsCodeHash = null;
    user.resetSmsExpires = null;
    user.resetPasswordToken = null;
    user.resetPasswordExpires = null;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Şifreniz başarıyla güncellendi.',
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  forgotPassword,
  resetPassword,
  resetPasswordSms,
  hashResetToken,
};
