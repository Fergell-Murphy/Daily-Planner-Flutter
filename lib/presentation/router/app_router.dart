import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/planner_provider.dart';
import '../screens/edit_task_screen.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(plannerProvider, (previous, next) {
    final onboardingChanged =
        previous?.needsOnboarding != next.needsOnboarding;
    final readinessChanged = previous?.isReady != next.isReady;
    if (onboardingChanged || readinessChanged) {
      refresh.value++;
    }
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/today',
    redirect: (context, state) {
      final planner = ref.read(plannerProvider);
      if (!planner.isReady) return null;

      final needsOnboarding = planner.needsOnboarding;
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (needsOnboarding && !onOnboarding) return '/onboarding';
      if (!needsOnboarding && onOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodayTab(),
            ),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressTab(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsTab(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/edit-task',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final taskId = state.uri.queryParameters['taskId'];
          final date = state.uri.queryParameters['date'];
          return CustomTransitionPage(
            fullscreenDialog: true,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            child: EditTaskScreen(
              taskId: taskId != null ? int.tryParse(taskId) : null,
              date: date,
            ),
          );
        },
      ),
    ],
  );
});
