import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecobin/app.dart';
import 'package:ecobin/core/theme/app_theme.dart';
import 'package:ecobin/data/models/device_connection_state.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:ecobin/data/providers/device_provider.dart';

import 'dart:async';

import 'package:ecobin/data/models/app_alert.dart';
import 'package:ecobin/data/models/debug_log_entry.dart';
import 'package:ecobin/data/models/device_event.dart';
import 'package:ecobin/data/repositories/device_repository.dart';
import 'package:ecobin/data/repositories/mock_device_repository.dart';
import 'package:ecobin/data/services/settings_service.dart';
import 'package:ecobin/features/controls/controls_screen.dart';
import 'package:ecobin/navigation/app_nav_shell.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EcoBin Production Mode App & UI Tests', () {
    testWidgets(
      'App launches with Onboarding on first run and connects to EcoBin',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              deviceRepositoryProvider.overrideWith(
                (ref) => ref.watch(mockDeviceRepositoryProvider),
              ),
            ],
            child: const EcoBinApp(),
          ),
        );

        // Wait for Settings to load
        await tester.pumpAndSettle();

        // Verify Onboarding Screen is shown
        expect(find.text('Welcome to EcoBin'), findsOneWidget);
        final connectButton = find.widgetWithText(
          FilledButton,
          'Connect to EcoBin',
        );
        expect(connectButton, findsOneWidget);

        // Scroll into view and tap Connect to EcoBin
        await tester.ensureVisible(connectButton);
        await tester.tap(connectButton);
        await tester.pumpAndSettle();

        // Verify transition to main AppNavShell and Dashboard
        expect(find.text('EcoBin Dashboard'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Controls'), findsOneWidget);
        expect(find.text('Activity'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets('Bottom navigation switches between screens seamlessly', (
      WidgetTester tester,
    ) async {
      // Simulate already completed onboarding
      SharedPreferences.setMockInitialValues({
        SettingsService.keyOnboardingComplete: true,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWith(
              (ref) => ref.watch(mockDeviceRepositoryProvider),
            ),
          ],
          child: const EcoBinApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify on Dashboard (Home)
      expect(find.text('EcoBin Dashboard'), findsOneWidget);

      // Tap Controls tab
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bin Actuation & Controls'), findsOneWidget);
      // In Automatic mode, manual controls are hidden
      expect(find.text('Open Lid'), findsNothing);
      expect(find.text('Close Lid'), findsNothing);

      // Tap Activity tab
      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bin Activity & History'), findsOneWidget);
      expect(find.text('Recent Events Log'), findsOneWidget);

      // Tap Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Device Settings & Configuration'), findsOneWidget);
      expect(find.text('ESP32 Device IP Address'), findsOneWidget);

      // Tap Home tab
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('EcoBin Dashboard'), findsOneWidget);
    });

    testWidgets(
      'Controls screen shows Open and Close Lid in Manual mode and follows lid state',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          SettingsService.keyOnboardingComplete: true,
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              deviceRepositoryProvider.overrideWith(
                (ref) => ref.watch(mockDeviceRepositoryProvider),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const AppNavShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to controls
        await tester.tap(find.byIcon(Icons.tune_outlined));
        await tester.pumpAndSettle();

        // In Automatic mode, manual Open/Close buttons are NOT shown
        expect(find.text('Open Lid'), findsNothing);
        expect(find.text('Close Lid'), findsNothing);

        // Switch to Manual Mode
        await tester.tap(find.text('Manual Mode'));
        await tester.pumpAndSettle();

        // Both Open Lid and Close Lid are now visible
        expect(find.text('Open Lid'), findsOneWidget);
        expect(find.text('Close Lid'), findsOneWidget);

        // Initial state is closed lid, so 'Open Lid' is enabled and 'Close Lid' is disabled
        final openLidButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        expect(openLidButton.onPressed, isNotNull);

        final closeLidButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(closeLidButton.onPressed, isNull);

        // Tap Open Lid
        await tester.tap(find.widgetWithText(FilledButton, 'Open Lid'));
        await tester.pump(const Duration(milliseconds: 100));

        // Wait for actuation to complete (600ms in MockDeviceRepository)
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        // Now lid is open, so 'Open Lid' is disabled and 'Close Lid' is enabled
        final openLidButtonAfter = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        expect(openLidButtonAfter.onPressed, isNull);

        final closeLidButtonAfter = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(closeLidButtonAfter.onPressed, isNotNull);

        // Tap Close Lid
        await tester.tap(find.widgetWithText(OutlinedButton, 'Close Lid'));
        await tester.pump(const Duration(milliseconds: 100));

        // Wait for close actuation to complete
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        // Lid is closed again: 'Open Lid' is enabled, 'Close Lid' is disabled
        final openLidButtonFinal = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        expect(openLidButtonFinal.onPressed, isNotNull);

        final closeLidButtonFinal = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(closeLidButtonFinal.onPressed, isNull);
      },
    );

    testWidgets('Onboarding screen saves IP and connects when submitted', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWith(
              (ref) => ref.watch(mockDeviceRepositoryProvider),
            ),
          ],
          child: const EcoBinApp(),
        ),
      );
      await tester.pumpAndSettle();

      final ipField = find.byType(TextField);
      expect(ipField, findsOneWidget);
      await tester.enterText(ipField, '192.168.1.150');

      final connectButton = find.widgetWithText(
        FilledButton,
        'Connect to EcoBin',
      );
      expect(connectButton, findsOneWidget);
      await tester.ensureVisible(connectButton);
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      // AppNavShell should now be displayed
      expect(find.text('EcoBin Dashboard'), findsOneWidget);
    });

    testWidgets('Maintenance mode shows confirmation dialog before switching', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        SettingsService.keyOnboardingComplete: true,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRepositoryProvider.overrideWith(
              (ref) => ref.watch(mockDeviceRepositoryProvider),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AppNavShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to controls
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();

      // Tap Maintenance Mode
      final maintenanceTile = find.text('Maintenance Mode');
      await tester.ensureVisible(maintenanceTile);
      await tester.tap(maintenanceTile);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Enable Maintenance Mode?'), findsOneWidget);
      expect(find.text('Lock & Enable'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Enable Maintenance Mode?'), findsNothing);
    });

    testWidgets(
      'Monitoring screen displays separate Hand Sensor and Fill Sensor health indicators',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          SettingsService.keyOnboardingComplete: true,
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              deviceRepositoryProvider.overrideWith(
                (ref) => ref.watch(mockDeviceRepositoryProvider),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const AppNavShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify indicators on Home screen
        expect(find.text('Dual Ultrasonic Sensors'), findsOneWidget);
        expect(find.text('Hand Sensor'), findsOneWidget);
        expect(find.text('Fill Sensor'), findsOneWidget);
        expect(find.text('HEALTHY'), findsNWidgets(2));

        // Tap Details to open dedicated Monitoring screen
        await tester.ensureVisible(find.text('Details'));
        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();

        expect(find.text('Sensor Monitoring & Telemetry'), findsOneWidget);
        expect(find.text('Dual Ultrasonic Sensors'), findsOneWidget);
        expect(find.text('Hand Sensor'), findsOneWidget);
        expect(find.text('Fill Sensor'), findsOneWidget);
      },
    );

    testWidgets(
      'Real Mode: Monitoring screen displays sensor failure distinctly and null fill as Unavailable',
      (WidgetTester tester) async {
        final realStatus = DeviceStatus(
          isDemo: false,
          connectionStatus: DeviceConnectionStatus.online,
          lidState: LidState.closed,
          mode: OperatingMode.automatic,
          todayOpenings: 5,
          openingsSinceBoot: 5,
          lastUpdated: DateTime.now(),
          handSensorOk: false,
          fillSensorOk: true,
          handDistanceCm: null,
          fillDistanceCm: null,
          fillPercentage: null,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              deviceStatusProvider.overrideWith(
                (ref) => Stream.value(realStatus),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const AppNavShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hand sensor failure indicator on Home
        expect(find.text('FAILURE'), findsOneWidget);
        expect(find.text('HEALTHY'), findsOneWidget);
        expect(find.textContaining('Hand sensor unavailable'), findsWidgets);
        expect(find.text('Unavailable'), findsWidgets);
        expect(find.text('0%'), findsNothing);

        // Tap Details to verify on full Monitoring screen
        await tester.ensureVisible(find.text('Details'));
        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();

        expect(find.text('FAILURE'), findsOneWidget);
        expect(find.text('HEALTHY'), findsOneWidget);
        expect(find.textContaining('Hand sensor unavailable'), findsWidgets);
        expect(find.text('Unavailable'), findsWidgets);
        expect(find.text('0%'), findsNothing);
      },
    );
  });

  group('ControlsScreen Visibility & Offline Usability Tests', () {
    testWidgets(
      'Controls buttons are hidden in Automatic mode and Maintenance mode, and both visible in Manual mode',
      (WidgetTester tester) async {
        final autoStatus = DeviceStatus(
          isDemo: false,
          connectionStatus: DeviceConnectionStatus.online,
          lidState: LidState.closed,
          mode: OperatingMode.automatic,
          todayOpenings: 3,
          openingsSinceBoot: 3,
          lastUpdated: DateTime.now(),
        );

        final repo = FakeDeviceRepository(autoStatus);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [deviceRepositoryProvider.overrideWith((ref) => repo)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const ControlsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Bin Actuation & Controls'), findsOneWidget);
        expect(find.text('Automatic Mode'), findsWidgets);
        expect(find.text('Open Lid'), findsNothing);
        expect(find.text('Close Lid'), findsNothing);

        // Switch to Manual Mode: both Open Lid and Close Lid become visible
        repo.updateStatus(autoStatus.copyWith(mode: OperatingMode.manual));
        await tester.pumpAndSettle();

        expect(find.text('Manual Actuation'), findsOneWidget);
        expect(find.text('Open Lid'), findsOneWidget);
        expect(find.text('Close Lid'), findsOneWidget);

        // Switch to Maintenance Mode: buttons are hidden for safety
        repo.updateStatus(autoStatus.copyWith(mode: OperatingMode.maintenance));
        await tester.pumpAndSettle();

        expect(find.text('Maintenance Mode'), findsWidgets);
        expect(find.text('Open Lid'), findsNothing);
        expect(find.text('Close Lid'), findsNothing);
      },
    );

    testWidgets(
      'Manual mode buttons remain visible when lid is closed, open, or moving',
      (WidgetTester tester) async {
        final baseManualStatus = DeviceStatus(
          isDemo: false,
          connectionStatus: DeviceConnectionStatus.online,
          lidState: LidState.closed,
          mode: OperatingMode.manual,
          todayOpenings: 2,
          openingsSinceBoot: 2,
          lastUpdated: DateTime.now(),
        );

        final repo = FakeDeviceRepository(baseManualStatus);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [deviceRepositoryProvider.overrideWith((ref) => repo)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const ControlsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Lid Closed: both visible, Open enabled, Close disabled
        expect(find.text('Open Lid'), findsOneWidget);
        expect(find.text('Close Lid'), findsOneWidget);
        final openWhenClosed = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        final closeWhenClosed = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(openWhenClosed.onPressed, isNotNull);
        expect(closeWhenClosed.onPressed, isNull);

        // 2. Lid Open: both visible, Open disabled, Close enabled
        repo.updateStatus(baseManualStatus.copyWith(lidState: LidState.open));
        await tester.pumpAndSettle();

        expect(find.text('Open Lid'), findsOneWidget);
        expect(find.text('Close Lid'), findsOneWidget);
        final openWhenOpen = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        final closeWhenOpen = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(openWhenOpen.onPressed, isNull);
        expect(closeWhenOpen.onPressed, isNotNull);

        // 3. Lid Moving: both visible, both disabled with spinner
        repo.updateStatus(baseManualStatus.copyWith(lidState: LidState.moving));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Open Lid'), findsOneWidget);
        expect(find.text('Close Lid'), findsOneWidget);
        final openWhenMoving = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        final closeWhenMoving = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(openWhenMoving.onPressed, isNull);
        expect(closeWhenMoving.onPressed, isNull);
      },
    );

    testWidgets(
      'Controls screen renders when EcoBin is offline: buttons visible in Manual mode, disabled with explanation',
      (WidgetTester tester) async {
        final offlineManualStatus = DeviceStatus(
          isDemo: false,
          connectionStatus: DeviceConnectionStatus.offline,
          lidState: LidState.closed,
          mode: OperatingMode.manual,
          todayOpenings: 0,
          openingsSinceBoot: 0,
          lastUpdated: DateTime.now(),
        );

        final repo = FakeDeviceRepository(offlineManualStatus);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [deviceRepositoryProvider.overrideWith((ref) => repo)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const ControlsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Offline warning banner is shown
        expect(find.text('EcoBin is Offline'), findsOneWidget);
        expect(
          find.text(
            'Hardware commands disabled. Connect to EcoBin or enable Simulation Mode.',
          ),
          findsOneWidget,
        );
        expect(find.text('Simulate'), findsOneWidget);

        // 2. Controls section is NOT hidden; both buttons are visible
        expect(find.text('Manual Actuation'), findsOneWidget);
        expect(find.text('Open Lid'), findsOneWidget);
        expect(find.text('Close Lid'), findsOneWidget);

        // 3. Explanation is displayed above buttons
        expect(
          find.text(
            'EcoBin is offline. Reconnect Wi-Fi or enable Simulation Mode to actuate.',
          ),
          findsOneWidget,
        );

        // 4. Buttons are safely disabled since hardware is unreachable
        final openBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Open Lid'),
        );
        final closeBtn = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Close Lid'),
        );
        expect(openBtn.onPressed, isNull);
        expect(closeBtn.onPressed, isNull);
      },
    );

    testWidgets('Tapping Simulate in offline banner enables simulation mode', (
      WidgetTester tester,
    ) async {
      final offlineManualStatus = DeviceStatus(
        isDemo: false,
        connectionStatus: DeviceConnectionStatus.offline,
        lidState: LidState.closed,
        mode: OperatingMode.manual,
        todayOpenings: 0,
        openingsSinceBoot: 0,
        lastUpdated: DateTime.now(),
      );

      final repo = FakeDeviceRepository(offlineManualStatus);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [deviceRepositoryProvider.overrideWith((ref) => repo)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ControlsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final simulateBtn = find.text('Simulate');
      expect(simulateBtn, findsOneWidget);
      await tester.tap(simulateBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Simulation Mode enabled'), findsOneWidget);
    });
  });

  group('MockDeviceRepository & Architecture Unit Tests', () {
    test('MockDeviceRepository manages state transitions cleanly', () async {
      final repo = MockDeviceRepository();

      expect(repo.getCurrentStatus().isDemo, isTrue);
      expect(repo.getCurrentStatus().lidState, LidState.closed);

      await repo.openLid();
      expect(repo.getCurrentStatus().lidState, LidState.open);

      await repo.closeLid();
      expect(repo.getCurrentStatus().lidState, LidState.closed);

      await repo.setOperatingMode(OperatingMode.manual);
      expect(repo.getCurrentStatus().mode, OperatingMode.manual);

      await repo.setFillPercentage(null);
      expect(repo.getCurrentStatus().fillPercentage, isNull);

      await repo.setFillPercentage(75.5);
      expect(repo.getCurrentStatus().fillPercentage, 75.5);

      final events = await repo.getEvents();
      expect(events.isNotEmpty, isTrue);

      final alerts = await repo.getAlerts();
      expect(alerts.isNotEmpty, isTrue);

      final logs = await repo.getDebugLogs();
      expect(logs.isNotEmpty, isTrue);
    });

    test('SettingsService IPv4 validation and sanitization helper', () {
      expect(SettingsService.isValidIpv4('192.168.4.1'), isTrue);
      expect(SettingsService.isValidIpv4('10.0.0.1'), isTrue);
      expect(SettingsService.isValidIpv4('172.16.0.100'), isTrue);
      expect(SettingsService.isValidIpv4('10.236.242.197'), isTrue);
      expect(SettingsService.isValidIpv4('http://10.236.242.197'), isTrue);
      expect(
        SettingsService.isValidIpv4('http://10.236.242.197/api/health'),
        isTrue,
      );
      expect(SettingsService.isValidIpv4('10.236.242.197:80'), isTrue);

      expect(
        SettingsService.sanitizeIp('http://10.236.242.197/api/status'),
        equals('10.236.242.197'),
      );
      expect(
        SettingsService.sanitizeIp('  10.236.242.197  '),
        equals('10.236.242.197'),
      );
      expect(
        SettingsService.sanitizeIp('http://10.236.242.197:80/'),
        equals('10.236.242.197'),
      );

      expect(SettingsService.isValidIpv4(''), isFalse);
      expect(SettingsService.isValidIpv4('256.0.0.1'), isFalse);
      expect(SettingsService.isValidIpv4('192.168.1'), isFalse);
      expect(SettingsService.isValidIpv4('192.168.1.1.1'), isFalse);
      expect(SettingsService.isValidIpv4('abc.def.ghi.jkl'), isFalse);
      expect(SettingsService.isValidIpv4('192.168.01.1'), isFalse);
    });
  });
}

class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository(this._status);

  DeviceStatus _status;
  final StreamController<DeviceStatus> _controller =
      StreamController<DeviceStatus>.broadcast();

  void updateStatus(DeviceStatus newStatus) {
    _status = newStatus;
    _controller.add(_status);
  }

  @override
  DeviceStatus getCurrentStatus() => _status;

  @override
  Stream<DeviceStatus> watchStatus() async* {
    yield _status;
    yield* _controller.stream;
  }

  @override
  Future<void> openLid() async {
    _status = _status.copyWith(lidState: LidState.open);
    _controller.add(_status);
  }

  @override
  Future<void> closeLid() async {
    _status = _status.copyWith(lidState: LidState.closed);
    _controller.add(_status);
  }

  @override
  Future<void> setOperatingMode(OperatingMode mode) async {
    _status = _status.copyWith(mode: mode);
    _controller.add(_status);
  }

  @override
  Future<void> refreshStatus() async {}

  @override
  Future<Map<String, dynamic>> checkHealth() async => {'status': 'ok'};

  @override
  Future<void> setFillPercentage(double? percentage) async {}

  @override
  Future<List<DeviceEvent>> getEvents() async => [];

  @override
  Future<List<AppAlert>> getAlerts() async => [];

  @override
  Future<void> dismissAlert(String alertId) async {}

  @override
  Future<List<DebugLogEntry>> getDebugLogs() async => [];

  @override
  void clearDebugLogs() {}

  @override
  void pausePolling() {}

  @override
  void resumePolling() {}

  @override
  void dispose() {
    _controller.close();
  }
}
