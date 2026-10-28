import '../core/json_utils.dart';

/// Genre musik dari Deezer API (dipakai sebagai filter chart di Beranda).
class Genre {
  const Genre({required this.id, required this.name});

  final int id;
  final String name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    final id = asInt(json['id']);
    return Genre(
      id: id,
      name: id == 0 ? 'Semua' : asString(json['name'], fallback: 'Genre $id'),
    );
  }
}
