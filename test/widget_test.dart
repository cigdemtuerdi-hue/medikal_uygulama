import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/config/app_routes.dart';
import 'package:medikal_uygulama/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openHome(WidgetTester tester) async {
    await tester.pumpWidget(const MedGiftApp());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pumpAndSettle();
  }

  testWidgets('App opens auth landing with Partner with Us footer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MedGiftApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to MedGift US'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Partner with Us'), findsOneWidget);
    expect(
      find.textContaining('Interested in sponsorship or collaboration'),
      findsOneWidget,
    );
    expect(find.text('Contact Us / Sponsorship Inquiry'), findsOneWidget);
  });

  testWidgets('Home screen opens via named route', (WidgetTester tester) async {
    await tester.pumpWidget(const MedGiftApp());
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacementNamed(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.text('Donate DME & Wound Care Supplies'), findsOneWidget);
  });

  testWidgets('Bottom nav opens ProfileScreen', (WidgetTester tester) async {
    await openHome(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile & Tax Records'), findsOneWidget);
    expect(find.text('Cigdem Yeter'), findsWidgets);
    expect(find.text('Update Address / ZIP Code'), findsOneWidget);
  });

  testWidgets('Named profile route opens ProfileScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MedGiftApp());
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacementNamed(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.text('Profile & Tax Records'), findsOneWidget);
    expect(find.text('Update Address / ZIP Code'), findsOneWidget);
  });

  testWidgets('Bottom nav opens My Items screen', (WidgetTester tester) async {
    await openHome(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'My Items'));
    await tester.pumpAndSettle();

    expect(find.text('My Received Items'), findsOneWidget);
    expect(find.textContaining('Pass It On'), findsWidgets);
  });
}
