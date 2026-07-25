import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';

/// Compact icon badge showing the donor's handoff / transport option.
class HandoffOptionBadge extends StatelessWidget {
  const HandoffOptionBadge({
    super.key,
    required this.option,
    this.compact = false,
    this.showHint = false,
  });

  final HandoffOption option;
  final bool compact;
  final bool showHint;

  static IconData iconFor(HandoffOption option) {
    return switch (option) {
      HandoffOption.pickupOnly => Icons.home_outlined,
      HandoffOption.assistanceAvailable => Icons.handshake_outlined,
      HandoffOption.meetupPossible => Icons.place_outlined,
    };
  }

  static Color colorFor(HandoffOption option) {
    return switch (option) {
      HandoffOption.pickupOnly => const Color(0xFF1565C0),
      HandoffOption.assistanceAvailable => const Color(0xFF2E7D32),
      HandoffOption.meetupPossible => const Color(0xFF6A1B9A),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = colorFor(option);
    final icon = iconFor(option);
    final label = locHandoffOption(loc, option);

    if (showHint) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locHandoffOptionHint(loc, option),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      avatar: Icon(icon, size: compact ? 16 : 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 12 : 13,
        ),
      ),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 4)
          : const EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Radio-style picker used on Add Item forms.
class HandoffOptionPicker extends StatelessWidget {
  const HandoffOptionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HandoffOption value;
  final ValueChanged<HandoffOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('handoff.formTitle'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          loc.t('handoff.formSubtitle'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ...HandoffOption.values.map((option) {
          final selected = option == value;
          final color = HandoffOptionBadge.colorFor(option);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected
                  ? color.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? color
                          : Colors.grey.withValues(alpha: 0.35),
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        HandoffOptionBadge.iconFor(option),
                        color: color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locHandoffOption(loc, option),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? color : null,
                              ),
                            ),
                            Text(
                              locHandoffOptionHint(loc, option),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selected ? color : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
