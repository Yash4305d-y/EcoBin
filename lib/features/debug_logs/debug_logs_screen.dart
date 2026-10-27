import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/models/debug_log_entry.dart';
import '../../data/providers/device_provider.dart';

class DebugLogsScreen extends ConsumerWidget {
  const DebugLogsScreen({super.key});

  String _formatLogTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Color _getSeverityColor(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.info:
        return AppColors.textSecondary;
      case LogSeverity.action:
        return AppColors.mintGreen;
      case LogSeverity.warning:
        return AppColors.warning;
      case LogSeverity.error:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(debugLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulated Debug Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear Logs',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              ref.read(deviceRepositoryProvider).clearDebugLogs();
              ref.invalidate(debugLogsProvider);
            },
          ),
          IconButton(
            tooltip: 'Refresh Logs',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(debugLogsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoBanner(
                message: 'Simulated Log Stream: Records app action dispatches and mock state transitions. No real HTTP wire requests are fabricated.',
              ),
              AppSpacing.gapH8,

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Recent Execution Trace',
                    style: AppTextStyles.titleMedium,
                  ),
                  DemoBadge(text: 'IN-MEMORY TRACE'),
                ],
              ),
              AppSpacing.gapH12,

              logsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.mintGreen),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (logs) {
                  if (logs.isEmpty) {
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
                            Icons.terminal_rounded,
                            size: 40,
                            color: AppColors.textTertiary,
                          ),
                          AppSpacing.gapH12,
                          Text(
                            'No Logs Present',
                            style: AppTextStyles.titleMedium,
                          ),
                          AppSpacing.gapH4,
                          Text(
                            'Execute a lid command in Controls to generate new log entries.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => AppSpacing.gapH8,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final color = _getSeverityColor(log.severity);

                      return Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.slateSurfaceCard,
                          borderRadius: AppRadii.borderRadiusMd,
                          border: Border.all(
                            color: AppColors.slateOutlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: AppRadii.borderRadiusXs,
                                  ),
                                  child: Text(
                                    log.severity.label,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                AppSpacing.gapW8,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateSurfaceVariant,
                                    borderRadius: AppRadii.borderRadiusXs,
                                  ),
                                  child: Text(
                                    log.source,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.mintGreen,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatLogTime(log.timestamp),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH8,
                            Text(
                              log.message,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
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
