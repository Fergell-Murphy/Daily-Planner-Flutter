import '../../data/models/task.dart';
import 'date_utils.dart';

bool isTaskMarkedComplete(Task task) => task.completion >= 100;

int getScheduledProgress(Task task, [DateTime? now]) {
  final current = now ?? DateTime.now();
  final today = formatDateKey(current);

  if (task.date.compareTo(today) > 0) return 0;
  if (task.date.compareTo(today) < 0) return 100;

  final nowMinutes = dateToMinutes(current);

  if (nowMinutes <= task.startTime) return 0;
  if (nowMinutes >= task.endTime) return 100;

  final duration = task.endTime - task.startTime;
  if (duration <= 0) return 0;

  return (((nowMinutes - task.startTime) / duration) * 100).round();
}

int getDisplayProgress(Task task, [DateTime? now]) {
  return isTaskMarkedComplete(task) ? 100 : getScheduledProgress(task, now);
}
