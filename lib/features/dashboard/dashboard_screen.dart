import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_fill_gauge.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/models/device_connection_state.dart';
import '../../data/models/device_status.dart';
import '../../data/providers/device_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenAlerts,
  });

  /// Allows jumping directly to primary bottom nav tabs (0: Dashboard, 1: Controls, 2: Monitoring, 3: Activity, 4: Settings)
  final void Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenAlerts;

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(deviceStatusProvider);

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
            tooltip: 'View Sample Alerts',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onOpenAlerts,
          ),
        ],
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.mintGreen),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Text(
                'Error loading telemetry: $err',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (status) {
            return SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prominent Demo Mode Banner
                  if (status.isDemo) const DemoBanner(),

                  // Connection & Mode Header Card
                  Container(
                    padding: AppSpacing.paddingCard,
                    decoration: BoxDecoration(
                      color: AppColors.slateSurface,
                      borderRadius: AppRadii.borderRadiusLg,
                      border: Border.all(color: AppColors.slateOutlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status.isDemo
                                ? AppColors.warning
                                : status.connectionStatus ==
                                      DeviceConnectionStatus.online
                                ? AppColors.mintGreen
                                : status.connectionStatus ==
                                      DeviceConnectionStatus.connecting
                                ? AppColors.info
                                : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.isDemo
                                    ? 'Demo Environment (Simulated)'
                                    : '${status.connectionStatus.displayName}: http://${status.deviceIp ?? "ESP32"}',
                                style: AppTextStyles.titleSmall,
                              ),
                              Text(
                                'Mode: ${status.mode.displayName}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (status.isDemo)
                          const DemoBadge()
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  status.connectionStatus ==
                                      DeviceConnectionStatus.online
                                  ? AppColors.mintGreenContainer
                                  : AppColors.errorContainer,
                              borderRadius: AppRadii.borderRadiusXs,
                            ),
                            child: Text(
                              status.connectionStatus.displayName.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color:
                                    status.connectionStatus ==
                                        DeviceConnectionStatus.online
                                    ? AppColors.onMintGreenContainer
                                    : AppColors.onErrorContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Central Gauge Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Fill Level',
                                style: AppTextStyles.titleMedium,
                              ),
                              if (status.isDemo)
                                const DemoBadge(text: 'SIMULATED SENSOR'),
                            ],
                          ),
                          AppSpacing.gapH24,
                          AnimatedFillGauge(
                            fillPercentage: status.fillPercentage,
                            isDemo: status.isDemo,
                            size: 190,
                          ),
                          AppSpacing.gapH20,

                          // Status Pills (Lid & Mode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatusChip(
                                icon: status.lidState == LidState.open
                                    ? Icons.lock_open_rounded
                                    : status.lidState == LidState.moving
                                    ? Icons.sync_rounded
                                    : Icons.lock_outline_rounded,
                                label: 'Lid: ${status.lidState.displayName}',
                                color: status.lidState == LidState.open
                                    ? AppColors.warning
                                    : AppColors.mintGreen,
                              ),
                              _StatusChip(
                                icon: Icons.tune_rounded,
                                label: status.mode == OperatingMode.automatic
                                    ? 'Auto Mode'
                                    : status.mode == OperatingMode.manual
                                    ? 'Manual Mode'
                                    : 'Maintenance',
                                color: AppColors.info,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Telemetry Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.repeat_rounded,
                          label: "Today's Openings",
                          value: '${status.todayOpenings}',
                          subtitle: 'Simulated counter',
                        ),
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: _StatCard(
                          icon: Icons.access_time_rounded,
                          label: 'Last Telemetry',
                          value: _formatTime(status.lastUpdated),
                          subtitle: 'Simulated ping',
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH24,

                  // Quick Action Links
                  const Text(
                    'Quick Navigation',
                    style: AppTextStyles.titleMedium,
                  ),
                  AppSpacing.gapH12,

                  _QuickNavCard(
                    icon: Icons.power_settings_new_rounded,
                    title: 'Lid Controls & Actuation',
                    subtitle: 'Trigger lid opening, closing, or toggle mode',
                    onTap: () => onNavigateToTab(1), // Controls tab
                  ),
                  AppSpacing.gapH8,

                  _QuickNavCard(
                    icon: Icons.analytics_outlined,
                    title: 'Detailed Sensor Monitoring',
                    subtitle: 'Inspect capacity thresholds and offline states',
                    onTap: () => onNavigateToTab(2), // Monitoring tab
                  ),
                  AppSpacing.gapH8,

                  _QuickNavCard(
                    icon: Icons.history_rounded,
                    title: 'Activity & Opening History',
                    subtitle: 'View recent demo logs and daily summary',
                    onTap: () => onNavigateToTab(3), // Activity tab
                  ),
                  AppSpacing.gapH8,

                  _QuickNavCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'System Alerts & Diagnostics',
                    subtitle: 'Check warning thresholds and notices',
                    onTap: onOpenAlerts,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.slateSurface,
        borderRadius: AppRadii.borderRadiusLg,
        border: Border.all(color: AppColors.slateOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mintGreen, size: 20),
          AppSpacing.gapH8,
          Text(label, style: AppTextStyles.bodySmall),
          AppSpacing.gapH4,
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderRadiusMd,
      child: Container(
        padding: AppSpacing.paddingCard,
        decoration: BoxDecoration(
          color: AppColors.slateSurface,
          borderRadius: AppRadii.borderRadiusMd,
          border: Border.all(color: AppColors.slateOutlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.slateSurfaceVariant,
                borderRadius: AppRadii.borderRadiusSm,
              ),
              child: Icon(icon, color: AppColors.mintGreen, size: 20),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  AppSpacing.gapH2,
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
