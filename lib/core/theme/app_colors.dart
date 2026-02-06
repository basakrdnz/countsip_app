import 'package:flutter/material.dart';
import 'dart:ui';

class AppColors {
  // ==================== 2026 PROFESSIONAL DARK MODE ====================
  
  // Backgrounds
  static const background = Color(0xFF0A0E14);      // Deep navy black
  static const surface = Color(0xFF1A1F2E);         // Dark navy-gray card background
  static const surfaceElevated = Color(0xFF242938); // Elevated card hover state
  static const surfacePressed = Color(0xFF2E3442);  // Pressed state
  
  // High-Contrast Accents (Professional Palette)
  static const primary = Color(0xFFFF6B6B);         // Vibrant Coral Red
  static const secondary = Color(0xFF4ECDC4);       // Teal / Turquoise
  static const tertiary = Color(0xFFFFE66D);        // Professional Yellow
  
  // Support Colors
  static const accentPrimary = Color(0xFFEE5A6F);   // Secondary tone for primary gradient
  
  // Category Mapping (Drink Types)
  static const categoryBeer = tertiary;             // Yellow for Beer
  static const categoryWine = primary;              // Coral Red for Wine
  static const categoryRaki = secondary;            // Teal for Rakı
  static const categoryWhisky = primary;            // Coral Red for Whisky
  
  // Text Colors (Lighter for better contrast)
  static const textPrimary = Color(0xFFFFFFFF);     // Pure White (Titles)
  static const textSecondary = Color(0xFFF1F5F9);   // Very light gray (Body) - önceki: E2E8F0
  static const textTertiary = Color(0xFFCBD5E1);    // Light gray (Dim) - önceki: 94A3B8
  static const textPlaceholder = Color(0xFF94A3B8); // Placeholder Gray - önceki: 64748B
  
  // Status Colors
  static const success = Color(0xFF4ECDC4);         // Teal for success
  static const warning = Color(0xFFFFE66D);         // Yellow for warning
  static const error = Color(0xFFFF3B3B);           // Bright Red for error
  
  // Shadows & Borders
  static const border = Color(0x1AFFFFFF);           // Subtle border (white 10%)
  static const borderFocused = primary;             // Focused input border
  static const shadow = Color(0x26000000);           // rgba(0,0,0,0.15)
  static const shadowHeavy = Color(0x40000000);      // rgba(0,0,0,0.25)
  
  // Component Colors
  static const cardBackground = surface;
  static const cardBorder = Color(0x1AFFFFFF);
  static const cardShadow = Color(0x26000000);
  
  static const navbarBackground = surface;
  static const navbarBorder = Color(0x1AFFFFFF);
  
  // Buttons
  static const buttonPrimary = primary;
  static const buttonOnPrimary = Color(0xFFFFFFFF);
  static const buttonSecondary = surfaceElevated;
  static const buttonOnSecondary = textSecondary;
  
  // Gradients
  static const primaryGradient = [primary, accentPrimary];
  static const pointGradient = [secondary, primary];
  static const rank1Gradient = [Color(0xFFFFD700), Color(0xFFFFA500)]; // Gold
  static const rank2Gradient = [Color(0xFFC0C0C0), Color(0xFFA0A0A0)]; // Silver
  static const rank3Gradient = [Color(0xFFCD7F32), Color(0xFFB87333)]; // Bronze
}