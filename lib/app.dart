import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/planner_provider.dart';
import 'presentation/router/app_router.dart';

class DailyPlannerApp extends ConsumerStatefulWidget {
  const DailyPlannerApp({super.key});

  @override
  ConsumerState<DailyPlannerApp> createState() => _DailyPlannerAppState();
}

class _DailyPlannerAppState extends ConsumerState<DailyPlannerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(plannerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final planner = ref.watch(plannerProvider);

    return MaterialApp.router(
      title: 'Daily Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        if (!planner.isReady) {
          return const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: ColoredBox(
              color: Color(0xFFF9FAFB),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A3A5C)),
              ),
            ),
          );
        }
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
