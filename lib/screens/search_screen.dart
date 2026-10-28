import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../models/track.dart';
import '../widgets/state_views.dart';
import '../widgets/track_tile.dart';

/// Pencarian lagu berdasarkan judul atau nama artis (dengan debounce).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _suggestions = <String>[
    'Tulus',
    'Sheila on 7',
    'Dewa 19',
    'Hindia',
    'Raisa',
    'NOAH',
    'Coldplay',
    'Taylor Swift',
    'Bruno Mars',
    'Ed Sheeran',
  ];

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _activeQuery = '';
  Future<List<Track>>? _future;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Menunda pencarian 500 ms setelah pengguna berhenti mengetik agar tidak
  /// mengirim permintaan pada setiap huruf (menghemat kuota API).
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _search(value);
  }

  void _search(String value) {
    if (!mounted) return;
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _activeQuery = '';
        _future = null;
      });
      return;
    }
    if (query == _activeQuery && _future != null) return;

    setState(() {
      _activeQuery = query;
      _future = AppScope.of(context).api.searchTracks(query);
    });
  }

  void _retry() {
    final query = _activeQuery;
    if (query.isEmpty) return;
    setState(() {
      _future = AppScope.of(context).api.searchTracks(query);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _activeQuery = '';
      _future = null;
    });
  }

  void _pickSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _debounce?.cancel();
    _search(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Cari',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Judul lagu atau nama artis',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clear,
                    );
                  },
                ),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final future = _future;
    if (future == null) {
      return _SearchIdle(suggestions: _suggestions, onPick: _pickSuggestion);
    }

    return FutureBuilder<List<Track>>(
      future: future,
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingView(message: 'Mencari "$_activeQuery"…');
        }
        // 2. Error
        if (snapshot.hasError) {
          return ErrorView(error: snapshot.error!, onRetry: _retry);
        }
        // 3. Success (data kosong ditangani terpisah)
        final results = snapshot.data ?? const <Track>[];
        if (results.isEmpty) {
          return EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada hasil',
            message:
                'Tidak ada lagu untuk "$_activeQuery". Coba kata kunci lain atau periksa ejaannya.',
          );
        }

        final player = AppScope.of(context).player;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: results.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '${results.length} lagu untuk "$_activeQuery"',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            final track = results[index - 1];
            return TrackTile(
              key: ValueKey<int>(track.id),
              track: track,
              onPlay: () => player.playQueue(results, track),
            );
          },
        );
      },
    );
  }
}

class _SearchIdle extends StatelessWidget {
  const _SearchIdle({required this.suggestions, required this.onPick});

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        const Icon(
          Icons.queue_music_rounded,
          size: 56,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        const Text(
          'Temukan lagu favorit Anda',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ketik judul lagu atau nama artis, atau mulai dari saran di bawah ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final suggestion in suggestions)
              ActionChip(
                label: Text(suggestion),
                backgroundColor: AppColors.surfaceHigh,
                side: BorderSide.none,
                onPressed: () => onPick(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}
