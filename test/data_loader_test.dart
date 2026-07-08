import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/models/language_dictionary.dart';
// Note: In your actual project, import the file we create below
// import 'package:your_app/models/dictionary_model.dart';

void main() {
  group('IlonggoDictionary TDD Suite', () {
    // 1. Define the mock payload based on our expected contract
    final Map<String, dynamic> mockJson = {
      "dataset_name": "Ilonggo-English Dictionary",
      "source_file": "Ilonggo_Dictionary (1).xlsx",
      "language": "Ilonggo / Hiligaynon",
      "metadata": {
        "dictionary_entry_count": 893,
        "verb_appendix_count": 102,
        "notes":
            "Converted from the uploaded Excel dictionary file. Keys are Dart/Flutter-friendly snake_case.",
      },
      "abbreviations": [
        {"code": "N", "meaning": "Noun"},
        {"code": "V", "meaning": "Verb"},
      ],
      "dictionary": [
        {
          "ilonggo_word": "abogado",
          "part_of_speech": "N",
          "english_definition": "lawyer",
        },
      ],
    };

    test('should parse IlonggoDictionary root object correctly', () {
      final dictionary = LanguageDictionary.fromJson(mockJson);

      expect(dictionary.datasetName, 'Ilonggo-English Dictionary');
      expect(dictionary.sourceFile, 'Ilonggo_Dictionary (1).xlsx');
      expect(dictionary.language, 'Ilonggo / Hiligaynon');
    });

    test('should parse DictionaryMetadata correctly', () {
      final dictionary = LanguageDictionary.fromJson(mockJson);

      expect(dictionary.metadata.dictionaryEntryCount, 893);
      expect(dictionary.metadata.verbAppendixCount, 102);
      expect(
        dictionary.metadata.notes,
        contains('Converted from the uploaded Excel'),
      );
    });

    test('should parse Abbreviation list correctly', () {
      final dictionary = LanguageDictionary.fromJson(mockJson);

      expect(dictionary.abbreviations.length, 2);
      expect(dictionary.abbreviations.first.code, 'N');
      expect(dictionary.abbreviations.first.meaning, 'Noun');
    });

    test('should parse DictionaryEntry list correctly', () {
      final dictionary = LanguageDictionary.fromJson(mockJson);

      expect(dictionary.entries.length, 1);
      expect(dictionary.entries.first.word, 'abogado');
      expect(dictionary.entries.first.partOfSpeech, 'N');
      expect(dictionary.entries.first.englishDefinition, 'lawyer');
    });

    test('should handle missing nullable fields gracefully', () {
      // If some entries might not have a part of speech, we test that behavior here.
      final incompleteEntryJson = {
        "ilonggo_word": "abot (2)",
        "english_definition": "arrival",
        // 'part_of_speech' is intentionally missing
      };

      final entry = DictionaryEntry.fromJson(incompleteEntryJson);
      expect(entry.word, 'abot (2)');
      expect(entry.partOfSpeech, isNull);
    });
  });
}
