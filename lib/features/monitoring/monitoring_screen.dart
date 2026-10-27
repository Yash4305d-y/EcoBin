import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_fill_gauge.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/providers/device_provider.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

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

                  // Hero Gauge Card
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
                              if (status.isDemo)
                                const DemoBadge(text: 'SIMULATED DATA'),
                            ],
                          ),
                          AppSpacing.gapH24,

                          // Large Animated Gauge
                          AnimatedFillGauge(
                            fillPercentage: fill,
                            isDemo: status.isDemo,
                            size: 220,
                            strokeWidth: 16,
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
                                        ? 'Sensor reading unavailable. The ultrasonic probe did not return a valid echo.'
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
                          range: '— %',
                          description: 'Sensor probe disconnected',
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
                        const Text(
                          'Hardware Probe Metrics (Simulated)',
                          style: AppTextStyles.titleSmall,
                        ),
                        AppSpacing.gapH12,
                        _MetricLine(
                          label: 'Transducer Type',
                          value: 'HC-SR04 Ultrasonic Sensor',
                        ),
                        _MetricLine(
                          label: 'Echo Range',
                          value: '2 cm – 400 cm (Accuracy ±3mm)',
                        ),
                        _MetricLine(
                          label: 'Poll Cycle',
                          value: 'Continuous (5.0s interval)',
                        ),
                        _MetricLine(
                          label: 'Bin Height Calibration',
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
