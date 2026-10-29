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

/// Rolling median filter for ultrasonic dustbin fill-level measurements.
///
/// Implements a rolling window filter (default 5 samples) to eliminate ultrasonic
/// distance measurement spikes, echo jitters, and sensor noise while preserving authentic
/// level changes.
class RollingMedianFillFilter {
  RollingMedianFillFilter({
    this.windowSize = 5,
    this.calculator = const DustbinFillCalculator(),
  });

  /// Maximum number of recent valid distance readings maintained in memory.
  final int windowSize;

  /// Underlying physical depth calibration calculator.
  final DustbinFillCalculator calculator;

  final List<double> _history = [];

  /// Returns an unmodifiable list of valid distance readings currently in the window.
  List<double> get history => List.unmodifiable(_history);

  /// Number of valid samples currently buffered.
  int get sampleCount => _history.length;

  /// Returns the median distance from the valid readings history,
  /// or `null` if no valid readings are recorded.
  double? get medianDistance {
    if (_history.isEmpty) return null;
    final sorted = List<double>.from(_history)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }

  /// Ingests a new sensor distance reading.
  ///
  /// Requirements:
  /// - Ignores invalid, null, negative, NaN, or failed readings without treating them as zero or full.
  /// - If [fillSensorOk] is `false` or [distanceCm] is `null` or negative, returns `null`
  ///   (Unavailable state) and does not pollute the filter history.
  /// - If valid, stores the reading in the rolling buffer (max [windowSize] items),
  ///   calculates the median distance, and computes the clamped fill percentage (0.0–100.0%).
  double? addReading(double? distanceCm, {bool? fillSensorOk}) {
    if (fillSensorOk == false ||
        distanceCm == null ||
        distanceCm.isNaN ||
        distanceCm.isInfinite ||
        distanceCm < 0) {
      return null;
    }

    _history.add(distanceCm);
    if (_history.length > windowSize) {
      _history.removeAt(0);
    }

    final median = medianDistance;
    return calculator.calculate(median, fillSensorOk: true);
  }

  /// Resets the rolling filter history.
  void reset() {
    _history.clear();
  }
}
