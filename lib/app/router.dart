import 'package:go_router/go_router.dart';

import '../features/explore/presentation/explore_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/my_words/presentation/my_words_page.dart';
import '../features/practice/presentation/practice_page.dart';
import '../features/profile/presentation/profile_page.dart';
import 'shell/app_shell.dart';

/// Rute aplikasi. Bottom navigation memakai satu branch per tab, sehingga
/// posisi scroll & state tiap tab terjaga saat berpindah.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', name: 'home', builder: (_, _) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/explore', name: 'explore', builder: (_, _) => const ExplorePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/practice', name: 'practice', builder: (_, _) => const PracticePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/my-words', name: 'myWords', builder: (_, _) => const MyWordsPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', name: 'profile', builder: (_, _) => const ProfilePage()),
          ],
        ),
      ],
    ),
  ],
);
