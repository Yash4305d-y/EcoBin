enum AlertSeverity {
  info('Notice'),
  warning('Warning'),
  critical('Critical');

  const AlertSeverity(this.displayName);
  final String displayName;
}

/// Represents an in-app sample alert notification.
class AppAlert {
  const AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isDemo = true,
    this.isDismissed = false,
  });

  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isDemo;
  final bool isDismissed;

  AppAlert copyWith({bool? isDismissed}) {
    return AppAlert(
      id: id,
      title: title,
      message: message,
      severity: severity,
      timestamp: timestamp,
      isDemo: isDemo,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
