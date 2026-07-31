require('dotenv').config();

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const authRoutes = require('./routes/auth');
const MongoUser = require('./models/User');
const { MemoryUserModel } = require('./models/memoryUserStore');
const { setUserModel, getUserModel } = require('./models/userModel');

const PORT = Number(process.env.PORT) || 3001;
const MONGODB_URI =
  process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/medgift_us';
const USE_MEMORY =
  String(process.env.USE_MEMORY_DB || '').toLowerCase() === 'true' ||
  MONGODB_URI === 'memory';

/** Safe boot diagnostics for /api/health (never includes secrets). */
let dbStatus = {
  mode: 'starting',
  reason: 'booting',
  detail: null,
};

const app = express();

/**
 * CORS: production domains + any localhost / 127.0.0.1 Flutter web debug port.
 */
function isAllowedOrigin(origin) {
  if (!origin) return true;
  if (origin === 'https://medgift.us' || origin === 'https://www.medgift.us') {
    return true;
  }
  return /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
}

app.use(
  cors({
    origin(origin, callback) {
      if (isAllowedOrigin(origin)) return callback(null, true);
      return callback(new Error(`CORS blocked for origin: ${origin}`));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  }),
);
app.use(express.json({ limit: '128kb' }));

const { enforceTls } = require('./middleware/tls');
app.use(enforceTls);

app.get('/api/health', (_req, res) => {
  let db = 'unknown';
  try {
    db = getUserModel() === MemoryUserModel ? 'memory' : 'mongo';
  } catch (_) {
    db = 'starting';
  }

  const { isAdminConfigured } = require('./controllers/adminAuthController');
  const {
    isEmailConfigured,
    usesResend,
  } = require('./services/emailService');

  res.json({
    ok: true,
    service: 'medgift-us-api',
    db,
    dbReason: dbStatus.reason,
    dbDetail: dbStatus.detail,
    useMemoryEnv:
      String(process.env.USE_MEMORY_DB || '').toLowerCase() === 'true',
    mongoUriSet: Boolean(
      (process.env.MONGODB_URI || '').trim() &&
        process.env.MONGODB_URI !== 'memory',
    ),
    emailDryRun:
      String(process.env.EMAIL_DRY_RUN || '').toLowerCase() === 'true',
    adminConfigured: isAdminConfigured(),
    compliance: {
      phiEncryption: 'aes-256-gcm',
      tlsEnforced:
        String(process.env.NODE_ENV || '').toLowerCase() === 'production',
      hipaaNoticeVersion: 'hipaa-npp-2026.07',
      sessionIdleMinutes: 15,
    },
    messaging: {
      emailConfigured: isEmailConfigured(),
      emailProvider: usesResend()
        ? 'resend'
        : (process.env.EMAIL_HOST || '').trim()
          ? 'smtp'
          : null,
      emailHost: usesResend()
        ? 'api.resend.com'
        : (process.env.EMAIL_HOST || '').trim() || null,
      smsEnabled: false,
    },
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/settings', require('./routes/settings'));
app.use('/api/compliance', require('./routes/compliance'));
app.use('/api/health-records', require('./routes/healthRecords'));

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  // Never dump request bodies (may contain PHI) into logs.
  console.error('[api]', err?.name || 'Error', err?.message || err);
  const isCors = String(err.message || '').startsWith('CORS blocked');
  res.status(isCors ? 403 : err.status || 500).json({
    success: false,
    message: isCors ? 'İstek engellendi.' : err.message || 'Sunucu hatası.',
  });
});

async function seedDemoUserIfNeeded() {
  const email = (process.env.SEED_DEMO_USER_EMAIL || '').trim().toLowerCase();
  if (!email) return;

  const phone = (process.env.SEED_DEMO_USER_PHONE || '+15551234567').trim();
  // Memory-DB deploys wipe users on restart; keep a known demo password so login works.
  const seedPassword = (
    process.env.SEED_DEMO_USER_PASSWORD ||
    (USE_MEMORY ? 'MedGiftDemo1!' : '')
  ).trim();
  const bcrypt = require('bcrypt');
  const User = getUserModel();
  const existing = await User.findOne({ email });

  if (existing) {
    let changed = false;
    if (!existing.phone && phone) {
      existing.phone = phone;
      changed = true;
    }
    // Keep demo login working on memory restarts when a seed password is set.
    if (seedPassword && seedPassword.length >= 8) {
      existing.passwordHash = await bcrypt.hash(seedPassword, 10);
      changed = true;
    }
    if (changed) {
      await existing.save();
      console.info('[seed] Demo user updated (email redacted)');
    }
    return;
  }

  const doc = { email, phone, role: 'donor' };
  if (seedPassword && seedPassword.length >= 8) {
    doc.passwordHash = await bcrypt.hash(seedPassword, 10);
  }
  await User.create(doc);
  console.info(
    `[seed] Demo user created` +
      (doc.passwordHash ? ' (password set)' : ' (no password)'),
  );
}

function redactMongoUri(uri) {
  return String(uri || '').replace(
    /(mongodb(?:\+srv)?:\/\/[^:]+:)([^@]+)(@)/i,
    '$1***$3',
  );
}

async function resolveUserModel() {
  if (USE_MEMORY) {
    dbStatus = {
      mode: 'memory',
      reason: 'use_memory_flag',
      detail: 'USE_MEMORY_DB=true or MONGODB_URI=memory',
    };
    console.info('[db] Using in-memory store (USE_MEMORY_DB / MONGODB_URI=memory)');
    return MemoryUserModel;
  }

  if (!MONGODB_URI || MONGODB_URI === 'memory') {
    dbStatus = {
      mode: 'memory',
      reason: 'missing_uri',
      detail: 'MONGODB_URI is empty',
    };
    console.warn('[db] MONGODB_URI missing — using in-memory store.');
    return MemoryUserModel;
  }

  try {
    console.info('[db] Connecting to', redactMongoUri(MONGODB_URI));
    await mongoose.connect(MONGODB_URI, {
      // Atlas from Render free tier can be slow on cold start.
      serverSelectionTimeoutMS: 20000,
      connectTimeoutMS: 20000,
    });
    dbStatus = {
      mode: 'mongo',
      reason: 'connected',
      detail: null,
    };
    console.info('[db] Connected:', redactMongoUri(MONGODB_URI));
    return MongoUser;
  } catch (err) {
    const detail = String(err?.message || err).slice(0, 180);
    dbStatus = {
      mode: 'memory',
      reason: 'connect_failed',
      detail,
    };
    console.warn('[db] Mongo unavailable — falling back to in-memory store.');
    console.warn('[db] reason:', err?.name || 'Error', '-', err?.message || err);
    if (err?.reason?.type) {
      console.warn('[db] topology:', err.reason.type);
    }
    return MemoryUserModel;
  }
}

async function start() {
  setUserModel(await resolveUserModel());
  await seedDemoUserIfNeeded();

  app.listen(PORT, '0.0.0.0', () => {
    console.info(`[api] Listening on http://127.0.0.1:${PORT}`);
    console.info('[api] POST /api/auth/forgot-password');
    console.info('[api] POST /api/auth/reset-password/:token');
    console.info('[api] POST /api/auth/register');
    console.info('[api] POST /api/auth/login');
    console.info('[api] GET  /api/settings/public');
    console.info('[api] PUT  /api/settings/admin');
    console.info('[api] POST /api/compliance/consent');
    console.info('[api] POST /api/compliance/audit');
    console.info('[api] /api/health-records (RBAC + AES-256)');
  });
}

start().catch((err) => {
  console.error('[boot] Failed to start API:', err);
  process.exit(1);
});
