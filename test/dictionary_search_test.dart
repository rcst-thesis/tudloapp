import 'package:flutter_test/flutter_test.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_search.dart';

const _pool = [
  DictionaryEntry(
    id: 'balay',
    word: 'balay',
    phonetic: '/ba-lay/',
    definition: 'n. house.',
    example: 'test',
    category: 'home',
  ),
  DictionaryEntry(
    id: 'adobo',
    word: 'adóbo',
    phonetic: '/a-do-bo/',
    definition: 'n. meat cooked in vinegar.',
    example: 'test',
    category: 'food',
  ),
  DictionaryEntry(
    id: 'kan-on',
    word: 'kan-on',
    phonetic: '/kan-on/',
    definition: 'n. rice.',
    example: 'test',
    category: 'food',
  ),
];

const _autocompletePool = [
  DictionaryEntry(
    id: 'balay',
    word: 'balay',
    phonetic: '/ba-lay/',
    definition: 'n. house.',
    example: 'test',
    category: 'home',
  ),
  DictionaryEntry(
    id: 'balita',
    word: 'balita',
    phonetic: '/ba-li-ta/',
    definition: 'n. news.',
    example: 'test',
    category: 'general',
  ),
  DictionaryEntry(
    id: 'bag-o',
    word: 'bag-o',
    phonetic: '/bag-o/',
    definition: 'adj. new.',
    example: 'test',
    category: 'descriptions',
  ),
  DictionaryEntry(
    id: 'adobo',
    word: 'adóbo',
    phonetic: '/a-do-bo/',
    definition: 'n. meat cooked in vinegar.',
    example: 'test',
    category: 'food',
  ),
  DictionaryEntry(
    id: 'atis',
    word: 'atis',
    phonetic: '/a-tis/',
    definition: 'n. custard-apple.',
    example: 'test',
    category: 'food',
  ),
  DictionaryEntry(
    id: 'atubangan',
    word: 'atubangan',
    phonetic: '/a-tu-ban-gan/',
    definition: 'n. in front of.',
    example: 'test',
    category: 'general',
  ),
];

void main() {
  group('normalizeForSearch', () {
    test('strips accents', () {
      expect(normalizeForSearch('adóbo'), 'adobo');
      // 'i' folds to 'e' (see phonetic folding below), so "gáb-i" ->
      // "gabe", not "gabi".
      expect(normalizeForSearch('gáb-i'), 'gabe');
    });

    test('drops hyphens, apostrophes, spaces, and curly quotes', () {
      // 'k' folds to 'c' (phonetic folding), so "kan-on" -> "canon".
      expect(normalizeForSearch('kan-on'), 'canon');
      // 'i' folds to 'e'.
      expect(normalizeForSearch('ara dira'), 'aradera');
      expect(normalizeForSearch('“diin”'), 'deen');
    });

    test('lowercases', () {
      // 'i' folds to 'e'.
      expect(normalizeForSearch('Abril'), 'abrel');
    });

    test('folds phonetically-interchangeable letters together', () {
      expect(normalizeForSearch('kuring'), normalizeForSearch('koring'));
      expect(normalizeForSearch('lalaki'), normalizeForSearch('lalake'));
      expect(normalizeForSearch('baka'), normalizeForSearch('vaka'));
      expect(normalizeForSearch('kolor'), normalizeForSearch('color'));
    });
  });

  group('matchesSearch', () {
    test('empty query always matches', () {
      expect(matchesSearch('anything', ''), isTrue);
    });

    test('matches accented words against a plain-ASCII query', () {
      expect(matchesSearch('adóbo', 'adobo'), isTrue);
      expect(matchesSearch('adóbo', 'ado'), isTrue);
    });

    test('matches hyphenated words against a query with no hyphen', () {
      expect(matchesSearch('kan-on', 'kanon'), isTrue);
      expect(matchesSearch('bís-ak', 'bisak'), isTrue);
    });

    test('matches multi-word entries against a query with no space', () {
      expect(matchesSearch('ara dira', 'aradira'), isTrue);
    });

    test('is case-insensitive', () {
      expect(matchesSearch('Abril', 'abril'), isTrue);
      expect(matchesSearch('abril', 'ABRIL'), isTrue);
    });

    test('still rejects a genuinely non-matching query', () {
      expect(matchesSearch('adóbo', 'xyz'), isFalse);
    });

    test('matches across phonetically-interchangeable letters', () {
      expect(matchesSearch('kuring', 'koring'), isTrue);
      expect(matchesSearch('baka', 'vaka'), isTrue);
      expect(matchesSearch('kolor', 'color'), isTrue);
    });
  });

  group('closestWordMatches', () {
    test('suggests the right word for a single typo\'d letter', () {
      final matches = closestWordMatches('balay', _pool);
      // Exact match has distance 0 and is excluded -- this isn't the "did
      // you mean" path when the query already matches exactly.
      expect(matches, isEmpty);

      final typoMatches = closestWordMatches('balat', _pool);
      expect(typoMatches.map((e) => e.id), contains('balay'));
    });

    test('typo tolerance scales with query length', () {
      // "adobo" (5 letters) vs "adóbo" normalized to "adobo" is an exact
      // match (distance 0), so try a couple of real typos instead.
      expect(
        closestWordMatches('adoba', _pool).map((e) => e.id),
        contains('adobo'),
      );
      expect(
        closestWordMatches('adova', _pool).map((e) => e.id),
        contains('adobo'),
      );
    });

    test('accents/hyphens do not count as typos', () {
      // "kanon" (no hyphen) should match "kan-on" via normalization, not
      // edit distance -- but closestWordMatches only fires on an actual
      // typo gap, so a query that already normalizes-matches returns no
      // suggestions (matchesSearch already found it).
      expect(closestWordMatches('kanon', _pool), isEmpty);
    });

    test('returns nothing for a wildly different query', () {
      expect(closestWordMatches('zzzzzzzzzz', _pool), isEmpty);
    });

    test('empty query returns nothing', () {
      expect(closestWordMatches('', _pool), isEmpty);
    });
  });

  group('autocompleteSuggestion', () {
    test('empty typed text returns nothing', () {
      expect(autocompleteSuggestion('', _autocompletePool), isNull);
    });

    test('returns the remaining suffix of the shortest matching word', () {
      // "balay" (5) and "balita" (6) both start with "bal" -- the shorter,
      // less-presumptuous completion wins.
      expect(autocompleteSuggestion('bal', _autocompletePool), 'ay');
      // "atis" (4) and "atubangan" (9) both start with "at".
      expect(autocompleteSuggestion('at', _autocompletePool), 'is');
    });

    test('breaks ties between equal-length words alphabetically', () {
      const pool = [
        DictionaryEntry(
          id: 'baya',
          word: 'baya',
          phonetic: '/ba-ya/',
          definition: 'n. test.',
          example: 'test',
          category: 'test',
        ),
        DictionaryEntry(
          id: 'bayo',
          word: 'bayo',
          phonetic: '/ba-yo/',
          definition: 'n. test.',
          example: 'test',
          category: 'test',
        ),
      ];
      // Both are 4 letters starting with "ba" -- "baya" sorts first.
      expect(autocompleteSuggestion('ba', pool), 'ya');
    });

    test('is accent-insensitive but returns the real suffix with accents', () {
      // Typed plain "ado" should still suggest the rest of "adóbo",
      // accent included, since only matching is accent-insensitive.
      expect(autocompleteSuggestion('ado', _autocompletePool), 'bo');
    });

    test('keeps the typed text\'s separators/casing out of the comparison', () {
      // "bag-o" (5 chars incl. hyphen) vs typed "bag" (3) -- a genuine
      // prefix match once accents are stripped (no hyphen-dropping here,
      // unlike normalizeForSearch, so this only works because "bag" really
      // is a literal prefix of "bag-o").
      expect(autocompleteSuggestion('bag', _autocompletePool), '-o');
    });

    test('returns null when nothing is a plausible completion', () {
      expect(autocompleteSuggestion('zzz', _autocompletePool), isNull);
    });

    test('returns null once the typed text already equals a whole word', () {
      expect(autocompleteSuggestion('balay', _autocompletePool), isNull);
    });
  });

  group('indexLetterFor', () {
    test('accented vowels merge into their plain letter\'s bucket', () {
      expect(indexLetterFor('ádlaw'), 'A');
      expect(indexLetterFor('íwat'), 'I');
      expect(indexLetterFor('óras'), 'O');
      expect(indexLetterFor('úbra'), 'U');
    });

    test('plain words return their own uppercase first letter', () {
      expect(indexLetterFor('balay'), 'B');
      expect(indexLetterFor('Abril'), 'A');
    });

    test(
      'leading punctuation is skipped in favor of the first real letter',
      () {
        expect(indexLetterFor("'iwat"), 'I');
      },
    );

    test('a word with no letters at all falls back to #', () {
      expect(indexLetterFor("'-"), '#');
      expect(indexLetterFor(''), '#');
    });
  });
}
