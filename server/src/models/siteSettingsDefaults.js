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
      crisisLabel: '',
    },
    landing: {
      welcomeTitle: '',
      welcomeSubtitle: '',
      loginCta: '',
      signupCta: '',
      forgotPasswordCta: '',
      newHereHint: '',
      aboutLinkLabel: '',
    },
    home: {
      title: '',
      subtitle: '',
      locationLabel: '',
      complianceBanner: '',
      browseTitle: '',
      browseBody: '',
      passItOnTitle: '',
      passItOnBody: '',
      quickActionsTitle: '',
      quickActionsSubtitle: '',
      donateDmeLabel: '',
      donateWoundCareLabel: '',
      browseCtaLabel: '',
      recentTitle: '',
      sponsorsTitle: '',
      sponsorsSubtitle: '',
      impactTitle: '',
      impactSubtitle: '',
      statItemsValue: '',
      statItemsLabel: '',
      statOrgsValue: '',
      statOrgsLabel: '',
      statAiValue: '',
      statAiLabel: '',
      statStatesValue: '',
      statStatesLabel: '',
    },
    manifesto: {
      eyebrow: '',
      title: '',
      subtitle: '',
      lead: '',
      ctaBody: '',
      ctaButton: '',
      readMoreLabel: '',
    },
    about: {
      appBarTitle: '',
      title: '',
      intro: '',
    },
    partner: {
      title: '',
      subtitle: '',
      contactEmail: 'info@medgift.us',
      contactLine: 'MedGift US · info@medgift.us',
      contactButton: '',
    },
    inquiry: {
      sheetTitle: '',
      sheetSubtitle: '',
      nameLabel: '',
      emailLabel: '',
      sendButton: '',
      successTitle: '',
      successBody: '',
      responseSla: '',
    },
    brand: {
      displayName: '',
      supportEmail: 'info@medgift.us',
      notifyEmail: 'info@medgift.us',
    },
    flags: {
      showAiChat: true,
      showEmergencyBanner: true,
      showPartnershipFooter: true,
      showManifesto: true,
      showAboutLink: true,
      showComplianceBanner: true,
      showHomeStats: true,
      showImpactCard: true,
      showBrowseEntry: true,
      showPassItOnEntry: true,
      showQuickActions: true,
      showSponsors: true,
      showRecentDonations: true,
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
    manifesto: d.manifesto,
    about: d.about,
    partner: d.partner,
    inquiry: d.inquiry,
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
