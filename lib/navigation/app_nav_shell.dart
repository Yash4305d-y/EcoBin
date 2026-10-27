import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../data/providers/device_provider.dart';
import '../features/activity/activity_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/controls/controls_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/debug_logs/debug_logs_screen.dart';
import '../features/monitoring/monitoring_screen.dart';
import '../features/settings/settings_screen.dart';

class AppNavShell extends ConsumerStatefulWidget {
  const AppNavShell({super.key});

  @override
  ConsumerState<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends ConsumerState<AppNavShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final repo = ref.read(deviceRepositoryProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      repo.pausePolling();
    } else if (state == AppLifecycleState.resumed) {
      repo.resumePolling();
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index.clamp(0, 4);
    });
  }

  void _openAlertsScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AlertsScreen()));
  }

  void _openDebugLogsScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const DebugLogsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        onNavigateToTab: _navigateToTab,
        onOpenAlerts: _openAlertsScreen,
      ),
      const ControlsScreen(),
      const MonitoringScreen(),
      const ActivityScreen(),
      SettingsScreen(onOpenDebugLogs: _openDebugLogsScreen),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.slateSurface,
          indicatorColor: AppColors.mintGreenContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.mintGreen);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.mintGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _navigateToTab,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Controls',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Monitoring',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
