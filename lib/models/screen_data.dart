import 'album.dart';
import 'artist.dart';
import 'track.dart';

/// Data gabungan untuk halaman Beranda (hasil tiga permintaan API paralel).
class HomeData {
  const HomeData({
    required this.tracks,
    required this.artists,
    required this.albums,
  });

  final List<Track> tracks;
  final List<Artist> artists;
  final List<Album> albums;

  bool get isEmpty => tracks.isEmpty && artists.isEmpty && albums.isEmpty;
}

/// Data gabungan untuk halaman detail artis.
class ArtistDetail {
  const ArtistDetail({
    required this.artist,
    required this.topTracks,
    required this.albums,
  });

  final Artist artist;
  final List<Track> topTracks;
  final List<Album> albums;
}

/// Data gabungan untuk halaman detail album beserta daftar lagunya.
class AlbumDetail {
  const AlbumDetail({required this.album, required this.tracks});

  final Album album;
  final List<Track> tracks;
}
