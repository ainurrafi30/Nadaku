import 'package:flutter_test/flutter_test.dart';
import 'package:nadaku/models/album.dart';
import 'package:nadaku/models/artist.dart';
import 'package:nadaku/models/track.dart';
import 'package:nadaku/services/favorites_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Track _track(int id) {
  return Track(
    id: id,
    title: 'Lagu $id',
    durationSeconds: 200,
    previewUrl: 'https://example.com/$id.mp3',
    artist: const Artist(id: 1, name: 'Artis'),
    album: const Album(id: 1, title: 'Album'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferences.getInstance();
  }

  test('toggle menambah lalu menghapus lagu favorit', () async {
    final controller = FavoritesController(await freshPrefs());

    await controller.toggle(_track(1));
    expect(controller.isFavorite(_track(1)), isTrue);
    expect(controller.count, 1);

    await controller.toggle(_track(1));
    expect(controller.isFavorite(_track(1)), isFalse);
    expect(controller.count, 0);
  });

  test('favorit tetap tersimpan setelah controller dibuat ulang', () async {
    final prefs = await freshPrefs();
    final first = FavoritesController(prefs);
    await first.toggle(_track(1));
    await first.toggle(_track(2));

    final second = FavoritesController(prefs);

    expect(second.count, 2);
    // Lagu terbaru ditempatkan paling atas.
    expect(second.items.first.id, 2);
    expect(second.items.last.title, 'Lagu 1');
  });
}
