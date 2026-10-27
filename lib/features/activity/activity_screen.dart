import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/device_event.dart';
import '../../data/providers/device_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getEventIcon(DeviceEventType type) {
    switch (type) {
      case DeviceEventType.lidOpened:
        return Icons.arrow_upward_rounded;
      case DeviceEventType.lidClosed:
        return Icons.arrow_downward_rounded;
      case DeviceEventType.fillWarning:
        return Icons.warning_amber_rounded;
      case DeviceEventType.modeChanged:
        return Icons.tune_rounded;
      case DeviceEventType.maintenance:
        return Icons.build_rounded;
    }
  }

  Color _getEventColor(DeviceEventType type) {
    switch (type) {
      case DeviceEventType.lidOpened:
        return AppColors.mintGreen;
      case DeviceEventType.lidClosed:
        return AppColors.info;
      case DeviceEventType.fillWarning:
        return AppColors.warning;
      case DeviceEventType.modeChanged:
        return AppColors.textPrimary;
      case DeviceEventType.maintenance:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(deviceEventsProvider);
    final statusAsync = ref.watch(deviceStatusProvider);
    final todayCount = statusAsync.value?.openingsSinceBoot ?? 0;
    final eventsList = eventsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Bin Activity & History')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreenWithNav,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Stats Row
              Row(
                children: [
                  Expanded(
                    child: _SummaryBox(
                      title: 'Since Boot',
                      stat: '$todayCount Openings',
                      detail: 'Firmware opening counter',
                      icon: Icons.repeat_rounded,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: _SummaryBox(
                      title: 'Current Session',
                      stat: '${eventsList.length} Events',
                      detail: 'Observed while active',
                      icon: Icons.history_rounded,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH24,

              // Header
              const Text('Recent Events Log', style: AppTextStyles.titleMedium),
              AppSpacing.gapH12,

              eventsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.mintGreen),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (events) {
                  if (events.isEmpty) {
                    return Container(
                      padding: AppSpacing.paddingCard,
                      decoration: BoxDecoration(
                        color: AppColors.slateSurface,
                        borderRadius: AppRadii.borderRadiusLg,
                        border: Border.all(
                          color: AppColors.slateOutlineVariant,
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 40,
                                color: AppColors.textTertiary,
                              ),
                              AppSpacing.gapH12,
                              Text(
                                'No activity yet',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              AppSpacing.gapH4,
                              Text(
                                'Events observed while connected to EcoBin will appear here.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (context, index) => AppSpacing.gapH8,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final color = _getEventColor(event.type);

                      return Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.slateSurface,
                          borderRadius: AppRadii.borderRadiusMd,
                          border: Border.all(
                            color: AppColors.slateOutlineVariant,
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
                                _getEventIcon(event.type),
                                color: color,
                                size: 18,
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
                                        event.title,
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      Text(
                                        _formatRelativeTime(event.timestamp),
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapH4,
                                  Text(
                                    event.description,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.title,
    required this.stat,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String stat;
  final String detail;
  final IconData icon;

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
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.mintGreen),
              AppSpacing.gapW8,
              Text(title, style: AppTextStyles.labelSmall),
            ],
          ),
          AppSpacing.gapH8,
          Text(
            stat,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(detail, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
