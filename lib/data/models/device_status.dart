import '../../core/utils/dustbin_fill_calculator.dart';
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
    int? openingsSinceBoot,
    this.connectionStatus = DeviceConnectionStatus.connecting,
    this.lastSuccessfulCommunication,
    this.fillPercentage,
    this.deviceIp,
    this.batteryPercentage = 94,
    this.wifiSignalDbm = -58,
    this.handSensorOk,
    this.fillSensorOk,
    this.handDistanceCm,
    this.fillDistanceCm,
  }) : openingsSinceBoot = openingsSinceBoot ?? todayOpenings;

  /// Indicates if this status is simulated mock data.
  final bool isDemo;

  /// Current network / hardware connectivity state.
  final DeviceConnectionStatus connectionStatus;

  /// Timestamp of the last verified successful HTTP exchange with hardware.
  final DateTime? lastSuccessfulCommunication;

  /// Fill percentage between 0.0 and 100.0 from fill sensor, or null if offline/unavailable.
  final double? fillPercentage;

  final LidState lidState;
  final OperatingMode mode;

  /// Opening count since ESP32 startup.
  final int openingsSinceBoot;

  /// Legacy alias for [openingsSinceBoot] to preserve backward compatibility.
  final int todayOpenings;

  final DateTime lastUpdated;
  final String? deviceIp;
  final int? batteryPercentage;
  final int? wifiSignalDbm;

  /// Hand-detection proximity sensor health (true = OK, false = Error, null = Unreported).
  final bool? handSensorOk;

  /// Internal fill-level sensor health (true = OK, false = Error, null = Unreported).
  final bool? fillSensorOk;

  /// Distance reading from the hand sensor in cm (null if out of range or sensor offline).
  final double? handDistanceCm;

  /// Distance reading from the fill sensor in cm (null if sensor offline).
  final double? fillDistanceCm;

  /// Parses JSON response from `GET /api/status`.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  /// If `fill_percentage` is null or missing, [fillPercentage] is parsed as null.
  /// Supports both new dual sensor fields and legacy `sensor_ok` / `distance_cm`.
  factory DeviceStatus.fromJson(
    Map<String, dynamic> json, {
    required String deviceIp,
    DateTime? communicationTime,
    RollingMedianFillFilter? fillFilter,
  }) {
    final bool hasLid =
        json.containsKey('lid_state') ||
        json.containsKey('lid') ||
        json.containsKey('state') ||
        json.containsKey('lidState');
    final bool hasMode =
        json.containsKey('mode') ||
        json.containsKey('operating_mode') ||
        json.containsKey('operatingMode');

    if (!hasLid || !hasMode) {
      throw const FormatException('Missing required fields: lid_state or mode');
    }

    // Extract lid_state with resilient fallbacks
    final dynamic rawLid =
        json['lid_state'] ?? json['lid'] ?? json['state'] ?? json['lidState'];
    final LidState parsedLidState = rawLid != null
        ? LidState.fromString(rawLid.toString())
        : LidState.unknown;

    // Extract mode with resilient fallbacks
    final dynamic rawMode =
        json['mode'] ?? json['operating_mode'] ?? json['operatingMode'];
    final OperatingMode parsedMode = rawMode != null
        ? OperatingMode.fromString(rawMode.toString())
        : OperatingMode.automatic;

    // Opening count: check openings_since_boot first, fallback to today_openings
    final dynamic rawOpenings =
        json['openings_since_boot'] ?? json['today_openings'];
    final int openings = (rawOpenings is num) ? rawOpenings.toInt() : 0;

    // Hand sensor health (hand_sensor_ok)
    final bool? parsedHandSensorOk;
    if (json.containsKey('hand_sensor_ok')) {
      final dynamic rawHandOk = json['hand_sensor_ok'];
      parsedHandSensorOk = rawHandOk is bool ? rawHandOk : null;
    } else {
      parsedHandSensorOk = null;
    }

    // Fill sensor health (fill_sensor_ok with fallback to legacy sensor_ok)
    final bool? parsedFillSensorOk;
    if (json.containsKey('fill_sensor_ok')) {
      final dynamic rawFillOk = json['fill_sensor_ok'];
      parsedFillSensorOk = rawFillOk is bool ? rawFillOk : null;
    } else if (json.containsKey('sensor_ok')) {
      final dynamic rawLegacyOk = json['sensor_ok'];
      parsedFillSensorOk = rawLegacyOk is bool ? rawLegacyOk : null;
    } else {
      parsedFillSensorOk = null;
    }

    // Hand distance (hand_distance_cm)
    final double? parsedHandDistance;
    final dynamic rawHandDist = json['hand_distance_cm'];
    if (rawHandDist is num) {
      parsedHandDistance = rawHandDist.toDouble();
    } else {
      parsedHandDistance = null;
    }

    // Fill distance (fill_distance_cm with fallback to legacy distance_cm)
    double? parsedFillDistance;
    final dynamic rawFillDist = json['fill_distance_cm'] ?? json['distance_cm'];
    if (rawFillDist is num) {
      parsedFillDistance = rawFillDist.toDouble();
    } else {
      parsedFillDistance = null;
    }

    // Fill percentage: Use ESP-provided percentage if present, otherwise calculate from calibrated fill sensor depth
    final double? parsedFill;
    final dynamic rawFill = json['fill_percentage'];
    if (rawFill is num) {
      parsedFill = rawFill.toDouble().clamp(0.0, 100.0);
    } else if (fillFilter != null) {
      parsedFill = fillFilter.addReading(
        parsedFillDistance,
        fillSensorOk: parsedFillSensorOk,
      );
      if (parsedFillSensorOk != false &&
          parsedFill != null &&
          fillFilter.medianDistance != null) {
        parsedFillDistance = double.parse(
          fillFilter.medianDistance!.toStringAsFixed(1),
        );
      }
    } else if (parsedFillDistance != null && parsedFillSensorOk != false) {
      parsedFill = const DustbinFillCalculator().calculate(
        parsedFillDistance,
        fillSensorOk: parsedFillSensorOk,
      );
    } else {
      parsedFill = null;
    }

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
      lidState: parsedLidState,
      mode: parsedMode,
      todayOpenings: openings,
      openingsSinceBoot: openings,
      batteryPercentage: battery,
      wifiSignalDbm: signal,
      handSensorOk: parsedHandSensorOk,
      fillSensorOk: parsedFillSensorOk,
      handDistanceCm: parsedHandDistance,
      fillDistanceCm: parsedFillDistance,
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
    int? openingsSinceBoot,
    DateTime? lastUpdated,
    String? deviceIp,
    int? batteryPercentage,
    int? wifiSignalDbm,
    bool? Function()? handSensorOk,
    bool? Function()? fillSensorOk,
    double? Function()? handDistanceCm,
    double? Function()? fillDistanceCm,
  }) {
    final effectiveOpenings =
        openingsSinceBoot ?? todayOpenings ?? this.openingsSinceBoot;
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
      todayOpenings: effectiveOpenings,
      openingsSinceBoot: effectiveOpenings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deviceIp: deviceIp ?? this.deviceIp,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      wifiSignalDbm: wifiSignalDbm ?? this.wifiSignalDbm,
      handSensorOk: handSensorOk != null ? handSensorOk() : this.handSensorOk,
      fillSensorOk: fillSensorOk != null ? fillSensorOk() : this.fillSensorOk,
      handDistanceCm: handDistanceCm != null
          ? handDistanceCm()
          : this.handDistanceCm,
      fillDistanceCm: fillDistanceCm != null
          ? fillDistanceCm()
          : this.fillDistanceCm,
    );
  }
}
