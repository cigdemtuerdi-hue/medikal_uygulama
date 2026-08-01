import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/site_settings.dart';
import '../services/admin_access_service.dart';
import '../services/contact_inquiry_service.dart';
import '../services/site_settings_service.dart';
import '../widgets/async_state_widgets.dart';
import 'admin_inquiries_screen.dart';

/// Owner-only admin CMS at `/admin` — full control of public site copy & visibility.
class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  final _access = AdminAccessService.instance;
  final _settingsService = SiteSettingsService.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final TabController _tabs;
  late final _CmsDraft _draft;

  bool _obscure = true;
  bool _submitting = false;
  bool _saving = false;
  Map<String, dynamic>? _health;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _draft = _CmsDraft();
    _tabs = TabController(length: 8, vsync: this);
    _access.addListener(_onChanged);
    _settingsService.addListener(_onChanged);
    _emailController.text = AppConfig.adminEmail;
    if (_access.isAuthenticated) {
      _bootstrapAuthenticated();
    }
  }

  Future<void> _bootstrapAuthenticated() async {
    await _settingsService.refresh();
    _draft.hydrate(_settingsService.settings);
    await _refreshHealth();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _access.removeListener(_onChanged);
    _settingsService.removeListener(_onChanged);
    _tabs.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshHealth() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/health',
      );
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          setState(() => _health = decoded);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _health = null);
    }
  }

  Future<void> _submitLogin() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await _access.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _passwordController.clear();
      await _bootstrapAuthenticated();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    final ok = await _settingsService.save(_draft.toSettings(_settingsService.settings));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveMessage = ok
          ? (_settingsService.persistence == 'mongo'
              ? 'Kaydedildi (Mongo — kalıcı). Canlı site güncellendi.'
              : 'Kaydedildi (memory — Render restart’ta silinebilir).')
          : (_settingsService.lastError ?? 'Kayıt başarısız.');
    });
    if (ok) {
      _draft.hydrate(_settingsService.settings);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_saveMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_access.isAuthenticated) {
      return _AdminLoginView(
        emailController: _emailController,
        passwordController: _passwordController,
        emailFocus: _emailFocus,
        passwordFocus: _passwordFocus,
        obscure: _obscure,
        submitting: _submitting,
        error: _access.lastError,
        onToggleObscure: () => setState(() => _obscure = !_obscure),
        onSubmit: _submitLogin,
      );
    }

    final unread = ContactInquiryService.instance.unreadCount;
    final db = _health?['db']?.toString() ?? _settingsService.persistence;
    final emailConfigured = (_health?['messaging'] is Map &&
        (_health!['messaging'] as Map)['emailConfigured'] == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedGift Admin CMS'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await _settingsService.refresh();
              _draft.hydrate(_settingsService.settings);
              await _refreshHealth();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Lock admin panel',
            onPressed: () => _access.lock(),
            icon: const Icon(Icons.lock_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Görünürlük'),
            Tab(text: 'Karşılama'),
            Tab(text: 'Ana Sayfa'),
            Tab(text: 'Manifesto'),
            Tab(text: 'About'),
            Tab(text: 'Emergency'),
            Tab(text: 'İletişim'),
            Tab(text: 'Sistem'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
      ),
      body: ContentConstrained(
        maxWidth: 920,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        child: TabBarView(
          controller: _tabs,
          children: [
            _VisibilityTab(
              email: _access.email ?? AppConfig.adminEmail,
              draft: _draft,
              onChanged: () => setState(() {}),
            ),
            _LandingTab(draft: _draft),
            _HomeTab(draft: _draft),
            _ManifestoTab(draft: _draft),
            _AboutTab(draft: _draft),
            _EmergencyTab(
              draft: _draft,
              onChanged: () => setState(() {}),
            ),
            _ContactTab(
              draft: _draft,
              unread: unread,
              onOpenInbox: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminInquiriesScreen(),
                  ),
                );
              },
            ),
            _SystemTab(
              db: db,
              apiOnline: _health != null,
              emailConfigured: emailConfigured,
              persistence: _settingsService.persistence,
              saveMessage: _saveMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Holds all CMS text fields + flags for the admin draft.
class _CmsDraft {
  // Landing
  final welcomeTitle = TextEditingController();
  final welcomeSubtitle = TextEditingController();
  final loginCta = TextEditingController();
  final signupCta = TextEditingController();
  final forgotPasswordCta = TextEditingController();
  final newHereHint = TextEditingController();
  final aboutLinkLabel = TextEditingController();

  // Home
  final homeTitle = TextEditingController();
  final homeSubtitle = TextEditingController();
  final locationLabel = TextEditingController();
  final complianceBanner = TextEditingController();
  final browseTitle = TextEditingController();
  final browseBody = TextEditingController();
  final passItOnTitle = TextEditingController();
  final passItOnBody = TextEditingController();
  final quickActionsTitle = TextEditingController();
  final quickActionsSubtitle = TextEditingController();
  final donateDmeLabel = TextEditingController();
  final donateWoundCareLabel = TextEditingController();
  final browseCtaLabel = TextEditingController();
  final recentTitle = TextEditingController();
  final sponsorsTitle = TextEditingController();
  final sponsorsSubtitle = TextEditingController();
  final impactTitle = TextEditingController();
  final impactSubtitle = TextEditingController();
  final statItemsValue = TextEditingController();
  final statItemsLabel = TextEditingController();
  final statOrgsValue = TextEditingController();
  final statOrgsLabel = TextEditingController();
  final statAiValue = TextEditingController();
  final statAiLabel = TextEditingController();
  final statStatesValue = TextEditingController();
  final statStatesLabel = TextEditingController();

  // Manifesto
  final manifestoEyebrow = TextEditingController();
  final manifestoTitle = TextEditingController();
  final manifestoSubtitle = TextEditingController();
  final manifestoLead = TextEditingController();
  final manifestoCtaBody = TextEditingController();
  final manifestoCtaButton = TextEditingController();
  final manifestoReadMore = TextEditingController();

  // About
  final aboutAppBar = TextEditingController();
  final aboutTitle = TextEditingController();
  final aboutIntro = TextEditingController();

  // Emergency
  final bannerTitle = TextEditingController();
  final bannerBody = TextEditingController();
  final crisisLabel = TextEditingController();
  bool emergencyEnabled = true;

  // Partner
  final partnerTitle = TextEditingController();
  final partnerSubtitle = TextEditingController();
  final partnerEmail = TextEditingController();
  final partnerLine = TextEditingController();
  final partnerButton = TextEditingController();

  // Inquiry
  final inquirySheetTitle = TextEditingController();
  final inquirySheetSubtitle = TextEditingController();
  final inquiryNameLabel = TextEditingController();
  final inquiryEmailLabel = TextEditingController();
  final inquirySendButton = TextEditingController();
  final inquirySuccessTitle = TextEditingController();
  final inquirySuccessBody = TextEditingController();
  final inquiryResponseSla = TextEditingController();

  // Brand
  final displayName = TextEditingController();
  final supportEmail = TextEditingController();
  final notifyEmail = TextEditingController();

  // Flags
  bool showAiChat = true;
  bool showEmergencyBanner = true;
  bool showPartnershipFooter = true;
  bool showManifesto = true;
  bool showAboutLink = true;
  bool showComplianceBanner = true;
  bool showHomeStats = true;
  bool showImpactCard = true;
  bool showBrowseEntry = true;
  bool showPassItOnEntry = true;
  bool showQuickActions = true;
  bool showSponsors = true;
  bool showRecentDonations = true;

  List<TextEditingController> get _allControllers => [
        welcomeTitle,
        welcomeSubtitle,
        loginCta,
        signupCta,
        forgotPasswordCta,
        newHereHint,
        aboutLinkLabel,
        homeTitle,
        homeSubtitle,
        locationLabel,
        complianceBanner,
        browseTitle,
        browseBody,
        passItOnTitle,
        passItOnBody,
        quickActionsTitle,
        quickActionsSubtitle,
        donateDmeLabel,
        donateWoundCareLabel,
        browseCtaLabel,
        recentTitle,
        sponsorsTitle,
        sponsorsSubtitle,
        impactTitle,
        impactSubtitle,
        statItemsValue,
        statItemsLabel,
        statOrgsValue,
        statOrgsLabel,
        statAiValue,
        statAiLabel,
        statStatesValue,
        statStatesLabel,
        manifestoEyebrow,
        manifestoTitle,
        manifestoSubtitle,
        manifestoLead,
        manifestoCtaBody,
        manifestoCtaButton,
        manifestoReadMore,
        aboutAppBar,
        aboutTitle,
        aboutIntro,
        bannerTitle,
        bannerBody,
        crisisLabel,
        partnerTitle,
        partnerSubtitle,
        partnerEmail,
        partnerLine,
        partnerButton,
        inquirySheetTitle,
        inquirySheetSubtitle,
        inquiryNameLabel,
        inquiryEmailLabel,
        inquirySendButton,
        inquirySuccessTitle,
        inquirySuccessBody,
        inquiryResponseSla,
        displayName,
        supportEmail,
        notifyEmail,
      ];

  void hydrate(SiteSettings s) {
    welcomeTitle.text = s.landing.welcomeTitle;
    welcomeSubtitle.text = s.landing.welcomeSubtitle;
    loginCta.text = s.landing.loginCta;
    signupCta.text = s.landing.signupCta;
    forgotPasswordCta.text = s.landing.forgotPasswordCta;
    newHereHint.text = s.landing.newHereHint;
    aboutLinkLabel.text = s.landing.aboutLinkLabel;

    homeTitle.text = s.home.title;
    homeSubtitle.text = s.home.subtitle;
    locationLabel.text = s.home.locationLabel;
    complianceBanner.text = s.home.complianceBanner;
    browseTitle.text = s.home.browseTitle;
    browseBody.text = s.home.browseBody;
    passItOnTitle.text = s.home.passItOnTitle;
    passItOnBody.text = s.home.passItOnBody;
    quickActionsTitle.text = s.home.quickActionsTitle;
    quickActionsSubtitle.text = s.home.quickActionsSubtitle;
    donateDmeLabel.text = s.home.donateDmeLabel;
    donateWoundCareLabel.text = s.home.donateWoundCareLabel;
    browseCtaLabel.text = s.home.browseCtaLabel;
    recentTitle.text = s.home.recentTitle;
    sponsorsTitle.text = s.home.sponsorsTitle;
    sponsorsSubtitle.text = s.home.sponsorsSubtitle;
    impactTitle.text = s.home.impactTitle;
    impactSubtitle.text = s.home.impactSubtitle;
    statItemsValue.text = s.home.statItemsValue;
    statItemsLabel.text = s.home.statItemsLabel;
    statOrgsValue.text = s.home.statOrgsValue;
    statOrgsLabel.text = s.home.statOrgsLabel;
    statAiValue.text = s.home.statAiValue;
    statAiLabel.text = s.home.statAiLabel;
    statStatesValue.text = s.home.statStatesValue;
    statStatesLabel.text = s.home.statStatesLabel;

    manifestoEyebrow.text = s.manifesto.eyebrow;
    manifestoTitle.text = s.manifesto.title;
    manifestoSubtitle.text = s.manifesto.subtitle;
    manifestoLead.text = s.manifesto.lead;
    manifestoCtaBody.text = s.manifesto.ctaBody;
    manifestoCtaButton.text = s.manifesto.ctaButton;
    manifestoReadMore.text = s.manifesto.readMoreLabel;

    aboutAppBar.text = s.about.appBarTitle;
    aboutTitle.text = s.about.title;
    aboutIntro.text = s.about.intro;

    bannerTitle.text = s.emergency.bannerTitle;
    bannerBody.text = s.emergency.bannerBody;
    crisisLabel.text = s.emergency.crisisLabel;
    emergencyEnabled = s.emergency.enabled;

    partnerTitle.text = s.partner.title;
    partnerSubtitle.text = s.partner.subtitle;
    partnerEmail.text = s.partner.contactEmail;
    partnerLine.text = s.partner.contactLine;
    partnerButton.text = s.partner.contactButton;

    inquirySheetTitle.text = s.inquiry.sheetTitle;
    inquirySheetSubtitle.text = s.inquiry.sheetSubtitle;
    inquiryNameLabel.text = s.inquiry.nameLabel;
    inquiryEmailLabel.text = s.inquiry.emailLabel;
    inquirySendButton.text = s.inquiry.sendButton;
    inquirySuccessTitle.text = s.inquiry.successTitle;
    inquirySuccessBody.text = s.inquiry.successBody;
    inquiryResponseSla.text = s.inquiry.responseSla;

    displayName.text = s.brand.displayName;
    supportEmail.text = s.brand.supportEmail;
    notifyEmail.text = s.brand.notifyEmail;

    showAiChat = s.flags.showAiChat;
    showEmergencyBanner = s.flags.showEmergencyBanner;
    showPartnershipFooter = s.flags.showPartnershipFooter;
    showManifesto = s.flags.showManifesto;
    showAboutLink = s.flags.showAboutLink;
    showComplianceBanner = s.flags.showComplianceBanner;
    showHomeStats = s.flags.showHomeStats;
    showImpactCard = s.flags.showImpactCard;
    showBrowseEntry = s.flags.showBrowseEntry;
    showPassItOnEntry = s.flags.showPassItOnEntry;
    showQuickActions = s.flags.showQuickActions;
    showSponsors = s.flags.showSponsors;
    showRecentDonations = s.flags.showRecentDonations;
  }

  SiteSettings toSettings(SiteSettings base) {
    String t(TextEditingController c) => c.text.trim();
    return base.copyWith(
      emergency: base.emergency.copyWith(
        enabled: emergencyEnabled,
        bannerTitle: t(bannerTitle),
        bannerBody: t(bannerBody),
        crisisLabel: t(crisisLabel),
      ),
      landing: base.landing.copyWith(
        welcomeTitle: t(welcomeTitle),
        welcomeSubtitle: t(welcomeSubtitle),
        loginCta: t(loginCta),
        signupCta: t(signupCta),
        forgotPasswordCta: t(forgotPasswordCta),
        newHereHint: t(newHereHint),
        aboutLinkLabel: t(aboutLinkLabel),
      ),
      home: base.home.copyWith(
        title: t(homeTitle),
        subtitle: t(homeSubtitle),
        locationLabel: t(locationLabel),
        complianceBanner: t(complianceBanner),
        browseTitle: t(browseTitle),
        browseBody: t(browseBody),
        passItOnTitle: t(passItOnTitle),
        passItOnBody: t(passItOnBody),
        quickActionsTitle: t(quickActionsTitle),
        quickActionsSubtitle: t(quickActionsSubtitle),
        donateDmeLabel: t(donateDmeLabel),
        donateWoundCareLabel: t(donateWoundCareLabel),
        browseCtaLabel: t(browseCtaLabel),
        recentTitle: t(recentTitle),
        sponsorsTitle: t(sponsorsTitle),
        sponsorsSubtitle: t(sponsorsSubtitle),
        impactTitle: t(impactTitle),
        impactSubtitle: t(impactSubtitle),
        statItemsValue: t(statItemsValue),
        statItemsLabel: t(statItemsLabel),
        statOrgsValue: t(statOrgsValue),
        statOrgsLabel: t(statOrgsLabel),
        statAiValue: t(statAiValue),
        statAiLabel: t(statAiLabel),
        statStatesValue: t(statStatesValue),
        statStatesLabel: t(statStatesLabel),
      ),
      manifesto: base.manifesto.copyWith(
        eyebrow: t(manifestoEyebrow),
        title: t(manifestoTitle),
        subtitle: t(manifestoSubtitle),
        lead: t(manifestoLead),
        ctaBody: t(manifestoCtaBody),
        ctaButton: t(manifestoCtaButton),
        readMoreLabel: t(manifestoReadMore),
      ),
      about: base.about.copyWith(
        appBarTitle: t(aboutAppBar),
        title: t(aboutTitle),
        intro: t(aboutIntro),
      ),
      partner: base.partner.copyWith(
        title: t(partnerTitle),
        subtitle: t(partnerSubtitle),
        contactEmail: t(partnerEmail),
        contactLine: t(partnerLine),
        contactButton: t(partnerButton),
      ),
      inquiry: base.inquiry.copyWith(
        sheetTitle: t(inquirySheetTitle),
        sheetSubtitle: t(inquirySheetSubtitle),
        nameLabel: t(inquiryNameLabel),
        emailLabel: t(inquiryEmailLabel),
        sendButton: t(inquirySendButton),
        successTitle: t(inquirySuccessTitle),
        successBody: t(inquirySuccessBody),
        responseSla: t(inquiryResponseSla),
      ),
      brand: base.brand.copyWith(
        displayName: t(displayName),
        supportEmail: t(supportEmail),
        notifyEmail: t(notifyEmail),
      ),
      flags: base.flags.copyWith(
        showAiChat: showAiChat,
        showEmergencyBanner: showEmergencyBanner,
        showPartnershipFooter: showPartnershipFooter,
        showManifesto: showManifesto,
        showAboutLink: showAboutLink,
        showComplianceBanner: showComplianceBanner,
        showHomeStats: showHomeStats,
        showImpactCard: showImpactCard,
        showBrowseEntry: showBrowseEntry,
        showPassItOnEntry: showPassItOnEntry,
        showQuickActions: showQuickActions,
        showSponsors: showSponsors,
        showRecentDonations: showRecentDonations,
      ),
    );
  }

  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
  }
}

Widget _hint(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedIcon,
          ),
    ),
  );
}

Widget _sectionTitle(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDeepBlue,
          ),
    ),
  );
}

Widget _field(
  TextEditingController c,
  String label, {
  int maxLines = 1,
  String? helper,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class _VisibilityTab extends StatelessWidget {
  const _VisibilityTab({
    required this.email,
    required this.draft,
    required this.onChanged,
  });

  final String email;
  final _CmsDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Oturum: $email',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDeepBlue,
              ),
        ),
        _hint(
          context,
          'Boş metin alanlarında sitedeki varsayılan dil çevirisi kullanılır. '
          'Aşağıdaki anahtarlarla sayfa bölümlerini aç/kapat.',
        ),
        _sectionTitle(context, 'Marka e-postaları'),
        _field(draft.displayName, 'Görünen marka adı (boş = MedGift US)'),
        _field(draft.supportEmail, 'Destek e-postası'),
        _field(draft.notifyEmail, 'Bildirim e-postası (inquiry)'),
        _sectionTitle(context, 'Sayfa bölümleri'),
        SwitchListTile(
          title: const Text('MeGi sohbet robotu'),
          subtitle: const Text('Site rehberi — bağış, rezervasyon, şifre, QR…'),
          value: draft.showAiChat,
          onChanged: (v) {
            draft.showAiChat = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Emergency banner'),
          value: draft.showEmergencyBanner,
          onChanged: (v) {
            draft.showEmergencyBanner = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Partnership footer'),
          value: draft.showPartnershipFooter,
          onChanged: (v) {
            draft.showPartnershipFooter = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Manifesto bölümü'),
          value: draft.showManifesto,
          onChanged: (v) {
            draft.showManifesto = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('About Us linki (karşılama)'),
          value: draft.showAboutLink,
          onChanged: (v) {
            draft.showAboutLink = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Compliance banner (home)'),
          value: draft.showComplianceBanner,
          onChanged: (v) {
            draft.showComplianceBanner = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Browse equipment kartı'),
          value: draft.showBrowseEntry,
          onChanged: (v) {
            draft.showBrowseEntry = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Pass-It-On kartı'),
          value: draft.showPassItOnEntry,
          onChanged: (v) {
            draft.showPassItOnEntry = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Impact / ESG kartı'),
          value: draft.showImpactCard,
          onChanged: (v) {
            draft.showImpactCard = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('İstatistik kutuları'),
          value: draft.showHomeStats,
          onChanged: (v) {
            draft.showHomeStats = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Quick Actions'),
          value: draft.showQuickActions,
          onChanged: (v) {
            draft.showQuickActions = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Recent donations'),
          value: draft.showRecentDonations,
          onChanged: (v) {
            draft.showRecentDonations = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: const Text('Sponsors bölümü'),
          value: draft.showSponsors,
          onChanged: (v) {
            draft.showSponsors = v;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _LandingTab extends StatelessWidget {
  const _LandingTab({required this.draft});

  final _CmsDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _sectionTitle(context, 'Karşılama sayfası (Log In / Sign Up)'),
        _hint(context, 'medgift.us ana ekranı — giriş öncesi.'),
        _field(draft.welcomeTitle, 'Başlık'),
        _field(draft.welcomeSubtitle, 'Alt yazı', maxLines: 3),
        _field(draft.loginCta, 'Log In buton metni'),
        _field(draft.signupCta, 'Sign Up buton metni'),
        _field(draft.forgotPasswordCta, 'Forgot Password buton metni'),
        _field(draft.newHereHint, '“New here?” ipucu'),
        _field(draft.aboutLinkLabel, 'About Us link metni'),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.draft});

  final _CmsDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _sectionTitle(context, 'Ana sayfa üst alan'),
        _field(draft.homeTitle, 'Başlık'),
        _field(draft.homeSubtitle, 'Alt yazı', maxLines: 3),
        _field(draft.locationLabel, 'Konum etiketi (United States)'),
        _field(draft.complianceBanner, 'Compliance banner metni', maxLines: 3),
        _sectionTitle(context, 'Giriş kartları'),
        _field(draft.browseTitle, 'Browse Equipment başlık'),
        _field(draft.browseBody, 'Browse Equipment açıklama', maxLines: 3),
        _field(draft.passItOnTitle, 'Pass-It-On başlık'),
        _field(
          draft.passItOnBody,
          'Pass-It-On açıklama (boş = dil dosyası; {count} desteklenir)',
          maxLines: 3,
        ),
        _sectionTitle(context, 'Impact & istatistikler'),
        _field(draft.impactTitle, 'Impact kart başlık'),
        _field(draft.impactSubtitle, 'Impact kart alt yazı', maxLines: 2),
        _field(draft.statItemsValue, 'Stat 1 değer (örn. 1,284)'),
        _field(draft.statItemsLabel, 'Stat 1 etiket'),
        _field(draft.statOrgsValue, 'Stat 2 değer'),
        _field(draft.statOrgsLabel, 'Stat 2 etiket'),
        _field(draft.statAiValue, 'Stat 3 değer'),
        _field(draft.statAiLabel, 'Stat 3 etiket'),
        _field(draft.statStatesValue, 'Stat 4 değer'),
        _field(draft.statStatesLabel, 'Stat 4 etiket'),
        _sectionTitle(context, 'Quick Actions'),
        _field(draft.quickActionsTitle, 'Başlık'),
        _field(draft.quickActionsSubtitle, 'Alt yazı', maxLines: 2),
        _field(draft.donateDmeLabel, 'Donate DME butonu'),
        _field(draft.donateWoundCareLabel, 'Donate Wound Care butonu'),
        _field(draft.browseCtaLabel, 'Browse CTA butonu'),
        _field(draft.recentTitle, 'Recent donations başlık'),
        _sectionTitle(context, 'Sponsors'),
        _field(draft.sponsorsTitle, 'Sponsors başlık'),
        _field(draft.sponsorsSubtitle, 'Sponsors alt yazı', maxLines: 2),
      ],
    );
  }
}

class _ManifestoTab extends StatelessWidget {
  const _ManifestoTab({required this.draft});

  final _CmsDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _sectionTitle(context, 'Our Manifesto'),
        _hint(
          context,
          'Pillar detay diyalogları dil dosyasından gelir; üst metinleri buradan yönet.',
        ),
        _field(draft.manifestoEyebrow, 'Eyebrow'),
        _field(draft.manifestoTitle, 'Başlık'),
        _field(draft.manifestoSubtitle, 'Alt yazı', maxLines: 3),
        _field(draft.manifestoLead, 'Lead paragraf', maxLines: 4),
        _field(draft.manifestoCtaBody, 'CTA açıklama', maxLines: 3),
        _field(draft.manifestoCtaButton, 'CTA buton'),
        _field(draft.manifestoReadMore, 'Read more etiketi'),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.draft});

  final _CmsDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _sectionTitle(context, 'About Us sayfası'),
        _field(draft.aboutAppBar, 'App bar başlık'),
        _field(draft.aboutTitle, 'Sayfa başlık'),
        _field(draft.aboutIntro, 'Giriş metni', maxLines: 5),
      ],
    );
  }
}

class _EmergencyTab extends StatelessWidget {
  const _EmergencyTab({
    required this.draft,
    required this.onChanged,
  });

  final _CmsDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          secondary: Icon(
            Icons.crisis_alert,
            color: draft.emergencyEnabled
                ? const Color(0xFFC62828)
                : AppTheme.mutedIcon,
          ),
          title: const Text('Emergency Response Mode'),
          subtitle: const Text('Kırmızı üst banner’ı açar/kapatır'),
          value: draft.emergencyEnabled,
          onChanged: (v) {
            draft.emergencyEnabled = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _field(draft.bannerTitle, 'Banner başlığı (boş = dil dosyası)'),
        _field(draft.bannerBody, 'Banner metni', maxLines: 3),
        _field(draft.crisisLabel, 'Crisis etiket (harita vb.)'),
      ],
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab({
    required this.draft,
    required this.unread,
    required this.onOpenInbox,
  });

  final _CmsDraft draft;
  final int unread;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            leading: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.inbox_outlined),
            ),
            title: const Text('Gelen kutusu'),
            subtitle: Text(
              unread > 0
                  ? '$unread okunmamış mesaj'
                  : 'Contact / Sponsorship mesajları',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenInbox,
          ),
        ),
        _sectionTitle(context, 'Partnership footer'),
        _field(draft.partnerTitle, 'Başlık'),
        _field(draft.partnerSubtitle, 'Alt yazı', maxLines: 3),
        _field(draft.partnerButton, 'Buton metni'),
        _field(draft.partnerEmail, 'Gösterilen e-posta'),
        _field(draft.partnerLine, 'Alt satır (MedGift US · email)'),
        _sectionTitle(context, 'Contact / Inquiry formu'),
        _field(draft.inquirySheetTitle, 'Form başlık'),
        _field(draft.inquirySheetSubtitle, 'Form alt yazı', maxLines: 3),
        _field(draft.inquiryNameLabel, 'İsim alanı etiketi'),
        _field(draft.inquiryEmailLabel, 'E-posta alanı etiketi'),
        _field(draft.inquirySendButton, 'Gönder butonu'),
        _field(draft.inquirySuccessTitle, 'Teşekkür başlığı'),
        _field(
          draft.inquirySuccessBody,
          'Teşekkür metni ({name} kullanabilirsin)',
          maxLines: 4,
        ),
        _field(draft.inquiryResponseSla, 'Yanıt süresi notu'),
      ],
    );
  }
}

class _SystemTab extends StatelessWidget {
  const _SystemTab({
    required this.db,
    required this.apiOnline,
    required this.emailConfigured,
    required this.persistence,
    required this.saveMessage,
  });

  final String db;
  final bool apiOnline;
  final bool emailConfigured;
  final String persistence;
  final String? saveMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (saveMessage != null) ...[
          Text(
            saveMessage!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
        ],
        _row('API', apiOnline ? 'online' : 'unreachable', apiOnline),
        _row('Database', db, db == 'mongo'),
        _row('CMS persistence', persistence, persistence == 'mongo'),
        _row(
          'Transactional email',
          emailConfigured ? 'configured' : 'not configured',
          emailConfigured,
        ),
        const SizedBox(height: 16),
        if (persistence != 'mongo')
          Text(
            'Uyarı: MongoDB bağlı değil. Kaydettiğin metinler Render yeniden '
            'başlayınca silinebilir.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B3F00),
                ),
          ),
      ],
    );
  }

  Widget _row(String label, String value, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 18,
            color: ok ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AdminLoginView extends StatelessWidget {
  const _AdminLoginView({
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.obscure,
    required this.submitting,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool obscure;
  final bool submitting;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: SafeArea(
        child: Center(
          child: ContentConstrained(
            maxWidth: 440,
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 42,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Owner CMS access',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDeepBlue,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sayfanın her metnini ve görünürlüğünü buradan yönetirsin.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (error != null) ...[
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: emailController,
                        focusNode: emailFocus,
                        enabled: !submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => passwordFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Admin email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        enabled: !submitting,
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onSubmit(),
                        decoration: InputDecoration(
                          labelText: 'Admin password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: submitting ? null : onToggleObscure,
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: submitting ? null : onSubmit,
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enter admin CMS'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
