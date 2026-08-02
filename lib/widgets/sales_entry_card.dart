import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Home shortcut into the paid equipment marketplace.
class SalesEntryCard extends StatelessWidget {
  const SalesEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.shop),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryDeepBlue,
                child: const Icon(Icons.storefront_outlined, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('shop.entryTitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDeepBlue,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.t('shop.entryBody'),
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
  }
}
