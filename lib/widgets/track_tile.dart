import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../models/track.dart';
import 'cover_image.dart';

/// Baris lagu: sampul, judul, artis, penanda sedang diputar, dan tombol favorit.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onPlay,
    this.number,
  });

  final Track track;
  final VoidCallback onPlay;

  /// Jika diisi, nomor urut ditampilkan menggantikan sampul (halaman album).
  final int? number;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[scope.player, scope.favorites]),
      builder: (context, _) {
        final isCurrent = scope.player.isCurrent(track);
        final isFavorite = scope.favorites.isFavorite(track);
        final available = track.hasPreview;

        final Color titleColor;
        if (!available) {
          titleColor = AppColors.textSecondary;
        } else if (isCurrent) {
          titleColor = AppColors.accent;
        } else {
          titleColor = AppColors.textPrimary;
        }

        return ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          onTap: available ? onPlay : () => _showUnavailable(context),
          leading: number == null
              ? CoverImage(url: track.album.coverMedium, size: 52, radius: 6)
              : SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color:
                            isCurrent ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              if (track.explicit)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: _ExplicitBadge(),
                ),
              Expanded(
                child: Text(
                  available ? track.artist.name : 'Preview tidak tersedia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent && scope.player.isPlaying)
                const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              IconButton(
                tooltip: isFavorite
                    ? 'Hapus dari favorit'
                    : 'Tambahkan ke favorit',
                onPressed: () => scope.favorites.toggle(track),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.heart : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview untuk lagu ini tidak tersedia.')),
    );
  }
}

class _ExplicitBadge extends StatelessWidget {
  const _ExplicitBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'E',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.background,
        ),
      ),
    );
  }
}
