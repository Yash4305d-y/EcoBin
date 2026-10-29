import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

/// A button wrapper that scales down to 0.97 on press and provides
/// subtle light haptic feedback for deliberate, responsive interactions.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.targetScale = 0.97,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double targetScale;
  final bool enableHaptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.micro);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? _handleTapDown : null,
      onTapUp: widget.enabled ? _handleTapUp : null,
      onTapCancel: widget.enabled ? _handleTapCancel : null,
      child: AnimatedScale(
        scale: _isPressed && widget.enabled ? widget.targetScale : 1.0,
        duration: duration,
        curve: AppMotion.snappyCurve,
        child: widget.child,
      ),
    );
  }
}
