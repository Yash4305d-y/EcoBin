import 'package:ecobin/core/constants/app_constants.dart';
import 'package:ecobin/core/utils/dustbin_fill_calculator.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DustbinFillCalculator Unit Tests', () {
    const calculator = DustbinFillCalculator(
      emptyDistanceCm: 20.0,
      fullDistanceCm: 3.0,
    );

    test('Default calibration constants match user physical bin specs', () {
      expect(AppConstants.defaultEmptyDistanceCm, 20.0);
      expect(AppConstants.defaultFullDistanceCm, 3.0);
    });

    test(
      'Accurately calculates fill percentage using calibrated depth formula',
      () {
        // Empty bin: 20.0 cm -> ((20 - 20) / 17) * 100 = 0.0%
        expect(calculator.calculate(20.0), closeTo(0.0, 0.01));

        // Half full: 11.5 cm -> ((20 - 11.5) / 17) * 100 = 50.0%
        expect(calculator.calculate(11.5), closeTo(50.0, 0.01));

        // Full bin: 3.0 cm -> ((20 - 3) / 17) * 100 = 100.0%
        expect(calculator.calculate(3.0), closeTo(100.0, 0.01));

        // Quarter full: 15.75 cm -> ((20 - 15.75) / 17) * 100 = 25.0%
        expect(calculator.calculate(15.75), closeTo(25.0, 0.01));

        // Three quarters full: 7.25 cm -> ((20 - 7.25) / 17) * 100 = 75.0%
        expect(calculator.calculate(7.25), closeTo(75.0, 0.01));
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
        'fill_distance_cm': 11.5, // 8.5 cm of trash in 17cm span = 50.0%
      };

      final status = DeviceStatus.fromJson(json, deviceIp: '192.168.4.1');
      expect(status.fillPercentage, closeTo(50.0, 0.01));
      expect(status.fillDistanceCm, 11.5);
    });

    test('Calculates fill percentage from legacy distance_cm fallback when fill_percentage is null', () {
      final json = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_percentage': null,
        'sensor_ok': true,
        'distance_cm': 7.25, // ((20 - 7.25) / 17) * 100 = 75.0%
      };

      final status = DeviceStatus.fromJson(json, deviceIp: '192.168.4.1');
      expect(status.fillPercentage, closeTo(75.0, 0.01));
      expect(status.fillDistanceCm, 7.25);
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

    test('Integrates with persistent RollingMedianFillFilter to reduce sensor fluctuation', () {
      final filter = RollingMedianFillFilter(windowSize: 5);

      final json1 = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_sensor_ok': true,
        'fill_distance_cm': 11.5,
      };
      final status1 = DeviceStatus.fromJson(
        json1,
        deviceIp: '192.168.4.1',
        fillFilter: filter,
      );
      expect(status1.fillPercentage, closeTo(50.0, 0.01));
      expect(status1.fillDistanceCm, 11.5);

      // Reading with ultrasonic outlier echo spike: 25.0 cm
      final jsonSpike = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_sensor_ok': true,
        'fill_distance_cm': 25.0,
      };
      final status2 = DeviceStatus.fromJson(
        jsonSpike,
        deviceIp: '192.168.4.1',
        fillFilter: filter,
      );
      // History: [11.5, 25.0] -> median: 18.25 cm -> ((20 - 18.25)/17)*100 = 10.29%
      expect(status2.fillPercentage, closeTo(10.29, 0.01));

      // Third reading settles back to authentic level: 11.5 cm
      final json3 = {
        'lid_state': 'closed',
        'mode': 'automatic',
        'fill_sensor_ok': true,
        'fill_distance_cm': 11.5,
      };
      final status3 = DeviceStatus.fromJson(
        json3,
        deviceIp: '192.168.4.1',
        fillFilter: filter,
      );
      // History: [11.5, 25.0, 11.5] -> sorted [11.5, 11.5, 25.0] -> median: 11.5 cm!
      // Outlier 25.0 cm is completely rejected by median!
      expect(status3.fillPercentage, closeTo(50.0, 0.01));
      expect(status3.fillDistanceCm, 11.5);
    });
  });

  group('RollingMedianFillFilter Unit Tests', () {
    test(
      'Calculates rolling median across up to 5 valid distance readings',
      () {
        final filter = RollingMedianFillFilter(windowSize: 5);

        expect(filter.sampleCount, 0);
        expect(filter.medianDistance, isNull);

        // Sample 1: 11.5 cm -> Fill: ((20-11.5)/17)*100 = 50.0%
        expect(filter.addReading(11.5), closeTo(50.0, 0.01));
        expect(filter.medianDistance, 11.5);
        expect(filter.sampleCount, 1);

        // Sample 2: 11.7 cm -> sorted [11.5, 11.7] -> median: 11.6 cm -> ((20-11.6)/17)*100 = 49.41%
        expect(filter.addReading(11.7), closeTo(49.41, 0.01));
        expect(filter.medianDistance, 11.6);

        // Sample 3: Spike echo glitch 25.0 cm -> sorted [11.5, 11.7, 25.0] -> median: 11.7 cm -> ((20-11.7)/17)*100 = 48.82%
        expect(filter.addReading(25.0), closeTo(48.82, 0.01));
        expect(filter.medianDistance, 11.7);

        // Sample 4: 11.3 cm -> sorted [11.3, 11.5, 11.7, 25.0] -> median: (11.5+11.7)/2 = 11.6 cm -> 49.41%
        expect(filter.addReading(11.3), closeTo(49.41, 0.01));
        expect(filter.medianDistance, 11.6);

        // Sample 5: 11.5 cm -> sorted [11.3, 11.5, 11.5, 11.7, 25.0] -> median: 11.5 cm -> 50.0%
        expect(filter.addReading(11.5), closeTo(50.0, 0.01));
        expect(filter.medianDistance, 11.5);
        expect(filter.sampleCount, 5);

        // Sample 6: oldest (11.5) evicted, new 11.5 added
        // [11.7, 25.0, 11.3, 11.5, 11.5] -> sorted [11.3, 11.5, 11.5, 11.7, 25.0] -> median: 11.5 cm -> 50.0%
        expect(filter.addReading(11.5), closeTo(50.0, 0.01));
        expect(filter.medianDistance, 11.5);
        expect(filter.sampleCount, 5);
      },
    );

    test('Ignores invalid, negative, NaN, Infinite readings without polluting history', () {
      final filter = RollingMedianFillFilter(windowSize: 5);

      filter.addReading(10.0);
      expect(filter.sampleCount, 1);
      expect(filter.medianDistance, 10.0);

      // Invalid readings
      expect(filter.addReading(null), isNull);
      expect(filter.addReading(-5.0), isNull);
      expect(filter.addReading(double.nan), isNull);
      expect(filter.addReading(double.infinity), isNull);

      // Buffer remains unchanged
      expect(filter.sampleCount, 1);
      expect(filter.medianDistance, 10.0);
      expect(filter.history, [10.0]);
    });

    test(
      'Handles fillSensorOk: false as Unavailable without polluting history',
      () {
        final filter = RollingMedianFillFilter(windowSize: 5);

        filter.addReading(12.0);
        expect(filter.sampleCount, 1);

        // Hardware failure reported
        expect(filter.addReading(12.0, fillSensorOk: false), isNull);
        expect(filter.sampleCount, 1);
        expect(filter.history, [12.0]);
      },
    );

    test('Clamps output percentage to 0.0 - 100.0%', () {
      final filter = RollingMedianFillFilter(windowSize: 5);

      // Over-empty distance (e.g. 30 cm > 20 cm) -> clamped to 0.0%
      expect(filter.addReading(30.0), 0.0);

      // Over-full distance (e.g. 1.0 cm < 3.0 cm) -> clamped to 100.0%
      filter.reset();
      expect(filter.addReading(1.0), 100.0);
    });

    test('Reset clears buffer cleanly', () {
      final filter = RollingMedianFillFilter(windowSize: 5);
      filter.addReading(10.0);
      filter.addReading(12.0);
      expect(filter.sampleCount, 2);

      filter.reset();
      expect(filter.sampleCount, 0);
      expect(filter.medianDistance, isNull);
    });
  });
}
