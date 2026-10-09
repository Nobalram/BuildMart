import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFE8621A);
  static const Color primaryDark = Color(0xFFB94E12);
  static const Color primaryLight = Color(0xFFFFE3D1);
  static const Color primarySoft = Color(0xFFFFF3EA);

  static const Color secondary = Color(0xFF2B2D34);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F4F6);
  static const Color border = Color(0xFFECECEF);

  static const Color textPrimary = Color(0xFF17181C);
  static const Color textSecondary = Color(0xFF6B6D76);
  static const Color textMuted = Color(0xFFA3A5AD);

  static const Color success = Color(0xFF1E9E5A);
  static const Color error = Color(0xFFE5484D);
  static const Color warning = Color(0xFFE8A317);
  static const Color info = Color(0xFF2E7DD1);

  static const Color star = Color(0xFFFFB800);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF07B35), primary, primaryDark],
  );

  /// Deep sunset wash used behind hero headers and the splash screen.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A4C), primary, Color(0xFF9C3F0D)],
  );

  /// Soft vertical fade for card image scrims and chips.
  static const LinearGradient scrimGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC17181C)],
  );

  /// Subtle tinted surface — used for "elevated" cards on white.
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7FA)],
  );

  /// Gradient text/icon accent for prices and headings.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC94D), Color(0xFFFFB800), Color(0xFFE89B00)],
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// A soft, layered shadow (not a flat default Material elevation) —
/// this one detail does a lot of work toward a "designed" rather than
/// "generated" feel.
class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> raised = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  static List<BoxShadow> colored(Color color, {double alpha = 0.28}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Colored halo for buttons/cards that sit on a light surface.
  static List<BoxShadow> glow(Color color, {double alpha = 0.35}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  /// Floating card shadow — deeper, softer, more "designed".
  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF17181C).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF17181C).withValues(alpha: 0.07),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];
}

/// Ready-made box decorations used across premium surfaces.
class AppDecors {
  /// Frosted-glass style surface (no BackdropFilter — cheap on purpose).
  static BoxDecoration glass({
    Color color = AppColors.surface,
    double radius = AppRadius.lg,
    BorderRadius? borderRadius,
  }) =>
      BoxDecoration(
        color: color.withValues(alpha: 0.86),
        borderRadius:
            borderRadius ?? BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: AppShadows.floating,
      );

  /// Elevated white card with hairline border.
  static BoxDecoration card({
    double radius = AppRadius.lg,
    Color? color,
    List<BoxShadow>? shadow,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: shadow ?? AppShadows.soft,
      );

  /// Circular gradient chip (category icons, avatars).
  static BoxDecoration gradientCircle(
    LinearGradient gradient, {
    List<BoxShadow>? shadow,
  }) =>
      BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: shadow ?? AppShadows.colored(AppColors.primary),
      );
}

class AppTheme {
  static ThemeData get light {
    final TextTheme base = ThemeData.light(useMaterial3: true).textTheme;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),

      textTheme: base.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
      ),
    );
  }
}
