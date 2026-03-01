import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/core/services/drink_data_service.dart';

void main() {
  final service = DrinkDataService.instance;

  // -------------------------------------------------------------------------
  // resolve
  // -------------------------------------------------------------------------
  group('DrinkDataService.resolve', () {
    test('returns correct data for known category id', () {
      final result = service.resolve({'categoryId': 'beer'});
      expect(result.id, 'beer');
      expect(result.name, isNotEmpty);
      expect(result.emoji, isNotEmpty);
    });

    test('returns fallback category for unknown id', () {
      // Should fall back to drinkCategories.first without throwing
      final result = service.resolve({'categoryId': 'does-not-exist'});
      expect(result.id, isNotEmpty);
    });

    test('wine with variety sets subtitle to variety in uppercase', () {
      final result = service.resolve({
        'categoryId': 'wine',
        'variety': 'Rosé',
      });
      expect(result.subtitle, 'ROSÉ');
    });

    test('non-wine with portion sets subtitle to portion name in uppercase', () {
      final result = service.resolve({
        'categoryId': 'beer',
        'portion': {'name': '500ml', 'volume': 500},
      });
      expect(result.subtitle, '500ML');
    });

    test('no variety or portion leaves subtitle null', () {
      final result = service.resolve({'categoryId': 'vodka'});
      expect(result.subtitle, isNull);
    });

    test('resolved category is stored in result', () {
      final result = service.resolve({'categoryId': 'whiskey'});
      expect(result.category, isNotNull);
      expect(result.category!.id, 'whiskey');
    });
  });

  // -------------------------------------------------------------------------
  // resolveFromId
  // -------------------------------------------------------------------------
  group('DrinkDataService.resolveFromId', () {
    test('returns same result as resolve with just categoryId', () {
      final a = service.resolveFromId('raki');
      final b = service.resolve({'categoryId': 'raki'});
      expect(a.id, b.id);
      expect(a.name, b.name);
      expect(a.emoji, b.emoji);
    });

    test('works for every built-in drink category without throwing', () {
      const knownIds = [
        'beer', 'wine', 'raki', 'whiskey', 'vodka',
        'gin', 'tequila', 'rum', 'cocktail', 'champagne',
        'liqueur', 'shot', 'custom',
      ];
      for (final id in knownIds) {
        expect(
          () => service.resolveFromId(id),
          returnsNormally,
          reason: 'resolveFromId($id) should not throw',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Singleton
  // -------------------------------------------------------------------------
  group('DrinkDataService singleton', () {
    test('instance is the same object across calls', () {
      expect(identical(DrinkDataService.instance, DrinkDataService.instance), isTrue);
    });
  });
}
