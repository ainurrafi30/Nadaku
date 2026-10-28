import '../core/json_utils.dart';
import 'album.dart';
import 'artist.dart';

/// Lagu dari Deezer API.
///
/// Class model ini mengubah objek JSON (Map) menjadi objek Dart bertipe aman.
/// Format [toJson] sengaja dibuat sama dengan format API agar data favorit
/// yang disimpan di perangkat dapat dibaca kembali dengan [Track.fromJson].
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.previewUrl,
    required this.artist,
    required this.album,
    this.rank = 0,
    this.explicit = false,
    this.link = '',
    this.releaseDate,
    this.bpm,
  });

  final int id;
  final String title;

  /// Durasi lagu penuh dalam detik (preview yang diputar hanya 30 detik).
  final int durationSeconds;

  /// URL preview MP3 30 detik. Kosong jika tidak tersedia.
  final String previewUrl;
  final Artist artist;
  final Album album;
  final int rank;
  final bool explicit;
  final String link;
  final String? releaseDate;
  final int? bpm;

  bool get hasPreview => previewUrl.isNotEmpty;

  factory Track.fromJson(
    Map<String, dynamic> json, {
    Album? fallbackAlbum,
    Artist? fallbackArtist,
  }) {
    final artistJson = json['artist'];
    final albumJson = json['album'];

    final artist = artistJson is Map
        ? Artist.fromJson(asMap(artistJson))
        : (fallbackArtist ??
            const Artist(id: 0, name: 'Artis tidak dikenal'));
    final album = albumJson is Map
        ? Album.fromJson(asMap(albumJson))
        : (fallbackAlbum ?? const Album(id: 0, title: 'Album tidak dikenal'));
    final bpmValue = asInt(json['bpm']);

    return Track(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Tanpa judul'),
      durationSeconds: asInt(json['duration']),
      previewUrl: asString(json['preview']),
      rank: asInt(json['rank']),
      explicit: asBool(json['explicit_lyrics']),
      link: asString(json['link']),
      releaseDate: asStringOrNull(json['release_date']) ?? album.releaseDate,
      bpm: bpmValue > 0 ? bpmValue : null,
      artist: artist,
      album: album,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'duration': durationSeconds,
      'preview': previewUrl,
      'rank': rank,
      'explicit_lyrics': explicit,
      'link': link,
      if (releaseDate != null) 'release_date': releaseDate,
      if (bpm != null) 'bpm': bpm,
      'artist': artist.toJson(),
      'album': album.toJson(),
    };
  }

  Track copyWith({String? previewUrl}) {
    return Track(
      id: id,
      title: title,
      durationSeconds: durationSeconds,
      previewUrl: previewUrl ?? this.previewUrl,
      artist: artist,
      album: album,
      rank: rank,
      explicit: explicit,
      link: link,
      releaseDate: releaseDate,
      bpm: bpm,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Track && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
