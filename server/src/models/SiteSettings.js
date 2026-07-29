const mongoose = require('mongoose');
const { defaultSiteSettings } = require('./siteSettingsDefaults');

const siteSettingsSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, default: 'global' },
    emergency: {
      enabled: { type: Boolean, default: true },
      bannerTitle: { type: String, default: '' },
      bannerBody: { type: String, default: '' },
    },
    landing: {
      welcomeTitle: { type: String, default: '' },
      welcomeSubtitle: { type: String, default: '' },
      loginCta: { type: String, default: '' },
      signupCta: { type: String, default: '' },
    },
    home: {
      title: { type: String, default: '' },
      subtitle: { type: String, default: '' },
    },
    partner: {
      title: { type: String, default: '' },
      subtitle: { type: String, default: '' },
      contactEmail: { type: String, default: 'info@medgift.us' },
      contactLine: { type: String, default: 'MedGift US · info@medgift.us' },
      contactButton: { type: String, default: '' },
    },
    brand: {
      supportEmail: { type: String, default: 'info@medgift.us' },
      notifyEmail: { type: String, default: 'info@medgift.us' },
    },
    flags: {
      showAiChat: { type: Boolean, default: true },
      showEmergencyBanner: { type: Boolean, default: true },
      showPartnershipFooter: { type: Boolean, default: true },
    },
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
