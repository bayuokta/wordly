import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  bool get isUnavailable => _unavailable;

  Future<void> _configure() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } on Object {
      _unavailable = true;
    }
  }

  /// Mengucapkan [text]; mengembalikan `false` bila TTS tidak tersedia.
  Future<bool> speak(String text) async {
    try {
      await _init;
      if (_unavailable) return false;
      await _tts.stop();
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
