import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../services/item_lifecycle_service.dart';
import '../services/site_settings_service.dart';

/// Home / Profile entry point so Pass-It-On is easy to find.
class PassItOnEntryCard extends StatelessWidget {
  const PassItOnEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ItemLifecycleService.instance,
        cms,
      ]),
      builder: (context, _) {
        final count = ItemLifecycleService.instance.myReceivedItems.length;
        final h = cms.settings.home;
        final title = cms.text(h.passItOnTitle, loc.t('passItOn.entryTitle'));
        final bodyTemplate = h.passItOnBody.trim();
        final body = bodyTemplate.isEmpty
            ? loc.t('passItOn.entryBody', {'count': count})
            : bodyTemplate.replaceAll('{count}', '$count');

        return Card(
          color: const Color(0xFFFFF3E0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.myItems);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepOrange.shade700,
                    child: const Icon(Icons.replay, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.deepOrange.shade900,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.deepOrange.shade700),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}