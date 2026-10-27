import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_fill_gauge.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/device_provider.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  String _getHandDistanceDisplay(DeviceStatus status) {
    if (status.handSensorOk == false) {
      return 'Failure';
    }
    if (status.handDistanceCm != null) {
      return '${status.handDistanceCm!.toStringAsFixed(1)} cm';
    }
    if (status.handSensorOk == true) {
      return 'No Object';
    }
    return 'Unknown';
  }

  String _getHandSensorDetail(DeviceStatus status) {
    if (status.handSensorOk == false) {
      return 'Sensor failure: Echo timeout or hardware error';
    }
    if (status.handDistanceCm != null) {
      if (status.handDistanceCm! <= 20.0) {
        return 'Object detected in trigger zone (≤ 20cm)';
      } else {
        return 'Object far away (> 20cm trigger zone)';
      }
    }
    if (status.handSensorOk == true) {
      return 'Clear: No object in range (Far away)';
    }
    return 'Health status not reported';
  }

  String _getFillSensorDetail(DeviceStatus status) {
    if (status.fillSensorOk == false) {
      return 'Sensor failure: Echo timeout or hardware error';
    }
    if (status.fillDistanceCm != null) {
      return 'Depth: ${status.fillDistanceCm!.toStringAsFixed(1)} cm to waste';
    }
    if (status.fillPercentage != null) {
      return 'Calculated capacity from fill sensor';
    }
    if (status.fillSensorOk == true) {
      return 'Sensor online: Reading unavailable';
    }
    return 'Health status not reported';
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
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (status) {
            final fill = status.fillPercentage;
            final isOffline = fill == null;

            return SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (status.isDemo)
                    const DemoBanner(
                      message: 'Sensor Telemetry is simulated for demonstration and threshold validation.',
                    ),

                  // Dual Ultrasonic Sensors Health & Telemetry Card
                  Container(
                    padding: AppSpacing.paddingCard,
                    decoration: BoxDecoration(
                      color: AppColors.slateSurface,
                      borderRadius: AppRadii.borderRadiusLg,
                      border: Border.all(color: AppColors.slateOutlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dual Ultrasonic Sensors',
                              style: AppTextStyles.titleMedium,
                            ),
                            if (status.isDemo)
                              const DemoBadge(text: 'SIMULATED DATA')
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintGreenContainer,
                                  borderRadius: AppRadii.borderRadiusXs,
                                ),
                                child: Text(
                                  'REAL SENSORS',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.onMintGreenContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        AppSpacing.gapH16,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hand Sensor Indicator
                            Expanded(
                              child: _SensorTelemetryBox(
                                title: 'Hand Sensor',
                                subtitle: 'Proximity Trigger',
                                icon: Icons.front_hand_rounded,
                                isOk: status.handSensorOk,
                                isDemo: status.isDemo,
                                primaryMetric: _getHandDistanceDisplay(status),
                                statusDetail: _getHandSensorDetail(status),
                              ),
                            ),
                            AppSpacing.gapW12,
                            // Fill Sensor Indicator
                            Expanded(
                              child: _SensorTelemetryBox(
                                title: 'Fill Sensor',
                                subtitle: 'Waste Depth Level',
                                icon: Icons.straighten_rounded,
                                isOk: status.fillSensorOk,
                                isDemo: status.isDemo,
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
                  AppSpacing.gapH20,

                  // Hero Gauge Card (Internal Fill Sensor Only)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ultrasonic Fill Sensor',
                                style: AppTextStyles.titleMedium,
                              ),
                              Text(
                                'Fill Sensor Only',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.mintGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapH24,

                          // Large Animated Gauge (Fill Sensor Only) with Hero Shared Element
                          Hero(
                            tag: 'ecobin_hero_fill_gauge',
                            child: Material(
                              color: Colors.transparent,
                              child: AnimatedFillGauge(
                                fillPercentage: fill,
                                isDemo: status.isDemo,
                                size: 220,
                                strokeWidth: 16,
                              ),
                            ),
                          ),
                          AppSpacing.gapH24,

                          // Capacity Explanation
                          Container(
                            padding: AppSpacing.paddingCard,
                            decoration: BoxDecoration(
                              color: isOffline
                                  ? AppColors.errorContainer.withValues(
                                      alpha: 0.2,
                                    )
                                  : (fill < 50.0)
                                  ? AppColors.mintGreenContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : (fill <= 80.0)
                                  ? AppColors.warningContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.errorContainer.withValues(
                                      alpha: 0.3,
                                    ),
                              borderRadius: AppRadii.borderRadiusMd,
                              border: Border.all(
                                color: isOffline
                                    ? AppColors.error.withValues(alpha: 0.5)
                                    : (fill < 50.0)
                                    ? AppColors.mintGreen.withValues(alpha: 0.5)
                                    : (fill <= 80.0)
                                    ? AppColors.warning.withValues(alpha: 0.5)
                                    : AppColors.error.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isOffline
                                      ? Icons.warning_amber_rounded
                                      : (fill < 50.0)
                                      ? Icons.check_circle_outline_rounded
                                      : (fill <= 80.0)
                                      ? Icons.info_outline_rounded
                                      : Icons.error_outline_rounded,
                                  color: isOffline
                                      ? AppColors.error
                                      : (fill < 50.0)
                                      ? AppColors.mintGreen
                                      : (fill <= 80.0)
                                      ? AppColors.warning
                                      : AppColors.error,
                                ),
                                AppSpacing.gapW12,
                                Expanded(
                                  child: Text(
                                    isOffline
                                        ? 'Fill sensor reading unavailable. Probe returned null echo or is offline.'
                                        : (fill < 50.0)
                                        ? 'Normal Fill Level: Bin has ample available capacity.'
                                        : (fill <= 80.0)
                                        ? 'Moderate Fill Level: Approaching scheduled collection threshold.'
                                        : 'Critical Capacity Alert: Bin exceeds 80% and should be emptied immediately.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH20,

                  // Threshold Reference Legend
                  Container(
                    padding: AppSpacing.paddingCard,
                    decoration: BoxDecoration(
                      color: AppColors.slateSurface,
                      borderRadius: AppRadii.borderRadiusLg,
                      border: Border.all(color: AppColors.slateOutlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Telemetry Color Coding Scale',
                          style: AppTextStyles.titleSmall,
                        ),
                        AppSpacing.gapH12,
                        const _ThresholdLegendRow(
                          color: AppColors.mintGreen,
                          label: 'Normal Capacity',
                          range: '0% – 49%',
                          description: 'Safe operating level',
                        ),
                        const Divider(height: AppSpacing.lg),
                        const _ThresholdLegendRow(
                          color: AppColors.warning,
                          label: 'Warning Threshold',
                          range: '50% – 80%',
                          description: 'Prepare to empty',
                        ),
                        const Divider(height: AppSpacing.lg),
                        const _ThresholdLegendRow(
                          color: AppColors.error,
                          label: 'Critical Overflow',
                          range: '> 80%',
                          description: 'Immediate action required',
                        ),
                        const Divider(height: AppSpacing.lg),
                        const _ThresholdLegendRow(
                          color: AppColors.textTertiary,
                          label: 'Unavailable / Offline',
                          range: 'Unavailable',
                          description: 'Fill sensor probe offline / null echo',
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH20,

                  // Sensor Diagnostic Specifications
                  Container(
                    padding: AppSpacing.paddingCard,
                    decoration: BoxDecoration(
                      color: AppColors.slateSurfaceCard,
                      borderRadius: AppRadii.borderRadiusLg,
                      border: Border.all(color: AppColors.slateOutlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.isDemo
                              ? 'Hardware Probe Metrics (Simulated)'
                              : 'ESP32 Dual Sensor Specifications',
                          style: AppTextStyles.titleSmall,
                        ),
                        AppSpacing.gapH12,
                        _MetricLine(
                          label: 'Hand Proximity Sensor',
                          value: status.handSensorOk == true
                              ? 'Healthy (HC-SR04)'
                              : (status.handSensorOk == false
                                    ? 'Failure / Offline'
                                    : 'Not reported'),
                        ),
                        _MetricLine(
                          label: 'Hand Distance Echo',
                          value: status.handDistanceCm != null
                              ? '${status.handDistanceCm!.toStringAsFixed(1)} cm'
                              : (status.handSensorOk == false
                                    ? 'Sensor Failure'
                                    : 'Out of range (>400cm)'),
                        ),
                        _MetricLine(
                          label: 'Internal Fill Sensor',
                          value: status.fillSensorOk == true
                              ? 'Healthy (HC-SR04)'
                              : (status.fillSensorOk == false
                                    ? 'Failure / Offline'
                                    : 'Not reported'),
                        ),
                        _MetricLine(
                          label: 'Fill Depth Echo',
                          value: status.fillDistanceCm != null
                              ? '${status.fillDistanceCm!.toStringAsFixed(1)} cm'
                              : (status.fillSensorOk == false
                                    ? 'Sensor Failure'
                                    : 'Unavailable'),
                        ),
                        _MetricLine(
                          label: 'Poll Cycle',
                          value: 'Continuous (5.0s interval)',
                        ),
                        _MetricLine(
                          label: 'Bin Depth Calibration',
                          value: '65.0 cm (Total Depth)',
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

class _SensorTelemetryBox extends StatelessWidget {
  const _SensorTelemetryBox({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOk,
    required this.isDemo,
    required this.primaryMetric,
    required this.statusDetail,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool? isOk;
  final bool isDemo;
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
        : 'UNKNOWN';

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.slateSurfaceVariant,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(
          color: isOk == false
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.slateOutlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.mintGreen, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.15),
                  borderRadius: AppRadii.borderRadiusXs,
                  border: Border.all(color: healthColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      healthLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: healthColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          Text(title, style: AppTextStyles.titleSmall),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          AppSpacing.gapH8,
          Text(
            primaryMetric,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isOk == false ? AppColors.error : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            statusDetail,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: isOk == false ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdLegendRow extends StatelessWidget {
  const _ThresholdLegendRow({
    required this.color,
    required this.label,
    required this.range,
    required this.description,
  });

  final Color color;
  final String label;
  final String range;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.titleSmall),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Text(
          range,
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
