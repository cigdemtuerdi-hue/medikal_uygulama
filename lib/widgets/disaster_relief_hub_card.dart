import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/disaster_models.dart';
import '../services/emergency_mode_service.dart';

/// Logistics card: staging hub + field-team delivery address for disaster gear.
class DisasterReliefHubCard extends StatelessWidget {
  const DisasterReliefHubCard({
    super.key,
    this.zone,
    this.compact = false,
  });

  /// When null, shows the primary active hub (or all hubs briefly).
  final DisasterZone? zone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EmergencyModeService.instance,
      builder: (context, _) {
        if (!EmergencyModeService.instance.enabled) {
          return const SizedBox.shrink();
        }

        final loc = AppLocalizations.of(context);
        final hubs = zone != null
            ? [zone!]
            : EmergencyModeService.activeZones;

        return Card(
          color: const Color(0xFFB71C1C).withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: const Color(0xFFC62828).withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC62828).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warehouse_outlined,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('disaster.hubCardTitle'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB71C1C),
                                ),
                          ),
                          Text(
                            loc.t('disaster.hubCardSubtitle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < hubs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _HubBlock(zone: hubs[i]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HubBlock extends StatelessWidget {
  const _HubBlock({required this.zone});

  final DisasterZone zone;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cleanWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC62828).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zone.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_city_outlined,
            label: loc.t('disaster.hubNameLabel'),
            value: zone.hubName,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.pin_drop_outlined,
            label: loc.t('disaster.hubAddressLabel'),
            value: zone.hubAddress,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.groups_outlined,
            label: loc.t('disaster.fieldTeamLabel'),
            value: zone.fieldTeamContact,
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('disaster.priorityNeedsLabel'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final need in zone.priorityNeeds)
                Chip(
                  label: Text(need, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      const Color(0xFFC62828).withValues(alpha: 0.08),
                  side: BorderSide(
                    color: const Color(0xFFC62828).withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFC62828)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: Colors.black87,
                  ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
