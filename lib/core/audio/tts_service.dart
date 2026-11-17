import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/settings_controller.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Pembaca teks perangkat (TTS). Dipakai mode listening & spelling.
///
/// Selalu tersedia offline di sebagian besar perangkat Android (locale en-US).
class TtsService {
  TtsService() {
    _init = _configure();
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _init;
  bool _unavailable = false;
  static const double _baseRate = 0.45;

  bool get isUnavailable => _unavailable;

  Future<void> _configure() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_baseRate);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } on Object {
      _unavailable = true;
    }
  }

  /// Mengucapkan [text]; mengembalikan `false` bila TTS tidak tersedia.
  Future<bool> speak(String text, {double rate = 0.45}) async {
    try {
      await _init;
      if (_unavailable) return false;
      await _tts.stop();
      await _tts.setSpeechRate(rate.clamp(0.2, 1.0));
      await _tts.speak(text);
      return true;
    } on Object {
      _unavailable = true;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // diabaikan: TTS opsional
    }
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.stop);
  return service;
});

/// Mengucapkan [text] dari widget mana pun.
///
/// Memakai ProviderScope.containerOf supaya tidak perlu mengubah widget
/// menjadi ConsumerWidget hanya untuk satu tombol audio.
Future<void> speakText(BuildContext context, String text, {double rateScale = 1}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final speed = container.read(settingsProvider).audioSpeed;
  final ok = await container
      .read(ttsServiceProvider)
      .speak(text, rate: 0.45 * speed * rateScale);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Audio tidak tersedia di perangkat ini.')));
  }
}

/// Mengucapkan satu kata (mengikuti setelan kecepatan pengguna).
Future<void> speakWord(BuildContext context, String text) => speakText(context, text);

/// Mengucapkan kalimat contoh dengan tempo sedikit lebih pelan.
Future<void> speakSentence(BuildContext context, String text) =>
    speakText(context, text, rateScale: 0.9);