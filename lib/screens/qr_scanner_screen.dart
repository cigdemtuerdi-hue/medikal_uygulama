import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/available_donation_item.dart';
import '../services/available_items_service.dart';
import '../services/delivery_service.dart';
import '../services/donation_service.dart';
import '../services/profile_address_service.dart';
import '../services/reservation_service.dart';

/// Recipient scans the QR code on the MedGift donation label at handoff
/// to confirm the delivery.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handlingCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingCode) return;
    final rawValue = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    await _handleCode(rawValue);
  }

  Future<void> _handleCode(String payload) async {
    if (_handlingCode) return;
    _handlingCode = true;

    try {
      final itemId = DeliveryService.parseItemId(payload);
      if (itemId == null) {
        _showError(
          'This QR code is not a MedGift delivery label. '
          'Look for the QR code on the printed MedGift donation label.',
        );
        return;
      }

      final item = AvailableItemsService.instance.findById(itemId);
      if (item == null) {
        _showError('No listing found for code "$itemId".');
        return;
      }

      if (DeliveryService.instance.isDelivered(itemId)) {
        _showError('This delivery was already confirmed.');
        return;
      }

      await _controller.stop();
      if (!mounted) return;

      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _DeliveryConfirmSheet(item: item),
      );

      if (!mounted) return;

      if (confirmed == true) {
        Navigator.of(context).pop();
      } else {
        await _controller.start();
      }
    } finally {
      _handlingCode = false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Demo helper — same flow as a real camera scan, using the QR payload
  /// that is printed on the item's donation label.
  Future<void> _simulateScan(AvailableDonationItem item) async {
    await _handleCode(DeliveryService.qrPayloadFor(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final undelivered = AvailableItemsService.instance.allItems
        .where((item) => !DeliveryService.instance.isDelivered(item.id))
        .toList();
    final reservedItems = undelivered
        .where((item) => ReservationService.instance.isReserved(item.id))
        .toList();
    final demoItems =
        reservedItems.isNotEmpty ? reservedItems : undelivered.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('qr.scanTitle'))),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner,
                    size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Point the camera at the QR code on the MedGift donation '
                    'label to confirm you received the item.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraUnavailable(
                    error: error,
                  ),
                ),
                // Viewfinder frame overlay.
                IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (demoItems.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservedItems.isNotEmpty
                          ? 'No printed label handy? Simulate scanning a reserved item:'
                          : 'Demo (web/camera unavailable): simulate scanning a label QR:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in demoItems)
                          ActionChip(
                            avatar: const Icon(Icons.qr_code_2, size: 18),
                            label: Text(item.title),
                            onPressed: () => _simulateScan(item),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              'Camera unavailable (${error.errorCode.name}). '
              'Allow camera access in your browser, or use the simulate '
              'buttons below.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryConfirmSheet extends StatefulWidget {
  const _DeliveryConfirmSheet({required this.item});

  final AvailableDonationItem item;

  @override
  State<_DeliveryConfirmSheet> createState() => _DeliveryConfirmSheetState();
}

class _DeliveryConfirmSheetState extends State<_DeliveryConfirmSheet> {
  bool _confirming = false;

  Future<void> _confirm() async {
    setState(() => _confirming = true);

    final recipient = ProfileAddressService.matchedRecipient;
    DeliveryService.instance.confirmDelivery(
      widget.item,
      confirmedBy: recipient.name,
    );

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delivery confirmed — ${widget.item.title} was received. '
          'Thank you for using MedGift!',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reservation = ReservationService.instance.reservationFor(item.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Label scanned successfully',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Item ${item.id} · ${conditionLabel(item.condition)}\n'
                    'From donor area: ${item.donorAreaLabel}'
                    '${reservation != null ? '\nReserved by: ${reservation.reservedByName}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'By confirming, you verify that you physically received this '
              'item in the described condition. The 48-hour hold will be '
              'closed and the donor will be notified.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirming
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context).t('common.cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirming ? null : _confirm,
                    icon: _confirming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _confirming ? 'Confirming...' : 'Confirm Delivery',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
