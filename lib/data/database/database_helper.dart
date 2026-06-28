import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/category.dart';
import '../models/task.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daily_planner.db');

    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );

    await _migrateSchema(db);
    await _seedIfEmpty(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        completion INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        alarm_enabled INTEGER NOT NULL DEFAULT 1,
        notification_id TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_tasks_date ON tasks(date)',
    );
  }

  Future<void> _migrateSchema(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(tasks)');
    final columnNames = columns.map((c) => c['name'] as String).toSet();

    if (!columnNames.contains('alarm_enabled')) {
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!columnNames.contains('notification_id')) {
      await db.execute('ALTER TABLE tasks ADD COLUMN notification_id TEXT');
    }
  }

  Future<void> _seedIfEmpty(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    final count = Sqflite.firstIntValue(result) ?? 0;
    if (count > 0) return;

    for (final cat in AppConstants.defaultCategories) {
      await db.insert('categories', {'name': cat.name, 'color': cat.color});
    }
  }

  static const _taskSelect = '''
    SELECT t.*, c.name as category_name, c.color as category_color
    FROM tasks t
    JOIN categories c ON t.category_id = c.id
  ''';

  Task _mapTask(Map<String, Object?> row) {
    return Task(
      id: row['id'] as int,
      name: row['name'] as String,
      startTime: row['start_time'] as int,
      endTime: row['end_time'] as int,
      completion: row['completion'] as int,
      categoryId: row['category_id'] as int,
      date: row['date'] as String,
      completedAt: row['completed_at'] as String?,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
      alarmEnabled: (row['alarm_enabled'] as int? ?? 1) != 0,
      notificationId: row['notification_id'] as String?,
      category: Category(
        id: row['category_id'] as int,
        name: row['category_name'] as String,
        color: row['category_color'] as String,
      ),
    );
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name');
    return rows
        .map(
          (row) => Category(
            id: row['id'] as int,
            name: row['name'] as String,
            color: row['color'] as String,
          ),
        )
        .toList();
  }

  Future<Category> createCategory(String name, String color) async {
    final db = await database;
    final id = await db.insert('categories', {'name': name, 'color': color});
    return Category(id: id, name: name, color: color);
  }

  Future<List<Task>> getTasksByDate(String date) async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_taskSelect WHERE t.date = ? ORDER BY t.start_time',
      [date],
    );
    return rows.map(_mapTask).toList();
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('$_taskSelect WHERE t.id = ?', [id]);
    if (rows.isEmpty) return null;
    return _mapTask(rows.first);
  }

  Future<Task> createTask(TaskInput input) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    final completedAt = input.completion >= 100 ? now : null;

    final id = await db.insert('tasks', {
      'name': input.name,
      'start_time': input.startTime,
      'end_time': input.endTime,
      'completion': input.completion,
      'category_id': input.categoryId,
      'date': input.date,
      'completed_at': completedAt,
      'created_at': now,
      'updated_at': now,
      'alarm_enabled': input.alarmEnabled ? 1 : 0,
    });

    final task = await getTaskById(id);
    if (task == null) throw StateError('Failed to create task');
    return task;
  }

  Future<Task> updateTask(int id, TaskInput partial, Task existing) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    final completion = partial.completion;
    final completedAt = completion >= 100
        ? (existing.completedAt ?? now)
        : completion < 100
            ? null
            : existing.completedAt;

    await db.update(
      'tasks',
      {
        'name': partial.name,
        'start_time': partial.startTime,
        'end_time': partial.endTime,
        'completion': completion,
        'category_id': partial.categoryId,
        'date': partial.date,
        'completed_at': completedAt,
        'updated_at': now,
        'alarm_enabled': partial.alarmEnabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final task = await getTaskById(id);
    if (task == null) throw StateError('Failed to update task');
    return task;
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setTaskNotificationId(int taskId, String? notificationId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'notification_id': notificationId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<Task>> getUpcomingAlarmTasks() async {
    final db = await database;
    final today = formatDateKey(DateTime.now());
    final rows = await db.rawQuery(
      '$_taskSelect WHERE t.date >= ? AND t.alarm_enabled = 1 AND t.completion < 100 ORDER BY t.date, t.start_time',
      [today],
    );
    return rows.map(_mapTask).toList();
  }

  Future<Task> updateTaskCompletion(int id, int completion) async {
    final existing = await getTaskById(id);
    if (existing == null) throw StateError('Task not found');
    return updateTask(
      id,
      TaskInput(
        name: existing.name,
        startTime: existing.startTime,
        endTime: existing.endTime,
        completion: completion,
        categoryId: existing.categoryId,
        date: existing.date,
        alarmEnabled: existing.alarmEnabled,
      ),
      existing,
    );
  }

  Future<int> moveUnfinishedTasks(String fromDate, String toDate) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    return db.update(
      'tasks',
      {'date': toDate, 'updated_at': now},
      where: 'date = ? AND completion < 100',
      whereArgs: [fromDate],
    );
  }

  Future<DayStats> getDayStats(String date) async {
    final db = await database;
    final row = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN completion >= 100 THEN 1 ELSE 0 END) as completed
      FROM tasks WHERE date = ?
      ''',
      [date],
    );

    final total = row.first['total'] as int? ?? 0;
    final completed = row.first['completed'] as int? ?? 0;
    final percentage = total > 0 ? ((completed / total) * 100).round() : 0;

    return DayStats(total: total, completed: completed, percentage: percentage);
  }

  Future<int> getStreak() async {
    var streak = 0;
    var checkDate = DateTime.now();

    while (true) {
      final dateKey = formatDateKey(checkDate);
      final stats = await getDayStats(dateKey);

      if (stats.total == 0) break;
      if (stats.percentage < AppConstants.streakThreshold) break;

      streak++;
      checkDate = addDays(checkDate, -1);
    }

    return streak;
  }

  Future<int> getWeeklyAverage() async {
    var totalPercentage = 0;
    var daysWithTasks = 0;

    for (var i = 0; i < 7; i++) {
      final date = formatDateKey(addDays(DateTime.now(), -i));
      final stats = await getDayStats(date);
      if (stats.total > 0) {
        totalPercentage += stats.percentage;
        daysWithTasks++;
      }
    }

    return daysWithTasks > 0 ? (totalPercentage / daysWithTasks).round() : 0;
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_taskSelect WHERE t.name LIKE ? ORDER BY t.date DESC, t.start_time',
      ['%$query%'],
    );
    return rows.map(_mapTask).toList();
  }
}
