import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/models/us_address_models.dart';
import 'package:medikal_uygulama/services/us_address_filter.dart';
import 'package:medikal_uygulama/services/us_offline_address_catalog.dart';

void main() {
  test('US filter accepts addresses from any state', () {
    const ca = UsAddressSuggestion(zipCode: '92880', city: 'Eastvale', state: 'CA');
    const ny = UsAddressSuggestion(zipCode: '10001', city: 'New York', state: 'NY');
    const tx = UsAddressSuggestion(zipCode: '77002', city: 'Houston', state: 'TX');

    expect(UsAddressFilter.matches(ca), isTrue);
    expect(UsAddressFilter.matches(ny), isTrue);
    expect(UsAddressFilter.matches(tx), isTrue);
  });

  test('offline catalog covers multiple US regions', () {
    final matches = UsOfflineAddressCatalog.search('a', limit: 20);
    final states = matches.map((entry) => entry.state).toSet();
    expect(states.length, greaterThan(3));
    expect(states, contains('CA'));
    expect(states, contains('NY'));
    expect(states, contains('TX'));
  });
}
