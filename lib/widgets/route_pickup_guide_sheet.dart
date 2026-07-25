import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/available_donation_item.dart';
import '../models/profile_address.dart';
import '../models/proximity_models.dart';
import '../services/proximity_matching_service.dart';
import 'proximity_badges.dart';

/// Opens the Smart Proximity Route & Pickup Guide bottom sheet.
/// Returns `true` if the user confirms the pickup / reservation.
Future<bool> showRoutePickupGuideSheet({
  required BuildContext context,
  required AvailableDonationItem item,
  required ProfileAddress recipient,
  bool requireConfirm = true,
}) async {
  final guide = ProximityMatchingService.instance.buildRouteGuide(
    recipient: recipient,
    item: item,
  );

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _RoutePickupGuideSheet(
        item: item,
        guide: guide,
        requireConfirm: requireConfirm,
      );
    },
  );

  return confirmed == true;
}

class _RoutePickupGuideSheet extends StatelessWidget {
  const _RoutePickupGuideSheet({
    required this.item,
    required this.guide,
    required this.requireConfirm,
  });

  final AvailableDonationItem item;
  final RoutePickupGuide guide;
  final bool requireConfirm;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: AppTheme.primaryDeepBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('proximity.routeGuideTitle'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDeepBlue,
                        ),
                      ),
                      Text(
                        loc.t('proximity.routeGuideSubtitle'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MapPreviewBanner(guide: guide),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.t('proximity.routeBetween', {
                'from': guide.recipientAreaLabel ?? '',
                'to': guide.donorAreaLabel ?? item.donorAreaLabel,
              }),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.social_distance_outlined,
                    label: loc.t('proximity.estimatedDistance'),
                    value: loc.t('proximity.milesValue', {
                      'miles': guide.formattedMiles,
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.directions_car_outlined,
                    label: loc.t('proximity.driveTime'),
                    value: loc.t('proximity.driveMinutes', {
                      'minutes': guide.driveMinutes,
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: AppTheme.primaryDeepBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('proximity.recommendedSpotLabel'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDeepBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guide.recommendedSpot,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (guide.isLocal) ...[
              const SizedBox(height: 12),
              EcoTransportBadge(co2KgSaved: guide.ecoCo2KgSaved),
              const SizedBox(height: 6),
              Text(
                loc.t('proximity.ecoTransportHint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (requireConfirm) ...[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.lock_clock_outlined),
                label: Text(loc.t('proximity.confirmPickup')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.t('proximity.closeGuide')),
              ),
            ] else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.t('proximity.closeGuide')),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewBanner extends StatelessWidget {
  const _MapPreviewBanner({required this.guide});

  final RoutePickupGuide guide;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDeepBlue,
            AppTheme.primaryBlue,
            AppTheme.lightBlue.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.map_outlined,
              size: 120,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('proximity.routePreviewTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        guide.recipientAreaLabel ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                  child: Icon(
                    Icons.more_vert,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        guide.donorAreaLabel ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.skyBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDeepBlue,
                ),
          ),
        ],
      ),
    );
  }
}
