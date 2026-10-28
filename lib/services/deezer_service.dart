import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/json_utils.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/genre.dart';
import '../models/screen_data.dart';
import '../models/track.dart';
import 'api_exception.dart';

/// Klien untuk Deezer Public API (https://developers.deezer.com/api).
///
/// Seluruh method bersifat asinkron (mengembalikan [Future]) dan melempar
/// [ApiException] dengan pesan yang jelas jika terjadi kegagalan.
class DeezerService {
  DeezerService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() => _client.close();

  // ---------------------------------------------------------------------------
  // Permintaan HTTP dasar
  // ---------------------------------------------------------------------------

  /// Mengirim permintaan GET, memeriksa status respons, lalu mendekode JSON.
  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri =
        Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: query);

    try {
      final response = await _client
          .get(uri, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Server mengembalikan kode status ${response.statusCode}. '
          'Silakan coba lagi beberapa saat lagi.',
          type: ApiErrorType.server,
          statusCode: response.statusCode,
        );
      }

      // bodyBytes didekode sebagai UTF-8 agar karakter khusus (é, ñ, dll.) benar.
      final Object? decoded =
          jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
      if (decoded is! Map) {
        throw const ApiException(
          'Format respons dari server tidak dikenali.',
          type: ApiErrorType.parse,
        );
      }

      final body = Map<String, dynamic>.from(decoded);

      // Deezer dapat membalas HTTP 200 dengan isi {"error": {...}}.
      final error = body['error'];
      if (error is Map) {
        throw _mapApiError(Map<String, dynamic>.from(error));
      }
      return body;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu tunggu habis. Periksa koneksi internet Anda lalu coba lagi.',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        type: ApiErrorType.network,
      );
    } on http.ClientException {
      throw const ApiException(
        'Koneksi ke server terputus. Periksa koneksi internet Anda.',
        type: ApiErrorType.network,
      );
    } on FormatException {
      throw const ApiException(
        'Data dari server tidak dapat diproses.',
        type: ApiErrorType.parse,
      );
    }
  }

  ApiException _mapApiError(Map<String, dynamic> error) {
    final code = asInt(error['code']);
    final message = asString(error['message']);

    switch (code) {
      case 4:
        return const ApiException(
          'Batas permintaan ke API tercapai. Tunggu beberapa detik lalu coba lagi.',
          type: ApiErrorType.api,
        );
      case 700:
        return const ApiException(
          'Layanan Deezer sedang sibuk. Coba lagi beberapa saat lagi.',
          type: ApiErrorType.api,
        );
      case 800:
        return const ApiException(
          'Data yang diminta tidak ditemukan.',
          type: ApiErrorType.api,
        );
      default:
        return ApiException(
          message.isEmpty
              ? 'API mengembalikan kesalahan (kode $code).'
              : 'API mengembalikan kesalahan: $message',
          type: ApiErrorType.api,
        );
    }
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> body) {
    return asMapList(body['data']);
  }

  // ---------------------------------------------------------------------------
  // Chart & genre (Beranda)
  // ---------------------------------------------------------------------------

  Future<List<Track>> fetchChartTracks({
    int genreId = 0,
    int limit = AppConfig.chartTrackLimit,
  }) async {
    final body = await _getJson(
      '/chart/$genreId/tracks',
      query: <String, String>{'limit': '$limit'},
    );
    return _dataList(body)
        .map((json) => Track.fromJson(json))
        .where((track) => track.id != 0)
        .toList();
  }

  Future<List<Artist>> fetchChartArtists({
    int genreId = 0,
    int limit = AppConfig.chartArtistLimit,
  }) async {
    final body = await _getJson(
      '/chart/$genreId/artists',
      query: <String, String>{'limit': '$limit'},
    );
    return _dataList(body)
        .map((json) => Artist.fromJson(json))
        .where((artist) => artist.id != 0)
        .toList();
  }

  Future<List<Album>> fetchChartAlbums({
    int genreId = 0,
    int limit = AppConfig.chartAlbumLimit,
  }) async {
    final body = await _getJson(
      '/chart/$genreId/albums',
      query: <String, String>{'limit': '$limit'},
    );
    return _dataList(body)
        .map((json) => Album.fromJson(json))
        .where((album) => album.id != 0)
        .toList();
  }

  Future<List<Genre>> fetchGenres() async {
    final body = await _getJson('/genre');
    return _dataList(body).map((json) => Genre.fromJson(json)).toList();
  }

  /// Mengambil tiga chart (lagu, artis, album) secara paralel.
  ///
  /// Future.wait (versi list) meneruskan error asli (ApiException), sehingga
  /// pesan kesalahan tetap jelas bagi pengguna.
  Future<HomeData> fetchHomeData({int genreId = 0}) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      fetchChartTracks(genreId: genreId),
      fetchChartArtists(genreId: genreId),
      fetchChartAlbums(genreId: genreId),
    ]);

    return HomeData(
      tracks: results[0] as List<Track>,
      artists: results[1] as List<Artist>,
      albums: results[2] as List<Album>,
    );
  }

  // ---------------------------------------------------------------------------
  // Pencarian & detail
  // ---------------------------------------------------------------------------

  Future<List<Track>> searchTracks(
    String query, {
    int limit = AppConfig.searchLimit,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const <Track>[];

    final body = await _getJson(
      '/search',
      query: <String, String>{'q': keyword, 'limit': '$limit'},
    );
    return _dataList(body)
        .map((json) => Track.fromJson(json))
        .where((track) => track.id != 0)
        .toList();
  }

  /// Detail satu lagu. Juga dipakai untuk memperbarui URL preview yang
  /// bertoken (dapat kedaluwarsa) sebelum diputar.
  Future<Track> fetchTrack(int id) async {
    final body = await _getJson('/track/$id');
    return Track.fromJson(body);
  }

  Future<ArtistDetail> fetchArtistDetail(int id) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      _getJson('/artist/$id'),
      _getJson('/artist/$id/top', query: <String, String>{'limit': '20'}),
      _getJson('/artist/$id/albums', query: <String, String>{'limit': '20'}),
    ]);

    final artist = Artist.fromJson(results[0] as Map<String, dynamic>);
    final topTracks = _dataList(results[1] as Map<String, dynamic>)
        .map((json) => Track.fromJson(json, fallbackArtist: artist))
        .where((track) => track.id != 0)
        .toList();
    final albums = _dataList(results[2] as Map<String, dynamic>)
        .map((json) => Album.fromJson(json))
        .where((album) => album.id != 0)
        .toList();

    return ArtistDetail(artist: artist, topTracks: topTracks, albums: albums);
  }

  Future<AlbumDetail> fetchAlbumDetail(int id) async {
    final body = await _getJson('/album/$id');
    final album = Album.fromJson(body);

    // Lagu di dalam album tidak memuat objek album, jadi disisipkan manual.
    final tracks = asMapList(asMap(body['tracks'])['data'])
        .map(
          (json) => Track.fromJson(
            json,
            fallbackAlbum: album,
            fallbackArtist: album.artist,
          ),
        )
        .where((track) => track.id != 0)
        .toList();

    return AlbumDetail(album: album, tracks: tracks);
  }
}
