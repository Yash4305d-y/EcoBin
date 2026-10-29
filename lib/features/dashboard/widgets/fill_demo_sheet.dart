import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../data/providers/demo_mode_provider.dart';

/// Shows the developer-only Fill Level Demo bottom sheet.
Future<void> showFillDemoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.slateSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: AppColors.slateOutlineVariant),
    ),
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FillDemoSheet(),
  );
}

/// Developer-only preview controls for dustbin fill levels.
class FillDemoSheet extends ConsumerWidget {
  const FillDemoSheet({super.key});

  Color _getThresholdColor(double percentage) {
    if (percentage < 50.0) {
      return AppColors.mintGreen;
    } else if (percentage <= 80.0) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _getThresholdLabel(double percentage) {
    if (percentage < 50.0) {
      return 'Low Capacity (<50%)';
    } else if (percentage <= 80.0) {
      return 'Moderate Fill (50-80%)';
    } else {
      return 'Nearly Full (>80%)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFill = ref.watch(fillDemoOverrideProvider);
    final activeFill = currentFill ?? 50.0;
    final isEnabled = currentFill != null;
    final thresholdColor = _getThresholdColor(activeFill);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen.withValues(alpha: 0.12),
                    borderRadius: AppRadii.borderRadiusSm,
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: AppColors.mintGreen,
                    size: 20,
                  ),
                ),
                AppSpacing.gapW12,
                const Expanded(
                  child: Text(
                    'Fill Level Demo Preview',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: AppRadii.borderRadiusXs,
                  ),
                  child: const Text(
                    'DEBUG ONLY',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,

            // Informational disclaimer
            Text(
              'Simulate fill gauge animations and threshold color transitions in emulator. Connection status remains genuinely Offline.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapH16,

            // Active percentage display & Threshold status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                borderRadius: AppRadii.borderRadiusMd,
                border: Border.all(
                  color: isEnabled
                      ? thresholdColor.withValues(alpha: 0.5)
                      : AppColors.slateOutlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? thresholdColor
                              : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Text(
                        isEnabled
                            ? '${activeFill.toStringAsFixed(0)}% Full'
                            : 'Demo Disabled (Authentic Mode)',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isEnabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (isEnabled)
                    Text(
                      _getThresholdLabel(activeFill),
                      style: TextStyle(
                        color: thresholdColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.gapH16,

            // Preset Buttons (0%, 25%, 50%, 75%, 100%)
            const Text(
              'Presets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapH8,
            Row(
              children: [
                _PresetButton(
                  label: '0%',
                  sublabel: 'Empty',
                  percentage: 0.0,
                  isSelected: isEnabled && activeFill == 0.0,
                  onTap: () => ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(0.0),
                ),
                AppSpacing.gapW8,
                _PresetButton(
                  label: '25%',
                  sublabel: 'Low',
                  percentage: 25.0,
                  isSelected: isEnabled && activeFill == 25.0,
                  onTap: () => ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(25.0),
                ),
                AppSpacing.gapW8,
                _PresetButton(
                  label: '50%',
                  sublabel: 'Half',
                  percentage: 50.0,
                  isSelected: isEnabled && activeFill == 50.0,
                  onTap: () => ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(50.0),
                ),
                AppSpacing.gapW8,
                _PresetButton(
                  label: '75%',
                  sublabel: 'Nearly',
                  percentage: 75.0,
                  isSelected: isEnabled && activeFill == 75.0,
                  onTap: () => ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(75.0),
                ),
                AppSpacing.gapW8,
                _PresetButton(
                  label: '100%',
                  sublabel: 'Full',
                  percentage: 100.0,
                  isSelected: isEnabled && activeFill == 100.0,
                  onTap: () => ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(100.0),
                ),
              ],
            ),
            AppSpacing.gapH16,

            // Continuous Slider
            const Text(
              'Continuous Level',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: thresholdColor,
                inactiveTrackColor: AppColors.slateSurfaceVariant,
                thumbColor: thresholdColor,
                overlayColor: thresholdColor.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: activeFill,
                min: 0.0,
                max: 100.0,
                divisions: 100,
                label: '${activeFill.round()}%',
                onChanged: (val) {
                  ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(val);
                },
              ),
            ),
            AppSpacing.gapH12,

            // Disable / Reset Button
            if (isEnabled)
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(fillDemoOverrideProvider.notifier).disable();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                label: const Text('Turn Off Demo Mode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.slateOutlineVariant),
                ),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(fillDemoOverrideProvider.notifier)
                      .setFillPercentage(50.0);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Enable Demo (Start at 50%)'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.sublabel,
    required this.percentage,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final double percentage;
  final bool isSelected;
  final VoidCallback onTap;

  Color _getColor() {
    if (percentage < 50.0) return AppColors.mintGreen;
    if (percentage <= 80.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : AppColors.slateSurfaceVariant,
            borderRadius: AppRadii.borderRadiusSm,
            border: Border.all(
              color: isSelected ? color : AppColors.slateOutlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? color : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
