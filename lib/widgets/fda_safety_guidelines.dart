import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Opens the Safety & Maintenance Guidelines checklist modal.
Future<void> showFdaSafetyGuidelinesDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Row(
          children: [
            const Icon(
              Icons.checklist_rtl_outlined,
              color: AppTheme.primaryDeepBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.t('fda.guidelinesTitle'),
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
                  loc.t('fda.guidelinesIntro'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                _GuidelineStep(
                  number: '1',
                  text: loc.t('fda.guidelineClean'),
                ),
                const SizedBox(height: 10),
                _GuidelineStep(
                  number: '2',
                  text: loc.t('fda.guidelineInspect'),
                ),
                const SizedBox(height: 10),
                _GuidelineStep(
                  number: '3',
                  text: loc.t('fda.guidelineLabel'),
                ),
                const SizedBox(height: 10),
                _GuidelineStep(
                  number: '4',
                  text: loc.t('fda.guidelineAccessories'),
                ),
                const SizedBox(height: 10),
                _GuidelineStep(
                  number: '5',
                  text: loc.t('fda.guidelineRecall'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.t('fda.guidelinesClose')),
          ),
        ],
      );
    },
  );
}

/// Text button that opens the safety guidelines modal.
class FdaSafetyGuidelinesLink extends StatelessWidget {
  const FdaSafetyGuidelinesLink({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showFdaSafetyGuidelinesDialog(context),
        icon: const Icon(Icons.menu_book_outlined, size: 18),
        label: Text(loc.t('fda.guidelinesLink')),
      ),
    );
  }
}

class _GuidelineStep extends StatelessWidget {
  const _GuidelineStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
