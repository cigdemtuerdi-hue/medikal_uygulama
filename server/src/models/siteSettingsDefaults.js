/**
 * Default public site settings (CMS). Empty strings mean “use l10n fallback”.
 */
function defaultSiteSettings() {
  return {
    key: 'global',
    emergency: {
      enabled: true,
      bannerTitle: '',
      bannerBody: '',
    },
    landing: {
      welcomeTitle: '',
      welcomeSubtitle: '',
      loginCta: '',
      signupCta: '',
    },
    home: {
      title: '',
      subtitle: '',
    },
    partner: {
      title: '',
      subtitle: '',
      contactEmail: 'info@medgift.us',
      contactLine: 'MedGift US · info@medgift.us',
      contactButton: '',
    },
    brand: {
      supportEmail: 'info@medgift.us',
      notifyEmail: 'info@medgift.us',
    },
    flags: {
      showAiChat: true,
      showEmergencyBanner: true,
      showPartnershipFooter: true,
    },
    updatedAt: null,
    updatedBy: null,
  };
}

function deepMerge(base, patch) {
  if (patch == null || typeof patch !== 'object' || Array.isArray(patch)) {
    return patch === undefined ? base : patch;
  }
  const out = { ...base };
  for (const [k, v] of Object.entries(patch)) {
    if (
      v &&
      typeof v === 'object' &&
      !Array.isArray(v) &&
      base[k] &&
      typeof base[k] === 'object' &&
      !Array.isArray(base[k])
    ) {
      out[k] = deepMerge(base[k], v);
    } else if (v !== undefined) {
      out[k] = v;
    }
  }
  return out;
}

function publicProjection(doc) {
  const d = deepMerge(defaultSiteSettings(), doc || {});
  return {
    emergency: d.emergency,
    landing: d.landing,
    home: d.home,
    partner: d.partner,
    brand: d.brand,
    flags: d.flags,
    updatedAt: d.updatedAt,
  };
}

module.exports = {
  defaultSiteSettings,
  deepMerge,
  publicProjection,
};
