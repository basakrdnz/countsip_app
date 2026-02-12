import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedNotificationBell extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const AnimatedNotificationBell({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  State<AnimatedNotificationBell> createState() => _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<AnimatedNotificationBell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Trigger animation once on load if there are notifications
    if (widget.count > 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If notification count increases, shake again
    if (widget.count > oldWidget.count) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 32,
            ),
          ),
          if (widget.count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
