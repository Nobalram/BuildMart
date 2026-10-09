import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// A bottom nav where the selected icon lifts into a filled pill with
/// a spring-like scale animation, instead of the stock flat tab look.
class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final void Function(int) onTap;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;

            return GestureDetector(
              onTap: () {
                if (index != currentIndex) HapticFeedback.selectionClick();
                onTap(index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 16 : 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: selected
                      ? AppShadows.colored(AppColors.primary, alpha: 0.35)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            key: ValueKey(selected),
                            color: selected
                                ? Colors.white
                                : AppColors.textMuted,
                            size: 23,
                          ),
                        ),
                        if (item.badgeCount > 0)
                          Positioned(
                            right: -7,
                            top: -5,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: item.badgeCount.toDouble(),
                              ),
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              builder: (context, value, _) {
                                return Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 17,
                                    minHeight: 17,
                                  ),
                                  child: Text(
                                    '${value.round()}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
