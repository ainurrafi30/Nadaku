import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Status pemrosesan audio yang tidak bergantung pada package tertentu.
enum EngineStatus { idle, loading, buffering, ready, completed }

class EngineState {
  const EngineState({required this.playing, required this.status});

  final bool playing;
  final EngineStatus status;
}

/// Dilempar ketika audio gagal dimuat atau diputar.
class AudioEngineException implements Exception {
  const AudioEngineException(this.message);

  final String message;

  @override
  String toString() => 'AudioEngineException: $message';
}

/// Dilempar ketika pemuatan dibatalkan karena ada permintaan pemuatan baru.
class AudioEngineInterrupted implements Exception {
  const AudioEngineInterrupted();
}

/// Abstraksi mesin audio agar logika pemutar dapat diuji tanpa perangkat.
abstract class AudioEngine {
  Stream<EngineState> get stateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  Future<void> setUrl(String url);

  /// Memulai pemutaran tanpa menunggu lagu selesai.
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// Implementasi [AudioEngine] memakai package just_audio.
class JustAudioEngine implements AudioEngine {
  JustAudioEngine({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<EngineState> get stateStream => _player.playerStateStream.map(
        (state) => EngineState(
          playing: state.playing,
          status: _mapStatus(state.processingState),
        ),
      );

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> setUrl(String url) async {
    try {
      await _player.setUrl(url);
    } on PlayerInterruptedException {
      throw const AudioEngineInterrupted();
    } on PlayerException catch (error) {
      throw AudioEngineException(
        error.message ?? 'Audio tidak dapat dimuat.',
      );
    }
  }

  /// Future dari AudioPlayer.play() baru selesai saat lagu berhenti,
  /// sehingga sengaja tidak di-await agar pemanggil tidak terblokir.
  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() => _player.dispose();

  EngineStatus _mapStatus(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return EngineStatus.idle;
      case ProcessingState.loading:
        return EngineStatus.loading;
      case ProcessingState.buffering:
        return EngineStatus.buffering;
      case ProcessingState.ready:
        return EngineStatus.ready;
      case ProcessingState.completed:
        return EngineStatus.completed;
    }
  }
}
