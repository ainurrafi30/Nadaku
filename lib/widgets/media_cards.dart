import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'cover_image.dart';

/// Kartu artis berbentuk lingkaran.
class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artist, required this.onTap});

  final Artist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoverImage(
              url: artist.pictureMedium,
              size: 96,
              circle: true,
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu album persegi dengan judul dan keterangan singkat.
class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
    this.subtitle,
  });

  final Album album;
  final VoidCallback onTap;

  /// Keterangan di bawah judul. Jika null, memakai nama artis album.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final caption = subtitle ?? album.artist?.name ?? '';

    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CoverImage(
              url: album.coverMedium,
              size: 140,
              radius: 10,
              icon: Icons.album_rounded,
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            if (caption.isNotEmpty)
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
