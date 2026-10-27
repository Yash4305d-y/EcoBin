import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecobin/app.dart';
import 'package:ecobin/core/theme/app_theme.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:ecobin/data/repositories/mock_device_repository.dart';
import 'package:ecobin/data/services/settings_service.dart';
import 'package:ecobin/navigation/app_nav_shell.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EcoBin Phase 2 App & UI Tests', () {
    testWidgets(
      'App launches with Onboarding on first run and enters Demo Mode',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: EcoBinApp()));

        // Wait for Settings to load
        await tester.pumpAndSettle();

        // Verify Onboarding Screen is shown
        expect(find.text('Welcome to EcoBin'), findsOneWidget);
        final demoButton = find.text('Launch Demo Mode (No Hardware)');
        expect(demoButton, findsOneWidget);

        // Scroll into view and tap Launch Demo Mode
        await tester.ensureVisible(demoButton);
        await tester.tap(demoButton);
        await tester.pumpAndSettle();

        // Verify transition to main AppNavShell and Dashboard
        expect(find.text('EcoBin Dashboard'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Controls'), findsOneWidget);
        expect(find.text('Monitoring'), findsOneWidget);
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

      await tester.pumpWidget(const ProviderScope(child: EcoBinApp()));
      await tester.pumpAndSettle();

      // Verify on Dashboard
      expect(find.text('EcoBin Dashboard'), findsOneWidget);

      // Tap Controls tab
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bin Actuation & Controls'), findsOneWidget);
      expect(find.text('Open Lid'), findsOneWidget);
      expect(find.text('Close Lid'), findsOneWidget);

      // Tap Monitoring tab
      await tester.tap(find.byIcon(Icons.analytics_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Sensor Monitoring & Telemetry'), findsOneWidget);
      expect(find.text('Ultrasonic Fill Sensor'), findsOneWidget);

      // Tap Activity tab
      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bin Activity & History'), findsOneWidget);
      expect(find.text('Recent Events Log'), findsOneWidget);

      // Tap Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Device Settings & Configuration'), findsOneWidget);
      expect(find.text('Demo Mode (Simulated)'), findsOneWidget);
    });

    testWidgets('Controls screen disables conflicting buttons when executing', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        SettingsService.keyOnboardingComplete: true,
      });

      await tester.pumpWidget(
        ProviderScope(
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

      // Initial state is closed lid, so 'Close Lid' is disabled and 'Open Lid' is enabled
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
      // Pump initial frame to start async delay
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for actuation to complete (600ms in MockDeviceRepository)
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Now lid should be open, so 'Open Lid' is disabled and 'Close Lid' is enabled
      final openLidButtonAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Open Lid'),
      );
      expect(openLidButtonAfter.onPressed, isNull);

      final closeLidButtonAfter = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Close Lid'),
      );
      expect(closeLidButtonAfter.onPressed, isNotNull);
    });

    testWidgets(
      'Onboarding screen saves IP and enters Real Mode when selected',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: EcoBinApp()));
        await tester.pumpAndSettle();

        final ipField = find.byType(TextField);
        expect(ipField, findsOneWidget);
        await tester.enterText(ipField, '192.168.1.150');

        final connectButton = find.text('Save IP & Connect Real ESP32');
        expect(connectButton, findsOneWidget);
        await tester.ensureVisible(connectButton);
        await tester.tap(connectButton);
        await tester.pumpAndSettle();

        // AppNavShell should now be displayed
        expect(find.text('EcoBin Dashboard'), findsOneWidget);
      },
    );

    testWidgets('Maintenance mode shows confirmation dialog before switching', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        SettingsService.keyOnboardingComplete: true,
      });

      await tester.pumpWidget(
        ProviderScope(
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
