class HolidayUtils {
  static Set<DateTime> _holidays = {};

  static void setHolidays(Set<DateTime> holidays) {
    _holidays = holidays.map((h) => DateTime(h.year, h.month, h.day)).toSet();
  }

  static bool isWorkingDay(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday && !_holidays.contains(cleanDate);
  }

  static int getWorkingDaysBetween(DateTime start, DateTime end) {
    int count = 0;
    for (DateTime d = start; !d.isAfter(end); d = d.add(Duration(days: 1))) {
      if (isWorkingDay(d)) count++;
    }
    return count;
  }
}
