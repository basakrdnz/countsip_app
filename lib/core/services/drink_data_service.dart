import 'package:flutter/material.dart';
import '../../data/drink_categories.dart';
import '../../data/models/drink_category_model.dart';
import '../theme/app_icons.dart';

class DrinkDisplayData {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final String? imagePath;
  final String? subtitle;
  final DrinkCategory? category;
  final DrinkPortion? portion;

  DrinkDisplayData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    this.imagePath,
    this.subtitle,
    this.category,
    this.portion,
  });
}

class DrinkDataService {
  static final DrinkDataService instance = DrinkDataService._internal();
  DrinkDataService._internal();

  /// Resolves a JSON config (e.g. from SharedPreferences quick-add) into
  /// display-ready data by looking up the typed [DrinkCategory] list.
  DrinkDisplayData resolve(Map<String, dynamic> config) {
    final String categoryId = config['categoryId'];
    final category = drinkCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => drinkCategories.first,
    );

    String name = category.name;
    String emoji = category.emoji;
    String? imagePath = category.image;
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
      category: category,
    );
  }

  /// Resolves a category by [id] alone, without any variety or portion context.
  /// Equivalent to `resolve({'categoryId': id})`.
  DrinkDisplayData resolveFromId(String id) {
    return resolve({'categoryId': id});
  }

  /// Resolves by Turkish display name (e.g. 'Şarap', 'Bira').
  /// Falls back to resolveFromId if name is not recognized.
  DrinkDisplayData resolveFromName(String name) {
    const nameToId = <String, String>{
      'bira': 'beer',
      'şarap': 'wine',
      'rakı': 'raki',
      'viski': 'whiskey',
      'votka': 'vodka',
      'cin': 'gin',
      'cin tonik': 'gin',
      'tekila': 'tequila',
      'rom': 'rum',
      'kokteyl': 'cocktail',
      'likör': 'liqueur',
    };
    final id = nameToId[name.toLowerCase().trim()] ?? '';
    if (id.isNotEmpty) return resolveFromId(id);
    // Last resort: search categories by name
    final match = drinkCategories.where(
      (c) => c.name.toLowerCase() == name.toLowerCase().trim(),
    ).firstOrNull;
    if (match != null) return resolveFromId(match.id);
    return resolveFromId('cocktail');
  }

  /// Smart resolve: tries categoryId first, then falls back to drinkType name.
  /// Pass the RAW categoryId (may be null for old entries).
  DrinkDisplayData smartResolve({required String? categoryId, required String drinkType}) {
    // If categoryId is a known id, use it directly
    if (categoryId != null) {
      final known = drinkCategories.any((c) => c.id == categoryId);
      if (known) return resolveFromId(categoryId);
    }
    // Otherwise resolve by Turkish display name
    return resolveFromName(drinkType);
  }
}


