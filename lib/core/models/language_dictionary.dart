class LanguageDictionary {
  final Map<String, dynamic> metadata;
  final Map<String, String> abbreviations;
  final List<dynamic> _rawEntries;

  const LanguageDictionary({
    required this.metadata,
    required this.abbreviations,
    required List<dynamic> rawEntries,
  }) : _rawEntries = rawEntries;

  factory LanguageDictionary.fromJson(Map<String, dynamic> json) {
    return LanguageDictionary(
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      abbreviations: Map<String, String>.from(
        json['abbreviations'] as Map? ?? {},
      ),
      rawEntries: json['entries'] as List<dynamic>? ?? [],
    );
  }

  int get length => _rawEntries.length;

  DictionaryEntry getEntryAt(int index) {
    return DictionaryEntry.fromJson(_rawEntries[index] as Map<String, dynamic>);
  }

  List<DictionaryEntry> search(String query) {
    final q = query.toLowerCase();
    final matches = <Map<String, dynamic>>[];
    for (final e in _rawEntries) {
      final map = e as Map<String, dynamic>;
      if ((map['word'] as String? ?? '').toLowerCase().contains(q)) {
        matches.add(map);
      }
    }
    return matches.map(DictionaryEntry.fromJson).toList();
  }
}

class DictionaryEntry {
  final String word;
  final String? partOfSpeech;
  final List<Meaning> meanings;

  const DictionaryEntry({
    required this.word,
    this.partOfSpeech,
    required this.meanings,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String?,
      meanings: (json['meanings'] as List<dynamic>? ?? [])
          .map((e) => Meaning.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Meaning {
  final List<String> definition;
  final List<String>? forms;
  final List<String>? notes;

  const Meaning({required this.definition, this.forms, this.notes});

  factory Meaning.fromJson(Map<String, dynamic> json) {
    final raw = json['definition'];
    final List<String> defs;
    if (raw is List) {
      defs = raw.cast<String>();
    } else {
      defs = [(raw as String? ?? '')];
    }

    // Handles legacy 'form' (string) during migration
    final rawForms = json.containsKey('forms') ? json['forms'] : json['form'];
    final List<String>? formsList;
    if (rawForms is List) {
      formsList = rawForms.cast<String>();
    } else if (rawForms is String) {
      formsList = [rawForms];
    } else {
      formsList = null;
    }

    final rawNotes = json['notes'];
    final List<String>? notesList;
    if (rawNotes is List) {
      notesList = rawNotes.cast<String>();
    } else if (rawNotes is String) {
      notesList = [rawNotes];
    } else {
      notesList = null;
    }

    return Meaning(definition: defs, forms: formsList, notes: notesList);
  }
}
