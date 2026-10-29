import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/device_connection_state.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/device_provider.dart';
import '../../data/providers/settings_provider.dart';

class ControlsScreen extends ConsumerStatefulWidget {
  const ControlsScreen({super.key});

  @override
  ConsumerState<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends ConsumerState<ControlsScreen> {
  /// Tracks the user's selected mode in the UI so that mode selection
  /// and button visibility remain 100% consistent, even when the device is offline.
  OperatingMode? _selectedMode;

  void _handleDisabledTap(
    BuildContext context, {
    required bool isOffline,
    required bool isLidMoving,
    required bool isLidOpen,
    required bool isOpenAction,
    required bool isMaintenance,
  }) {
    if (isMaintenance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot actuate lid while Maintenance Mode is active (Lid Locked).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cannot actuate: EcoBin is offline. Check Wi-Fi connection or enable Simulation Mode in Settings.',
          ),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Simulate',
            textColor: Colors.white,
            onPressed: () {
              ref.read(settingsProvider.notifier).setDemoMode(true);
            },
          ),
        ),
      );
      return;
    }

    if (isLidMoving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lid command in progress. Please wait.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isOpenAction && isLidOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lid is already open.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!isOpenAction && !isLidOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lid is already closed.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  }

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
    HapticFeedback.mediumImpact();
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't open lid: $e"),
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

    if (status.mode == OperatingMode.maintenance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot close lid: Maintenance Mode is active (Lid Locked).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(isCommandPendingProvider.notifier).setPending(true);
    HapticFeedback.mediumImpact();
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't close lid: $e"),
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
    DeviceStatus status,
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
      if (confirmed != true) {
        setState(() {
          _selectedMode = status.mode;
        });
        return;
      }
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
        final isOffline =
            status.connectionStatus == DeviceConnectionStatus.offline;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'EcoBin offline: Mode set to ${mode.displayName} locally in app.'
                  : 'Mode change rejected: $e',
            ),
            backgroundColor: isOffline ? AppColors.warning : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.read(isCommandPendingProvider.notifier).setPending(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(deviceStatusProvider);
    final isPending = ref.watch(isCommandPendingProvider);
    final settings = ref.watch(settingsProvider);

    // Always resolve to a valid status so controls remain visible even when offline or before first poll
    final status =
        statusAsync.value ??
        ref.read(deviceRepositoryProvider).getCurrentStatus();

    final activeMode = _selectedMode ?? status.mode;
    final isOffline = status.connectionStatus == DeviceConnectionStatus.offline;
    final isLidMoving = status.lidState == LidState.moving || isPending;
    final isLidOpen = status.lidState == LidState.open;
    final isMaintenance = activeMode == OperatingMode.maintenance;

    // Both buttons remain visible in Manual mode.
    // If device is offline, hardware commands are disabled with a clear explanation.
    final canActuate = !isOffline && !isLidMoving && !isMaintenance;
    final canOpen = canActuate && !isLidOpen;
    final canClose = canActuate && isLidOpen;

    return Scaffold(
      appBar: AppBar(title: const Text('Bin Actuation & Controls')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreenWithNav,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Offline banner offering explanation and local simulation option
              if (isOffline && !settings.isDemoMode) ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 20,
                        color: AppColors.warning,
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'EcoBin is Offline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hardware commands disabled. Connect to EcoBin or enable Simulation Mode.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(settingsProvider.notifier).setDemoMode(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Simulation Mode enabled. Actuation commands operate locally in mock.',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Simulate'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH16,
              ],

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
                      label: activeMode.displayName,
                      icon: activeMode == OperatingMode.automatic
                          ? Icons.auto_mode_rounded
                          : activeMode == OperatingMode.manual
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

              // Manual Actuation Section: Specifically shown in Manual Mode
              if (activeMode == OperatingMode.manual) ...[
                const Text(
                  'Manual Actuation',
                  style: AppTextStyles.titleMedium,
                ),
                AppSpacing.gapH12,

                // Informative explanation when offline
                if (isOffline) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'EcoBin is offline. Reconnect Wi-Fi or enable Simulation Mode to actuate.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Row(
                  children: [
                    // Open Lid Button
                    Expanded(
                      child: PressableScale(
                        enabled: canOpen,
                        onTap: () {
                          if (canOpen) {
                            _handleOpenLid(context, ref, status);
                          } else {
                            _handleDisabledTap(
                              context,
                              isOffline: isOffline,
                              isLidMoving: isLidMoving,
                              isLidOpen: isLidOpen,
                              isOpenAction: true,
                              isMaintenance: isMaintenance,
                            );
                          }
                        },
                        child: SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: canOpen
                                ? () => _handleOpenLid(context, ref, status)
                                : null,
                            icon: isLidMoving && !isLidOpen
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
                    ),
                    AppSpacing.gapW12,
                    // Close Lid Button
                    Expanded(
                      child: PressableScale(
                        enabled: canClose,
                        onTap: () {
                          if (canClose) {
                            _handleCloseLid(context, ref, status);
                          } else {
                            _handleDisabledTap(
                              context,
                              isOffline: isOffline,
                              isLidMoving: isLidMoving,
                              isLidOpen: isLidOpen,
                              isOpenAction: false,
                              isMaintenance: isMaintenance,
                            );
                          }
                        },
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: canClose
                                ? () => _handleCloseLid(context, ref, status)
                                : null,
                            icon: isLidMoving && isLidOpen
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.mintGreen,
                                    ),
                                  )
                                : const Icon(Icons.arrow_downward_rounded),
                            label: const Text('Close Lid'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH24,
              ],

              // Operating Mode Selection Header
              const Text('Operating Mode', style: AppTextStyles.titleMedium),
              AppSpacing.gapH12,

              _ModeOptionTile(
                title: 'Automatic Mode',
                subtitle: 'Ultrasonic proximity triggers hands-free opening',
                icon: Icons.auto_mode_rounded,
                selected: activeMode == OperatingMode.automatic,
                disabled: isPending,
                onTap: () {
                  setState(() {
                    _selectedMode = OperatingMode.automatic;
                  });
                  _handleSetMode(context, ref, OperatingMode.automatic, status);
                },
              ),
              AppSpacing.gapH8,

              _ModeOptionTile(
                title: 'Manual Mode',
                subtitle: 'App or button controls only (sensor disabled)',
                icon: Icons.touch_app_rounded,
                selected: activeMode == OperatingMode.manual,
                disabled: isPending,
                onTap: () {
                  setState(() {
                    _selectedMode = OperatingMode.manual;
                  });
                  _handleSetMode(context, ref, OperatingMode.manual, status);
                },
              ),
              AppSpacing.gapH8,

              _ModeOptionTile(
                title: 'Maintenance Mode',
                subtitle: 'Lid locked closed for bag changing or cleaning',
                icon: Icons.build_rounded,
                selected: activeMode == OperatingMode.maintenance,
                disabled: isPending,
                onTap: () {
                  setState(() {
                    _selectedMode = OperatingMode.maintenance;
                  });
                  _handleSetMode(
                    context,
                    ref,
                    OperatingMode.maintenance,
                    status,
                  );
                },
              ),
            ],
          ),
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
