import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Smoothly animates integer counter changes over [AppMotion.standard].
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  int _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _prevValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.standard);

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: _prevValue, end: widget.value),
      duration: duration,
      curve: AppMotion.enterCurve,
      builder: (context, animatedValue, child) {
        return Text(
          '${widget.prefix}$animatedValue${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
