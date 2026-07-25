import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/donation_models.dart';
import 'available_items_service.dart';
import 'donation_service.dart';

/// Live Impact & ESG metrics derived from donations, listings, and fulfilled requests.
class ImpactMetrics {
  const ImpactMetrics({
    required this.equipmentSaved,
    required this.co2SavedKg,
    required this.communitySavingsUsd,
  });

  final int equipmentSaved;
  final double co2SavedKg;
  final double communitySavingsUsd;
}

class ImpactMetricsService extends ChangeNotifier {
  ImpactMetricsService._() {
    AvailableItemsService.instance.addListener(_onSourceChanged);
  }

  static final ImpactMetricsService instance = ImpactMetricsService._();

  /// Approximate CO₂e (kg) avoided when one unit is reused instead of landfilled/replaced.
  static const double _co2DmeDefaultKg = 40;
  static const double _co2WoundCareKg = 0.5;
  static const Map<DmeType, double> _co2ByDmeType = {
    DmeType.wheelchair: 85,
    DmeType.walker: 35,
    DmeType.hospitalBed: 120,
    DmeType.oxygenEquipment: 95,
    DmeType.nebulizer: 28,
    DmeType.commode: 32,
    DmeType.showerChair: 30,
    DmeType.other: 40,
  };

  /// Fallback fair-market estimates when a listing has no donation FMV record.
  static const double _fmvDmeDefault = 350;
  static const double _fmvWoundCare = 25;
  static const Map<DmeType, double> _fmvByDmeType = {
    DmeType.wheelchair: 800,
    DmeType.walker: 250,
    DmeType.hospitalBed: 1100,
    DmeType.oxygenEquipment: 1200,
    DmeType.nebulizer: 180,
    DmeType.commode: 120,
    DmeType.showerChair: 90,
    DmeType.other: 350,
  };

  void _onSourceChanged() => notifyListeners();

  ImpactMetrics get metrics {
    var equipment = 0;
    var co2 = 0.0;
    var savings = 0.0;

    for (final record in DonationService.donationHistory) {
      final qty = record.quantity;
      equipment += qty;
      co2 += _co2ForCategory(record.category, dmeType: null) * qty;
      savings += record.estimatedRetailValueUsd;
    }

    for (final item in AvailableItemsService.instance.allItems) {
      final qty = item.quantityAvailable;
      equipment += qty;
      co2 += _co2ForItem(item) * qty;
      savings += _fmvForItem(item) * qty;
    }

    for (final request in DonationService.openRequests) {
      final qty = request.unitsFulfilled;
      if (qty <= 0) continue;
      equipment += qty;
      co2 += _co2ForCategory(request.category, dmeType: null) * qty;
      savings += _fmvForCategory(request.category) * qty;
    }

    return ImpactMetrics(
      equipmentSaved: equipment,
      co2SavedKg: co2,
      communitySavingsUsd: savings,
    );
  }

  double _co2ForItem(AvailableDonationItem item) {
    return co2KgForDmeType(item.dmeType);
  }

  /// Public CO₂e (kg) factor for one reuse hop of a DME type.
  static double co2KgForDmeType(DmeType? dmeType) {
    if (dmeType == null) return _co2DmeDefaultKg;
    return _co2ByDmeType[dmeType] ?? _co2DmeDefaultKg;
  }

  double _co2ForCategory(DonationCategory category, {DmeType? dmeType}) {
    if (category == DonationCategory.woundCare) return _co2WoundCareKg;
    if (dmeType != null) return _co2ByDmeType[dmeType] ?? _co2DmeDefaultKg;
    return _co2DmeDefaultKg;
  }

  double _fmvForItem(AvailableDonationItem item) {
    if (item.dmeType != null) {
      return _fmvByDmeType[item.dmeType!] ?? _fmvDmeDefault;
    }
    return _fmvDmeDefault;
  }

  double _fmvForCategory(DonationCategory category) {
    return category == DonationCategory.woundCare ? _fmvWoundCare : _fmvDmeDefault;
  }
}
