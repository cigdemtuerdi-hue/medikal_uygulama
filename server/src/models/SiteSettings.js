const mongoose = require('mongoose');
const { defaultSiteSettings } = require('./siteSettingsDefaults');

/**
 * Flexible CMS document — nested blocks stored as Mixed so admin can evolve
 * fields without a migration every time.
 */
const siteSettingsSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, default: 'global' },
    emergency: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().emergency },
    landing: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().landing },
    home: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().home },
    manifesto: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().manifesto },
    about: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().about },
    partner: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().partner },
    inquiry: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().inquiry },
    brand: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().brand },
    flags: { type: mongoose.Schema.Types.Mixed, default: () => defaultSiteSettings().flags },
    updatedAt: { type: Date, default: null },
    updatedBy: { type: String, default: null },
  },
  { minimize: false },
);

const SiteSettings =
  mongoose.models.SiteSettings ||
  mongoose.model('SiteSettings', siteSettingsSchema);

async function getOrCreateMongoSettings() {
  let doc = await SiteSettings.findOne({ key: 'global' });
  if (!doc) {
    doc = await SiteSettings.create(defaultSiteSettings());
  }
  return doc;
}

module.exports = {
  SiteSettings,
  getOrCreateMongoSettings,
};
