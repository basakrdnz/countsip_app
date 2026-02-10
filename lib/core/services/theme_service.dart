import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppThemeMode {
  defaultMode,
  midnight,
  neon,
  gradient,
  goldVip;

  static AppThemeMode fromName(String name) {
    return AppThemeMode.values.firstWhere((e) => e.name == name, orElse: () => AppThemeMode.defaultMode);
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.defaultMode: return 'Varsayılan';
      case AppThemeMode.midnight: return 'Midnight';
      case AppThemeMode.neon: return 'Neon';
      case AppThemeMode.gradient: return 'Gradient';
      case AppThemeMode.goldVip: return 'Gold VIP';
    }
  }
}

class ThemeService {
  static AppThemeMode getThemeForLevel(int level) {
    if (level >= 50) return AppThemeMode.goldVip;
    if (level >= 20) return AppThemeMode.gradient;
    if (level >= 10) return AppThemeMode.neon;
    if (level >= 5) return AppThemeMode.midnight;
    return AppThemeMode.defaultMode;
  }

  static int getRequiredLevel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.defaultMode: return 1;
      case AppThemeMode.midnight: return 5;
      case AppThemeMode.neon: return 10;
      case AppThemeMode.gradient: return 20;
      case AppThemeMode.goldVip: return 50;
    }
  }

  static LinearGradient? getBackgroundGradient(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.gradient:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1C2C), Color(0xFF4A1942)],
        );
      case AppThemeMode.goldVip:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F0F), Color(0xFF2D2409)],
        );
      default:
        return null;
    }
  }

  static int calculateLevel(double totalAPS) {
    // PRD 5.1: Her 50 APS 1 seviye kazandırır (Örn: 250 APS = Seviye 5)
    return (totalAPS / 50).floor() + 1;
  }

  static Color getAccentColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.neon:
        return const Color(0xFF00FFC2);
      case AppThemeMode.goldVip:
        return const Color(0xFFFFD700);
      default:
        return AppColors.primary;
    }
  }
}
