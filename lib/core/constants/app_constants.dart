class AppConstants {
  static const appName = 'Daily Planner';
  static const appVersion = '1.0.0';

  static const defaultCategories = [
    (name: 'Health', color: '#4a9b75'),
    (name: 'Family', color: '#7e96ba'),
    (name: 'Chores', color: '#b8956a'),
    (name: 'Appointment', color: '#5373a3'),
    (name: 'Hobby', color: '#67b38f'),
    (name: 'Activity', color: '#8dc6ab'),
  ];

  static const categoryColors = [
    '#4a9b75',
    '#7e96ba',
    '#b8956a',
    '#5373a3',
    '#67b38f',
    '#e879a9',
    '#f59e0b',
  ];

  static const streakThreshold = 75;
  static const taskAlarmChannelId = 'task-alarms';
  static const taskCompletionChannelId = 'task-completion';

  static const notificationIdOffsetEnd = 500000;
  static const notificationIdOffsetInstant = 1000000;
}
