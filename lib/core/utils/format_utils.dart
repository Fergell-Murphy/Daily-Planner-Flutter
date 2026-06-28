import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import 'date_utils.dart';
import 'task_progress.dart';

String minutesToTimeString(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  final period = hours >= 12 ? 'PM' : 'AM';
  final displayHours = hours % 12 == 0 ? 12 : hours % 12;
  return '${displayHours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} $period';
}

DateTime minutesToDate(int minutes, [DateTime? baseDate]) {
  final base = baseDate ?? DateTime.now();
  return DateTime(base.year, base.month, base.day, minutes ~/ 60, minutes % 60);
}

String formatTimeRange(int startMinutes, int endMinutes) {
  return '${minutesToTimeString(startMinutes)} - ${minutesToTimeString(endMinutes)}';
}

String formatCompletedAt(String? isoString) {
  if (isoString == null) return '';
  final date = DateTime.parse(isoString).toLocal();
  return 'Completed at ${minutesToTimeString(dateToMinutes(date))}';
}

TaskStatus getTaskStatus(Task task, [DateTime? now]) {
  if (isTaskMarkedComplete(task)) return TaskStatus.done;
  if (getScheduledProgress(task, now) > 0) return TaskStatus.inProgress;
  return TaskStatus.notStarted;
}

String getStatusLabel(Task task, [DateTime? now]) {
  return switch (getTaskStatus(task, now)) {
    TaskStatus.done => 'Done',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.notStarted => 'Not Started',
  };
}

Color statusColor(Task task, [DateTime? now]) {
  return switch (getTaskStatus(task, now)) {
    TaskStatus.done => const Color(0xFF4A9B75),
    TaskStatus.inProgress => const Color(0xFF1A3A5C),
    TaskStatus.notStarted => const Color(0xFF9CA3AF),
  };
}
