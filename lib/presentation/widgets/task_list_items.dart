import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/task_progress.dart';
import '../../data/models/task.dart';
import 'category_chip.dart';

class ProgressTaskItem extends StatelessWidget {
  const ProgressTaskItem({
    super.key,
    required this.task,
    required this.variant,
    required this.onPress,
    required this.onToggle,
  });

  final Task task;
  final String variant;
  final VoidCallback onPress;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isCompleted = variant == 'completed';
    final categoryColor = task.category != null
        ? parseHexColor(task.category!.color)
        : AppColors.navy500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.sage500 : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCompleted ? AppColors.sage500 : AppColors.gray300,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(AppIcons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? AppColors.gray400 : AppColors.navy500,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTimeRange(task.startTime, task.endTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                CategoryChip(
                  name: task.category?.name ?? '',
                  color: categoryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.task,
    required this.onPress,
  });

  final Task task;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final completed = isTaskMarkedComplete(task);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.sage100
                        : AppColors.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed ? AppIcons.check : AppIcons.x,
                    size: 16,
                    color: completed ? AppColors.sage500 : AppColors.gray400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatTimeRange(task.startTime, task.endTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
