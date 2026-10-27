import 'package:flutter/material.dart';

import '../../data/models/device_connection_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Connection status indicator dot with a subtle, limited 2-cycle pulse
/// when entering the online state, stopping thereafter to save resources.
class PulsingStatusDot extends StatefulWidget {
  const PulsingStatusDot({
    super.key,
    required this.connectionStatus,
    this.isDemo = false,
  });

  final DeviceConnectionStatus connectionStatus;
  final bool isDemo;

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  int _cyclesCompleted = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _cyclesCompleted++;
        if (_cyclesCompleted < 2 && mounted && _isLive) {
          _pulseController.forward();
        }
      }
    });

    if (_isLive) {
      _pulseController.forward();
    }
  }

  bool get _isLive => widget.connectionStatus == DeviceConnectionStatus.online;

  Color get _dotColor {
    switch (widget.connectionStatus) {
      case DeviceConnectionStatus.online:
        return AppColors.mintGreen;
      case DeviceConnectionStatus.connecting:
        return AppColors.info;
      case DeviceConnectionStatus.offline:
      case DeviceConnectionStatus.error:
      case DeviceConnectionStatus.demoMode:
        return AppColors.error;
    }
  }

  @override
  void didUpdateWidget(covariant PulsingStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionStatus != widget.connectionStatus) {
      if (_isLive) {
        _cyclesCompleted = 0;
        _pulseController.forward(from: 0.0);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _dotColor;

    return SizedBox(
      width: 14,
      height: 14,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (_isLive && _pulseController.isAnimating)
                  Container(
                    width: 8 * _pulseAnimation.value,
                    height: 8 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(
                        alpha: (0.4 * (1.35 - _pulseAnimation.value) / 0.35)
                            .clamp(0.0, 0.4),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.standard),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: _isLive
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
