import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium/fade_slide_in.dart';
import '../../widgets/premium/scale_on_tap.dart';
import '../auth/welcome_screen.dart';
import '../orders/orders_screen.dart';
import 'edit_profile_screen.dart';
import 'addresses_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'customer_care_screen.dart';
import 'notifications_screen.dart';
import 'static_content_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Logout?'),
        content: const Text(
          'You will need to verify your phone number again to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Hero header ----
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.xl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    profileAsync.when(
                      loading: () => const SizedBox(
                        width: 68,
                        height: 68,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      ),
                      error: (_, _) => const _ProfileAvatar(letter: '?'),
                      data: (user) => _ProfileAvatar(
                        letter:
                            (user?.name.isNotEmpty == true
                                    ? user!.name[0]
                                    : '?')
                                .toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            loading: () => const _WhiteLine(width: 120),
                            error: (_, _) => const Text(
                              'Buyer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            data: (user) => Text(
                              user?.name ?? 'Buyer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          profileAsync.when(
                            loading: () => const _WhiteLine(width: 90),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (user) => Row(
                              children: [
                                const Icon(
                                  Icons.phone_rounded,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  user?.phoneNumber ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (profileAsync.value?.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                profileAsync.value!.email!,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ScaleOnTap(
                      pressedScale: 0.92,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            AppRadius.pill,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ---- Account ----
          FadeSlideIn(
            delayMs: 40,
            child: const _GroupLabel('ACCOUNT'),
          ),
          _ProfileMenuItem(
            icon: Icons.receipt_long_outlined,
            tint: AppColors.primary,
            label: 'My Orders',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          _ProfileMenuItem(
            icon: Icons.location_on_outlined,
            tint: AppColors.info,
            label: 'My Addresses',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddressesScreen())),
          ),
          _ProfileMenuItem(
            icon: Icons.favorite_border,
            tint: AppColors.error,
            label: 'My Wishlist',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          _ProfileMenuItem(
            icon: Icons.notifications_none_outlined,
            tint: AppColors.warning,
            label: 'Notifications',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ---- Support ----
          FadeSlideIn(
            delayMs: 40,
            child: const _GroupLabel('SUPPORT'),
          ),
          _ProfileMenuItem(
            icon: Icons.support_agent_outlined,
            tint: AppColors.success,
            label: 'Customer Care',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerCareScreen()),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.help_outline,
            tint: AppColors.secondary,
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StaticContentScreen(
                  title: 'Help & Support',
                  content:
                      'For any questions or issues, contact us at support@buildmart.example '
                      'or call our helpline. We typically respond within 24 hours.',
                ),
              ),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.description_outlined,
            tint: AppColors.info,
            label: 'Terms & Conditions',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StaticContentScreen(
                  title: 'Terms & Conditions',
                  content:
                      'By using BuildMart, you agree to purchase construction materials '
                      'subject to each seller\'s stated availability and delivery terms. '
                      'Orders are fulfilled directly by independent sellers on the platform.',
                ),
              ),
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.privacy_tip_outlined,
            tint: AppColors.warning,
            label: 'Privacy Policy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StaticContentScreen(
                  title: 'Privacy Policy',
                  content:
                      'BuildMart collects your phone number, name, and address solely to '
                      'process orders and deliveries. We do not sell your data to third parties.',
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          _ProfileMenuItem(
            icon: Icons.logout_rounded,
            tint: AppColors.error,
            label: 'Logout',
            danger: true,
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 4,
        AppSpacing.sm,
        AppSpacing.md + 4,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String letter;
  const _ProfileAvatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 31,
        backgroundColor: Colors.white,
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _WhiteLine extends StatelessWidget {
  final double width;
  const _WhiteLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;
  final bool danger;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = AppColors.primary,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ScaleOnTap(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: AppDecors.card(radius: AppRadius.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: Icon(icon, size: 19, color: tint),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: danger ? AppColors.error : AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: danger
                    ? AppColors.error.withValues(alpha: 0.6)
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
