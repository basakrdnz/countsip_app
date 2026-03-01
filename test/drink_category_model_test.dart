import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/data/models/drink_category_model.dart';
import 'package:countsip_app/data/drink_categories.dart';

void main() {
  // -------------------------------------------------------------------------
  // DrinkPortion serialisation
  // -------------------------------------------------------------------------
  group('DrinkPortion.toJson / fromJson', () {
    test('round-trips without variety', () {
      const portion = DrinkPortion(name: 'Tek (50ml)', volume: 50, abv: 45.0);
      final json = portion.toJson();
      final restored = DrinkPortion.fromJson(json);
      expect(restored.name, portion.name);
      expect(restored.volume, portion.volume);
      expect(restored.abv, portion.abv);
      expect(restored.variety, isNull);
    });

    test('round-trips with variety', () {
      const portion =
          DrinkPortion(name: 'Kırmızı (150ml)', variety: 'Kırmızı', volume: 150, abv: 13.0);
      final json = portion.toJson();
      final restored = DrinkPortion.fromJson(json);
      expect(restored.variety, 'Kırmızı');
      expect(restored.abv, 13.0);
    });

    test('toJson does not include variety key when null', () {
      const portion = DrinkPortion(name: 'Shot', volume: 40, abv: 40.0);
      final json = portion.toJson();
      expect(json.containsKey('variety'), isFalse);
    });

    test('fromJson handles int volume stored as double', () {
      final json = {'name': 'Test', 'volume': 330.0, 'abv': 5.0};
      final portion = DrinkPortion.fromJson(json);
      expect(portion.volume, 330);
      expect(portion.volume, isA<int>());
    });
  });

  // -------------------------------------------------------------------------
  // DrinkPortion equality
  // -------------------------------------------------------------------------
  group('DrinkPortion equality', () {
    test('two identical portions are equal', () {
      const a = DrinkPortion(name: 'Shot', volume: 40, abv: 40.0);
      const b = DrinkPortion(name: 'Shot', volume: 40, abv: 40.0);
      expect(a, equals(b));
    });

    test('portions with different volumes are not equal', () {
      const a = DrinkPortion(name: 'Shot', volume: 40, abv: 40.0);
      const b = DrinkPortion(name: 'Shot', volume: 80, abv: 40.0);
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal portions', () {
      const a = DrinkPortion(name: 'Shot', volume: 40, abv: 40.0);
      const b = DrinkPortion(name: 'Shot', volume: 40, abv: 40.0);
      expect(a.hashCode, b.hashCode);
    });
  });

  // -------------------------------------------------------------------------
  // drinkCategories constant
  // -------------------------------------------------------------------------
  group('drinkCategories', () {
    test('is not empty', () {
      expect(drinkCategories, isNotEmpty);
    });

    test('every category has a non-empty id, name, emoji and portions', () {
      for (final cat in drinkCategories) {
        expect(cat.id, isNotEmpty, reason: 'id empty for ${cat.name}');
        expect(cat.name, isNotEmpty, reason: 'name empty for ${cat.id}');
        expect(cat.emoji, isNotEmpty, reason: 'emoji empty for ${cat.id}');
        expect(cat.portions, isNotEmpty, reason: 'no portions for ${cat.id}');
      }
    });

    test('every portion has a positive abv (except custom)', () {
      for (final cat in drinkCategories) {
        if (cat.id == 'custom') continue;
        for (final p in cat.portions) {
          expect(p.abv, greaterThan(0),
              reason: '${cat.id}/${p.name} has abv=${p.abv}');
          expect(p.volume, greaterThan(0),
              reason: '${cat.id}/${p.name} has volume=${p.volume}');
        }
      }
    });

    test('no duplicate category ids', () {
      final ids = drinkCategories.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('beer category has Standart variety', () {
      final beer = drinkCategories.firstWhere((c) => c.id == 'beer');
      final hasStandart = beer.portions.any((p) => p.variety == 'Standart');
      expect(hasStandart, isTrue);
    });
  });
}
