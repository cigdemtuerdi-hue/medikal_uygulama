import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/fda_safety_models.dart';

/// Live FDA Safety Compliance Status indicator for donate forms.
class FdaSafetyComplianceCard extends StatelessWidget {
  const FdaSafetyComplianceCard({
    super.key,
    required this.result,
  });

  final FdaSafetyCheckResult result;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    late final Color color;
    late final IconData icon;
    late final String title;
    late final String body;

    switch (result.status) {
      case FdaSafetyStatus.idle:
        color = AppTheme.primaryBlue;
        icon = Icons.health_and_safety_outlined;
        title = loc.t('fda.complianceIdleTitle');
        body = loc.t('fda.complianceIdleBody');
      case FdaSafetyStatus.checking:
        color = AppTheme.primaryBlue;
        icon = Icons.hourglass_top_rounded;
        title = loc.t('fda.complianceCheckingTitle');
        body = loc.t('fda.complianceCheckingBody');
      case FdaSafetyStatus.verified:
        color = const Color(0xFF2E7D32);
        icon = Icons.verified_user;
        title = loc.t('fda.complianceVerifiedTitle');
        body = loc.t('fda.complianceVerifiedBody', {
          'item': result.checkedLabel ?? '',
        });
      case FdaSafetyStatus.recall:
        color = const Color(0xFFC62828);
        icon = Icons.warning_amber_rounded;
        title = loc.t('fda.complianceRecallTitle');
        body = loc.t('fda.recallBlockWarning');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (result.status == FdaSafetyStatus.checking)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.t('fda.complianceStatusLabel'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          if (result.isRecall && result.recall != null) ...[
            const SizedBox(height: 8),
            Text(
              loc.t('fda.recallMeta', {
                'id': result.recall!.recallId,
                'brand': result.recall!.brand,
                'model': result.recall!.model,
              }),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
