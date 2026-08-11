import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/site_settings_service.dart';
import '../widgets/founding_story_welcome.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/medgift_logo.dart';
import '../widgets/medgift_manifesto_section.dart';
import '../widgets/partnership_footer.dart';

/// About Us — founding story, manifesto, and Partner with Us.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: cms,
      builder: (context, _) {
        final s = cms.settings;
        final appBar =
            cms.text(s.about.appBarTitle, loc.t('about.appBarTitle'));

        return Scaffold(
          appBar: AppBar(
            title: Text(appBar),
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
                      const FoundingStoryContent(),
                      const SizedBox(height: 28),
                      if (s.flags.showManifesto)
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
