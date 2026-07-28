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
app.use(express.json({ limit: '32kb' }));

app.get('/api/health', (_req, res) => {
  let db = 'unknown';
  try {
    db = getUserModel() === MemoryUserModel ? 'memory' : 'mongo';
  } catch (_) {
    db = 'starting';
  }
  res.json({
    ok: true,
    service: 'medgift-us-api',
    db,
    emailDryRun:
      String(process.env.EMAIL_DRY_RUN || '').toLowerCase() === 'true',
  });
});

app.use('/api/auth', authRoutes);

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('[api]', err);
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
  const User = getUserModel();
  const existing = await User.findOne({ email });
  if (existing) {
    if (!existing.phone && phone) {
      existing.phone = phone;
      await existing.save();
      console.info(`[seed] Demo user phone updated: ${email} → ${phone}`);
    }
    return;
  }

  await User.create({ email, phone });
  console.info(`[seed] Demo user created: ${email} phone=${phone}`);
}

async function resolveUserModel() {
  if (USE_MEMORY) {
    console.info('[db] Using in-memory store (USE_MEMORY_DB / MONGODB_URI=memory)');
    return MemoryUserModel;
  }

  try {
    await mongoose.connect(MONGODB_URI, {
      serverSelectionTimeoutMS: 2500,
    });
    console.info('[db] Connected:', MONGODB_URI);
    return MongoUser;
  } catch (err) {
    console.warn('[db] Mongo unavailable — falling back to in-memory store.');
    console.warn('[db]', err.message);
    return MemoryUserModel;
  }
}

async function start() {
  setUserModel(await resolveUserModel());
  await seedDemoUserIfNeeded();

  app.listen(PORT, '0.0.0.0', () => {
    console.info(`[api] Listening on http://127.0.0.1:${PORT}`);
    console.info('[api] POST /api/auth/forgot-password  (method=email|sms)');
    console.info('[api] POST /api/auth/reset-password/:token');
    console.info('[api] POST /api/auth/reset-password-sms');
  });
}

start().catch((err) => {
  console.error('[boot] Failed to start API:', err);
  process.exit(1);
});
