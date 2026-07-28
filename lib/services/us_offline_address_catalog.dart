import '../models/us_address_models.dart';

/// Offline US ZIP / city lookup when Google Places is unavailable.
class UsOfflineAddressCatalog {
  UsOfflineAddressCatalog._();

  static const List<UsAddressSuggestion> entries = [
    // California — Orange County / Inland Empire (common donation ZIPs)
    UsAddressSuggestion(zipCode: '92606', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92602', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92603', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92604', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92612', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92614', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92618', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92620', city: 'Irvine', state: 'CA'),
    UsAddressSuggestion(zipCode: '92626', city: 'Costa Mesa', state: 'CA'),
    UsAddressSuggestion(zipCode: '92627', city: 'Costa Mesa', state: 'CA'),
    UsAddressSuggestion(zipCode: '92660', city: 'Newport Beach', state: 'CA'),
    UsAddressSuggestion(zipCode: '92663', city: 'Newport Beach', state: 'CA'),
    UsAddressSuggestion(zipCode: '92701', city: 'Santa Ana', state: 'CA'),
    UsAddressSuggestion(zipCode: '92705', city: 'Santa Ana', state: 'CA'),
    UsAddressSuggestion(zipCode: '92801', city: 'Anaheim', state: 'CA'),
    UsAddressSuggestion(zipCode: '92805', city: 'Anaheim', state: 'CA'),
    UsAddressSuggestion(zipCode: '92840', city: 'Garden Grove', state: 'CA'),
    UsAddressSuggestion(zipCode: '92866', city: 'Orange', state: 'CA'),
    UsAddressSuggestion(zipCode: '92868', city: 'Orange', state: 'CA'),
    UsAddressSuggestion(zipCode: '92880', city: 'Eastvale', state: 'CA'),
    // California — major metros
    UsAddressSuggestion(zipCode: '90012', city: 'Los Angeles', state: 'CA'),
    UsAddressSuggestion(zipCode: '90210', city: 'Beverly Hills', state: 'CA'),
    UsAddressSuggestion(zipCode: '94102', city: 'San Francisco', state: 'CA'),
    UsAddressSuggestion(zipCode: '92101', city: 'San Diego', state: 'CA'),
    UsAddressSuggestion(zipCode: '95814', city: 'Sacramento', state: 'CA'),
    UsAddressSuggestion(zipCode: '95110', city: 'San Jose', state: 'CA'),
    // New York
    UsAddressSuggestion(zipCode: '10001', city: 'New York', state: 'NY'),
    UsAddressSuggestion(zipCode: '11201', city: 'Brooklyn', state: 'NY'),
    UsAddressSuggestion(zipCode: '14201', city: 'Buffalo', state: 'NY'),
    // Texas
    UsAddressSuggestion(zipCode: '77002', city: 'Houston', state: 'TX'),
    UsAddressSuggestion(zipCode: '75201', city: 'Dallas', state: 'TX'),
    UsAddressSuggestion(zipCode: '78701', city: 'Austin', state: 'TX'),
    UsAddressSuggestion(zipCode: '78205', city: 'San Antonio', state: 'TX'),
    // Florida
    UsAddressSuggestion(zipCode: '33101', city: 'Miami', state: 'FL'),
    UsAddressSuggestion(zipCode: '32801', city: 'Orlando', state: 'FL'),
    UsAddressSuggestion(zipCode: '33602', city: 'Tampa', state: 'FL'),
    // Illinois / Midwest
    UsAddressSuggestion(zipCode: '60601', city: 'Chicago', state: 'IL'),
    UsAddressSuggestion(zipCode: '48226', city: 'Detroit', state: 'MI'),
    UsAddressSuggestion(zipCode: '55401', city: 'Minneapolis', state: 'MN'),
    UsAddressSuggestion(zipCode: '64106', city: 'Kansas City', state: 'MO'),
    // Southeast
    UsAddressSuggestion(zipCode: '30303', city: 'Atlanta', state: 'GA'),
    UsAddressSuggestion(zipCode: '28202', city: 'Charlotte', state: 'NC'),
    UsAddressSuggestion(zipCode: '37203', city: 'Nashville', state: 'TN'),
    UsAddressSuggestion(zipCode: '70112', city: 'New Orleans', state: 'LA'),
    // Mountain / Southwest
    UsAddressSuggestion(zipCode: '85004', city: 'Phoenix', state: 'AZ'),
    UsAddressSuggestion(zipCode: '89101', city: 'Las Vegas', state: 'NV'),
    UsAddressSuggestion(zipCode: '80202', city: 'Denver', state: 'CO'),
    UsAddressSuggestion(zipCode: '87102', city: 'Albuquerque', state: 'NM'),
    // Pacific Northwest
    UsAddressSuggestion(zipCode: '98101', city: 'Seattle', state: 'WA'),
    UsAddressSuggestion(zipCode: '97201', city: 'Portland', state: 'OR'),
    // Northeast
    UsAddressSuggestion(zipCode: '02108', city: 'Boston', state: 'MA'),
    UsAddressSuggestion(zipCode: '19103', city: 'Philadelphia', state: 'PA'),
    UsAddressSuggestion(zipCode: '21201', city: 'Baltimore', state: 'MD'),
    // Other
    UsAddressSuggestion(zipCode: '43215', city: 'Columbus', state: 'OH'),
    UsAddressSuggestion(zipCode: '73102', city: 'Oklahoma City', state: 'OK'),
    UsAddressSuggestion(zipCode: '84101', city: 'Salt Lake City', state: 'UT'),
    UsAddressSuggestion(zipCode: '96813', city: 'Honolulu', state: 'HI'),
    UsAddressSuggestion(zipCode: '99501', city: 'Anchorage', state: 'AK'),
  ];

  static List<UsAddressSuggestion> search(String query, {int limit = 12}) {
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
    if (normalized == 'usa' || normalized == 'united states') return true;
    if (entry.streetAddress?.toLowerCase().contains(normalized) ?? false) {
      return true;
    }
    return normalized.contains(entry.zipCode);
  }
}
