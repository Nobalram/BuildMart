import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_mode.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium/fade_slide_in.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  Widget _featurePill(IconData icon, String label, int index) {
    return FadeSlideIn(
      delayMs: 500 + (index * 130),
      offset: const Offset(0, 0.2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
                begin: Alignment(-1 + t * 0.5, -1),
                end: Alignment(1, 1 - t * 0.4),
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
                // decorative floating orbs
                Positioned(
                  top: -70 - (t * 24),
                  right: -50,
                  child: _orb(220, Colors.white.withValues(alpha: 0.08)),
                ),
                Positioned(
                  bottom: 120 + (t * 30),
                  left: -70,
                  child: _orb(180, Colors.white.withValues(alpha: 0.06)),
                ),
                Positioned(
                  top: 180 + (t * 18),
                  left: 40,
                  child: _orb(70, Colors.white.withValues(alpha: 0.07)),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        FadeSlideIn(
                          delayMs: 60,
                          offset: const Offset(0, 0.25),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(26),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 40,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.primaryGradient
                                          .createShader(bounds),
                                  child: const Icon(
                                    Icons.construction_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Text(
                                'Welcome to BuildMart',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                'Sand, bricks, cement, steel & more —\ndelivered straight to your site.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.5,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            _featurePill(
                              Icons.local_shipping_outlined,
                              'Site Delivery',
                              0,
                            ),
                            _featurePill(
                              Icons.verified_outlined,
                              'Genuine Brands',
                              1,
                            ),
                            _featurePill(
                              Icons.support_agent_outlined,
                              'Order Support',
                              2,
                            ),
                          ],
                        ),

                        const Spacer(flex: 3),

                        FadeSlideIn(
                          delayMs: 320,
                          offset: const Offset(0, 0.3),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppRadius.xl,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                AppButton(
                                  label: 'Create Account',
                                  type: AppButtonType.gradient,
                                  icon: Icons.person_add_alt_outlined,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(
                                          mode: AuthMode.signup,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm + 2),
                                AppButton(
                                  label: 'Login',
                                  type: AppButtonType.outlined,
                                  icon: Icons.login_rounded,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(
                                          mode: AuthMode.login,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'By continuing you agree to our Terms & Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 60)],
      ),
    );
  }
}
