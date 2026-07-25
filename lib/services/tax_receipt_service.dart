import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/donation_models.dart';
import 'ai_vision_service.dart';
import 'donation_service.dart';
import 'tax_receipt_pdf_service.dart';

class TaxReceiptService {
  Future<void> downloadReceipt(BuildContext context, DonationRecord record) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _TaxReceiptDialog(record: record),
    );
  }

  String buildReceiptText(DonationRecord record) {
    final donor = DonationService.donorProfile;
    final dmeNote = record.category == DonationCategory.dme
        ? '''

DME EQUIPMENT DONATION NOTE
───────────────────────────
This donation qualifies as durable medical equipment (DME). The item
was donated in the condition stated above and received by a qualified
501(c)(3) healthcare organization for charitable use. Retain device
photos and inspection records with your tax documentation per IRS
Publication 561.
'''
        : '';

    return '''
MEDGIFT US — CHARITABLE DONATION TAX RECEIPT
═══════════════════════════════════════════
Receipt No: ${record.receiptNumber}
Date of Donation: ${formatDonationDate(record.donatedAt)}
Tax Year: ${record.donatedAt.year}

DONOR INFORMATION
─────────────────
Name: ${donor.name}
Email: ${donor.email}
ZIP: ${donor.zipCode}

QUALIFYING 501(c)(3) ORGANIZATION
─────────────────────────────────
Organization: ${record.organizationName}
EIN: ${record.organizationEin}
IRS Status: Tax-exempt under IRC Section 501(c)(3)

DONATED PROPERTY (NO GOODS OR SERVICES PROVIDED)
────────────────────────────────────────────────
Item: ${record.title}
${record.brand != null ? 'Brand: ${record.brand}\n' : ''}${record.model != null ? 'Model: ${record.model}\n' : ''}Category: ${DonationService.categoryLabel(record.category)}
Condition: ${conditionLabel(record.condition)}
Quantity: ${record.quantity}
Fair Market Value (Est. Retail): ${formatUsd(record.estimatedRetailValueUsd)}
Tax-Deductible Amount: ${formatUsd(record.taxDeductionUsd)}

IRS COMPLIANCE NOTE
───────────────────
No goods or services were provided in exchange for this donation.
The donor is responsible for determining the fair market value per
IRS Publication 561. Retain this receipt for your tax records.
$dmeNote
MedGift US · medgift.us · support@medgift.us
''';
  }
}

class _TaxReceiptDialog extends StatefulWidget {
  const _TaxReceiptDialog({required this.record});

  final DonationRecord record;

  @override
  State<_TaxReceiptDialog> createState() => _TaxReceiptDialogState();
}

class _TaxReceiptDialogState extends State<_TaxReceiptDialog> {
  final _service = TaxReceiptService();
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    final message = await TaxReceiptPdfService.instance
        .downloadDonationReceipt(widget.record);
    if (!mounted) return;
    setState(() => _isDownloading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _service.downloadReceipt(context, widget.record),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptText = _service.buildReceiptText(widget.record);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('501(c)(3) Tax Receipt'),
                Text(
                  widget.record.receiptNumber,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              receiptText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).t('common.close')),
        ),
        FilledButton.icon(
          onPressed: _isDownloading ? null : _downloadPdf,
          icon: _isDownloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(_isDownloading ? 'Downloading...' : 'Download Tax Receipt'),
        ),
      ],
    );
  }
}
