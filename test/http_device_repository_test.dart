import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecobin/core/errors/device_exceptions.dart';
import 'package:ecobin/data/models/device_connection_state.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:ecobin/data/providers/device_provider.dart';
import 'package:ecobin/data/providers/settings_provider.dart';
import 'package:ecobin/data/repositories/http_device_repository.dart';
import 'package:ecobin/data/repositories/mock_device_repository.dart';
import 'package:ecobin/data/services/device_api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeviceApiService Tests', () {
    test('Successful health and status responses parse correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response(
            jsonEncode({
              'status': 'ok',
              'device': 'ecobin-esp32',
              'firmware': '1.0.0',
              'uptime_seconds': 1200,
            }),
            200,
          );
        } else if (request.url.path == '/api/status') {
          return http.Response(
            jsonEncode({
              'fill_percentage': 55.4,
              'lid_state': 'closed',
              'mode': 'automatic',
              'today_openings': 12,
              'battery_percentage': 88,
              'wifi_signal_dbm': -60,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = DeviceApiService(client: mockClient);

      final health = await service.checkHealth('192.168.4.1');
      expect(health['status'], 'ok');
      expect(health['firmware'], '1.0.0');

      final status = await service.getStatus('192.168.4.1');
      expect(status.fillPercentage, 55.4);
      expect(status.lidState, LidState.closed);
      expect(status.mode, OperatingMode.automatic);
      expect(status.todayOpenings, 12);
      expect(status.connectionStatus, DeviceConnectionStatus.online);
    });

    test(
      'Valid status parsing with explicit null fill level (never 0%)',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'fill_percentage': null,
              'lid_state': 'open',
              'mode': 'manual',
              'today_openings': 4,
            }),
            200,
          );
        });

        final service = DeviceApiService(client: mockClient);
        final status = await service.getStatus('192.168.4.1');

        expect(status.fillPercentage, isNull);
        expect(status.lidState, LidState.open);
        expect(status.mode, OperatingMode.manual);
      },
    );

    test('Dual ultrasonic sensors parsing: hand & fill sensors, distances, and openings_since_boot', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'lid_state': 'closed',
            'mode': 'automatic',
            'openings_since_boot': 22,
            'hand_sensor_ok': true,
            'fill_sensor_ok': true,
            'hand_distance_cm': 14.5,
            'fill_distance_cm': 32.1,
            'fill_percentage': 45.0,
          }),
          200,
        );
      });

      final service = DeviceApiService(client: mockClient);
      final status = await service.getStatus('192.168.4.1');

      expect(status.handSensorOk, isTrue);
      expect(status.fillSensorOk, isTrue);
      expect(status.handDistanceCm, 14.5);
      expect(status.fillDistanceCm, 32.1);
      expect(status.fillPercentage, 45.0);
      expect(status.openingsSinceBoot, 22);
      expect(status.todayOpenings, 22);
    });

    test('Hand sensor failure parsing maintains fill sensor data and null hand distance', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'lid_state': 'closed',
            'mode': 'automatic',
            'openings_since_boot': 8,
            'hand_sensor_ok': false,
            'fill_sensor_ok': true,
            'hand_distance_cm': null,
            'fill_distance_cm': 18.0,
            'fill_percentage': 72.0,
          }),
          200,
        );
      });

      final service = DeviceApiService(client: mockClient);
      final status = await service.getStatus('192.168.4.1');

      expect(status.handSensorOk, isFalse);
      expect(status.fillSensorOk, isTrue);
      expect(status.handDistanceCm, isNull);
      expect(status.fillDistanceCm, 18.0);
      expect(status.fillPercentage, 72.0);
    });

    test('Backward compatibility: fallback to legacy sensor_ok, distance_cm, and today_openings', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'lid_state': 'closed',
            'mode': 'automatic',
            'today_openings': 15,
            'sensor_ok': true,
            'distance_cm': 28.5,
            'fill_percentage': 60.0,
          }),
          200,
        );
      });

      final service = DeviceApiService(client: mockClient);
      final status = await service.getStatus('192.168.4.1');

      // Backward compatibility fallbacks
      expect(status.fillSensorOk, isTrue);
      expect(status.fillDistanceCm, 28.5);
      expect(status.openingsSinceBoot, 15);
      expect(status.todayOpenings, 15);

      // Fields not present in legacy firmware remain null
      expect(status.handSensorOk, isNull);
      expect(status.handDistanceCm, isNull);
    });

    test(
      'Invalid JSON and missing required fields throw DeviceDataException',
      () async {
        final malformedClient = MockClient((request) async {
          return http.Response('{not valid json', 200);
        });
        final service1 = DeviceApiService(client: malformedClient);
        expect(
          () => service1.getStatus('192.168.4.1'),
          throwsA(isA<DeviceDataException>()),
        );

        final missingFieldsClient = MockClient((request) async {
          return http.Response(jsonEncode({'fill_percentage': 50.0}), 200);
        });
        final service2 = DeviceApiService(client: missingFieldsClient);
        expect(
          () => service2.getStatus('192.168.4.1'),
          throwsA(isA<DeviceDataException>()),
        );
      },
    );

    test(
      'Connection socket failure throws DeviceConnectionException',
      () async {
        final failingClient = MockClient((request) async {
          throw const SocketException('Connection refused');
        });

        final service = DeviceApiService(client: failingClient);
        expect(
          () => service.getStatus('192.168.4.1'),
          throwsA(isA<DeviceConnectionException>()),
        );
      },
    );

    test(
      'Command rejection returns DeviceApiException with status code',
      () async {
        final conflictClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'error': 'Lid locked'}),
            409,
          );
        });

        final service = DeviceApiService(client: conflictClient);
        expect(
          () => service.openLid('192.168.4.1'),
          throwsA(
            isA<DeviceApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              409,
            ),
          ),
        );
      },
    );
  });

  group('HttpDeviceRepository Polling & Connection States', () {
    test('Transitions to offline ONLY after 3 consecutive failures and recovers on success', () async {
      bool failRequests = false;

      final mockClient = MockClient((request) async {
        if (failRequests) {
          throw const SocketException('No route to host');
        }
        return http.Response(
          jsonEncode({
            'fill_percentage': 42.0,
            'lid_state': 'closed',
            'mode': 'automatic',
            'today_openings': 8,
          }),
          200,
        );
      });

      final service = DeviceApiService(client: mockClient);
      final repo = HttpDeviceRepository(
        apiService: service,
        deviceIp: '192.168.4.1',
        autoStartPolling: false,
      );

      // 1. Initial success poll -> Online
      await repo.pollStatus();
      expect(
        repo.getCurrentStatus().connectionStatus,
        DeviceConnectionStatus.online,
      );
      expect(repo.getCurrentStatus().lastSuccessfulCommunication, isNotNull);

      // Now enable failures
      failRequests = true;

      // 2. Failure 1: Still online (has not hit 3 consecutive failures)
      await repo.pollStatus();
      expect(
        repo.getCurrentStatus().connectionStatus,
        DeviceConnectionStatus.online,
      );

      // 3. Failure 2: Still online
      await repo.pollStatus();
      expect(
        repo.getCurrentStatus().connectionStatus,
        DeviceConnectionStatus.online,
      );

      // 4. Failure 3: Transitions to offline!
      await repo.pollStatus();
      expect(
        repo.getCurrentStatus().connectionStatus,
        DeviceConnectionStatus.offline,
      );

      // 5. Recovery: Next successful poll recovers to online immediately
      failRequests = false;
      await repo.pollStatus();
      expect(
        repo.getCurrentStatus().connectionStatus,
        DeviceConnectionStatus.online,
      );

      repo.dispose();
    });

    test('Prevents overlapping status polls', () async {
      int activeRequests = 0;
      int maxConcurrentRequests = 0;

      final mockClient = MockClient((request) async {
        activeRequests++;
        if (activeRequests > maxConcurrentRequests) {
          maxConcurrentRequests = activeRequests;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        activeRequests--;
        return http.Response(
          jsonEncode({
            'fill_percentage': 70.0,
            'lid_state': 'closed',
            'mode': 'automatic',
            'today_openings': 5,
          }),
          200,
        );
      });

      final service = DeviceApiService(client: mockClient);
      final repo = HttpDeviceRepository(
        apiService: service,
        deviceIp: '192.168.4.1',
        autoStartPolling: false,
      );

      // Fire multiple polls simultaneously
      final future1 = repo.pollStatus();
      final future2 = repo.pollStatus();
      final future3 = repo.pollStatus();

      await Future.wait([future1, future2, future3]);

      // Verify that concurrent in-flight requests never exceeded 1
      expect(maxConcurrentRequests, 1);

      repo.dispose();
    });
  });

  group('Provider Selection & Direct HTTP Connection Tests', () {
    test('deviceRepositoryProvider connects directly to HttpDeviceRepository with configured IP', () async {
      final container = ProviderContainer(
        overrides: [
          deviceApiServiceProvider.overrideWithValue(
            DeviceApiService(
              client: MockClient((request) async {
                return http.Response(
                  jsonEncode({
                    'fill_percentage': 15.0,
                    'lid_state': 'closed',
                    'mode': 'automatic',
                    'today_openings': 1,
                  }),
                  200,
                );
              }),
            ),
          ),
        ],
      );

      // App defaults to real mode (Demo Mode removed)
      final initialSettings = container.read(settingsProvider);
      expect(initialSettings.isDemoMode, isFalse);

      final initialRepo = container.read(deviceRepositoryProvider);
      expect(initialRepo, isA<HttpDeviceRepository>());
      expect(initialRepo.getCurrentStatus().isDemo, isFalse);

      // Updating IP updates repository target
      await container
          .read(settingsProvider.notifier)
          .updateDeviceIp('192.168.1.100');

      final updatedRepo = container.read(deviceRepositoryProvider);
      expect(updatedRepo, isA<HttpDeviceRepository>());
      expect(container.read(settingsProvider).deviceIp, '192.168.1.100');

      container.dispose();
    });
  });

  group('HttpDeviceRepository Actuation & Fill Filtering Tests', () {
    test(
      'closeLid issues POST /api/lid/close and transitions state cleanly',
      () async {
        String? executedPath;
        String? executedMethod;

        final mockClient = MockClient((request) async {
          executedPath = request.url.path;
          executedMethod = request.method;

          if (request.url.path == '/api/lid/close') {
            return http.Response(
              jsonEncode({'status': 'accepted', 'lid_state': 'closed'}),
              200,
            );
          } else if (request.url.path == '/api/status') {
            return http.Response(
              jsonEncode({
                'lid_state': 'closed',
                'mode': 'manual',
                'fill_sensor_ok': true,
                'fill_distance_cm': 13.0,
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final service = DeviceApiService(client: mockClient);
        final repo = HttpDeviceRepository(
          apiService: service,
          deviceIp: '192.168.4.1',
          autoStartPolling: false,
        );

        await repo.closeLid();

        expect(executedPath, '/api/status'); // Polled after close
        expect(executedMethod, 'GET');
        expect(repo.getCurrentStatus().lidState, LidState.closed);

        repo.dispose();
      },
    );

    test('HttpDeviceRepository smooths fluctuating fill sensor readings using rolling median', () async {
      double simulatedDistance = 13.0;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/status') {
          return http.Response(
            jsonEncode({
              'lid_state': 'closed',
              'mode': 'automatic',
              'fill_sensor_ok': true,
              'fill_distance_cm': simulatedDistance,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = DeviceApiService(client: mockClient);
      final repo = HttpDeviceRepository(
        apiService: service,
        deviceIp: '192.168.4.1',
        autoStartPolling: false,
      );

      // Poll 1: 11.5 cm -> ((20 - 11.5) / 17) * 100 = 50.0%
      simulatedDistance = 11.5;
      await repo.pollStatus();
      expect(repo.getCurrentStatus().fillPercentage, closeTo(50.0, 0.01));

      // Poll 2: 11.7 cm -> median (11.5 + 11.7)/2 = 11.6 -> ((20 - 11.6) / 17) * 100 = 49.41%
      simulatedDistance = 11.7;
      await repo.pollStatus();
      expect(repo.getCurrentStatus().fillPercentage, closeTo(49.41, 0.01));

      // Poll 3: Glitch spike to 25.0 cm -> history [11.5, 11.7, 25.0] -> median 11.7 cm -> 48.82%
      simulatedDistance = 25.0;
      await repo.pollStatus();
      // Does not drop to 0%, outlier 25.0 cm is safely ignored by median!
      expect(repo.getCurrentStatus().fillPercentage, closeTo(48.82, 0.01));
      expect(repo.getCurrentStatus().fillDistanceCm, 11.7);

      repo.dispose();
    });

    test('HttpDeviceRepository updates local status mode even if POST /api/mode fails due to offline', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final service = DeviceApiService(client: mockClient);
      final repo = HttpDeviceRepository(
        apiService: service,
        deviceIp: '192.168.4.1',
        autoStartPolling: false,
      );

      expect(repo.getCurrentStatus().mode, OperatingMode.automatic);

      await expectLater(
        repo.setOperatingMode(OperatingMode.manual),
        throwsA(isA<DeviceConnectionException>()),
      );

      // Status mode is still updated locally in app
      expect(repo.getCurrentStatus().mode, OperatingMode.manual);

      repo.dispose();
    });

    test('deviceRepositoryProvider switches dynamically between HttpDeviceRepository and MockDeviceRepository via isDemoMode', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially in real HTTP mode
      expect(container.read(settingsProvider).isDemoMode, isFalse);
      expect(
        container.read(deviceRepositoryProvider),
        isA<HttpDeviceRepository>(),
      );

      // Enable Demo/Simulation Mode
      await container.read(settingsProvider.notifier).setDemoMode(true);
      expect(container.read(settingsProvider).isDemoMode, isTrue);
      expect(
        container.read(deviceRepositoryProvider),
        isA<MockDeviceRepository>(),
      );

      // Disable Demo Mode
      await container.read(settingsProvider.notifier).setDemoMode(false);
      expect(container.read(settingsProvider).isDemoMode, isFalse);
      expect(
        container.read(deviceRepositoryProvider),
        isA<HttpDeviceRepository>(),
      );
    });
  });
}
