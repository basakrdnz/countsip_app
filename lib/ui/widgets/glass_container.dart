import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_decorations.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final double blur;
  final double borderRadius;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.opacity = 0.85,
    this.blur = 24.0,
    this.borderRadius = 24.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: AppDecorations.glassCard(
              borderRadius: borderRadius,
              color: (color ?? Colors.white).withOpacity(opacity),
            ).copyWith(border: border),
            child: child,
          ),
        ),
      ),
    );
  }
}
