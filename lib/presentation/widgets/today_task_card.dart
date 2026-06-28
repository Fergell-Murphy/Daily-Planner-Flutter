import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/task_progress.dart';
import '../../data/models/task.dart';
import 'category_chip.dart';
import 'progress_bar.dart';

class TodayTaskCard extends StatelessWidget {
  const TodayTaskCard({
    super.key,
    required this.task,
    required this.now,
    required this.onPress,
    this.onToggleComplete,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onPress;
  final VoidCallback? onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final displayProgress = getDisplayProgress(task, now);
    final color = statusColor(task, now);
    final isCompleted = isTaskMarkedComplete(task);
    final categoryColor = task.category != null
        ? parseHexColor(task.category!.color)
        : AppColors.navy500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: AppDecorations.card(radius: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            color.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (onToggleComplete != null) ...[
                                  GestureDetector(
                                    onTap: onToggleComplete,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppColors.sage500
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isCompleted
                                              ? AppColors.sage500
                                              : AppColors.gray300,
                                          width: 2,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(
                                              AppIcons.check,
                                              size: 15,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                CategoryChip(
                                  name: task.category?.name.toUpperCase() ?? 'TASK',
                                  color: categoryColor,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    formatTimeRange(task.startTime, task.endTime),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              task.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: isCompleted
                                    ? AppColors.gray400
                                    : AppColors.navy500,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ProgressBar(
                                    percentage: displayProgress,
                                    color: categoryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    '$displayProgress%',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  getStatusLabel(task, now),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
