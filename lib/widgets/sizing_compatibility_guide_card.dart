import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/equipment_sizing_specs.dart';

/// Visual "Sizing & Compatibility Guide" for recipients reviewing a DME item.
class SizingCompatibilityGuideCard extends StatelessWidget {
  const SizingCompatibilityGuideCard({super.key, required this.sizing});

  final EquipmentSizingSpecs sizing;

  String _inches(AppLocalizations loc, double value) =>
      loc.t('sizing.valueInches', {'value': _fmt(value)});

  String _lbs(AppLocalizations loc, double value) =>
      loc.t('sizing.valueLbs', {'value': _fmt(value)});

  String _fmt(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (!sizing.hasAnyValue) return const SizedBox.shrink();

    final doorway = sizing.fitsStandardDoorway;
    final rows = <_SpecRow>[
      if (sizing.seatWidthInches != null)
        _SpecRow(
          icon: Icons.straighten,
          label: loc.t('sizing.seatWidth'),
          value: _inches(loc, sizing.seatWidthInches!),
          highlight: true,
        ),
      if (sizing.weightCapacityLbs != null)
        _SpecRow(
          icon: Icons.monitor_weight_outlined,
          label: loc.t('sizing.weightCapacity'),
          value: _lbs(loc, sizing.weightCapacityLbs!),
          highlight: true,
        ),
      if (sizing.widthInches != null)
        _SpecRow(
          icon: Icons.swap_horiz,
          label: loc.t('sizing.overallWidth'),
          value: _inches(loc, sizing.widthInches!),
        ),
      if (sizing.depthInches != null)
        _SpecRow(
          icon: Icons.swap_vert,
          label: loc.t('sizing.overallDepth'),
          value: _inches(loc, sizing.depthInches!),
        ),
      if (sizing.heightInches != null)
        _SpecRow(
          icon: Icons.height,
          label: loc.t('sizing.overallHeight'),
          value: _inches(loc, sizing.heightInches!),
        ),
      if (sizing.seatToFloorInches != null)
        _SpecRow(
          icon: Icons.airline_seat_recline_normal_outlined,
          label: loc.t('sizing.seatToFloor'),
          value: _inches(loc, sizing.seatToFloorInches!),
        ),
      if (sizing.wheelSizeInches != null)
        _SpecRow(
          icon: Icons.album_outlined,
          label: loc.t('sizing.wheelSize'),
          value: _inches(loc, sizing.wheelSizeInches!),
        ),
      if (sizing.minUserHeightInches != null ||
          sizing.maxUserHeightInches != null)
        _SpecRow(
          icon: Icons.accessibility_new,
          label: loc.t('sizing.userHeight'),
          value: loc.t('sizing.userHeightRange', {
            'min': sizing.minUserHeightInches != null
                ? _fmt(sizing.minUserHeightInches!)
                : '—',
            'max': sizing.maxUserHeightInches != null
                ? _fmt(sizing.maxUserHeightInches!)
                : '—',
          }),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.architecture,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('sizing.guideTitle'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDeepBlue,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.t('sizing.guideSubtitle'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (doorway != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: doorway
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: doorway
                        ? Colors.green.withValues(alpha: 0.35)
                        : Colors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      doorway ? Icons.check_circle_outline : Icons.info_outline,
                      color: doorway
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doorway
                            ? loc.t('sizing.fitsDoorwayYes')
                            : loc.t('sizing.fitsDoorwayNo'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: doorway
                                  ? Colors.green.shade800
                                  : Colors.orange.shade900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final row in rows)
                  _SpecChip(
                    icon: row.icon,
                    label: row.label,
                    value: row.value,
                    highlight: row.highlight,
                  ),
              ],
            ),
            if (sizing.notes != null && sizing.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                loc.t('sizing.notesLabel'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(sizing.notes!.trim()),
            ],
            const SizedBox(height: 12),
            Text(
              loc.t('sizing.disclaimer'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow {
  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.skyBlue.withValues(alpha: 0.35)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppTheme.primaryBlue.withValues(alpha: 0.25)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryDeepBlue),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDeepBlue,
                ),
          ),
        ],
      ),
    );
  }
}
