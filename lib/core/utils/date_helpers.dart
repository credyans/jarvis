import 'package:intl/intl.dart';

class DateHelpers {
  /// Returns a time-of-day greeting based on current hour.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  /// Returns 'Today', 'Yesterday', 'Tomorrow', or a formatted date like 'Mon, Jan 15'.
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == -1) return 'Yesterday';
    if (difference == 1) return 'Tomorrow';

    return DateFormat('EEE, MMM d').format(date);
  }

  /// Converts 24h time string '14:00' to '2:00 PM'.
  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  /// Returns relative date string like '3 days ago', 'in 2 days', 'just now'.
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (days < 0) {
      // Future
      final absDays = days.abs();
      if (absDays == 0) {
        final absHours = hours.abs();
        if (absHours == 0) {
          final absMinutes = minutes.abs();
          if (absMinutes <= 1) return 'just now';
          return 'in $absMinutes minutes';
        }
        return 'in $absHours ${absHours == 1 ? 'hour' : 'hours'}';
      }
      if (absDays == 1) return 'tomorrow';
      if (absDays < 7) return 'in $absDays days';
      if (absDays < 30) {
        final weeks = absDays ~/ 7;
        return 'in $weeks ${weeks == 1 ? 'week' : 'weeks'}';
      }
      if (absDays < 365) {
        final months = absDays ~/ 30;
        return 'in $months ${months == 1 ? 'month' : 'months'}';
      }
      final years = absDays ~/ 365;
      return 'in $years ${years == 1 ? 'year' : 'years'}';
    }

    // Past
    if (days == 0) {
      if (hours == 0) {
        if (minutes <= 1) return 'just now';
        return '$minutes minutes ago';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) {
      final weeks = days ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    if (days < 365) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    final years = days ~/ 365;
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }

  /// Returns ISO week key like '2026-W22' for weekly grouping.
  static String weekKey(DateTime date) {
    // ISO 8601 week calculation
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    final weekNumber =
        ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Returns month key like '2026-05' for monthly grouping.
  static String monthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  /// Returns date key like '2026-05-29'.
  static String dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Whether the given date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Whether two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns Mon–Sun for the week containing [date].
  static List<DateTime> daysInWeek(DateTime date) {
    // Monday = 1 in Dart
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return DateTime(day.year, day.month, day.day);
    });
  }

  /// Returns every day in the month containing [date].
  static List<DateTime> daysInMonth(DateTime date) {
    final first = DateTime(date.year, date.month, 1);
    final last = DateTime(date.year, date.month + 1, 0); // last day of month
    return List.generate(last.day, (i) {
      return DateTime(first.year, first.month, first.day + i);
    });
  }
}
