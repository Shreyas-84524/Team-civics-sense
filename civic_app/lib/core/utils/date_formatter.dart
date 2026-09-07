/// Utility for formatting dates and relative time in CivicFix without extra dependencies.
class DateFormatter {
  DateFormatter._();

  static const List<String> _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String formatShortDate(DateTime dateTime) {
    return '${dateTime.day} ${_shortMonths[dateTime.month - 1]} ${dateTime.year}';
  }

  static String formatFullDate(DateTime dateTime) {
    return '${_fullMonths[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    final dateStr = formatShortDate(dateTime);
    final timeStr = formatTimeOnly(dateTime);
    return '$dateStr at $timeStr';
  }

  static String formatTimeOnly(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static String formatTime(DateTime dateTime) => formatTimeOnly(dateTime);

  static String formatRelative(DateTime dateTime) => formatRelativeTime(dateTime);

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatShortDate(dateTime);
    }
  }

  static String formatTimelineDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = formatTimeOnly(dateTime);

    final diffDays = today.difference(itemDate).inDays;
    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Yesterday, $timeStr';
    } else {
      return '${_shortMonths[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}, $timeStr';
    }
  }
}
