import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/recipient_models.dart';
import '../services/ai_matching_service.dart';

class AiMatchingIndicator extends StatelessWidget {
  const AiMatchingIndicator({
    super.key,
    required this.summary,
  });

  final AiMatchingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final percent = (summary.overallScore * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(loc.t('aiMatching.title'), style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '$percent%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: summary.overallScore,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            color: _scoreColor(summary.overallScore),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${summary.totalDonorsInPool} donations in pool · auto-matched to needs',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ...summary.itemResults.map((result) => _MatchRow(result: result)),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return AppTheme.accentTeal;
    if (score >= 0.5) return AppTheme.primaryBlue;
    return Colors.orange.shade600;
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.result});

  final ItemMatchResult result;

  @override
  Widget build(BuildContext context) {
    final (icon, color, detail) = switch (result.status) {
      MatchStatus.matched => (
          Icons.check_circle,
          AppTheme.accentTeal,
          '${result.donorsFound} donor(s) · ZIP ${result.nearestDonorZip}',
        ),
      MatchStatus.partial => (
          Icons.adjust,
          Colors.orange.shade700,
          '${result.donorsFound} of ${result.item.quantity} found · ZIP ${result.nearestDonorZip}',
        ),
      MatchStatus.searching => (
          Icons.search,
          Colors.grey.shade500,
          'No matches yet — expanding search radius',
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.item.displayText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            matchStatusLabel(result.status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
