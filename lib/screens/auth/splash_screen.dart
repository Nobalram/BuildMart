import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'welcome_screen.dart';
import 'profile_setup_screen.dart';
import '../home/main_shell.dart';

/// Premium splash: staged logo entrance, shine sweep across the mark,
/// drifting background orbs, animated wordmark reveal and a progress bar
/// that resolves as Firebase auth is checked.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.5, curve: Curves.elasticOut),
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.28, curve: Curves.easeOut),
  );

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.28, 0.55, curve: Curves.easeOut),
  );

  late final Animation<double> _titleRise = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.28, 0.6, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _tagFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> _shine = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.55, 0.95, curve: Curves.easeInOut),
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.1, 1, curve: Curves.easeInOut),
  );

  bool _routing = false;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for both the splash animation AND Firebase's real auth
    // state to resolve — on a cold start, Firebase needs a moment to
    // restore a previously signed-in session from disk, so checking
    // too early can wrongly look like "logged out".
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1900)),
      ref.read(authServiceProvider).authStateChanges.first,
    ]);

    if (!mounted) return;
    final user = results[1];

    if (user == null) {
      _goTo(const WelcomeScreen());
      return;
    }

    // Logged in — check whether a profile document exists yet.
    try {
      final profile = await ref
          .read(userRepositoryProvider)
          .getUser(user.uid);
      if (!mounted) return;
      _goTo(
        profile == null ? const ProfileSetupScreen() : const MainShell(),
      );
    } catch (_) {
      // Firestore hiccup — never trap the user on splash.
      if (!mounted) return;
      _goTo(const MainShell());
    }
  }

  void _goTo(Widget screen) {
    if (_routing || !mounted) return;
    _routing = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => screen,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.03, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    super.dispose();
  }

  Widget _orb(double size, Color color, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          final t = _drift.value;
          final dx = math.sin(t * math.pi * 2) * 18;
          final dy = math.cos(t * math.pi * 2) * 14;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 60,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          final t = _drift.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -1 + t * 0.6,
                  -1 + t * 0.3,
                ),
                end: Alignment(1 - t * 0.3, 1),
                colors: const [
                  Color(0xFFFF8A4C),
                  AppColors.primary,
                  Color(0xFF9C3F0D),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _orb(200, Colors.white.withValues(alpha: 0.07), Alignment.topRight),
                _orb(260, Colors.white.withValues(alpha: 0.05), Alignment.bottomLeft),
                _orb(140, Colors.white.withValues(alpha: 0.06), const Alignment(0.7, 0.2)),

                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // ---- Logo mark ----
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => AppColors
                                        .primaryGradient
                                        .createShader(bounds),
                                    child: const Icon(
                                      Icons.construction_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // shine sweep
                                  AnimatedBuilder(
                                    animation: _shine,
                                    builder: (context, _) {
                                      final x = -0.6 + (_shine.value * 2.2);
                                      return Positioned.fill(
                                        child: ShaderMask(
                                          blendMode: BlendMode.srcATop,
                                          shaderCallback: (bounds) =>
                                              LinearGradient(
                                                begin: Alignment(x - 1, 0),
                                                end: Alignment(x + 1, 0),
                                                colors: const [
                                                  Colors.transparent,
                                                  Colors.white,
                                                  Colors.transparent,
                                                ],
                                              ).createShader(bounds),
                                          child: Container(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ---- Wordmark ----
                      FadeTransition(
                        opacity: _titleFade,
                        child: Transform.translate(
                          offset: Offset(0, 26 * (1 - _titleRise.value)),
                          child: const Text(
                            'BuildMart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      FadeTransition(
                        opacity: _tagFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(
                              AppRadius.pill,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Text(
                            'CONSTRUCTION MATERIALS, DELIVERED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // ---- Progress bar ----
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl + AppSpacing.lg,
                        ),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) {
                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: _progress.value,
                                    minHeight: 3,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.25),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Preparing your site supplies…',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
