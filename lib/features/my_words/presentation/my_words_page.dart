import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_surfaces.dart';

class MyWordsPage extends StatefulWidget {
  const MyWordsPage({super.key});

  @override
  State<MyWordsPage> createState() => _MyWordsPageState();
}

class _MyWordsPageState extends State<MyWordsPage> {
  static const List<String> _tabs = ['Favorit', 'Riwayat', 'Belum', 'Dikuasai'];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
        children: [
          const PageHeader(eyebrow: 'Koleksi pribadi', title: 'Kata Saya'),
          const SizedBox(height: 14),
          _SegmentedTabs(
            tabs: _tabs,
            index: _index,
            onChanged: (value) => setState(() => _index = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Urutkan: A–Z',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 13, color: p.chevron),
                  const SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: EmptyState(
              icon: switch (_index) {
                0 => Icons.bookmark_border_rounded,
                1 => Icons.history_rounded,
                2 => Icons.auto_stories_outlined,
                _ => Icons.verified_outlined,
              },
              title: 'Belum ada kata di ${_tabs[_index].toLowerCase()}',
              message: 'Kata yang kamu simpan, pelajari, atau kuasai akan terkumpul di sini.',
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const IconTile(icon: Icons.folder_outlined),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi saya',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('Belum ada koleksi', style: context.tiny),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 15, color: p.chevron),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tabs, required this.index, required this.onChanged});

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.fieldBg,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == index ? p.tabOnBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: i == index ? p.tabOnLine : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11.5,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: i == index ? p.textPrimary : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
