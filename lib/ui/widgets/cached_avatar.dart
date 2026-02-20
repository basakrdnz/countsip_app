import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A circular avatar that uses [CachedNetworkImage] for efficient loading
/// and caching. Falls back to an initials placeholder when no URL is provided
/// or while loading.
class CachedAvatar extends StatelessWidget {
  final String? photoUrl;

  /// Displayed as initials placeholder when [photoUrl] is null or loading.
  final String? fallbackName;

  final double size;
  final double? borderRadius;
  final BoxFit fit;

  const CachedAvatar({
    super.key,
    this.photoUrl,
    this.fallbackName,
    this.size = 40,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size / 2;

    if (photoUrl == null || photoUrl!.isEmpty) {
      return _placeholder(radius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: fit,
        placeholder: (_, __) => _placeholder(radius),
        errorWidget: (_, __, ___) => _placeholder(radius),
      ),
    );
  }

  Widget _placeholder(double radius) {
    final initials = _initials();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(Icons.person, size: size * 0.55, color: Colors.grey.shade500)
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white70,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  String _initials() {
    if (fallbackName == null || fallbackName!.isEmpty) return '';
    final parts = fallbackName!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
