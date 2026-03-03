import 'package:flutter/material.dart';
import 'dart:ui'; // Hot reload trigger
import 'app_colors.dart';

class AppDecorations {
  // ==================== CARD DECORATIONS ====================
  
  /// Default Card: #1A1F2E, 16px radius, Box-shadow 0 4px 12px
  static BoxDecoration glassCard({
    double borderRadius = 16.0,
    double borderWidth = 1.0,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.05),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// NEW Approved Style: Outlined & Transparent Glass Card
  static BoxDecoration outlinedGlassCard({
    double borderRadius = 24.0,
    double borderWidth = 1.5,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.18),
        width: borderWidth,
      ),
    );
  }

  /// Outlined Glass Widget wrapper with BackdropFilter
  static Widget outlinedGlassWidget({
    required Widget child,
    double borderRadius = 24.0,
    double borderWidth = 1.5,
    double blurSigma = 12.0,
    Color? backgroundColor,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: outlinedGlassCard(
              borderRadius: borderRadius,
              borderWidth: borderWidth,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Glassmorphism Card Widget with Backdrop Blur
  static Widget glassCardWidget({
    required Widget child,
    double borderRadius = 16.0,
    double borderWidth = 1.0,
    double blurSigma = 10.0,
    Color? color,
    EdgeInsetsGeometry? padding,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: glassCard(
            borderRadius: borderRadius,
            borderWidth: borderWidth,
            color: color ?? AppColors.surface.withOpacity(0.7),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Premium Glow effect for hero elements
  static BoxDecoration glassGlow({
    required Color color,
    double blurRadius = 40.0,
    double opacity = 0.2,
  }) {
    return BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: blurRadius,
          spreadRadius: 10,
        ),
      ],
    );
  }

  /// Professional Accent Card (for featured content)
  static BoxDecoration accentCard({
    required Color accentColor,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surface,
          accentColor.withOpacity(0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accentColor.withOpacity(0.2),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ==================== BUTTON DECORATIONS ====================

  /// Primary Button: Coral Gradient (135deg, 12px radius)
  static BoxDecoration primaryButton({
    double borderRadius = 12.0,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.primaryGradient,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// Secondary Button: Elevated Dark Surface (#242938)
  static BoxDecoration secondaryButton({
    double borderRadius = 12.0,
  }) {
    return BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1.0,
      ),
    );
  }

  /// Icon Button (Round) - 48x48
  static BoxDecoration iconButton({
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: AppColors.surfaceElevated,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1.0,
      ),
      boxShadow: elevated ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ] : null,
    );
  }

  /// Counter Button (Plus/Minus) - 48x48 Circular
  static BoxDecoration counterButton() {
    return const BoxDecoration(
      color: AppColors.surfaceElevated,
      shape: BoxShape.circle,
    );
  }

  // ==================== INPUT DECORATIONS ====================

  /// Search/Input Bar
  static BoxDecoration inputDecoration({
    bool isFocused = false,
    double borderRadius = 12.0,
  }) {
    return BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? AppColors.primary : Colors.white.withOpacity(0.1),
        width: isFocused ? 2.0 : 1.0,
      ),
      boxShadow: isFocused ? [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ] : null,
    );
  }

  // ==================== SPECIAL DECORATIONS ====================

  /// Leaderboard Rank Badge
  static BoxDecoration rankBadge(int rank) {
    List<Color> gradient;
    switch (rank) {
      case 1:
        gradient = AppColors.rank1Gradient;
        break;
      case 2:
        gradient = AppColors.rank2Gradient;
        break;
      case 3:
        gradient = AppColors.rank3Gradient;
        break;
      default:
        return BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
        );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: gradient[0].withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Calendar Selected Day
  static BoxDecoration calendarSelected() {
    return BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Calendar Today (not selected)
  static BoxDecoration calendarToday() {
    return BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.primary,
        width: 2.0,
      ),
    );
  }

  /// Notification Badge (red dot with pulse)
  static BoxDecoration notificationBadge() {
    return BoxDecoration(
      color: AppColors.error,
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.background,
        width: 2.0,
      ),
    );
  }

  // ==================== SHADOWS ====================

  /// Subtle shadow for smaller elements
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Heavy shadow for elevated elements
  static List<BoxShadow> get heavyShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
