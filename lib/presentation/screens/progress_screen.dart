import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/task_progress.dart';
import '../providers/planner_provider.dart';
import '../widgets/circular_progress.dart';
import '../widgets/date_selector.dart';
import '../widgets/screen_header.dart';
import '../widgets/task_list_items.dart';

enum ProgressViewMode { history, detail }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressViewMode _viewMode = ProgressViewMode.history;

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);

    if (!planner.isReady) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy500),
      );
    }

    final weekDates = getWeekDates(parseDateKey(planner.selectedDate));
    final today = formatDateKey(DateTime.now());
    final unfinished = planner.tasks
        .where((t) => !isTaskMarkedComplete(t))
        .toList();
    final todoTasks = unfinished;
    final completedTasks = planner.tasks
        .where((t) => isTaskMarkedComplete(t))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const ScreenHeader(),
        DateSelector(
          dates: weekDates,
          selectedDate: planner.selectedDate,
          onSelectDate: (date) =>
              ref.read(plannerProvider.notifier).setSelectedDate(date),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'History',
                selected: _viewMode == ProgressViewMode.history,
                onTap: () =>
                    setState(() => _viewMode = ProgressViewMode.history),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TabButton(
                label: 'Analytics',
                selected: _viewMode == ProgressViewMode.detail,
                onTap: () =>
                    setState(() => _viewMode = ProgressViewMode.detail),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_viewMode == ProgressViewMode.history) ...[
          _HistoryCard(
            stats: planner.dayStats,
            selectedDate: planner.selectedDate,
          ),
          if (unfinished.isNotEmpty && planner.selectedDate != today) ...[
            const SizedBox(height: 16),
            _MoveToTodayBanner(
              count: unfinished.length,
              onTap: () => _moveToToday(today),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Activities List',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (planner.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No activities for this day.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray400),
              ),
            )
          else
            ...planner.tasks.map(
              (task) => ActivityItem(
                task: task,
                onPress: () => context.push('/edit-task?taskId=${task.id}'),
              ),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgress(percentage: planner.dayStats.percentage),
                const SizedBox(height: 16),
                Text(
                  "You've completed ${planner.dayStats.completed} out of ${planner.dayStats.total} of your scheduled tasks. ${planner.dayStats.percentage >= 75 ? 'Almost there!' : 'Keep going!'}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.navy500,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(AppIcons.star, color: AppColors.amber400),
                      const SizedBox(height: 12),
                      const Text(
                        'Great Streak!',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${planner.streak} day${planner.streak == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.sage100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(AppIcons.trendingUp, color: AppColors.sage500),
                      const SizedBox(height: 12),
                      Text(
                        'Daily Average',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${planner.weeklyAverage}%',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Still to Do',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${todoTasks.length} Left',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...todoTasks.map(
            (task) => ProgressTaskItem(
              task: task,
              variant: 'todo',
              onPress: () => context.push('/edit-task?taskId=${task.id}'),
              onToggle: () => ref
                  .read(plannerProvider.notifier)
                  .toggleTaskComplete(task.id),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(AppIcons.check, color: AppColors.sage500, size: 20),
              const SizedBox(width: 8),
              Text('Completed', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          ...completedTasks.map(
            (task) => ProgressTaskItem(
              task: task,
              variant: 'completed',
              onPress: () => context.push('/edit-task?taskId=${task.id}'),
              onToggle: () => ref
                  .read(plannerProvider.notifier)
                  .toggleTaskComplete(task.id),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _moveToToday(String today) async {
    final planner = ref.read(plannerProvider);
    final count = await ref
        .read(plannerProvider.notifier)
        .moveLeftoverTasks(planner.selectedDate, today);

    if (!mounted) return;

    final message = count > 0
        ? '$count unfinished task${count == 1 ? '' : 's'} moved to today.'
        : 'No unfinished tasks to move.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await ref.read(plannerProvider.notifier).setSelectedDate(today);
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy500 : AppColors.white,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.navy500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.stats, required this.selectedDate});

  final dynamic stats;
  final String selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy500,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getRelativeDayLabel(selectedDate),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.completed} of ${stats.total} tasks completed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (stats.percentage.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveToTodayBanner extends StatelessWidget {
  const _MoveToTodayBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream100,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(AppIcons.alertTriangle, color: AppColors.red500),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '$count item${count == 1 ? '' : 's'} were left unfinished\n',
                        style: const TextStyle(
                          color: AppColors.navy500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                        text: 'and may need your attention today. ',
                      ),
                      const TextSpan(
                        text: 'Move to Today →',
                        style: TextStyle(
                          color: AppColors.navy500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
