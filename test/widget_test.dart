import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecobin/app.dart';
import 'package:ecobin/core/theme/app_theme.dart';
import 'package:ecobin/data/models/device_connection_state.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:ecobin/data/providers/device_provider.dart';
import 'package:ecobin/data/repositories/mock_device_repository.dart';
import 'package:ecobin/data/services/settings_service.dart';
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

    test('SettingsService IPv4 validation helper', () {
      expect(SettingsService.isValidIpv4('192.168.4.1'), isTrue);
      expect(SettingsService.isValidIpv4('10.0.0.1'), isTrue);
      expect(SettingsService.isValidIpv4('172.16.0.100'), isTrue);

      expect(SettingsService.isValidIpv4(''), isFalse);
      expect(SettingsService.isValidIpv4('256.0.0.1'), isFalse);
      expect(SettingsService.isValidIpv4('192.168.1'), isFalse);
      expect(SettingsService.isValidIpv4('192.168.1.1.1'), isFalse);
      expect(SettingsService.isValidIpv4('abc.def.ghi.jkl'), isFalse);
      expect(SettingsService.isValidIpv4('192.168.01.1'), isFalse);
    });
  });
}
