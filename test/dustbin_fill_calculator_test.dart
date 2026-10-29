import 'package:ecobin/core/constants/app_constants.dart';
import 'package:ecobin/core/utils/dustbin_fill_calculator.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DustbinFillCalculator Unit Tests', () {
    const calculator = DustbinFillCalculator(
      emptyDistanceCm: 23.0,
      fullDistanceCm: 3.0,
    );

    test('Default calibration constants match user physical bin specs', () {
      expect(AppConstants.defaultEmptyDistanceCm, 23.0);
      expect(AppConstants.defaultFullDistanceCm, 3.0);
    });

    test(
      'Accurately calculates fill percentage using calibrated depth formula',
      () {
        // Empty bin: 23.0 cm -> ((23 - 23) / 20) * 100 = 0.0%
        expect(calculator.calculate(23.0), closeTo(0.0, 0.01));

        // Half full: 13.0 cm -> ((23 - 13) / 20) * 100 = 50.0%
        expect(calculator.calculate(13.0), closeTo(50.0, 0.01));

        // Full bin: 3.0 cm -> ((23 - 3) / 20) * 100 = 100.0%
        expect(calculator.calculate(3.0), closeTo(100.0, 0.01));

        // Quarter full: 18.0 cm -> ((23 - 18) / 20) * 100 = 25.0%
        expect(calculator.calculate(18.0), closeTo(25.0, 0.01));

        // Three quarters full: 8.0 cm -> ((23 - 8) / 20) * 100 = 75.0%
        expect(calculator.calculate(8.0), closeTo(75.0, 0.01));
      },
    );

    test('Clamps readings that exceed physical empty or full thresholds', () {
      // Over-empty (echo past bottom, e.g. 25 cm): clamped to 0.0%
      expect(calculator.calculate(25.0), 0.0);

      // Over-full (trash mounded above 3 cm, e.g. 1.5 cm): clamped to 100.0%
      expect(calculator.calculate(1.5), 100.0);

      // Trash right up to sensor face (0.0 cm): clamped to 100.0%
      expect(calculator.calculate(0.0), 100.0);
    });

    test(
      'Safely returns null (Unavailable) on invalid or faulty sensor readings',
      () {
        // Null reading
        expect(calculator.calculate(null), isNull);

        // Negative distance indicates ultrasonic timeout error
        expect(calculator.calculate(-1.0), isNull);
        expect(calculator.calculate(-99.0), isNull);

        // Explicit sensor error flag
        expect(calculator.calculate(10.0, fillSensorOk: false), isNull);
      },
    );

    test(
      'Protects against division by zero and inverted calibration values',
      () {
        // Zero span (emptyDistance == fullDistance)
        const zeroSpanCalc = DustbinFillCalculator(
          emptyDistanceCm: 20.0,
          fullDistanceCm: 20.0,
        );
        expect(zeroSpanCalc.calculate(10.0), isNull);

        // Inverted span (emptyDistance < fullDistance)
        const invertedCalc = DustbinFillCalculator(
          emptyDistanceCm: 5.0,
          fullDistanceCm: 20.0,
        );
        expect(invertedCalc.calculate(10.0), isNull);
      },
    );
  });

  group('DeviceStatus Fill Calculation Integration Tests', () {
    test('Calculates fill percentage from fill_distance_cm when fill_percentage is omitted', () {
      final json = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_sensor_ok': true,
        'fill_distance_cm': 13.0, // 10 cm of trash in 20cm span = 50.0%
      };

      final status = DeviceStatus.fromJson(json, deviceIp: '192.168.4.1');
      expect(status.fillPercentage, closeTo(50.0, 0.01));
      expect(status.fillDistanceCm, 13.0);
    });

    test('Calculates fill percentage from legacy distance_cm fallback when fill_percentage is null', () {
      final json = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_percentage': null,
        'sensor_ok': true,
        'distance_cm': 8.0, // ((23 - 8) / 20) * 100 = 75.0%
      };

      final status = DeviceStatus.fromJson(json, deviceIp: '192.168.4.1');
      expect(status.fillPercentage, closeTo(75.0, 0.01));
      expect(status.fillDistanceCm, 8.0);
    });

    test('Prioritizes pre-calculated ESP fill_percentage when provided as a valid number', () {
      final json = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_percentage': 82.5,
        'fill_distance_cm': 15.0,
      };

      final status = DeviceStatus.fromJson(json, deviceIp: '192.168.4.1');
      expect(status.fillPercentage, 82.5);
    });

    test('Does not confuse hand proximity sensor with fill level sensor', () {
      final json = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'hand_sensor_ok': true,
        'hand_distance_cm': 4.0, // Hand is very close
        'fill_percentage': null,
        'fill_sensor_ok': false, // Fill sensor is broken
        'fill_distance_cm': null,
      };

      final status = DeviceStatus.fromJson(json, deviceIp: '192.168.4.1');
      // Hand distance should be populated, but fill percentage MUST be null (Unavailable)
      expect(status.handDistanceCm, 4.0);
      expect(status.fillPercentage, isNull);
    });
  });
}
