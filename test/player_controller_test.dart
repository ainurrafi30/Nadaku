import 'package:flutter_test/flutter_test.dart';
import 'package:nadaku/models/album.dart';
import 'package:nadaku/models/artist.dart';
import 'package:nadaku/models/track.dart';
import 'package:nadaku/services/audio_engine.dart';
import 'package:nadaku/services/player_controller.dart';

import 'helpers/fake_audio_engine.dart';

Track _track(int id, {String? preview}) {
  return Track(
    id: id,
    title: 'Lagu $id',
    durationSeconds: 200,
    previewUrl: preview ?? 'https://example.com/$id.mp3',
    artist: const Artist(id: 1, name: 'Artis'),
    album: const Album(id: 1, title: 'Album'),
  );
}

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late Track Function(int id) onRefresh;

  setUp(() {
    engine = FakeAudioEngine();
    onRefresh = (id) => _track(id, preview: 'https://example.com/fresh-$id.mp3');
    controller = PlayerController(
      engine: engine,
      refreshTrack: (id) async => onRefresh(id),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('playQueue memutar lagu yang dipilih', () async {
    final tracks = <Track>[_track(1), _track(2), _track(3)];

    await controller.playQueue(tracks, tracks[1]);
    await pumpEventQueue();

    expect(controller.currentTrack?.id, 2);
    expect(controller.isPlaying, isTrue);
    expect(engine.loadedUrls, <String>['https://example.com/2.mp3']);
  });

  test('lagu tanpa preview dilewati dari antrean', () async {
    final tracks = <Track>[_track(1), _track(2, preview: ''), _track(3)];

    await controller.playQueue(tracks, tracks.first);
    await controller.next();
    await pumpEventQueue();

    expect(controller.currentTrack?.id, 3);
    expect(controller.hasNext, isFalse);
  });

  test('menekan lagu yang sedang aktif menjeda pemutaran', () async {
    final tracks = <Track>[_track(1)];

    await controller.playQueue(tracks, tracks.first);
    await pumpEventQueue();
    expect(controller.isPlaying, isTrue);

    await controller.playQueue(tracks, tracks.first);
    await pumpEventQueue();
    expect(controller.isPlaying, isFalse);
    expect(engine.loadedUrls, hasLength(1));
  });

  test('previous kembali ke lagu sebelumnya', () async {
    final tracks = <Track>[_track(1), _track(2), _track(3)];

    await controller.playQueue(tracks, tracks[1]);
    await pumpEventQueue();
    await controller.previous();
    await pumpEventQueue();

    expect(controller.currentTrack?.id, 1);
  });

  test('lagu yang selesai otomatis berpindah ke lagu berikutnya', () async {
    final tracks = <Track>[_track(1), _track(2)];

    await controller.playQueue(tracks, tracks.first);
    await pumpEventQueue();
    engine.complete();
    await pumpEventQueue();

    expect(controller.currentTrack?.id, 2);
    expect(controller.isPlaying, isTrue);
  });

  test('mode ulangi memutar ulang lagu yang sama', () async {
    final tracks = <Track>[_track(1), _track(2)];

    await controller.playQueue(tracks, tracks.first);
    await pumpEventQueue();
    controller.toggleRepeat();
    engine.complete();
    await pumpEventQueue();

    expect(controller.currentTrack?.id, 1);
    expect(engine.loadedUrls, hasLength(1));
    expect(controller.isPlaying, isTrue);
  });

  test('URL preview kedaluwarsa diperbarui lalu dicoba sekali lagi', () async {
    engine.failNextSetUrlWith = const AudioEngineException('403');
    final tracks = <Track>[_track(1)];

    await controller.playQueue(tracks, tracks.first);
    await pumpEventQueue();

    expect(engine.loadedUrls, <String>['https://example.com/fresh-1.mp3']);
    expect(controller.errorMessage, isNull);
    expect(controller.isPlaying, isTrue);
  });

  test('gagal memuat menampilkan pesan kesalahan', () async {
    onRefresh = (id) => _track(id, preview: '');
    engine.failNextSetUrlWith = const AudioEngineException('403');
    final tracks = <Track>[_track(1)];

    await controller.playQueue(tracks, tracks.first);
    await pumpEventQueue();

    expect(controller.errorMessage, 'Preview lagu ini tidak tersedia.');
    expect(controller.isPlaying, isFalse);
  });
}
