import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_fill_gauge.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/pulsing_status_dot.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../data/models/device_connection_state.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/device_provider.dart';
import '../../navigation/app_nav_shell.dart';
import '../monitoring/monitoring_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenAlerts,
  });

  /// Allows jumping directly to primary bottom nav tabs (0: Home, 1: Controls, 2: Activity, 3: Settings)
  final void Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenAlerts;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _gaugeFade;
  late final Animation<Offset> _gaugeSlide;
  late final Animation<double> _sensorsFade;
  late final Animation<Offset> _sensorsSlide;
  late final Animation<double> _shortcutsFade;
  late final Animation<Offset> _shortcutsSlide;

  @override
  void initState() {
    super.initState();
    // Staggered entrance animation: ~60ms between items over a 450ms duration
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: AppMotion.enterCurve),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.55, curve: AppMotion.enterCurve),
          ),
        );

    _gaugeFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.70, curve: AppMotion.enterCurve),
    );
    _gaugeSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.15, 0.70, curve: AppMotion.enterCurve),
          ),
        );

    _sensorsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.85, curve: AppMotion.enterCurve),
    );
    _sensorsSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.30, 0.85, curve: AppMotion.enterCurve),
          ),
        );

    _shortcutsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: AppMotion.enterCurve),
    );
    _shortcutsSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.45, 1.0, curve: AppMotion.enterCurve),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handlePrimaryLidAction(
    BuildContext context,
    DeviceStatus status,
  ) async {
    final pending = ref.read(isCommandPendingProvider);
    if (pending || status.lidState == LidState.moving) return;

    if (status.mode == OperatingMode.maintenance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lid is locked in Maintenance Mode.'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final repo = ref.read(deviceRepositoryProvider);
    final isCurrentlyOpen = status.lidState == LidState.open;

    ref.read(isCommandPendingProvider.notifier).setPending(true);
    try {
      if (isCurrentlyOpen) {
        await repo.closeLid();
      } else {
        await repo.openLid();
      }

      if (context.mounted) {
        final currentLid = repo.getCurrentStatus().lidState;
        final targetLid = isCurrentlyOpen ? LidState.closed : LidState.open;
        final isConfirmed = currentLid == targetLid;

        final message = isConfirmed
            ? 'Lid is ${currentLid.displayName.toLowerCase()}.'
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
              onPressed: () => _handlePrimaryLidAction(context, status),
            ),
          ),
        );
      }
    } finally {
      ref.read(isCommandPendingProvider.notifier).setPending(false);
    }
  }

  void _openMonitoringScreen() {
    Navigator.of(context)
        .push(createPremiumPageRoute(const MonitoringScreen()));
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingScreenWithNav,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SkeletonLoader(width: double.infinity, height: 42),
          AppSpacing.gapH16,
          SkeletonLoader(width: double.infinity, height: 320),
          AppSpacing.gapH16,
          SkeletonLoader(width: double.infinity, height: 110),
          AppSpacing.gapH12,
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(width: double.infinity, height: 48),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: SkeletonLoader(width: double.infinity, height: 48),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(deviceStatusProvider);
    final isPending = ref.watch(isCommandPendingProvider);
    final alerts = ref.watch(alertsProvider).value ?? [];
    final hasActiveAlerts = alerts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.mintGreenContainer,
                borderRadius: AppRadii.borderRadiusSm,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.mintGreen,
                size: 20,
              ),
            ),
            AppSpacing.gapW8,
            const Text('EcoBin Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Alerts',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (hasActiveAlerts)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.mintGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: widget.onOpenAlerts,
          ),
        ],
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: _buildLoadingSkeleton,
          error: (_, _) => Center(
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapH16,
                  Text(
                    "Couldn't connect to EcoBin",
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Ensure the device is powered on and your phone is connected to the same Wi-Fi network.',
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
            final isMoving = status.lidState == LidState.moving || isPending;
            final isLidOpen = status.lidState == LidState.open;
            final isMaintenance = status.mode == OperatingMode.maintenance;

            final syncTime = status.lastSuccessfulCommunication != null
                ? _formatTime(status.lastSuccessfulCommunication!)
                : _formatTime(status.lastUpdated);

            return SingleChildScrollView(
              padding: AppSpacing.paddingScreenWithNav,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Item 1: Header & Connection Bar
                  SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slateSurface,
                              borderRadius: AppRadii.borderRadiusMd,
                              border: Border.all(
                                color: AppColors.slateOutlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                PulsingStatusDot(
                                  connectionStatus: status.connectionStatus,
                                ),
                                AppSpacing.gapW8,
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: AppMotion.duration(
                                      context,
                                      AppMotion.standard,
                                    ),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                    child: Text(
                                      status.connectionStatus ==
                                              DeviceConnectionStatus.online
                                          ? (status.deviceIp != null &&
                                                    status.deviceIp!.isNotEmpty
                                                ? 'Connected: ${status.deviceIp}'
                                                : 'Connected to EcoBin')
                                          : status.connectionStatus.displayName,
                                      key: ValueKey<DeviceConnectionStatus>(
                                        status.connectionStatus,
                                      ),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                AppSpacing.gapW8,
                                if (status.connectionStatus !=
                                    DeviceConnectionStatus.online)
                                  InkWell(
                                    onTap: () => ref
                                        .read(deviceRepositoryProvider)
                                        .refreshStatus(),
                                    borderRadius: AppRadii.borderRadiusSm,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.refresh_rounded,
                                            size: 13,
                                            color: AppColors.mintGreen,
                                          ),
                                          AppSpacing.gapW4,
                                          Text(
                                            'Retry',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: AppColors.mintGreen,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: AppColors.textTertiary,
                                      ),
                                      AppSpacing.gapW4,
                                      Text(
                                        syncTime,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Item 2: Central Hero Fill Gauge & Primary Lid Action Card
                  SlideTransition(
                    position: _gaugeSlide,
                    child: FadeTransition(
                      opacity: _gaugeFade,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.slateSurface,
                          borderRadius: AppRadii.borderRadiusLg,
                          border: Border.all(
                            color: AppColors.slateOutlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Top Row: Title & Mode Chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Current Fill Level',
                                  style: AppTextStyles.titleMedium,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateSurfaceVariant,
                                    borderRadius: AppRadii.borderRadiusFull,
                                    border: Border.all(
                                      color: AppColors.slateOutline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status.mode == OperatingMode.automatic
                                            ? Icons.auto_mode_rounded
                                            : status.mode ==
                                                  OperatingMode.manual
                                            ? Icons.touch_app_rounded
                                            : Icons.build_rounded,
                                        size: 12,
                                        color:
                                            status.mode ==
                                                OperatingMode.maintenance
                                            ? AppColors.warning
                                            : AppColors.mintGreen,
                                      ),
                                      AppSpacing.gapW4,
                                      Text(
                                        status.mode.displayName,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH24,

                            // Radial Fill Gauge with Hero Shared Transition to Monitoring Screen
                            GestureDetector(
                              onTap: _openMonitoringScreen,
                              behavior: HitTestBehavior.opaque,
                              child: Hero(
                                tag: 'ecobin_hero_fill_gauge',
                                child: Material(
                                  color: Colors.transparent,
                                  child: AnimatedFillGauge(
                                    fillPercentage: status.fillPercentage,
                                    size: 185,
                                  ),
                                ),
                              ),
                            ),
                            AppSpacing.gapH20,

                            // Status Summary: Lid State & Animated Count-Up Since Boot
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatusPill(
                                  icon: isMoving
                                      ? Icons.sync_rounded
                                      : isLidOpen
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_outline_rounded,
                                  label: 'Lid: ${status.lidState.displayName}',
                                  color: isMoving
                                      ? AppColors.info
                                      : isLidOpen
                                      ? AppColors.warning
                                      : AppColors.mintGreen,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateSurfaceVariant,
                                    borderRadius: AppRadii.borderRadiusFull,
                                    border: Border.all(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.repeat_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      AppSpacing.gapW4,
                                      CountUpText(
                                        prefix: 'Since boot: ',
                                        value: status.openingsSinceBoot,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH20,

                            // Primary Lid Action Button with PressableScale Feedback
                            PressableScale(
                              enabled: !isMoving && !isMaintenance,
                              onTap: isMoving || isMaintenance
                                  ? null
                                  : () => _handlePrimaryLidAction(
                                      context,
                                      status,
                                    ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: AnimatedSwitcher(
                                  duration: AppMotion.duration(
                                    context,
                                    AppMotion.standard,
                                  ),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  child: isMoving
                                      ? FilledButton.icon(
                                          key: const ValueKey('moving'),
                                          onPressed: null,
                                          icon: const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.onMintGreen,
                                            ),
                                          ),
                                          label: const Text('Moving Lid...'),
                                        )
                                      : isMaintenance
                                      ? OutlinedButton.icon(
                                          key: const ValueKey('maintenance'),
                                          onPressed: null,
                                          icon: const Icon(
                                            Icons.lock_rounded,
                                            size: 18,
                                            color: AppColors.warning,
                                          ),
                                          label: const Text(
                                            'Lid Locked (Maintenance)',
                                            style: TextStyle(
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        )
                                      : isLidOpen
                                      ? OutlinedButton.icon(
                                          key: const ValueKey('open'),
                                          onPressed: () =>
                                              _handlePrimaryLidAction(
                                                context,
                                                status,
                                              ),
                                          icon: const Icon(
                                            Icons.arrow_downward_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Close Lid'),
                                        )
                                      : FilledButton.icon(
                                          key: const ValueKey('closed'),
                                          onPressed: () =>
                                              _handlePrimaryLidAction(
                                                context,
                                                status,
                                              ),
                                          icon: const Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Open Lid'),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Item 3: Dual Ultrasonic Sensors Health Card
                  SlideTransition(
                    position: _sensorsSlide,
                    child: FadeTransition(
                      opacity: _sensorsFade,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.slateSurface,
                          borderRadius: AppRadii.borderRadiusLg,
                          border: Border.all(
                            color: AppColors.slateOutlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Dual Ultrasonic Sensors',
                                  style: AppTextStyles.titleSmall,
                                ),
                                TextButton(
                                  onPressed: _openMonitoringScreen,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    minimumSize: const Size(50, 30),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mintGreen,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: AppColors.mintGreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH8,
                            Row(
                              children: [
                                // Hand Sensor
                                Expanded(
                                  child: _SensorMiniCard(
                                    icon: Icons.front_hand_rounded,
                                    name: 'Hand Sensor',
                                    isOk: status.handSensorOk,
                                    reading: status.handSensorOk == false
                                        ? 'Hand sensor unavailable'
                                        : status.handDistanceCm != null
                                        ? '${status.handDistanceCm!.toStringAsFixed(1)} cm'
                                        : (status.handSensorOk == true
                                              ? 'Clear'
                                              : 'Unavailable'),
                                  ),
                                ),
                                AppSpacing.gapW12,
                                // Fill Sensor
                                Expanded(
                                  child: _SensorMiniCard(
                                    icon: Icons.straighten_rounded,
                                    name: 'Fill Sensor',
                                    isOk: status.fillSensorOk,
                                    reading: status.fillSensorOk == false
                                        ? 'Fill sensor unavailable'
                                        : status.fillPercentage != null
                                        ? '${status.fillPercentage!.toStringAsFixed(0)}%'
                                        : 'Unavailable',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH12,

                  // Item 4: Quick Navigation Shortcuts (Controls & Activity)
                  SlideTransition(
                    position: _shortcutsSlide,
                    child: FadeTransition(
                      opacity: _shortcutsFade,
                      child: Row(
                        children: [
                          Expanded(
                            child: _NavShortcutTile(
                              icon: Icons.tune_rounded,
                              title: 'Controls & Modes',
                              onTap: () => widget.onNavigateToTab(1),
                            ),
                          ),
                          AppSpacing.gapW12,
                          Expanded(
                            child: _NavShortcutTile(
                              icon: Icons.history_rounded,
                              title: 'Activity Log',
                              onTap: () => widget.onNavigateToTab(2),
                            ),
                          ),
                        ],
                      ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.slateSurfaceVariant,
        borderRadius: AppRadii.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          AppSpacing.gapW4,
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorMiniCard extends StatelessWidget {
  const _SensorMiniCard({
    required this.icon,
    required this.name,
    required this.isOk,
    required this.reading,
  });

  final IconData icon;
  final String name;
  final bool? isOk;
  final String reading;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOk == true
        ? AppColors.mintGreen
        : isOk == false
        ? AppColors.error
        : AppColors.textTertiary;

    final statusText = isOk == true
        ? 'HEALTHY'
        : isOk == false
        ? 'FAILURE'
        : 'UNREPORTED';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.slateSurfaceVariant,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.slateOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: statusColor),
              AppSpacing.gapW4,
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: AppRadii.borderRadiusXs,
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH4,
          Text(
            reading,
            style: AppTextStyles.bodySmall.copyWith(
              color: isOk == false ? AppColors.error : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NavShortcutTile extends StatelessWidget {
  const _NavShortcutTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.slateSurface,
          borderRadius: AppRadii.borderRadiusMd,
          border: Border.all(color: AppColors.slateOutlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mintGreen),
            AppSpacing.gapW8,
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
