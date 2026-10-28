import 'package:flutter_test/flutter_test.dart';
import 'package:nadaku/core/formatters.dart';
import 'package:nadaku/models/album.dart';
import 'package:nadaku/models/artist.dart';
import 'package:nadaku/models/track.dart';

void main() {
  group('Track.fromJson', () {
    test('membaca atribut penting dari respons Deezer', () {
      final track = Track.fromJson(<String, dynamic>{
        'id': 3135556,
        'title': 'Harder, Better, Faster, Stronger',
        'duration': 224,
        'rank': 900000,
        'explicit_lyrics': true,
        'preview': 'https://example.com/p.mp3',
        'link': 'https://www.deezer.com/track/3135556',
        'bpm': 123.4,
        'artist': <String, dynamic>{'id': 27, 'name': 'Daft Punk'},
        'album': <String, dynamic>{
          'id': 302127,
          'title': 'Discovery',
          'cover_xl': 'https://example.com/xl.jpg',
          'release_date': '2001-03-07',
        },
      });

      expect(track.id, 3135556);
      expect(track.title, 'Harder, Better, Faster, Stronger');
      expect(track.durationSeconds, 224);
      expect(track.explicit, isTrue);
      expect(track.hasPreview, isTrue);
      expect(track.bpm, 123);
      expect(track.artist.name, 'Daft Punk');
      expect(track.album.title, 'Discovery');
      expect(track.album.bestCover, 'https://example.com/xl.jpg');
      // Tanggal rilis lagu diambil dari album jika tidak tersedia pada lagu.
      expect(track.releaseDate, '2001-03-07');
    });

    test('memakai nilai cadangan saat atribut hilang atau bertipe salah', () {
      final track = Track.fromJson(<String, dynamic>{
        'id': '42',
        'title': null,
        'duration': 'abc',
      });

      expect(track.id, 42);
      expect(track.title, 'Tanpa judul');
      expect(track.durationSeconds, 0);
      expect(track.hasPreview, isFalse);
      expect(track.artist.name, 'Artis tidak dikenal');
      expect(track.album.title, 'Album tidak dikenal');
    });

    test('memakai album dan artis cadangan bila objeknya tidak ada', () {
      const album = Album(id: 7, title: 'Album Induk');
      const artist = Artist(id: 8, name: 'Artis Induk');

      final track = Track.fromJson(
        <String, dynamic>{'id': 1, 'title': 'Lagu'},
        fallbackAlbum: album,
        fallbackArtist: artist,
      );

      expect(track.album.title, 'Album Induk');
      expect(track.artist.name, 'Artis Induk');
    });

    test('toJson lalu fromJson menghasilkan data yang sama (untuk favorit)', () {
      final original = Track.fromJson(<String, dynamic>{
        'id': 5,
        'title': 'Lagu Favorit',
        'duration': 180,
        'preview': 'https://example.com/fav.mp3',
        'artist': <String, dynamic>{'id': 2, 'name': 'Artis'},
        'album': <String, dynamic>{'id': 3, 'title': 'Album'},
      });

      final restored = Track.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.previewUrl, original.previewUrl);
      expect(restored.artist.name, original.artist.name);
      expect(restored.album.title, original.album.title);
    });
  });

  group('formatters', () {
    test('formatClock menampilkan menit:detik', () {
      expect(formatClock(const Duration(seconds: 75)), '1:15');
      expect(formatClock(const Duration(seconds: 5)), '0:05');
    });

    test('formatCompact memakai singkatan bahasa Indonesia', () {
      expect(formatCompact(999), '999');
      expect(formatCompact(1500), '1,5 rb');
      expect(formatCompact(2000000), '2 jt');
    });

    test('formatReleaseDate dan formatYear menangani data tidak valid', () {
      expect(formatReleaseDate('2024-05-12'), '12 Mei 2024');
      expect(formatReleaseDate('0000-00-00'), '-');
      expect(formatReleaseDate(null), '-');
      expect(formatYear('2001-03-07'), '2001');
      expect(formatYear('0000-00-00'), isNull);
    });
  });
}
