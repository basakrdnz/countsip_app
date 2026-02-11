import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ProfileFrameRank {
  none,
  bronze,
  silver,
  gold,
  platinumVip;

  static ProfileFrameRank fromName(String name) {
    return ProfileFrameRank.values.firstWhere((e) => e.name == name, orElse: () => ProfileFrameRank.none);
  }

  String get displayName {
    switch (this) {
      case ProfileFrameRank.none: return 'Yok';
      case ProfileFrameRank.bronze: return 'Bronz';
      case ProfileFrameRank.silver: return 'Gümüş';
      case ProfileFrameRank.gold: return 'Altın';
      case ProfileFrameRank.platinumVip: return 'Platin VIP';
    }
  }

  Color get frameColor {
    switch (this) {
      case ProfileFrameRank.none: return Colors.transparent;
      case ProfileFrameRank.bronze: return const Color(0xFFCD7F32);
      case ProfileFrameRank.silver: return const Color(0xFFC0C0C0);
      case ProfileFrameRank.gold: return const Color(0xFFFFD700);
      case ProfileFrameRank.platinumVip: return const Color(0xFFE5E4E2);
    }
  }
}

class ThemeService {
  static ProfileFrameRank getFrameRankForLevel(int level) {
    if (level >= 50) return ProfileFrameRank.platinumVip;
    if (level >= 20) return ProfileFrameRank.gold;
    if (level >= 10) return ProfileFrameRank.silver;
    if (level >= 5) return ProfileFrameRank.bronze;
    return ProfileFrameRank.none;
  }

  static int getRequiredLevel(ProfileFrameRank rank) {
    switch (rank) {
      case ProfileFrameRank.none: return 1;
      case ProfileFrameRank.bronze: return 5;
      case ProfileFrameRank.silver: return 10;
      case ProfileFrameRank.gold: return 20;
      case ProfileFrameRank.platinumVip: return 50;
    }
  }

  static int calculateLevel(double totalAPS) {
    // PRD 5.1: Her 50 APS 1 seviye kazandırır
    return (totalAPS / 50).floor() + 1;
  }
}
