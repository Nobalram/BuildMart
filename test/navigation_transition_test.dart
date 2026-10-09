import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:buildmart_buyer/core/theme/app_theme.dart';
import 'package:buildmart_buyer/models/app_notification.dart';
import 'package:buildmart_buyer/models/app_user.dart';
import 'package:buildmart_buyer/models/cart_item.dart';
import 'package:buildmart_buyer/models/category.dart';
import 'package:buildmart_buyer/models/product.dart';
import 'package:buildmart_buyer/providers/auth_provider.dart';
import 'package:buildmart_buyer/providers/cart_provider.dart';
import 'package:buildmart_buyer/providers/location_provider.dart';
import 'package:buildmart_buyer/providers/notification_provider.dart';
import 'package:buildmart_buyer/providers/product_provider.dart';
import 'package:buildmart_buyer/providers/recently_viewed_provider.dart';
import 'package:buildmart_buyer/screens/categories/categories_screen.dart';
import 'package:buildmart_buyer/screens/cart/cart_screen.dart';
import 'package:buildmart_buyer/screens/home/home_screen.dart';
import 'package:buildmart_buyer/screens/products/product_details_screen.dart';
import 'package:buildmart_buyer/screens/profile/notifications_screen.dart';
import 'package:buildmart_buyer/screens/search/search_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
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

  List<Override> overrides() {
    return [
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
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      categoriesProvider.overrideWith(
        (ref) => Stream<List<ProductCategory>>.value([
          ProductCategory(
            id: 'c1',
            name: 'Cement',
            icon: 'warehouse',
            order: 1,
          ),
        ]),
      ),
      homeProductsProvider.overrideWith(
        (ref) => Stream<List<Product>>.value([
          fakeProduct('p1'),
          fakeProduct('p2', name: 'Steel Rod'),
        ]),
      ),
      productDetailsProvider('p1')
          .overrideWith((ref) => Stream<Product?>.value(fakeProduct('p1'))),
      wishlistIdsProvider.overrideWith(
        (ref) => Stream<Set<String>>.value(const {}),
      ),
      recentlyViewedProductsProvider.overrideWith(
        (ref) => Future<List<Product>>.value([fakeProduct('p3')]),
      ),
      currentCityProvider.overrideWith((ref) => Future<String>.value('Mumbai')),
      unreadNotificationCountProvider.overrideWithValue(2),
      notificationsProvider.overrideWith(
        (ref) => Stream.value(<AppNotification>[]),
      ),
      cartItemsProvider.overrideWith(
        (ref) => Stream.value(<CartItem>[
          CartItem(
            productId: 'p1',
            productName: 'Cement Bag 50kg',
            imageUrl: 'https://example.com/img.png',
            sellerId: 'seller1',
            sellerName: 'BuildMart Traders',
            unit: 'bag',
            unitPrice: 400,
            originalPrice: 450,
            quantity: 2,
            availableStock: 20,
            addedAt: DateTime(2026),
          ),
        ]),
      ),
      cartSubtotalProvider.overrideWithValue(800),
      cartTransportFeeProvider.overrideWithValue(50),
      cartPlatformFeeProvider.overrideWithValue(29),
      cartTaxProvider.overrideWithValue(40),
      cartGrandTotalProvider.overrideWithValue(919),
    ];
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: overrides(),
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  Future<void> pumpFrames(
    WidgetTester tester, {
    List<Duration> frames = const [
      Duration(milliseconds: 30),
      Duration(milliseconds: 80),
      Duration(milliseconds: 160),
      Duration(milliseconds: 320),
      Duration(milliseconds: 600),
    ],
  }) async {
    for (final f in frames) {
      await tester.pump(f);
    }
  }

  testWidgets('home -> product details transition (slideFadeRoute) renders '
      'without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const HomeScreen()));
    await pumpFrames(tester);

    await tester.tap(find.text('Cement Bag').first);
    await pumpFrames(tester);

    // Mid-transition frames plus settled state — any layout/painting
    // assertion fails the test automatically with the full widget chain.
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(ProductDetailsScreen))).pop();
    await pumpFrames(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('pushing notifications, categories, search and cart '
      'transitions renders without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const HomeScreen()));
    await pumpFrames(tester);

    NavigatorState nav() =>
        Navigator.of(tester.element(find.byType(HomeScreen)));

    nav().push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    await pumpFrames(tester);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(NotificationsScreen))).pop();
    await pumpFrames(tester);

    nav().push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
    await pumpFrames(tester);
    expect(find.byType(CategoriesScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(CategoriesScreen))).pop();
    await pumpFrames(tester);

    nav().push(MaterialPageRoute(builder: (_) => const SearchScreen()));
    await pumpFrames(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SearchScreen))).pop();
    await pumpFrames(tester);

    nav().push(MaterialPageRoute(builder: (_) => const CartScreen()));
    await pumpFrames(tester);
    expect(find.byType(CartScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(CartScreen))).pop();
    await pumpFrames(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('add-to-cart snackbar from product card auto-hides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const HomeScreen()));
    await pumpFrames(tester);

    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded).first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('added to cart'), findsOneWidget);

    // 3s persist:false duration + entry/exit animation margin.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
