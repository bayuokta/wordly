import 'package:material_ui/material_ui.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/app_typography.dart';

class NavItem {
  const NavItem({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom navigation sesuai mockup: ikon + label + titik penanda aktif.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.navBg,
        border: Border(top: BorderSide(color: p.navBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      active: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.primary : p.navInactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
