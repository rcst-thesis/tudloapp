import 'package:flutter_tts/flutter_tts.dart';
import 'package:tudloapp/core/services/tudlo_tts_platform_interface.dart';

TudloTtsPlatform createTudloTtsPlatform() => _NativeTudloTtsPlatform();

class _NativeTudloTtsPlatform implements TudloTtsPlatform {
  final FlutterTts _tts = FlutterTts();
  Map<String, String>? _preferredFilipinoVoice;
  bool _lookedForFilipinoVoice = false;

  @override
  Future<void> speak(
    String text, {
    required bool hiligaynon,
    required bool waitForCompletion,
  }) async {
    await _tts.stop();
    await _tts.awaitSpeakCompletion(waitForCompletion);
    await _setSpeechLanguage(hiligaynon: hiligaynon);
    await _tts.setSpeechRate(.29);
    await _tts.setPitch(1.04);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();

  Future<void> _setSpeechLanguage({required bool hiligaynon}) async {
    if (!hiligaynon) {
      await _tts.setLanguage('en-US');
      return;
    }

    const preferredLocales = ['tl-PH', 'fil-PH'];
    for (final locale in preferredLocales) {
      try {
        await _tts.setLanguage(locale);
        break;
      } catch (_) {
        // Try the next Filipino/Tagalog locale supported by the platform.
      }
    }

    final voice = await _preferredVoiceForLocales(preferredLocales);
    if (voice != null) {
      try {
        await _tts.setVoice(voice);
      } catch (_) {
        // Some platforms accept the language but do not support setVoice.
      }
    }
  }

  Future<Map<String, String>?> _preferredVoiceForLocales(
    List<String> locales,
  ) async {
    if (_lookedForFilipinoVoice) return _preferredFilipinoVoice;
    _lookedForFilipinoVoice = true;

    try {
      final voices = await _tts.getVoices;
      if (voices is! Iterable) return null;

      final normalizedLocales = locales.map((locale) => locale.toLowerCase());
      final candidates = <Map<String, String>>[];
      for (final voice in voices) {
        if (voice is! Map) continue;
        final name = voice['name']?.toString();
        final locale = voice['locale']?.toString();
        if (name == null || locale == null) continue;
        if (!normalizedLocales.contains(locale.toLowerCase())) continue;
        candidates.add({'name': name, 'locale': locale});
      }

      if (candidates.isEmpty) return null;
      candidates.sort((a, b) => _voiceRank(a).compareTo(_voiceRank(b)));
      _preferredFilipinoVoice = candidates.first;
      return _preferredFilipinoVoice;
    } catch (_) {
      return null;
    }
  }

  static int _voiceRank(Map<String, String> voice) {
    final name = voice['name']!.toLowerCase();
    final locale = voice['locale']!.toLowerCase();
    var rank = 0;
    if (locale == 'tl-ph') rank -= 20;
    if (name.contains('female') ||
        name.contains('woman') ||
        name.contains('zira')) {
      rank -= 8;
    }
    if (name.contains('male') ||
        name.contains('man') ||
        name.contains('david')) {
      rank += 8;
    }
    return rank;
  }
}
