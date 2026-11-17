import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_nav_bar.dart';

/// Kerangka aplikasi: area halaman + bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<NavItem> _items = [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
    NavItem(icon: Icons.layers_outlined, activeIcon: Icons.layers_rounded, label: 'Practice'),
    NavItem(icon: Icons.bookmark_border, activeIcon: Icons.bookmark, label: 'My Words'),
    NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
