import 'package:safe_text/safe_text.dart';

class ChildSafetyFilter {
  static const blockedMessage = 'Let’s use child-friendly words.';

  static const _hiligaynonWords = ['buang', 'linti', 'oten', 'pisti', 'yawa'];
  static const _allowedWords = ['i'];

  static Future<void>? _initialization;
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    if (_ready) return;
    final pending = _initialization ??= SafeTextFilter.init(
      languages: const [Language.english, Language.filipino, Language.cebuano],
    );
    try {
      await pending;
      _ready = true;
    } catch (_) {
      if (identical(_initialization, pending)) _initialization = null;
      rethrow;
    }
  }

  static bool isUnsafe(String text) {
    final trimmedTokens = text.splitMapJoin(
      RegExp(r'\S+'),
      onMatch: (match) => match
          .group(0)!
          .replaceAll(
            RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
            '',
          ),
    );
    return _filter(text) != text ||
        _filter(trimmedTokens) != trimmedTokens ||
        _containsHiligaynonWord(trimmedTokens);
  }

  static String _filter(String text) {
    return SafeTextFilter.filterText(
      text: text,
      extraWords: _hiligaynonWords,
      excludedWords: _allowedWords,
    );
  }

  static bool _containsHiligaynonWord(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('7', 't');
    return RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .any(_hiligaynonWords.contains);
  }
}
