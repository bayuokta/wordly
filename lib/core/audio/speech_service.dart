import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Pembungkus pengenalan suara perangkat untuk latihan pelafalan.
///
/// Memakai layanan bawaan Android/iOS (offline bila perangkat mendukung).
class SpeechService {
  SpeechService();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _unavailable = false;

  bool get isListening => _speech.isListening;
  bool get isUnavailable => _unavailable;

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (_unavailable) return false;
    try {
      _initialized = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      return _initialized;
    } on Object {
      _unavailable = true;
      return false;
    }
  }

  /// Mulai mendengarkan; [onWords] dipanggil untuk hasil sementara/final.
  Future<bool> listen({
    required void Function(String words, bool isFinal) onWords,
  }) async {
    if (!await initialize()) return false;
    try {
      await _speech.listen(
        onResult: (result) => onWords(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } on Object {
      _unavailable = true;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Object {
      // diabaikan
    }
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(service.stop);
  return service;
});
