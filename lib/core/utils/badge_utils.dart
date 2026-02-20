import 'package:intl/intl.dart';
import '../../data/models/drink_entry_model.dart';

/// Pure-logic helpers extracted from BadgeService so they can be unit-tested
/// without a Firebase dependency.
class BadgeUtils {
  BadgeUtils._();

  /// Returns the current consecutive-day drinking streak for [drinks].
  ///
  /// - Today counts if there is an entry today.
  /// - If today has no entry, yesterday's entry can still start the streak.
  /// - The streak breaks the moment a day is skipped.
  static int calculateStreak(List<DrinkEntry> drinks) {
    if (drinks.isEmpty) return 0;

    final sorted = List<DrinkEntry>.from(drinks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Collect the unique calendar days that have at least one entry.
    final uniqueDays = sorted
        .map((d) =>
            DateTime(d.timestamp.year, d.timestamp.month, d.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // most-recent first

    final today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    // If the most-recent entry is not today, try starting from yesterday.
    if (uniqueDays.first != checkDate) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (uniqueDays.first != checkDate) return 0;
    }

    int streak = 0;
    for (final day in uniqueDays) {
      if (day == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Returns the highest single-night total APS (points) across all nights.
  ///
  /// A "night" runs from 06:00 to 05:59 the following day.
  /// Drinks between 00:00–05:59 are attributed to the previous night.
  static double calculateMaxSingleNight(List<DrinkEntry> drinks) {
    if (drinks.isEmpty) return 0;

    final Map<String, double> nightAps = {};
    for (final drink in drinks) {
      var adjusted = drink.timestamp;
      if (drink.timestamp.hour < 6) {
        adjusted = drink.timestamp.subtract(const Duration(days: 1));
      }
      final key = DateFormat('yyyy-MM-dd').format(adjusted);
      nightAps[key] = (nightAps[key] ?? 0) + drink.points;
    }

    return nightAps.values.reduce((a, b) => a > b ? a : b);
  }

  /// Returns true if [time] falls within [[start], [end]] (inclusive).
  ///
  /// Supports overnight ranges — e.g. start = "22:00", end = "02:00".
  /// All times are in "HH:mm" format.
  static bool isTimeInRange(String time, String start, String end) {
    final t = _toMinutes(time);
    final s = _toMinutes(start);
    final e = _toMinutes(end);
    // Normal range
    if (s <= e) return t >= s && t <= e;
    // Overnight range: e.g. 22:00 → 02:00
    return t >= s || t <= e;
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
