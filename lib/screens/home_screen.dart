import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../models/genre.dart';
import '../models/screen_data.dart';
import '../widgets/media_cards.dart';
import '../widgets/section_header.dart';
import '../widgets/shelf.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';
import 'album_screen.dart';
import 'artist_screen.dart';

/// Beranda: chart musik dunia yang dapat difilter berdasarkan genre.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _genreId = 0;
  late Future<HomeData> _future;
  late final Future<List<Genre>> _genresFuture;

  @override
  void initState() {
    super.initState();
    final api = AppScope.of(context).api;
    _genresFuture = api.fetchGenres();
    _future = api.fetchHomeData(genreId: _genreId);
  }

  void _reload() {
    setState(() {
      _future = AppScope.of(context).api.fetchHomeData(genreId: _genreId);
    });
  }

  void _selectGenre(int genreId) {
    if (genreId == _genreId) return;
    setState(() {
      _genreId = genreId;
      _future = AppScope.of(context).api.fetchHomeData(genreId: genreId);
    });
  }

  /// Tarik-untuk-muat-ulang. Hasil atau kesalahan ditampilkan oleh FutureBuilder.
  Future<void> _refresh() async {
    final future = AppScope.of(context).api.fetchHomeData(genreId: _genreId);
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // Kesalahan sudah ditangani oleh FutureBuilder (ErrorView).
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Apa yang ingin Anda dengar?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          _GenreBar(
            future: _genresFuture,
            selectedId: _genreId,
            onSelected: _selectGenre,
          ),
          Expanded(
            child: FutureBuilder<HomeData>(
              future: _future,
              builder: (context, snapshot) {
                // 1. Loading: permintaan masih berjalan.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Memuat tangga lagu…');
                }
                // 2. Error: permintaan gagal atau data tidak dapat diproses.
                if (snapshot.hasError) {
                  return ErrorView(error: snapshot.error!, onRetry: _reload);
                }
                // 3. Success: data siap disajikan.
                final data = snapshot.data;
                if (data == null || data.isEmpty) {
                  return const EmptyView(
                    icon: Icons.library_music_outlined,
                    title: 'Belum ada data',
                    message:
                        'Genre ini belum memiliki chart. Pilih genre lain di atas.',
                  );
                }
                return _HomeContent(data: data, onRefresh: _refresh);
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.data, required this.onRefresh});

  final HomeData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final player = AppScope.of(context).player;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceHigh,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (data.artists.isNotEmpty) ...[
            const SectionHeader('Artis populer'),
            Shelf(
              height: 150,
              itemCount: data.artists.length,
              itemBuilder: (context, index) {
                final artist = data.artists[index];
                return ArtistCard(
                  artist: artist,
                  onTap: () => ArtistScreen.open(
                    context,
                    id: artist.id,
                    name: artist.name,
                  ),
                );
              },
            ),
          ],
          if (data.albums.isNotEmpty) ...[
            const SectionHeader('Album populer'),
            Shelf(
              height: 210,
              itemCount: data.albums.length,
              itemBuilder: (context, index) {
                final album = data.albums[index];
                return AlbumCard(
                  album: album,
                  onTap: () => AlbumScreen.open(
                    context,
                    id: album.id,
                    title: album.title,
                  ),
                );
              },
            ),
          ],
          if (data.tracks.isNotEmpty) ...[
            const SectionHeader('Lagu populer'),
            for (final track in data.tracks)
              TrackTile(
                key: ValueKey<int>(track.id),
                track: track,
                onPlay: () => player.playQueue(data.tracks, track),
              ),
          ],
        ],
      ),
    );
  }
}

/// Deretan chip genre. Daftar genre bersifat pelengkap: saat masih dimuat atau
/// gagal diambil, bar disembunyikan agar chart utama tetap bisa dipakai.
class _GenreBar extends StatelessWidget {
  const _GenreBar({
    required this.future,
    required this.selectedId,
    required this.onSelected,
  });

  final Future<List<Genre>> future;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Genre>>(
      future: future,
      builder: (context, snapshot) {
        final genres = snapshot.data;
        if (genres == null || genres.isEmpty) return const SizedBox(height: 12);

        return SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: genres.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final genre = genres[index];
              final selected = genre.id == selectedId;
              return ChoiceChip(
                label: Text(genre.name),
                selected: selected,
                showCheckmark: false,
                backgroundColor: AppColors.surfaceHigh,
                selectedColor: AppColors.accent,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: selected ? AppColors.onAccent : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onSelected(genre.id),
              );
            },
          ),
        );
      },
    );
  }
}
