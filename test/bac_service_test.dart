import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/core/services/bac_service.dart';

/// Helper: create a drink map with the given alcohol volume and timestamp.
Map<String, dynamic> _drink({
  required double volumeMl,
  required double abvPercent,
  required DateTime timestamp,
}) {
  return {
    'volume': volumeMl,
    'abv': abvPercent,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

void main() {
  // Standard male profile used across most tests
  const double weightKg = 80.0;
  const double heightCm = 180.0;
  const int age = 30;
  const String male = 'male';
  const String female = 'female';

  group('BacService.calculateDynamicBac – edge cases', () {
    test('empty drink list returns zero BAC', () {
      final result = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [],
      );
      expect(result.min, 0.0);
      expect(result.max, 0.0);
      expect(result.isZero, isTrue);
      expect(result.trend, BacTrend.stable);
    });

    test('zero weight returns zero BAC', () {
      final result = BacService.calculateDynamicBac(
        weightKg: 0,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 330, abvPercent: 5, timestamp: DateTime.now())],
      );
      expect(result.min, 0.0);
      expect(result.max, 0.0);
    });

    test('drink in the future is ignored', () {
      final result = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 500, abvPercent: 5, timestamp: DateTime.now().add(const Duration(hours: 2)))],
      );
      expect(result.isZero, isTrue);
    });
  });

  group('BacService.calculateDynamicBac – absorption & elimination', () {
    test('drink consumed now produces positive BAC', () {
      final result = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 330, abvPercent: 5, timestamp: DateTime.now())],
      );
      expect(result.max, greaterThan(0.0));
    });

    test('BAC is lower 4 hours after single drink compared to just after', () {
      final recentResult = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 500, abvPercent: 5, timestamp: DateTime.now().subtract(const Duration(minutes: 60)))],
      );
      final laterResult = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 500, abvPercent: 5, timestamp: DateTime.now().subtract(const Duration(hours: 4)))],
      );
      // BAC should decrease over time
      expect(recentResult.average, greaterThanOrEqualTo(laterResult.average));
    });

    test('more drinks produce higher BAC than fewer drinks', () {
      final now = DateTime.now().subtract(const Duration(minutes: 30));
      final singleDrink = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 330, abvPercent: 5, timestamp: now)],
      );
      final fiveDrinks = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: List.generate(5, (_) => _drink(volumeMl: 330, abvPercent: 5, timestamp: now)),
      );
      expect(fiveDrinks.average, greaterThan(singleDrink.average));
    });

    test('high ABV drink produces higher BAC than low ABV drink (same volume)', () {
      final now = DateTime.now().subtract(const Duration(minutes: 30));
      final lowAbv = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 50, abvPercent: 5, timestamp: now)],
      );
      final highAbv = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 50, abvPercent: 40, timestamp: now)],
      );
      expect(highAbv.average, greaterThan(lowAbv.average));
    });
  });

  group('BacService.calculateDynamicBac – gender differences (Watson Formula)', () {
    test('female gets higher BAC than male for same drinks (lower TBW)', () {
      final now = DateTime.now().subtract(const Duration(minutes: 30));
      final drinkList = [_drink(volumeMl: 330, abvPercent: 5, timestamp: now)];

      final maleResult = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: drinkList,
      );
      final femaleResult = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: female,
        drinks: drinkList,
      );
      // Female TBW is generally lower, so BAC should be higher
      expect(femaleResult.average, greaterThan(maleResult.average));
    });

    test('Turkish gender label kadın works same as female', () {
      final now = DateTime.now().subtract(const Duration(minutes: 30));
      final drinkList = [_drink(volumeMl: 330, abvPercent: 5, timestamp: now)];

      final femaleEn = BacService.calculateDynamicBac(
        weightKg: weightKg, heightCm: heightCm, age: age,
        gender: 'female', drinks: drinkList,
      );
      final femaleTr = BacService.calculateDynamicBac(
        weightKg: weightKg, heightCm: heightCm, age: age,
        gender: 'kadın', drinks: drinkList,
      );
      expect(femaleTr.average, closeTo(femaleEn.average, 0.001));
    });
  });

  group('BacResult.statusLabel', () {
    BacResult _resultWithAvg(double avg) => BacResult(
          min: avg - 0.01,
          max: avg + 0.01,
          trend: BacTrend.stable,
        );

    test('< 0.2 → AYIK', () {
      expect(_resultWithAvg(0.1).statusLabel, 'AYIK');
    });

    test('0.2–0.5 → KEYİFLİ', () {
      expect(_resultWithAvg(0.3).statusLabel, 'KEYİFLİ');
    });

    test('0.5–0.8 → ÇAKIRKEYİF', () {
      expect(_resultWithAvg(0.6).statusLabel, 'ÇAKIRKEYİF');
    });

    test('0.8–1.2 → SARHOŞ', () {
      expect(_resultWithAvg(1.0).statusLabel, 'SARHOŞ');
    });

    test('1.2–2.0 → ÇOK SARHOŞ', () {
      expect(_resultWithAvg(1.5).statusLabel, 'ÇOK SARHOŞ');
    });

    test('>= 2.0 → RİSKLİ', () {
      expect(_resultWithAvg(2.5).statusLabel, 'RİSKLİ');
    });
  });

  group('BacResult.recoveryPercentage', () {
    test('returns 0.0 when peak is negligible', () {
      final result = BacResult(min: 0, max: 0, trend: BacTrend.stable);
      expect(result.recoveryPercentage, 0.0);
    });

    test('returns 0.0 when current equals peak', () {
      final result = BacResult(
        min: 0.49,
        max: 0.51,
        trend: BacTrend.stable,
        dailyPeak: (min: 0.49, max: 0.51),
      );
      expect(result.recoveryPercentage, closeTo(0.0, 0.01));
    });

    test('returns positive when current is below peak', () {
      final result = BacResult(
        min: 0.24,
        max: 0.26,
        trend: BacTrend.falling,
        dailyPeak: (min: 0.49, max: 0.51),
      );
      expect(result.recoveryPercentage, greaterThan(0.0));
      expect(result.recoveryPercentage, lessThanOrEqualTo(1.0));
    });

    test('clamps to 1.0 maximum', () {
      final result = BacResult(
        min: 0.0,
        max: 0.01,
        trend: BacTrend.stable,
        dailyPeak: (min: 0.9, max: 1.1),
      );
      expect(result.recoveryPercentage, lessThanOrEqualTo(1.0));
    });
  });

  group('BacResult.trend', () {
    test('trend is included in result', () {
      final now = DateTime.now().subtract(const Duration(minutes: 10));
      final result = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 330, abvPercent: 5, timestamp: now)],
      );
      // Trend should be one of the valid enum values
      expect(BacTrend.values, contains(result.trend));
    });
  });

  group('BacResult.dailyPeak', () {
    test('daily peak is always >= current BAC', () {
      final now = DateTime.now().subtract(const Duration(minutes: 30));
      final result = BacService.calculateDynamicBac(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: male,
        drinks: [_drink(volumeMl: 330, abvPercent: 5, timestamp: now)],
      );
      if (result.dailyPeak != null) {
        expect(result.peakAverage, greaterThanOrEqualTo(result.average - 0.001));
      }
    });
  });
}
