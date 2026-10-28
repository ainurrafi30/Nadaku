import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';

/// Daftar lagu favorit yang disimpan secara lokal di perangkat.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: scope.favorites,
        builder: (context, _) {
          final items = scope.favorites.items;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Lagu favorit',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${items.length} lagu tersimpan di perangkat',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            scope.player.playQueue(items, items.first),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Putar semua'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyView(
                        icon: Icons.favorite_border_rounded,
                        title: 'Belum ada favorit',
                        message:
                            'Ketuk ikon hati pada sebuah lagu untuk menyimpannya di sini.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final track = items[index];
                          return TrackTile(
                            key: ValueKey<int>(track.id),
                            track: track,
                            onPlay: () => scope.player.playQueue(items, track),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
