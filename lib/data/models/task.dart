import 'category.dart';

class Task {
  const Task({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.completion,
    required this.categoryId,
    required this.date,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.alarmEnabled,
    required this.notificationId,
    this.category,
  });

  final int id;
  final String name;
  final int startTime;
  final int endTime;
  final int completion;
  final int categoryId;
  final String date;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;
  final bool alarmEnabled;
  final String? notificationId;
  final Category? category;

  Task copyWith({
    int? id,
    String? name,
    int? startTime,
    int? endTime,
    int? completion,
    int? categoryId,
    String? date,
    String? completedAt,
    String? createdAt,
    String? updatedAt,
    bool? alarmEnabled,
    String? notificationId,
    Category? category,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completion: completion ?? this.completion,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      notificationId: notificationId ?? this.notificationId,
      category: category ?? this.category,
    );
  }
}

class TaskInput {
  const TaskInput({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.completion,
    required this.categoryId,
    required this.date,
    this.alarmEnabled = true,
  });

  final String name;
  final int startTime;
  final int endTime;
  final int completion;
  final int categoryId;
  final String date;
  final bool alarmEnabled;

  TaskInput copyWith({
    String? name,
    int? startTime,
    int? endTime,
    int? completion,
    int? categoryId,
    String? date,
    bool? alarmEnabled,
  }) {
    return TaskInput(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completion: completion ?? this.completion,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    );
  }
}

class DayStats {
  const DayStats({
    required this.total,
    required this.completed,
    required this.percentage,
  });

  final int total;
  final int completed;
  final int percentage;

  static const empty = DayStats(total: 0, completed: 0, percentage: 0);
}

enum TaskStatus { done, inProgress, notStarted }
