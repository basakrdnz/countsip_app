import 'package:flutter/material.dart';

enum BadgeCategory {
  consumption, // Tüketim
  variety, // Çeşittilik
  social, // Sosyal
  location, // Konum
  photo, // Fotoğraf
  streak, // Süreklilik
  special, // Özel
}

enum BadgeRarity {
  common, // Yaygın
  uncommon, // Nadir değil
  rare, // Nadir
  epic, // Epik
  legendary, // Efsanevi
}

enum BadgeCondition {
  totalAPS, // Toplam APS
  categoryAPS, // Kategori APS (beer, wine, etc.)
  singleNightAPS, // Tek gece APS
  drinkVariety, // Farklı içki sayısı
  cocktailVariety, // Farklı kokteyl sayısı
  friendCount, // Arkadaş sayısı
  locationCount, // Farklı mekan sayısı
  photoCount, // Fotoğraf sayısı
  streakDays, // Ardışık gün sayısı
  specificDate, // Belirli tarih
  timeOfDay, // Günün belirli saati
  leaderboardRank, // Sıralama
  firstNUsers, // İlk N kullanıcı
  allBadges, // Tüm rozetler
}

class Badge {
  final String id; // Unique ID
  final String name; // Rozet adı (TR)
  final String nameEn; // Rozet adı (EN)
  final IconData icon; // Material IconData
  final String description; // Açıklama
  final String descriptionEn; // English Description
  final BadgeCategory category; // Kategori
  final BadgeRarity rarity; // Nadirlik
  final String colorHex; // Renk kodu (hex)
  final BadgeCondition condition; // Kazanma koşulu

  // Koşul parametreleri
  final double? requiredAPS; // Gerekli APS (null ise koşul değil)
  final String? requiredCategory; // Gerekli kategori (beer, wine, etc.)
  final int? requiredCount; // Gerekli sayı (streak, variety, etc.)
  final DateTime? requiredDate; // Gerekli tarih (MM-DD format as DateTime usually)
  final String? requiredTimeStart; // Gerekli saat başlangıç (HH:mm)
  final String? requiredTimeEnd; // Gerekli saat bitiş (HH:mm)

  // Kullanıcı durumu (These might be handled outside or as part of a UserBadge model)
  final bool isUnlocked; // Kazanıldı mı?
  final DateTime? unlockDate; // Kazanılma tarihi
  final double progress; // İlerleme yüzdesi (0.0 - 1.0)

  Badge({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.description,
    required this.descriptionEn,
    required this.category,
    required this.rarity,
    required this.colorHex,
    required this.condition,
    this.requiredAPS,
    this.requiredCategory,
    this.requiredCount,
    this.requiredDate,
    this.requiredTimeStart,
    this.requiredTimeEnd,
    this.isUnlocked = false,
    this.unlockDate,
    this.progress = 0.0,
  });

  Badge copyWith({
    bool? isUnlocked,
    DateTime? unlockDate,
    double? progress,
  }) {
    return Badge(
      id: id,
      name: name,
      nameEn: nameEn,
      icon: icon,
      description: description,
      descriptionEn: descriptionEn,
      category: category,
      rarity: rarity,
      colorHex: colorHex,
      condition: condition,
      requiredAPS: requiredAPS,
      requiredCategory: requiredCategory,
      requiredCount: requiredCount,
      requiredDate: requiredDate,
      requiredTimeStart: requiredTimeStart,
      requiredTimeEnd: requiredTimeEnd,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockDate: unlockDate ?? this.unlockDate,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'description': description,
      'descriptionEn': descriptionEn,
      'category': category.name,
      'rarity': rarity.name,
      'colorHex': colorHex,
      'condition': condition.name,
      'requiredAPS': requiredAPS,
      'requiredCategory': requiredCategory,
      'requiredCount': requiredCount,
      'requiredDate': requiredDate?.toIso8601String(),
      'requiredTimeStart': requiredTimeStart,
      'requiredTimeEnd': requiredTimeEnd,
    };
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'],
      name: map['name'],
      nameEn: map['nameEn'],
      icon: map['iconCodePoint'] != null 
          ? IconData(
              map['iconCodePoint'], 
              fontFamily: map['iconFontFamily'], 
              fontPackage: map['iconFontPackage']
            )
          : Icons.emoji_events_rounded, // Fallback for old records where 'icon' was a string emoji
      description: map['description'],
      descriptionEn: map['descriptionEn'],
      category: BadgeCategory.values.byName(map['category']),
      rarity: BadgeRarity.values.byName(map['rarity']),
      colorHex: map['colorHex'],
      condition: BadgeCondition.values.byName(map['condition']),
      requiredAPS: map['requiredAPS']?.toDouble(),
      requiredCategory: map['requiredCategory'],
      requiredCount: map['requiredCount'],
      requiredDate: map['requiredDate'] != null ? DateTime.parse(map['requiredDate']) : null,
      requiredTimeStart: map['requiredTimeStart'],
      requiredTimeEnd: map['requiredTimeEnd'],
    );
  }
}
