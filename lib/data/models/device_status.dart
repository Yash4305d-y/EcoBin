import 'device_connection_state.dart';

/// Operating state of the bin's lid.
enum LidState {
  closed('Closed'),
  open('Open'),
  moving('Moving...'),
  unknown('Unknown');

  const LidState(this.displayName);
  final String displayName;

  static LidState fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'open':
        return LidState.open;
      case 'closed':
        return LidState.closed;
      case 'moving':
        return LidState.moving;
      default:
        return LidState.unknown;
    }
  }
}

/// Operating mode for the EcoBin hardware.
enum OperatingMode {
  automatic('Automatic (Ultrasonic Trigger)'),
  manual('Manual (App / Button Only)'),
  maintenance('Maintenance Mode (Lid Locked)');

  const OperatingMode(this.displayName);
  final String displayName;

  static OperatingMode fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'manual':
        return OperatingMode.manual;
      case 'maintenance':
        return OperatingMode.maintenance;
      case 'automatic':
      default:
        return OperatingMode.automatic;
    }
  }
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
    this.connectionStatus = DeviceConnectionStatus.demoMode,
    this.lastSuccessfulCommunication,
    this.fillPercentage,
    this.deviceIp,
    this.batteryPercentage = 94,
    this.wifiSignalDbm = -58,
  });

  /// Indicates if this status is simulated mock data.
  final bool isDemo;

  /// Current network / hardware connectivity state.
  final DeviceConnectionStatus connectionStatus;

  /// Timestamp of the last verified successful HTTP exchange with hardware.
  final DateTime? lastSuccessfulCommunication;

  /// Fill percentage between 0.0 and 100.0, or null if the ultrasonic/IR sensor is offline/unavailable.
  final double? fillPercentage;

  final LidState lidState;
  final OperatingMode mode;
  final int todayOpenings;
  final DateTime lastUpdated;
  final String? deviceIp;
  final int? batteryPercentage;
  final int? wifiSignalDbm;

  /// Parses JSON response from `GET /api/status`.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  /// If `fill_percentage` is null or missing, [fillPercentage] is parsed as null.
  factory DeviceStatus.fromJson(
    Map<String, dynamic> json, {
    required String deviceIp,
    DateTime? communicationTime,
  }) {
    if (!json.containsKey('lid_state') || !json.containsKey('mode')) {
      throw const FormatException('Missing required fields: lid_state or mode');
    }

    final double? parsedFill;
    final dynamic rawFill = json['fill_percentage'];
    if (rawFill == null) {
      parsedFill = null;
    } else if (rawFill is num) {
      parsedFill = rawFill.toDouble().clamp(0.0, 100.0);
    } else {
      parsedFill = null;
    }

    final dynamic rawOpenings = json['today_openings'];
    final int openings = (rawOpenings is num) ? rawOpenings.toInt() : 0;

    final dynamic rawBattery = json['battery_percentage'];
    final int? battery = (rawBattery is num) ? rawBattery.toInt() : null;

    final dynamic rawSignal = json['wifi_signal_dbm'];
    final int? signal = (rawSignal is num) ? rawSignal.toInt() : null;

    final now = communicationTime ?? DateTime.now();

    return DeviceStatus(
      isDemo: false,
      connectionStatus: DeviceConnectionStatus.online,
      lastSuccessfulCommunication: now,
      deviceIp: deviceIp,
      fillPercentage: parsedFill,
      lidState: LidState.fromString(json['lid_state']?.toString()),
      mode: OperatingMode.fromString(json['mode']?.toString()),
      todayOpenings: openings,
      batteryPercentage: battery,
      wifiSignalDbm: signal,
      lastUpdated: now,
    );
  }

  DeviceStatus copyWith({
    bool? isDemo,
    DeviceConnectionStatus? connectionStatus,
    DateTime? lastSuccessfulCommunication,
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
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastSuccessfulCommunication:
          lastSuccessfulCommunication ?? this.lastSuccessfulCommunication,
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
