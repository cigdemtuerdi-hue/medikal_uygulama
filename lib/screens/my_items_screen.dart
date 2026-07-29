import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/available_donation_item.dart';
import '../models/delivery_models.dart';
import '../models/donation_models.dart';
import '../models/item_lifecycle_models.dart';
import '../services/available_items_service.dart';
import '../services/donation_label_pdf_service.dart';
import '../services/donation_service.dart';
import '../services/item_lifecycle_service.dart';
import '../services/ai_vision_service.dart' show formatUsd;
import '../widgets/async_state_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/item_journey_timeline.dart';
import 'dme_product_detail_screen.dart';

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final donated = DonationService.donationHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('myItems.appBarTitle')),
      ),
      body: ListenableBuilder(
        listenable: ItemLifecycleService.instance,
        builder: (context, _) {
          final received = ItemLifecycleService.instance.myReceivedItems;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SectionHeader(
                title: loc.t('passItOn.receivedSectionTitle'),
                subtitle: loc.t('passItOn.receivedSectionSubtitle'),
              ),
              const SizedBox(height: 12),
              if (received.isEmpty)
                EmptyStateCard(
                  icon: Icons.volunteer_activism_outlined,
                  title: loc.t('passItOn.receivedSectionTitle'),
                  body: loc.t('passItOn.receivedEmpty'),
                  padding: const EdgeInsets.all(24),
                )
              else
                ...received.map(
                  (record) => _ReceivedItemCard(record: record),
                ),
              const SizedBox(height: 28),
              SectionHeader(
                title: loc.t('myItems.sectionTitle'),
                subtitle: loc.t('myItems.sectionSubtitle'),
              ),
              const SizedBox(height: 16),
              if (donated.isEmpty)
                EmptyStateCard(
                  icon: Icons.inventory_2_outlined,
                  title: loc.t('myItems.emptyTitle'),
                  body: loc.t('myItems.emptyBody'),
                )
              else
                ...donated.map((record) => _MyItemCard(record: record)),
            ],
          );
        },
      ),
    );
  }
}

class _ReceivedItemCard extends StatefulWidget {
  const _ReceivedItemCard({required this.record});

  final ItemLifecycleRecord record;

  @override
  State<_ReceivedItemCard> createState() => _ReceivedItemCardState();
}

class _ReceivedItemCardState extends State<_ReceivedItemCard> {
  bool _passingOn = false;

  Future<void> _passItOn() async {
    final loc = AppLocalizations.of(context);
    final title = widget.record.title;
    setState(() => _passingOn = true);

    final result =
        ItemLifecycleService.instance.passItOn(widget.record.lineageId);

    if (!mounted) return;
    setState(() => _passingOn = false);

    final message = switch (result) {
      PassItOnResult.listed => loc.t('passItOn.successSnack', {
          'title': title,
        }),
      PassItOnResult.notOwned => loc.t('passItOn.errorNotOwned'),
      PassItOnResult.alreadyPassedOn => loc.t('passItOn.errorAlreadyPassed'),
      PassItOnResult.itemMissing => loc.t('passItOn.errorMissing'),
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (result != PassItOnResult.listed) return;

    final journey =
        ItemLifecycleService.instance.journeyForLineage(widget.record.lineageId);
    final listed = journey == null
        ? null
        : AvailableItemsService.instance.findById(journey.currentItemId) ??
            _copyWithId(journey.snapshot, journey.currentItemId);
    if (listed == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DmeProductDetailScreen(item: listed),
      ),
    );
  }

  AvailableDonationItem _copyWithId(AvailableDonationItem src, String id) {
    return AvailableDonationItem(
      id: id,
      title: src.title,
      description: src.description,
      condition: src.condition,
      donorZipCode: src.donorZipCode,
      donorCity: src.donorCity,
      donorState: src.donorState,
      brand: src.brand,
      model: src.model,
      dmeType: src.dmeType,
      quantityAvailable: src.quantityAvailable,
      sizing: src.sizing,
      handoffOption: src.handoffOption,
      priorityToUrgentRequests: src.priorityToUrgentRequests,
      fdaSafetyVerified: src.fdaSafetyVerified,
      disasterReliefAllocation: src.disasterReliefAllocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final record = widget.record;
    final co2 = ItemLifecycleService.instance.co2SavedKgFor(record);
    final co2Label = co2.round().toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.t('passItOn.receivedMeta', {
                          'lives': record.livesImpacted,
                          'co2': co2Label,
                        }),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ItemJourneyCard(record: record),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _passingOn ? null : _passItOn,
                icon: _passingOn
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.replay),
                label: Text(
                  _passingOn
                      ? loc.t('passItOn.passingOn')
                      : loc.t('passItOn.cta'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.t('passItOn.ctaHint'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyItemCard extends StatefulWidget {
  const _MyItemCard({required this.record});

  final DonationRecord record;

  @override
  State<_MyItemCard> createState() => _MyItemCardState();
}

class _MyItemCardState extends State<_MyItemCard> {
  bool _downloadingLabel = false;

  Future<void> _downloadLabel() async {
    final loc = AppLocalizations.of(context);
    final record = widget.record;
    setState(() => _downloadingLabel = true);

    final message = await DonationLabelPdfService.instance.downloadLabel(
      DonationLabelData(
        itemId: record.id,
        title: record.title,
        categoryLabel: locCategory(loc, record.category),
        conditionLabel: locCondition(loc, record.condition),
        quantity: record.quantity,
        donorAreaLabel: loc.t('common.zipArea', {'zip': record.zipCode}),
        brand: record.brand,
        model: record.model,
      ),
    );

    if (!mounted) return;
    setState(() => _downloadingLabel = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final record = widget.record;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
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
              title: Text(record.title),
              subtitle: Text(
                loc.t('myItems.itemSubtitle', {
                  'category': locCategory(loc, record.category),
                  'qty': record.quantity,
                  'zip': record.zipCode,
                }),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatUsd(record.taxDeductionUsd),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.accentOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    loc.t('myItems.deductionLabel'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadingLabel ? null : _downloadLabel,
                icon: _downloadingLabel
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2),
                label: Text(
                  _downloadingLabel
                      ? loc.t('common.generatingLabel')
                      : loc.t('myItems.downloadLabel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
