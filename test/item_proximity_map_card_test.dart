import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/l10n/app_localizations.dart';
import 'package:medikal_uygulama/models/available_donation_item.dart';
import 'package:medikal_uygulama/models/donation_models.dart';
import 'package:medikal_uygulama/models/profile_address.dart';
import 'package:medikal_uygulama/widgets/item_proximity_map_card.dart';

void main() {
  testWidgets('ItemProximityMapCard shows distance without Google Maps',
      (tester) async {
    const recipient = ProfileAddress(
      roleLabel: 'Recipient',
      zipCode: '92880',
      city: 'Eastvale',
      state: 'CA',
    );
    const item = AvailableDonationItem(
      id: 'test-001',
      title: 'Test Wheelchair',
      description: 'Test item',
      condition: ItemCondition.good,
      donorZipCode: '92880',
      donorCity: 'Eastvale',
      donorState: 'CA',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ItemProximityMapCard(
            recipient: recipient,
            item: item,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Distance to Item'), findsOneWidget);
    expect(
      find.textContaining('in your area'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
