enum DeviceEventType {
  lidOpened('Lid Opened'),
  lidClosed('Lid Closed'),
  fillWarning('Fill Threshold Reached'),
  modeChanged('Operating Mode Changed'),
  maintenance('Maintenance Event');

  const DeviceEventType(this.displayName);
  final String displayName;
}

/// Represents an operational event in the bin history.
class DeviceEvent {
  const DeviceEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isDemo = true,
  });

  final String id;
  final DeviceEventType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isDemo;
}
