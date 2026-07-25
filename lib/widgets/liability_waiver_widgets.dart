import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Opens the Liability Waiver & Terms informational dialog.
Future<void> showLiabilityWaiverDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Row(
          children: [
            const Icon(Icons.gavel_outlined, color: AppTheme.primaryDeepBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.t('waiver.modalTitle'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('waiver.modalIntro'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                _WaiverClause(
                  icon: Icons.hub_outlined,
                  text: loc.t('waiver.clausePlatform'),
                ),
                const SizedBox(height: 12),
                _WaiverClause(
                  icon: Icons.health_and_safety_outlined,
                  text: loc.t('waiver.clauseAsIs'),
                ),
                const SizedBox(height: 12),
                _WaiverClause(
                  icon: Icons.shield_outlined,
                  text: loc.t('waiver.clauseRelease'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.t('waiver.close')),
          ),
        ],
      );
    },
  );
}

class _WaiverClause extends StatelessWidget {
  const _WaiverClause({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryDeepBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Required acknowledgment checkbox with a tappable Liability Waiver link.
class LiabilityWaiverCheckbox extends StatelessWidget {
  const LiabilityWaiverCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      loc.t('waiver.checkboxBefore'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    InkWell(
                      onTap: () => showLiabilityWaiverDialog(context),
                      child: Text(
                        loc.t('waiver.checkboxLink'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Text(
                      loc.t('waiver.checkboxAfter'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
