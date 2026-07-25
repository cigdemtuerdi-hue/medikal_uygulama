import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/disaster_models.dart';

/// Platform-wide Disaster & Emergency Response Mode flag + relief hubs.
class EmergencyModeService extends ChangeNotifier {
  EmergencyModeService._() {
    _load();
  }

  static final EmergencyModeService instance = EmergencyModeService._();

  static const _prefsKey = 'disaster_emergency_mode_enabled';

  bool _enabled = true;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get isLoaded => _loaded;

  /// Demo crisis zones with staging / field-team logistics.
  static const List<DisasterZone> activeZones = [
    DisasterZone(
      id: 'zone-ie-flood',
      name: 'Inland Empire Flood Response',
      state: 'CA',
      zipCodes: ['92880', '91761', '92335', '92553'],
      hubName: 'MedGift IE Emergency Staging Hub',
      hubAddress: '12950 Citrus Ave, Eastvale, CA 92880 — Dock B (24/7)',
      fieldTeamContact: 'Field Ops Desk · (951) 555-0142',
      priorityNeeds: [
        'Wheelchairs',
        'Hospital beds',
        'Oxygen concentrators',
        'Walkers',
      ],
    ),
    DisasterZone(
      id: 'zone-sf-quake',
      name: 'Bay Area Quake Relief Corridor',
      state: 'CA',
      zipCodes: ['94102', '94103', '94107', '94110'],
      hubName: 'SF Civic Center Relief Cache',
      hubAddress: '100 Larkin St, San Francisco, CA 94102 — Loading Bay 2',
      fieldTeamContact: 'Bay Area Mutual Aid · (415) 555-0198',
      priorityNeeds: [
        'Oxygen equipment',
        'Wheelchairs',
        'Nebulizers',
        'Commodes',
      ],
    ),
  ];

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      _enabled = true;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }

  DisasterZone? zoneForZip(String? zip) {
    if (zip == null || zip.isEmpty) return null;
    for (final zone in activeZones) {
      if (zone.coversZip(zip)) return zone;
    }
    return null;
  }

  DisasterZone get primaryHub => activeZones.first;

  bool isDisasterZip(String zip) => zoneForZip(zip) != null;
}
