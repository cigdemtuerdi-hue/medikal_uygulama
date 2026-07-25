import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/urgent_need_models.dart';

/// Red/orange priority tag for active urgent medical needs.
class UrgentNeedBadge extends StatelessWidget {
  const UrgentNeedBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.showCountdownHours,
  });

  final UrgentVerificationStatus status;
  final bool compact;
  final int? showCountdownHours;

  bool get _isUrgent =>
      status == UrgentVerificationStatus.verified ||
      status == UrgentVerificationStatus.pending;

  @override
  Widget build(BuildContext context) {
    if (!_isUrgent) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final verified = status == UrgentVerificationStatus.verified;
    final color = verified ? Colors.red.shade700 : Colors.deepOrange.shade700;
    final label = verified
        ? loc.t('urgent.badgeUrgentNeed')
        : loc.t('urgent.badgePendingReview');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.priority_high : Icons.hourglass_top,
            size: compact ? 14 : 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 11,
              letterSpacing: 0.6,
            ),
          ),
          if (verified && showCountdownHours != null) ...[
            const SizedBox(width: 6),
            Text(
              loc.t('urgent.hoursLeft', {'hours': showCountdownHours!}),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 9 : 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Donor listing tag: prioritizes matching urgent recipient requests.
class PriorityMatchBadge extends StatelessWidget {
  const PriorityMatchBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const color = Color(0xFFE65100);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            loc.t('urgent.priorityMatch'),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle + optional medical proof upload for request forms.
class UrgentNeedRequestToggle extends StatelessWidget {
  const UrgentNeedRequestToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        Icons.medical_services_outlined,
        color: value ? Colors.red.shade700 : null,
      ),
      title: Text(
        loc.t('urgent.requestToggle'),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: value ? Colors.red.shade800 : null,
        ),
      ),
      subtitle: Text(loc.t('urgent.requestToggleHint')),
    );
  }
}

/// Donor-side priority matching preference.
class PriorityToUrgentToggle extends StatelessWidget {
  const PriorityToUrgentToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          Icons.bolt,
          color: value ? const Color(0xFFE65100) : null,
        ),
        title: Text(
          loc.t('urgent.donorPriorityToggle'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(loc.t('urgent.donorPriorityHint')),
      ),
    );
  }
}
