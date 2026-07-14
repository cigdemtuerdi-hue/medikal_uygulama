import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/donation_models.dart';
import '../services/ai_vision_service.dart';
import '../services/donation_service.dart';

class AiScanResultCard extends StatelessWidget {
  const AiScanResultCard({
    super.key,
    required this.result,
    this.onContinue,
  });

  final AiVisionResult result;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryDeepBlue,
                  AppTheme.primaryBlue,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'GPT-4o Vision',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(result.confidence * 100).round()}% match',
                      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  result.productName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.brand} · ${result.model}',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _ValueRow(
                  label: 'Category',
                  value: result.category,
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 12),
                _ValueRow(
                  label: 'Brand',
                  value: result.brand,
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 12),
                _ValueRow(
                  label: 'Model',
                  value: result.model,
                  icon: Icons.qr_code_2_outlined,
                ),
                const SizedBox(height: 12),
                _ValueRow(
                  label: 'Condition',
                  value: conditionLabel(result.suggestedCondition),
                  icon: Icons.fact_check_outlined,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: AppTheme.accentTeal),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated Retail Value',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.accentTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatUsd(result.estimatedRetailValueUsd),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.taxDeductionNote,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _NoteBox(
                  title: 'FDA / Safety',
                  body: result.fdaNote,
                  icon: Icons.policy_outlined,
                ),
                const SizedBox(height: 12),
                _NoteBox(
                  title: 'Recommendation',
                  body: result.recommendation,
                  icon: Icons.lightbulb_outline,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: Icon(result.isDme ? Icons.accessible : Icons.healing),
                  label: Text(
                    result.isDme
                        ? 'Continue to DME Donation Form'
                        : 'Continue to Wound Care Form',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
