int dateToMinutes(DateTime date) => date.hour * 60 + date.minute;

String formatDateKey(DateTime date) {
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime addDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

List<DateTime> getWeekDates(DateTime centerDate) {
  final start = addDays(centerDate, -3);
  return List.generate(7, (i) => addDays(start, i));
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isToday(DateTime date) => isSameDay(date, DateTime.now());

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String getDayLabel(DateTime date) {
  const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return labels[date.weekday - 1];
}

int getDayNumber(DateTime date) => date.day;

String getRelativeDayLabel(String dateKey) {
  final date = parseDateKey(dateKey);
  final today = DateTime.now();
  final yesterday = addDays(today, -1);

  if (isSameDay(date, today)) return 'Today';
  if (isSameDay(date, yesterday)) return 'Yesterday';

  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return weekdays[date.weekday - 1];
}

DateTime taskStartToDate(String dateKey, int startTimeMinutes) {
  final date = parseDateKey(dateKey);
  return DateTime(
    date.year,
    date.month,
    date.day,
    startTimeMinutes ~/ 60,
    startTimeMinutes % 60,
  );
}
