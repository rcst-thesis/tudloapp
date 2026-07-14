import 'package:tudloapp/core/data/content_repository.dart';
import 'package:tudloapp/core/models/language_dictionary.dart' as formatted;
import 'package:tudloapp/data/dictionary/dictionary_item.dart';

export 'package:tudloapp/data/dictionary/dictionary_item.dart';

/// JSON-backed lookup data for Dictionary, Translation, and word tooltips.
///
/// The data is bundled from `assets/data/ilonggo-dictionary-formatted.json`.
/// [initialize] loads it once, on first use.
class DictionaryData {
  static final _repository = ContentRepository();
  static const _jsonDatasetAsset =
      'assets/data/ilonggo-dictionary-formatted.json';

  static List<DictionaryEntry> entries = const [];
  static Map<String, String> hiligaynonToEnglish = const {};
  static Map<String, String> englishToHiligaynon = const {};
  static Future<void>? _initialization;

  /// Small phrase support for the Translation page. Full lesson sentences
  /// should remain in LessonBank instead of becoming dictionary entries.
  static const phraseTranslations = {
    'maayong aga': 'good morning',
    'maayong hapon': 'good afternoon',
    'maayong gab-i': 'good evening',
    'good morning': 'maayong aga',
    'good afternoon': 'maayong hapon',
    'good evening': 'maayong gab-i',
    'thank you': 'salamat',
    'pwede mo ako buligan': 'can you help me',
    'can you help me': 'pwede mo ako buligan',
  };

  static Future<void> initialize() => _initialization ??= _load();

  static Future<void> _load() async {
    final dictionary = formatted.LanguageDictionary.fromJson(
      await _repository.loadMap(_jsonDatasetAsset),
    );
    final parsedEntries = <DictionaryEntry>[
      for (var index = 0; index < dictionary.length; index++)
        _entryFromFormatted(
          dictionary.getEntryAt(index),
          dictionary.abbreviations,
        ),
    ].where((entry) => entry.hiligaynon.trim().isNotEmpty).toList();

    entries = _deduplicate(parsedEntries)
      ..sort(
        (a, b) => normalizeForSearch(
          a.hiligaynon,
        ).compareTo(normalizeForSearch(b.hiligaynon)),
      );
    hiligaynonToEnglish = {
      for (final entry in entries) _normalize(entry.hiligaynon): entry.english,
    };
    englishToHiligaynon = {
      for (final entry in entries)
        for (final meaning in _englishMeanings(entry.english))
          _normalize(meaning): entry.hiligaynon,
    };
  }

  static String meaningFor(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return '';
    return hiligaynonToEnglish[normalized] ??
        englishToHiligaynon[normalized] ??
        phraseTranslations[normalized] ??
        '';
  }

  static String normalizeForSearch(String value) => _normalize(value);

  static DictionaryEntry _entryFromFormatted(
    formatted.DictionaryEntry entry,
    Map<String, String> abbreviations,
  ) {
    final definitions = [
      for (final meaning in entry.meanings) ...meaning.definition,
    ].where((value) => value.trim().isNotEmpty).join('; ');
    return DictionaryEntry(
      hiligaynon: entry.word,
      english: definitions,
      partOfSpeech:
          abbreviations[entry.partOfSpeech] ?? entry.partOfSpeech ?? '',
    );
  }

  static List<DictionaryEntry> _deduplicate(List<DictionaryEntry> values) {
    final seen = <String>{};
    final deduped = <DictionaryEntry>[];
    for (final entry in values) {
      final key =
          '${_normalize(entry.hiligaynon)}|${_normalize(entry.english)}';
      if (!seen.add(key)) continue;
      deduped.add(entry);
    }
    return deduped;
  }

  static String _normalize(String value) {
    var normalized = value.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ñ': 'n',
      '’': '',
      "'": '',
    };
    for (final item in replacements.entries) {
      normalized = normalized.replaceAll(item.key, item.value);
    }
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9\-\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _englishMeanings(String value) {
    return value
        .split(RegExp(r'\s*(?:/|,|;|\bor\b)\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part.length <= 48)
        .toList();
  }
}
