import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/medgift_logo.dart';
import '../widgets/medgift_manifesto_section.dart';
import '../widgets/partnership_footer.dart';

/// About Us — brand story and The MedGift Manifesto.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('about.appBarTitle')),
        actions: const [LanguageMenuButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: MedGiftBrand(showLabel: true, logoSize: 64),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.t('about.title'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.t('about.intro'),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  const MedGiftManifestoSection(),
                  const PartnershipFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
