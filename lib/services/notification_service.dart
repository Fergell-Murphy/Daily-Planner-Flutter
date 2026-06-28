import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../data/database/database_helper.dart';
import '../data/models/task.dart';

class NotificationService {
  NotificationService(this._db);

  final DatabaseHelper _db;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  int _startNotificationId(int taskId) => taskId;

  int _endNotificationId(int taskId) =>
      taskId + AppConstants.notificationIdOffsetEnd;

  int _instantNotificationId(int taskId) =>
      taskId + AppConstants.notificationIdOffsetInstant;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _ensureAndroidChannels();
    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final sign = hours >= 0 ? '-' : '+';
      tz.setLocalLocation(tz.getLocation('Etc/GMT$sign${hours.abs()}'));
    }
  }

  Future<void> _ensureAndroidChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const alarmChannel = AndroidNotificationChannel(
      AppConstants.taskAlarmChannelId,
      'Task reminders',
      description: 'Notifications when tasks are scheduled to start',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const completionChannel = AndroidNotificationChannel(
      AppConstants.taskCompletionChannelId,
      'Task completion',
      description: 'Notifications when tasks are completed',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await android?.createNotificationChannel(alarmChannel);
    await android?.createNotificationChannel(completionChannel);
  }

  Future<bool> requestPermissions() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  Future<bool> ensureInfrastructure() async {
    await initialize();
    return requestPermissions();
  }

  Future<void> cancelNotification(String notificationId) async {
    try {
      await _plugin.cancel(int.parse(notificationId));
    } catch (_) {
      // Notification may already have fired or been removed.
    }
  }

  Future<void> cancelTaskNotifications(Task task) async {
    await cancelNotification(_startNotificationId(task.id).toString());
    await cancelNotification(_endNotificationId(task.id).toString());
    await cancelNotification(_instantNotificationId(task.id).toString());
    if (task.notificationId != null) {
      await cancelNotification(task.notificationId!);
      await _db.setTaskNotificationId(task.id, null);
    }
  }

  NotificationDetails _alarmDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.taskAlarmChannelId,
        'Task reminders',
        channelDescription: 'Notifications when tasks are scheduled to start',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  NotificationDetails _completionDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.taskCompletionChannelId,
        'Task completion',
        channelDescription: 'Notifications when tasks are completed',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<String?> scheduleTaskStartAlarm(Task task) async {
    await initialize();

    if (task.completion >= 100) return null;

    final triggerDate = taskStartToDate(task.date, task.startTime);
    if (!triggerDate.isAfter(DateTime.now())) return null;

    final id = _startNotificationId(task.id);
    final scheduled = tz.TZDateTime.from(triggerDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Task starting',
      task.name,
      scheduled,
      _alarmDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    return id.toString();
  }

  Future<void> scheduleTaskEndAlarm(Task task) async {
    await initialize();

    if (task.completion >= 100) return;

    final triggerDate = taskStartToDate(task.date, task.endTime);
    if (!triggerDate.isAfter(DateTime.now())) return;

    final id = _endNotificationId(task.id);
    final scheduled = tz.TZDateTime.from(triggerDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Task complete',
      '${task.name} — great job finishing up!',
      scheduled,
      _completionDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showTaskCompletedNotification(Task task) async {
    await initialize();

    final permitted = await ensureInfrastructure();
    if (!permitted) return;

    await _plugin.show(
      _instantNotificationId(task.id),
      'Task completed!',
      task.name,
      _completionDetails(),
    );
  }

  Future<void> syncTaskNotification(
    Task task,
    bool notificationsEnabled,
  ) async {
    await cancelTaskNotifications(task);

    if (!notificationsEnabled ||
        !task.alarmEnabled ||
        task.completion >= 100) {
      return;
    }

    final permitted = await ensureInfrastructure();
    if (!permitted) return;

    final notificationId = await scheduleTaskStartAlarm(task);
    await scheduleTaskEndAlarm(task);

    if (notificationId != null) {
      await _db.setTaskNotificationId(task.id, notificationId);
    }
  }

  Future<void> onTaskCompleted(Task task, bool notificationsEnabled) async {
    await cancelTaskNotifications(task);

    if (!notificationsEnabled || !task.alarmEnabled) return;

    await showTaskCompletedNotification(task);
  }

  Future<void> cancelAllTaskNotifications(List<Task> tasks) async {
    for (final task in tasks) {
      await cancelTaskNotifications(task);
    }
  }

  Future<void> rescheduleAllTaskNotifications(
    List<Task> tasks,
    bool notificationsEnabled,
  ) async {
    if (!notificationsEnabled) {
      await cancelAllTaskNotifications(tasks);
      return;
    }

    final permitted = await ensureInfrastructure();
    if (!permitted) return;

    for (final task in tasks) {
      if (task.alarmEnabled && task.completion < 100) {
        await syncTaskNotification(
          task.copyWith(notificationId: null),
          true,
        );
      } else if (task.notificationId != null) {
        await cancelTaskNotifications(task);
      }
    }
  }
}
