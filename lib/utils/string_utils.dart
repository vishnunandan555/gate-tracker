import 'dart:math';

String getCategoryShortName(String name) {
  if (name.isEmpty) return "";
  final parts = name.trim().split(RegExp(r'[^a-zA-Z0-9]+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return "";
  if (parts.length == 1) {
    final word = parts.first;
    if (word.length <= 3) return word.toUpperCase();
    return word.substring(0, min(3, word.length)).toUpperCase();
  }
  return parts.map((p) => p[0].toUpperCase()).join("");
}

String formatTimeOfDay(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final ampm = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMinute = minute.toString().padLeft(2, '0');
  return "$displayHour:$displayMinute $ampm";
}

String getMonthName(int month, {bool short = false}) {
  if (month < 1 || month > 12) return "";
  const fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return short ? shortMonths[month - 1] : fullMonths[month - 1];
}

String formatSyncTime(DateTime time) {
  final now = DateTime.now();
  final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  if (isToday) {
    return "$hour:$minute";
  } else {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return "$day/$month $hour:$minute";
  }
}
