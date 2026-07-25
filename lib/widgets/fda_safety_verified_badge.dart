import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Green badge for listings that passed the FDA Safety Checker.
class FdaSafetyVerifiedBadge extends StatelessWidget {
  const FdaSafetyVerifiedBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const color = Color(0xFF2E7D32);

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
          Icon(Icons.verified_user, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            loc.t('fda.verifiedBadge'),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
