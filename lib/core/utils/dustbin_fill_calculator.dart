import '../constants/app_constants.dart';

/// Calibrated dustbin fill-level calculation utility.
///
/// Implements the standard physical depth formula:
/// `fillPercentage = ((emptyDistance - currentDistance) / (emptyDistance - fullDistance)) * 100`
///
/// Where:
/// - [emptyDistanceCm] is the measured distance from sensor to bin bottom when empty.
/// - [currentDistanceCm] is the latest valid ultrasonic distance reading from the fill sensor.
/// - [fullDistanceCm] is the calibrated distance at the intended 100% full level.
class DustbinFillCalculator {
  const DustbinFillCalculator({
    this.emptyDistanceCm = AppConstants.defaultEmptyDistanceCm,
    this.fullDistanceCm = AppConstants.defaultFullDistanceCm,
  });

  /// Measured distance (cm) when the bin is empty.
  final double emptyDistanceCm;

  /// Calibrated distance (cm) at the intended full capacity line.
  final double fullDistanceCm;

  /// Calculates fill percentage clamped to 0.0 – 100.0%.
  ///
  /// Returns `null` if:
  /// - [currentDistanceCm] is `null` or negative
  /// - [fillSensorOk] is `false` (sensor hardware failure)
  /// - Calibration is invalid (e.g., division by zero or [emptyDistanceCm] <= [fullDistanceCm])
  double? calculate(double? currentDistanceCm, {bool? fillSensorOk}) {
    // Sensor failure or unavailable reading
    if (fillSensorOk == false || currentDistanceCm == null) {
      return null;
    }

    // Negative reading indicates sensor error / timeout echo glitch
    if (currentDistanceCm < 0) {
      return null;
    }

    final span = emptyDistanceCm - fullDistanceCm;
    // Guard against division by zero or invalid inverted calibration
    if (span <= 0) {
      return null;
    }

    final rawPercentage =
        ((emptyDistanceCm - currentDistanceCm) / span) * 100.0;

    // Clamp strictly to 0.0 – 100.0%
    return rawPercentage.clamp(0.0, 100.0);
  }
}
