import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:buildmart_buyer/models/app_user.dart';
import 'package:buildmart_buyer/models/category.dart';
import 'package:buildmart_buyer/models/product.dart';
import 'package:buildmart_buyer/providers/auth_provider.dart';
import 'package:buildmart_buyer/providers/location_provider.dart';
import 'package:buildmart_buyer/providers/notification_provider.dart';
import 'package:buildmart_buyer/providers/product_provider.dart';
import 'package:buildmart_buyer/providers/recently_viewed_provider.dart';
import 'package:buildmart_buyer/screens/home/home_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Product fakeProduct(String id, {String name = 'Cement Bag'}) {
    return Product(
      id: id,
      name: name,
      sellerId: 'seller1',
      sellerName: 'BuildMart Traders',
      categoryName: 'Cement',
      price: 400,
      discountPercent: 5,
      unit: 'bag',
      stock: 20,
      rating: 4.2,
      imageUrl: 'https://example.com/img.png',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(
          (ref) => Stream<AppUser?>.value(
            AppUser(
              uid: 'u1',
              phoneNumber: '+911234567890',
              name: 'Ravi Kumar',
              createdAt: DateTime(2026),
            ),
          ),
        ),
        categoriesProvider.overrideWith(
          (ref) => Stream<List<ProductCategory>>.value([
            ProductCategory(id: 'c1', name: 'Cement', icon: 'warehouse', order: 1),
          ]),
        ),
        homeProductsProvider.overrideWith(
          (ref) => Stream<List<Product>>.value([
            fakeProduct('p1'),
            fakeProduct('p2', name: 'Steel Rod'),
          ]),
        ),
        wishlistIdsProvider.overrideWith(
          (ref) => Stream<Set<String>>.value(const {}),
        ),
        recentlyViewedProductsProvider.overrideWith(
          (ref) => Future<List<Product>>.value([fakeProduct('p3')]),
        ),
        currentCityProvider.overrideWith((ref) => Future<String>.value('Mumbai')),
        unreadNotificationCountProvider.overrideWithValue(2),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('home screen renders content without layout exceptions',
      (tester) async {
    // Use a tall viewport so all slivers (including the products header
    // further down the scroll) get built.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Greeting from profile data.
    expect(find.text('Hi, Ravi'), findsOneWidget);

    // Products section header (no category selected).
    expect(find.text('Popular Products'), findsOneWidget);

    // Product cards rendered.
    expect(find.text('Cement Bag'), findsWidgets);

    // Search bar present.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('home scrolls through fully at device size without exceptions',
      (tester) async {
    // Realistic phone metrics (e.g. 1080x2400 @ 2.75x => 393x872 logical).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    // Drag through the whole scroll view so every sliver gets built and
    // laid out at the narrow device width.
    for (var i = 0; i < 10; i++) {
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.pump(const Duration(milliseconds: 400));
    // Any layout/overflow exception will fail the test automatically via
    // the FlutterError handler; no extra assertion needed.
  });
}
