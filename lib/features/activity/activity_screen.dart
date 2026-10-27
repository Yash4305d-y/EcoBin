import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/demo_badge.dart';
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
    final isDemo = statusAsync.value?.isDemo ?? true;
    final todayCount = statusAsync.value?.openingsSinceBoot ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Bin Activity & History')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreenWithNav,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDemo)
                const DemoBanner(
                  message: 'Simulated Demo Events: Local SQLite database persistence will be integrated in a subsequent phase.',
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: AppSpacing.paddingCard,
                  decoration: BoxDecoration(
                    color: AppColors.slateSurfaceCard,
                    borderRadius: AppRadii.borderRadiusMd,
                    border: Border.all(color: AppColors.slateOutlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.mintGreen,
                        size: 20,
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: Text(
                          'Local Activity Persistence: Event history will be persisted in SQLite in a subsequent phase. Live opening count ($todayCount) is reported directly by the ESP32.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

              // Summary Stats Row
              Row(
                children: [
                  Expanded(
                    child: _SummaryBox(
                      title: 'Since Boot',
                      stat: '$todayCount Openings',
                      detail: isDemo
                          ? 'Peak: 1:15 PM – 2:00 PM'
                          : 'ESP32 hardware counter',
                      icon: Icons.repeat_rounded,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: _SummaryBox(
                      title: 'Weekly Total',
                      stat: isDemo ? '114 Openings' : 'N/A',
                      detail: isDemo
                          ? 'Avg: 16.2 / day'
                          : 'Requires SQLite persistence',
                      icon: Icons.date_range_rounded,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH24,

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Events Log',
                    style: AppTextStyles.titleMedium,
                  ),
                  if (isDemo)
                    const DemoBadge(text: 'MOCK HISTORY')
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreenContainer,
                        borderRadius: AppRadii.borderRadiusXs,
                      ),
                      child: Text(
                        'REAL EVENT STREAM',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onMintGreenContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
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
                      ),
                      child: Center(
                        child: Text(
                          isDemo ? 'No recent activity recorded.' : 'No events recorded during this session.\nActuate the bin lid via Controls to record live events.',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
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
              AppSpacing.gapH24,

              // Explicit Persistence Notice
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurfaceCard,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storage_rounded,
                      color: AppColors.info,
                      size: 22,
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'SQLite Persistence Scope',
                            style: AppTextStyles.titleSmall,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Events are currently held in-memory via MockDeviceRepository for UI preview. SQLite database integration will follow in a subsequent phase.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
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
