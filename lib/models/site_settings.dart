/// Remote CMS settings for MedGift US (from `/api/settings/public`).
class SiteSettings {
  const SiteSettings({
    required this.emergency,
    required this.landing,
    required this.home,
    required this.partner,
    required this.brand,
    required this.flags,
    this.updatedAt,
    this.persistence = 'memory',
  });

  final EmergencySettings emergency;
  final LandingSettings landing;
  final HomeSettings home;
  final PartnerSettings partner;
  final BrandSettings brand;
  final FeatureFlags flags;
  final DateTime? updatedAt;
  final String persistence;

  factory SiteSettings.defaults() => SiteSettings(
        emergency: EmergencySettings.defaults(),
        landing: LandingSettings.defaults(),
        home: HomeSettings.defaults(),
        partner: PartnerSettings.defaults(),
        brand: BrandSettings.defaults(),
        flags: FeatureFlags.defaults(),
      );

  factory SiteSettings.fromJson(
    Map<String, dynamic> json, {
    String persistence = 'memory',
  }) {
    return SiteSettings(
      emergency: EmergencySettings.fromJson(
        Map<String, dynamic>.from(json['emergency'] as Map? ?? {}),
      ),
      landing: LandingSettings.fromJson(
        Map<String, dynamic>.from(json['landing'] as Map? ?? {}),
      ),
      home: HomeSettings.fromJson(
        Map<String, dynamic>.from(json['home'] as Map? ?? {}),
      ),
      partner: PartnerSettings.fromJson(
        Map<String, dynamic>.from(json['partner'] as Map? ?? {}),
      ),
      brand: BrandSettings.fromJson(
        Map<String, dynamic>.from(json['brand'] as Map? ?? {}),
      ),
      flags: FeatureFlags.fromJson(
        Map<String, dynamic>.from(json['flags'] as Map? ?? {}),
      ),
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
        'partner': partner.toJson(),
        'brand': brand.toJson(),
        'flags': flags.toJson(),
      };

  SiteSettings copyWith({
    EmergencySettings? emergency,
    LandingSettings? landing,
    HomeSettings? home,
    PartnerSettings? partner,
    BrandSettings? brand,
    FeatureFlags? flags,
    DateTime? updatedAt,
    String? persistence,
  }) {
    return SiteSettings(
      emergency: emergency ?? this.emergency,
      landing: landing ?? this.landing,
      home: home ?? this.home,
      partner: partner ?? this.partner,
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
  });

  final bool enabled;
  final String bannerTitle;
  final String bannerBody;

  factory EmergencySettings.defaults() => const EmergencySettings(
        enabled: true,
        bannerTitle: '',
        bannerBody: '',
      );

  factory EmergencySettings.fromJson(Map<String, dynamic> json) {
    return EmergencySettings(
      enabled: json['enabled'] as bool? ?? true,
      bannerTitle: (json['bannerTitle'] as String?)?.trim() ?? '',
      bannerBody: (json['bannerBody'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'bannerTitle': bannerTitle,
        'bannerBody': bannerBody,
      };

  EmergencySettings copyWith({
    bool? enabled,
    String? bannerTitle,
    String? bannerBody,
  }) {
    return EmergencySettings(
      enabled: enabled ?? this.enabled,
      bannerTitle: bannerTitle ?? this.bannerTitle,
      bannerBody: bannerBody ?? this.bannerBody,
    );
  }
}

class LandingSettings {
  const LandingSettings({
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.loginCta,
    required this.signupCta,
  });

  final String welcomeTitle;
  final String welcomeSubtitle;
  final String loginCta;
  final String signupCta;

  factory LandingSettings.defaults() => const LandingSettings(
        welcomeTitle: '',
        welcomeSubtitle: '',
        loginCta: '',
        signupCta: '',
      );

  factory LandingSettings.fromJson(Map<String, dynamic> json) {
    return LandingSettings(
      welcomeTitle: (json['welcomeTitle'] as String?)?.trim() ?? '',
      welcomeSubtitle: (json['welcomeSubtitle'] as String?)?.trim() ?? '',
      loginCta: (json['loginCta'] as String?)?.trim() ?? '',
      signupCta: (json['signupCta'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'welcomeTitle': welcomeTitle,
        'welcomeSubtitle': welcomeSubtitle,
        'loginCta': loginCta,
        'signupCta': signupCta,
      };

  LandingSettings copyWith({
    String? welcomeTitle,
    String? welcomeSubtitle,
    String? loginCta,
    String? signupCta,
  }) {
    return LandingSettings(
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      welcomeSubtitle: welcomeSubtitle ?? this.welcomeSubtitle,
      loginCta: loginCta ?? this.loginCta,
      signupCta: signupCta ?? this.signupCta,
    );
  }
}

class HomeSettings {
  const HomeSettings({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  factory HomeSettings.defaults() =>
      const HomeSettings(title: '', subtitle: '');

  factory HomeSettings.fromJson(Map<String, dynamic> json) {
    return HomeSettings(
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
      };

  HomeSettings copyWith({String? title, String? subtitle}) {
    return HomeSettings(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }
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

  factory PartnerSettings.fromJson(Map<String, dynamic> json) {
    return PartnerSettings(
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
      contactEmail: (json['contactEmail'] as String?)?.trim() ??
          'info@medgift.us',
      contactLine: (json['contactLine'] as String?)?.trim() ??
          'MedGift US · info@medgift.us',
      contactButton: (json['contactButton'] as String?)?.trim() ?? '',
    );
  }

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
  }) {
    return PartnerSettings(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      contactEmail: contactEmail ?? this.contactEmail,
      contactLine: contactLine ?? this.contactLine,
      contactButton: contactButton ?? this.contactButton,
    );
  }
}

class BrandSettings {
  const BrandSettings({
    required this.supportEmail,
    required this.notifyEmail,
  });

  final String supportEmail;
  final String notifyEmail;

  factory BrandSettings.defaults() => const BrandSettings(
        supportEmail: 'info@medgift.us',
        notifyEmail: 'info@medgift.us',
      );

  factory BrandSettings.fromJson(Map<String, dynamic> json) {
    return BrandSettings(
      supportEmail:
          (json['supportEmail'] as String?)?.trim() ?? 'info@medgift.us',
      notifyEmail:
          (json['notifyEmail'] as String?)?.trim() ?? 'info@medgift.us',
    );
  }

  Map<String, dynamic> toJson() => {
        'supportEmail': supportEmail,
        'notifyEmail': notifyEmail,
      };

  BrandSettings copyWith({String? supportEmail, String? notifyEmail}) {
    return BrandSettings(
      supportEmail: supportEmail ?? this.supportEmail,
      notifyEmail: notifyEmail ?? this.notifyEmail,
    );
  }
}

class FeatureFlags {
  const FeatureFlags({
    required this.showAiChat,
    required this.showEmergencyBanner,
    required this.showPartnershipFooter,
  });

  final bool showAiChat;
  final bool showEmergencyBanner;
  final bool showPartnershipFooter;

  factory FeatureFlags.defaults() => const FeatureFlags(
        showAiChat: true,
        showEmergencyBanner: true,
        showPartnershipFooter: true,
      );

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      showAiChat: json['showAiChat'] as bool? ?? true,
      showEmergencyBanner: json['showEmergencyBanner'] as bool? ?? true,
      showPartnershipFooter: json['showPartnershipFooter'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'showAiChat': showAiChat,
        'showEmergencyBanner': showEmergencyBanner,
        'showPartnershipFooter': showPartnershipFooter,
      };

  FeatureFlags copyWith({
    bool? showAiChat,
    bool? showEmergencyBanner,
    bool? showPartnershipFooter,
  }) {
    return FeatureFlags(
      showAiChat: showAiChat ?? this.showAiChat,
      showEmergencyBanner: showEmergencyBanner ?? this.showEmergencyBanner,
      showPartnershipFooter:
          showPartnershipFooter ?? this.showPartnershipFooter,
    );
  }
}
