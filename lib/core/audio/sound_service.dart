import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Efek suara pendek (bukan TTS) untuk umpan balik latihan.
class SoundService {
  SoundService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();
  bool _unavailable = false;

  static const String correct = 'sounds/correct.wav';
  static const String wrong = 'sounds/wrong.wav';
  static const String streak = 'sounds/streak.wav';

  Future<void> play(String asset) async {
    if (_unavailable) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset), volume: 0.7);
    } on Object {
      // Perangkat tanpa audio output: abaikan, jangan ganggu alur belajar.
      _unavailable = true;
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } on Object {
      // diabaikan
    }
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});
