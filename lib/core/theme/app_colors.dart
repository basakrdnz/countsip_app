import 'package:flutter/material.dart';

class AppColors {
  // Primary - Stone Brand Color
  static const primary = Color(0xFF6A4A3C);
  
  // Backgrounds - Stone/Soft Light Theme
  static const background = Color(0xFFF4F1ED);      // Lighter Broken White/Stone
  static const surface = Color(0xFFFFFFFF);         // Pure White for contrast
  static const surfaceElevated = Color(0xFFFAF9F8); // Very light warm grey
  
  // Text - High Contrast
  static const textPrimary = Color(0xFF4B3126);     // Dark Brown
  static const textSecondary = Color(0xFF6A4A3C);   // Medium Brown
  static const textTertiary = Color(0xFF8E847B);    // Muted Taupe
  
  // Borders
  static const border = Color(0xFF4B3126);
  
  // Status Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFEF5350);
  
  // Shadows
  static const shadow = Color(0x40000000);
  
  // Component Colors
  static final cardBackground = Colors.white.withOpacity(0.85);
  static final cardBorder = primary.withOpacity(0.1);
  static final cardShadow = primary.withOpacity(0.05);
  
  // Buttons
  static const buttonPrimary = primary;
  static const buttonOnPrimary = Colors.white;
}