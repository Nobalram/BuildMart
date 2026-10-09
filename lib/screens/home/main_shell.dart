import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/fcm_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/local_notification_service.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/animated_bottom_nav.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'home_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    LocalNotificationService.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        FcmService().initAndSaveToken(uid);
      }
      LocationService.ensureLocationEnabled(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      notificationWatcherProvider,
    ); // keep the local-notify watcher alive
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          const NavItem(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: 'Wishlist',
          ),
          NavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Cart',
            badgeCount: cartCount,
          ),
          const NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
