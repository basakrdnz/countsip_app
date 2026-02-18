import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;
  final bool showOrbs;

  const AuthBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _drift1;
  late Animation<double> _drift2;
  late Animation<double> _drift3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _drift1 = Tween<double>(begin: -30, end: 30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _drift2 = Tween<double>(begin: 0, end: 50).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _drift3 = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeInOutSine),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      body: Stack(
        children: [
          // ── Layer 1: Deep base gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D1120), // Deep navy
                    Color(0xFF080B14), // Very dark blue
                    Color(0xFF050810), // Near black
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Layer 2: Static ambient radial glows ──
          // Top-left warm glow
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.25,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Bottom-right cool glow
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.85,
              height: size.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPrimary.withValues(alpha: 0.06),
                    AppColors.accentPrimary.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Bottom-right warm glow (matching top-left for symmetry)
          Positioned(
            bottom: -size.height * 0.10,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.95,
              height: size.width * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Center subtle blue glow
          Positioned(
            top: size.height * 0.35,
            left: size.width * 0.15,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A90E2).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Layer 3: Animated orbs (optional) ──
          if (widget.showOrbs) ...[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Positioned(
                  top: -80 + _drift1.value,
                  left: -30 + _drift2.value * 0.4,
                  child: _buildSoftOrb(
                    size: 320,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blur: 120,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Positioned(
                  bottom: -120 + _drift3.value,
                  right: -80 + _drift1.value * 0.3,
                  child: _buildSoftOrb(
                    size: 280,
                    color: AppColors.accentPrimary.withValues(alpha: 0.08),
                    blur: 100,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Positioned(
                  top: size.height * 0.4 + _drift2.value * 0.6,
                  right: -160,
                  child: _buildSoftOrb(
                    size: 300,
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                    blur: 140,
                  ),
                );
              },
            ),
          ],

          // ── Layer 4: Dot grid pattern ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(
                painter: _DotGridPainter(),
              ),
            ),
          ),

          // ── Layer 5: Top edge highlight ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 6: Bottom vignette ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF050810).withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 7: Content ──
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSoftOrb({
    required double size,
    required Color color,
    required double blur,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}

/// Dots instead of grid lines — subtler, more modern texture
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double spacing = 28;
    const double radius = 0.8;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
