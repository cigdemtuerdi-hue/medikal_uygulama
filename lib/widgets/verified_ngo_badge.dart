import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Blue verified badge for approved NGO / non-profit partners.
class VerifiedNgoBadge extends StatelessWidget {
  const VerifiedNgoBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const color = Color(0xFF1565C0);

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
          Icon(Icons.verified, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            loc.t('ngo.verifiedBadge'),
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
