/// Operating state of the bin's lid.
enum LidState {
  closed('Closed'),
  open('Open'),
  moving('Moving...'),
  unknown('Unknown');

  const LidState(this.displayName);
  final String displayName;
}

/// Operating mode for the EcoBin hardware.
enum OperatingMode {
  automatic('Automatic (Ultrasonic Trigger)'),
  manual('Manual (App / Button Only)'),
  maintenance('Maintenance Mode (Lid Locked)');

  const OperatingMode(this.displayName);
  final String displayName;
}

/// Snapshot of the EcoBin device state.
///
/// If [fillPercentage] is null, sensor reading is considered unavailable
/// and must never be defaulted to 0%.
class DeviceStatus {
  const DeviceStatus({
    required this.isDemo,
    required this.lidState,
    required this.mode,
    required this.todayOpenings,
    required this.lastUpdated,
    this.fillPercentage,
    this.deviceIp,
    this.batteryPercentage = 94,
    this.wifiSignalDbm = -58,
  });

  /// Indicates if this status is simulated mock data.
  final bool isDemo;

  /// Fill percentage between 0.0 and 100.0, or null if the ultrasonic/IR sensor is offline/unavailable.
  final double? fillPercentage;

  final LidState lidState;
  final OperatingMode mode;
  final int todayOpenings;
  final DateTime lastUpdated;
  final String? deviceIp;
  final int? batteryPercentage;
  final int? wifiSignalDbm;

  DeviceStatus copyWith({
    bool? isDemo,
    double? Function()? fillPercentage,
    LidState? lidState,
    OperatingMode? mode,
    int? todayOpenings,
    DateTime? lastUpdated,
    String? deviceIp,
    int? batteryPercentage,
    int? wifiSignalDbm,
  }) {
    return DeviceStatus(
      isDemo: isDemo ?? this.isDemo,
      fillPercentage: fillPercentage != null
          ? fillPercentage()
          : this.fillPercentage,
      lidState: lidState ?? this.lidState,
      mode: mode ?? this.mode,
      todayOpenings: todayOpenings ?? this.todayOpenings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deviceIp: deviceIp ?? this.deviceIp,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      wifiSignalDbm: wifiSignalDbm ?? this.wifiSignalDbm,
    );
  }
}
