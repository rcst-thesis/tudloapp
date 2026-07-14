import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/data/content_repository.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

export 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

/// Lazy, cached JSON-backed lesson content.
class LessonBank {
  static final _repository = ContentRepository();
  static const _asset = 'assets/data/tudlo_updated_lesson_dataset.json';

  static Future<LevelContent> loadLevelContentForLevel(int level) async {
    final data = await _repository.loadMap(_asset);
    return _levelContentFromJson(data, level);
  }

  static Future<List<LevelContent>> loadAllLevelContentForActiveGrade() async {
    final data = await _repository.loadMap(_asset);
    return [
      for (var level = 1; level <= AppData.maxLevel; level++)
        _levelContentFromJson(data, level),
    ];
  }

  static Future<List<LessonTerm>> loadTermsForActiveGrade() async {
    final contents = await loadAllLevelContentForActiveGrade();
    final seen = <String>{};
    return [
      for (final content in contents)
        for (final example in content.examples)
          if (example.hiligaynon.trim().isNotEmpty &&
              seen.add(
                '${example.hiligaynon.trim().toLowerCase()}|'
                '${example.english.trim().toLowerCase()}',
              ))
            LessonTerm(
              unitNumber: content.unitNumber,
              unitTitle: AppData.units
                  .firstWhere((unit) => unit.number == content.unitNumber)
                  .title,
              gradeLevel: content.gradeLevel,
              hil: example.hiligaynon,
              eng: example.english,
              exampleSentenceHiligaynon: example.note,
              imagePath: example.imageAsset,
              audioPath: example.audioAsset,
              lessonNumber: content.lessonNumber,
            ),
    ];
  }

  static String lessonTitleForLevel(int level) =>
      'Leksyon ${AppData.lessonNumberForLevel(level)}';

  static int unitForLevel(int level) => AppData.unitForLevel(level).number;

  static LevelContent _levelContentFromJson(
    Map<String, dynamic> data,
    int level,
  ) {
    final grade = AppData.selectedGradeLevel.number;
    final gradeData = _jsonList(data['grades'])
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['gradeLevel'] == grade);
    final lessons = [
      for (final unit in _jsonList(
        gradeData['units'],
      ).cast<Map<String, dynamic>>())
        ..._jsonList(unit['lessons']).cast<Map<String, dynamic>>(),
    ];
    if (level < 1 || level > lessons.length) {
      throw RangeError.range(level, 1, lessons.length, 'level');
    }
    final lessonData = lessons[level - 1];
    final unit = _integer(lessonData['unitNumber'], unitForLevel(level));
    final lesson = _integer(
      lessonData['lessonNumber'],
      AppData.lessonNumberForLevel(level),
    );

    return LevelContent(
      id: _string(lessonData['id'], 'g${grade}_u${unit}_l$lesson'),
      gradeLevel: grade,
      unitNumber: unit,
      lessonNumber: lesson,
      title: _string(lessonData['title'], 'Leksyon $lesson'),
      storyTitle: _nullableString(lessonData['storyTitle']),
      story: _nullableString(lessonData['story']),
      storyImageAsset: _nullableString(lessonData['storyImageAsset']),
      lesson: _string(lessonData['lesson'], ''),
      examples: [
        for (final item in _jsonList(
          lessonData['examples'],
        ).cast<Map<String, dynamic>>())
          LessonExample(
            category: _string(item['category'], ''),
            hiligaynon: _string(item['hiligaynon'], ''),
            english: _string(item['english'], ''),
            note: _string(item['note'], ''),
            imageAsset: _nullableString(item['imageAsset']),
            audioAsset: _nullableString(item['audioAsset']),
          ),
      ],
      quizItems: [
        for (final item in _jsonList(
          lessonData['shortQuiz'],
        ).cast<Map<String, dynamic>>())
          _quizFromJson(item, grade, unit, lesson),
      ],
    );
  }

  static QuizItem _quizFromJson(
    Map<String, dynamic> data,
    int grade,
    int unit,
    int lesson,
  ) {
    final pairs = _jsonMap(
      data['pairs'],
    ).map((key, value) => MapEntry(key, '$value'));
    final choices = _jsonList(data['choices']).map((item) => '$item').toList();
    if (choices.isEmpty) choices.add('Tapos');
    final answer = _string(data['answer'], choices.first);
    return QuizItem(
      id: _string(data['id'], 'g${grade}_u${unit}_l${lesson}_quiz'),
      type: _quizType(_string(data['type'], 'multipleChoice'), pairs),
      question: _string(data['question'], ''),
      choices: choices,
      answer: answer,
      audioAsset: _nullableString(data['audioAsset']),
      imageAsset: _nullableString(data['imageAsset']),
      leftItems: pairs.isEmpty
          ? _jsonList(data['leftItems']).map((item) => '$item').toList()
          : pairs.keys.toList(),
      rightItems: pairs.isEmpty
          ? _jsonList(data['rightItems']).map((item) => '$item').toList()
          : pairs.values.toList(),
      matchingPairs: pairs,
    );
  }

  static QuizType _quizType(String value, Map<String, String> pairs) {
    if (pairs.isNotEmpty) return QuizType.matching;
    return switch (value) {
      'pictureChoice' => QuizType.pictureChoice,
      'matching' => QuizType.matching,
      'arrangeWords' => QuizType.arrangeWords,
      'fillBlankChoice' => QuizType.fillBlankChoice,
      'listenAndChoose' => QuizType.listenAndChoose,
      'tapCorrectWord' => QuizType.tapCorrectWord,
      _ => QuizType.multipleChoice,
    };
  }

  static List<dynamic> _jsonList(Object? value) =>
      value is List ? value : const [];

  static Map<String, dynamic> _jsonMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static String _string(Object? value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text == 'null' ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text == 'null' ? null : text;
  }

  static int _integer(Object? value, int fallback) =>
      value is int ? value : int.tryParse('$value') ?? fallback;
}
