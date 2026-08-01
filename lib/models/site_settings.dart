// Remote CMS settings for MedGift US (from `/api/settings/public`).
// Empty strings mean “use l10n fallback” via SiteSettingsService.text.

String _s(Map<String, dynamic> json, String key, [String fallback = '']) =>
    (json[key] as String?)?.trim() ?? fallback;

bool _b(Map<String, dynamic> json, String key, [bool fallback = true]) =>
    json[key] as bool? ?? fallback;

class SiteSettings {
  const SiteSettings({
    required this.emergency,
    required this.landing,
    required this.home,
    required this.manifesto,
    required this.about,
    required this.partner,
    required this.inquiry,
    required this.brand,
    required this.flags,
    this.updatedAt,
    this.persistence = 'memory',
  });

  final EmergencySettings emergency;
  final LandingSettings landing;
  final HomeSettings home;
  final ManifestoSettings manifesto;
  final AboutSettings about;
  final PartnerSettings partner;
  final InquirySettings inquiry;
  final BrandSettings brand;
  final FeatureFlags flags;
  final DateTime? updatedAt;
  final String persistence;

  factory SiteSettings.defaults() => SiteSettings(
        emergency: EmergencySettings.defaults(),
        landing: LandingSettings.defaults(),
        home: HomeSettings.defaults(),
        manifesto: ManifestoSettings.defaults(),
        about: AboutSettings.defaults(),
        partner: PartnerSettings.defaults(),
        inquiry: InquirySettings.defaults(),
        brand: BrandSettings.defaults(),
        flags: FeatureFlags.defaults(),
      );

  factory SiteSettings.fromJson(
    Map<String, dynamic> json, {
    String persistence = 'memory',
  }) {
    Map<String, dynamic> block(String key) =>
        Map<String, dynamic>.from(json[key] as Map? ?? {});

    return SiteSettings(
      emergency: EmergencySettings.fromJson(block('emergency')),
      landing: LandingSettings.fromJson(block('landing')),
      home: HomeSettings.fromJson(block('home')),
      manifesto: ManifestoSettings.fromJson(block('manifesto')),
      about: AboutSettings.fromJson(block('about')),
      partner: PartnerSettings.fromJson(block('partner')),
      inquiry: InquirySettings.fromJson(block('inquiry')),
      brand: BrandSettings.fromJson(block('brand')),
      flags: FeatureFlags.fromJson(block('flags')),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      persistence: persistence,
    );
  }

  Map<String, dynamic> toJson() => {
        'emergency': emergency.toJson(),
        'landing': landing.toJson(),
        'home': home.toJson(),
        'manifesto': manifesto.toJson(),
        'about': about.toJson(),
        'partner': partner.toJson(),
        'inquiry': inquiry.toJson(),
        'brand': brand.toJson(),
        'flags': flags.toJson(),
      };

  SiteSettings copyWith({
    EmergencySettings? emergency,
    LandingSettings? landing,
    HomeSettings? home,
    ManifestoSettings? manifesto,
    AboutSettings? about,
    PartnerSettings? partner,
    InquirySettings? inquiry,
    BrandSettings? brand,
    FeatureFlags? flags,
    DateTime? updatedAt,
    String? persistence,
  }) {
    return SiteSettings(
      emergency: emergency ?? this.emergency,
      landing: landing ?? this.landing,
      home: home ?? this.home,
      manifesto: manifesto ?? this.manifesto,
      about: about ?? this.about,
      partner: partner ?? this.partner,
      inquiry: inquiry ?? this.inquiry,
      brand: brand ?? this.brand,
      flags: flags ?? this.flags,
      updatedAt: updatedAt ?? this.updatedAt,
      persistence: persistence ?? this.persistence,
    );
  }
}

class EmergencySettings {
  const EmergencySettings({
    required this.enabled,
    required this.bannerTitle,
    required this.bannerBody,
    required this.crisisLabel,
  });

  final bool enabled;
  final String bannerTitle;
  final String bannerBody;
  final String crisisLabel;

  factory EmergencySettings.defaults() => const EmergencySettings(
        enabled: true,
        bannerTitle: '',
        bannerBody: '',
        crisisLabel: '',
      );

  factory EmergencySettings.fromJson(Map<String, dynamic> json) =>
      EmergencySettings(
        enabled: _b(json, 'enabled'),
        bannerTitle: _s(json, 'bannerTitle'),
        bannerBody: _s(json, 'bannerBody'),
        crisisLabel: _s(json, 'crisisLabel'),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'bannerTitle': bannerTitle,
        'bannerBody': bannerBody,
        'crisisLabel': crisisLabel,
      };

  EmergencySettings copyWith({
    bool? enabled,
    String? bannerTitle,
    String? bannerBody,
    String? crisisLabel,
  }) =>
      EmergencySettings(
        enabled: enabled ?? this.enabled,
        bannerTitle: bannerTitle ?? this.bannerTitle,
        bannerBody: bannerBody ?? this.bannerBody,
        crisisLabel: crisisLabel ?? this.crisisLabel,
      );
}

class LandingSettings {
  const LandingSettings({
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.loginCta,
    required this.signupCta,
    required this.forgotPasswordCta,
    required this.newHereHint,
    required this.aboutLinkLabel,
  });

  final String welcomeTitle;
  final String welcomeSubtitle;
  final String loginCta;
  final String signupCta;
  final String forgotPasswordCta;
  final String newHereHint;
  final String aboutLinkLabel;

  factory LandingSettings.defaults() => const LandingSettings(
        welcomeTitle: '',
        welcomeSubtitle: '',
        loginCta: '',
        signupCta: '',
        forgotPasswordCta: '',
        newHereHint: '',
        aboutLinkLabel: '',
      );

  factory LandingSettings.fromJson(Map<String, dynamic> json) =>
      LandingSettings(
        welcomeTitle: _s(json, 'welcomeTitle'),
        welcomeSubtitle: _s(json, 'welcomeSubtitle'),
        loginCta: _s(json, 'loginCta'),
        signupCta: _s(json, 'signupCta'),
        forgotPasswordCta: _s(json, 'forgotPasswordCta'),
        newHereHint: _s(json, 'newHereHint'),
        aboutLinkLabel: _s(json, 'aboutLinkLabel'),
      );

  Map<String, dynamic> toJson() => {
        'welcomeTitle': welcomeTitle,
        'welcomeSubtitle': welcomeSubtitle,
        'loginCta': loginCta,
        'signupCta': signupCta,
        'forgotPasswordCta': forgotPasswordCta,
        'newHereHint': newHereHint,
        'aboutLinkLabel': aboutLinkLabel,
      };

  LandingSettings copyWith({
    String? welcomeTitle,
    String? welcomeSubtitle,
    String? loginCta,
    String? signupCta,
    String? forgotPasswordCta,
    String? newHereHint,
    String? aboutLinkLabel,
  }) =>
      LandingSettings(
        welcomeTitle: welcomeTitle ?? this.welcomeTitle,
        welcomeSubtitle: welcomeSubtitle ?? this.welcomeSubtitle,
        loginCta: loginCta ?? this.loginCta,
        signupCta: signupCta ?? this.signupCta,
        forgotPasswordCta: forgotPasswordCta ?? this.forgotPasswordCta,
        newHereHint: newHereHint ?? this.newHereHint,
        aboutLinkLabel: aboutLinkLabel ?? this.aboutLinkLabel,
      );
}

class HomeSettings {
  const HomeSettings({
    required this.title,
    required this.subtitle,
    required this.locationLabel,
    required this.complianceBanner,
    required this.browseTitle,
    required this.browseBody,
    required this.passItOnTitle,
    required this.passItOnBody,
    required this.quickActionsTitle,
    required this.quickActionsSubtitle,
    required this.donateDmeLabel,
    required this.donateWoundCareLabel,
    required this.browseCtaLabel,
    required this.recentTitle,
    required this.sponsorsTitle,
    required this.sponsorsSubtitle,
    required this.impactTitle,
    required this.impactSubtitle,
    required this.statItemsValue,
    required this.statItemsLabel,
    required this.statOrgsValue,
    required this.statOrgsLabel,
    required this.statAiValue,
    required this.statAiLabel,
    required this.statStatesValue,
    required this.statStatesLabel,
  });

  final String title;
  final String subtitle;
  final String locationLabel;
  final String complianceBanner;
  final String browseTitle;
  final String browseBody;
  final String passItOnTitle;
  final String passItOnBody;
  final String quickActionsTitle;
  final String quickActionsSubtitle;
  final String donateDmeLabel;
  final String donateWoundCareLabel;
  final String browseCtaLabel;
  final String recentTitle;
  final String sponsorsTitle;
  final String sponsorsSubtitle;
  final String impactTitle;
  final String impactSubtitle;
  final String statItemsValue;
  final String statItemsLabel;
  final String statOrgsValue;
  final String statOrgsLabel;
  final String statAiValue;
  final String statAiLabel;
  final String statStatesValue;
  final String statStatesLabel;

  factory HomeSettings.defaults() => const HomeSettings(
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
      );

  factory HomeSettings.fromJson(Map<String, dynamic> json) => HomeSettings(
        title: _s(json, 'title'),
        subtitle: _s(json, 'subtitle'),
        locationLabel: _s(json, 'locationLabel'),
        complianceBanner: _s(json, 'complianceBanner'),
        browseTitle: _s(json, 'browseTitle'),
        browseBody: _s(json, 'browseBody'),
        passItOnTitle: _s(json, 'passItOnTitle'),
        passItOnBody: _s(json, 'passItOnBody'),
        quickActionsTitle: _s(json, 'quickActionsTitle'),
        quickActionsSubtitle: _s(json, 'quickActionsSubtitle'),
        donateDmeLabel: _s(json, 'donateDmeLabel'),
        donateWoundCareLabel: _s(json, 'donateWoundCareLabel'),
        browseCtaLabel: _s(json, 'browseCtaLabel'),
        recentTitle: _s(json, 'recentTitle'),
        sponsorsTitle: _s(json, 'sponsorsTitle'),
        sponsorsSubtitle: _s(json, 'sponsorsSubtitle'),
        impactTitle: _s(json, 'impactTitle'),
        impactSubtitle: _s(json, 'impactSubtitle'),
        statItemsValue: _s(json, 'statItemsValue'),
        statItemsLabel: _s(json, 'statItemsLabel'),
        statOrgsValue: _s(json, 'statOrgsValue'),
        statOrgsLabel: _s(json, 'statOrgsLabel'),
        statAiValue: _s(json, 'statAiValue'),
        statAiLabel: _s(json, 'statAiLabel'),
        statStatesValue: _s(json, 'statStatesValue'),
        statStatesLabel: _s(json, 'statStatesLabel'),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'locationLabel': locationLabel,
        'complianceBanner': complianceBanner,
        'browseTitle': browseTitle,
        'browseBody': browseBody,
        'passItOnTitle': passItOnTitle,
        'passItOnBody': passItOnBody,
        'quickActionsTitle': quickActionsTitle,
        'quickActionsSubtitle': quickActionsSubtitle,
        'donateDmeLabel': donateDmeLabel,
        'donateWoundCareLabel': donateWoundCareLabel,
        'browseCtaLabel': browseCtaLabel,
        'recentTitle': recentTitle,
        'sponsorsTitle': sponsorsTitle,
        'sponsorsSubtitle': sponsorsSubtitle,
        'impactTitle': impactTitle,
        'impactSubtitle': impactSubtitle,
        'statItemsValue': statItemsValue,
        'statItemsLabel': statItemsLabel,
        'statOrgsValue': statOrgsValue,
        'statOrgsLabel': statOrgsLabel,
        'statAiValue': statAiValue,
        'statAiLabel': statAiLabel,
        'statStatesValue': statStatesValue,
        'statStatesLabel': statStatesLabel,
      };

  HomeSettings copyWith({
    String? title,
    String? subtitle,
    String? locationLabel,
    String? complianceBanner,
    String? browseTitle,
    String? browseBody,
    String? passItOnTitle,
    String? passItOnBody,
    String? quickActionsTitle,
    String? quickActionsSubtitle,
    String? donateDmeLabel,
    String? donateWoundCareLabel,
    String? browseCtaLabel,
    String? recentTitle,
    String? sponsorsTitle,
    String? sponsorsSubtitle,
    String? impactTitle,
    String? impactSubtitle,
    String? statItemsValue,
    String? statItemsLabel,
    String? statOrgsValue,
    String? statOrgsLabel,
    String? statAiValue,
    String? statAiLabel,
    String? statStatesValue,
    String? statStatesLabel,
  }) =>
      HomeSettings(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        locationLabel: locationLabel ?? this.locationLabel,
        complianceBanner: complianceBanner ?? this.complianceBanner,
        browseTitle: browseTitle ?? this.browseTitle,
        browseBody: browseBody ?? this.browseBody,
        passItOnTitle: passItOnTitle ?? this.passItOnTitle,
        passItOnBody: passItOnBody ?? this.passItOnBody,
        quickActionsTitle: quickActionsTitle ?? this.quickActionsTitle,
        quickActionsSubtitle: quickActionsSubtitle ?? this.quickActionsSubtitle,
        donateDmeLabel: donateDmeLabel ?? this.donateDmeLabel,
        donateWoundCareLabel: donateWoundCareLabel ?? this.donateWoundCareLabel,
        browseCtaLabel: browseCtaLabel ?? this.browseCtaLabel,
        recentTitle: recentTitle ?? this.recentTitle,
        sponsorsTitle: sponsorsTitle ?? this.sponsorsTitle,
        sponsorsSubtitle: sponsorsSubtitle ?? this.sponsorsSubtitle,
        impactTitle: impactTitle ?? this.impactTitle,
        impactSubtitle: impactSubtitle ?? this.impactSubtitle,
        statItemsValue: statItemsValue ?? this.statItemsValue,
        statItemsLabel: statItemsLabel ?? this.statItemsLabel,
        statOrgsValue: statOrgsValue ?? this.statOrgsValue,
        statOrgsLabel: statOrgsLabel ?? this.statOrgsLabel,
        statAiValue: statAiValue ?? this.statAiValue,
        statAiLabel: statAiLabel ?? this.statAiLabel,
        statStatesValue: statStatesValue ?? this.statStatesValue,
        statStatesLabel: statStatesLabel ?? this.statStatesLabel,
      );
}

class ManifestoSettings {
  const ManifestoSettings({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.lead,
    required this.ctaBody,
    required this.ctaButton,
    required this.readMoreLabel,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String lead;
  final String ctaBody;
  final String ctaButton;
  final String readMoreLabel;

  factory ManifestoSettings.defaults() => const ManifestoSettings(
        eyebrow: '',
        title: '',
        subtitle: '',
        lead: '',
        ctaBody: '',
        ctaButton: '',
        readMoreLabel: '',
      );

  factory ManifestoSettings.fromJson(Map<String, dynamic> json) =>
      ManifestoSettings(
        eyebrow: _s(json, 'eyebrow'),
        title: _s(json, 'title'),
        subtitle: _s(json, 'subtitle'),
        lead: _s(json, 'lead'),
        ctaBody: _s(json, 'ctaBody'),
        ctaButton: _s(json, 'ctaButton'),
        readMoreLabel: _s(json, 'readMoreLabel'),
      );

  Map<String, dynamic> toJson() => {
        'eyebrow': eyebrow,
        'title': title,
        'subtitle': subtitle,
        'lead': lead,
        'ctaBody': ctaBody,
        'ctaButton': ctaButton,
        'readMoreLabel': readMoreLabel,
      };

  ManifestoSettings copyWith({
    String? eyebrow,
    String? title,
    String? subtitle,
    String? lead,
    String? ctaBody,
    String? ctaButton,
    String? readMoreLabel,
  }) =>
      ManifestoSettings(
        eyebrow: eyebrow ?? this.eyebrow,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        lead: lead ?? this.lead,
        ctaBody: ctaBody ?? this.ctaBody,
        ctaButton: ctaButton ?? this.ctaButton,
        readMoreLabel: readMoreLabel ?? this.readMoreLabel,
      );
}

class AboutSettings {
  const AboutSettings({
    required this.appBarTitle,
    required this.title,
    required this.intro,
  });

  final String appBarTitle;
  final String title;
  final String intro;

  factory AboutSettings.defaults() =>
      const AboutSettings(appBarTitle: '', title: '', intro: '');

  factory AboutSettings.fromJson(Map<String, dynamic> json) => AboutSettings(
        appBarTitle: _s(json, 'appBarTitle'),
        title: _s(json, 'title'),
        intro: _s(json, 'intro'),
      );

  Map<String, dynamic> toJson() => {
        'appBarTitle': appBarTitle,
        'title': title,
        'intro': intro,
      };

  AboutSettings copyWith({
    String? appBarTitle,
    String? title,
    String? intro,
  }) =>
      AboutSettings(
        appBarTitle: appBarTitle ?? this.appBarTitle,
        title: title ?? this.title,
        intro: intro ?? this.intro,
      );
}

class PartnerSettings {
  const PartnerSettings({
    required this.title,
    required this.subtitle,
    required this.contactEmail,
    required this.contactLine,
    required this.contactButton,
  });

  final String title;
  final String subtitle;
  final String contactEmail;
  final String contactLine;
  final String contactButton;

  factory PartnerSettings.defaults() => const PartnerSettings(
        title: '',
        subtitle: '',
        contactEmail: 'info@medgift.us',
        contactLine: 'MedGift US · info@medgift.us',
        contactButton: '',
      );

  factory PartnerSettings.fromJson(Map<String, dynamic> json) =>
      PartnerSettings(
        title: _s(json, 'title'),
        subtitle: _s(json, 'subtitle'),
        contactEmail: _s(json, 'contactEmail', 'info@medgift.us'),
        contactLine: _s(json, 'contactLine', 'MedGift US · info@medgift.us'),
        contactButton: _s(json, 'contactButton'),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'contactEmail': contactEmail,
        'contactLine': contactLine,
        'contactButton': contactButton,
      };

  PartnerSettings copyWith({
    String? title,
    String? subtitle,
    String? contactEmail,
    String? contactLine,
    String? contactButton,
  }) =>
      PartnerSettings(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        contactEmail: contactEmail ?? this.contactEmail,
        contactLine: contactLine ?? this.contactLine,
        contactButton: contactButton ?? this.contactButton,
      );
}

class InquirySettings {
  const InquirySettings({
    required this.sheetTitle,
    required this.sheetSubtitle,
    required this.nameLabel,
    required this.emailLabel,
    required this.sendButton,
    required this.successTitle,
    required this.successBody,
    required this.responseSla,
  });

  final String sheetTitle;
  final String sheetSubtitle;
  final String nameLabel;
  final String emailLabel;
  final String sendButton;
  final String successTitle;
  final String successBody;
  final String responseSla;

  factory InquirySettings.defaults() => const InquirySettings(
        sheetTitle: '',
        sheetSubtitle: '',
        nameLabel: '',
        emailLabel: '',
        sendButton: '',
        successTitle: '',
        successBody: '',
        responseSla: '',
      );

  factory InquirySettings.fromJson(Map<String, dynamic> json) =>
      InquirySettings(
        sheetTitle: _s(json, 'sheetTitle'),
        sheetSubtitle: _s(json, 'sheetSubtitle'),
        nameLabel: _s(json, 'nameLabel'),
        emailLabel: _s(json, 'emailLabel'),
        sendButton: _s(json, 'sendButton'),
        successTitle: _s(json, 'successTitle'),
        successBody: _s(json, 'successBody'),
        responseSla: _s(json, 'responseSla'),
      );

  Map<String, dynamic> toJson() => {
        'sheetTitle': sheetTitle,
        'sheetSubtitle': sheetSubtitle,
        'nameLabel': nameLabel,
        'emailLabel': emailLabel,
        'sendButton': sendButton,
        'successTitle': successTitle,
        'successBody': successBody,
        'responseSla': responseSla,
      };

  InquirySettings copyWith({
    String? sheetTitle,
    String? sheetSubtitle,
    String? nameLabel,
    String? emailLabel,
    String? sendButton,
    String? successTitle,
    String? successBody,
    String? responseSla,
  }) =>
      InquirySettings(
        sheetTitle: sheetTitle ?? this.sheetTitle,
        sheetSubtitle: sheetSubtitle ?? this.sheetSubtitle,
        nameLabel: nameLabel ?? this.nameLabel,
        emailLabel: emailLabel ?? this.emailLabel,
        sendButton: sendButton ?? this.sendButton,
        successTitle: successTitle ?? this.successTitle,
        successBody: successBody ?? this.successBody,
        responseSla: responseSla ?? this.responseSla,
      );
}

class BrandSettings {
  const BrandSettings({
    required this.displayName,
    required this.supportEmail,
    required this.notifyEmail,
  });

  final String displayName;
  final String supportEmail;
  final String notifyEmail;

  factory BrandSettings.defaults() => const BrandSettings(
        displayName: '',
        supportEmail: 'info@medgift.us',
        notifyEmail: 'info@medgift.us',
      );

  factory BrandSettings.fromJson(Map<String, dynamic> json) => BrandSettings(
        displayName: _s(json, 'displayName'),
        supportEmail: _s(json, 'supportEmail', 'info@medgift.us'),
        notifyEmail: _s(json, 'notifyEmail', 'info@medgift.us'),
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'supportEmail': supportEmail,
        'notifyEmail': notifyEmail,
      };

  BrandSettings copyWith({
    String? displayName,
    String? supportEmail,
    String? notifyEmail,
  }) =>
      BrandSettings(
        displayName: displayName ?? this.displayName,
        supportEmail: supportEmail ?? this.supportEmail,
        notifyEmail: notifyEmail ?? this.notifyEmail,
      );
}

class FeatureFlags {
  const FeatureFlags({
    required this.showAiChat,
    required this.showEmergencyBanner,
    required this.showPartnershipFooter,
    required this.showManifesto,
    required this.showAboutLink,
    required this.showComplianceBanner,
    required this.showHomeStats,
    required this.showImpactCard,
    required this.showBrowseEntry,
    required this.showPassItOnEntry,
    required this.showQuickActions,
    required this.showSponsors,
    required this.showRecentDonations,
  });

  final bool showAiChat;
  final bool showEmergencyBanner;
  final bool showPartnershipFooter;
  final bool showManifesto;
  final bool showAboutLink;
  final bool showComplianceBanner;
  final bool showHomeStats;
  final bool showImpactCard;
  final bool showBrowseEntry;
  final bool showPassItOnEntry;
  final bool showQuickActions;
  final bool showSponsors;
  final bool showRecentDonations;

  factory FeatureFlags.defaults() => const FeatureFlags(
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
      );

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
        showAiChat: _b(json, 'showAiChat'),
        showEmergencyBanner: _b(json, 'showEmergencyBanner'),
        showPartnershipFooter: _b(json, 'showPartnershipFooter'),
        showManifesto: _b(json, 'showManifesto'),
        showAboutLink: _b(json, 'showAboutLink'),
        showComplianceBanner: _b(json, 'showComplianceBanner'),
        showHomeStats: _b(json, 'showHomeStats'),
        showImpactCard: _b(json, 'showImpactCard'),
        showBrowseEntry: _b(json, 'showBrowseEntry'),
        showPassItOnEntry: _b(json, 'showPassItOnEntry'),
        showQuickActions: _b(json, 'showQuickActions'),
        showSponsors: _b(json, 'showSponsors'),
        showRecentDonations: _b(json, 'showRecentDonations'),
      );

  Map<String, dynamic> toJson() => {
        'showAiChat': showAiChat,
        'showEmergencyBanner': showEmergencyBanner,
        'showPartnershipFooter': showPartnershipFooter,
        'showManifesto': showManifesto,
        'showAboutLink': showAboutLink,
        'showComplianceBanner': showComplianceBanner,
        'showHomeStats': showHomeStats,
        'showImpactCard': showImpactCard,
        'showBrowseEntry': showBrowseEntry,
        'showPassItOnEntry': showPassItOnEntry,
        'showQuickActions': showQuickActions,
        'showSponsors': showSponsors,
        'showRecentDonations': showRecentDonations,
      };

  FeatureFlags copyWith({
    bool? showAiChat,
    bool? showEmergencyBanner,
    bool? showPartnershipFooter,
    bool? showManifesto,
    bool? showAboutLink,
    bool? showComplianceBanner,
    bool? showHomeStats,
    bool? showImpactCard,
    bool? showBrowseEntry,
    bool? showPassItOnEntry,
    bool? showQuickActions,
    bool? showSponsors,
    bool? showRecentDonations,
  }) =>
      FeatureFlags(
        showAiChat: showAiChat ?? this.showAiChat,
        showEmergencyBanner: showEmergencyBanner ?? this.showEmergencyBanner,
        showPartnershipFooter:
            showPartnershipFooter ?? this.showPartnershipFooter,
        showManifesto: showManifesto ?? this.showManifesto,
        showAboutLink: showAboutLink ?? this.showAboutLink,
        showComplianceBanner: showComplianceBanner ?? this.showComplianceBanner,
        showHomeStats: showHomeStats ?? this.showHomeStats,
        showImpactCard: showImpactCard ?? this.showImpactCard,
        showBrowseEntry: showBrowseEntry ?? this.showBrowseEntry,
        showPassItOnEntry: showPassItOnEntry ?? this.showPassItOnEntry,
        showQuickActions: showQuickActions ?? this.showQuickActions,
        showSponsors: showSponsors ?? this.showSponsors,
        showRecentDonations: showRecentDonations ?? this.showRecentDonations,
      );
}
