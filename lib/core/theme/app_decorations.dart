import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  /// Standard glass/white card decoration used across the app
  static BoxDecoration glassCard({
    double borderRadius = 24.0,
    double borderWidth = 1.2,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.cardBorder,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Subtle shadow for smaller elements
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}
