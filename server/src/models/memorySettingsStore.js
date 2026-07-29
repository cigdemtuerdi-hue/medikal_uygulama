const {
  defaultSiteSettings,
  deepMerge,
} = require('./siteSettingsDefaults');

/** In-memory CMS store (lost on Render restart unless Mongo is connected). */
let memoryDoc = defaultSiteSettings();

const MemorySettingsStore = {
  async get() {
    return { ...deepMerge(defaultSiteSettings(), memoryDoc) };
  },

  async save(patch, updatedBy) {
    memoryDoc = deepMerge(await this.get(), patch || {});
    memoryDoc.key = 'global';
    memoryDoc.updatedAt = new Date().toISOString();
    memoryDoc.updatedBy = updatedBy || null;
    return { ...memoryDoc };
  },

  _reset() {
    memoryDoc = defaultSiteSettings();
  },
};

module.exports = { MemorySettingsStore };
