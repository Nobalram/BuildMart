import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum SnackKind { success, error, info }

/// App-wide snackbar with an icon well, slide-up entry and rounded pill
/// shape. Use this instead of ScaffoldMessenger.showSnackBar(...) so
/// feedback looks identical everywhere.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackKind kind = SnackKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final (icon, color) = switch (kind) {
    SnackKind.success => (Icons.check_rounded, AppColors.success),
    SnackKind.error => (Icons.error_outline_rounded, AppColors.error),
    SnackKind.info => (Icons.info_outline_rounded, AppColors.primary),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Row(          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        // SnackBars with an action default to persist: true, which means
        // they never auto-dismiss. Our VIEW action is optional, so keep the
        // snackbar timing out after [duration].
        persist: false,
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppColors.primaryLight,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}
