import 'package:cloud_firestore/cloud_firestore.dart';

class DrinkEntry {
  final String id;
  final String userId;
  final String drinkType;
  final String drinkEmoji;
  final String portion;
  final int volume;
  final double abv;
  final int quantity;
  final double points;
  final String note;
  final String locationName;
  final int intoxicationLevel;
  final DateTime timestamp;
  final DateTime createdAt;
  final bool hasImage;
  final String? imagePath;
  // Additional fields for location and social
  final double? latitude;
  final double? longitude;
  final String? locationType;
  final String? city;
  final String? country;
  final List<String>? friendIds;

  DrinkEntry({
    required this.id,
    required this.userId,
    required this.drinkType,
    required this.drinkEmoji,
    required this.portion,
    required this.volume,
    required this.abv,
    required this.quantity,
    required this.points,
    required this.note,
    required this.locationName,
    required this.intoxicationLevel,
    required this.timestamp,
    required this.createdAt,
    required this.hasImage,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.locationType,
    this.city,
    this.country,
    this.friendIds,
  });

  DrinkEntry copyWith({
    String? id,
    String? userId,
    String? drinkType,
    String? drinkEmoji,
    String? portion,
    int? volume,
    double? abv,
    int? quantity,
    double? points,
    String? note,
    String? locationName,
    int? intoxicationLevel,
    DateTime? timestamp,
    DateTime? createdAt,
    bool? hasImage,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? locationType,
    String? city,
    String? country,
    List<String>? friendIds,
  }) {
    return DrinkEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      drinkType: drinkType ?? this.drinkType,
      drinkEmoji: drinkEmoji ?? this.drinkEmoji,
      portion: portion ?? this.portion,
      volume: volume ?? this.volume,
      abv: abv ?? this.abv,
      quantity: quantity ?? this.quantity,
      points: points ?? this.points,
      note: note ?? this.note,
      locationName: locationName ?? this.locationName,
      intoxicationLevel: intoxicationLevel ?? this.intoxicationLevel,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      hasImage: hasImage ?? this.hasImage,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationType: locationType ?? this.locationType,
      city: city ?? this.city,
      country: country ?? this.country,
      friendIds: friendIds ?? this.friendIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'drinkType': drinkType,
      'drinkEmoji': drinkEmoji,
      'portion': portion,
      'volume': volume,
      'abv': abv,
      'quantity': quantity,
      'points': points,
      'note': note,
      'locationName': locationName,
      'intoxicationLevel': intoxicationLevel,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'hasImage': hasImage,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'locationType': locationType,
      'city': city,
      'country': country,
      'friendIds': friendIds,
    };
  }

  factory DrinkEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DrinkEntry.fromMap(doc.id, data);
  }

  /// Creates a [DrinkEntry] from a raw Firestore data map.
  /// The [id] is the document ID, which is typically stored in [data] as 'id'.
  factory DrinkEntry.fromMap(String id, Map<String, dynamic> data) {
    return DrinkEntry(
      id: id,
      userId: data['userId'] ?? '',
      drinkType: data['drinkType'] ?? '',
      drinkEmoji: data['drinkEmoji'] ?? '',
      portion: data['portion'] ?? '',
      volume: (data['volume'] as num?)?.toInt() ?? 0,
      abv: (data['abv'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toDouble() ?? 0.0,
      note: data['note'] ?? '',
      locationName: data['locationName'] ?? '',
      intoxicationLevel: (data['intoxicationLevel'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasImage: data['hasImage'] ?? false,
      imagePath: data['imagePath'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationType: data['locationType'],
      city: data['city'],
      country: data['country'],
      friendIds: data['friendIds'] != null ? List<String>.from(data['friendIds']) : null,
    );
  }
}
