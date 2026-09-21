class LanguageDictionary {
  const LanguageDictionary({
    required this.metadata,
    required this.abbreviations,
    required List<dynamic> rawEntries,
  }) : _rawEntries = rawEntries;

  final Map<String, dynamic> metadata;
  final Map<String, String> abbreviations;
  final List<dynamic> _rawEntries;

  factory LanguageDictionary.fromJson(Map<String, dynamic> json) {
    return LanguageDictionary(
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      abbreviations: Map<String, String>.from(
        json['abbreviations'] as Map? ?? const {},
      ),
      rawEntries: json['entries'] as List<dynamic>? ?? const [],
    );
  }

  int get length => _rawEntries.length;

  DictionaryEntry getEntryAt(int index) =>
      DictionaryEntry.fromJson(_rawEntries[index] as Map<String, dynamic>);
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.meanings,
    this.partOfSpeech,
  });

  final String word;
  final String? partOfSpeech;
  final List<Meaning> meanings;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) =>
      DictionaryEntry(
        word: json['word'] as String? ?? '',
        partOfSpeech: json['part_of_speech'] as String?,
        meanings: (json['meanings'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((value) => Meaning.fromJson(Map<String, dynamic>.from(value)))
            .toList(),
      );
}

class Meaning {
  const Meaning({required this.definition, this.forms, this.notes});

  final List<String> definition;
  final List<String>? forms;
  final List<String>? notes;

  factory Meaning.fromJson(Map<String, dynamic> json) {
    List<String>? values(Object? value) => switch (value) {
      List() => value.whereType<String>().toList(),
      String() => [value],
      _ => null,
    };
    return Meaning(
      definition: values(json['definition']) ?? const [''],
      forms: values(json['forms'] ?? json['form']),
      notes: values(json['notes']),
    );
  }
}
