import 'package:flutter/material.dart';

import '../widgets/mini_player.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

/// Kerangka utama aplikasi: tiga tab, pemutar mini, dan navigasi bawah.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // IndexedStack menjaga state setiap tab, sehingga hasil chart dan pencarian
  // tidak hilang saat pengguna berpindah tab.
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Cari',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Favorit',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
