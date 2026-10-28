import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nadaku/main.dart';
import 'package:nadaku/services/api_exception.dart';
import 'package:nadaku/services/deezer_service.dart';
import 'package:nadaku/services/favorites_controller.dart';
import 'package:nadaku/services/player_controller.dart';
import 'package:nadaku/widgets/state_views.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_audio_engine.dart';

// Data uji sengaja tidak memuat URL gambar agar pengujian tidak memakai jaringan.
const String _chartBody = '''
{"data":[
  {"id":1,"title":"Lagu Chart Satu","duration":200,"preview":"https://example.com/1.mp3",
   "artist":{"id":10,"name":"Artis Satu"},"album":{"id":20,"title":"Album Satu"}},
  {"id":2,"title":"Lagu Chart Dua","duration":180,"preview":"https://example.com/2.mp3",
   "artist":{"id":11,"name":"Artis Dua"},"album":{"id":21,"title":"Album Dua"}}
]}
''';

const String _searchBody = '''
{"data":[
  {"id":3,"title":"Hasil Cari Satu","duration":210,"preview":"https://example.com/3.mp3",
   "artist":{"id":12,"name":"Penyanyi Uji"},"album":{"id":22,"title":"Album Uji"}}
]}
''';

http.Response _json(String body) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: const <String, String>{'content-type': 'application/json'},
  );
}

http.Response _route(http.Request request) {
  final path = request.url.path;
  if (path == '/genre') {
    return _json('{"data":[{"id":0,"name":"All"},{"id":132,"name":"Pop"}]}');
  }
  if (path == '/chart/0/tracks' || path == '/chart/132/tracks') {
    return _json(_chartBody);
  }
  if (path.startsWith('/chart/')) {
    return _json('{"data":[]}');
  }
  if (path == '/search') {
    final keyword = request.url.queryParameters['q'] ?? '';
    return keyword == 'tulus' ? _json(_searchBody) : _json('{"data":[]}');
  }
  return http.Response('Not Found', 404);
}

Future<void> _pumpApp(
  WidgetTester tester,
  http.Response Function(http.Request) route, {
  List<String>? log,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();

  final api = DeezerService(
    client: MockClient((request) async {
      log?.add(request.url.path);
      return route(request);
    }),
  );
  final player = PlayerController(
    engine: FakeAudioEngine(),
    refreshTrack: api.fetchTrack,
  );

  await tester.pumpWidget(
    NadakuApp(api: api, player: player, favorites: FavoritesController(prefs)),
  );
}

void main() {
  group('Widget state view', () {
    testWidgets('ErrorView memanggil onRetry saat tombol ditekan', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              error: const ApiException(
                'Koneksi terputus.',
                type: ApiErrorType.network,
              ),
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      expect(find.text('Tidak ada koneksi'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(retried, 1);
    });
  });

  group('Beranda', () {
    testWidgets('menampilkan loading lalu daftar lagu chart', (tester) async {
      await _pumpApp(tester, _route);

      // Frame pertama: permintaan masih berjalan.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Lagu Chart Satu'), findsOneWidget);
      expect(find.text('Lagu Chart Dua'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('menampilkan pesan error dan bisa dicoba lagi', (tester) async {
      var failing = true;
      await _pumpApp(tester, (request) {
        if (failing) return http.Response('Server Error', 500);
        return _route(request);
      });

      await tester.pumpAndSettle();
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);

      failing = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Lagu Chart Satu'), findsOneWidget);
    });

    testWidgets('memilih genre memuat chart sesuai genre', (tester) async {
      final log = <String>[];
      await _pumpApp(tester, _route, log: log);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pop'));
      await tester.pumpAndSettle();

      expect(log, contains('/chart/132/tracks'));
    });
  });

  group('Pencarian', () {
    Future<void> openSearchTab(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Cari'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan hasil untuk kata kunci', (tester) async {
      await _pumpApp(tester, _route);
      await tester.pumpAndSettle();
      await openSearchTab(tester);

      await tester.enterText(find.byType(TextField), 'tulus');
      // Melewati jeda debounce 500 ms sebelum permintaan dikirim.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Hasil Cari Satu'), findsOneWidget);
    });

    testWidgets('menampilkan keadaan kosong bila tidak ada hasil', (tester) async {
      await _pumpApp(tester, _route);
      await tester.pumpAndSettle();
      await openSearchTab(tester);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada hasil'), findsOneWidget);
    });
  });
}
