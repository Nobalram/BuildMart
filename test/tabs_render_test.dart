import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:buildmart_buyer/models/app_user.dart';
import 'package:buildmart_buyer/models/cart_item.dart';
import 'package:buildmart_buyer/models/product.dart';
import 'package:buildmart_buyer/providers/auth_provider.dart';
import 'package:buildmart_buyer/providers/cart_provider.dart';
import 'package:buildmart_buyer/providers/product_provider.dart';
import 'package:buildmart_buyer/screens/cart/cart_screen.dart';
import 'package:buildmart_buyer/screens/profile/profile_screen.dart';
import 'package:buildmart_buyer/screens/wishlist/wishlist_screen.dart';

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

  Widget wrap(List<Override> overrides, Widget child) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );
  }

  testWidgets('cart tab renders items without layout exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final item = CartItem(
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
    );

    await tester.pumpWidget(
      wrap(
        [
          cartItemsProvider.overrideWith((ref) => Stream.value([item])),
          cartSubtotalProvider.overrideWithValue(800),
          cartTransportFeeProvider.overrideWithValue(50),
          cartPlatformFeeProvider.overrideWithValue(29),
          cartTaxProvider.overrideWithValue(40),
          cartGrandTotalProvider.overrideWithValue(919),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        const CartScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cement Bag 50kg'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
  });

  testWidgets('wishlist tab renders without layout exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        [
          wishlistIdsProvider.overrideWith(
            (ref) => Stream.value(<String>{'p1'}),
          ),
          wishlistedProductsProvider.overrideWith(
            (ref) => Stream.value([fakeProduct('p1')]),
          ),
        ],
        const WishlistScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cement Bag'), findsWidgets);
  });

  testWidgets('profile tab renders without layout exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        [
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
        ],
        const ProfileScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Ravi'), findsWidgets);
  });
}
