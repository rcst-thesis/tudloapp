import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';

/// Diacritic-stripping map for the accented characters that actually show
/// up in the Hiligaynon dictionary content (à á â é ì í î ò ó ô ú û, plus a
/// few others defensively included for future content). Lets a learner
/// search "adobo" and still find "adóbo", "gabi" and still find "gáb-i",
/// etc. -- without this, `String.contains` fails on anything with an
/// accent since 'o' != 'ó'.
const _diacriticMap = <String, String>{
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Letters that are basically interchangeable in casual Hiligaynon/Filipino
/// spelling -- folded to one canonical letter so a search doesn't fail over
/// a spelling variant that isn't really a different word: o/u ("kuring" /
/// "koring"), e/i ("lalaki" / "lalake"), b/v ("baka" / "vaka"), and the
/// c/k/s cluster from Spanish loanwords ("kolor" / "color" / "kulay"-ish
/// spellings). Each key folds to its value; only affects matching, never
/// what's actually displayed.
const _phoneticFoldMap = <String, String>{
  'u': 'o',
  'i': 'e',
  'v': 'b',
  'k': 'c',
  's': 'c',
};

/// Normalizes [input] for loose search matching: lowercased, accents
/// stripped, separators (hyphens, apostrophes, spaces, curly quotes)
/// dropped entirely, and phonetically-interchangeable letters folded
/// together (see [_phoneticFoldMap]) -- so "kan-on" matches a search for
/// "kanon", "bís-ak" matches "bisak", "ara dira" matches "aradira", and
/// "kuring" matches a search for "koring". Only affects matching, never
/// what's actually displayed.
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    switch (char) {
      case '-':
      case "'":
      case ' ':
      case '"':
      case '‘': // '
      case '’': // '
      case '“': // "
      case '”': // "
        continue;
      default:
        final base = _diacriticMap[char] ?? char;
        buffer.write(_phoneticFoldMap[base] ?? base);
    }
  }
  return buffer.toString();
}

/// Whether [haystack] contains [query] under [normalizeForSearch]. An empty
/// [query] always matches (treated as "no filter").
bool matchesSearch(String haystack, String query) {
  if (query.isEmpty) return true;
  return normalizeForSearch(haystack).contains(normalizeForSearch(query));
}

/// Lowercases and strips accents only -- unlike [normalizeForSearch], does
/// *not* drop separators or fold phonetically-similar letters together.
/// Two uses need exactly this, neither the fuzzier one:
/// [autocompleteSuggestion] needs a strict, position-aligned prefix match
/// against the literal characters still in the search field (so the
/// remaining suffix it returns lines up character-for-character with what's
/// already typed); [indexLetterFor] and the A-Z letter index's sort need
/// "how a human alphabetizes this," which cares about accents (á sorts
/// with a, not off in its own bucket after z) but not about separators or
/// phonetic near-misses (kan-on should still sort near kanon-shaped words,
/// not have its hyphen silently deleted from the comparison).
String stripAccentsLower(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacriticMap[char] ?? char);
  }
  return buffer.toString();
}

/// The A-Z index "letter" [word] should be filed under: its first actual
/// letter, accents stripped and uppercased (so "ádlaw" files under "A",
/// not a separate "Á" bucket off at the end of the alphabet) -- skipping
/// any leading punctuation, so "'iwat" files under "I", not its own
/// punctuation-mark bucket. Falls back to `'#'` if [word] has no letters at
/// all.
String indexLetterFor(String word) {
  for (final rune in word.runes) {
    final char = String.fromCharCode(rune).toLowerCase();
    final normalized = _diacriticMap[char] ?? char;
    final code = normalized.codeUnitAt(0);
    if (normalized.length == 1 && code >= 97 && code <= 122) {
      return normalized.toUpperCase();
    }
  }
  return '#';
}

/// The inline "ghost text" completion for [typed] -- the remaining
/// characters (in the matched word's real spelling/casing) of whichever
/// pool word looks like the most plausible completion, or `null` if
/// [typed] is empty or nothing in [pool] is a plausible completion.
///
/// Matching is a case-insensitive, accent-stripped *prefix* match (see
/// [stripAccentsLower]) -- deliberately stricter than [matchesSearch]'s
/// fuzzy substring matching, since this is meant to visually continue what
/// the learner already typed, not surface a loosely-related word. Among
/// every word that's a plausible completion, the shortest one wins (the
/// least presumptuous guess), ties broken alphabetically for a
/// deterministic pick.
String? autocompleteSuggestion(String typed, List<DictionaryEntry> pool) {
  if (typed.isEmpty) return null;
  final normalizedTyped = stripAccentsLower(typed);

  DictionaryEntry? best;
  for (final entry in pool) {
    final word = entry.word;
    if (word.length <= typed.length) continue;
    final normalizedWord = stripAccentsLower(word);
    if (!normalizedWord.startsWith(normalizedTyped)) continue;

    if (best == null ||
        word.length < best.word.length ||
        (word.length == best.word.length && word.compareTo(best.word) < 0)) {
      best = entry;
    }
  }

  return best?.word.substring(typed.length);
}

/// Levenshtein (edit) distance between [a] and [b]: the minimum number of
/// single-character insertions, deletions, or substitutions to turn one
/// into the other. Classic dynamic-programming implementation, O(a.length *
/// b.length).
int _editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previousRow = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final currentRow = List<int>.filled(b.length + 1, 0);
    currentRow[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final deletionCost = previousRow[j + 1] + 1;
      final insertionCost = currentRow[j] + 1;
      final substitutionCost = previousRow[j] + (a[i] == b[j] ? 0 : 1);
      currentRow[j + 1] = [
        deletionCost,
        insertionCost,
        substitutionCost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previousRow = currentRow;
  }
  return previousRow[b.length];
}

/// How many typo'd characters to still tolerate for a query of
/// [queryLength], as a "did you mean" suggestion -- generous enough to
/// catch a couple of fat-fingered letters on a real word, tight enough that
/// a 3-letter query doesn't match half the dictionary.
int _suggestionThreshold(int queryLength) {
  if (queryLength <= 3) return 1;
  if (queryLength <= 6) return 2;
  return 3;
}

/// Finds up to [maxResults] entries in [pool] whose word is close to
/// [query] under edit distance (after [normalizeForSearch], so accents/
/// hyphens/spacing don't count as typos) -- for "did you mean" suggestions
/// when a search comes up empty. Returns entries closest-first; ties keep
/// [pool]'s order. Returns nothing for an empty query or an exact/
/// substring match (that's [matchesSearch]'s job, not this one).
List<DictionaryEntry> closestWordMatches(
  String query,
  List<DictionaryEntry> pool, {
  int maxResults = 3,
}) {
  final normalizedQuery = normalizeForSearch(query);
  if (normalizedQuery.isEmpty) return const [];
  final threshold = _suggestionThreshold(normalizedQuery.length);

  final scored = <MapEntry<DictionaryEntry, int>>[];
  for (final entry in pool) {
    final distance = _editDistance(
      normalizedQuery,
      normalizeForSearch(entry.word),
    );
    if (distance > 0 && distance <= threshold) {
      scored.add(MapEntry(entry, distance));
    }
  }
  scored.sort((a, b) => a.value.compareTo(b.value));

  final seenWords = <String>{};
  final results = <DictionaryEntry>[];
  for (final match in scored) {
    if (results.length >= maxResults) break;
    if (seenWords.add(match.key.word)) results.add(match.key);
  }
  return results;
}
