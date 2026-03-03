import 'package:flutter/material.dart';

/// A reusable centered empty state widget with an icon and a message.
/// Matches the app's dark-mode design language (white10 icon, white24 text).
///
/// [verticalBias] shifts the content vertically:
///   0.0  = perfectly centered (default)
///  -0.3  = shifted up (useful when a sticky AppBar takes visual space)
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final double iconSize;
  final double verticalBias;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconSize = 96,
    this.verticalBias = -0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(0, verticalBias),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: Colors.white10),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white24,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
