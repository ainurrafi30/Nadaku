import '../core/json_utils.dart';

/// Artis atau grup musik dari Deezer API.
class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.pictureMedium = '',
    this.pictureBig = '',
    this.pictureXl = '',
    this.fans,
    this.albumCount,
    this.link = '',
  });

  final int id;
  final String name;
  final String pictureMedium;
  final String pictureBig;
  final String pictureXl;

  /// Jumlah penggemar. Hanya tersedia pada endpoint detail artis.
  final int? fans;

  /// Jumlah album. Hanya tersedia pada endpoint detail artis.
  final int? albumCount;
  final String link;

  /// Foto beresolusi tertinggi yang tersedia (kosong jika tidak ada foto).
  String get bestPicture {
    if (pictureXl.isNotEmpty) return pictureXl;
    if (pictureBig.isNotEmpty) return pictureBig;
    return pictureMedium;
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: asInt(json['id']),
      name: asString(json['name'], fallback: 'Artis tidak dikenal'),
      pictureMedium: asString(json['picture_medium']),
      pictureBig: asString(json['picture_big']),
      pictureXl: asString(json['picture_xl']),
      fans: asIntOrNull(json['nb_fan']),
      albumCount: asIntOrNull(json['nb_album']),
      link: asString(json['link']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'picture_medium': pictureMedium,
      'picture_big': pictureBig,
      'picture_xl': pictureXl,
      if (fans != null) 'nb_fan': fans,
      if (albumCount != null) 'nb_album': albumCount,
      'link': link,
    };
  }
}
