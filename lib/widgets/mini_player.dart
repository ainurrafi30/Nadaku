import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../screens/player_screen.dart';
import '../services/player_controller.dart';
import 'cover_image.dart';

/// Pemutar mini di bagian bawah layar; muncul setelah sebuah lagu dipilih.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = AppScope.of(context).player;

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final track = player.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final busy = player.isLoading || player.isBuffering;

        return Material(
          color: AppColors.surfaceHigh,
          child: InkWell(
            onTap: () => PlayerScreen.open(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    children: [
                      CoverImage(
                        url: track.album.coverMedium,
                        size: 44,
                        radius: 6,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              player.errorMessage ?? track.artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: player.errorMessage == null
                                    ? AppColors.textSecondary
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else
                        IconButton(
                          tooltip: player.isPlaying ? 'Jeda' : 'Putar',
                          iconSize: 32,
                          onPressed: player.togglePlayPause,
                          icon: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Berikutnya',
                        onPressed: player.hasNext ? player.next : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<PlaybackProgress>(
                  valueListenable: player.progress,
                  builder: (context, progress, _) {
                    return LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 2,
                      color: AppColors.accent,
                      backgroundColor: const Color(0x1FFFFFFF),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
