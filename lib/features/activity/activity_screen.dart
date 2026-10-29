import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
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
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.repeat_rounded,
                                size: 15,
                                color: AppColors.mintGreen,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Since Boot',
                                style: AppTextStyles.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$todayCount Openings',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.history_rounded,
                                size: 15,
                                color: AppColors.mintGreen,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Current Session',
                                style: AppTextStyles.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${eventsList.length} Events',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                        horizontal: AppSpacing.lg,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 36,
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
                              'Events observed will appear here.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.slateOutlineVariant.withValues(
                          alpha: 0.35,
                        ),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final color = _getEventColor(event.type);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: AppRadii.borderRadiusSm,
                                ),
                                child: Icon(
                                  _getEventIcon(event.type),
                                  color: color,
                                  size: 16,
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
                                                fontSize: 10,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      event.description,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
