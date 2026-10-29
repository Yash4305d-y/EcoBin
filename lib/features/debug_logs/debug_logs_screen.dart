import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
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
        title: const Text('Network & Diagnostic Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear Logs',
            icon: const Icon(Icons.delete_sweep_rounded, size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: AppColors.slateSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.borderRadiusLg,
                    side: const BorderSide(
                      color: AppColors.slateOutlineVariant,
                    ),
                  ),
                  title: Row(
                    children: const [
                      Icon(
                        Icons.delete_sweep_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      AppSpacing.gapW8,
                      Text(
                        'Clear Debug Logs?',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                  content: const Text(
                    'Clear all diagnostic trace entries recorded during this session?',
                    style: AppTextStyles.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                ref.read(deviceRepositoryProvider).clearDebugLogs();
                ref.invalidate(debugLogsProvider);
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh Logs',
            icon: const Icon(Icons.refresh_rounded, size: 20),
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
              logsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.mintGreen),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (logs) {
                  if (logs.isEmpty) {
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxxl,
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.terminal_rounded,
                            size: 36,
                            color: AppColors.textTertiary,
                          ),
                          AppSpacing.gapH12,
                          Text(
                            'No Logs Present',
                            style: AppTextStyles.titleMedium,
                          ),
                          AppSpacing.gapH4,
                          Text(
                            'Execute a lid command to view transaction logs.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
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
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.slateOutlineVariant.withValues(
                          alpha: 0.35,
                        ),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final color = _getSeverityColor(log.severity);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: AppRadii.borderRadiusXs,
                                    ),
                                    child: Text(
                                      log.severity.name.toUpperCase(),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 8,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapW8,
                                  Text(
                                    log.source,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.mintGreen,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatLogTime(log.timestamp),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textTertiary,
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapH4,
                              Text(
                                log.message,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
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
