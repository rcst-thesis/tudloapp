/// One word-based dictionary entry.
///
/// Dictionary entries are for lookup and translation only. Full lesson
/// sentences belong in LessonBank, not here.
class DictionaryEntry {
  final String hiligaynon;
  final String english;
  final String? pronunciation;
  final String? audioPath;
  final String? partOfSpeech;
  final String? exampleSentence;

  const DictionaryEntry({
    required this.hiligaynon,
    required this.english,
    this.pronunciation,
    this.audioPath,
    this.partOfSpeech,
    this.exampleSentence,
  });
}
