import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Gambar sampul/foto dari jaringan dengan placeholder saat memuat atau gagal.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
    this.size,
    this.radius = 8,
    this.circle = false,
    this.icon = Icons.music_note_rounded,
  });

  final String url;

  /// Sisi persegi dalam piksel logis. Jika null, mengikuti ukuran induknya.
  final double? size;
  final double radius;
  final bool circle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: AppColors.textSecondary,
        size: (size ?? 96) * 0.4,
      ),
    );

    final Widget image = url.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (ctx, imageUrl) => placeholder,
            errorWidget: (ctx, imageUrl, error) => placeholder,
          );

    if (circle) return ClipOval(child: image);
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}
