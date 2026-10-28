import 'dart:async';

import 'package:nadaku/services/audio_engine.dart';

/// Mesin audio palsu untuk pengujian: tidak butuh perangkat maupun jaringan.
class FakeAudioEngine implements AudioEngine {
  final StreamController<EngineState> _state =
      StreamController<EngineState>.broadcast();
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _duration =
      StreamController<Duration?>.broadcast();

  /// URL yang berhasil dimuat, berurutan.
  final List<String> loadedUrls = <String>[];

  /// Jika diisi, pemanggilan setUrl berikutnya melempar error ini satu kali.
  Object? failNextSetUrlWith;

  bool _playing = false;

  @override
  Stream<EngineState> get stateStream => _state.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Future<void> setUrl(String url) async {
    final failure = failNextSetUrlWith;
    if (failure != null) {
      failNextSetUrlWith = null;
      throw failure;
    }
    loadedUrls.add(url);
    _duration.add(const Duration(seconds: 30));
    _state.add(EngineState(playing: _playing, status: EngineStatus.ready));
  }

  @override
  Future<void> play() async {
    _playing = true;
    _state.add(const EngineState(playing: true, status: EngineStatus.ready));
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _state.add(const EngineState(playing: false, status: EngineStatus.ready));
  }

  @override
  Future<void> seek(Duration position) async {
    _position.add(position);
  }

  @override
  Future<void> dispose() async {
    await _state.close();
    await _position.close();
    await _duration.close();
  }

  /// Mensimulasikan lagu yang selesai diputar.
  void complete() {
    _state.add(const EngineState(playing: true, status: EngineStatus.completed));
  }
}
