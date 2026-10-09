import 'package:flutter/material.dart';

/// Staggered entrance: fades + slides up (or from any [offset]) with an
/// optional [delayMs]. Wrap list items / sections for a premium load-in.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 460),
    this.offset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  /// Convenience for column-style staggering:
  /// `FadeSlideIn.stagger(index: i, child: ...)`
  factory FadeSlideIn.stagger({
    Key? key,
    required int index,
    required Widget child,
    int stepMs = 70,
    int baseMs = 0,
    Offset offset = const Offset(0, 0.08),
  }) =>
      FadeSlideIn(
        key: key,
        delayMs: baseMs + (index * stepMs),
        offset: offset,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Interval(
        (delayMs / (delayMs + duration.inMilliseconds)).clamp(0.0, 0.9),
        1,
        curve: curve,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
