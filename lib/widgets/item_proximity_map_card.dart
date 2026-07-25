import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/available_donation_item.dart';
import '../models/item_proximity_result.dart';
import '../models/profile_address.dart';
import '../services/maps_distance_service.dart';

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
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadProximity();
  }

  Future<void> _loadProximity() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (!AppConfig.hasGoogleMapsApiKey) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final result = await MapsDistanceService.instance.calculateItemProximity(
      recipient: widget.recipient,
      donorZipCode: widget.item.donorZipCode,
      donorCity: widget.item.donorCity,
      donorState: widget.item.donorState,
    );

    if (!mounted) return;

    setState(() {
      _result = result;
      _isLoading = false;
      _hasError = result == null;
    });

    if (result != null && _mapController != null) {
      _fitMapToArea(result);
    }
  }

  void _fitMapToArea(ItemProximityResult result) {
    final latDelta = result.donorAreaRadiusMeters / 111320;
    final lngDelta = result.donorAreaRadiusMeters /
        (111320 * math.cos(result.donorAreaCenter.latitude * math.pi / 180));

    final bounds = LatLngBounds(
      southwest: LatLng(
        _min(
          result.recipientLocation.latitude - 0.01,
          result.donorAreaCenter.latitude - latDelta,
        ),
        _min(
          result.recipientLocation.longitude - 0.01,
          result.donorAreaCenter.longitude - lngDelta,
        ),
      ),
      northeast: LatLng(
        _max(
          result.recipientLocation.latitude + 0.01,
          result.donorAreaCenter.latitude + latDelta,
        ),
        _max(
          result.recipientLocation.longitude + 0.01,
          result.donorAreaCenter.longitude + lngDelta,
        ),
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  Set<Marker> _buildMarkers(ItemProximityResult result) {
    return {
      Marker(
        markerId: const MarkerId('recipient'),
        position: result.recipientLocation,
        infoWindow: const InfoWindow(
          title: 'You',
          snippet: 'Your location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Set<Circle> _buildCircles(ItemProximityResult result) {
    final circles = <Circle>{
      Circle(
        circleId: const CircleId('donor_privacy_area'),
        center: result.donorAreaCenter,
        radius: result.donorAreaRadiusMeters,
        fillColor: AppTheme.primaryBlue.withValues(alpha: 0.18),
        strokeColor: AppTheme.primaryBlue.withValues(alpha: 0.45),
        strokeWidth: 2,
      ),
    };

    final isCrisis = widget.item.disasterReliefAllocation;
    if (isCrisis) {
      circles.add(
        Circle(
          circleId: const CircleId('disaster_zone'),
          center: result.donorAreaCenter,
          radius: result.donorAreaRadiusMeters * 1.35,
          fillColor: const Color(0xFFC62828).withValues(alpha: 0.16),
          strokeColor: const Color(0xFFB71C1C).withValues(alpha: 0.65),
          strokeWidth: 2,
        ),
      );
    }
    return circles;
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
    if (_isLoading) {
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
          child: Text(
            AppConfig.hasGoogleMapsApiKey
                ? 'Distance map is temporarily unavailable.'
                : AppConfig.missingApiKeyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final result = _result!;
    final midpoint = LatLng(
      (result.recipientLocation.latitude + result.donorAreaCenter.latitude) /
          2,
      (result.recipientLocation.longitude +
              result.donorAreaCenter.longitude) /
          2,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: midpoint, zoom: 10),
      markers: _buildMarkers(result),
      circles: _buildCircles(result),
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitMapToArea(result);
      },
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
    return Expanded(
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
