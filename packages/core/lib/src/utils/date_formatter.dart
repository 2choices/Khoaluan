/// Utility class for formatting dates in Vietnamese locale.
class DateFormatter {
  DateFormatter._();

  static const List<String> _vietnameseMonths = [
    'Th\u00e1ng 1',
    'Th\u00e1ng 2',
    'Th\u00e1ng 3',
    'Th\u00e1ng 4',
    'Th\u00e1ng 5',
    'Th\u00e1ng 6',
    'Th\u00e1ng 7',
    'Th\u00e1ng 8',
    'Th\u00e1ng 9',
    'Th\u00e1ng 10',
    'Th\u00e1ng 11',
    'Th\u00e1ng 12',
  ];

  static const List<String> _vietnameseDays = [
    'Ch\u1ee7 nh\u1eadt',
    'Th\u1ee9 hai',
    'Th\u1ee9 ba',
    'Th\u1ee9 t\u01b0',
    'Th\u1ee9 n\u0103m',
    'Th\u1ee9 s\u00e1u',
    'Th\u1ee9 b\u1ea3y',
  ];

  /// Formats date as "dd/MM/yyyy".
  ///
  /// Example: 2024-03-15 -> "15/03/2024"
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  /// Formats date and time as "dd/MM/yyyy HH:mm".
  ///
  /// Example: 2024-03-15T14:30:00 -> "15/03/2024 14:30"
  static String formatDateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  /// Formats time as "HH:mm".
  ///
  /// Example: 14:30:00 -> "14:30"
  static String formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  /// Formats date with Vietnamese month name.
  ///
  /// Example: 2024-03-15 -> "15 Thang 3, 2024"
  static String formatDateVN(DateTime date) {
    return '${date.day} ${_vietnameseMonths[date.month - 1]}, ${date.year}';
  }

  /// Formats date with Vietnamese day of week.
  ///
  /// Example: 2024-03-15 (Friday) -> "Thu sau, 15/03/2024"
  static String formatDateWithDay(DateTime date) {
    final dayName = _vietnameseDays[date.weekday % 7];
    return '$dayName, ${formatDate(date)}';
  }

  /// Returns a relative time string in Vietnamese.
  ///
  /// Example: 30 seconds ago -> "Vua xong"
  /// Example: 5 minutes ago -> "5 phut truoc"
  /// Example: 2 hours ago -> "2 gio truoc"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) {
      return formatDateTime(date);
    }

    if (diff.inSeconds < 60) {
      return 'V\u1eeba xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ph\u00fat tr\u01b0\u1edbc';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} gi\u1edd tr\u01b0\u1edbc';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ng\u00e0y tr\u01b0\u1edbc';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks tu\u1ea7n tr\u01b0\u1edbc';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months th\u00e1ng tr\u01b0\u1edbc';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years n\u0103m tr\u01b0\u1edbc';
    }
  }

  /// Formats a date range.
  ///
  /// Example: "15/03/2024 - 20/03/2024"
  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }
}
