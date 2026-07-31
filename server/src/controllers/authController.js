const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { getUserModel } = require('../models/userModel');
const { sendPasswordResetEmail } = require('../services/emailService');

/** bcrypt cost factor — balance security vs latency on modest hosts. */
const BCRYPT_ROUNDS = 12;

/** Minimum accepted password length (matches Flutter client). */
const MIN_PASSWORD_LENGTH = 8;

const FORGOT_EMAIL_SUCCESS_MESSAGE =
  'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';

const RESET_TOKEN_INVALID_MESSAGE =
  'Sıfırlama bağlantısının süresi dolmuş veya geçersiz.';

function appOrigin() {
  const raw = (process.env.APP_ORIGIN || 'https://medgift.us').trim();
  return raw.replace(/\/$/, '');
}

function hashResetToken(rawToken) {
  return crypto.createHash('sha256').update(rawToken).digest('hex');
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

async function findUserByEmail(email) {
  const User = getUserModel();
  if (!email) return null;
  return User.findOne({ email });
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

async function clearResetToken(user) {
  user.resetPasswordToken = null;
  user.resetPasswordExpires = null;
  await user.save();
}

/**
 * POST /api/auth/forgot-password
 * Body: { email }
 */
async function forgotPassword(req, res, next) {
  try {
    const email = sanitizeEmail(req.body?.email);

    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir e-posta adresi girin.',
      });
    }

    const user = await findUserByEmail(email);
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
    return res.status(emailErr.status || 502).json({
      success: false,
      message:
        emailErr.message ||
        'İstek işlenemedi. Lütfen daha sonra tekrar deneyin.',
      code: emailErr.code || 'REQUEST_FAILED',
    });
  }

  return res.status(200).json({
    success: true,
    message: FORGOT_EMAIL_SUCCESS_MESSAGE,
    method: 'email',
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
 * Load a user including passwordHash (Mongoose selects it opt-in; memory always has it).
 */
async function findUserWithPassword(email) {
  const User = getUserModel();
  const result = User.findOne({ email });
  if (result && typeof result.select === 'function') {
    return result.select('+passwordHash');
  }
  return result;
}

/**
 * POST /api/auth/register
 * Body: { email, password, phone?, role?, hipaaConsentVersion?, hipaaConsentAccepted? }
 */
async function register(req, res, next) {
  try {
    const email = sanitizeEmail(req.body?.email);
    const password = sanitizePassword(req.body?.password);
    const phoneRaw =
      typeof req.body?.phone === 'string' ? req.body.phone.trim() : '';
    const phone = phoneRaw ? normalizePhone(phoneRaw) : '';
    const roleRaw =
      typeof req.body?.role === 'string' ? req.body.role.trim() : '';
    const allowedRoles = new Set(['donor', 'recipient', 'ngoPartner']);
    const role = allowedRoles.has(roleRaw) ? roleRaw : null;
    const hipaaAccepted = req.body?.hipaaConsentAccepted === true;
    const hipaaConsentVersion =
      typeof req.body?.hipaaConsentVersion === 'string'
        ? req.body.hipaaConsentVersion.trim()
        : null;

    if (!email || !isValidEmailFormat(email)) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir e-posta adresi girin.',
        code: 'EMAIL_INVALID',
      });
    }

    if (password.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        success: false,
        message: 'Şifre en az 8 karakter olmalıdır.',
        code: 'PASSWORD_TOO_SHORT',
      });
    }

    if (phoneRaw && !isValidPhoneFormat(phoneRaw)) {
      return res.status(400).json({
        success: false,
        message: 'Geçerli bir telefon numarası girin.',
        code: 'PHONE_INVALID',
      });
    }

    if (!hipaaAccepted) {
      return res.status(400).json({
        success: false,
        message: 'HIPAA privacy consent is required to create an account.',
        code: 'HIPAA_CONSENT_REQUIRED',
      });
    }

    const existing = await findUserWithPassword(email);
    if (existing?.passwordHash) {
      return res.status(409).json({
        success: false,
        message: 'Bu e-posta ile zaten bir hesap var. Giriş yapın.',
        code: 'EMAIL_TAKEN',
      });
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const consentAt = new Date();

    if (existing) {
      existing.passwordHash = passwordHash;
      if (phone) existing.phone = phone;
      if (role) existing.role = role;
      existing.hipaaConsentVersion = hipaaConsentVersion || 'hipaa-npp-2026.07';
      existing.hipaaConsentAt = consentAt;
      await existing.save();
      return res.status(200).json({
        success: true,
        message: 'Hesabınız oluşturuldu. Giriş yapabilirsiniz.',
        email,
        userId: String(existing._id),
      });
    }

    const User = getUserModel();
    const created = await User.create({
      email,
      phone: phone || null,
      passwordHash,
      role,
      hipaaConsentVersion: hipaaConsentVersion || 'hipaa-npp-2026.07',
      hipaaConsentAt: consentAt,
    });

    return res.status(201).json({
      success: true,
      message: 'Hesabınız oluşturuldu. Giriş yapabilirsiniz.',
      email,
      userId: String(created._id),
    });
  } catch (err) {
    if (err && (err.code === 11000 || /duplicate/i.test(String(err.message)))) {
      return res.status(409).json({
        success: false,
        message: 'Bu e-posta ile zaten bir hesap var. Giriş yapın.',
        code: 'EMAIL_TAKEN',
      });
    }
    return next(err);
  }
}

/**
 * POST /api/auth/login
 * Body: { email, password }
 */
async function login(req, res, next) {
  try {
    const email = sanitizeEmail(req.body?.email);
    const password = sanitizePassword(req.body?.password);

    if (!email || !isValidEmailFormat(email) || !password) {
      return res.status(400).json({
        success: false,
        message: 'E-posta ve şifre gerekli.',
        code: 'CREDENTIALS_REQUIRED',
      });
    }

    const user = await findUserWithPassword(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'E-posta veya şifre hatalı.',
        code: 'INVALID_CREDENTIALS',
      });
    }

    if (!user.passwordHash) {
      return res.status(401).json({
        success: false,
        message:
          'Bu hesap için henüz şifre belirlenmemiş. Şifre belirle / sıfırla adımını kullanın.',
        code: 'PASSWORD_NOT_SET',
      });
    }

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) {
      return res.status(401).json({
        success: false,
        message: 'E-posta veya şifre hatalı.',
        code: 'INVALID_CREDENTIALS',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Giriş başarılı.',
      email: user.email,
      userId: String(user._id),
      role: user.role || null,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  forgotPassword,
  resetPassword,
  register,
  login,
  hashResetToken,
};
