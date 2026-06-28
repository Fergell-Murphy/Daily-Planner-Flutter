import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/progress')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/today');
      case 1:
        context.go('/progress');
      case 2:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: AppDecorations.card(radius: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _selectedIndex(context),
              onDestinationSelected: (index) => _onTap(context, index),
              backgroundColor: AppColors.white,
              indicatorColor: AppColors.navy100,
              elevation: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(AppIcons.calendarDays),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.barChart3),
                  label: 'Progress',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: TodayScreen());
  }
}

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: ProgressScreen());
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: SettingsScreen());
  }
}
