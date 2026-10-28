import '../core/json_utils.dart';
import 'artist.dart';

/// Album musik dari Deezer API.
class Album {
  const Album({
    required this.id,
    required this.title,
    this.coverMedium = '',
    this.coverBig = '',
    this.coverXl = '',
    this.releaseDate,
    this.trackCount,
    this.label,
    this.genres = const <String>[],
    this.artist,
    this.recordType,
  });

  final int id;
  final String title;
  final String coverMedium;
  final String coverBig;
  final String coverXl;

  /// Tanggal rilis berformat yyyy-MM-dd.
  final String? releaseDate;
  final int? trackCount;
  final String? label;
  final List<String> genres;
  final Artist? artist;

  /// Jenis rilisan, misalnya album, single, atau ep.
  final String? recordType;

  /// Sampul beresolusi tertinggi yang tersedia (kosong jika tidak ada).
  String get bestCover {
    if (coverXl.isNotEmpty) return coverXl;
    if (coverBig.isNotEmpty) return coverBig;
    return coverMedium;
  }

  /// Sampul berukuran sedang (500 px) untuk halaman detail; hemat memori.
  String get displayCover {
    if (coverBig.isNotEmpty) return coverBig;
    if (coverXl.isNotEmpty) return coverXl;
    return coverMedium;
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    final genreItems = asMapList(asMap(json['genres'])['data']);
    final artistJson = json['artist'];

    return Album(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Album tidak dikenal'),
      coverMedium: asString(json['cover_medium']),
      coverBig: asString(json['cover_big']),
      coverXl: asString(json['cover_xl']),
      releaseDate: asStringOrNull(json['release_date']),
      trackCount: asIntOrNull(json['nb_tracks']),
      label: asStringOrNull(json['label']),
      genres: genreItems
          .map((genre) => asString(genre['name']))
          .where((name) => name.isNotEmpty)
          .toList(),
      artist: artistJson is Map ? Artist.fromJson(asMap(artistJson)) : null,
      recordType: asStringOrNull(json['record_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'cover_medium': coverMedium,
      'cover_big': coverBig,
      'cover_xl': coverXl,
      if (releaseDate != null) 'release_date': releaseDate,
      if (trackCount != null) 'nb_tracks': trackCount,
      if (label != null) 'label': label,
      if (recordType != null) 'record_type': recordType,
      if (artist != null) 'artist': artist!.toJson(),
    };
  }
}
