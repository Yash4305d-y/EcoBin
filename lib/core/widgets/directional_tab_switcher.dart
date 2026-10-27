import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Direction-aware animated tab container that preserves state across all tabs.
///
/// Animation rules:
/// - Moving to higher tab index: old content shifts left by ~24px and fades out;
///   new content enters from the right.
/// - Moving to lower tab index: reverse the direction.
/// - Scale transition: incoming scales 0.97 -> 1.0; outgoing scales 1.0 -> 0.97.
/// - Target timing: 300 ms with [AppMotion.enterCurve] (Curves.easeOutCubic).
/// - Wrapped in [RepaintBoundary] per tab for optimal rendering.
/// - Respects system accessibility reduced-motion settings.
class DirectionalTabSwitcher extends StatefulWidget {
  const DirectionalTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<DirectionalTabSwitcher> createState() => _DirectionalTabSwitcherState();
}

class _DirectionalTabSwitcherState extends State<DirectionalTabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final Animation<double> _animation;

  int _previousIndex = 0;
  double _direction =
      1.0; // 1.0 = moving right (higher index), -1.0 = moving left

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _transitionController = AnimationController(
      vsync: this,
      duration: AppMotion.pageTransition,
    );
    _animation = CurvedAnimation(
      parent: _transitionController,
      curve: AppMotion.enterCurve,
    );
  }

  @override
  void didUpdateWidget(covariant DirectionalTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;

      _previousIndex = oldWidget.currentIndex;
      _direction = widget.currentIndex > oldWidget.currentIndex ? 1.0 : -1.0;

      if (disableAnimations) {
        _transitionController.value = 1.0;
      } else {
        _transitionController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final isAnimating = _transitionController.isAnimating;
        final t = _animation.value;

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final isCurrent = index == widget.currentIndex;
            final isPrevious = index == _previousIndex && isAnimating;
            final isVisible = isCurrent || isPrevious;

            if (!isVisible) {
              return Visibility(
                key: ValueKey<int>(index),
                visible: false,
                maintainState: true,
                child: TickerMode(
                  enabled: false,
                  child: widget.children[index],
                ),
              );
            }

            Widget animatedTab;

            if (isCurrent) {
              // Incoming Tab: enters in direction of movement (+/- 24px), scales 0.97 -> 1.0, fades 0.0 -> 1.0
              final opacity = isAnimating ? t.clamp(0.0, 1.0) : 1.0;
              final scale = isAnimating ? (0.97 + (0.03 * t)) : 1.0;
              final slideX = isAnimating
                  ? ((1.0 - t) * _direction * 24.0)
                  : 0.0;

              animatedTab = Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(slideX, 0.0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: widget.children[index],
                  ),
                ),
              );
            } else {
              // Outgoing Tab: leaves in opposite direction (-/+ 24px), scales 1.0 -> 0.97, fades 1.0 -> 0.0
              final opacity = (1.0 - t).clamp(0.0, 1.0);
              final scale = 1.0 - (0.03 * t);
              final slideX = -_direction * t * 24.0;

              animatedTab = Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(slideX, 0.0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: widget.children[index],
                  ),
                ),
              );
            }

            return Visibility(
              key: ValueKey<int>(index),
              visible: true,
              maintainState: true,
              child: TickerMode(
                enabled: isCurrent,
                child: RepaintBoundary(child: animatedTab),
              ),
            );
          }),
        );
      },
    );
  }
}
