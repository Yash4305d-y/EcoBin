import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/device_provider.dart';

class ControlsScreen extends ConsumerWidget {
  const ControlsScreen({super.key});

  Future<void> _handleOpenLid(
    BuildContext context,
    WidgetRef ref,
    DeviceStatus status,
  ) async {
    final pending = ref.read(isCommandPendingProvider);
    if (pending ||
        status.lidState == LidState.open ||
        status.lidState == LidState.moving) {
      return;
    }

    if (status.mode == OperatingMode.maintenance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot open lid while Maintenance Mode is active (Lid Locked).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(isCommandPendingProvider.notifier).setPending(true);
    try {
      await ref.read(deviceRepositoryProvider).openLid();
      if (context.mounted) {
        final currentLid = ref
            .read(deviceRepositoryProvider)
            .getCurrentStatus()
            .lidState;
        final message = status.isDemo
            ? 'Simulated Action: Servo opened lid (Demo Mode).'
            : (currentLid == LidState.open
                  ? 'HTTP Command Confirmed: Lid is OPEN.'
                  : 'HTTP Command Accepted: Awaiting physical servo confirmation from ESP32.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: currentLid == LidState.open || status.isDemo
                ? AppColors.successContainer
                : AppColors.slateSurfaceVariant,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Command failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.read(isCommandPendingProvider.notifier).setPending(false);
    }
  }

  Future<void> _handleCloseLid(
    BuildContext context,
    WidgetRef ref,
    DeviceStatus status,
  ) async {
    final pending = ref.read(isCommandPendingProvider);
    if (pending ||
        status.lidState == LidState.closed ||
        status.lidState == LidState.moving) {
      return;
    }

    ref.read(isCommandPendingProvider.notifier).setPending(true);
    try {
      await ref.read(deviceRepositoryProvider).closeLid();
      if (context.mounted) {
        final currentLid = ref
            .read(deviceRepositoryProvider)
            .getCurrentStatus()
            .lidState;
        final message = status.isDemo
            ? 'Simulated Action: Servo closed lid (Demo Mode).'
            : (currentLid == LidState.closed
                  ? 'HTTP Command Confirmed: Lid is CLOSED.'
                  : 'HTTP Command Accepted: Awaiting physical servo confirmation from ESP32.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: currentLid == LidState.closed || status.isDemo
                ? AppColors.slateSurfaceVariant
                : AppColors.warningContainer,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Command failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.read(isCommandPendingProvider.notifier).setPending(false);
    }
  }

  Future<void> _handleSetMode(
    BuildContext context,
    WidgetRef ref,
    OperatingMode mode,
  ) async {
    final pending = ref.read(isCommandPendingProvider);
    if (pending) return;

    if (mode == OperatingMode.maintenance) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.slateSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderRadiusLg,
            side: const BorderSide(color: AppColors.warning),
          ),
          title: Row(
            children: const [
              Icon(Icons.build_rounded, color: AppColors.warning),
              AppSpacing.gapW8,
              Text(
                'Enable Maintenance Mode?',
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          content: const Text(
            'Maintenance Mode locks the bin lid closed and halts automatic proximity actuation routines. This prevents accidental opening while replacing waste bags or cleaning.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text(
                'Lock & Enable',
                style: TextStyle(color: AppColors.onWarningContainer),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    ref.read(isCommandPendingProvider.notifier).setPending(true);
    try {
      await ref.read(deviceRepositoryProvider).setOperatingMode(mode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode updated: ${mode.displayName}.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode change failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.read(isCommandPendingProvider.notifier).setPending(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(deviceStatusProvider);
    final isPending = ref.watch(isCommandPendingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bin Actuation & Controls')),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mintGreen),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (status) {
            final isLidMoving = status.lidState == LidState.moving || isPending;
            final isLidOpen = status.lidState == LidState.open;
            final isLidClosed = status.lidState == LidState.closed;
            final isMaintenance = status.mode == OperatingMode.maintenance;

            return SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (status.isDemo)
                    const DemoBanner(
                      message: 'Simulated Hardware: Commands execute on MockDeviceRepository with realistic latency.',
                    ),

                  // Current State Summary Card with smooth transition
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: AppSpacing.paddingCard,
                    decoration: BoxDecoration(
                      color: AppColors.slateSurface,
                      borderRadius: AppRadii.borderRadiusLg,
                      border: Border.all(color: AppColors.slateOutlineVariant),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isLidMoving
                                ? AppColors.warningContainer
                                : isLidOpen
                                ? AppColors.mintGreenContainer
                                : AppColors.slateSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLidMoving
                                ? Icons.sync_rounded
                                : isLidOpen
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: isLidMoving
                                ? AppColors.onWarningContainer
                                : isLidOpen
                                ? AppColors.mintGreen
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lid State: ${status.lidState.displayName}',
                                style: AppTextStyles.titleMedium,
                              ),
                              AppSpacing.gapH2,
                              Text(
                                'Active Mode: ${status.mode.displayName}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (isLidMoving)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mintGreen,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH12,

                  // Compact Sensor Overview
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slateSurfaceCard,
                      borderRadius: AppRadii.borderRadiusMd,
                      border: Border.all(color: AppColors.slateOutlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sensors_rounded,
                          size: 16,
                          color: AppColors.mintGreen,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'Sensors:',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (status.handSensorOk == true
                                        ? AppColors.mintGreen
                                        : status.handSensorOk == false
                                        ? AppColors.error
                                        : AppColors.textTertiary)
                                    .withValues(alpha: 0.15),
                            borderRadius: AppRadii.borderRadiusXs,
                          ),
                          child: Text(
                            'Hand: ${status.handSensorOk == true
                                ? "OK"
                                : status.handSensorOk == false
                                ? "FAIL"
                                : "N/A"}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: status.handSensorOk == true
                                  ? AppColors.mintGreen
                                  : status.handSensorOk == false
                                  ? AppColors.error
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        AppSpacing.gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (status.fillSensorOk == true
                                        ? AppColors.mintGreen
                                        : status.fillSensorOk == false
                                        ? AppColors.error
                                        : AppColors.textTertiary)
                                    .withValues(alpha: 0.15),
                            borderRadius: AppRadii.borderRadiusXs,
                          ),
                          child: Text(
                            'Fill: ${status.fillSensorOk == true
                                ? "OK"
                                : status.fillSensorOk == false
                                ? "FAIL"
                                : "N/A"}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: status.fillSensorOk == true
                                  ? AppColors.mintGreen
                                  : status.fillSensorOk == false
                                  ? AppColors.error
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          status.fillPercentage != null
                              ? '${status.fillPercentage!.toStringAsFixed(0)}% depth'
                              : 'Unavailable',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: status.fillPercentage != null
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH20,

                  // Lid Commands Section
                  const Text(
                    'Manual Servo Actuation',
                    style: AppTextStyles.titleMedium,
                  ),
                  AppSpacing.gapH4,
                  const Text(
                    'Conflicting actions are locked while actuation commands are running.',
                    style: AppTextStyles.bodySmall,
                  ),
                  AppSpacing.gapH12,

                  Row(
                    children: [
                      // Open Lid Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (isLidMoving || isLidOpen || isMaintenance)
                              ? null
                              : () => _handleOpenLid(context, ref, status),
                          icon: isLidMoving && !isLidClosed
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onMintGreen,
                                  ),
                                )
                              : const Icon(Icons.arrow_upward_rounded),
                          label: const Text('Open Lid'),
                        ),
                      ),
                      AppSpacing.gapW12,

                      // Close Lid Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (isLidMoving || isLidClosed)
                              ? null
                              : () => _handleCloseLid(context, ref, status),
                          icon: isLidMoving && !isLidOpen
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : const Icon(Icons.arrow_downward_rounded),
                          label: const Text('Close Lid'),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH24,

                  // Operating Mode Selection
                  const Text(
                    'Operating Mode Selection',
                    style: AppTextStyles.titleMedium,
                  ),
                  AppSpacing.gapH4,
                  const Text(
                    'Determines ultrasonic triggering and lid locking policies.',
                    style: AppTextStyles.bodySmall,
                  ),
                  AppSpacing.gapH12,

                  _ModeOptionTile(
                    title: 'Automatic Mode',
                    description: 'Ultrasonic proximity sensor triggers contactless opening when movement is detected within 20cm.',
                    icon: Icons.auto_mode_rounded,
                    selected: status.mode == OperatingMode.automatic,
                    disabled: isPending,
                    onTap: () =>
                        _handleSetMode(context, ref, OperatingMode.automatic),
                  ),
                  AppSpacing.gapH8,

                  _ModeOptionTile(
                    title: 'Manual Mode',
                    description: 'Disables ultrasonic proximity trigger. Bin only opens via companion app or physical override.',
                    icon: Icons.touch_app_rounded,
                    selected: status.mode == OperatingMode.manual,
                    disabled: isPending,
                    onTap: () =>
                        _handleSetMode(context, ref, OperatingMode.manual),
                  ),
                  AppSpacing.gapH8,

                  _ModeOptionTile(
                    title: 'Maintenance Mode',
                    description: 'Locks lid closed and halts all actuation routines for safe bag replacement or cleaning.',
                    icon: Icons.build_rounded,
                    selected: status.mode == OperatingMode.maintenance,
                    disabled: isPending,
                    onTap: () =>
                        _handleSetMode(context, ref, OperatingMode.maintenance),
                  ),
                  // Interactive Sandbox: Test Sensor Thresholds (Demo Mode Only)
                  if (status.isDemo) ...[
                    AppSpacing.gapH24,
                    Container(
                      padding: AppSpacing.paddingCard,
                      decoration: BoxDecoration(
                        color: AppColors.slateSurfaceCard,
                        borderRadius: AppRadii.borderRadiusLg,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.science_outlined,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              AppSpacing.gapW8,
                              Text(
                                'Demo Sandbox: Sensor Simulation',
                                style: AppTextStyles.titleSmall,
                              ),
                              Spacer(),
                              DemoBadge(),
                            ],
                          ),
                          AppSpacing.gapH8,
                          const Text(
                            'Test how the UI, gauge, and alerts respond to various capacity thresholds and offline states.',
                            style: AppTextStyles.bodySmall,
                          ),
                          AppSpacing.gapH12,
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _QuickPresetButton(
                                label: 'Low (25%)',
                                onPressed: () => ref
                                    .read(deviceRepositoryProvider)
                                    .setFillPercentage(25.0),
                              ),
                              _QuickPresetButton(
                                label: 'Moderate (64%)',
                                onPressed: () => ref
                                    .read(deviceRepositoryProvider)
                                    .setFillPercentage(64.0),
                              ),
                              _QuickPresetButton(
                                label: 'High (88%)',
                                onPressed: () => ref
                                    .read(deviceRepositoryProvider)
                                    .setFillPercentage(88.0),
                              ),
                              _QuickPresetButton(
                                label: 'Sensor Offline (Null)',
                                onPressed: () => ref
                                    .read(deviceRepositoryProvider)
                                    .setFillPercentage(null),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppRadii.borderRadiusMd,
      child: Container(
        padding: AppSpacing.paddingCard,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.slateSurfaceVariant
              : AppColors.slateSurface,
          borderRadius: AppRadii.borderRadiusMd,
          border: Border.all(
            color: selected
                ? AppColors.mintGreen
                : AppColors.slateOutlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.mintGreen : AppColors.textSecondary,
              size: 22,
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: selected
                              ? AppColors.mintGreen
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (selected) ...[
                        AppSpacing.gapW8,
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.mintGreen,
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapH4,
                  Text(description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPresetButton extends StatelessWidget {
  const _QuickPresetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      label: Text(label),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textPrimary,
      ),
      backgroundColor: AppColors.slateSurfaceVariant,
      side: const BorderSide(color: AppColors.slateOutlineVariant),
    );
  }
}
