import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/screen_data.dart';
import '../widgets/cover_image.dart';
import '../widgets/mini_player.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';
import 'artist_screen.dart';

/// Detail album: sampul, informasi rilis, dan daftar lagu.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.albumId, this.initialTitle});

  final int albumId;
  final String? initialTitle;

  static Future<void> open(
    BuildContext context, {
    required int id,
    String? title,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AlbumScreen(albumId: id, initialTitle: title),
      ),
    );
  }

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<AlbumDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = AppScope.of(context).api.fetchAlbumDetail(widget.albumId);
  }

  void _reload() {
    setState(() {
      _future = AppScope.of(context).api.fetchAlbumDetail(widget.albumId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AlbumDetail>(
      future: _future,
      builder: (context, snapshot) {
        final title = widget.initialTitle ?? 'Album';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const LoadingView(message: 'Memuat album…'),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: ErrorView(error: snapshot.error!, onRetry: _reload),
          );
        }

        final detail = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(detail.album.title)),
          body: _AlbumBody(detail: detail),
          bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
        );
      },
    );
  }
}

String _recordTypeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'album':
      return 'Album';
    case 'single':
      return 'Single';
    case 'ep':
      return 'EP';
    case 'compile':
      return 'Kompilasi';
    default:
      return type;
  }
}

class _AlbumBody extends StatelessWidget {
  const _AlbumBody({required this.detail});

  final AlbumDetail detail;

  @override
  Widget build(BuildContext context) {
    final player = AppScope.of(context).player;
    final album = detail.album;
    final tracks = detail.tracks;
    final artist = album.artist;
    final year = formatYear(album.releaseDate);
    final firstPlayable = tracks.indexWhere((track) => track.hasPreview);

    final meta = <String>[
      if (album.recordType != null) _recordTypeLabel(album.recordType!),
      if (year != null) year,
      if (album.trackCount != null) '${album.trackCount} lagu',
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CoverImage(
            url: album.displayCover,
            size: 220,
            radius: 16,
            icon: Icons.album_rounded,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                album.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              if (artist != null && artist.id != 0)
                InkWell(
                  onTap: () => ArtistScreen.open(
                    context,
                    id: artist.id,
                    name: artist.name,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      artist.name,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              if (meta.isNotEmpty)
                Text(
                  meta.join(', '),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              if (album.genres.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    album.genres.join(', '),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              if (album.label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Label: ${album.label}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 16),
              if (firstPlayable >= 0)
                FilledButton.icon(
                  onPressed: () =>
                      player.playQueue(tracks, tracks[firstPlayable]),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Putar album'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Daftar lagu album ini tidak tersedia.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          for (final (index, track) in tracks.indexed)
            TrackTile(
              key: ValueKey<int>(track.id),
              track: track,
              number: index + 1,
              onPlay: () => player.playQueue(tracks, track),
            ),
      ],
    );
  }
}
