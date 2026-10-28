import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nadaku/services/api_exception.dart';
import 'package:nadaku/services/deezer_service.dart';

const String _tracksBody = '''
{"data":[
  {"id":3135556,"title":"Harder, Better, Faster, Stronger","duration":224,"rank":900000,
   "explicit_lyrics":false,"preview":"https://example.com/p1.mp3",
   "artist":{"id":27,"name":"Daft Punk"},"album":{"id":302127,"title":"Discovery"}},
  {"id":2,"title":"Tanpa Preview","duration":100,"preview":"",
   "artist":{"id":1,"name":"Beyoncé"},"album":{"id":9,"title":"Album B"}}
],"total":2}
''';

const String _albumBody = '''
{"id":302127,"title":"Discovery","release_date":"2001-03-07","nb_tracks":2,
 "record_type":"album","artist":{"id":27,"name":"Daft Punk"},
 "genres":{"data":[{"id":113,"name":"Dance"}]},
 "tracks":{"data":[
   {"id":10,"title":"One More Time","duration":320,"preview":"https://example.com/a.mp3",
    "artist":{"id":27,"name":"Daft Punk"}},
   {"id":11,"title":"Aerodynamic","duration":212,"preview":"https://example.com/b.mp3",
    "artist":{"id":27,"name":"Daft Punk"}}
 ]}}
''';

http.Response _json(String body, {int status = 200}) {
  return http.Response.bytes(
    utf8.encode(body),
    status,
    headers: const <String, String>{'content-type': 'application/json'},
  );
}

DeezerService _service(Future<http.Response> Function(http.Request) handler) {
  return DeezerService(client: MockClient(handler));
}

Matcher _apiError(ApiErrorType type) {
  return throwsA(
    isA<ApiException>().having((error) => error.type, 'type', type),
  );
}

void main() {
  group('Pengambilan data chart', () {
    test('mengubah JSON menjadi daftar Track', () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return _json(_tracksBody);
      });

      final tracks = await service.fetchChartTracks(limit: 2);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/chart/0/tracks');
      expect(captured.url.queryParameters['limit'], '2');
      expect(tracks, hasLength(2));
      expect(tracks.first.title, 'Harder, Better, Faster, Stronger');
      expect(tracks.first.artist.name, 'Daft Punk');
      expect(tracks.first.hasPreview, isTrue);
      expect(tracks.last.hasPreview, isFalse);
    });

    test('membaca karakter UTF-8 dengan benar', () async {
      final service = _service((request) async => _json(_tracksBody));

      final tracks = await service.fetchChartTracks();

      expect(tracks.last.artist.name, 'Beyoncé');
    });

    test('memakai genreId pada alamat endpoint', () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return _json('{"data":[]}');
      });

      await service.fetchChartTracks(genreId: 132);

      expect(captured.url.path, '/chart/132/tracks');
    });

    test('fetchHomeData menggabungkan tiga permintaan paralel', () async {
      final paths = <String>[];
      final service = _service((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/chart/0/tracks') return _json(_tracksBody);
        if (request.url.path == '/chart/0/artists') {
          return _json('{"data":[{"id":27,"name":"Daft Punk"}]}');
        }
        return _json('{"data":[{"id":302127,"title":"Discovery"}]}');
      });

      final home = await service.fetchHomeData();

      expect(paths, hasLength(3));
      expect(home.tracks, hasLength(2));
      expect(home.artists.single.name, 'Daft Punk');
      expect(home.albums.single.title, 'Discovery');
    });
  });

  group('Pencarian', () {
    test('mengirim kata kunci pada parameter q', () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return _json(_tracksBody);
      });

      final results = await service.searchTracks('  daft punk ');

      expect(captured.url.path, '/search');
      expect(captured.url.queryParameters['q'], 'daft punk');
      expect(results, hasLength(2));
    });

    test('kata kunci kosong tidak mengirim permintaan', () async {
      var calls = 0;
      final service = _service((request) async {
        calls++;
        return _json(_tracksBody);
      });

      final results = await service.searchTracks('   ');

      expect(results, isEmpty);
      expect(calls, 0);
    });
  });

  group('Detail', () {
    test('fetchTrack membaca tanggal rilis dan BPM', () async {
      final service = _service((request) async {
        expect(request.url.path, '/track/3135556');
        return _json(
          '{"id":3135556,"title":"Harder","duration":224,"preview":"https://example.com/p.mp3",'
          '"release_date":"2001-03-07","bpm":123,'
          '"artist":{"id":27,"name":"Daft Punk"},"album":{"id":302127,"title":"Discovery"}}',
        );
      });

      final track = await service.fetchTrack(3135556);

      expect(track.releaseDate, '2001-03-07');
      expect(track.bpm, 123);
    });

    test('fetchAlbumDetail menyisipkan album ke setiap lagu', () async {
      final service = _service((request) async => _json(_albumBody));

      final detail = await service.fetchAlbumDetail(302127);

      expect(detail.album.title, 'Discovery');
      expect(detail.album.genres, <String>['Dance']);
      expect(detail.tracks, hasLength(2));
      expect(detail.tracks.first.album.title, 'Discovery');
      expect(detail.tracks.first.artist.name, 'Daft Punk');
    });
  });

  group('Penanganan kesalahan', () {
    test('status HTTP selain 200 menjadi ApiException bertipe server', () async {
      final service = _service((request) async {
        return http.Response('Internal Server Error', 500);
      });

      await expectLater(service.fetchChartTracks(), _apiError(ApiErrorType.server));
    });

    test('isi error dari Deezer (kode 4) menjadi ApiException bertipe api', () async {
      final service = _service((request) async {
        return _json(
          '{"error":{"type":"Exception","message":"Quota limit exceeded","code":4}}',
        );
      });

      await expectLater(service.fetchChartTracks(), _apiError(ApiErrorType.api));
    });

    test('JSON rusak menjadi ApiException bertipe parse', () async {
      final service = _service((request) async => _json('bukan json'));

      await expectLater(service.fetchChartTracks(), _apiError(ApiErrorType.parse));
    });

    test('tidak ada koneksi menjadi ApiException bertipe network', () async {
      final service = _service((request) async {
        throw const SocketException('Failed host lookup');
      });

      await expectLater(service.fetchChartTracks(), _apiError(ApiErrorType.network));
    });
  });
}
