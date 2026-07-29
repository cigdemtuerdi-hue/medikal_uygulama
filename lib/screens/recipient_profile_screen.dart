import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/available_donation_item.dart';
import '../models/donation_models.dart';
import '../models/profile_address.dart';
import '../models/proximity_models.dart';
import '../models/recipient_models.dart';
import '../models/wishlist_models.dart';
import '../services/ai_matching_service.dart';
import '../services/available_items_service.dart';
import '../services/delivery_service.dart';
import '../services/profile_address_service.dart';
import '../services/proximity_matching_service.dart';
import '../services/reservation_service.dart';
import '../services/wishlist_service.dart';
import '../widgets/ai_matching_indicator.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/disaster_emergency_widgets.dart';
import '../widgets/disaster_relief_hub_card.dart';
import '../widgets/handoff_option_badge.dart';
import '../widgets/instant_match_banner.dart';
import '../widgets/proximity_badges.dart';
import '../widgets/reservation_countdown.dart';
import '../widgets/urgent_need_badge.dart';
import '../widgets/wishlist_section_card.dart';
import 'dme_product_detail_screen.dart';
import 'qr_scanner_screen.dart';

class RecipientProfileScreen extends StatefulWidget {
  const RecipientProfileScreen({super.key});

  @override
  State<RecipientProfileScreen> createState() => _RecipientProfileScreenState();
}

class _RecipientProfileScreenState extends State<RecipientProfileScreen> {
  final _matchingService = AiMatchingService();
  final _reservationService = ReservationService.instance;
  final _itemsService = AvailableItemsService.instance;
  final _searchController = TextEditingController();

  DmeType? _categoryFilter;
  ItemCondition? _conditionFilter;
  ProximityRange? _proximityFilter;

  late final RecipientProfile _recipient = ProfileAddressService.matchedRecipient;

  late AiMatchingSummary _matching = _matchingService.matchForRecipient(_recipient);

  @override
  void initState() {
    super.initState();
    _reservationService.addListener(_onReservationChanged);
    DeliveryService.instance.addListener(_onReservationChanged);
    _itemsService.addListener(_onReservationChanged);
    WishlistService.instance.addListener(_onReservationChanged);
    _searchController.addListener(_onReservationChanged);
  }

  @override
  void dispose() {
    _reservationService.removeListener(_onReservationChanged);
    DeliveryService.instance.removeListener(_onReservationChanged);
    _itemsService.removeListener(_onReservationChanged);
    WishlistService.instance.removeListener(_onReservationChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _addCurrentSearchToWishlist() {
    final loc = AppLocalizations.of(context);
    final result = WishlistService.instance.addFromSearch(
      query: _searchController.text,
      categoryFilter: _categoryFilter,
    );
    final message = switch (result) {
      WishlistAddResult.added => loc.t('wishlist.addedSnack'),
      WishlistAddResult.duplicate => loc.t('wishlist.duplicateSnack'),
      WishlistAddResult.empty => loc.t('wishlist.emptyLabelSnack'),
      WishlistAddResult.missingFeatures =>
        loc.t('urgent.featuresRequiredError'),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onReservationChanged() {
    if (mounted) setState(() {});
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _categoryFilter = null;
      _conditionFilter = null;
      _proximityFilter = null;
    });
  }

  List<AvailableDonationItem> _filteredItems(AppLocalizations loc) {
    final query = _searchController.text.trim().toLowerCase();
    final proximity = ProximityMatchingService.instance;
    final recipientAddress = ProfileAddress(
      roleLabel: 'Recipient',
      zipCode: _recipient.zipCode,
      city: _recipient.city,
      state: _recipient.state,
      name: _recipient.name,
    );

    return _itemsService.allItems.where((item) {
      if (_categoryFilter != null && item.dmeType != _categoryFilter) {
        return false;
      }
      if (_conditionFilter != null && item.condition != _conditionFilter) {
        return false;
      }
      if (_proximityFilter != null) {
        final miles = proximity.estimateMilesToItem(
          recipient: recipientAddress,
          item: item,
        );
        final ok = proximity.matchesProximityFilter(
          range: _proximityFilter!,
          miles: miles,
          recipientState: _recipient.state,
          donorState: item.donorState,
        );
        if (!ok) return false;
      }
      if (query.isEmpty) return true;

      final haystack = [
        item.title,
        item.description,
        item.brand ?? '',
        item.model ?? '',
        if (item.dmeType != null) locDmeType(loc, item.dmeType!),
        locCondition(loc, item.condition),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList()
      ..sort((a, b) {
        // Pin disaster / crisis relief allocations to the top.
        final ac = a.disasterReliefAllocation ? 0 : 1;
        final bc = b.disasterReliefAllocation ? 0 : 1;
        return ac.compareTo(bc);
      });
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QrScannerScreen()),
    );
  }

  void _refreshMatching() {
    setState(() {
      _matching = _matchingService.matchForRecipient(_recipient);
    });
  }

  void _openItemDetail(BuildContext context, String itemId) {
    final item = AvailableItemsService.instance.findById(itemId);
    if (item == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DmeProductDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = _filteredItems(loc);
    final hasActiveFilters = _searchController.text.trim().isNotEmpty ||
        _categoryFilter != null ||
        _conditionFilter != null ||
        _proximityFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('recipient.appBarTitle')),
        actions: [
          IconButton(
            onPressed: _openQrScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: loc.t('recipient.scanQrTooltip'),
          ),
          IconButton(
            onPressed: _refreshMatching,
            icon: const Icon(Icons.sync_outlined),
            tooltip: loc.t('recipient.refreshMatchingTooltip'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: Text(
                            _recipient.initials,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recipient.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${_recipient.city}, ${_recipient.state} ${_recipient.zipCode}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _openQrScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(loc.t('recipient.scanQrButton')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InstantMatchBanner(onOpenItem: (id) => _openItemDetail(context, id)),
                const SizedBox(height: 16),
                const DisasterReliefHubCard(compact: true),
                const SizedBox(height: 16),
                Text(
                  loc.t('recipient.browseTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDeepBlue,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('recipient.browseSubtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('search.title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: loc.t('search.title'),
                    hintText: loc.t('search.hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: loc.t('a11y.clearSearch'),
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DmeType?>(
                        key: ValueKey('category-$_categoryFilter'),
                        initialValue: _categoryFilter,
                        decoration: InputDecoration(
                          labelText: loc.t('search.categoryLabel'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<DmeType?>(
                            value: null,
                            child: Text(loc.t('search.allCategories')),
                          ),
                          ...DmeType.values.map(
                            (type) => DropdownMenuItem<DmeType?>(
                              value: type,
                              child: Text(locDmeType(loc, type)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryFilter = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ItemCondition?>(
                        key: ValueKey('condition-$_conditionFilter'),
                        initialValue: _conditionFilter,
                        decoration: InputDecoration(
                          labelText: loc.t('search.conditionLabel'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<ItemCondition?>(
                            value: null,
                            child: Text(loc.t('search.allConditions')),
                          ),
                          ...ItemCondition.values.map(
                            (condition) => DropdownMenuItem<ItemCondition?>(
                              value: condition,
                              child: Text(locCondition(loc, condition)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _conditionFilter = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProximityRange?>(
                  key: ValueKey('proximity-$_proximityFilter'),
                  initialValue: _proximityFilter,
                  decoration: InputDecoration(
                    labelText: loc.t('proximity.filterLabel'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.near_me_outlined),
                  ),
                  items: [
                    DropdownMenuItem<ProximityRange?>(
                      value: null,
                      child: Text(loc.t('proximity.allDistances')),
                    ),
                    ...ProximityRange.values.map(
                      (range) => DropdownMenuItem<ProximityRange?>(
                        value: range,
                        child: Text(loc.t(range.l10nKey)),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _proximityFilter = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      loc.t('search.resultsCount', {'count': items.length}),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (hasActiveFilters)
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(loc.t('search.clearFilters')),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  EmptyStateCard(
                    icon: Icons.search_off_outlined,
                    title: loc.t('empty.searchTitle'),
                    body: loc.t('empty.searchBody'),
                    action: FilledButton.icon(
                      onPressed: _addCurrentSearchToWishlist,
                      icon: const Icon(Icons.playlist_add),
                      label: Text(loc.t('wishlist.saveSearchCta')),
                    ),
                  ),
                ...items.map(
                  (item) {
                    final reservation =
                        _reservationService.reservationFor(item.id);
                    final isDelivered =
                        DeliveryService.instance.isDelivered(item.id);
                    final isLocked = !isDelivered && reservation != null;
                    final miles =
                        ProximityMatchingService.instance.estimateMilesToItem(
                      recipient: ProfileAddress(
                        roleLabel: 'Recipient',
                        zipCode: _recipient.zipCode,
                        city: _recipient.city,
                        state: _recipient.state,
                        name: _recipient.name,
                      ),
                      item: item,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isDelivered
                              ? Colors.green.withValues(alpha: 0.15)
                              : isLocked
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : AppTheme.skyBlue.withValues(alpha: 0.35),
                          child: Icon(
                            isDelivered
                                ? Icons.check_circle_outline
                                : isLocked
                                    ? Icons.lock_outline
                                    : _iconForItem(item.dmeType),
                            color: isDelivered
                                ? Colors.green.shade700
                                : isLocked
                                    ? Colors.orange.shade800
                                    : AppTheme.primaryDeepBlue,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${locCondition(loc, item.condition)} · '
                              '${item.donorCity != null && item.donorState != null ? '${item.donorCity}, ${item.donorState} ${item.donorZipCode}' : loc.t('common.zipArea', {'zip': item.donorZipCode})}',
                            ),
                            if (miles != null) ...[
                              const SizedBox(height: 6),
                              ProximityMilesAwayChip(
                                miles: miles,
                                compact: true,
                              ),
                            ],
                            const SizedBox(height: 6),
                            HandoffOptionBadge(
                              option: item.handoffOption,
                              compact: true,
                            ),
                            if (item.disasterReliefAllocation) ...[
                              const SizedBox(height: 6),
                              const CrisisReliefNeedBadge(compact: true),
                            ],
                            if (item.priorityToUrgentRequests) ...[
                              const SizedBox(height: 6),
                              const PriorityMatchBadge(compact: true),
                            ],
                            if (isLocked)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    ReservationCountdown(
                                      reservation: reservation,
                                      prefix: loc.t('recipient.reservedPrefix'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: isDelivered
                            ? Chip(
                                label: Text(loc.t('recipient.chipDelivered')),
                                visualDensity: VisualDensity.compact,
                                backgroundColor:
                                    Colors.green.withValues(alpha: 0.12),
                                labelStyle: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 12,
                                ),
                              )
                            : isLocked
                                ? Chip(
                                    label: Text(loc.t('recipient.chipOnHold')),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        Colors.orange.withValues(alpha: 0.12),
                                    labelStyle: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 12,
                                    ),
                                    side: BorderSide(
                                      color:
                                          Colors.orange.withValues(alpha: 0.4),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                        onTap: () => _openItemDetail(context, item.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const WishlistSectionCard(),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AiMatchingIndicator(summary: _matching),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForItem(DmeType? type) {
    return switch (type) {
      DmeType.wheelchair => Icons.accessible,
      DmeType.walker => Icons.directions_walk,
      DmeType.oxygenEquipment => Icons.air,
      _ => Icons.medical_services_outlined,
    };
  }
}
