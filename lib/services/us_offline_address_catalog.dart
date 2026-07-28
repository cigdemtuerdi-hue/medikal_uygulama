import '../models/us_address_models.dart';

/// Offline US ZIP / city lookup used when Google Places is unavailable
/// (missing key, referrer restrictions, billing, etc.).
class UsOfflineAddressCatalog {
  UsOfflineAddressCatalog._();

  static const List<UsAddressSuggestion> entries = [
    UsAddressSuggestion(zipCode: '92880', city: 'Eastvale', state: 'CA'),
    UsAddressSuggestion(
      zipCode: '92880',
      city: 'Eastvale',
      state: 'CA',
      streetAddress: '12300 Limonite Ave',
    ),
    UsAddressSuggestion(zipCode: '94102', city: 'San Francisco', state: 'CA'),
    UsAddressSuggestion(
      zipCode: '94102',
      city: 'San Francisco',
      state: 'CA',
      streetAddress: '1355 Market St',
    ),
    UsAddressSuggestion(zipCode: '90012', city: 'Los Angeles', state: 'CA'),
    UsAddressSuggestion(
      zipCode: '90210',
      city: 'Beverly Hills',
      state: 'CA',
    ),
    UsAddressSuggestion(zipCode: '92101', city: 'San Diego', state: 'CA'),
    UsAddressSuggestion(zipCode: '95814', city: 'Sacramento', state: 'CA'),
    UsAddressSuggestion(zipCode: '89101', city: 'Las Vegas', state: 'NV'),
    UsAddressSuggestion(zipCode: '85004', city: 'Phoenix', state: 'AZ'),
    UsAddressSuggestion(zipCode: '78701', city: 'Austin', state: 'TX'),
    UsAddressSuggestion(zipCode: '77002', city: 'Houston', state: 'TX'),
    UsAddressSuggestion(zipCode: '75201', city: 'Dallas', state: 'TX'),
    UsAddressSuggestion(zipCode: '60601', city: 'Chicago', state: 'IL'),
    UsAddressSuggestion(
      zipCode: '60601',
      city: 'Chicago',
      state: 'IL',
      streetAddress: '233 S Wacker Dr',
    ),
    UsAddressSuggestion(zipCode: '10001', city: 'New York', state: 'NY'),
    UsAddressSuggestion(
      zipCode: '10001',
      city: 'New York',
      state: 'NY',
      streetAddress: '350 5th Ave',
    ),
    UsAddressSuggestion(zipCode: '33101', city: 'Miami', state: 'FL'),
    UsAddressSuggestion(zipCode: '30303', city: 'Atlanta', state: 'GA'),
    UsAddressSuggestion(zipCode: '98101', city: 'Seattle', state: 'WA'),
    UsAddressSuggestion(zipCode: '80202', city: 'Denver', state: 'CO'),
    UsAddressSuggestion(zipCode: '19103', city: 'Philadelphia', state: 'PA'),
    UsAddressSuggestion(zipCode: '02108', city: 'Boston', state: 'MA'),
    UsAddressSuggestion(zipCode: '48226', city: 'Detroit', state: 'MI'),
    UsAddressSuggestion(zipCode: '55401', city: 'Minneapolis', state: 'MN'),
    UsAddressSuggestion(zipCode: '97201', city: 'Portland', state: 'OR'),
    UsAddressSuggestion(zipCode: '37203', city: 'Nashville', state: 'TN'),
    UsAddressSuggestion(zipCode: '70112', city: 'New Orleans', state: 'LA'),
    UsAddressSuggestion(zipCode: '64106', city: 'Kansas City', state: 'MO'),
    UsAddressSuggestion(zipCode: '43215', city: 'Columbus', state: 'OH'),
    UsAddressSuggestion(zipCode: '28202', city: 'Charlotte', state: 'NC'),
    UsAddressSuggestion(zipCode: '89109', city: 'Las Vegas', state: 'NV'),
    UsAddressSuggestion(zipCode: '91761', city: 'Ontario', state: 'CA'),
    UsAddressSuggestion(zipCode: '92335', city: 'Fontana', state: 'CA'),
    UsAddressSuggestion(zipCode: '92553', city: 'Moreno Valley', state: 'CA'),
  ];

  static List<UsAddressSuggestion> search(String query, {int limit = 8}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final matches = entries.where((entry) => _matches(entry, normalized)).toList();
    return matches.take(limit).toList();
  }

  static UsAddressSuggestion? findByZip(String zip) {
    final normalized = zip.trim();
    if (normalized.length != 5 || int.tryParse(normalized) == null) {
      return null;
    }

    for (final entry in entries) {
      if (entry.zipCode == normalized) {
        return entry;
      }
    }
    return null;
  }

  static bool _matches(UsAddressSuggestion entry, String normalized) {
    if (entry.zipCode.startsWith(normalized)) return true;
    if (entry.city.toLowerCase().contains(normalized)) return true;
    if (entry.state.toLowerCase().startsWith(normalized)) return true;
    if (entry.streetAddress?.toLowerCase().contains(normalized) ?? false) {
      return true;
    }
    return normalized.contains(entry.zipCode);
  }
}
