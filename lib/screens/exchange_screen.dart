import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/exchange_models.dart';
import '../services/ai_vision_service.dart';
import '../services/donation_service.dart';
import '../services/exchange_service.dart';
import '../services/tax_receipt_pdf_service.dart';
import '../widgets/common_widgets.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _service = ExchangeService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmExchange(ExchangeTransaction exchange) async {
    final receipts = _service.completeExchange(exchange);
    if (receipts.isEmpty || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _ReceiptsIssuedDialog(receipts: receipts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final exchanges = _service.exchanges;

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('exchange.appBarTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: loc.t('exchange.sectionTitle'),
              subtitle: loc.t('exchange.sectionSubtitle'),
            ),
            const SizedBox(height: 16),
            ...exchanges.map(
              (exchange) => _ExchangeCard(
                exchange: exchange,
                onConfirm: () => _confirmExchange(exchange),
              ),
            ),
            const SizedBox(height: 8),
            const ComplianceBanner(),
          ],
        ),
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({required this.exchange, required this.onConfirm});

  final ExchangeTransaction exchange;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isCompleted = exchange.status == ExchangeStatus.completed;
    final isWide = MediaQuery.sizeOf(context).width > 900;
    final gives = loc.t('exchange.gives');

    final assetCards = [
      Expanded(
        child: _AssetTile(
          owner: exchange.partyA,
          asset: exchange.assetFromA,
          direction: gives,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Icon(Icons.swap_horiz, size: 32, color: AppTheme.primaryBlue),
      ),
      Expanded(
        child: _AssetTile(
          owner: exchange.partyB,
          asset: exchange.assetFromB,
          direction: gives,
        ),
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(exchange.id),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Chip(
                  avatar: Icon(
                    isCompleted ? Icons.check_circle : Icons.pending_outlined,
                    size: 18,
                    color: isCompleted ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                  label: Text(
                    isCompleted
                        ? loc.t('exchange.statusCompleted')
                        : loc.t('exchange.statusAwaiting'),
                  ),
                  backgroundColor: isCompleted
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isWide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: assetCards)
            else
              Column(
                children: [
                  _AssetTile(
                    owner: exchange.partyA,
                    asset: exchange.assetFromA,
                    direction: gives,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.swap_vert, size: 28),
                  ),
                  _AssetTile(
                    owner: exchange.partyB,
                    asset: exchange.assetFromB,
                    direction: gives,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (isCompleted)
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.t('exchange.completedBanner', {
                        'date': formatDonationDate(exchange.completedAt!),
                      }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade800,
                          ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.handshake_outlined),
                  label: Text(loc.t('exchange.confirmButton')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.owner,
    required this.asset,
    required this.direction,
  });

  final ExchangeUser owner;
  final ExchangeAsset asset;
  final String direction;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                child: Text(
                  owner.name.substring(0, 1),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.t('exchange.ownerGives', {
                    'name': owner.name,
                    'direction': direction,
                  }),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(asset.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            loc.t('exchange.assetMeta', {
              'id': asset.assetId,
              'category': locCategory(loc, asset.category),
              'qty': asset.quantity,
            }),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            locCondition(loc, asset.condition),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('exchange.fmv', {
              'amount': formatUsd(asset.fairMarketValueUsd),
            }),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.accentTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptsIssuedDialog extends StatefulWidget {
  const _ReceiptsIssuedDialog({required this.receipts});

  final List<ExchangeTaxReceipt> receipts;

  @override
  State<_ReceiptsIssuedDialog> createState() => _ReceiptsIssuedDialogState();
}

class _ReceiptsIssuedDialogState extends State<_ReceiptsIssuedDialog> {
  final Set<String> _downloading = {};

  Future<void> _download(ExchangeTaxReceipt receipt) async {
    setState(() => _downloading.add(receipt.receiptNumber));
    final message =
        await TaxReceiptPdfService.instance.downloadExchangeReceipt(receipt);
    if (!mounted) return;
    setState(() => _downloading.remove(receipt.receiptNumber));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(loc.t('exchange.dialogTitle'))),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('exchange.dialogBody')),
            const SizedBox(height: 16),
            for (final receipt in widget.receipts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(receipt.pdfFileName),
                subtitle: Text(
                  loc.t('exchange.dialogReceiptSubtitle', {
                    'name': receipt.donor.name,
                    'title': receipt.asset.title,
                  }),
                ),
                trailing: _downloading.contains(receipt.receiptNumber)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.download_outlined),
                        tooltip: loc.t('exchange.downloadPdfTooltip'),
                        onPressed: () => _download(receipt),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('common.done')),
        ),
      ],
    );
  }
}
