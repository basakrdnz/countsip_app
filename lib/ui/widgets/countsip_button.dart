import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum CountSipButtonVariant { 
  primary,   // Gradient (Coral/Orange)
  secondary, // Muted/Glassy
  danger,    // Error/Red
  outlined,  // Transparent with border
  ghost      // Purely text
}

class CountSipButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CountSipButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double fontSize;
  final Color? textColor;

  const CountSipButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CountSipButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.isExpanded = true,
    this.padding,
    this.borderRadius = 16,
    this.fontSize = 16,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor ?? _getTextColor()),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor ?? _getTextColor(),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: isExpanded ? (width ?? double.infinity) : width,
      height: height,
      child: Container(
        decoration: _getBoxDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || onPressed == null) ? null : onPressed,
            onLongPress: (isLoading || onPressed == null) ? null : () {}, // For splash
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
                child: buttonContent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration() {
    switch (variant) {
      case CountSipButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: onPressed == null ? 0.5 : 1.0),
              AppColors.accentPrimary.withValues(alpha: onPressed == null ? 0.5 : 1.0),
            ],
          ),
          boxShadow: onPressed == null ? null : [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        );
      case CountSipButtonVariant.danger:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppColors.error.withValues(alpha: onPressed == null ? 0.5 : 1.0),
          boxShadow: onPressed == null ? null : [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case CountSipButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        );
      case CountSipButtonVariant.outlined:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        );
      case CountSipButtonVariant.ghost:
        return const BoxDecoration();
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case CountSipButtonVariant.primary:
      case CountSipButtonVariant.danger:
        return Colors.white;
      case CountSipButtonVariant.secondary:
        return AppColors.textSecondary.withValues(alpha: 0.8);
      case CountSipButtonVariant.outlined:
      case CountSipButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  Color _getLoadingColor() {
    return (variant == CountSipButtonVariant.primary || variant == CountSipButtonVariant.danger)
        ? Colors.white
        : AppColors.primary;
  }
}
