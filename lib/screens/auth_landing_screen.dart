import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/site_settings_service.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/medgift_logo.dart';
import '../widgets/medgift_manifesto_section.dart';
import '../widgets/partnership_footer.dart';
import '../widgets/ai_support_chat_widget.dart';
import 'about_us_screen.dart';
import 'onboarding/role_selection_screen.dart';

/// First-screen Login / Sign Up landing with manifesto and Partner with Us.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  void _openSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AiSupportHost(child: RoleSelectionScreen()),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  void _openForgotPassword(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  void _openAboutUs(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AiSupportHost(child: AboutUsScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: cms,
      builder: (context, _) {
        final s = cms.settings;
        final welcomeTitle =
            cms.text(s.landing.welcomeTitle, loc.t('auth.welcomeTitle'));
        final welcomeSubtitle =
            cms.text(s.landing.welcomeSubtitle, loc.t('auth.welcomeSubtitle'));
        final loginCta = cms.text(s.landing.loginCta, loc.t('auth.logIn'));
        final signupCta = cms.text(s.landing.signupCta, loc.t('auth.signUp'));

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: const [LanguageMenuButton()],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: _AdminEntryLogo(),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        welcomeTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDeepBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        welcomeSubtitle,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Center(child: LanguageMenuButton()),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _openLogin(context),
                        icon: const Icon(Icons.login),
                        label: Text(loginCta),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openSignUp(context),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(signupCta),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openForgotPassword(context),
                        icon: const Icon(Icons.lock_reset_outlined),
                        label: Text(loc.t('auth.forgotPasswordCta')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.t('auth.newHere'),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _openAboutUs(context),
                        child: Text(loc.t('about.openLink')),
                      ),
                      const SizedBox(height: 24),
                      const MedGiftManifestoSection(),
                      if (s.flags.showPartnershipFooter)
                        const PartnershipFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Long-press logo → owner CMS (hidden from casual users).
class _AdminEntryLogo extends StatelessWidget {
  const _AdminEntryLogo();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Navigator.of(context).pushNamed(AppRoutes.admin);
      },
      child: const MedGiftBrand(
        showLabel: true,
        logoSize: 72,
      ),
    );
  }
}
