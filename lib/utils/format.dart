/// Formatting utilities for dates, used across the app.
/// We deliberately avoid the `intl` package to keep dependencies minimal.
library format;

/// Returns a human-readable label for a due date relative to today.
/// Examples: "Today", "Tomorrow", "Yesterday", "Mon", "Sep 28"
String dueLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';

  // Within the current week: show short weekday
  if (diff > 1 && diff < 7) return weekdayShort(date);

  // Otherwise show abbreviated month + day
  return '${_monthAbbr(date.month)} ${date.day}';
}

/// Returns a formatted date string like "Sep 28, 2026".
String formatDate(DateTime date) {
  return '${_monthAbbr(date.month)} ${date.day}, ${date.year}';
}

/// Returns a 3-letter weekday abbreviation, e.g. "Mon".
String weekdayShort(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // weekday is 1 (Mon) … 7 (Sun)
  return days[date.weekday - 1];
}

/// Returns 3-letter month abbreviation for the given 1-based [month].
String _monthAbbr(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}
