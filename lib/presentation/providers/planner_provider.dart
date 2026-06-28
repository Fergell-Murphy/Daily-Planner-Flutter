import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/task.dart';
import '../../services/notification_service.dart';

final databaseProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(databaseProvider));
});

class PlannerState {
  const PlannerState({
    this.isReady = false,
    this.userName = '',
    this.notificationsEnabled = true,
    this.categories = const [],
    this.selectedDate = '',
    this.tasks = const [],
    this.todayTasks = const [],
    this.dayStats = DayStats.empty,
    this.streak = 0,
    this.weeklyAverage = 0,
  });

  final bool isReady;
  final String userName;
  final bool notificationsEnabled;
  final List<Category> categories;
  final String selectedDate;
  final List<Task> tasks;
  final List<Task> todayTasks;
  final DayStats dayStats;
  final int streak;
  final int weeklyAverage;

  bool get needsOnboarding => isReady && userName.trim().isEmpty;

  PlannerState copyWith({
    bool? isReady,
    String? userName,
    bool? notificationsEnabled,
    List<Category>? categories,
    String? selectedDate,
    List<Task>? tasks,
    List<Task>? todayTasks,
    DayStats? dayStats,
    int? streak,
    int? weeklyAverage,
  }) {
    return PlannerState(
      isReady: isReady ?? this.isReady,
      userName: userName ?? this.userName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      categories: categories ?? this.categories,
      selectedDate: selectedDate ?? this.selectedDate,
      tasks: tasks ?? this.tasks,
      todayTasks: todayTasks ?? this.todayTasks,
      dayStats: dayStats ?? this.dayStats,
      streak: streak ?? this.streak,
      weeklyAverage: weeklyAverage ?? this.weeklyAverage,
    );
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._db, this._notifications)
      : super(PlannerState(selectedDate: formatDateKey(DateTime.now())));

  final DatabaseHelper _db;
  final NotificationService _notifications;

  Future<void> initialize() async {
    await _db.database;
    await _notifications.initialize();
    await loadData();

    final notifSetting = await _db.getSetting('notificationsEnabled');
    final enabled = _parseNotificationsEnabled(notifSetting);
    if (enabled) {
      await _notifications.requestPermissions();
      final upcoming = await _db.getUpcomingAlarmTasks();
      await _notifications.rescheduleAllTaskNotifications(upcoming, true);
    }

    state = state.copyWith(isReady: true);
  }

  bool _parseNotificationsEnabled(String? value) => value != 'false';

  Future<void> loadData() async {
    final today = formatDateKey(DateTime.now());
    final results = await Future.wait([
      _db.getCategories(),
      _db.getSetting('userName'),
      _db.getSetting('notificationsEnabled'),
      _db.getTasksByDate(state.selectedDate),
      _db.getTasksByDate(today),
      _db.getDayStats(state.selectedDate),
      _db.getStreak(),
      _db.getWeeklyAverage(),
    ]);

    state = state.copyWith(
      categories: results[0] as List<Category>,
      userName: (results[1] as String?) ?? '',
      notificationsEnabled:
          _parseNotificationsEnabled(results[2] as String?),
      tasks: results[3] as List<Task>,
      todayTasks: results[4] as List<Task>,
      dayStats: results[5] as DayStats,
      streak: results[6] as int,
      weeklyAverage: results[7] as int,
    );
  }

  Future<void> setSelectedDate(String date) async {
    state = state.copyWith(selectedDate: date);
    await loadData();
  }

  Future<void> setUserName(String name) async {
    await _db.setSetting('userName', name);
    state = state.copyWith(userName: name);
  }

  Future<void> completeOnboarding(String name) async {
    await setUserName(name);
    await _notifications.requestPermissions();
    final upcoming = await _db.getUpcomingAlarmTasks();
    await _notifications.rescheduleAllTaskNotifications(upcoming, true);
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _notifications.requestPermissions();
      if (!granted) return false;
    }

    await _db.setSetting('notificationsEnabled', enabled ? 'true' : 'false');
    state = state.copyWith(notificationsEnabled: enabled);

    final upcoming = await _db.getUpcomingAlarmTasks();
    await _notifications.rescheduleAllTaskNotifications(upcoming, enabled);
    await loadData();
    return true;
  }

  Future<Task> addTask(TaskInput input) async {
    final task = await _db.createTask(input);
    await _syncNotification(task);
    await loadData();
    return (await _db.getTaskById(task.id)) ?? task;
  }

  Future<Task> editTask(int id, TaskInput partial) async {
    final existing = await _db.getTaskById(id);
    if (existing == null) throw StateError('Task not found');

    await _notifications.cancelTaskNotifications(existing);

    final task = await _db.updateTask(id, partial, existing);
    await _syncNotification(task);
    await loadData();
    return (await _db.getTaskById(task.id)) ?? task;
  }

  Future<void> removeTask(int id) async {
    final existing = await _db.getTaskById(id);
    if (existing != null) {
      await _notifications.cancelTaskNotifications(existing);
    }
    await _db.deleteTask(id);
    await loadData();
  }

  Future<void> toggleTaskComplete(int id) async {
    final task = await _db.getTaskById(id);
    if (task == null) return;
    final newCompletion = task.completion >= 100 ? 0 : 100;
    await _db.updateTaskCompletion(id, newCompletion);

    final updated = await _db.getTaskById(id);
    if (updated == null) return;

    if (newCompletion >= 100) {
      await _notifications.onTaskCompleted(updated, state.notificationsEnabled);
    } else {
      await _notifications.syncTaskNotification(
        updated,
        state.notificationsEnabled,
      );
    }

    await loadData();
  }

  Future<Category> addCategory(String name, String color) async {
    final category = await _db.createCategory(name, color);
    await loadData();
    return category;
  }

  Future<int> moveLeftoverTasks(String fromDate, String toDate) async {
    final count = await _db.moveUnfinishedTasks(fromDate, toDate);
    if (state.notificationsEnabled) {
      final upcoming = await _db.getUpcomingAlarmTasks();
      await _notifications.rescheduleAllTaskNotifications(upcoming, true);
    }
    await loadData();
    return count;
  }

  Future<List<Task>> findTasks(String query) => _db.searchTasks(query);

  Future<Task?> getTask(int id) => _db.getTaskById(id);

  Future<void> _syncNotification(Task task) async {
    final fresh = await _db.getTaskById(task.id);
    if (fresh != null) {
      await _notifications.syncTaskNotification(
        fresh,
        state.notificationsEnabled,
      );
    }
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  return PlannerNotifier(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

final minuteTickerProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  await for (final _ in Stream.periodic(const Duration(minutes: 1))) {
    yield DateTime.now();
  }
});
