import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);
    final productIcon = productLeadingIcon(result);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                loc.t('aiScan.engineBadge'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          loc.t('aiScan.matchPercent', {
                            'percent': (result.confidence * 100).round(),
                          }),
                          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                        ),
                        if (result.isDme) const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            productIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _ValueRow(
                      label: loc.t('aiScan.category'),
                      value: result.category,
                      icon: isWheelchairProduct(result)
                          ? Icons.accessible
                          : Icons.category_outlined,
                    ),
                const SizedBox(height: 12),
                _ValueRow(
                  label: loc.t('aiScan.brand'),
                  value: result.brand,
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 12),
                _ValueRow(
                  label: loc.t('fda.modelLabel'),
                  value: result.model,
                  icon: Icons.qr_code_2_outlined,
                ),
                const SizedBox(height: 12),
                _ValueRow(
                  label: loc.t('aiScan.condition'),
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
                          const Icon(Icons.payments_outlined, color: AppTheme.accentOnSurface),
                          const SizedBox(width: 8),
                          Text(
                            loc.t('aiScan.estimatedValue'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.accentOnSurface,
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
                  title: loc.t('fda.complianceIdleTitle'),
                  body: result.fdaNote,
                  icon: Icons.policy_outlined,
                ),
                const SizedBox(height: 12),
                _NoteBox(
                  title: loc.t('aiScan.recommendation'),
                  body: result.recommendation,
                  icon: Icons.lightbulb_outline,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: Icon(productIcon),
                  label: Text(loc.t('aiScan.continueDonate')),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
        if (result.isDme)
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 12,
            end: 12,
            child: _DmeBadge(icon: productIcon, label: loc.t('aiScan.dmeBadge')),
          ),
      ],
    );
  }
}

bool isWheelchairProduct(AiVisionResult result) {
  final haystack =
      '${result.productName} ${result.model} ${result.category}'.toLowerCase();
  return haystack.contains('wheelchair') ||
      haystack.contains('tekerlekli sandalye');
}

IconData productLeadingIcon(AiVisionResult result) {
  if (isWheelchairProduct(result)) return Icons.accessible;

  final productLabel = result.productName.toLowerCase();
  if (productLabel.contains('rollator') || productLabel.contains('walker')) {
    return Icons.directions_walk;
  }
  if (productLabel.contains('oxygen') ||
      result.category.toLowerCase().contains('respiratory')) {
    return Icons.air;
  }
  if (result.isDme) return Icons.medical_services_outlined;
  return Icons.healing_outlined;
}

class _DmeBadge extends StatelessWidget {
  const _DmeBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.accentTeal,
            AppTheme.lightBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
