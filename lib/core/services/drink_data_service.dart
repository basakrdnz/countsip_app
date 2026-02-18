import 'package:flutter/foundation.dart';
import '../../data/drink_categories.dart';

class DrinkDisplayData {
  final String id;
  final String name;
  final String emoji;
  final String? imagePath;
  final String? subtitle;
  final Map<String, dynamic>? config;

  DrinkDisplayData({
    required this.id,
    required this.name,
    required this.emoji,
    this.imagePath,
    this.subtitle,
    this.config,
  });
}

class DrinkDataService {
  static final DrinkDataService instance = DrinkDataService._internal();
  DrinkDataService._internal();

  DrinkDisplayData resolve(Map<String, dynamic> config) {
    final String categoryId = config['categoryId'];
    final category = drinkCategories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => drinkCategories.first,
    );

    String name = category['name'];
    String emoji = category['emoji'];
    String? imagePath = category['image'];
    String? subtitle;

    // Handle variety-based subtitles (e.g., Wine variety)
    if (categoryId == 'wine' && config['variety'] != null) {
      subtitle = config['variety'].toString().toUpperCase();
    } else if (config['portion'] != null) {
      subtitle = config['portion']['name'].toString().toUpperCase();
    }

    return DrinkDisplayData(
      id: categoryId,
      name: name,
      emoji: emoji,
      imagePath: imagePath,
      subtitle: subtitle,
      config: config,
    );
  }

  /// Helper for legacy list rendering where only IDs might be present
  DrinkDisplayData resolveFromId(String id) {
    return resolve({'categoryId': id});
  }
}
