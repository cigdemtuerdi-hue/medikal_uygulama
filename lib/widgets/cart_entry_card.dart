import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/cart_service.dart';

/// Home shortcut into Sepetim (shopping cart).
class CartEntryCard extends StatelessWidget {
  const CartEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    CartService.instance.ensureLoaded();

    return ListenableBuilder(
      listenable: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.count;
        final subtitle = count > 0
            ? loc.t('cart.entryBodyCount', {
                'count': '$count',
                'total': CartService.instance.totalLabel,
              })
            : loc.t('cart.entryBody');

        return Card(
          color: AppTheme.primaryDeepBlue.withValues(alpha: 0.08),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.cart),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryDeepBlue,
                    child: Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 9 ? '9+' : '$count'),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('cart.entryTitle'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryDeepBlue,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
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
