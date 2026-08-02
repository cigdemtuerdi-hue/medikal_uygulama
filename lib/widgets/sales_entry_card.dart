import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';

/// Home shortcut into the paid equipment marketplace.
class SalesEntryCard extends StatelessWidget {
  const SalesEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                      'Satış / Shop',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDeepBlue,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bağış yapmak istemiyorsanız ekipmanınızı satın. '
                      'Her satışta %17 MedGift komisyonu uygulanır.',
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
