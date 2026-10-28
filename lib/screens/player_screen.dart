import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/track.dart';
import '../services/api_exception.dart';
import '../services/deezer_service.dart';
import '../services/player_controller.dart';
import '../widgets/cover_image.dart';
import '../widgets/state_views.dart';
import 'album_screen.dart';
import 'artist_screen.dart';

const TextStyle _timeStyle = TextStyle(
  fontSize: 12,
  color: AppColors.textSecondary,
);

/// Halaman "Sedang diputar": sampul besar, seek bar, dan kontrol pemutaran.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const PlayerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final player = scope.player;

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[player, scope.favorites]),
      builder: (context, _) {
        final track = player.currentTrack;

        if (track == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(
              icon: Icons.music_off_rounded,
              title: 'Belum ada lagu diputar',
              message: 'Pilih lagu dari Beranda atau Cari untuk mulai mendengarkan.',
            ),
          );
        }

        final isFavorite = scope.favorites.isFavorite(track);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Tutup',
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Sedang diputar'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CoverImage(
                        url: track.album.bestCover,
                        radius: 20,
                        icon: Icons.album_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _LinkChips(track: track),
                const SizedBox(height: 8),
                _SeekBar(player: player),
                const SizedBox(height: 4),
                _Controls(
                  player: player,
                  isFavorite: isFavorite,
                  onToggleFavorite: () => scope.favorites.toggle(track),
                ),
                if (player.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      player.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger, height: 1.4),
                    ),
                  ),
                const SizedBox(height: 24),
                _TrackDetailCard(
                  key: ValueKey<int>(track.id),
                  api: scope.api,
                  track: track,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinkChips extends StatelessWidget {
  const _LinkChips({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (track.artist.id != 0)
          ActionChip(
            avatar: const Icon(Icons.person_rounded, size: 18),
            label: const Text('Lihat artis'),
            backgroundColor: AppColors.surfaceHigh,
            side: BorderSide.none,
            onPressed: () => ArtistScreen.open(
              context,
              id: track.artist.id,
              name: track.artist.name,
            ),
          ),
        if (track.album.id != 0)
          ActionChip(
            avatar: const Icon(Icons.album_rounded, size: 18),
            label: const Text('Lihat album'),
            backgroundColor: AppColors.surfaceHigh,
            side: BorderSide.none,
            onPressed: () => AlbumScreen.open(
              context,
              id: track.album.id,
              title: track.album.title,
            ),
          ),
      ],
    );
  }
}

/// Slider posisi lagu. Posisi sementara disimpan selama pengguna menggeser
/// agar thumb tidak melompat-lompat; seek dilakukan saat jari dilepas.
class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player});

  final PlayerController player;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlaybackProgress>(
      valueListenable: widget.player.progress,
      builder: (context, progress, _) {
        final totalMs = progress.total.inMilliseconds;
        final hasDuration = totalMs > 0;
        final dragValue = _dragValue;
        final value =
            (dragValue ?? progress.fraction).clamp(0.0, 1.0).toDouble();
        final shownPosition = dragValue == null
            ? progress.position
            : Duration(milliseconds: (dragValue * totalMs).round());

        return Column(
          children: [
            Slider(
              value: value,
              onChanged: hasDuration
                  ? (newValue) {
                      setState(() => _dragValue = newValue);
                    }
                  : null,
              onChangeEnd: hasDuration
                  ? (newValue) {
                      widget.player.seek(
                        Duration(milliseconds: (newValue * totalMs).round()),
                      );
                      setState(() => _dragValue = null);
                    }
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatClock(shownPosition), style: _timeStyle),
                  Text(formatClock(progress.total), style: _timeStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.player,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final PlayerController player;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final busy = player.isLoading || player.isBuffering;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: player.repeatEnabled ? 'Matikan ulangi' : 'Ulangi lagu',
          iconSize: 24,
          onPressed: player.toggleRepeat,
          icon: Icon(
            player.repeatEnabled
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color:
                player.repeatEnabled ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
        IconButton(
          tooltip: 'Sebelumnya',
          iconSize: 36,
          onPressed: player.previous,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.onAccent,
                  ),
                )
              : IconButton(
                  tooltip: player.isPlaying ? 'Jeda' : 'Putar',
                  iconSize: 38,
                  color: AppColors.onAccent,
                  onPressed: player.togglePlayPause,
                  icon: Icon(
                    player.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
        ),
        IconButton(
          tooltip: 'Berikutnya',
          iconSize: 36,
          onPressed: player.hasNext ? player.next : null,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        IconButton(
          tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambahkan ke favorit',
          iconSize: 24,
          onPressed: onToggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.heart : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Kartu "Tentang lagu ini". Mengambil detail lagu dari endpoint /track/{id}
/// (tanggal rilis, BPM, dll.) dengan FutureBuilder sendiri.
class _TrackDetailCard extends StatefulWidget {
  const _TrackDetailCard({super.key, required this.api, required this.track});

  final DeezerService api;
  final Track track;

  @override
  State<_TrackDetailCard> createState() => _TrackDetailCardState();
}

class _TrackDetailCardState extends State<_TrackDetailCard> {
  late Future<Track> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchTrack(widget.track.id);
  }

  void _retry() {
    setState(() {
      _future = widget.api.fetchTrack(widget.track.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang lagu ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Track>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        describeError(snapshot.error!),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _retry,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                );
              }

              final detail = snapshot.data ?? widget.track;
              return Column(
                children: [
                  _InfoRow(label: 'Artis', value: detail.artist.name),
                  _InfoRow(label: 'Album', value: detail.album.title),
                  _InfoRow(
                    label: 'Tanggal rilis',
                    value: formatReleaseDate(detail.releaseDate),
                  ),
                  _InfoRow(
                    label: 'Durasi lagu penuh',
                    value: formatSeconds(detail.durationSeconds),
                  ),
                  _InfoRow(
                    label: 'Tempo',
                    value: detail.bpm == null ? '-' : '${detail.bpm} BPM',
                  ),
                  _InfoRow(
                    label: 'Peringkat Deezer',
                    value: formatCompact(detail.rank),
                  ),
                  _InfoRow(
                    label: 'Konten eksplisit',
                    value: detail.explicit ? 'Ya' : 'Tidak',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
