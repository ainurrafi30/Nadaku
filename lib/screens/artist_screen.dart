import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/screen_data.dart';
import '../widgets/cover_image.dart';
import '../widgets/media_cards.dart';
import '../widgets/mini_player.dart';
import '../widgets/section_header.dart';
import '../widgets/shelf.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';
import 'album_screen.dart';

/// Detail artis: foto, jumlah penggemar, lagu populer, dan daftar album.
class ArtistScreen extends StatefulWidget {
  const ArtistScreen({super.key, required this.artistId, this.initialName});

  final int artistId;
  final String? initialName;

  static Future<void> open(
    BuildContext context, {
    required int id,
    String? name,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ArtistScreen(artistId: id, initialName: name),
      ),
    );
  }

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Future<ArtistDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = AppScope.of(context).api.fetchArtistDetail(widget.artistId);
  }

  void _reload() {
    setState(() {
      _future = AppScope.of(context).api.fetchArtistDetail(widget.artistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ArtistDetail>(
      future: _future,
      builder: (context, snapshot) {
        final title = widget.initialName ?? 'Artis';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const LoadingView(message: 'Memuat profil artis…'),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: ErrorView(error: snapshot.error!, onRetry: _reload),
          );
        }

        return Scaffold(
          body: _ArtistBody(detail: snapshot.data!),
          bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
        );
      },
    );
  }
}

String _statsText(int? fans, int? albumCount) {
  final parts = <String>[
    if (fans != null) '${formatCompact(fans)} penggemar',
    if (albumCount != null) '$albumCount album',
  ];
  return parts.join(', ');
}

class _ArtistBody extends StatelessWidget {
  const _ArtistBody({required this.detail});

  final ArtistDetail detail;

  @override
  Widget build(BuildContext context) {
    final player = AppScope.of(context).player;
    final artist = detail.artist;
    final topTracks = detail.topTracks;
    final albums = detail.albums;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CoverImage(
                  url: artist.bestPicture,
                  radius: 0,
                  icon: Icons.person_rounded,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0x000E1230), AppColors.background],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statsText(artist.fans, artist.albumCount),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                if (topTracks.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => player.playQueue(topTracks, topTracks.first),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Putar'),
                  ),
              ],
            ),
          ),
        ),
        if (topTracks.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Lagu populer')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = topTracks[index];
                return TrackTile(
                  key: ValueKey<int>(track.id),
                  track: track,
                  onPlay: () => player.playQueue(topTracks, track),
                );
              },
              childCount: topTracks.length,
            ),
          ),
        ],
        if (albums.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Album')),
          SliverToBoxAdapter(
            child: Shelf(
              height: 210,
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return AlbumCard(
                  album: album,
                  subtitle: formatYear(album.releaseDate) ?? '',
                  onTap: () => AlbumScreen.open(
                    context,
                    id: album.id,
                    title: album.title,
                  ),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
