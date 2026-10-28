import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_scope.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/main_shell.dart';
import 'services/audio_engine.dart';
import 'services/deezer_service.dart';
import 'services/favorites_controller.dart';
import 'services/player_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final api = DeezerService();
  final player = PlayerController(
    engine: JustAudioEngine(),
    refreshTrack: api.fetchTrack,
  );
  final favorites = FavoritesController(prefs);

  runApp(NadakuApp(api: api, player: player, favorites: favorites));
}

/// Widget akar aplikasi. Layanan diberikan dari luar (dependency injection)
/// sehingga mudah diganti dengan versi palsu saat pengujian.
class NadakuApp extends StatelessWidget {
  const NadakuApp({
    super.key,
    required this.api,
    required this.player,
    required this.favorites,
  });

  final DeezerService api;
  final PlayerController player;
  final FavoritesController favorites;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: api,
      player: player,
      favorites: favorites,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const MainShell(),
      ),
    );
  }
}
