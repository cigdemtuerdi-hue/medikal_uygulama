import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/wishlist_service.dart';
import 'urgent_need_badge.dart';

/// Banner showing unread Instant Match alerts for the current recipient.
class InstantMatchBanner extends StatelessWidget {
  const InstantMatchBanner({
    super.key,
    this.onOpenItem,
  });

  final void Function(String itemId)? onOpenItem;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: WishlistService.instance,
      builder: (context, _) {
        final service = WishlistService.instance;
        final unread = service.unreadAlerts;
        if (unread.isEmpty) return const SizedBox.shrink();

        final latest = unread.first;

        return Card(
          color: const Color(0xFFE8F5E9),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.t('wishlist.matchBannerTitle'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                            ),
                      ),
                    ),
                    if (unread.length > 1)
                      Chip(
                        label: Text('${unread.length}'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                      ),
                    IconButton(
                      tooltip: loc.t('wishlist.dismiss'),
                      onPressed: () => service.dismissAlert(latest.id),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                Text(
                  loc.t('wishlist.matchBannerBody', {
                    'item': latest.itemTitle,
                    'wish': latest.wishlistLabel,
                  }),
                ),
                if (latest.priorityMatch) ...[
                  const SizedBox(height: 8),
                  const PriorityMatchBadge(compact: true),
                ],
                const SizedBox(height: 6),
                Text(
                  loc.t('wishlist.emailSimulated', {
                    'email': latest.recipientEmail,
                  }),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        service.markAlertRead(latest.id);
                        onOpenItem?.call(latest.itemId);
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(loc.t('wishlist.viewMatch')),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppTheme.primaryDeepBlue,
                      ),
                    ),
                    TextButton(
                      onPressed: service.markAllAlertsRead,
                      child: Text(loc.t('wishlist.markAllRead')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
