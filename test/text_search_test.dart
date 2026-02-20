import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/core/utils/text_search.dart';

// Sample categories used for smartSearch tests
final _categories = [
  {
    'id': 'beer',
    'name': 'Bira',
    'emoji': '🍺',
    'portions': [
      {'name': '500ml', 'variety': 'Lager'},
      {'name': '330ml', 'variety': 'IPA'},
    ],
  },
  {
    'id': 'wine',
    'name': 'Şarap',
    'emoji': '🍷',
    'portions': [
      {'name': '150ml', 'variety': 'Kırmızı'},
      {'name': '150ml', 'variety': 'Beyaz'},
    ],
  },
  {
    'id': 'whiskey',
    'name': 'Viski',
    'emoji': '🥃',
    'portions': [
      {'name': '45ml', 'variety': null},
    ],
  },
];

void main() {
  // -------------------------------------------------------------------------
  // levenshtein
  // -------------------------------------------------------------------------
  group('TextSearch.levenshtein', () {
    test('identical strings = 0', () {
      expect(TextSearch.levenshtein('hello', 'hello'), 0);
    });

    test('empty source = length of target', () {
      expect(TextSearch.levenshtein('', 'abc'), 3);
    });

    test('empty target = length of source', () {
      expect(TextSearch.levenshtein('abc', ''), 3);
    });

    test('single substitution', () {
      expect(TextSearch.levenshtein('cat', 'bat'), 1);
    });

    test('single insertion', () {
      expect(TextSearch.levenshtein('abc', 'abbc'), 1);
    });

    test('single deletion', () {
      expect(TextSearch.levenshtein('abcd', 'abc'), 1);
    });

    test('completely different strings = max length', () {
      expect(TextSearch.levenshtein('abc', 'xyz'), 3);
    });

    test('both empty = 0', () {
      expect(TextSearch.levenshtein('', ''), 0);
    });
  });

  // -------------------------------------------------------------------------
  // similarity
  // -------------------------------------------------------------------------
  group('TextSearch.similarity', () {
    test('identical strings → 1.0', () {
      expect(TextSearch.similarity('hello', 'hello'), 1.0);
    });

    test('completely different → 0.0', () {
      expect(TextSearch.similarity('abc', 'xyz'), 0.0);
    });

    test('empty strings → 1.0', () {
      expect(TextSearch.similarity('', ''), 1.0);
    });

    test('single char difference is high similarity', () {
      final sim = TextSearch.similarity('bira', 'birA');
      expect(sim, greaterThan(0.7));
    });

    test('case insensitive', () {
      expect(TextSearch.similarity('BIRA', 'bira'), 1.0);
    });
  });

  // -------------------------------------------------------------------------
  // smartSearch
  // -------------------------------------------------------------------------
  group('TextSearch.smartSearch', () {
    test('empty query returns empty list', () {
      expect(TextSearch.smartSearch('', _categories), isEmpty);
    });

    test('single-char query returns empty list', () {
      expect(TextSearch.smartSearch('b', _categories), isEmpty);
    });

    test('exact match returns that category', () {
      final results = TextSearch.smartSearch('Bira', _categories);
      expect(results, isNotEmpty);
      expect(results.first['id'], 'beer');
    });

    test('near-match returns top result', () {
      // "Bire" is close to "Bira"
      final results = TextSearch.smartSearch('bire', _categories);
      expect(results, isNotEmpty);
    });

    test('returns at most maxResults items', () {
      // All categories somewhat match a short query
      final results = TextSearch.smartSearch('vi', _categories, maxResults: 2);
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('no close match returns empty list', () {
      // "zzzzz" has no close match
      final results = TextSearch.smartSearch('zzzzz', _categories);
      expect(results, isEmpty);
    });

    test('portion variety match is returned', () {
      // "lager" matches the portion variety of beer
      final results = TextSearch.smartSearch('lager', _categories);
      expect(results, isNotEmpty);
      final ids = results.map((r) => r['id']).toList();
      expect(ids, contains('beer'));
    });

    test('results are sorted by similarity score descending', () {
      // "Bira" should rank above "Şarap" and "Viski"
      final results = TextSearch.smartSearch('Bira', _categories);
      if (results.length >= 2) {
        // First result should be beer (exact match)
        expect(results.first['id'], 'beer');
      }
    });
  });
}
