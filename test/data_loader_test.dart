import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/content_repository.dart';
import 'package:tudloapp/core/models/language_dictionary.dart';

/// A fake [AssetBundle] that serves in-memory JSON for unit tests.
/// No actual asset loading, no isolate overhead.
class _TestAssetBundle extends AssetBundle {
  final Map<String, dynamic> _data;

  _TestAssetBundle(this._data);

  @override
  Future<ByteData> load(String key) async {
    final value = _data[key];
    if (value == null) throw FlutterError('Asset not found: $key');
    final bytes = utf8.encode(jsonEncode(value));
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async {
    final value = _data[key];
    if (value == null) throw FlutterError('Asset not found: $key');
    return parser(jsonEncode(value));
  }
}

void main() {
  group('ContentRepository + LanguageDictionary TDD Suite', () {
    late _TestAssetBundle bundle;
    late ContentRepository repo;

    final Map<String, dynamic> mockDictionaryJson = {
      "metadata": {
        "dictionary_entry_count": 893,
        "verb_appendix_count": 102,
        "notes": "Converted from the uploaded Excel dictionary file.",
      },
      "abbreviations": {
        "N": "Noun",
        "V": "Verb",
        "ADV": "Adverb",
        "ADJ": "Adjective",
        "P": "Pronoun",
        "IMP": "Imperative",
        "INF": "Infinitive",
        "AF": "Actor Focus",
      },
      "entries": [
        {
          "word": "abogado",
          "part_of_speech": "N",
          "meanings": [
            {
              "definition": ["lawyer"],
            },
          ],
        },
        {
          "word": "adlaw",
          "part_of_speech": "N",
          "meanings": [
            {
              "definition": ["sun", "day"],
            },
          ],
        },
        {
          "word": "adlaw-adlaw",
          "part_of_speech": "ADV",
          "meanings": [
            {
              "definition": ["everyday"],
            },
          ],
        },
        {
          "word": "balikan",
          "part_of_speech": "V",
          "meanings": [
            {
              "definition": ["to go back"],
              "forms": ["INF"],
            },
            {
              "definition": ["go back"],
              "forms": ["IMP"],
            },
          ],
        },
        {
          "word": "pilipino",
          "part_of_speech": "N",
          "meanings": [
            {
              "definition": ["Filipino"],
              "notes": ["persons"],
            },
          ],
        },
        {
          "word": "kaonon",
          "part_of_speech": "V",
          "meanings": [
            {
              "definition": ["(to) eat"],
              "forms": ["INF", "IMP"],
            },
          ],
        },
        {
          "word": "lakat diri",
          "part_of_speech": "P",
          "meanings": [
            {
              "definition": ["(you, singular/plural)", "walk here"],
            },
          ],
        },
      ],
    };

    setUp(() {
      bundle = _TestAssetBundle({
        'assets/data/ilonggo-dictionary-formatted.json': mockDictionaryJson,
        'assets/data/list.json': [1, 2, 3],
      });
      repo = ContentRepository(bundle: bundle);
    });

    // ─── ContentRepository ─────────────────────────────────────────────

    test('should load a JSON map through the repository', () async {
      final map = await repo.loadMap(
        'assets/data/ilonggo-dictionary-formatted.json',
      );

      expect(map['metadata']['dictionary_entry_count'], 893);
      expect((map['entries'] as List).length, 7);
    });

    test('should load a JSON list through the repository', () async {
      final list = await repo.loadList('assets/data/list.json');

      expect(list, [1, 2, 3]);
    });

    test('should cache the same future for repeated map loads', () async {
      final f1 = repo.loadMap('assets/data/ilonggo-dictionary-formatted.json');
      final f2 = repo.loadMap('assets/data/ilonggo-dictionary-formatted.json');

      expect(identical(f1, f2), isTrue);
      expect(await f1, await f2);
    });

    test('should cache the same future for repeated list loads', () async {
      final f1 = repo.loadList('assets/data/list.json');
      final f2 = repo.loadList('assets/data/list.json');

      expect(identical(f1, f2), isTrue);
    });

    test('should throw when asset is missing', () async {
      await expectLater(
        () => repo.loadMap('assets/missing.json'),
        throwsA(isA<Exception>()),
      );
    });

    test('clear should reset the cache', () async {
      await repo.loadMap('assets/data/ilonggo-dictionary-formatted.json');
      repo.clear();

      // After clear, a new Future is created
      final f1 = repo.loadMap('assets/data/ilonggo-dictionary-formatted.json');
      final f2 = repo.loadMap('assets/data/ilonggo-dictionary-formatted.json');
      expect(identical(f1, f2), isTrue); // still same within one clear cycle
    });

    // ─── LanguageDictionary via ContentRepository ─────────────────────

    test('should parse full dictionary from repo-loaded map', () async {
      final map = await repo.loadMap(
        'assets/data/ilonggo-dictionary-formatted.json',
      );
      final dictionary = LanguageDictionary.fromJson(map);

      expect(dictionary.length, 7);
      expect(dictionary.abbreviations['N'], 'Noun');
      expect(dictionary.abbreviations['IMP'], 'Imperative');
    });

    test('should JIT parse entry from repo-loaded dictionary', () async {
      final map = await repo.loadMap(
        'assets/data/ilonggo-dictionary-formatted.json',
      );
      final dictionary = LanguageDictionary.fromJson(map);

      final entry = dictionary.getEntryAt(0);
      expect(entry.word, 'abogado');
      expect(entry.partOfSpeech, 'N');
      expect(entry.meanings.first.definition, ['lawyer']);
    });

    test('should search entries from repo-loaded dictionary', () async {
      final map = await repo.loadMap(
        'assets/data/ilonggo-dictionary-formatted.json',
      );
      final dictionary = LanguageDictionary.fromJson(map);

      final results = dictionary.search('adlaw');
      expect(results.length, 2);
      expect(results.any((e) => e.word == 'adlaw-adlaw'), isTrue);
    });

    test('should handle forms correctly from repo-loaded dictionary', () async {
      final map = await repo.loadMap(
        'assets/data/ilonggo-dictionary-formatted.json',
      );
      final dictionary = LanguageDictionary.fromJson(map);

      final entry = dictionary.getEntryAt(3); // balikan
      expect(entry.meanings.length, 2);

      final inf = entry.meanings.firstWhere(
        (m) => m.forms?.contains('INF') ?? false,
      );
      expect(inf.definition, ['to go back']);

      final imp = entry.meanings.firstWhere(
        (m) => m.forms?.contains('IMP') ?? false,
      );
      expect(imp.definition, ['go back']);
    });

    test('should handle notes correctly from repo-loaded dictionary', () async {
      final map = await repo.loadMap(
        'assets/data/ilonggo-dictionary-formatted.json',
      );
      final dictionary = LanguageDictionary.fromJson(map);

      final entry = dictionary.getEntryAt(4); // pilipino
      expect(entry.meanings.first.notes, ['persons']);
      expect(entry.meanings.first.definition, ['Filipino']);
      expect(entry.meanings.first.forms, isNull);
    });

    test(
      'should preserve parenthetical before definition as raw text',
      () async {
        final map = await repo.loadMap(
          'assets/data/ilonggo-dictionary-formatted.json',
        );
        final dictionary = LanguageDictionary.fromJson(map);

        final entry = dictionary.getEntryAt(6); // lakat diri
        expect(entry.word, 'lakat diri');
        expect(entry.meanings.first.definition, [
          '(you, singular/plural)',
          'walk here',
        ]);
        expect(entry.meanings.first.forms, isNull);
        expect(entry.meanings.first.notes, isNull);
      },
    );

    test(
      'should handle union forms (INF & IMP) from repo-loaded dictionary',
      () async {
        final map = await repo.loadMap(
          'assets/data/ilonggo-dictionary-formatted.json',
        );
        final dictionary = LanguageDictionary.fromJson(map);

        final entry = dictionary.getEntryAt(5); // kaonon
        expect(entry.meanings.first.forms, ['INF', 'IMP']);
        expect(entry.meanings.first.definition, ['(to) eat']);
      },
    );

    test('should handle missing nullable fields gracefully', () async {
      final incompleteJson = {
        "word": "abot",
        "meanings": [
          {
            "definition": ["arrival"],
          },
        ],
      };

      final entry = DictionaryEntry.fromJson(incompleteJson);
      expect(entry.word, 'abot');
      expect(entry.partOfSpeech, isNull);
      expect(entry.meanings.first.forms, isNull);
      expect(entry.meanings.first.notes, isNull);
    });

    test('should handle legacy string definition during migration', () async {
      final legacyJson = {
        "word": "legacy",
        "part_of_speech": "N",
        "meanings": [
          {"definition": "old format string", "form": "INF"},
        ],
      };

      final entry = DictionaryEntry.fromJson(legacyJson);
      expect(entry.meanings.first.definition, ['old format string']);
      expect(entry.meanings.first.forms, ['INF']);
    });
  });
}
