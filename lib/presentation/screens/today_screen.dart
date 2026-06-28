import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/utils/date_utils.dart';
import '../providers/planner_provider.dart';
import '../widgets/screen_header.dart';
import '../widgets/today_task_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planner = ref.watch(plannerProvider);
    final now = ref.watch(minuteTickerProvider).value ?? DateTime.now();

    if (!planner.isReady) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy500),
      );
    }

    final today = formatDateKey(DateTime.now());

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            const ScreenHeader(),
            Text(
              '${getGreeting()}, ${planner.userName}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'You have ${planner.todayTasks.length} task${planner.todayTasks.length == 1 ? '' : 's'} scheduled for today.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (planner.todayTasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                decoration: AppDecorations.card(radius: 24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.navy100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        AppIcons.plus,
                        color: AppColors.navy500,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first task for today.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              ...planner.todayTasks.map(
                (task) => TodayTaskCard(
                  task: task,
                  now: now,
                  onPress: () => context.push('/edit-task?taskId=${task.id}'),
                  onToggleComplete: () => ref
                      .read(plannerProvider.notifier)
                      .toggleTaskComplete(task.id),
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            onPressed: () => context.push('/edit-task?date=$today'),
            child: const Icon(AppIcons.plus, size: 28),
          ),
        ),
      ],
    );
  }
}
