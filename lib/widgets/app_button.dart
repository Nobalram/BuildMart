import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'premium/fade_slide_in.dart';
import 'premium/scale_on_tap.dart';

enum AppButtonType { primary, gradient, outlined, text }

/// Reusable button with a built-in loading spinner state and a
/// premium press interaction. Use this instead of raw ElevatedButton /
/// OutlinedButton so loading and feedback look identical everywhere.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final bool animateIn;
  final int delayMs;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.animateIn = false,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final bool enabled = effectiveOnPressed != null;

    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
          );

    final Widget button;
    switch (type) {
      case AppButtonType.gradient:
        button = _GradientButton(
          onPressed: effectiveOnPressed,
          isLoading: isLoading,
          child: child,
        );
        break;
      case AppButtonType.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: AppColors.textMuted,
          ),
          child: child,
        );
        break;
      case AppButtonType.outlined:
        button = OutlinedButton(onPressed: effectiveOnPressed, child: child);
        break;
      case AppButtonType.text:
        button = TextButton(onPressed: effectiveOnPressed, child: child);
        break;
    }

    final sized = SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: enabled
          ? ScaleOnTap(onTap: effectiveOnPressed, child: button)
          : button,
    );

    if (!animateIn) return sized;
    return FadeSlideIn(
      delayMs: delayMs,
      offset: const Offset(0, 0.15),
      child: sized,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : AppColors.textMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: enabled ? AppShadows.colored(AppColors.primary) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
