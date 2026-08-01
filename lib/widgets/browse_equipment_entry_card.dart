import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/site_settings_service.dart';

/// Home / Profile shortcut to the Recipient equipment browser + distance map.
class BrowseEquipmentEntryCard extends StatelessWidget {
  const BrowseEquipmentEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: cms,
      builder: (context, _) {
        final h = cms.settings.home;
        final title =
            cms.text(h.browseTitle, loc.t('browseEquipment.entryTitle'));
        final body =
            cms.text(h.browseBody, loc.t('browseEquipment.entryBody'));

        return Card(
          color: AppTheme.skyBlue.withValues(alpha: 0.35),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.browse);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: const Icon(Icons.near_me, color: Colors.white),
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
                                    color: AppTheme.primaryDeepBlue,
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
                  Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
