import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/available_donation_item.dart';
import '../models/delivery_models.dart';
import '../models/donation_models.dart';
import '../models/profile_address.dart';
import '../services/delivery_service.dart';
import '../services/donation_label_pdf_service.dart';
import '../services/donation_service.dart';
import '../services/emergency_mode_service.dart';
import '../services/item_lifecycle_service.dart';
import '../services/profile_address_service.dart';
import '../services/proximity_matching_service.dart';
import '../services/reservation_service.dart';
import '../widgets/disaster_emergency_widgets.dart';
import '../widgets/disaster_relief_hub_card.dart';
import '../widgets/fda_safety_verified_badge.dart';
import '../widgets/handoff_option_badge.dart';
import '../widgets/item_journey_timeline.dart';
import '../widgets/item_proximity_map_card.dart';
import '../widgets/liability_waiver_widgets.dart';
import '../widgets/proximity_badges.dart';
import '../widgets/reservation_countdown.dart';
import '../widgets/route_pickup_guide_sheet.dart';
import '../widgets/sizing_compatibility_guide_card.dart';
import '../widgets/urgent_need_badge.dart';
import 'qr_scanner_screen.dart';
import 'secure_chat_screen.dart';

class DmeProductDetailScreen extends StatefulWidget {
  const DmeProductDetailScreen({
    super.key,
    required this.item,
  });

  final AvailableDonationItem item;

  @override
  State<DmeProductDetailScreen> createState() => _DmeProductDetailScreenState();
}

class _DmeProductDetailScreenState extends State<DmeProductDetailScreen> {
  final _profileAddressService = ProfileAddressService.instance;
  final _reservationService = ReservationService.instance;
  ProfileAddress? _recipientAddress;
  bool _downloadingLabel = false;
  bool _waiverAccepted = false;
  String? _waiverError;

  @override
  void initState() {
    super.initState();
    _loadRecipientAddress();
    _reservationService.addListener(_onReservationChanged);
    DeliveryService.instance.addListener(_onReservationChanged);
  }

  @override
  void dispose() {
    _reservationService.removeListener(_onReservationChanged);
    DeliveryService.instance.removeListener(_onReservationChanged);
    super.dispose();
  }

  void _onReservationChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _downloadLabel() async {
    final loc = AppLocalizations.of(context);
    final item = widget.item;
    setState(() => _downloadingLabel = true);
    final message = await DonationLabelPdfService.instance.downloadLabel(
      DonationLabelData(
        itemId: item.id,
        title: item.title,
        categoryLabel: item.dmeType != null
            ? loc.t('common.categoryDme')
            : loc.t('common.categoryMedicalSupply'),
        conditionLabel: locCondition(loc, item.condition),
        quantity: item.quantityAvailable,
        donorAreaLabel: item.donorAreaLabel,
        brand: item.brand,
        model: item.model,
      ),
    );
    if (!mounted) return;
    setState(() => _downloadingLabel = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QrScannerScreen()),
    );
  }

  Future<void> _loadRecipientAddress() async {
    final address = await _profileAddressService.loadRecipientAddress();
    if (!mounted) return;
    setState(() => _recipientAddress = address);
  }

  Future<void> _requestPickup() async {
    final loc = AppLocalizations.of(context);
    if (!_waiverAccepted) {
      setState(() => _waiverError = loc.t('waiver.requiredError'));
      return;
    }
    setState(() => _waiverError = null);

    final recipientProfile = ProfileAddressService.matchedRecipient;
    final recipient = _recipientAddress ??
        ProfileAddress(
          roleLabel: 'Recipient',
          zipCode: recipientProfile.zipCode,
          city: recipientProfile.city,
          state: recipientProfile.state,
          name: recipientProfile.name,
        );

    final confirmed = await showRoutePickupGuideSheet(
      context: context,
      item: widget.item,
      recipient: recipient,
    );
    if (!confirmed || !mounted) return;

    final reservation = _reservationService.reserveItem(
      widget.item,
      recipientName: recipientProfile.name,
    );
    if (reservation == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.t('detail.reservedSnack', {'title': widget.item.title}),
        ),
      ),
    );
  }

  void _confirmReceivedAndInspected() {
    final loc = AppLocalizations.of(context);
    final recipient = ProfileAddressService.matchedRecipient;
    DeliveryService.instance.confirmDelivery(
      widget.item,
      confirmedBy: recipient.name,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('waiver.signOffSnack'))),
    );
  }

  void _openChat() {
    final reservation = _reservationService.reservationFor(widget.item.id);
    if (reservation == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SecureChatScreen(
          item: widget.item,
          reservation: reservation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final item = widget.item;
    final reservation = _reservationService.reservationFor(item.id);
    final isDelivered = DeliveryService.instance.isDelivered(item.id);
    final delivery = DeliveryService.instance.deliveryFor(item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('detail.appBarTitle')),
        actions: [
          IconButton(
            onPressed: _downloadingLabel ? null : _downloadLabel,
            icon: _downloadingLabel
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_2),
            tooltip: loc.t('detail.downloadLabelTooltip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconForItem(item),
                            color: AppTheme.primaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (item.brand != null)
                                Text(
                                  '${item.brand}${item.model != null ? ' · ${item.model}' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(item.description),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        HandoffOptionBadge(option: item.handoffOption),
                        if (item.fdaSafetyVerified)
                          const FdaSafetyVerifiedBadge(),
                        if (item.disasterReliefAllocation)
                          const CrisisReliefNeedBadge(),
                        if (item.priorityToUrgentRequests)
                          const PriorityMatchBadge(),
                        if (_recipientAddress != null)
                          Builder(
                            builder: (context) {
                              final miles = ProximityMatchingService.instance
                                  .estimateMilesToItem(
                                recipient: _recipientAddress!,
                                item: item,
                              );
                              if (miles == null) {
                                return const SizedBox.shrink();
                              }
                              return ProximityMilesAwayChip(miles: miles);
                            },
                          ),
                        _InfoChip(
                          icon: Icons.verified_outlined,
                          label: locCondition(loc, item.condition),
                        ),
                        _InfoChip(
                          icon: Icons.inventory_2_outlined,
                          label: loc.t('detail.qtyAvailable', {
                            'qty': item.quantityAvailable,
                          }),
                        ),
                        _InfoChip(
                          icon: Icons.shield_outlined,
                          label: loc.t('detail.donorProtected'),
                        ),
                        if (reservation != null)
                          _InfoChip(
                            icon: Icons.lock_outline,
                            label: loc.t('detail.reservedChip'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.t('handoff.detailSection'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    HandoffOptionBadge(
                      option: item.handoffOption,
                      showHint: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (item.sizing != null && item.sizing!.hasAnyValue)
              SizingCompatibilityGuideCard(sizing: item.sizing!)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.architecture, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.t('sizing.unavailable'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (item.disasterReliefAllocation ||
                EmergencyModeService.instance.enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DisasterReliefHubCard(
                  zone: EmergencyModeService.instance
                      .zoneForZip(item.donorZipCode),
                  compact: true,
                ),
              ),
            if (_recipientAddress != null) ...[
              Builder(
                builder: (context) {
                  final guide =
                      ProximityMatchingService.instance.buildRouteGuide(
                    recipient: _recipientAddress!,
                    item: item,
                  );
                  if (!guide.isLocal) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EcoTransportBadge(co2KgSaved: guide.ecoCo2KgSaved),
                  );
                },
              ),
              ItemProximityMapCard(
                recipient: _recipientAddress!,
                item: item,
              ),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: ItemLifecycleService.instance,
              builder: (context, _) {
                final journey =
                    ItemLifecycleService.instance.journeyForItemId(item.id);
                if (journey == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ItemJourneyCard(record: journey),
                );
              },
            ),
            if (isDelivered)
              Card(
                color: Colors.green.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          delivery != null
                              ? loc.t('detail.deliveryConfirmedOn', {
                                  'date': formatDonationDate(delivery.confirmedAt),
                                })
                              : loc.t('detail.deliveryConfirmed'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.green.shade800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (reservation == null) ...[
              LiabilityWaiverCheckbox(
                value: _waiverAccepted,
                errorText: _waiverError,
                onChanged: (value) {
                  setState(() {
                    _waiverAccepted = value ?? false;
                    if (_waiverAccepted) _waiverError = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _requestPickup,
                icon: const Icon(Icons.route_outlined),
                label: Text(loc.t('proximity.requestPickup')),
              ),
            ]
            else ...[
              Card(
                color: Colors.orange.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.orange.shade800),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.t('detail.reservedFor', {
                                'name': reservation.reservedByName,
                              }),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          ReservationCountdown(
                            reservation: reservation,
                            prefix: loc.t('detail.holdExpiresPrefix'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.t('detail.lockedHelp'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.t('waiver.signOffHelp'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _confirmReceivedAndInspected,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(loc.t('waiver.signOffButton')),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(loc.t('detail.scanConfirmDelivery')),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(loc.t('detail.deliveryChat')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _reservationService.cancelReservation(item.id),
                    icon: const Icon(Icons.close),
                    label: Text(loc.t('detail.cancelHold')),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _downloadingLabel ? null : _downloadLabel,
              icon: const Icon(Icons.print_outlined),
              label: Text(
                _downloadingLabel
                    ? loc.t('common.generatingLabel')
                    : loc.t('detail.downloadLabelButton'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForItem(AvailableDonationItem item) {
    return switch (item.dmeType) {
      DmeType.wheelchair => Icons.accessible,
      DmeType.walker => Icons.directions_walk,
      DmeType.oxygenEquipment => Icons.air,
      _ => Icons.medical_services_outlined,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryDeepBlue),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
