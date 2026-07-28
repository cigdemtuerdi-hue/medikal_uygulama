import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/us_address_models.dart';

/// Free US ZIP → city/state lookup for any valid 5-digit postal code.
/// Works without a Google API key (https://api.zippopotam.us).
class UsZipLookupService {
  UsZipLookupService._();

  static final UsZipLookupService instance = UsZipLookupService._();

  Future<UsAddressSuggestion?> lookup(String zip) async {
    final parsed = await _fetchZipData(zip);
    if (parsed == null) return null;

    return UsAddressSuggestion(
      zipCode: parsed.zipCode,
      city: parsed.city,
      state: parsed.state,
    );
  }

  Future<(double lat, double lng)?> latLngForZip(String zip) async {
    final parsed = await _fetchZipData(zip);
    if (parsed == null) return null;
    return (parsed.lat, parsed.lng);
  }

  Future<_ZipData?> _fetchZipData(String zip) async {
    final normalized = zip.trim();
    if (normalized.length != 5 || int.tryParse(normalized) == null) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('https://api.zippopotam.us/us/$normalized'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) return null;

      final place = places.first as Map<String, dynamic>;
      final city = (place['place name'] as String?)?.trim() ?? '';
      final state = (place['state abbreviation'] as String?)?.trim() ?? '';
      final lat = double.tryParse('${place['latitude']}');
      final lng = double.tryParse('${place['longitude']}');
      if (city.isEmpty || state.isEmpty || lat == null || lng == null) {
        return null;
      }

      return _ZipData(
        zipCode: normalized,
        city: city,
        state: state,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return null;
    }
  }
}

class _ZipData {
  const _ZipData({
    required this.zipCode,
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
  });

  final String zipCode;
  final String city;
  final String state;
  final double lat;
  final double lng;
}
