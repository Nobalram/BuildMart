import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any widget with a springy press-down scale + light haptic tick.
/// Used on cards, tiles and icon buttons for tactile micro-interaction.
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = true,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: widget.pressedScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : _handleTapDown,
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: widget.onTap == null ? null : _handleTapCancel,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress?.call();
            },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
