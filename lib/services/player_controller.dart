import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/track.dart';
import 'api_exception.dart';
import 'audio_engine.dart';

/// Fungsi untuk mengambil data terbaru sebuah lagu (memperbarui URL preview).
typedef TrackRefresher = Future<Track> Function(int trackId);

/// Posisi dan durasi pemutaran yang diperbarui terus-menerus saat lagu diputar.
class PlaybackProgress {
  const PlaybackProgress({
    this.position = Duration.zero,
    this.total = Duration.zero,
  });

  static const PlaybackProgress zero = PlaybackProgress();

  final Duration position;
  final Duration total;

  /// Nilai 0.0 sampai 1.0 untuk slider dan progress bar.
  double get fraction {
    if (total.inMilliseconds <= 0) return 0;
    final value = position.inMilliseconds / total.inMilliseconds;
    return value.clamp(0.0, 1.0).toDouble();
  }
}

/// Pengelola antrean dan status pemutaran preview lagu.
///
/// Controller ini adalah [ChangeNotifier]: widget cukup mendengarkannya dengan
/// ListenableBuilder, sedangkan posisi lagu diumumkan lewat [progress] agar
/// hanya slider yang digambar ulang setiap beberapa ratus milidetik.
class PlayerController extends ChangeNotifier {
  PlayerController({
    required AudioEngine engine,
    required TrackRefresher refreshTrack,
  })  : _engine = engine,
        _refreshTrack = refreshTrack {
    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      _engine.stateStream.listen(_onEngineState),
      _engine.positionStream.listen(_onPosition),
      _engine.durationStream.listen(_onDuration),
    ]);
  }

  final AudioEngine _engine;
  final TrackRefresher _refreshTrack;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  /// Posisi dan durasi lagu saat ini.
  final ValueNotifier<PlaybackProgress> progress =
      ValueNotifier<PlaybackProgress>(PlaybackProgress.zero);

  List<Track> _queue = const <Track>[];
  int _index = -1;
  bool _playing = false;
  bool _loading = false;
  bool _buffering = false;
  bool _repeat = false;
  String? _errorMessage;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  int _loadToken = 0;

  Track? get currentTrack =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  List<Track> get queue => _queue;
  bool get isPlaying => _playing;
  bool get isLoading => _loading;
  bool get isBuffering => _buffering;
  bool get repeatEnabled => _repeat;
  String? get errorMessage => _errorMessage;
  bool get hasNext => _index >= 0 && _index < _queue.length - 1;
  bool get hasPrevious => _index > 0;

  bool isCurrent(Track track) => currentTrack?.id == track.id;

  // ---------------------------------------------------------------------------
  // Perintah dari antarmuka
  // ---------------------------------------------------------------------------

  /// Memutar [start] dan menjadikan [tracks] sebagai antrean.
  /// Lagu tanpa preview otomatis dilewati dari antrean.
  Future<void> playQueue(List<Track> tracks, Track start) async {
    final playable = tracks.where((track) => track.hasPreview).toList();
    if (playable.isEmpty) return;

    var startIndex = playable.indexWhere((track) => track.id == start.id);
    if (startIndex < 0) startIndex = 0;

    // Menekan lagu yang sedang aktif pada antrean yang sama: jeda atau lanjutkan.
    if (currentTrack?.id == playable[startIndex].id && _sameQueue(playable)) {
      await togglePlayPause();
      return;
    }

    _queue = List<Track>.unmodifiable(playable);
    await _loadAt(startIndex);
  }

  Future<void> togglePlayPause() async {
    if (currentTrack == null) return;

    // Setelah gagal memuat, menekan tombol putar berarti mencoba lagi.
    if (_errorMessage != null) {
      await _loadAt(_index);
      return;
    }

    if (_playing) {
      await _engine.pause();
    } else {
      await _engine.play();
    }
  }

  Future<void> next() async {
    if (hasNext) await _loadAt(_index + 1);
  }

  Future<void> previous() async {
    if (currentTrack == null) return;

    // Jika lagu sudah berjalan lebih dari 3 detik, kembali ke awal lagu.
    if (_position > const Duration(seconds: 3) || !hasPrevious) {
      await _engine.seek(Duration.zero);
      return;
    }
    await _loadAt(_index - 1);
  }

  Future<void> seek(Duration position) => _engine.seek(position);

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Logika internal
  // ---------------------------------------------------------------------------

  bool _sameQueue(List<Track> other) {
    if (other.length != _queue.length) return false;
    for (var i = 0; i < other.length; i++) {
      if (other[i].id != _queue[i].id) return false;
    }
    return true;
  }

  Future<void> _loadAt(int index) async {
    if (index < 0 || index >= _queue.length) return;

    // Token menandai permintaan terbaru; hasil permintaan lama diabaikan.
    final token = ++_loadToken;

    _index = index;
    _loading = true;
    _errorMessage = null;
    _position = Duration.zero;
    _total = Duration.zero;
    _publishProgress();
    notifyListeners();

    try {
      await _prepare(index);
      if (token != _loadToken) return;
      await _engine.play();
    } on AudioEngineInterrupted {
      return;
    } catch (error) {
      if (token != _loadToken) return;
      _errorMessage = error is AudioEngineException
          ? error.message
          : describeError(error);
      _playing = false;
      unawaited(_engine.pause());
    } finally {
      if (token == _loadToken) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _prepare(int index) async {
    final track = _queue[index];

    try {
      await _engine.setUrl(track.previewUrl);
    } on AudioEngineInterrupted {
      rethrow;
    } on AudioEngineException {
      // URL preview Deezer memakai token yang dapat kedaluwarsa. Ambil data
      // terbaru lagu tersebut lalu coba sekali lagi sebelum menyerah.
      final fresh = await _refreshTrack(track.id);
      if (!fresh.hasPreview) {
        throw const AudioEngineException('Preview lagu ini tidak tersedia.');
      }
      if (index >= _queue.length || _queue[index].id != track.id) {
        throw const AudioEngineInterrupted();
      }

      final updated = List<Track>.of(_queue);
      updated[index] = track.copyWith(previewUrl: fresh.previewUrl);
      _queue = List<Track>.unmodifiable(updated);
      await _engine.setUrl(fresh.previewUrl);
    }
  }

  void _onEngineState(EngineState state) {
    _buffering = state.status == EngineStatus.loading ||
        state.status == EngineStatus.buffering;
    _playing = state.playing && state.status != EngineStatus.completed;
    notifyListeners();

    if (state.status == EngineStatus.completed && state.playing) {
      _handleCompleted();
    }
  }

  void _handleCompleted() {
    if (_repeat) {
      unawaited(_restartCurrent());
    } else if (hasNext) {
      unawaited(_loadAt(_index + 1));
    } else {
      unawaited(_stopAtEnd());
    }
  }

  Future<void> _restartCurrent() async {
    await _engine.seek(Duration.zero);
    await _engine.play();
  }

  Future<void> _stopAtEnd() async {
    await _engine.pause();
    await _engine.seek(Duration.zero);
  }

  void _onPosition(Duration position) {
    _position = position;
    _publishProgress();
  }

  void _onDuration(Duration? duration) {
    _total = duration ?? Duration.zero;
    _publishProgress();
  }

  void _publishProgress() {
    progress.value = PlaybackProgress(position: _position, total: _total);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    progress.dispose();
    unawaited(_engine.dispose());
    super.dispose();
  }
}
