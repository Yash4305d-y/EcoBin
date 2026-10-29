import 'package:ecobin/core/theme/app_theme.dart';
import 'package:ecobin/data/models/device_connection_state.dart';
import 'package:ecobin/data/models/device_status.dart';
import 'package:ecobin/data/providers/demo_mode_provider.dart';
import 'package:ecobin/data/providers/device_provider.dart';
import 'package:ecobin/data/repositories/mock_device_repository.dart';
import 'package:ecobin/features/dashboard/widgets/fill_demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FillDemoNotifier Unit Tests', () {
    test('Default state is null (demo mode disabled)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(fillDemoOverrideProvider), isNull);
      expect(container.read(isFillDemoActiveProvider), isFalse);
    });

    test('Sets and clamps demo fill percentage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fillDemoOverrideProvider.notifier).setFillPercentage(50.0);
      expect(container.read(fillDemoOverrideProvider), 50.0);
      expect(container.read(isFillDemoActiveProvider), isTrue);

      // Clamp below 0
      container
          .read(fillDemoOverrideProvider.notifier)
          .setFillPercentage(-15.0);
      expect(container.read(fillDemoOverrideProvider), 0.0);

      // Clamp above 100
      container
          .read(fillDemoOverrideProvider.notifier)
          .setFillPercentage(125.0);
      expect(container.read(fillDemoOverrideProvider), 100.0);

      // Disable
      container.read(fillDemoOverrideProvider.notifier).disable();
      expect(container.read(fillDemoOverrideProvider), isNull);
      expect(container.read(isFillDemoActiveProvider), isFalse);
    });
  });

  group('deviceStatusProvider Demo Overlay Tests', () {
    test('Preserves authentic Offline connection status while overlaying simulated fill level', () async {
      final container = ProviderContainer(
        overrides: [
          deviceRepositoryProvider.overrideWithValue(_OfflineTestRepository()),
        ],
      );
      addTearDown(container.dispose);

      final states = <AsyncValue<DeviceStatus>>[];
      container.listen(
        deviceStatusProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      await container.pump();

      expect(
        states.last.value?.connectionStatus,
        DeviceConnectionStatus.offline,
      );
      expect(states.last.value?.fillPercentage, isNull);

      // Activate Demo Mode at 75%
      container.read(fillDemoOverrideProvider.notifier).setFillPercentage(75.0);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Connection status MUST remain genuinely Offline!
      expect(
        states.last.value?.connectionStatus,
        DeviceConnectionStatus.offline,
      );
      expect(states.last.value?.fillPercentage, 75.0);

      // Verify realistic simulated depth calculation: 23 - (0.75 * 20) = 8.0 cm
      expect(states.last.value?.fillDistanceCm, 8.0);
    });
  });

  group('FillDemoSheet UI Interaction Tests', () {
    testWidgets(
      'Tapping presets 0%, 25%, 50%, 75%, 100% updates simulated fill level',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(body: FillDemoSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap 25% preset
        await tester.tap(find.text('25%'));
        await tester.pumpAndSettle();
        expect(container.read(fillDemoOverrideProvider), 25.0);

        // Tap 50% preset
        await tester.tap(find.text('50%'));
        await tester.pumpAndSettle();
        expect(container.read(fillDemoOverrideProvider), 50.0);

        // Tap 75% preset
        await tester.tap(find.text('75%'));
        await tester.pumpAndSettle();
        expect(container.read(fillDemoOverrideProvider), 75.0);

        // Tap 100% preset
        await tester.tap(find.text('100%'));
        await tester.pumpAndSettle();
        expect(container.read(fillDemoOverrideProvider), 100.0);

        // Tap 0% preset
        await tester.tap(find.text('0%'));
        await tester.pumpAndSettle();
        expect(container.read(fillDemoOverrideProvider), 0.0);

        // Tap Turn Off Demo Mode
        await tester.tap(find.text('Turn Off Demo Mode'));
        await tester.pumpAndSettle();
        expect(container.read(fillDemoOverrideProvider), isNull);
      },
    );
  });
}

class _OfflineTestRepository extends MockDeviceRepository {
  _OfflineTestRepository() {
    _offlineStatus = DeviceStatus(
      isDemo: false,
      connectionStatus: DeviceConnectionStatus.offline,
      lidState: LidState.closed,
      mode: OperatingMode.automatic,
      todayOpenings: 0,
      lastUpdated: DateTime.now(),
      fillPercentage: null,
    );
  }

  late final DeviceStatus _offlineStatus;

  @override
  Stream<DeviceStatus> watchStatus() => Stream.value(_offlineStatus);

  @override
  DeviceStatus getCurrentStatus() => _offlineStatus;
}
