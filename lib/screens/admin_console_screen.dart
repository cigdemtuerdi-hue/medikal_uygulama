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

/// Owner-only admin CMS at `/admin`.
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

  // Draft controllers
  final _welcomeTitle = TextEditingController();
  final _welcomeSubtitle = TextEditingController();
  final _loginCta = TextEditingController();
  final _signupCta = TextEditingController();
  final _homeTitle = TextEditingController();
  final _homeSubtitle = TextEditingController();
  final _bannerTitle = TextEditingController();
  final _bannerBody = TextEditingController();
  final _partnerTitle = TextEditingController();
  final _partnerSubtitle = TextEditingController();
  final _partnerEmail = TextEditingController();
  final _partnerLine = TextEditingController();
  final _partnerButton = TextEditingController();
  final _supportEmail = TextEditingController();
  final _notifyEmail = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  bool _saving = false;
  bool _emergencyEnabled = true;
  bool _showAiChat = true;
  bool _showEmergencyBanner = true;
  bool _showPartnershipFooter = true;
  Map<String, dynamic>? _health;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _access.addListener(_onChanged);
    _settingsService.addListener(_onChanged);
    _emailController.text = AppConfig.adminEmail;
    if (_access.isAuthenticated) {
      _bootstrapAuthenticated();
    }
  }

  Future<void> _bootstrapAuthenticated() async {
    await _settingsService.refresh();
    _hydrateFromSettings(_settingsService.settings);
    await _refreshHealth();
    if (mounted) setState(() {});
  }

  void _hydrateFromSettings(SiteSettings s) {
    _welcomeTitle.text = s.landing.welcomeTitle;
    _welcomeSubtitle.text = s.landing.welcomeSubtitle;
    _loginCta.text = s.landing.loginCta;
    _signupCta.text = s.landing.signupCta;
    _homeTitle.text = s.home.title;
    _homeSubtitle.text = s.home.subtitle;
    _bannerTitle.text = s.emergency.bannerTitle;
    _bannerBody.text = s.emergency.bannerBody;
    _emergencyEnabled = s.emergency.enabled;
    _partnerTitle.text = s.partner.title;
    _partnerSubtitle.text = s.partner.subtitle;
    _partnerEmail.text = s.partner.contactEmail;
    _partnerLine.text = s.partner.contactLine;
    _partnerButton.text = s.partner.contactButton;
    _supportEmail.text = s.brand.supportEmail;
    _notifyEmail.text = s.brand.notifyEmail;
    _showAiChat = s.flags.showAiChat;
    _showEmergencyBanner = s.flags.showEmergencyBanner;
    _showPartnershipFooter = s.flags.showPartnershipFooter;
  }

  SiteSettings _draftSettings() {
    final base = _settingsService.settings;
    return base.copyWith(
      emergency: base.emergency.copyWith(
        enabled: _emergencyEnabled,
        bannerTitle: _bannerTitle.text.trim(),
        bannerBody: _bannerBody.text.trim(),
      ),
      landing: base.landing.copyWith(
        welcomeTitle: _welcomeTitle.text.trim(),
        welcomeSubtitle: _welcomeSubtitle.text.trim(),
        loginCta: _loginCta.text.trim(),
        signupCta: _signupCta.text.trim(),
      ),
      home: base.home.copyWith(
        title: _homeTitle.text.trim(),
        subtitle: _homeSubtitle.text.trim(),
      ),
      partner: base.partner.copyWith(
        title: _partnerTitle.text.trim(),
        subtitle: _partnerSubtitle.text.trim(),
        contactEmail: _partnerEmail.text.trim(),
        contactLine: _partnerLine.text.trim(),
        contactButton: _partnerButton.text.trim(),
      ),
      brand: base.brand.copyWith(
        supportEmail: _supportEmail.text.trim(),
        notifyEmail: _notifyEmail.text.trim(),
      ),
      flags: base.flags.copyWith(
        showAiChat: _showAiChat,
        showEmergencyBanner: _showEmergencyBanner,
        showPartnershipFooter: _showPartnershipFooter,
      ),
    );
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
    for (final c in [
      _welcomeTitle,
      _welcomeSubtitle,
      _loginCta,
      _signupCta,
      _homeTitle,
      _homeSubtitle,
      _bannerTitle,
      _bannerBody,
      _partnerTitle,
      _partnerSubtitle,
      _partnerEmail,
      _partnerLine,
      _partnerButton,
      _supportEmail,
      _notifyEmail,
    ]) {
      c.dispose();
    }
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
    final ok = await _settingsService.save(_draftSettings());
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveMessage = ok
          ? (_settingsService.persistence == 'mongo'
              ? 'Kaydedildi (Mongo — kalıcı).'
              : 'Kaydedildi (memory — Render restart’ta silinebilir).')
          : (_settingsService.lastError ?? 'Kayıt başarısız.');
    });
    if (ok) {
      _hydrateFromSettings(_settingsService.settings);
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
              _hydrateFromSettings(_settingsService.settings);
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
            Tab(text: 'Genel'),
            Tab(text: 'Karşılama'),
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
            _GeneralTab(
              email: _access.email ?? AppConfig.adminEmail,
              supportEmail: _supportEmail,
              notifyEmail: _notifyEmail,
              showAiChat: _showAiChat,
              showEmergencyBanner: _showEmergencyBanner,
              showPartnershipFooter: _showPartnershipFooter,
              onShowAiChat: (v) => setState(() => _showAiChat = v),
              onShowEmergency: (v) => setState(() => _showEmergencyBanner = v),
              onShowPartner: (v) => setState(() => _showPartnershipFooter = v),
            ),
            _LandingTab(
              welcomeTitle: _welcomeTitle,
              welcomeSubtitle: _welcomeSubtitle,
              loginCta: _loginCta,
              signupCta: _signupCta,
              homeTitle: _homeTitle,
              homeSubtitle: _homeSubtitle,
            ),
            _EmergencyTab(
              enabled: _emergencyEnabled,
              bannerTitle: _bannerTitle,
              bannerBody: _bannerBody,
              onEnabled: (v) => setState(() => _emergencyEnabled = v),
            ),
            _ContactTab(
              partnerTitle: _partnerTitle,
              partnerSubtitle: _partnerSubtitle,
              partnerEmail: _partnerEmail,
              partnerLine: _partnerLine,
              partnerButton: _partnerButton,
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

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({
    required this.email,
    required this.supportEmail,
    required this.notifyEmail,
    required this.showAiChat,
    required this.showEmergencyBanner,
    required this.showPartnershipFooter,
    required this.onShowAiChat,
    required this.onShowEmergency,
    required this.onShowPartner,
  });

  final String email;
  final TextEditingController supportEmail;
  final TextEditingController notifyEmail;
  final bool showAiChat;
  final bool showEmergencyBanner;
  final bool showPartnershipFooter;
  final ValueChanged<bool> onShowAiChat;
  final ValueChanged<bool> onShowEmergency;
  final ValueChanged<bool> onShowPartner;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Oturum: $email',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDeepBlue,
                )),
        const SizedBox(height: 8),
        const Text(
          'Boş bıraktığın metin alanlarında sitedeki varsayılan dil çevirisi kullanılır. '
          'Kaydet’e basınca canlı site güncellenir.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: supportEmail,
          decoration: const InputDecoration(
            labelText: 'Destek e-postası',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notifyEmail,
          decoration: const InputDecoration(
            labelText: 'Bildirim e-postası (inquiry)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('AI destek sohbetini göster'),
          value: showAiChat,
          onChanged: onShowAiChat,
        ),
        SwitchListTile(
          title: const Text('Emergency banner’ı göster'),
          value: showEmergencyBanner,
          onChanged: onShowEmergency,
        ),
        SwitchListTile(
          title: const Text('Partnership footer’ı göster'),
          value: showPartnershipFooter,
          onChanged: onShowPartner,
        ),
      ],
    );
  }
}

class _LandingTab extends StatelessWidget {
  const _LandingTab({
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.loginCta,
    required this.signupCta,
    required this.homeTitle,
    required this.homeSubtitle,
  });

  final TextEditingController welcomeTitle;
  final TextEditingController welcomeSubtitle;
  final TextEditingController loginCta;
  final TextEditingController signupCta;
  final TextEditingController homeTitle;
  final TextEditingController homeSubtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Karşılama sayfası (Log In / Sign Up)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 12),
        _field(welcomeTitle, 'Başlık'),
        _field(welcomeSubtitle, 'Alt yazı', maxLines: 3),
        _field(loginCta, 'Log In buton metni'),
        _field(signupCta, 'Sign Up buton metni'),
        const SizedBox(height: 20),
        Text('Giriş sonrası Anasayfa',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 12),
        _field(homeTitle, 'Home başlık'),
        _field(homeSubtitle, 'Home alt yazı', maxLines: 3),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _EmergencyTab extends StatelessWidget {
  const _EmergencyTab({
    required this.enabled,
    required this.bannerTitle,
    required this.bannerBody,
    required this.onEnabled,
  });

  final bool enabled;
  final TextEditingController bannerTitle;
  final TextEditingController bannerBody;
  final ValueChanged<bool> onEnabled;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          secondary: Icon(
            Icons.crisis_alert,
            color: enabled ? const Color(0xFFC62828) : AppTheme.mutedIcon,
          ),
          title: const Text('Emergency Response Mode'),
          subtitle: const Text('Kırmızı üst banner’ı açar/kapatır'),
          value: enabled,
          onChanged: onEnabled,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bannerTitle,
          decoration: const InputDecoration(
            labelText: 'Banner başlığı (boş = dil dosyası)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bannerBody,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Banner metni (boş = dil dosyası)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab({
    required this.partnerTitle,
    required this.partnerSubtitle,
    required this.partnerEmail,
    required this.partnerLine,
    required this.partnerButton,
    required this.unread,
    required this.onOpenInbox,
  });

  final TextEditingController partnerTitle;
  final TextEditingController partnerSubtitle;
  final TextEditingController partnerEmail;
  final TextEditingController partnerLine;
  final TextEditingController partnerButton;
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
        const SizedBox(height: 16),
        TextField(
          controller: partnerTitle,
          decoration: const InputDecoration(
            labelText: 'Partnership başlık',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: partnerSubtitle,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Partnership alt yazı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: partnerButton,
          decoration: const InputDecoration(
            labelText: 'Buton metni',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: partnerEmail,
          decoration: const InputDecoration(
            labelText: 'Gösterilen e-posta',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: partnerLine,
          decoration: const InputDecoration(
            labelText: 'Alt satır (MedGift US · email)',
            border: OutlineInputBorder(),
          ),
        ),
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
          Text(saveMessage!,
              style: const TextStyle(fontWeight: FontWeight.w600)),
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
            'başlayınca silinebilir. Kalıcılık için Atlas connection string’i '
            'Render’da MONGODB_URI olarak ayarla ve USE_MEMORY_DB=false yap.',
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
                        'Site metinlerini ve ayarlarını buradan yönetirsin.',
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
