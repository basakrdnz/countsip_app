import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  // CountSip logo - Rosaline font
  static const logoStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    fontFamily: 'Rosaline',
    color: AppColors.primary,
    letterSpacing: -1,
  );

  // Headings - Cal Sans
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    fontFamily: 'CalSans',
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );

  static const title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontFamily: 'CalSans',
    color: AppColors.textPrimary,
  );

  static const title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: 'CalSans',
    color: AppColors.textPrimary,
  );

  static const title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: 'CalSans',
    color: AppColors.textPrimary,
  );

  // Body text - default system font
  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static const caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}
