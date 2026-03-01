import 'dart:math' as math;
import '../../data/models/drink_entry_model.dart';

enum BacTrend { rising, falling, stable }

class BacResult {
  final double min;
  final double max;
  final BacTrend trend;
  final ({double min, double max})? dailyPeak;

  BacResult({
    required this.min, 
    required this.max, 
    required this.trend,
    this.dailyPeak,
  });

  double get average => (min + max) / 2;
  double get peakAverage => dailyPeak != null ? (dailyPeak!.min + dailyPeak!.max) / 2 : average;
  
  /// Percentage recovery since peak (0.0 to 1.0)
  double get recoveryPercentage {
    if (peakAverage <= 0.01) return 0.0;
    final drop = 1.0 - (average / peakAverage);
    return drop.clamp(0.0, 1.0);
  }

  bool get isZero => max <= 0.01; // Tiny threshold for practical zero

  String get statusLabel {
    final val = average;
    if (val < 0.2) return 'AYIK';
    if (val < 0.5) return 'KEYİFLİ';
    if (val < 0.8) return 'ÇAKIRKEYİF';
    if (val < 1.2) return 'SARHOŞ';
    if (val < 2.0) return 'ÇOK SARHOŞ';
    return 'RİSKLİ';
  }

  String get statusDescription {
    final val = average;
    if (val < 0.2) return 'Kendinden emin ve zindesin.';
    if (val < 0.5) return 'Hafif bir gevşeme ve neşe hali.';
    if (val < 0.8) return 'Konuşkanlık artıyor, refleksler yavaşlıyor.';
    if (val < 1.2) return 'Dikkat ve denge kaybı belirginleşiyor.';
    if (val < 2.0) return 'Ayakta durmak ve odaklanmak zor.';
    return 'Hemen bir mola ver ve su iç!';
  }
}

class BacService {
  // Density of ethanol in g/ml
  static const double _densityAlcohol = 0.789;

  /// Calculates a dynamic Blood Alcohol Concentration (BAC) estimate using
  /// the **Watson Formula** for Total Body Water (TBW).
  ///
  /// The Watson Formula estimates TBW based on height, weight, age, and gender:
  ///   - Female: TBW = -2.097 + 0.1069*height + 0.2466*weight
  ///   - Male:   TBW =  2.447 - 0.09516*age + 0.1074*height + 0.3362*weight
  ///
  /// BAC is then derived per-drink using a Widmark-style model:
  ///   1. Alcohol mass (g) = volume (ml) * ABV * ethanol density (0.789 g/ml)
  ///   2. Absorption follows a linear ramp over ~45 minutes
  ///   3. Elimination uses a beta range (0.012 - 0.018 per hour) to produce a
  ///      min/max BAC window
  ///
  /// Returns a [BacResult] containing the current range, trend, and daily peak.
  static BacResult calculateDynamicBac({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required List<DrinkEntry> drinks,
  }) {
    if (weightKg <= 0 || drinks.isEmpty) {
      return BacResult(min: 0, max: 0, trend: BacTrend.stable);
    }

    final now = DateTime.now();
    
    // 1. Calculate Total Body Water (TBW) using Watson Formula
    double tbw;
    final isFemale = (gender.toLowerCase() == 'female' || gender.toLowerCase() == 'kadın');
    
    if (isFemale) {
      tbw = -2.097 + (0.1069 * heightCm) + (0.2466 * weightKg);
    } else {
      tbw = 2.447 - (0.09516 * age) + (0.1074 * heightCm) + (0.3362 * weightKg);
    }

    final double distributionVolume = tbw;

      // Standard: 0.015 g/dL/h (0.15 BAC unit/h)
      const double betaMin = 0.012;
      const double betaMax = 0.018;

      // 2. Calculate for Current and Trend
      final currentRange = _calculateForTime(now, drinks, distributionVolume, betaMin, betaMax);
      final pastRange = _calculateForTime(now.subtract(const Duration(minutes: 15)), drinks, distributionVolume, betaMin, betaMax);

      // 3. Find Daily Peak
      // We simulate from the first drink until now to find the maximum point
      var dailyPeak = currentRange;
      double maxAvg = (currentRange.min + currentRange.max) / 2;

      if (drinks.isNotEmpty) {
        final firstDrinkTime = drinks.map((d) => d.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
        
        // Step through time in 15-min intervals to find peak
        DateTime runner = firstDrinkTime;
        while (runner.isBefore(now)) {
          final rangeAtTime = _calculateForTime(runner, drinks, distributionVolume, betaMin, betaMax);
          final avgAtTime = (rangeAtTime.min + rangeAtTime.max) / 2;
          if (avgAtTime > maxAvg) {
            maxAvg = avgAtTime;
            dailyPeak = rangeAtTime;
          }
          runner = runner.add(const Duration(minutes: 15));
        }
      }

      // 4. Determine Trend
      BacTrend trend = BacTrend.stable;
      final currentAvg = (currentRange.min + currentRange.max) / 2;
      final pastAvg = (pastRange.min + pastRange.max) / 2;
      final diff = currentAvg - pastAvg;
      
      if (diff > 0.005) {
        trend = BacTrend.rising;
      } else if (diff < -0.005) {
        trend = BacTrend.falling;
      }

      final cappedCurrent = _capRange(currentRange);
      final cappedPeak = dailyPeak != null ? _capRange(dailyPeak) : null;

      return BacResult(
        min: cappedCurrent.min,
        max: cappedCurrent.max,
        trend: trend,
        dailyPeak: cappedPeak,
      );
    }

    static ({double min, double max}) _capRange(({double min, double max}) range) {
      final spread = range.max - range.min;
      if (spread <= 0.25) return range;
      
      final avg = (range.min + range.max) / 2;
      return (
        min: math.max(0, avg - 0.125),
        max: avg + 0.125,
      );
    }

    /// Computes the BAC range at a specific [targetTime] by summing each
    /// drink's contribution (absorption minus elimination).
    static ({double min, double max}) _calculateForTime(
      DateTime targetTime,
      List<DrinkEntry> drinks,
      double vDist,
      double betaMin,
      double betaMax,
    ) {
      double totalAlcoholMin = 0.0;
      double totalAlcoholMax = 0.0;

      for (var drink in drinks) {
        final timestamp = drink.timestamp;
        if (timestamp.isAfter(targetTime)) continue;

        final volume = drink.volume.toDouble();
        final abv = drink.abv;
        final alcoholGrams = volume * (abv / 100.0) * _densityAlcohol;

        // Absorption Curve Model (Simple linear ramp over 45 minutes)
        // We add +5 mins buffer or allow a minimum 0.1 factor so users see *some* change immediately.
        final minsSinceDrink = targetTime.difference(timestamp).inMinutes;
        double absorptionFactor = ((minsSinceDrink + 5) / 45.0).clamp(0.1, 1.0);
        
        // Bioavailability (100% for mathematical model, but can be adjusted)
        final availableAlcohol = alcoholGrams * absorptionFactor;
        
        // Widmark logic: peak increase = A / vDist
        // (Using vDist as TBW directly gives g/kg or approx BAC units)
        final peakBac = availableAlcohol / vDist;

        // Elimination logic: Beta * hours
        final hoursSinceDrink = minsSinceDrink / 60.0;
        
        // Beta: 0.12 - 0.20 g/L per hour (Turkey standard estimation)
        totalAlcoholMin += math.max(0, peakBac - (betaMax * hoursSinceDrink * 10)); 
        totalAlcoholMax += math.max(0, peakBac - (betaMin * hoursSinceDrink * 10));
    }

    // Ensure range is never degenerate
    if (totalAlcoholMax - totalAlcoholMin < 0.05 && totalAlcoholMax > 0.1) {
       totalAlcoholMin = math.max(0, totalAlcoholMax - 0.05);
    }

    return (min: totalAlcoholMin, max: totalAlcoholMax);
  }
}
