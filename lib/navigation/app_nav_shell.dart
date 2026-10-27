import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_motion.dart';
import '../core/widgets/directional_tab_switcher.dart';
import '../core/widgets/floating_pill_nav_bar.dart';
import '../data/providers/device_provider.dart';
import '../features/activity/activity_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/controls/controls_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/debug_logs/debug_logs_screen.dart';
import '../features/settings/settings_screen.dart';

/// Standard premium page transition with fade and 16px vertical slide.
PageRouteBuilder<T> createPremiumPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppMotion.detailTransition,
    reverseTransitionDuration: AppMotion.detailTransition,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        return child;
      }
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.stateChangeCurve,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.03), // ~16px slide
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

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
      _currentIndex = index.clamp(0, 3);
    });
  }

  void _openAlertsScreen() {
    Navigator.of(context).push(createPremiumPageRoute(const AlertsScreen()));
  }

  void _openDebugLogsScreen() {
    Navigator.of(context).push(createPremiumPageRoute(const DebugLogsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        onNavigateToTab: _navigateToTab,
        onOpenAlerts: _openAlertsScreen,
      ),
      const ControlsScreen(),
      const ActivityScreen(),
      SettingsScreen(onOpenDebugLogs: _openDebugLogsScreen),
    ];

    return Scaffold(
      extendBody: true,
      body: DirectionalTabSwitcher(
        currentIndex: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
        items: const [
          FloatingNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          FloatingNavItem(
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune_rounded,
            label: 'Controls',
          ),
          FloatingNavItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history_rounded,
            label: 'Activity',
          ),
          FloatingNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
