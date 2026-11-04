import 'package:crave/main.dart';
import 'package:crave/models/food.dart';
import 'package:crave/state/crave_store.dart';
import 'package:crave/ui/crave_screens.dart';
import 'package:crave/ui/crave_widgets.dart';
import 'package:crave/ui/seller_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/mock_food_data.dart';
import 'fixtures/test_stores.dart';

void main() {
  test('direct image URL validation rejects Google Images result pages', () {
    expect(isDirectImageUrl('https://cdn.example.test/idli.jpg'), isTrue);
    expect(
      isDirectImageUrl(
        'https://www.google.com/imgres?q=idli&imgurl=https%3A%2F%2Fcdn.example.test%2Fidli.jpg',
      ),
      isFalse,
    );
    expect(isDirectImageUrl('not a URL'), isFalse);
  });

  testWidgets('Firebase setup screen explains how to configure the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FirebaseSetupApp(
        message: 'Configure FlutterFire for the current platform.',
      ),
    );

    expect(find.text('Connect Firebase to continue'), findsOneWidget);
    expect(find.textContaining('Configure FlutterFire'), findsOneWidget);
  });

  testWidgets('splash opens the Crave welcome screen', (tester) async {
    final store = CraveStore(MockFoodData.foods);
    addTearDown(store.dispose);
    final navigatorObserver = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [navigatorObserver],
        home: SplashScreen(store: store),
      ),
    );

    expect(
      find.text('Your favourite meals are just a tap away.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.text('Good Food,\nGreat Mood!'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(navigatorObserver.replacements, 0);
  });

  testWidgets('customer login opens the restaurant partner login', (
    tester,
  ) async {
    final store = CraveStore(MockFoodData.foods);
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(home: LoginScreen(store: store)));

    expect(find.text('Are you a Restaurant Owner?'), findsOneWidget);
    await tester.tap(find.text('Login as Restaurant Partner'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('seller account screen explains immediate account access', (
    tester,
  ) async {
    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SellerAccountScreen(onSignOut: () async => signedOut = true),
      ),
    );

    expect(find.text('Your restaurant account is ready.'), findsOneWidget);
    expect(find.textContaining('No review is required'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('seller settings calls sign out after confirmation', (
    tester,
  ) async {
    final store = createSellerStore();
    addTearDown(store.dispose);
    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SellerSettingsScreen(
          store: store,
          onSignOut: () async => signedOut = true,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ListTile, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('seller dashboard navigates to orders and menu', (tester) async {
    final store = createSellerStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(home: SellerShell(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('Today at a glance'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('CRV-8031'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Classic Smash Burger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout uses COD and surfaces an unconfigured service error', (
    tester,
  ) async {
    final customerStore = CraveStore(MockFoodData.foods)
      ..saveAddress(
        const DeliveryAddress(
          id: 'address-1',
          name: 'Customer',
          phone: '1234567890',
          house: '12',
          street: 'Market Road',
          city: 'Pune',
          state: 'Maharashtra',
          pincode: '411001',
          type: 'Home',
        ),
      )
      ..addToCart(MockFoodData.foods.first);
    addTearDown(customerStore.dispose);

    await tester.pumpWidget(
      MaterialApp(home: CheckoutScreen(store: customerStore)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(find.textContaining('Place COD order'), findsOneWidget);
    await tester.tap(find.textContaining('Place COD order'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cash-on-delivery orders are not configured.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int replacements = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
