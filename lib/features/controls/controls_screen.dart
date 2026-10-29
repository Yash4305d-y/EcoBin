import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/status_chip.dart';
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
        final isConfirmed = currentLid == LidState.open;
        final message = isConfirmed
            ? 'Lid is open.'
            : 'Command sent. Awaiting confirmation from EcoBin.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isConfirmed
                ? AppColors.slateSurfaceVariant
                : AppColors.warningContainer,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't connect to EcoBin."),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleOpenLid(context, ref, status),
            ),
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
        final isConfirmed = currentLid == LidState.closed;
        final message = isConfirmed
            ? 'Lid is closed.'
            : 'Command sent. Awaiting confirmation from EcoBin.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isConfirmed
                ? AppColors.slateSurfaceVariant
                : AppColors.warningContainer,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't connect to EcoBin."),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleCloseLid(context, ref, status),
            ),
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
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.slateSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.warning, width: 1),
        ),
        enableDrag: true,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 600),
        builder: (sheetCtx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.build_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        'Enable Maintenance Mode?',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH8,
                const Text(
                  'Locks lid closed and halts proximity sensors for safe cleaning or bag replacement.',
                  style: AppTextStyles.bodySmall,
                ),
                AppSpacing.gapH20,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                        onPressed: () => Navigator.of(sheetCtx).pop(true),
                        child: const Text(
                          'Lock & Enable',
                          style: TextStyle(color: AppColors.onWarningContainer),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            content: Text('Mode: ${mode.displayName}.'),
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
                    'Check that the bin is powered and on the same Wi-Fi network.',
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
            final isLidMoving = status.lidState == LidState.moving || isPending;
            final isLidOpen = status.lidState == LidState.open;
            final isLidClosed = status.lidState == LidState.closed;
            final isMaintenance = status.mode == OperatingMode.maintenance;

            return SingleChildScrollView(
              padding: AppSpacing.paddingScreenWithNav,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Status Bar
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        StatusChip(
                          label: status.lidState.displayName,
                          icon: isLidMoving
                              ? Icons.sync_rounded
                              : isLidOpen
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                          accentColor: isLidMoving
                              ? AppColors.info
                              : isLidOpen
                              ? AppColors.warning
                              : AppColors.mintGreen,
                        ),
                        const Spacer(),
                        StatusChip(
                          label: status.mode.displayName,
                          icon: status.mode == OperatingMode.automatic
                              ? Icons.auto_mode_rounded
                              : status.mode == OperatingMode.manual
                              ? Icons.touch_app_rounded
                              : Icons.build_rounded,
                          accentColor: isMaintenance
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Manual Actuation Section Header
                  const Text(
                    'Manual Actuation',
                    style: AppTextStyles.titleMedium,
                  ),
                  AppSpacing.gapH12,

                  // Open / Close Buttons Row
                  Row(
                    children: [
                      // Open Lid Button
                      Expanded(
                        child: PressableScale(
                          enabled: !isLidMoving && !isLidOpen && !isMaintenance,
                          onTap: (isLidMoving || isLidOpen || isMaintenance)
                              ? null
                              : () => _handleOpenLid(context, ref, status),
                          child: FilledButton.icon(
                            onPressed:
                                (isLidMoving || isLidOpen || isMaintenance)
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
                      ),
                      AppSpacing.gapW12,

                      // Close Lid Button
                      Expanded(
                        child: PressableScale(
                          enabled: !isLidMoving && !isLidClosed,
                          onTap: (isLidMoving || isLidClosed)
                              ? null
                              : () => _handleCloseLid(context, ref, status),
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
                      ),
                    ],
                  ),
                  AppSpacing.gapH24,

                  // Operating Mode Selection Header
                  const Text(
                    'Operating Mode',
                    style: AppTextStyles.titleMedium,
                  ),
                  AppSpacing.gapH12,

                  _ModeOptionTile(
                    title: 'Automatic Mode',
                    subtitle:
                        'Ultrasonic proximity triggers hands-free opening',
                    icon: Icons.auto_mode_rounded,
                    selected: status.mode == OperatingMode.automatic,
                    disabled: isPending,
                    onTap: () =>
                        _handleSetMode(context, ref, OperatingMode.automatic),
                  ),
                  AppSpacing.gapH8,

                  _ModeOptionTile(
                    title: 'Manual Mode',
                    subtitle: 'App or button controls only (sensor disabled)',
                    icon: Icons.touch_app_rounded,
                    selected: status.mode == OperatingMode.manual,
                    disabled: isPending,
                    onTap: () =>
                        _handleSetMode(context, ref, OperatingMode.manual),
                  ),
                  AppSpacing.gapH8,

                  _ModeOptionTile(
                    title: 'Maintenance Mode',
                    subtitle: 'Lid locked closed for bag changing or cleaning',
                    icon: Icons.build_rounded,
                    selected: status.mode == OperatingMode.maintenance,
                    disabled: isPending,
                    onTap: () =>
                        _handleSetMode(context, ref, OperatingMode.maintenance),
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

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: !disabled,
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.smoothCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.slateSurfaceVariant
              : AppColors.slateSurface,
          borderRadius: AppRadii.borderRadiusMd,
          border: Border.all(
            color: selected
                ? AppColors.mintGreen
                : AppColors.slateOutlineVariant.withValues(alpha: 0.6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.mintGreen : AppColors.textSecondary,
              size: 20,
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: selected
                          ? AppColors.mintGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.mintGreen,
              ),
          ],
        ),
      ),
    );
  }
}
