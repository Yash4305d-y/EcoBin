import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_fill_gauge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pulsing_status_dot.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/device_connection_state.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/demo_mode_provider.dart';
import '../../data/providers/device_provider.dart';
import '../../navigation/app_nav_shell.dart';
import '../monitoring/monitoring_screen.dart';
import 'widgets/fill_demo_sheet.dart';

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
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.gentleCurve,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: AppMotion.enterCurve,
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
          AppSpacing.gapH24,
          Center(
            child: SkeletonLoader(
              width: 200,
              height: 200,
              borderRadius: AppRadii.borderRadiusFull,
            ),
          ),
          AppSpacing.gapH24,
          SkeletonLoader(width: double.infinity, height: 50),
          AppSpacing.gapH16,
          SkeletonLoader(width: double.infinity, height: 90),
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
    final isDemoActive = ref.watch(isFillDemoActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoBin Dashboard'),
        actions: [
          if (!kReleaseMode)
            IconButton(
              tooltip: 'Fill Level Demo Preview',
              icon: Icon(
                Icons.science_outlined,
                size: 20,
                color: isDemoActive
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
              onPressed: () => showFillDemoSheet(context),
            ),
          IconButton(
            tooltip: 'View Alerts',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 22),
                if (hasActiveAlerts)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 7,
                      height: 7,
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
          error: (err, _) => Center(
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
                    err.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Ensure the device is powered on and your phone is on the same Wi-Fi network.',
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

            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: AppSpacing.paddingScreenWithNav,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isDemoActive && !kReleaseMode) ...[
                        Center(
                          child: StatusChip(
                            label:
                                'Demo Fill: ${status.fillPercentage?.toInt() ?? 0}% (Tap to adjust)',
                            icon: Icons.science_outlined,
                            accentColor: AppColors.warning,
                            onTap: () => showFillDemoSheet(context),
                          ),
                        ),
                        AppSpacing.gapH16,
                      ],

                      // Status Bar: Connection status & Active Mode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Connection Status
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PulsingStatusDot(
                                connectionStatus: status.connectionStatus,
                              ),
                              AppSpacing.gapW8,
                              Text(
                                status.connectionStatus ==
                                        DeviceConnectionStatus.online
                                    ? (status.deviceIp != null &&
                                              status.deviceIp!.isNotEmpty
                                          ? status.deviceIp!
                                          : 'Online')
                                    : status.connectionStatus.displayName,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (status.connectionStatus ==
                                  DeviceConnectionStatus.online) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• $syncTime',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Operating Mode Chip
                          StatusChip(
                            label: status.mode == OperatingMode.automatic
                                ? 'Auto'
                                : status.mode == OperatingMode.manual
                                ? 'Manual'
                                : 'Maintenance',
                            icon: status.mode == OperatingMode.automatic
                                ? Icons.auto_mode_rounded
                                : status.mode == OperatingMode.manual
                                ? Icons.touch_app_rounded
                                : Icons.build_rounded,
                            accentColor: isMaintenance
                                ? AppColors.warning
                                : AppColors.mintGreen,
                            onTap: () => widget.onNavigateToTab(1),
                          ),
                        ],
                      ),
                      AppSpacing.gapH24,

                      // Central Hero Fill Gauge (Quiet background canvas, no enclosing box)
                      GestureDetector(
                        onTap: _openMonitoringScreen,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Hero(
                            tag: 'ecobin_hero_fill_gauge',
                            child: Material(
                              color: Colors.transparent,
                              child: AnimatedFillGauge(
                                fillPercentage: status.fillPercentage,
                                size: 195,
                                strokeWidth: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapH20,

                      // Lid State Pill indicator (Tapping navigates to Bin Controls)
                      Center(
                        child: StatusChip(
                          label: 'Lid: ${status.lidState.displayName}',
                          icon: isMoving
                              ? Icons.sync_rounded
                              : isLidOpen
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                          accentColor: isMoving
                              ? AppColors.info
                              : isLidOpen
                              ? AppColors.warning
                              : AppColors.mintGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          onTap: () => widget.onNavigateToTab(1),
                        ),
                      ),
                      AppSpacing.gapH24,

                      // Dual Ultrasonic Sensors Telemetry Card
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
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
                                      horizontal: AppSpacing.xs,
                                    ),
                                    minimumSize: const Size(40, 28),
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
                                  child: _SensorRowItem(
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
                                Container(
                                  width: 1,
                                  height: 36,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  color: AppColors.slateOutlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                                // Fill Sensor
                                Expanded(
                                  child: _SensorRowItem(
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SensorRowItem extends StatelessWidget {
  const _SensorRowItem({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: statusColor),
            const SizedBox(width: 5),
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
                color: statusColor.withValues(alpha: 0.15),
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
        const SizedBox(height: 3),
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
    );
  }
}
