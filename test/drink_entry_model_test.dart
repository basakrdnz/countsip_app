import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/data/models/drink_entry_model.dart';

DrinkEntry _sampleEntry({DateTime? timestamp, DateTime? createdAt}) {
  final ts = timestamp ?? DateTime(2024, 6, 15, 20, 0);
  final ca = createdAt ?? DateTime(2024, 6, 15, 20, 0);
  return DrinkEntry(
    id: 'entry-001',
    userId: 'user-abc',
    drinkType: 'Beer',
    drinkEmoji: '🍺',
    portion: '500ml',
    volume: 500,
    abv: 5.0,
    quantity: 2,
    points: 10.0,
    note: 'Test note',
    locationName: 'Kadıköy',
    intoxicationLevel: 2,
    timestamp: ts,
    createdAt: ca,
    hasImage: true,
    imagePath: 'entries/abc.jpg',
    latitude: 40.99,
    longitude: 29.02,
    locationType: 'bar',
    city: 'Istanbul',
    country: 'Turkey',
    friendIds: ['friend-1', 'friend-2'],
  );
}

void main() {
  // -------------------------------------------------------------------------
  // toMap
  // -------------------------------------------------------------------------
  group('DrinkEntry.toMap', () {
    test('all required fields are present', () {
      final map = _sampleEntry().toMap();
      expect(map['id'], 'entry-001');
      expect(map['userId'], 'user-abc');
      expect(map['drinkType'], 'Beer');
      expect(map['drinkEmoji'], '🍺');
      expect(map['portion'], '500ml');
      expect(map['volume'], 500);
      expect(map['abv'], 5.0);
      expect(map['quantity'], 2);
      expect(map['points'], 10.0);
      expect(map['note'], 'Test note');
      expect(map['locationName'], 'Kadıköy');
      expect(map['intoxicationLevel'], 2);
      expect(map['hasImage'], isTrue);
    });

    test('createdAt is a Timestamp (NOT FieldValue)', () {
      final map = _sampleEntry().toMap();
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('timestamp is a Timestamp', () {
      final map = _sampleEntry().toMap();
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('createdAt round-trips correctly', () {
      final original = DateTime(2024, 6, 15, 20, 0);
      final entry = _sampleEntry(createdAt: original);
      final ts = entry.toMap()['createdAt'] as Timestamp;
      expect(ts.toDate().isAtSameMomentAs(original), isTrue);
    });

    test('optional fields included when set', () {
      final map = _sampleEntry().toMap();
      expect(map['latitude'], 40.99);
      expect(map['longitude'], 29.02);
      expect(map['locationType'], 'bar');
      expect(map['city'], 'Istanbul');
      expect(map['country'], 'Turkey');
      expect(map['friendIds'], ['friend-1', 'friend-2']);
    });

    test('optional fields null when not set', () {
      final entry = DrinkEntry(
        id: 'x', userId: 'u', drinkType: 'Wine', drinkEmoji: '🍷',
        portion: '150ml', volume: 150, abv: 13.0, quantity: 1,
        points: 5.0, note: '', locationName: '', intoxicationLevel: 0,
        timestamp: DateTime.now(), createdAt: DateTime.now(), hasImage: false,
      );
      final map = entry.toMap();
      expect(map['imagePath'], isNull);
      expect(map['latitude'], isNull);
      expect(map['friendIds'], isNull);
    });
  });

  // -------------------------------------------------------------------------
  // fromFirestore
  // -------------------------------------------------------------------------
  group('DrinkEntry.fromFirestore', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    Future<DocumentSnapshot> _addDoc(Map<String, dynamic> data) async {
      final ref = await firestore.collection('entries').add(data);
      return ref.get();
    }

    test('all required fields are deserialized', () async {
      final now = DateTime(2024, 6, 15, 20, 0);
      final doc = await _addDoc({
        'userId': 'user-abc',
        'drinkType': 'Whiskey',
        'drinkEmoji': '🥃',
        'portion': '45ml',
        'volume': 45,
        'abv': 40.0,
        'quantity': 1,
        'points': 8.0,
        'note': 'Nice',
        'locationName': 'Bar X',
        'intoxicationLevel': 3,
        'timestamp': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'hasImage': false,
      });

      final entry = DrinkEntry.fromFirestore(doc);
      expect(entry.userId, 'user-abc');
      expect(entry.drinkType, 'Whiskey');
      expect(entry.volume, 45);
      expect(entry.abv, 40.0);
      expect(entry.points, 8.0);
      expect(entry.timestamp.isAtSameMomentAs(now), isTrue);
      expect(entry.createdAt.isAtSameMomentAs(now), isTrue);
      expect(entry.hasImage, isFalse);
    });

    test('missing createdAt falls back gracefully', () async {
      final doc = await _addDoc({
        'userId': 'u',
        'drinkType': 'Beer',
        'drinkEmoji': '🍺',
        'portion': '500ml',
        'volume': 500,
        'abv': 5.0,
        'quantity': 1,
        'points': 3.0,
        'note': '',
        'locationName': '',
        'intoxicationLevel': 1,
        'timestamp': Timestamp.fromDate(DateTime(2024)),
        'hasImage': false,
        // createdAt intentionally omitted
      });
      final entry = DrinkEntry.fromFirestore(doc);
      expect(entry.createdAt, isNotNull);
    });

    test('optional location fields deserialized', () async {
      final doc = await _addDoc({
        'userId': 'u', 'drinkType': 'Wine', 'drinkEmoji': '🍷',
        'portion': '150ml', 'volume': 150, 'abv': 12.0, 'quantity': 1,
        'points': 4.0, 'note': '', 'locationName': '', 'intoxicationLevel': 0,
        'timestamp': Timestamp.fromDate(DateTime(2024)),
        'createdAt': Timestamp.fromDate(DateTime(2024)),
        'hasImage': false,
        'latitude': 41.0, 'longitude': 28.9,
        'locationType': 'restaurant', 'city': 'Istanbul', 'country': 'Turkey',
        'friendIds': ['f1'],
      });

      final entry = DrinkEntry.fromFirestore(doc);
      expect(entry.latitude, 41.0);
      expect(entry.city, 'Istanbul');
      expect(entry.friendIds, ['f1']);
    });
  });

  // -------------------------------------------------------------------------
  // fromMap
  // -------------------------------------------------------------------------
  group('DrinkEntry.fromMap', () {
    test('deserializes all required fields from raw map', () {
      final now = DateTime(2024, 6, 15, 20, 0);
      final map = <String, dynamic>{
        'userId': 'user-abc',
        'drinkType': 'Beer',
        'drinkEmoji': '🍺',
        'portion': '500ml',
        'volume': 500,
        'abv': 5.0,
        'quantity': 2,
        'points': 25.0,
        'note': 'Good',
        'locationName': 'Bar',
        'intoxicationLevel': 2,
        'timestamp': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'hasImage': false,
      };
      final entry = DrinkEntry.fromMap('map-001', map);
      expect(entry.id, 'map-001');
      expect(entry.userId, 'user-abc');
      expect(entry.volume, 500);
      expect(entry.abv, 5.0);
      expect(entry.timestamp.isAtSameMomentAs(now), isTrue);
    });

    test('handles volume and abv stored as num (int/double interop)', () {
      final map = <String, dynamic>{
        'userId': 'u', 'drinkType': 'Wine', 'drinkEmoji': '🍷',
        'portion': '150ml', 'volume': 150, 'abv': 13, // int abv
        'quantity': 1, 'points': 4, // int points
        'note': '', 'locationName': '', 'intoxicationLevel': 0,
        'timestamp': Timestamp.fromDate(DateTime(2024)),
        'createdAt': Timestamp.fromDate(DateTime(2024)),
        'hasImage': false,
      };
      final entry = DrinkEntry.fromMap('x', map);
      expect(entry.abv, isA<double>());
      expect(entry.abv, 13.0);
      expect(entry.points, isA<double>());
    });

    test('fromMap and fromFirestore produce equivalent entries', () async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime(2024, 6, 15, 20, 0);
      final data = <String, dynamic>{
        'userId': 'user-abc', 'drinkType': 'Raki', 'drinkEmoji': '🥛',
        'portion': '50ml', 'volume': 50, 'abv': 45.0, 'quantity': 1,
        'points': 22.5, 'note': '', 'locationName': '', 'intoxicationLevel': 0,
        'timestamp': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'hasImage': false,
      };

      final ref = await firestore.collection('entries').add(data);
      final doc = await ref.get();

      final fromFirestore = DrinkEntry.fromFirestore(doc);
      data['id'] = doc.id;
      final fromMap = DrinkEntry.fromMap(doc.id, data);

      expect(fromFirestore.id, fromMap.id);
      expect(fromFirestore.volume, fromMap.volume);
      expect(fromFirestore.abv, fromMap.abv);
      expect(fromFirestore.timestamp, fromMap.timestamp);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------
  group('DrinkEntry.copyWith', () {
    test('unchanged fields are preserved', () {
      final original = _sampleEntry();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.points, original.points);
    });

    test('changed fields are updated', () {
      final original = _sampleEntry();
      final copy = original.copyWith(quantity: 3, points: 15.0);
      expect(copy.quantity, 3);
      expect(copy.points, 15.0);
      // Unchanged
      expect(copy.id, original.id);
      expect(copy.drinkType, original.drinkType);
    });

    test('copyWith does not mutate original', () {
      final original = _sampleEntry();
      original.copyWith(quantity: 99);
      expect(original.quantity, 2); // Unchanged
    });

    test('optional fields can be updated via copyWith', () {
      final original = _sampleEntry();
      final copy = original.copyWith(note: 'Updated note', city: 'Ankara');
      expect(copy.note, 'Updated note');
      expect(copy.city, 'Ankara');
    });
  });
}
