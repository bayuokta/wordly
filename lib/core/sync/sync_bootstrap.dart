import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/session_controller.dart';
import 'sync_providers.dart';

/// Memicu sinkronisasi latar belakang setelah sesi siap.
///
/// Bukan bagian dari alur belajar: widget ini tidak menampilkan apa pun dan
/// tidak menunggu jaringan sebelum halaman apa pun dirender.
class SyncBootstrap extends ConsumerStatefulWidget {
  const SyncBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<SyncBootstrap> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  void _maybeStart() {
    if (_started) return;
    final session = ref.read(sessionProvider);
    // Tamu/belum login tidak butuh provider database tambahan.
    if (session.isInitializing || session.isGuest || !session.signedIn) return;
    _started = true;
    unawaited(ref.read(syncCoordinatorProvider).start(session));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (_, _) => _maybeStart());
    return widget.child;
  }
}
