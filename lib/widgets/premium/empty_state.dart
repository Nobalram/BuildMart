import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'fade_slide_in.dart';
import 'scale_on_tap.dart';

/// Polished empty / error / info state with an illustrated icon well,
/// message, optional subtitle and CTA. Used instead of bare Text(...)
/// wherever a list can be empty or fail to load.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;

  const EmptyState({
    super.key,
    this.icon = Icons.inventory_2_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor = AppColors.primary,
  });

  /// Error variant with retry affordance.
  const EmptyState.error({
    super.key,
    required String title,
    String? subtitle,
    String retryLabel = 'Try Again',
    VoidCallback? onRetry,
  }) : icon = Icons.wifi_off_rounded,
       // ignore: prefer_initializing_formals, unnecessary_this
       this.title = title,
       // ignore: prefer_initializing_formals, unnecessary_this
       this.subtitle = subtitle,
       actionLabel = retryLabel,
       onAction = onRetry,
       accentColor = AppColors.error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Soft halo + icon well
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.18),
                        accentColor.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(icon, size: 34, color: accentColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ScaleOnTap(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.colored(accentColor),
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
