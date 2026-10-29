import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_fill_gauge.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/device_provider.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  String _getHandDistanceDisplay(DeviceStatus status) {
    if (status.handSensorOk == false) {
      return 'Unavailable';
    }
    if (status.handDistanceCm != null) {
      return '${status.handDistanceCm!.toStringAsFixed(1)} cm';
    }
    if (status.handSensorOk == true) {
      return 'Clear';
    }
    return 'Unknown';
  }

  String _getHandSensorDetail(DeviceStatus status) {
    if (status.handSensorOk == false) {
      return 'Hand sensor unavailable';
    }
    if (status.handDistanceCm != null) {
      if (status.handDistanceCm! <= 20.0) {
        return 'Object detected in range';
      } else {
        return 'Object out of trigger zone';
      }
    }
    if (status.handSensorOk == true) {
      return 'Clear: No object detected';
    }
    return 'Status unreported';
  }

  String _getFillSensorDetail(DeviceStatus status) {
    if (status.fillSensorOk == false) {
      return 'Fill sensor unavailable';
    }
    if (status.fillDistanceCm != null) {
      return 'Distance: ${status.fillDistanceCm!.toStringAsFixed(1)} cm';
    }
    if (status.fillPercentage != null) {
      return 'Capacity calculated';
    }
    if (status.fillSensorOk == true) {
      return 'Sensor online: Reading unavailable';
    }
    return 'Status unreported';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(deviceStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Monitoring & Telemetry')),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mintGreen),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapH16,
                  const Text(
                    "Couldn't connect to EcoBin",
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Ensure the device is powered on and on the same Wi-Fi network.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH16,
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(deviceRepositoryProvider).refreshStatus(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (status) {
            final fill = status.fillPercentage;

            return SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Radial Gauge
                  Center(
                    child: Hero(
                      tag: 'ecobin_hero_fill_gauge',
                      child: Material(
                        color: Colors.transparent,
                        child: AnimatedFillGauge(
                          fillPercentage: fill,
                          size: 210,
                          strokeWidth: 15,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Dual Ultrasonic Sensors Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dual Ultrasonic Sensors',
                          style: AppTextStyles.titleMedium,
                        ),
                        AppSpacing.gapH12,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hand Sensor Indicator
                            Expanded(
                              child: _SensorTelemetryItem(
                                title: 'Hand Sensor',
                                icon: Icons.front_hand_rounded,
                                isOk: status.handSensorOk,
                                primaryMetric: _getHandDistanceDisplay(status),
                                statusDetail: _getHandSensorDetail(status),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 80,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              color: AppColors.slateOutlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            // Fill Sensor Indicator
                            Expanded(
                              child: _SensorTelemetryItem(
                                title: 'Fill Sensor',
                                icon: Icons.straighten_rounded,
                                isOk: status.fillSensorOk,
                                primaryMetric: fill != null
                                    ? '${fill.toStringAsFixed(0)}%'
                                    : 'Unavailable',
                                statusDetail: _getFillSensorDetail(status),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Sensor Telemetry Specifications
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Telemetry Diagnostics',
                          style: AppTextStyles.titleSmall,
                        ),
                        AppSpacing.gapH12,
                        _DiagnosticLine(
                          label: 'Hand Sensor Echo',
                          value: status.handDistanceCm != null
                              ? '${status.handDistanceCm!.toStringAsFixed(1)} cm'
                              : (status.handSensorOk == false
                                    ? 'Unavailable'
                                    : 'Out of range'),
                        ),
                        _DiagnosticLine(
                          label: 'Fill Sensor Depth',
                          value: status.fillDistanceCm != null
                              ? '${status.fillDistanceCm!.toStringAsFixed(1)} cm'
                              : (status.fillSensorOk == false
                                    ? 'Unavailable'
                                    : (fill != null
                                          ? '${fill.toStringAsFixed(0)}%'
                                          : 'Unavailable')),
                        ),
                        _DiagnosticLine(
                          label: 'Poll Cycle',
                          value: '5.0s continuous',
                        ),
                        _DiagnosticLine(
                          label: 'Total Calibration Depth',
                          value:
                              '${AppConstants.defaultEmptyDistanceCm.toStringAsFixed(1)} cm',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SensorTelemetryItem extends StatelessWidget {
  const _SensorTelemetryItem({
    required this.title,
    required this.icon,
    required this.isOk,
    required this.primaryMetric,
    required this.statusDetail,
  });

  final String title;
  final IconData icon;
  final bool? isOk;
  final String primaryMetric;
  final String statusDetail;

  @override
  Widget build(BuildContext context) {
    final Color healthColor = isOk == true
        ? AppColors.mintGreen
        : isOk == false
        ? AppColors.error
        : AppColors.textTertiary;

    final String healthLabel = isOk == true
        ? 'HEALTHY'
        : isOk == false
        ? 'FAILURE'
        : 'UNREPORTED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: healthColor, size: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: healthColor.withValues(alpha: 0.15),
                borderRadius: AppRadii.borderRadiusXs,
              ),
              child: Text(
                healthLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: healthColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapH4,
        Text(
          primaryMetric,
          style: AppTextStyles.titleMedium.copyWith(
            color: isOk == false ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          statusDetail,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            color: isOk == false ? AppColors.error : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _DiagnosticLine extends StatelessWidget {
  const _DiagnosticLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
