import 'dart:convert';
import 'dart:io';

final _formPattern = RegExp(r'\s*\(([^)]+)\)\s*$');
final _tokenDelimiter = RegExp(r'\s*(?:,|&|/|\band\b|\bor\b)\s*');

void main() async {
  final rawFile = File('assets/data/ilonggo_dictionary_dataset.json');
  final outFile = File('assets/data/ilonggo-dictionary-formatted.json');

  if (!await rawFile.exists()) {
    print('Error: ilonggo_dictionary_dataset.json not found.');
    return;
  }

  final rawData = jsonDecode(await rawFile.readAsString());

  final abbreviations = <String, String>{};
  for (var abbr in rawData['abbreviations'] ?? []) {
    final code =
        abbr['code']?.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') ?? '';
    if (code.isNotEmpty) abbreviations[code] = abbr['meaning'];
  }

  final unified = <Map<String, dynamic>>[];
  for (var e in rawData['dictionary'] ?? []) {
    unified.add({
      'word': e['ilonggo_word'],
      'pos': e['part_of_speech'],
      'definition': e['english_definition'],
    });
  }
  for (var v in rawData['verb_list'] ?? []) {
    unified.add({
      'word': v['ilonggo_verb'],
      'pos': 'V',
      'definition': v['english_meaning'],
    });
  }

  final grouped = <String, Map<String, dynamic>>{};

  for (var entry in unified) {
    final rawWord = entry['word']?.toString() ?? '';
    final cleanWord = rawWord
        .replaceAll(RegExp(r'\s*\(\d+\)$'), '')
        .trim()
        .toLowerCase();
    if (cleanWord.isEmpty) continue;

    final rawPos = entry['pos']?.toString() ?? '';
    final cleanPos = rawPos.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final key = '${cleanWord}_$cleanPos';

    final rawDef = entry['definition']?.toString() ?? '';
    if (rawDef.trim().isEmpty) continue;

    final segments = rawDef
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final texts = <String>[];
    final formsPerSegment = <List<String>?>[];
    final notesPerSegment = <List<String>?>[];

    for (final seg in segments) {
      final match = _formPattern.firstMatch(seg);
      final rawParenContent = match?.group(1);
      var text = seg;
      List<String>? forms;
      List<String>? notes;

      if (rawParenContent != null) {
        final textBeforeParen = seg.substring(0, match!.start).trim();

        // ONLY extract if parenthetical comes AFTER definition text
        if (textBeforeParen.isNotEmpty) {
          text = seg.replaceFirst(_formPattern, '').trim();

          final tokens = rawParenContent
              .split(_tokenDelimiter)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          final validForms = <String>[];
          final invalidTokens = <String>[];

          for (final token in tokens) {
            final cleanToken = token.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            if (abbreviations.containsKey(cleanToken)) {
              validForms.add(cleanToken);
            } else {
              invalidTokens.add(token);
            }
          }

          if (validForms.isNotEmpty) forms = validForms;
          if (invalidTokens.isNotEmpty) notes = invalidTokens;
        }
        // else: parenthetical is BEFORE the words or IS the entire segment → leave it alone
      }

      if (text.isNotEmpty) {
        texts.add(text);
        formsPerSegment.add(forms);
        notesPerSegment.add(notes);
      }
    }

    final bySignature = <String, List<String>>{};
    final sigForms = <String, List<String>?>{};
    final sigNotes = <String, List<String>?>{};

    for (var i = 0; i < texts.length; i++) {
      final f = formsPerSegment[i]?.join('|') ?? '';
      final n = notesPerSegment[i]?.join('|') ?? '';
      final signature = '${f}__$n';
      bySignature.putIfAbsent(signature, () => []).add(texts[i]);
      sigForms[signature] = formsPerSegment[i];
      sigNotes[signature] = notesPerSegment[i];
    }

    final batches = <Map<String, dynamic>>[];
    for (final e in bySignature.entries) {
      final batch = <String, dynamic>{'definition': e.value};
      final f = sigForms[e.key];
      final n = sigNotes[e.key];
      if (f != null && f.isNotEmpty) batch['forms'] = f;
      if (n != null && n.isNotEmpty) batch['notes'] = n;
      batches.add(batch);
    }

    grouped.putIfAbsent(
      key,
      () => {
        'word': cleanWord,
        'part_of_speech': cleanPos.isEmpty ? null : cleanPos,
        'meanings': <Map<String, dynamic>>[],
      },
    );

    final meanings = grouped[key]!['meanings'] as List<Map<String, dynamic>>;

    for (final batch in batches) {
      final batchDefs = (batch['definition'] as List).cast<String>();
      final batchForms = (batch['forms'] as List?)?.cast<String>();
      final batchNotes = (batch['notes'] as List?)?.cast<String>();

      final existingIndex = meanings.indexWhere((m) {
        final existingDefs = (m['definition'] as List).cast<String>();
        if (existingDefs.length != batchDefs.length) return false;
        return existingDefs.every((d) => batchDefs.contains(d));
      });

      if (existingIndex != -1) {
        final existingForms = (meanings[existingIndex]['forms'] as List?)
            ?.cast<String>();
        if (existingForms == null && batchForms != null) {
          meanings[existingIndex]['forms'] = batchForms;
        } else if (existingForms != null && batchForms != null) {
          meanings[existingIndex]['forms'] = {
            ...existingForms,
            ...batchForms,
          }.toList();
        }

        final existingNotes = (meanings[existingIndex]['notes'] as List?)
            ?.cast<String>();
        if (existingNotes == null && batchNotes != null) {
          meanings[existingIndex]['notes'] = batchNotes;
        } else if (existingNotes != null && batchNotes != null) {
          meanings[existingIndex]['notes'] = {
            ...existingNotes,
            ...batchNotes,
          }.toList();
        }
      } else {
        meanings.add(batch);
      }
    }
  }

  final output = {
    'metadata': rawData['metadata'] ?? {},
    'abbreviations': abbreviations,
    'entries': grouped.values.toList(),
  };

  await outFile.create(recursive: true);
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );
  print('Done. ${grouped.length} entries written.');
}
