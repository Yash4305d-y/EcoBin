import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/models/app_alert.dart';
import '../../data/providers/device_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Warnings, 2: System

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppColors.info;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.critical:
        return AppColors.error;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.critical:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);
    final statusAsync = ref.watch(deviceStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('In-App Alerts & Notices')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoBanner(
                message: 'Sample Alerts: Displayed for in-app UI testing only. Remote push notification dispatch is not active.',
              ),

              // Filter Chips
              Row(
                children: [
                  _FilterChip(
                    label: 'All Alerts',
                    selected: _selectedFilterIndex == 0,
                    onSelected: () => setState(() => _selectedFilterIndex = 0),
                  ),
                  AppSpacing.gapW8,
                  _FilterChip(
                    label: 'Warnings',
                    selected: _selectedFilterIndex == 1,
                    onSelected: () => setState(() => _selectedFilterIndex = 1),
                  ),
                  AppSpacing.gapW8,
                  _FilterChip(
                    label: 'Notices',
                    selected: _selectedFilterIndex == 2,
                    onSelected: () => setState(() => _selectedFilterIndex = 2),
                  ),
                ],
              ),
              AppSpacing.gapH16,

              // Dynamic Offline Sensor Alert Banner (if sensor is currently null)
              statusAsync.maybeWhen(
                data: (status) {
                  if (status.fillPercentage == null) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: AppSpacing.paddingCard,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.3),
                        borderRadius: AppRadii.borderRadiusMd,
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.sensors_off_rounded,
                            color: AppColors.error,
                          ),
                          AppSpacing.gapW12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sensor Telemetry Unavailable',
                                  style: AppTextStyles.titleSmall,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Ultrasonic probe returned null echo. Verify hardware connections in Settings.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // Alert Items List
              alertsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.mintGreen),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (alerts) {
                  final filtered = alerts.where((a) {
                    if (a.isDismissed) return false;
                    if (_selectedFilterIndex == 1) {
                      return a.severity == AlertSeverity.warning ||
                          a.severity == AlertSeverity.critical;
                    }
                    if (_selectedFilterIndex == 2) {
                      return a.severity == AlertSeverity.info;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxxl,
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slateSurface,
                        borderRadius: AppRadii.borderRadiusLg,
                        border: Border.all(
                          color: AppColors.slateOutlineVariant,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 48,
                            color: AppColors.mintGreen,
                          ),
                          AppSpacing.gapH12,
                          Text('All Clear!', style: AppTextStyles.titleMedium),
                          AppSpacing.gapH4,
                          Text(
                            'No active warnings or unresolved alerts.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => AppSpacing.gapH8,
                    itemBuilder: (context, index) {
                      final alert = filtered[index];
                      final color = _getSeverityColor(alert.severity);

                      return Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.slateSurface,
                          borderRadius: AppRadii.borderRadiusMd,
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: AppRadii.borderRadiusSm,
                              ),
                              child: Icon(
                                _getSeverityIcon(alert.severity),
                                color: color,
                                size: 20,
                              ),
                            ),
                            AppSpacing.gapW12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        alert.title,
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      const DemoBadge(text: 'SAMPLE'),
                                    ],
                                  ),
                                  AppSpacing.gapH4,
                                  Text(
                                    alert.message,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(deviceRepositoryProvider)
                                    .dismissAlert(alert.id);
                                ref.invalidate(alertsProvider);
                              },
                              tooltip: 'Dismiss alert',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              AppSpacing.gapH24,

              // Information card about push notifications
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurfaceCard,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Text(
                        'Push notifications (FCM / Background daemon) are out of scope for Phase 2. Alerts operate within the in-app telemetry lifecycle only.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: selected ? AppColors.onMintGreen : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.mintGreen,
      backgroundColor: AppColors.slateSurfaceVariant,
      side: const BorderSide(color: AppColors.slateOutlineVariant),
    );
  }
}
