import 'package:cloud_firestore/cloud_firestore.dart';

class BacService {
  // Widmark constants
  static const double _densityAlcohol = 0.789; // g/ml
  static const double _rMale = 0.68;
  static const double _rFemale = 0.55;
  static const double _eliminationRate = 0.015; // % per hour

  /// Calculates the current Blood Alcohol Content (BAC).
  /// 
  /// [weightKg]: User's weight in kilograms.
  /// [gender]: 'Male' or 'Female' (case-insensitive). Defaults to Male if unknown.
  /// [drinks]: List of drink entries. Each entry must have 'timestamp' (DateTime), 'volume' (ml), and 'abv' (%).
  static double calculateBac({
    required double weightKg,
    required String gender,
    required List<Map<String, dynamic>> drinks,
  }) {
    if (weightKg <= 0) return 0.0;

    double r = (gender.toLowerCase() == 'female' || gender.toLowerCase() == 'kadın') ? _rFemale : _rMale;
    double totalAlcoholGrams = 0.0;
    double currentBac = 0.0;

    // Filter drinks from the last 24 hours only, as older drinks definitely eliminated
    final now = DateTime.now();
    final recentDrinks = drinks.where((d) {
      final timestamp = (d['timestamp'] as Timestamp).toDate();
      return now.difference(timestamp).inHours < 24;
    }).toList();

    // Sort by time (oldest first) to simulate accumulation vs elimination? 
    // Actually, Widmark is usually applied to total alcohol consumed in a period minus elimination over that period.
    // However, a more accurate way for a sequence of drinks is to calculate contribution of each drink remaining.
    // But standard simple accumulation: Total Alcohol / Body Water - (Rate * Time from start)
    // Time from start is tricky with multiple drinks.
    
    // Better approach: Calculate BAC contribution of each drink at NOW, assuming linear elimination started effectively when drink was consumed (or shortly after).
    // Sum positive contributions.
    
    for (var drink in recentDrinks) {
      final timestamp = (drink['timestamp'] as Timestamp).toDate();
      final volume = (drink['volume'] ?? 0).toDouble(); // ml
      final abv = (drink['abv'] ?? 0).toDouble(); // % (e.g., 5.0)
      
      // Calculate alcohol in grams for this drink
      final alcoholGrams = volume * (abv / 100.0) * _densityAlcohol;
      
      // Calculate theoretical max BAC increase from this drink
      // BAC Increase = Alcohol (g) / (Weight (kg) * 1000 * r) * 100
      // formula simplification: Alcohol (g) / (Weight (kg) * r) * 0.1? No.
      // Widmark: c = A / (m * r)
      // A in grams. m in kg -> c in g/kg (promil).
      // So simple: A / (Weight * r) gives Promil directly (g/kg ~ g/L blood approx).
      
      final peakBacIncrease = alcoholGrams / (weightKg * r);
      
      // Calculate time elapsed since this drink
      final hoursElapsed = now.difference(timestamp).inMinutes / 60.0;
      
      // Remaining BAC from this drink = Peak - (Elimination * Time)
      // Note: Elimination is total system elimination.
      // Doing it per drink is mathematically equivalent to Total Alcohol - Total Elimination Time? 
      // Not exactly. If you drank 10 hours ago, that drink is gone. It doesn't reduce the BAC of a drink you had 1 min ago.
      // So `max(0, contribution)` is correct for each drink independently? 
      // Actually, elimination is constant regardless of concentration (Zero-order kinetics).
      // So we should calculate Total Alcohol consumed in window, and Total Time?
      // No, "Total Time" is ambiguous.
      
      // Correct standard method for sequential drinking:
      // 1. Calculate Peak BAC for EACH drink as if consumed instantly.
      // 2. Sum them up to get "Theoretical Max BAC if no elimination occurred".
      // 3. Subtract Elimination Rate * (Time since FIRST drink).
      // Requirement: Only if BAC > 0.
      
      // Let's try:
      // Find easiest start time (time of first drink in the sequence that could potentially still be in system).
      // Actually, if we just sum (Alcohol / (W*r)) - (beta * t_elapsed) for each drink? 
      // No, elimination is not per drink. It's per body. 
      // 0.015 per hour is total reduction capacity.
      
      // Let's use the standard "Current BAC" accumulation.
      // We look at the timeline.
      // But for a simple effective estimate:
      // Calculate total alcohol of relevant drinks.
      // Calculate time from First Drink of the active session.
      // What is the "active session"?
      // If I drank 20 hours ago, that's done. I drank 1 hour ago.
      // The 20h ago drink should not contribute, but its "elimination time" should not subtract from the recent drink.
      
      // Algorithm:
      // Iterate drinks chronologically.
      // Add drink's BAC increase.
      // Subtract elimination for time diff between drinks.
      // Clamp to 0.
      
      // Sorted drinks needed.
      recentDrinks.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));
    }
    
    // Pass 2: Calculation with chronological simulation
    double runningBac = 0.0;
    DateTime? lastTime;
    
    for (var drink in recentDrinks) {
      final timestamp = (drink['timestamp'] as Timestamp).toDate();
      final volume = (drink['volume'] ?? 0).toDouble();
      final abv = (drink['abv'] ?? 0).toDouble();
      final alcoholGrams = volume * (abv / 100.0) * _densityAlcohol;
      final bacIncrease = alcoholGrams / (weightKg * r); // Promil
      
      if (lastTime != null) {
        // Eliminate for time passed since last update
        final hoursPassed = timestamp.difference(lastTime).inMinutes / 60.0;
        runningBac -= (hoursPassed * _eliminationRate);
        if (runningBac < 0) runningBac = 0;
      }
      
      // Add new drink
      runningBac += bacIncrease;
      lastTime = timestamp;
    }
    
    // Eliminate for time since last drink until NOW
    if (lastTime != null) {
      final hoursSinceLast = now.difference(lastTime).inMinutes / 60.0;
      runningBac -= (hoursSinceLast * _eliminationRate);
    }
    
    if (runningBac < 0) runningBac = 0;
    
    return runningBac;
  }
}
