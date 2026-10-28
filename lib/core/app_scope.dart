import 'package:flutter/widgets.dart';

import '../services/deezer_service.dart';
import '../services/favorites_controller.dart';
import '../services/player_controller.dart';

/// Menyediakan layanan utama (API, pemutar, favorit) ke seluruh widget tree.
///
/// Memakai InheritedWidget bawaan Flutter sehingga tidak butuh package state
/// management tambahan. Nilainya tidak pernah berganti selama aplikasi hidup,
/// jadi [of] memakai getInheritedWidgetOfExactType (aman dipanggil di initState).
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.api,
    required this.player,
    required this.favorites,
    required super.child,
  });

  final DeezerService api;
  final PlayerController player;
  final FavoritesController favorites;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di atas widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
