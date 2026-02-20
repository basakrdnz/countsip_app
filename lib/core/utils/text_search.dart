import 'dart:math';

/// Utility class for fuzzy text search functionality.
/// Used by AddEntryScreen to find drink categories and portions.
class TextSearch {
  TextSearch._(); // static-only

  /// Returns the Levenshtein edit distance between [s] and [t].
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  /// Returns a similarity score in [0, 1] between two strings.
  static double similarity(String a, String b) {
    final distance = levenshtein(a.toLowerCase(), b.toLowerCase());
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - (distance / maxLen);
  }

  /// Searches [categories] for entries matching [query] using fuzzy matching.
  ///
  /// Returns up to [maxResults] category maps, sorted by similarity score.
  /// Matches are checked against category name, portion name, and variety.
  static List<Map<String, dynamic>> smartSearch(
    String query,
    List<Map<String, dynamic>> categories, {
    double threshold = 0.4,
    int maxResults = 3,
  }) {
    if (query.length < 2) return [];

    final lowerQuery = query.toLowerCase();
    final List<(Map<String, dynamic>, int)> scored = [];

    for (final cat in categories) {
      final catName = cat['name'].toString().toLowerCase();
      final catSim = similarity(lowerQuery, catName);

      if (catSim > threshold) {
        scored.add((cat, (catSim * 100).toInt()));
      }

      // Also search inside portions (name + variety).
      if (cat['portions'] != null) {
        for (final p in cat['portions'] as List<dynamic>) {
          final pName = (p['name'] ?? '').toString().toLowerCase();
          final pVariety = (p['variety'] ?? '').toString().toLowerCase();

          final sName = pName.isEmpty ? 0.0 : similarity(lowerQuery, pName);
          final sVariety =
              pVariety.isEmpty ? 0.0 : similarity(lowerQuery, pVariety);
          final bestSim = max(sName, sVariety);

          if (bestSim > threshold) {
            scored.add(({
              ...cat,
              'displayName': '${cat['name']} - ${p['name']}',
              'isPortionMatch': true,
              'selectedPortion': p,
            }, (bestSim * 100).toInt()));
          }
        }
      }
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((s) => s.$1).take(maxResults).toList();
  }
}
