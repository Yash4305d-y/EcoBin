enum LogSeverity {
  info('INFO'),
  action('ACTION'),
  warning('WARN'),
  error('ERROR');

  const LogSeverity(this.label);
  final String label;
}

/// A simulated runtime execution log entry.
class DebugLogEntry {
  const DebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.message,
    required this.severity,
    this.isDemo = true,
  });

  final String id;
  final DateTime timestamp;
  final String source;
  final String message;
  final LogSeverity severity;
  final bool isDemo;
}
