const mongoose = require('mongoose');
const {
  defaultSiteSettings,
  deepMerge,
  publicProjection,
} = require('../models/siteSettingsDefaults');
const {
  SiteSettings,
  getOrCreateMongoSettings,
} = require('../models/SiteSettings');
const { MemorySettingsStore } = require('../models/memorySettingsStore');

function usingMongo() {
  return mongoose.connection.readyState === 1;
}

async function loadSettingsDoc() {
  if (usingMongo()) {
    const doc = await getOrCreateMongoSettings();
    return doc.toObject ? doc.toObject() : doc;
  }
  return MemorySettingsStore.get();
}

async function saveSettingsDoc(patch, updatedBy) {
  if (usingMongo()) {
    const current = await getOrCreateMongoSettings();
    const merged = deepMerge(
      current.toObject ? current.toObject() : current,
      patch || {},
    );
    merged.key = 'global';
    merged.updatedAt = new Date();
    merged.updatedBy = updatedBy || null;

    current.set(merged);
    await current.save();
    return current.toObject();
  }
  return MemorySettingsStore.save(patch, updatedBy);
}

/**
 * GET /api/settings/public — no auth
 */
async function getPublicSettings(_req, res, next) {
  try {
    const doc = await loadSettingsDoc();
    return res.status(200).json({
      success: true,
      settings: publicProjection(doc),
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/admin/settings — admin auth
 */
async function getAdminSettings(_req, res, next) {
  try {
    const doc = await loadSettingsDoc();
    return res.status(200).json({
      success: true,
      settings: deepMerge(defaultSiteSettings(), doc),
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * PUT /api/admin/settings — admin auth
 * Body: partial settings object (emergency, landing, home, partner, brand, flags)
 */
async function putAdminSettings(req, res, next) {
  try {
    const body = req.body || {};
    const allowed = {};
    for (const key of [
      'emergency',
      'landing',
      'home',
      'partner',
      'brand',
      'flags',
    ]) {
      if (body[key] != null && typeof body[key] === 'object') {
        allowed[key] = body[key];
      }
    }

    const updatedBy = req.admin?.email || null;
    const saved = await saveSettingsDoc(allowed, updatedBy);

    return res.status(200).json({
      success: true,
      message: 'Ayarlar kaydedildi.',
      settings: publicProjection(saved),
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getPublicSettings,
  getAdminSettings,
  putAdminSettings,
  loadSettingsDoc,
};
