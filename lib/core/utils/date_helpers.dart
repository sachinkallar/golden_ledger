import 'package:intl/intl.dart';

class DateHelpers {
  static final DateFormat _dayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthFormat = DateFormat('MMM');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEE, dd MMM');

  static String formatDate(DateTime dt) => _dayFormat.format(dt);
  static String formatMonthYear(DateTime dt) => _monthYearFormat.format(dt);
  static String formatShortMonth(DateTime dt) => _shortMonthFormat.format(dt);
  static String formatDayOfWeek(DateTime dt) => _dayOfWeekFormat.format(dt);

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool isYesterday(DateTime dt) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  static DateTime endOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);

  static DateTime startOfMonth(DateTime dt) => DateTime(dt.year, dt.month, 1);
  static DateTime endOfMonth(DateTime dt) {
    final nextMonth = DateTime(dt.year, dt.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }
}
