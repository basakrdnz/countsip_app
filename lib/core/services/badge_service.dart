import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/badge_model.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter/material.dart' hide Badge;
import '../../data/models/drink_entry_model.dart';
import 'package:intl/intl.dart';

class BadgeService {
  static final List<Badge> allBadges = [
    // 1. TÜKETİM ROZETLERİ - Kategori Bazlı
    Badge(
      id: 'beer_beginner',
      name: 'Bira Başlangıcı',
      nameEn: 'Beer Beginner',
      icon: AppIcons.drinkBeer,
      description: '50+ Bira APS puanına ulaş.',
      descriptionEn: 'Reach 50+ beer APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.common,
      colorHex: '#FFE66D',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 50,
      requiredCategory: 'Bira',
    ),
    Badge(
      id: 'beer_lover',
      name: 'Bira Aşığı',
      nameEn: 'Beer Lover',
      icon: Icons.sports_bar_outlined,
      description: '200+ Bira APS puanına ulaş.',
      descriptionEn: 'Reach 200+ beer APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFE66D',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 200,
      requiredCategory: 'Bira',
    ),
    Badge(
      id: 'beer_expert',
      name: 'Bira Uzmanı',
      nameEn: 'Beer Expert',
      icon: Icons.emoji_events_rounded,
      description: '500+ Bira APS puanına ulaş.',
      descriptionEn: 'Reach 500+ beer APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 500,
      requiredCategory: 'Bira',
    ),
    Badge(
      id: 'wine_enthusiast',
      name: 'Şarap Meraklısı',
      nameEn: 'Wine Enthusiast',
      icon: AppIcons.drinkGlass,
      description: '100+ Şarap APS puanına ulaş.',
      descriptionEn: 'Reach 100+ wine APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.common,
      colorHex: '#FFB4D4',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 100,
      requiredCategory: 'Şarap',
    ),
    Badge(
      id: 'sommelier',
      name: 'Sommelier',
      nameEn: 'Sommelier',
      icon: AppIcons.emojiCrown,
      description: '500+ Şarap APS puanına ulaş.',
      descriptionEn: 'Reach 500+ wine APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.legendary,
      colorHex: '#FFD700',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 500,
      requiredCategory: 'Şarap',
    ),
    Badge(
      id: 'raki_friend',
      name: 'Rakı Dostu',
      nameEn: 'Raki Friend',
      icon: AppIcons.drinkLiquor,
      description: '100+ Rakı APS puanına ulaş.',
      descriptionEn: 'Reach 100+ raki APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.common,
      colorHex: '#B4E4FF',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 100,
      requiredCategory: 'Rakı',
    ),
    Badge(
      id: 'raki_master',
      name: 'Rakı Ustası',
      nameEn: 'Raki Master',
      icon: AppIcons.emojiStar,
      description: '300+ Rakı APS puanına ulaş.',
      descriptionEn: 'Reach 300+ raki APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.rare,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 300,
      requiredCategory: 'Rakı',
    ),
    Badge(
      id: 'raki_legend',
      name: 'Rakı Efsanesi',
      nameEn: 'Raki Legend',
      icon: AppIcons.emojiCrown,
      description: '1000+ Rakı APS puanına ulaş.',
      descriptionEn: 'Reach 1000+ raki APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.legendary,
      colorHex: '#FFD700',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 1000,
      requiredCategory: 'Rakı',
    ),
    Badge(
      id: 'whisky_enthusiast',
      name: 'Viski Meraklısı',
      nameEn: 'Whisky Enthusiast',
      icon: AppIcons.drinkLiquor,
      description: '150+ Viski APS puanına ulaş.',
      descriptionEn: 'Reach 150+ whisky APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FF3B3B',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 150,
      requiredCategory: 'Viski',
    ),
    Badge(
      id: 'cocktail_lover',
      name: 'Kokteyl Severim',
      nameEn: 'Cocktail Lover',
      icon: AppIcons.drinkCocktail,
      description: '100+ Kokteyl APS puanına ulaş.',
      descriptionEn: 'Reach 100+ cocktail APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.common,
      colorHex: '#FFB4B4',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 100,
      requiredCategory: 'Kokteyl',
    ),
    Badge(
      id: 'cocktail_pro',
      name: 'Kokteyl Profesyoneli',
      nameEn: 'Cocktail Pro',
      icon: Icons.emoji_events_rounded,
      description: '500+ Kokteyl APS puanına ulaş.',
      descriptionEn: 'Reach 500+ cocktail APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.categoryAPS,
      requiredAPS: 500,
      requiredCategory: 'Kokteyl',
    ),

    // 1. TÜKETİM ROZETLERİ - Toplam APS
    Badge(
      id: 'first_step',
      name: 'İlk Adım',
      nameEn: 'First Step',
      icon: Icons.track_changes_rounded,
      description: 'İlk içecek kaydı (0 APS).',
      descriptionEn: 'Make your first drink record (0 APS).',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.common,
      colorHex: '#B4D4FF',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 0,
    ),
    Badge(
      id: 'beginner',
      name: 'Yeni Başlayan',
      nameEn: 'Beginner',
      icon: Icons.eco_rounded,
      description: '50 Toplam APS.',
      descriptionEn: 'Reach 50 Total APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.common,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 50,
    ),
    Badge(
      id: 'hundred_club',
      name: 'Yüzlük Kulübü',
      nameEn: 'Hundred Club',
      icon: Icons.workspace_premium_rounded,
      description: '100 Toplam APS.',
      descriptionEn: 'Reach 100 Total APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFE66D',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 100,
    ),
    Badge(
      id: 'rocket',
      name: 'Roket',
      nameEn: 'Rocket',
      icon: Icons.rocket_launch_rounded,
      description: '500 Toplam APS.',
      descriptionEn: 'Reach 500 Total APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.rare,
      colorHex: '#FF6B6B',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 500,
    ),
    Badge(
      id: 'star',
      name: 'Yıldız',
      nameEn: 'Star',
      icon: AppIcons.emojiStar,
      description: '1000 Toplam APS.',
      descriptionEn: 'Reach 1000 Total APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 1000,
    ),
    Badge(
      id: 'legend',
      name: 'Efsane',
      nameEn: 'Legend',
      icon: Icons.diamond_rounded,
      description: '5000 Toplam APS.',
      descriptionEn: 'Reach 5000 Total APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.legendary,
      colorHex: '#B4D4FF',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 5000,
    ),
    Badge(
      id: 'king_queen',
      name: 'Kral/Kraliçe',
      nameEn: 'King/Queen',
      icon: AppIcons.emojiCrown,
      description: '10000 Toplam APS.',
      descriptionEn: 'Reach 10000 Total APS points.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.legendary,
      colorHex: '#FFD700',
      condition: BadgeCondition.totalAPS,
      requiredAPS: 10000,
    ),

    // Tek Gece APS Rozetleri
    Badge(
      id: 'party_start',
      name: 'Parti Başlangıcı',
      nameEn: 'Party Start',
      icon: AppIcons.emojiParty,
      description: 'Tek gecede 100+ APS puanına ulaş.',
      descriptionEn: 'Reach 100+ APS points in a single night.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFB4D4',
      condition: BadgeCondition.singleNightAPS,
      requiredAPS: 100,
    ),
    Badge(
      id: 'fun_time',
      name: 'Eğlence Zamanı',
      nameEn: 'Fun Time',
      icon: Icons.celebration_rounded,
      description: 'Tek gecede 200+ APS puanına ulaş.',
      descriptionEn: 'Reach 200+ APS points in a single night.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.rare,
      colorHex: '#FF6B6B',
      condition: BadgeCondition.singleNightAPS,
      requiredAPS: 200,
    ),
    Badge(
      id: 'legendary_night',
      name: 'Efsane Gece',
      nameEn: 'Legendary Night',
      icon: Icons.stars_rounded,
      description: 'Tek gecede 300+ APS puanına ulaş.',
      descriptionEn: 'Reach 300+ APS points in a single night.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.singleNightAPS,
      requiredAPS: 300,
    ),
    Badge(
      id: 'fireball',
      name: 'Ateş Topu',
      nameEn: 'Fireball',
      icon: Icons.local_fire_department_rounded,
      description: 'Tek gecede 500+ APS puanına ulaş.',
      descriptionEn: 'Reach 500+ APS points in a single night.',
      category: BadgeCategory.consumption,
      rarity: BadgeRarity.legendary,
      colorHex: '#FF3B3B',
      condition: BadgeCondition.singleNightAPS,
      requiredAPS: 500,
    ),

    // 2. ÇEŞİTLİLİK ROZETLERİ
    Badge(
      id: 'drink_culture',
      name: 'İçki Kültürü',
      nameEn: 'Drink Culture',
      icon: Icons.palette_rounded,
      description: '5 farklı kategoride içecek dene.',
      descriptionEn: 'Try drinks in 5 different categories.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.uncommon,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.drinkVariety,
      requiredCount: 5,
    ),
    Badge(
      id: 'explorer',
      name: 'Kaşif',
      nameEn: 'Explorer',
      icon: Icons.map_rounded,
      description: '10 farklı içecek türü dene.',
      descriptionEn: 'Try 10 different types of drinks.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.uncommon,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.drinkVariety,
      requiredCount: 10,
    ),
    Badge(
      id: 'experiencer',
      name: 'Deneyimci',
      nameEn: 'Experiencer',
      icon: Icons.track_changes_rounded,
      description: '25 farklı içecek türü dene.',
      descriptionEn: 'Try 25 different types of drinks.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.rare,
      colorHex: '#FFE66D',
      condition: BadgeCondition.drinkVariety,
      requiredCount: 25,
    ),
    Badge(
      id: 'collector',
      name: 'Koleksiyoncu',
      nameEn: 'Collector',
      icon: Icons.emoji_events_rounded,
      description: '50 farklı içecek türü dene.',
      descriptionEn: 'Try 50 different types of drinks.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.drinkVariety,
      requiredCount: 50,
    ),
    Badge(
      id: 'connoisseur',
      name: 'Connoisseur',
      nameEn: 'Connoisseur',
      icon: Icons.diamond_rounded,
      description: '100 farklı içecek türü dene.',
      descriptionEn: 'Try 100 different types of drinks.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.legendary,
      colorHex: '#B4D4FF',
      condition: BadgeCondition.drinkVariety,
      requiredCount: 100,
    ),
    Badge(
      id: 'cocktail_enthusiast',
      name: 'Kokteyl Meraklısı',
      nameEn: 'Cocktail Enthusiast',
      icon: AppIcons.drinkCocktail,
      description: '5 farklı kokteyl dene.',
      descriptionEn: 'Try 5 different cocktails.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.common,
      colorHex: '#FFB4D4',
      condition: BadgeCondition.cocktailVariety,
      requiredCount: 5,
    ),
    Badge(
      id: 'cocktail_maestro',
      name: 'Kokteyl Maestro',
      nameEn: 'Cocktail Maestro',
      icon: AppIcons.emojiStar,
      description: '15 farklı kokteyl dene.',
      descriptionEn: 'Try 15 different cocktails.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.rare,
      colorHex: '#FFD700',
      condition: BadgeCondition.cocktailVariety,
      requiredCount: 15,
    ),
    Badge(
      id: 'mixologist',
      name: 'Mixologist',
      nameEn: 'Mixologist',
      icon: AppIcons.emojiCrown,
      description: '30 farklı kokteyl dene.',
      descriptionEn: 'Try 30 different cocktails.',
      category: BadgeCategory.variety,
      rarity: BadgeRarity.epic,
      colorHex: '#FF6B6B',
      condition: BadgeCondition.cocktailVariety,
      requiredCount: 30,
    ),

    // 3. SOSYAL ROZETLER
    Badge(
      id: 'social_start',
      name: 'Sosyal Başlangıç',
      nameEn: 'Social Start',
      icon: Icons.people_rounded,
      description: '3 arkadaş ekle.',
      descriptionEn: 'Add 3 friends.',
      category: BadgeCategory.social,
      rarity: BadgeRarity.common,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.friendCount,
      requiredCount: 3,
    ),
    Badge(
      id: 'social_butterfly',
      name: 'Sosyal Kelebek',
      nameEn: 'Social Butterfly',
      icon: Icons.people_outline_rounded,
      description: '10 arkadaş ekle.',
      descriptionEn: 'Add 10 friends.',
      category: BadgeCategory.social,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFE66D',
      condition: BadgeCondition.friendCount,
      requiredCount: 10,
    ),
    Badge(
      id: 'popular',
      name: 'Popüler',
      nameEn: 'Popular',
      icon: Icons.group_add_rounded,
      description: '25 arkadaş ekle.',
      descriptionEn: 'Add 25 friends.',
      category: BadgeCategory.social,
      rarity: BadgeRarity.rare,
      colorHex: '#FFD700',
      condition: BadgeCondition.friendCount,
      requiredCount: 25,
    ),
    Badge(
      id: 'team_player',
      name: 'Takım Oyuncusu',
      nameEn: 'Team Player',
      icon: AppIcons.drinkBeer,
      description: 'Arkadaşlarla 5 farklı gün kayıt yap.',
      descriptionEn: 'Register on 5 different days with friends.',
      category: BadgeCategory.social,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFB4D4',
      condition: BadgeCondition.friendCount, // Placeholder for logic
      requiredCount: 5,
    ),
    Badge(
      id: 'weekend_hero',
      name: 'Hafta Sonu Kahramanı',
      nameEn: 'Weekend Hero',
      icon: Icons.celebration_rounded,
      description: 'Cumartesi günü 200+ APS puanına ulaş.',
      descriptionEn: 'Reach 200+ APS points on a Saturday.',
      category: BadgeCategory.social,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFE66D',
      condition: BadgeCondition.singleNightAPS,
      requiredAPS: 200,
    ),

    // 4. KONUM ROZETLERİ
    Badge(
      id: 'traveler',
      name: 'Gezgin',
      nameEn: 'Traveler',
      icon: Icons.location_on_rounded,
      description: '5 farklı mekanda kayıt yap.',
      descriptionEn: 'Register at 5 different locations.',
      category: BadgeCategory.location,
      rarity: BadgeRarity.uncommon,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.locationCount,
      requiredCount: 5,
    ),
    Badge(
      id: 'explorer_loc',
      name: 'Keşifçi',
      nameEn: 'Explorer',
      icon: Icons.map_rounded,
      description: '15 farklı mekanda kayıt yap.',
      descriptionEn: 'Register at 15 different locations.',
      category: BadgeCategory.location,
      rarity: BadgeRarity.rare,
      colorHex: '#FFE66D',
      condition: BadgeCondition.locationCount,
      requiredCount: 15,
    ),
    Badge(
      id: 'world_tour',
      name: 'Dünya Turu',
      nameEn: 'World Tour',
      icon: Icons.public_rounded,
      description: '30 farklı mekanda kayıt yap.',
      descriptionEn: 'Register at 30 different locations.',
      category: BadgeCategory.location,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.locationCount,
      requiredCount: 30,
    ),

    // 5. FOTOĞRAF ROZETLERİ
    Badge(
      id: 'first_shot',
      name: 'İlk Kare',
      nameEn: 'First Shot',
      icon: Icons.photo_camera_rounded,
      description: 'İlk fotoğrafını ekle.',
      descriptionEn: 'Add your first photo.',
      category: BadgeCategory.photo,
      rarity: BadgeRarity.common,
      colorHex: '#B4D4FF',
      condition: BadgeCondition.photoCount,
      requiredCount: 1,
    ),
    Badge(
      id: 'photographer',
      name: 'Fotoğrafçı',
      nameEn: 'Photographer',
      icon: Icons.camera_alt_rounded,
      description: '10 fotoğraf ekle.',
      descriptionEn: 'Add 10 photos.',
      category: BadgeCategory.photo,
      rarity: BadgeRarity.uncommon,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.photoCount,
      requiredCount: 10,
    ),
    Badge(
      id: 'artist',
      name: 'Sanatçı',
      nameEn: 'Artist',
      icon: Icons.color_lens_rounded,
      description: '50 fotoğraf ekle.',
      descriptionEn: 'Add 50 photos.',
      category: BadgeCategory.photo,
      rarity: BadgeRarity.rare,
      colorHex: '#FFE66D',
      condition: BadgeCondition.photoCount,
      requiredCount: 50,
    ),

    // 6. SÜREKLİLİK ROZETLERİ (STREAK)
    Badge(
      id: 'streak_start',
      name: 'Başlangıç Günü',
      nameEn: 'Streak Start',
      icon: Icons.local_fire_department_rounded,
      description: '3 günlük seri yakala.',
      descriptionEn: 'Get a 3-day streak.',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.common,
      colorHex: '#FFE66D',
      condition: BadgeCondition.streakDays,
      requiredCount: 3,
    ),
    Badge(
      id: 'weekly_routine',
      name: 'Haftalık Rutin',
      nameEn: 'Weekly Routine',
      icon: Icons.calendar_month_rounded,
      description: '7 günlük seri yakala.',
      descriptionEn: 'Get a 7-day streak.',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.uncommon,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.streakDays,
      requiredCount: 7,
    ),
    Badge(
      id: 'monthly_habit',
      name: 'Ay Tamamı',
      nameEn: 'Monthly Habit',
      icon: Icons.fitness_center_rounded,
      description: '30 günlük seri yakala.',
      descriptionEn: 'Get a 30-day streak.',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.rare,
      colorHex: '#FFD700',
      condition: BadgeCondition.streakDays,
      requiredCount: 30,
    ),

    // 7. ÖZEL ROZETLER
    Badge(
      id: 'night_owl',
      name: 'Gece Kuşu',
      nameEn: 'Night Owl',
      icon: Icons.nights_stay_rounded,
      description: 'Gece 02:00-05:00 arası 10 kayıt yap.',
      descriptionEn: 'Make 10 records between 02:00 and 05:00 AM.',
      category: BadgeCategory.special,
      rarity: BadgeRarity.uncommon,
      colorHex: '#4ECDC4',
      condition: BadgeCondition.timeOfDay,
      requiredCount: 10,
      requiredTimeStart: '02:00',
      requiredTimeEnd: '05:00',
    ),
    Badge(
      id: 'new_year',
      name: 'Yılbaşı',
      nameEn: 'New Year',
      icon: Icons.celebration_rounded,
      description: '31 Aralık\'ta kayıt yap.',
      descriptionEn: 'Make a record on December 31st.',
      category: BadgeCategory.special,
      rarity: BadgeRarity.rare,
      colorHex: '#FFD700',
      condition: BadgeCondition.specificDate,
      requiredDate: DateTime(2026, 12, 31),
    ),
    Badge(
      id: 'happy_hour',
      name: 'Happy Hour',
      nameEn: 'Happy Hour',
      icon: Icons.location_city_rounded,
      description: '17:00-19:00 arası 15 kayıt yap.',
      descriptionEn: 'Make 15 records between 17:00 and 19:00.',
      category: BadgeCategory.special,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FF6B6B',
      condition: BadgeCondition.timeOfDay,
      requiredCount: 15,
      requiredTimeStart: '17:00',
      requiredTimeEnd: '19:00',
    ),
    Badge(
      id: 'early_bird',
      name: 'Erken Kuş',
      nameEn: 'Early Bird',
      icon: Icons.wb_sunny_rounded,
      description: 'Sabah 06:00-09:00 arası 10 kayıt yap.',
      descriptionEn: 'Make 10 records between 06:00 and 09:00 AM.',
      category: BadgeCategory.special,
      rarity: BadgeRarity.uncommon,
      colorHex: '#FFE66D',
      condition: BadgeCondition.timeOfDay,
      requiredCount: 10,
      requiredTimeStart: '06:00',
      requiredTimeEnd: '09:00',
    ),
    Badge(
      id: 'valentines',
      name: 'Sevgililer Günü',
      nameEn: 'Valentines Day',
      icon: Icons.favorite_rounded,
      description: '14 Şubat\'ta kayıt yap.',
      descriptionEn: 'Make a record on February 14th.',
      category: BadgeCategory.special,
      rarity: BadgeRarity.rare,
      colorHex: '#FF6B6B',
      condition: BadgeCondition.specificDate,
      requiredDate: DateTime(2026, 2, 14),
    ),
    Badge(
      id: 'halloween',
      name: 'Halloween',
      nameEn: 'Halloween',
      icon: Icons.sentiment_very_satisfied_rounded,
      description: '31 Ekim\'de kayıt yap.',
      descriptionEn: 'Make a record on October 31st.',
      category: BadgeCategory.special,
      rarity: BadgeRarity.rare,
      colorHex: '#FFD700',
      condition: BadgeCondition.specificDate,
      requiredDate: DateTime(2026, 10, 31),
    ),
    Badge(
      id: 'streak_two_weeks',
      name: 'İki Hafta',
      nameEn: 'Two Weeks',
      icon: Icons.bolt_rounded,
      description: '14 günlük seri yakala.',
      descriptionEn: 'Get a 14-day streak.',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.rare,
      colorHex: '#FF6B6B',
      condition: BadgeCondition.streakDays,
      requiredCount: 14,
    ),
    Badge(
      id: 'streak_three_months',
      name: 'Üç Ay',
      nameEn: 'Three Months',
      icon: Icons.emoji_events_rounded,
      description: '90 günlük seri yakala.',
      descriptionEn: 'Get a 90-day streak.',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.legendary,
      colorHex: '#FFD700',
      condition: BadgeCondition.streakDays,
      requiredCount: 90,
    ),
    Badge(
      id: 'jet_setter',
      name: 'Jet Setter',
      nameEn: 'Jet Setter',
      icon: Icons.flight_takeoff_rounded,
      description: '5 farklı şehirde kayıt yap.',
      descriptionEn: 'Register in 5 different cities.',
      category: BadgeCategory.location,
      rarity: BadgeRarity.epic,
      colorHex: '#FFD700',
      condition: BadgeCondition.locationCount, // Placeholder logic for city count
      requiredCount: 5,
    ),
    // ... more badges will be added in segments to avoid hitting limits
  ];

  static Future<void> syncBadges(String userId) async {
    // Fetch user drinks
    var drinksSnapshot = await FirebaseFirestore.instance
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .get();
        
    List<DrinkEntry> allDrinks = drinksSnapshot.docs
        .map((doc) => DrinkEntry.fromFirestore(doc))
        .toList();

    // Fetch user data
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    var userData = userDoc.data() ?? {};
    List<String> friendIds = List<String>.from(userData['friendIds'] ?? []);

    // Fetch existing user badges
    var unlockedBadgesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('badges')
        .get();
    
    Map<String, DocumentSnapshot> currentBadges = {
      for (var doc in unlockedBadgesSnapshot.docs) doc.id: doc
    };

    // Calculations
    double totalAPS = allDrinks.fold(0.0, (sum, d) => sum + d.points);
    
    Map<String, double> categoryAPS = {};
    for (var drink in allDrinks) {
      categoryAPS[drink.drinkType] = (categoryAPS[drink.drinkType] ?? 0) + drink.points;
    }
    
    Set<String> uniqueDrinks = allDrinks.map<String>((d) => '${d.drinkType}|${d.portion}').toSet();
    
    int uniqueCocktails = allDrinks
        .where((d) => d.drinkType == 'Kokteyl' || d.drinkType == 'Cocktail')
        .map<String>((d) => '${d.drinkType}|${d.portion}')
        .toSet()
        .length;
        
    Set<String> uniqueLocations = allDrinks
        .where((d) => d.locationName.isNotEmpty)
        .map<String>((d) => d.locationName)
        .toSet();
        
    int photoCount = allDrinks.where((d) => d.hasImage).length;
    int currentStreak = _calculateStreak(allDrinks);
    double maxSingleNight = _calculateMaxSingleNight(allDrinks);
    int friendCount = friendIds.length;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    bool updated = false;

    // Check each badge that the user currently HAS
    for (String badgeId in currentBadges.keys) {
      Badge? badge;
      try {
        badge = allBadges.firstWhere((b) => b.id == badgeId);
      } catch (_) {
        continue;
      }

      bool stillQualifies = false;
      
      switch (badge.condition) {
        case BadgeCondition.totalAPS:
          if (badge.requiredAPS == 0) stillQualifies = allDrinks.isNotEmpty;
          else stillQualifies = totalAPS >= (badge.requiredAPS ?? 0.0);
          break;
        case BadgeCondition.categoryAPS:
          stillQualifies = (categoryAPS[badge.requiredCategory] ?? 0) >= (badge.requiredAPS ?? 0.0);
          break;
        case BadgeCondition.drinkVariety:
          stillQualifies = uniqueDrinks.length >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.cocktailVariety:
          stillQualifies = uniqueCocktails >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.friendCount:
          stillQualifies = friendCount >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.locationCount:
          stillQualifies = uniqueLocations.length >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.photoCount:
          stillQualifies = photoCount >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.singleNightAPS:
          stillQualifies = maxSingleNight >= (badge.requiredAPS ?? 0.0);
          break;
        case BadgeCondition.streakDays:
          stillQualifies = currentStreak >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.timeOfDay:
          int countInTime = allDrinks.where((d) => _isTimeInRange(DateFormat('HH:mm').format(d.timestamp), badge!.requiredTimeStart!, badge.requiredTimeEnd!)).length;
          stillQualifies = countInTime >= (badge.requiredCount ?? 0);
          break;
        case BadgeCondition.specificDate:
          stillQualifies = allDrinks.any((d) => _isSameDay(d.timestamp, badge!.requiredDate!));
          break;
        case BadgeCondition.leaderboardRank:
          // TODO: Implement leaderboard rank check - query user's current rank
          // and compare with badge.requiredRank. Keeping badge for now to avoid
          // incorrectly revoking earned badges until backend supports this.
          stillQualifies = true;
          break;
        case BadgeCondition.firstNUsers:
          // TODO: Implement early adopter check - compare user's registration
          // order against badge.requiredCount. Once granted, this badge should
          // never be revoked, so keeping true is correct behavior.
          stillQualifies = true;
          break;
        case BadgeCondition.allBadges:
          // TODO: Implement collection check - verify user has all other badges
          // except this one. For now keeping true to avoid circular revocation.
          stillQualifies = true;
          break;
      }

      if (!stillQualifies) {
        batch.delete(FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('badges')
            .doc(badgeId));
        updated = true;
      }
    }

    if (updated) {
      await batch.commit();
    }
  }

  static Future<List<Badge>> checkBadges(String userId) async {
    List<Badge> newlyUnlocked = [];
    
    // Fetch user drinks
    var drinksSnapshot = await FirebaseFirestore.instance
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .get();
        
    List<DrinkEntry> allDrinks = drinksSnapshot.docs
        .map((doc) => DrinkEntry.fromFirestore(doc))
        .toList();

    // Fetch user data (for frieds, etc.)
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    var userData = userDoc.data() ?? {};
    List<String> friendIds = List<String>.from(userData['friendIds'] ?? []);

    // Fetch existing user badges to avoid duplicates
    var unlockedBadgesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('badges')
        .get();
    
    Set<String> alreadyUnlockedIds = unlockedBadgesSnapshot.docs.map((doc) => doc.id).toSet();

    // Calculations
    double totalAPS = allDrinks.fold(0.0, (sum, d) => sum + d.points);
    debugPrint('🏅 checkBadges: ${allDrinks.length} drinks, totalAPS=$totalAPS, alreadyUnlocked=${alreadyUnlockedIds.length}');
    
    Map<String, double> categoryAPS = {};
    for (var drink in allDrinks) {
      categoryAPS[drink.drinkType] = (categoryAPS[drink.drinkType] ?? 0) + drink.points;
    }
    
    Set<String> uniqueDrinks = allDrinks.map<String>((d) => '${d.drinkType}|${d.portion}').toSet();
    
    int uniqueCocktails = allDrinks
        .where((d) => d.drinkType == 'Kokteyl' || d.drinkType == 'Cocktail')
        .map<String>((d) => '${d.drinkType}|${d.portion}')
        .toSet()
        .length;
        
    Set<String> uniqueLocations = allDrinks
        .where((d) => d.locationName.isNotEmpty)
        .map<String>((d) => d.locationName)
        .toSet();
        
    int photoCount = allDrinks.where((d) => d.hasImage).length;
    
    int currentStreak = _calculateStreak(allDrinks);
    double maxSingleNight = _calculateMaxSingleNight(allDrinks);
    
    int friendCount = friendIds.length;

    // Check each badge
    for (Badge badge in allBadges) {
      if (alreadyUnlockedIds.contains(badge.id)) continue;
      
      bool shouldUnlock = false;
      double progress = 0.0;
      
      switch (badge.condition) {
        case BadgeCondition.totalAPS:
          if (badge.requiredAPS == 0) {
            shouldUnlock = allDrinks.isNotEmpty;
            progress = shouldUnlock ? 1.0 : 0.0;
          } else {
            progress = (totalAPS / badge.requiredAPS!).clamp(0.0, 1.0);
            shouldUnlock = totalAPS >= badge.requiredAPS!;
          }
          break;
          
        case BadgeCondition.categoryAPS:
          double catAPS = categoryAPS[badge.requiredCategory] ?? 0;
          progress = (catAPS / badge.requiredAPS!).clamp(0.0, 1.0);
          shouldUnlock = catAPS >= badge.requiredAPS!;
          break;
          
        case BadgeCondition.singleNightAPS:
          progress = (maxSingleNight / badge.requiredAPS!).clamp(0.0, 1.0);
          shouldUnlock = maxSingleNight >= badge.requiredAPS!;
          break;
          
        case BadgeCondition.drinkVariety:
          progress = (uniqueDrinks.length / badge.requiredCount!).clamp(0.0, 1.0);
          shouldUnlock = uniqueDrinks.length >= badge.requiredCount!;
          break;
          
        case BadgeCondition.cocktailVariety:
          progress = (uniqueCocktails / badge.requiredCount!).clamp(0.0, 1.0);
          shouldUnlock = uniqueCocktails >= badge.requiredCount!;
          break;
          
        case BadgeCondition.locationCount:
          progress = (uniqueLocations.length / badge.requiredCount!).clamp(0.0, 1.0);
          shouldUnlock = uniqueLocations.length >= badge.requiredCount!;
          break;
          
        case BadgeCondition.photoCount:
          progress = (photoCount / badge.requiredCount!).clamp(0.0, 1.0);
          shouldUnlock = photoCount >= badge.requiredCount!;
          break;
          
        case BadgeCondition.streakDays:
          progress = (currentStreak / badge.requiredCount!).clamp(0.0, 1.0);
          shouldUnlock = currentStreak >= badge.requiredCount!;
          break;
          
        case BadgeCondition.friendCount:
          progress = (friendCount / badge.requiredCount!).clamp(0.0, 1.0);
          shouldUnlock = friendCount >= badge.requiredCount!;
          break;
          
        case BadgeCondition.specificDate:
          final today = DateTime.now();
          shouldUnlock = today.month == badge.requiredDate!.month && today.day == badge.requiredDate!.day;
          progress = shouldUnlock ? 1.0 : 0.0;
          break;
          
        case BadgeCondition.timeOfDay:
          // Simplified: check if last drink was in range
          if (allDrinks.isNotEmpty) {
             final lastDrink = allDrinks.last;
             final timeStr = DateFormat('HH:mm').format(lastDrink.timestamp);
             if (_isTimeInRange(timeStr, badge.requiredTimeStart!, badge.requiredTimeEnd!)) {
                // Count how many drinks in total in this range
                int countInRange = allDrinks.where((d) => 
                  _isTimeInRange(DateFormat('HH:mm').format(d.timestamp), badge.requiredTimeStart!, badge.requiredTimeEnd!)
                ).length;
                progress = (countInRange / badge.requiredCount!).clamp(0.0, 1.0);
                shouldUnlock = countInRange >= badge.requiredCount!;
             }
          }
          break;
        case BadgeCondition.leaderboardRank:
          // TODO: Query leaderboard for user's rank and unlock if within requiredRank
          shouldUnlock = false;
          progress = 0.0;
          break;
        case BadgeCondition.firstNUsers:
          // TODO: Check user registration order against requiredCount threshold
          shouldUnlock = false;
          progress = 0.0;
          break;
        case BadgeCondition.allBadges:
          // TODO: Check if user has all other badges to award collector badge
          shouldUnlock = false;
          progress = 0.0;
          break;
      }
      
      if (shouldUnlock) {
        // Save unlocked badge to user's badges subcollection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('badges')
            .doc(badge.id)
            .set({
          'unlockedAt': FieldValue.serverTimestamp(),
          'badgeId': badge.id,
        });
        
        newlyUnlocked.add(badge.copyWith(isUnlocked: true, unlockDate: DateTime.now(), progress: 1.0));
      }
    }
    
    return newlyUnlocked;
  }

  static int _calculateStreak(List<DrinkEntry> drinks) {
    if (drinks.isEmpty) return 0;
    
    // Sort drinks by date
    final sortedDrinks = List<DrinkEntry>.from(drinks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
    // Get unique days with entries
    final uniqueDays = sortedDrinks.map((d) => 
      DateTime(d.timestamp.year, d.timestamp.month, d.timestamp.day)).toSet().toList();
      
    uniqueDays.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);
    
    // If no entry today, check if there was one yesterday to continue the streak
    if (uniqueDays.first != checkDate) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (uniqueDays.first != checkDate) return 0;
    }
    
    for (var day in uniqueDays) {
      if (day == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  static double _calculateMaxSingleNight(List<DrinkEntry> drinks) {
    if (drinks.isEmpty) return 0;
    
    // Group by "night" (e.g., 6 AM to 6 AM next day)
    Map<String, double> nightAPS = {};
    
    for (var drink in drinks) {
      // Adjust time: drinks between 00:00 and 06:00 belong to previous day's night
      DateTime adjustedDate = drink.timestamp;
      if (drink.timestamp.hour < 6) {
        adjustedDate = drink.timestamp.subtract(const Duration(days: 1));
      }
      String key = DateFormat('yyyy-MM-dd').format(adjustedDate);
      nightAPS[key] = (nightAPS[key] ?? 0) + drink.points;
    }
    
    if (nightAPS.isEmpty) return 0;
    return nightAPS.values.reduce((a, b) => a > b ? a : b);
  }
  
  static bool _isTimeInRange(String time, String start, String end) {
    // time format HH:mm
    int t = _timeToInt(time);
    int s = _timeToInt(start);
    int e = _timeToInt(end);
    
    if (s <= e) {
      return t >= s && t <= e;
    } else {
      // Overnight range (e.g., 22:00 to 02:00)
      return t >= s || t <= e;
    }
  }
  
  static int _timeToInt(String time) {
    var parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
