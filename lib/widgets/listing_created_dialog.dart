import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/delivery_models.dart';
import '../services/donation_label_pdf_service.dart';

/// Shown after a donation listing is created — offers the printable
/// MedGift / QR donation label PDF.
class ListingCreatedDialog extends StatefulWidget {
  const ListingCreatedDialog({
    super.key,
    required this.label,
    this.instantMatchCount = 0,
  });

  final DonationLabelData label;
  final int instantMatchCount;

  @override
  State<ListingCreatedDialog> createState() => _ListingCreatedDialogState();
}

class _ListingCreatedDialogState extends State<ListingCreatedDialog> {
  bool _downloading = false;

  Future<void> _downloadLabel() async {
    setState(() => _downloading = true);
    final message =
        await DonationLabelPdfService.instance.downloadLabel(widget.label);
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(loc.t('listing.createdTitle'))),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('listing.createdBody', {
                'title': widget.label.title,
                'qty': widget.label.quantity,
              }),
            ),
            if (widget.instantMatchCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                loc.t('wishlist.listingMatchNote', {
                  'count': widget.instantMatchCount,
                }),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Text(loc.t('listing.printHelp')),
            const SizedBox(height: 8),
            Text(
              loc.t('listing.itemId', {'id': widget.label.itemId}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('common.later')),
        ),
        FilledButton.icon(
          onPressed: _downloading ? null : _downloadLabel,
          icon: _downloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.qr_code_2),
          label: Text(
            _downloading
                ? loc.t('common.generating')
                : loc.t('listing.downloadLabel'),
          ),
        ),
      ],
    );
  }
}
