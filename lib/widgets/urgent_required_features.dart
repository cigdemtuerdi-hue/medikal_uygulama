import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/wishlist_models.dart';
import '../services/wishlist_service.dart';

/// Required features form block for urgent wishlist requests.
class UrgentRequiredFeaturesField extends StatelessWidget {
  const UrgentRequiredFeaturesField({
    super.key,
    required this.controller,
    this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rtl, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.t('urgent.featuresSectionTitle'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade800,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                loc.t('urgent.featuresRequiredChip'),
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          loc.t('urgent.featuresSectionHint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            labelText: loc.t('urgent.featuresLabel'),
            hintText: loc.t('urgent.featuresHint'),
            alignLabelWithHint: true,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// Donor-facing panel showing required features for an urgent request.
class UrgentDonorRequirementsPanel extends StatelessWidget {
  const UrgentDonorRequirementsPanel({
    super.key,
    required this.description,
    this.compact = false,
  });

  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final text = description.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule,
                size: compact ? 18 : 20,
                color: Colors.deepOrange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.t('urgent.featuresDonorTitle'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.deepOrange.shade900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            loc.t('urgent.featuresDonorIntro'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.deepOrange.shade800,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact list of open urgent needs + required features on donate forms.
class UrgentNeedsForDonorsCard extends StatelessWidget {
  const UrgentNeedsForDonorsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: WishlistService.instance,
      builder: (context, _) {
        final urgent = WishlistService.instance.urgentEntries
            .where((e) => e.hasDonorRequirements)
            .toList();
        if (urgent.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.t('urgent.donorCheckTitle'),
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  loc.t('urgent.donorCheckSubtitle'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ...urgent.take(3).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DonorUrgentNeedTile(entry: entry),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DonorUrgentNeedTile extends StatelessWidget {
  const _DonorUrgentNeedTile({required this.entry});

  final WishlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.displayText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (entry.dmeType != null) ...[
            const SizedBox(height: 2),
            Text(
              locDmeType(loc, entry.dmeType!),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          UrgentDonorRequirementsPanel(
            description: entry.requiredFeaturesDescription!,
            compact: true,
          ),
        ],
      ),
    );
  }
}
