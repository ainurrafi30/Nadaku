/// Konfigurasi global aplikasi Nadaku.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Nadaku';

  /// Base URL Deezer Public API. Endpoint yang dipakai tidak memerlukan API key.
  static const String apiBaseUrl = 'https://api.deezer.com';

  /// Batas waktu tunggu untuk setiap permintaan HTTP.
  static const Duration requestTimeout = Duration(seconds: 15);

  static const int chartTrackLimit = 30;
  static const int chartArtistLimit = 15;
  static const int chartAlbumLimit = 15;
  static const int searchLimit = 40;
}
