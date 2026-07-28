import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/available_donation_item.dart';
import '../models/item_proximity_result.dart';
import '../models/profile_address.dart';
import '../services/maps_distance_service.dart';
import '../services/proximity_matching_service.dart';
import 'proximity_map_preview.dart';

class ItemProximityMapCard extends StatefulWidget {
  const ItemProximityMapCard({
    super.key,
    required this.recipient,
    required this.item,
  });

  final ProfileAddress recipient;
  final AvailableDonationItem item;

  @override
  State<ItemProximityMapCard> createState() => _ItemProximityMapCardState();
}

class _ItemProximityMapCardState extends State<ItemProximityMapCard> {
  ItemProximityResult? _result;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProximity();
  }

  ItemProximityResult? _offlineResult() {
    final proximity = ProximityMatchingService.instance;
    final recipientLatLng = proximity.latLngForZip(widget.recipient.zipCode);
    final donorCenter = proximity.latLngForZip(widget.item.donorZipCode);
    if (recipientLatLng == null || donorCenter == null) return null;

    final miles = proximity.estimateMilesBetweenZips(
          widget.recipient.zipCode,
          widget.item.donorZipCode,
        ) ??
        0;

    final donorAreaLabel = widget.item.donorCity != null &&
            widget.item.donorState != null
        ? '${widget.item.donorCity}, ${widget.item.donorState} ${widget.item.donorZipCode} area'
        : 'ZIP ${widget.item.donorZipCode} area';

    return ItemProximityResult(
      distanceText: _formatDistance(miles),
      distanceMiles: miles,
      recipientLocation: recipientLatLng,
      donorAreaCenter: donorCenter,
      donorAreaRadiusMeters: MapsDistanceService.donorPrivacyRadiusMeters,
      donorAreaLabel: donorAreaLabel,
    );
  }

  String _formatDistance(double miles) {
    if (miles < 0.1) {
      return 'This item is in your area (same ZIP region)';
    }
    if (miles < 10) {
      return 'This item is ${miles.toStringAsFixed(1)} miles away from you';
    }
    return 'This item is ${miles.round()} miles away from you';
  }

  Future<void> _loadProximity() async {
    final offline = _offlineResult();
    if (offline != null && mounted) {
      setState(() {
        _result = offline;
        _isLoading = false;
        _hasError = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    final refined = await MapsDistanceService.instance.calculateItemProximity(
      recipient: widget.recipient,
      donorZipCode: widget.item.donorZipCode,
      donorCity: widget.item.donorCity,
      donorState: widget.item.donorState,
    );

    if (!mounted) return;

    setState(() {
      _result = refined ?? offline;
      _isLoading = false;
      _hasError = _result == null;
      _errorMessage = _result == null
          ? 'Could not estimate distance for these ZIP codes.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.near_me_outlined,
                        color: AppTheme.primaryDeepBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Distance to Item',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDeepBlue,
                                ),
                      ),
                    ),
                  ],
                ),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _result!.distanceText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _buildMapBody(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegendItem(
                      color: Colors.red,
                      label: 'You',
                      subtitle: widget.recipient.shortLabel,
                    ),
                    _LegendItem(
                      color: AppTheme.primaryBlue,
                      label: 'Item area',
                      subtitle: _result?.donorAreaLabel ??
                          widget.item.donorAreaLabel,
                      isCircle: true,
                    ),
                    if (widget.item.disasterReliefAllocation)
                      _LegendItem(
                        color: const Color(0xFFC62828),
                        label: loc.t('disaster.mapZoneLegend'),
                        subtitle: loc.t('disaster.crisisLabel'),
                        isCircle: true,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Donor exact address is hidden for privacy. Only the general ZIP area is shown.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBody(BuildContext context) {
    if (_isLoading && _result == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _result == null) {
      return Container(
        color: AppTheme.surfaceLight,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage ?? 'Distance map is temporarily unavailable.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadProximity, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final result = _result!;
    return ProximityMapPreview(
      recipient: result.recipientLocation,
      donorAreaCenter: result.donorAreaCenter,
      donorAreaRadiusMeters: result.donorAreaRadiusMeters,
      showDisasterZone: widget.item.disasterReliefAllocation,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.subtitle,
    this.isCircle = false,
  });

  final Color color;
  final String label;
  final String subtitle;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCircle ? 14 : 10,
          height: isCircle ? 14 : 10,
          decoration: BoxDecoration(
            color: isCircle ? color.withValues(alpha: 0.25) : color,
            shape: BoxShape.circle,
            border: isCircle ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
