import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

/// Menyimpan daftar lagu favorit secara lokal di perangkat.
///
/// Data disimpan sebagai daftar string JSON memakai SharedPreferences
/// sehingga tetap ada setelah aplikasi ditutup.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._prefs) {
    _restore();
  }

  static const String _storageKey = 'nadaku.favorite_tracks.v1';

  final SharedPreferences _prefs;
  final List<Track> _items = <Track>[];

  List<Track> get items => List<Track>.unmodifiable(_items);
  int get count => _items.length;

  bool isFavorite(Track track) => _items.any((item) => item.id == track.id);

  void _restore() {
    final raw = _prefs.getStringList(_storageKey) ?? const <String>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map) {
          _items.add(Track.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {
        // Data yang rusak dilewati agar aplikasi tetap bisa dibuka.
      }
    }
  }

  /// Menambah lagu ke favorit, atau menghapusnya jika sudah ada.
  Future<void> toggle(Track track) async {
    final index = _items.indexWhere((item) => item.id == track.id);
    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.insert(0, track);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = _items.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_storageKey, encoded);
  }
}
