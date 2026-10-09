import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium/fade_slide_in.dart';
import '../home/main_shell.dart';

class OrderSuccessScreen extends StatefulWidget {
  final int orderCount;

  const OrderSuccessScreen({super.key, required this.orderCount});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final AnimationController _pulse;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _controller.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulse.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // soft background wash
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFF3EA),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ---- Success mark with pulsing rings ----
                  ScaleTransition(
                    scale: _scale,
                    child: SizedBox(
                      width: 148,
                      height: 148,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final t = _pulse.value;
                              return Container(
                                width: 96 + (t * 52),
                                height: 96 + (t * 52),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success.withValues(
                                    alpha: 0.16 * (1 - t),
                                  ),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.30 * (1 - t),
                                    ),
                                    width: 1.6,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF34B36C), AppColors.success],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.colored(
                                AppColors.success,
                                alpha: 0.45,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  FadeSlideIn(
                    delayMs: 250,
                    child: Text(
                      'Order Placed!',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delayMs: 380,
                    child: Text(
                      widget.orderCount > 1
                          ? 'Your order has been split into ${widget.orderCount} shipments\nsince items came from different sellers.'
                          : 'Your order has been placed successfully.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  FadeSlideIn(
                    delayMs: 480,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: AppDecors.card(shadow: AppShadows.floating),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Track your order anytime from Profile → My Orders.',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  FadeSlideIn(
                    delayMs: 560,
                    offset: const Offset(0, 0.2),
                    child: AppButton(
                      label: 'Continue Shopping',
                      type: AppButtonType.gradient,
                      icon: Icons.storefront_rounded,
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 28,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              AppColors.primary,
              AppColors.success,
              AppColors.warning,
              AppColors.info,
              AppColors.star,
            ],
          ),
        ],
      ),
    );
  }
}
