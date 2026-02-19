import 'package:flutter/material.dart';
import '../../data/drink_categories.dart';
import '../theme/app_icons.dart';

class DrinkDisplayData {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final String? imagePath;
  final String? subtitle;
  final Map<String, dynamic>? config;

  DrinkDisplayData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
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

    IconData getIconForId(String id) {
      switch (id) {
        case 'beer': return AppIcons.drinkBeer;
        case 'wine': return AppIcons.drinkWine;
        case 'raki': return AppIcons.drinkGlass;
        case 'whiskey': return AppIcons.drinkGlass;
        case 'vodka': return AppIcons.drinkCocktail;
        case 'gin': return AppIcons.drinkCocktail;
        case 'tequila': return AppIcons.drinkGlass;
        case 'rum': return AppIcons.drinkGlass;
        case 'cocktail': return AppIcons.drinkCocktail;
        case 'liqueur': return AppIcons.drinkLiquor;
        case 'custom': return AppIcons.drinkCustom;
        default: return AppIcons.drinkGlass;
      }
    }

    return DrinkDisplayData(
      id: categoryId,
      name: name,
      emoji: emoji,
      icon: getIconForId(categoryId),
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

