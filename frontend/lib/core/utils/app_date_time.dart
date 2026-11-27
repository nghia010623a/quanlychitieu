/// Date and period formatting helpers for Keepoo.
abstract final class AppDateTime {
  static String formatDayMonth(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String formatShortDayMonth(DateTime date) {
    return '${date.day}/${date.month}';
  }

  static String formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatFullDate(start)} – ${formatFullDate(end)}';
  }

  static String formatCompactRange(DateTime start, DateTime end) {
    return '${formatDayMonth(start)} – ${formatDayMonth(end)}';
  }

  static String formatMonthYear(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return 'Tháng $month/${date.year}';
  }

  static String formatRelativeDay(DateTime date, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return formatDayMonth(date);
  }
}
