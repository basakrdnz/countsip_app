import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ==================== 2026 PROFESSIONAL TYPOGRAPHY (Inter) ====================
  
  // Hero / H1 (Screen titles) - 32px
  static TextStyle hero = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle h1 = hero;

  // H2 (Section headers) - 20px
  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  // H3 (Card titles) - 16px
  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0,
  );

  // Body Large / Regular (Main text) - 15px
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    letterSpacing: 0,
  );

  static TextStyle bodyRegular = bodyLarge;

  // Body Medium (Sub-text) - 14px
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Body Small - 12px
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Caption - 11px
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // Button Text - 15px
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonOnPrimary,
    height: 1.0,
    letterSpacing: 0.2,
  );

  // ==================== ALIASES FOR COMPATIBILITY ====================
  static TextStyle get display => hero;
  static TextStyle get title1 => h1;
  static TextStyle get title2 => h2;
  static TextStyle get title3 => h3;
  static TextStyle get body => bodyLarge;
  static TextStyle get largeTitle => hero;
  static TextStyle get bodyEmphasis => bodyLarge.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get callout => bodyMedium.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get subheadline => bodyRegular;
  static TextStyle get footnote => bodySmall;
  static TextStyle get textPrimary => bodyLarge.copyWith(color: AppColors.textPrimary);
}
