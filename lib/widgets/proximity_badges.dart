import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/proximity_matching_service.dart';

/// Chip showing dynamic distance from the viewer, e.g. "📍 3.2 miles away from you".
class ProximityMilesAwayChip extends StatelessWidget {
  const ProximityMilesAwayChip({
    super.key,
    required this.miles,
    this.compact = false,
  });

  final double miles;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final formatted =
        ProximityMatchingService.instance.formatMilesAway(miles);
    const color = Color(0xFF1565C0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            loc.t('proximity.milesAway', {'miles': formatted}),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Green Eco-Transport impact badge for local pickup.
class EcoTransportBadge extends StatelessWidget {
  const EcoTransportBadge({
    super.key,
    required this.co2KgSaved,
    this.compact = false,
  });

  final double co2KgSaved;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const color = Color(0xFF2E7D32);
    final kg = co2KgSaved < 10
        ? co2KgSaved.toStringAsFixed(0)
        : co2KgSaved.round().toString();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              loc.t('proximity.ecoTransportSaves', {'kg': kg}),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
