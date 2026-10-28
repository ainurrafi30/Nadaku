/// Jenis kesalahan yang mungkin terjadi saat mengambil data dari API.
enum ApiErrorType { network, timeout, server, parse, api, unknown }

/// Kesalahan terstruktur dengan pesan yang ramah bagi pengguna.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.type = ApiErrorType.unknown,
    this.statusCode,
  });

  final String message;
  final ApiErrorType type;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ', status $statusCode';
    return 'ApiException(${type.name}$code): $message';
  }
}

/// Mengubah error apa pun menjadi pesan yang aman ditampilkan ke pengguna.
String describeError(Object error) {
  if (error is ApiException) return error.message;
  return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
}
