import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';
import '../services/ai_vision_service.dart';
import '../services/donation_service.dart' show formatDonationDate;
import '../services/tax_receipt_service.dart';

class DonationHistoryCard extends StatelessWidget {
  const DonationHistoryCard({
    super.key,
    required this.record,
  });

  final DonationRecord record;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final taxService = TaxReceiptService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: record.category == DonationCategory.dme
                      ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                      : AppTheme.accentTeal.withValues(alpha: 0.12),
                  child: Icon(
                    record.category == DonationCategory.dme
                        ? Icons.accessible
                        : Icons.healing,
                    color: record.category == DonationCategory.dme
                        ? AppTheme.primaryBlue
                        : AppTheme.accentTeal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      if (record.brand != null && record.model != null)
                        Text(
                          '${record.brand} · ${record.model}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        loc.t('donationHistory.meta', {
                          'category': locCategory(loc, record.category),
                          'condition': locCondition(loc, record.condition),
                          'qty': record.quantity,
                        }),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatUsd(record.taxDeductionUsd),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.accentOnSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      loc.t('donationHistory.taxDeductionLabel'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.apartment_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.t('donationHistory.orgLine', {
                      'org': record.organizationName,
                      'ein': record.organizationEin,
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  formatDonationDate(record.donatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Chip(
                  label: Text(record.receiptNumber),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => taxService.downloadReceipt(context, record),
                icon: const Icon(Icons.download_outlined),
                label: Text(loc.t('donationHistory.downloadReceipt')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
