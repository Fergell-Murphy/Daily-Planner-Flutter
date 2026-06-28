import 'package:daily_planner/core/utils/date_utils.dart';
import 'package:daily_planner/core/utils/task_progress.dart';
import 'package:daily_planner/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('date utils', () {
    test('formatDateKey returns YYYY-MM-DD', () {
      expect(formatDateKey(DateTime(2026, 6, 25)), '2026-06-25');
    });

    test('getGreeting returns time-appropriate greeting', () {
      expect(getGreeting(), isNotEmpty);
    });
  });

  group('task progress', () {
    test('marked complete returns 100% display progress', () {
      const task = Task(
        id: 1,
        name: 'Test',
        startTime: 480,
        endTime: 540,
        completion: 100,
        categoryId: 1,
        date: '2026-06-25',
        completedAt: null,
        createdAt: '',
        updatedAt: '',
        alarmEnabled: true,
        notificationId: null,
      );

      expect(getDisplayProgress(task), 100);
      expect(isTaskMarkedComplete(task), isTrue);
    });
  });
}
