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
      'createdAt': FieldValue.serverTimestamp(),
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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DrinkEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      drinkType: data['drinkType'] ?? '',
      drinkEmoji: data['drinkEmoji'] ?? '',
      portion: data['portion'] ?? '',
      volume: data['volume'] ?? 0,
      abv: (data['abv'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      points: (data['points'] ?? 0).toDouble(),
      note: data['note'] ?? '',
      locationName: data['locationName'] ?? '',
      intoxicationLevel: data['intoxicationLevel'] ?? 0,
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
