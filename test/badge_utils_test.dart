import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/core/utils/badge_utils.dart';
import 'package:countsip_app/data/models/drink_entry_model.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DrinkEntry _entry({
  required DateTime timestamp,
  double points = 1.0,
  bool hasImage = false,
  String locationName = '',
}) {
  return DrinkEntry(
    id: 'test-id',
    userId: 'uid',
    drinkType: 'Beer',
    drinkEmoji: '🍺',
    portion: '500ml',
    volume: 500,
    abv: 5.0,
    quantity: 1,
    points: points,
    note: '',
    locationName: locationName,
    intoxicationLevel: 1,
    timestamp: timestamp,
    createdAt: timestamp,
    hasImage: hasImage,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // calculateStreak
  // -------------------------------------------------------------------------
  group('BadgeUtils.calculateStreak', () {
    test('empty list returns 0', () {
      expect(BadgeUtils.calculateStreak([]), 0);
    });

    test('single drink today returns streak of 1', () {
      final drinks = [_entry(timestamp: DateTime.now())];
      expect(BadgeUtils.calculateStreak(drinks), 1);
    });

    test('drinks today + yesterday = streak 2', () {
      final now = DateTime.now();
      final drinks = [
        _entry(timestamp: now),
        _entry(timestamp: now.subtract(const Duration(days: 1))),
      ];
      expect(BadgeUtils.calculateStreak(drinks), 2);
    });

    test('consecutive 5-day streak', () {
      final now = DateTime.now();
      final drinks = List.generate(
        5,
        (i) => _entry(timestamp: now.subtract(Duration(days: i))),
      );
      expect(BadgeUtils.calculateStreak(drinks), 5);
    });

    test('gap breaks the streak', () {
      final now = DateTime.now();
      // Today + 2 days ago (yesterday is missing)
      final drinks = [
        _entry(timestamp: now),
        _entry(timestamp: now.subtract(const Duration(days: 2))),
      ];
      expect(BadgeUtils.calculateStreak(drinks), 1);
    });

    test('only yesterday entry = streak of 1', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        BadgeUtils.calculateStreak([_entry(timestamp: yesterday)]),
        1,
      );
    });

    test('2-days-ago entry with no today/yesterday = 0', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(
        BadgeUtils.calculateStreak([_entry(timestamp: twoDaysAgo)]),
        0,
      );
    });

    test('multiple entries on same day count as 1 streak day', () {
      final now = DateTime.now();
      final drinks = [
        _entry(timestamp: now.copyWith(hour: 10)),
        _entry(timestamp: now.copyWith(hour: 15)),
        _entry(timestamp: now.copyWith(hour: 21)),
        _entry(timestamp: now.subtract(const Duration(days: 1))),
      ];
      expect(BadgeUtils.calculateStreak(drinks), 2);
    });
  });

  // -------------------------------------------------------------------------
  // calculateMaxSingleNight
  // -------------------------------------------------------------------------
  group('BadgeUtils.calculateMaxSingleNight', () {
    test('empty list returns 0', () {
      expect(BadgeUtils.calculateMaxSingleNight([]), 0.0);
    });

    test('single drink returns its points', () {
      final entry = _entry(
        timestamp: DateTime(2024, 6, 15, 20, 0),
        points: 5.0,
      );
      expect(BadgeUtils.calculateMaxSingleNight([entry]), 5.0);
    });

    test('two drinks same night are summed', () {
      final t1 = DateTime(2024, 6, 15, 20, 0);
      final t2 = DateTime(2024, 6, 15, 23, 0);
      final drinks = [
        _entry(timestamp: t1, points: 3.0),
        _entry(timestamp: t2, points: 4.0),
      ];
      expect(BadgeUtils.calculateMaxSingleNight(drinks), 7.0);
    });

    test('drink before 06:00 belongs to previous night', () {
      // Night of June 15 → June 16 early-morning drinks still count
      final eveningDrink = DateTime(2024, 6, 15, 22, 0);
      final earlyMorningDrink = DateTime(2024, 6, 16, 2, 0); // same night
      final nextEvening = DateTime(2024, 6, 16, 21, 0); // different night
      final drinks = [
        _entry(timestamp: eveningDrink, points: 5.0),
        _entry(timestamp: earlyMorningDrink, points: 3.0),
        _entry(timestamp: nextEvening, points: 2.0),
      ];
      // Night of June 15: 5 + 3 = 8; Night of June 16: 2 → max = 8
      expect(BadgeUtils.calculateMaxSingleNight(drinks), 8.0);
    });

    test('returns the highest night, not a total', () {
      final night1 = _entry(timestamp: DateTime(2024, 6, 14, 20, 0), points: 2.0);
      final night2a = _entry(timestamp: DateTime(2024, 6, 15, 20, 0), points: 6.0);
      final night2b = _entry(timestamp: DateTime(2024, 6, 15, 22, 0), points: 5.0);
      final drinks = [night1, night2a, night2b];
      expect(BadgeUtils.calculateMaxSingleNight(drinks), 11.0);
    });
  });

  // -------------------------------------------------------------------------
  // isTimeInRange
  // -------------------------------------------------------------------------
  group('BadgeUtils.isTimeInRange', () {
    // Normal (non-overnight) ranges
    test('time within normal range', () {
      expect(BadgeUtils.isTimeInRange('14:00', '12:00', '18:00'), isTrue);
    });

    test('time equals start of normal range', () {
      expect(BadgeUtils.isTimeInRange('12:00', '12:00', '18:00'), isTrue);
    });

    test('time equals end of normal range', () {
      expect(BadgeUtils.isTimeInRange('18:00', '12:00', '18:00'), isTrue);
    });

    test('time outside normal range (before start)', () {
      expect(BadgeUtils.isTimeInRange('09:00', '12:00', '18:00'), isFalse);
    });

    test('time outside normal range (after end)', () {
      expect(BadgeUtils.isTimeInRange('20:00', '12:00', '18:00'), isFalse);
    });

    // Overnight ranges
    test('time within overnight range (late night)', () {
      expect(BadgeUtils.isTimeInRange('23:30', '22:00', '02:00'), isTrue);
    });

    test('time within overnight range (early morning)', () {
      expect(BadgeUtils.isTimeInRange('01:00', '22:00', '02:00'), isTrue);
    });

    test('time equals start of overnight range', () {
      expect(BadgeUtils.isTimeInRange('22:00', '22:00', '02:00'), isTrue);
    });

    test('time equals end of overnight range', () {
      expect(BadgeUtils.isTimeInRange('02:00', '22:00', '02:00'), isTrue);
    });

    test('time outside overnight range (middle of day)', () {
      expect(BadgeUtils.isTimeInRange('12:00', '22:00', '02:00'), isFalse);
    });
  });
}

extension on DateTime {
  DateTime copyWith({int? hour, int? minute}) {
    return DateTime(year, month, day, hour ?? this.hour, minute ?? this.minute);
  }
}
