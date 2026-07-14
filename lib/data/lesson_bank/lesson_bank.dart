import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/data/content_repository.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade1/lessonBank/lesson_bank.dart';
import 'package:tudloapp/data/lesson_bank/grade2/lessonBank/lesson_bank.dart';
import 'package:tudloapp/data/lesson_bank/grade3/lessonBank/lesson_bank.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

export 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

/// Central lesson content source.
///
/// Level Game questions use only the current unit's terms. Unit Content Preview
/// also reads from this same bank, so editing content here updates both places.
class LessonBank {
  static const _jsonDatasetAsset =
      'assets/data/tudlo_updated_lesson_dataset.json';

  static const gradeDatasets = {
    GradeLevel.grade1: grade1LessonDataset,
    GradeLevel.grade2: grade2LessonDataset,
    GradeLevel.grade3: grade3LessonDataset,
  };

  static const List<LessonTerm> terms = [
    ...grade1LessonTerms,
    ...grade2LessonTerms,
    ...grade3LessonTerms,
  ];

  static Future<LevelContent> loadLevelContentForLevel(int level) async {
    try {
      final raw = await rootBundle.loadString(_jsonDatasetAsset);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return _levelContentFromJson(data, level);
    } catch (_) {
      return levelContentForLevel(level);
    }
  }

  static LevelContent _levelContentFromJson(
    Map<String, dynamic> data,
    int level,
  ) {
    final grade = AppData.selectedGradeLevel.number;
    final gradeData = _jsonList(data['grades'])
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (item) => item['unitNumber'] == unit,
          orElse: () =>
              throw StateError('Grade $grade unit $unit not found in JSON.'),
        );
    final lessonData = _jsonList(unitData['lessons'])
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (item) => item['lessonNumber'] == lesson,
          orElse: () => throw StateError(
            'Grade $grade unit $unit lesson $lesson not found in JSON.',
          ),
        );

    final quizItems = _jsonList(lessonData['shortQuiz'])
        .cast<Map<String, dynamic>>()
        .map((item) => _quizItemFromJson(item, grade, unit, lesson))
        .toList();

    return LevelContent(
      id: _string(lessonData['id'], 'g${grade}_u${unit}_l$lesson'),
      gradeLevel: grade,
      unitNumber: unit,
      lessonNumber: lesson,
      title: _jsonString(lessonData['title'], 'Leksyon $lesson'),
      storyTitle: _storyTitleFromJson(lessonData),
      story: _nullableJsonString(lessonData['story']),
      storyImageAsset: _nullableJsonString(lessonData['storyImageAsset']),
      lesson: _jsonString(lessonData['lesson'], ''),
      examples: _jsonList(
        lessonData['examples'],
      ).cast<Map<String, dynamic>>().map(_lessonExampleFromJson).toList(),
      quizItems: _jsonList(lessonData['shortQuiz'])
          .cast<Map<String, dynamic>>()
          .map((item) => _quizItemFromJson(item, grade, unit, lesson))
          .toList(),
    );
  }

  static LessonExample _lessonExampleFromJson(Map<String, dynamic> data) {
    return LessonExample(
      category: _jsonString(data['category'], 'Example'),
      hiligaynon: _jsonString(data['hiligaynon'], ''),
      english: _jsonString(data['english'], ''),
      note: _jsonString(data['note'], ''),
      imageAsset: _nullableJsonString(data['imageAsset']),
      audioAsset: _nullableJsonString(data['audioAsset']),
    );
  }

  static QuizItem _quizFromJson(
    Map<String, dynamic> data,
    int grade,
    int unit,
    int lesson,
  ) {
    final choices = _jsonList(data['choices']).map((item) => '$item').toList();
    final answer = _nullableJsonString(data['answer']);
    final fallbackAnswer = choices.isEmpty ? 'Natapos ko ini' : choices.first;
    final normalizedChoices = choices.isEmpty ? [fallbackAnswer] : choices;
    final pairs = _jsonMap(
      data['pairs'],
    ).map((key, value) => MapEntry(key, '$value'));
    final choices = _jsonList(data['choices']).map((item) => '$item').toList();
    if (choices.isEmpty) choices.add('Tapos');
    final answer = _string(data['answer'], choices.first);
    return QuizItem(
      id: _jsonString(data['id'], 'g${grade}_u${unit}_l${lesson}_quiz'),
      type: _quizTypeFromJson(_jsonString(data['type'], 'tapChoice'), pairs),
      question: _jsonString(data['question'], _jsonString(data['raw'], '')),
      choices: normalizedChoices,
      answer: answer ?? fallbackAnswer,
      audioAsset: _nullableJsonString(data['audioAsset']),
      imageAsset: _nullableJsonString(data['imageAsset']),
      leftItems: leftItems,
      rightItems: rightItems,
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

  static int unitForLevel(int level) {
    final unit = ((level - 1) ~/ AppData.unitLevels) + 1;
    return unit.clamp(1, AppData.units.length);
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

  static String? _storyTitleFromJson(Map<String, dynamic> data) {
    final title = _nullableJsonString(data['storyTitle']);
    if (title != null) return title;
    final story = _nullableJsonString(data['story']);
    return story == null ? null : _jsonString(data['title'], 'Istorya');
  }

  static LevelContent levelContentForLevel(int level) {
    final grade = AppData.selectedGradeLevel;
    final unit = unitForLevel(level);
    final lesson = ((level - 1) % AppData.unitLevels) + 1;
    final source = _sourceFor(grade: grade, unit: unit, lesson: lesson);
    if (source != null) {
      return _levelContentFromSource(
        grade: grade,
        unit: unit,
        lesson: lesson,
        source: source,
        terms: _termsForLocalLesson(level),
      );
    }

    final legacy = contentForLevel(level);
    final focusTerms = _nonScenarioTerms(_termsForLocalLesson(level)).take(4);
    return LevelContent(
      id: 'grade${grade.number}-unit$unit-lesson$lesson',
      gradeLevel: grade.number,
      unitNumber: unit,
      lessonNumber: lesson,
      title: legacy.title,
      storyTitle: grade == GradeLevel.grade3 ? legacy.storyTitle : null,
      story: grade == GradeLevel.grade3 ? legacy.story : null,
      storyImageAsset: grade == GradeLevel.grade3
          ? _storyImageAsset(grade: grade, unit: unit, lesson: lesson)
          : null,
      lesson: legacy.shortLesson,
      examples: legacy.examples,
      quizItems: [
        for (final term in focusTerms)
          QuizItem(
            id: '${term.hil}-choice',
            type: QuizType.multipleChoice,
            question: 'Ano ang kahulugan sang "${term.hil}"?',
            choices: _choicePoolFor(term, _termsForLocalLesson(level)),
            answer: term.eng,
            imageAsset: term.imagePath,
            audioAsset: term.audioPath,
          ),
      ],
    );
  }

  static GradeLessonSource? _sourceFor({
    required GradeLevel grade,
    required int unit,
    required int lesson,
  }) {
    if (unit != 1) return null;
    final sources = switch (grade) {
      GradeLevel.grade1 => grade1Unit1SourceLessons,
      GradeLevel.grade2 => grade2Unit1SourceLessons,
      GradeLevel.grade3 => grade3Unit1SourceLessons,
    };
    if (lesson < 1 || lesson > sources.length) return null;
    return sources[lesson - 1];
  }

  static LevelContent _levelContentFromSource({
    required GradeLevel grade,
    required int unit,
    required int lesson,
    required GradeLessonSource source,
    required List<LessonTerm> terms,
  }) {
    final reading = source.readingText;
    final hasGradeThreeStory = grade == GradeLevel.grade3 && reading.length > 1;
    return LevelContent(
      id: 'grade${grade.number}-unit$unit-lesson$lesson',
      gradeLevel: grade.number,
      unitNumber: unit,
      lessonNumber: lesson,
      title: 'Leksyon ${source.lessonNumber}: ${source.lessonTitle}',
      storyTitle: hasGradeThreeStory ? reading.first : null,
      story: hasGradeThreeStory ? reading.skip(1).join('\n\n') : null,
      storyImageAsset: hasGradeThreeStory
          ? _storyImageAsset(grade: grade, unit: unit, lesson: lesson)
          : null,
      lesson: source.paminsaraIni.join('\n\n'),
      examples: _examplesFromSource(source, terms),
      quizItems: _quizItemsFromSource(grade, source),
    );
  }

  static List<LessonExample> _examplesFromSource(
    GradeLessonSource source,
    List<LessonTerm> terms,
  ) {
    final examples = <LessonExample>[];
    for (var index = 0; index < source.pasanyugaIni.length; index += 2) {
      final vocabulary = source.pasanyugaIni[index];
      final parts = vocabulary.split(' - ');
      examples.add(
        LessonExample(
          category: 'Gamita Ini',
          hiligaynon: parts.first.trim(),
          english: parts.length > 1 ? parts.sublist(1).join(' - ').trim() : '',
          note: index + 1 < source.pasanyugaIni.length
              ? source.pasanyugaIni[index + 1]
              : '',
        ),
      );
    }
    for (final term in terms.take(8)) {
      if (examples.any((example) => example.hiligaynon == term.hil)) continue;
      examples.add(
        LessonExample(
          category: term.type == LessonContentType.sentence
              ? 'Pangungusap'
              : 'Halimbawa',
          hiligaynon: term.hil,
          english: term.eng,
          note: term.exampleSentenceHiligaynon ?? '',
          imageAsset: term.imagePath,
          audioAsset: term.audioPath,
        ),
      );
    }
    return examples;
  }

  static List<QuizItem> _quizItemsFromSource(
    GradeLevel grade,
    GradeLessonSource source,
  ) {
    if (grade == GradeLevel.grade1 && source.lessonNumber == 1) {
      const choices = [
        'Brum brum!',
        'Moo moo!',
        'Waa waa!',
        'Prit prit!',
        'Klik klik!',
        'Kring kring!',
      ];
      return const [
        QuizItem(
          id: 'alarm-sound',
          type: QuizType.pictureChoice,
          question: 'Pili-a ang huni sang alarm clock.',
          choices: choices,
          answer: 'Kring kring!',
          imageAsset:
              'assets/images/level_game/Grade1/unit1/lesson1/alarm-clock.png',
        ),
        QuizItem(
          id: 'cow-sound',
          type: QuizType.pictureChoice,
          question: 'Pili-a ang huni sang baka.',
          choices: choices,
          answer: 'Moo moo!',
          imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/cow.png',
        ),
        QuizItem(
          id: 'whistle-sound',
          type: QuizType.pictureChoice,
          question: 'Pili-a ang huni sang pito.',
          choices: choices,
          answer: 'Prit prit!',
          imageAsset:
              'assets/images/level_game/Grade1/unit1/lesson1/whistle.png',
        ),
        QuizItem(
          id: 'baby-sound',
          type: QuizType.pictureChoice,
          question: 'Pili-a ang huni sang lapsag.',
          choices: choices,
          answer: 'Waa waa!',
          imageAsset:
              'assets/images/level_game/Grade1/unit1/lesson1/crying-baby.png',
        ),
        QuizItem(
          id: 'car-sound',
          type: QuizType.pictureChoice,
          question: 'Pili-a ang huni sang salakyan.',
          choices: choices,
          answer: 'Brum brum!',
          imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/car.png',
        ),
        QuizItem(
          id: 'camera-sound',
          type: QuizType.pictureChoice,
          question: 'Pili-a ang huni sang kamera.',
          choices: choices,
          answer: 'Klik klik!',
          imageAsset:
              'assets/images/level_game/Grade1/unit1/lesson1/camera.png',
        ),
      ];
    }

    if (grade == GradeLevel.grade2 && source.lessonNumber == 1) {
      return const [
        QuizItem(
          id: 'g2-noun-definition',
          type: QuizType.multipleChoice,
          question:
              'Ano ang tawag sa ngalan sang tawo, butang, sapat, lugar kag hitabo?',
          choices: ['Pangalan', 'Kasilingan', 'Buluthuan', 'Barangay'],
          answer: 'Pangalan',
        ),
        QuizItem(
          id: 'g2-story-child',
          type: QuizType.multipleChoice,
          question: 'Sin-o ang bata sa istorya nga "Dalayawon"?',
          choices: ['Rina', 'Nanay Rowena', 'Mayor Basilio', 'Gg. Ramos'],
          answer: 'Rina',
        ),
        QuizItem(
          id: 'g2-project',
          type: QuizType.multipleChoice,
          question: 'Ano nga proyekto ang ginahimo sa barangay?',
          choices: [
            'Matinlo kag Berde nga Barangay',
            'Brigada Eskwela',
            'Adlaw sang Kahilwayan',
            'Lakbay Aral',
          ],
          answer: 'Matinlo kag Berde nga Barangay',
        ),
        QuizItem(
          id: 'g2-neighbor',
          type: QuizType.fillBlankChoice,
          question:
              'Kompletoha: Naagyan niya ang iya mga ___ sa Kalye Malinong.',
          choices: ['kasilingan', 'lapis', 'kuring', 'bulak'],
          answer: 'kasilingan',
        ),
        QuizItem(
          id: 'g2-category-match',
          type: QuizType.matching,
          question: 'Ipares ang grupo sang pangalan kag kahulugan.',
          choices: [],
          answer: '',
          leftItems: ['Tawo', 'Butang', 'Sapat', 'Lugar'],
          rightItems: ['Person', 'Thing', 'Animal', 'Place'],
          matchingPairs: {
            'Tawo': 'Person',
            'Butang': 'Thing',
            'Sapat': 'Animal',
            'Lugar': 'Place',
          },
        ),
      ];
    }

    if (grade == GradeLevel.grade3 && source.lessonNumber == 1) {
      return const [
        QuizItem(
          id: 'g3-count-noun',
          type: QuizType.multipleChoice,
          question:
              'Ano ang tawag sa mga pangalan nga pareho sang luto nga kamatis, prutas, kag tatlo ka adlaw?',
          choices: [
            'Pangalan nga pang-isip',
            'Pangalan nga indi maisip',
            'Katawhan',
            'Hinabo',
          ],
          answer: 'Pangalan nga pang-isip',
        ),
        QuizItem(
          id: 'g3-station',
          type: QuizType.multipleChoice,
          question: 'Ano ang kahulugan sang "estasyon"?',
          choices: [
            'balantayan sang salakyan',
            'dalagku nga mga edipisyo',
            'talamnan sang ulutanon',
            'bandehado nga kan-on',
          ],
          answer: 'balantayan sang salakyan',
        ),
        QuizItem(
          id: 'g3-establishment',
          type: QuizType.multipleChoice,
          question: 'Ano ang kahulugan sang "establisyemento"?',
          choices: [
            'dalagku nga mga edipisyo ukon building',
            'balantayan sang salakyan',
            'ulutanon sa talamnan',
            'pinirito nga isda',
          ],
          answer: 'dalagku nga mga edipisyo ukon building',
        ),
        QuizItem(
          id: 'g3-why-early',
          type: QuizType.multipleChoice,
          question:
              'Ngaa aga pa ginpukaw ni Nanay Rowena ang iya pamilya kag si Rina?',
          choices: [
            'Makadto sila sa lugar sang tatay ni Rina.',
            'May klase si Rina.',
            'Magbakal sila sa merkado.',
            'Magpaninlo sila sang barangay.',
          ],
          answer: 'Makadto sila sa lugar sang tatay ni Rina.',
        ),
        QuizItem(
          id: 'g3-word-match',
          type: QuizType.matching,
          question: 'Ipares ang tinaga kag kahulugan.',
          choices: [],
          answer: '',
          leftItems: ['estasyon', 'establisyemento', 'kamatis', 'talong'],
          rightItems: [
            'balantayan sang salakyan',
            'dalagku nga mga edipisyo ukon building',
            'tomato',
            'eggplant',
          ],
          matchingPairs: {
            'estasyon': 'balantayan sang salakyan',
            'establisyemento': 'dalagku nga mga edipisyo ukon building',
            'kamatis': 'tomato',
            'talong': 'eggplant',
          },
        ),
      ];
    }

    return const [
      QuizItem(
        id: 'source-check',
        type: QuizType.multipleChoice,
        question: 'Ano ang leksiyon nga ginatun-an naton?',
        choices: ['Leksiyon', 'Dula', 'Mapa', 'Profile'],
        answer: 'Leksiyon',
      ),
    ];
  }

  static List<String> _choicePoolFor(LessonTerm answer, List<LessonTerm> pool) {
    final choices = <String>[answer.eng];
    for (final term in pool) {
      if (term.eng == answer.eng || choices.contains(term.eng)) continue;
      choices.add(term.eng);
      if (choices.length == 4) break;
    }
    while (choices.length < 4) {
      choices.add('Pamati-i liwat');
    }
    return choices;
  }

  static String _storyImageAsset({
    required GradeLevel grade,
    required int unit,
    required int lesson,
  }) {
    const root = 'assets';
    return '$root/images/level_game/Grade${grade.number}/unit$unit/lesson$lesson/story.png';
  }

  static LessonLevelContent contentForLevel(int level) {
    if (_isGradeTwoUnitOneTextbookLevel(level)) {
      return gradeTwoUnitOneContentForLevel(level);
    }

    if (AppData.selectedGradeLevel == GradeLevel.grade3) {
      return gradeThreePdfContentForLevel(level);
    }

    final dataset = _activeGradeDataset;
    final unit = unitForLevel(level);
    final unitTitle = _unitTitleForActiveGradeUnit(unit);
    final levelTerms = _nonScenarioTerms(_termsForLocalLesson(level));
    final focusTerms = levelTerms.take(4).toList();
    if (focusTerms.isEmpty) {
      return LessonLevelContent(
        title: unitTitle,
        storyTitle: 'Source Needed',
        story: 'No source-backed lesson data is loaded for this grade yet.',
        shortLesson:
            'Add a verified lesson dataset before enabling this level game.',
        examples: const [],
      );
    }

    final focusLabels = focusTerms.map((term) => term.hil).toList();
    final focusWords = _joinQuoted(focusLabels);

    return LessonLevelContent(
      title: unitTitle,
      storyTitle: 'Listen and Learn',
      story: _applyGradeTemplate(
        dataset.storyTemplate,
        unitTitle: unitTitle,
        focusWords: focusWords,
      ),
      shortLesson: _applyGradeTemplate(
        dataset.lessonTemplate,
        unitTitle: unitTitle,
        focusWords: focusWords,
      ),
      examples: focusTerms
          .map((term) => LessonExample(hiligaynon: term.hil, english: term.eng))
          .toList(),
    );
  }

  static bool _isGradeTwoUnitOneTextbookLevel(int level) {
    if (AppData.selectedGradeLevel != GradeLevel.grade2) return false;
    if (unitForLevel(level) != 1) return false;
    final localLevel = ((level - 1) % AppData.unitLevels) + 1;
    return localLevel <= 2;
  }

  static List<LessonQuestion> questionsForLevel(int level) {
    final rng = math.Random(level + AppData.selectedGradeLevel.number * 1000);
    if (AppData.selectedGradeLevel == GradeLevel.grade3 && level == 1) {
      return gradeThreePdfQuestionSet(rng);
    }

    if (_isGradeTwoUnitOneTextbookLevel(level)) {
      return gradeTwoUnitOneQuestionSet(level);
    }

    final scopedUnitTerms = _termsForUnitLessonScope(level);
    final levelTerms = _termsForLocalLesson(level);
    final practiceTerms = _nonScenarioTerms(levelTerms);
    final practiceUnitTerms = _nonScenarioTerms(scopedUnitTerms);
    if (practiceTerms.isEmpty || practiceUnitTerms.isEmpty) {
      return _sourceUnavailableQuestionSet();
    }

    final questions = <LessonQuestion>[
      for (var index = 0; index < 3; index++)
        _translationChoiceQuestion(
          term: practiceTerms[(level + index) % practiceTerms.length],
          englishToHiligaynon: index.isEven,
          pool: practiceTerms,
          rng: rng,
        ),
      for (var index = 0; index < 3; index++)
        _arrangeWordsQuestion(level + index, practiceTerms, rng),
      for (var index = 0; index < 2; index++)
        _matchingQuestion(practiceTerms, practiceUnitTerms, level + index * 3),
      for (var index = 0; index < 2; index++)
        _missingWordQuestion(
          level + index,
          levelTerms,
          rng,
          unitFallbackTerms: scopedUnitTerms,
        ),
    ];
    final firstImageQuestion = _imageChoiceQuestion(
      levelTerms,
      rng,
      seed: level,
    );
    final secondImageQuestion = _imageChoiceQuestion(
      levelTerms,
      rng,
      seed: level + 7,
      avoidAnswer: firstImageQuestion?.answer,
    );
    if (firstImageQuestion != null) questions.add(firstImageQuestion);
    if (secondImageQuestion != null) questions.add(secondImageQuestion);

    return _completeFlexibleQuestionSet(
      questions,
      level: level,
      levelTerms: practiceTerms,
      unitTerms: practiceUnitTerms,
      scenarioTerms: levelTerms,
      scenarioUnitTerms: scopedUnitTerms,
      rng: rng,
    );
  }

  static String lessonTitleForLevel(int level) {
    return contentForLevel(level).title;
  }

  static List<LessonQuestion> _sourceUnavailableQuestionSet() {
    return const [
      LessonQuestion.translationChoice(
        prompt: 'No source-backed lesson data is loaded for this grade yet.',
        answer: 'Source needed',
        choices: [
          'Source needed',
          'Old placeholder',
          'Random lesson',
          'Use legacy data',
        ],
        targetPhrase: 'Source-backed lesson data',
        targetMeaning: 'Source needed',
        directionLabel: 'Dataset status',
      ),
    ];
  }

  static List<LessonTerm> termsForLevel(int level) {
    return _termsForLocalLesson(level);
  }

  static List<LessonTerm> termsForUnit(int unitNumber) {
    return terms.where((term) => term.unitNumber == unitNumber).toList();
  }

  static List<LessonTerm> _termsForActiveGradeUnit(int unitNumber) {
    final allUnitTerms = termsForUnit(unitNumber);
    final gradeTerms = allUnitTerms
        .where(_activeGradeDataset.includes)
        .toList();
    return gradeTerms.isEmpty ? allUnitTerms : gradeTerms;
  }

  static int unitForLevel(int level) {
    final unit = ((level - 1) ~/ AppData.unitLevels) + 1;
    return unit.clamp(1, AppData.units.length);
  }

  static String _unitTitleForActiveGradeUnit(int unitNumber) {
    final activeUnitTerms = _termsForActiveGradeUnit(unitNumber);
    if (activeUnitTerms.isNotEmpty) return activeUnitTerms.first.unitTitle;

    final anyUnitTerms = termsForUnit(unitNumber);
    if (anyUnitTerms.isNotEmpty) return anyUnitTerms.first.unitTitle;

    return 'Hiligaynon';
  }

  static List<LessonTerm> _termsForLocalLesson(int level) {
    final unitTerms = _termsForActiveGradeUnit(unitForLevel(level));
    if (unitTerms.isEmpty) return const [];
    final localLevel = (level - 1) % AppData.unitLevels;
    final explicitTerms = unitTerms
        .where((term) => term.lessonNumber == localLevel + 1)
        .toList();
    final laterLessonFallback = unitTerms
        .where((term) => term.lessonNumber == null || term.lessonNumber != 1)
        .toList();
    final localTerms = explicitTerms.isEmpty
        ? (localLevel == 0 || laterLessonFallback.isEmpty
              ? unitTerms
              : laterLessonFallback)
        : unitTerms
              .where(
                (term) =>
                    term.lessonNumber == null ||
                    term.lessonNumber == localLevel + 1,
              )
              .toList();

    // Each grade file owns the content pool. Levels rotate through that pool
    // so the unit stays grade-appropriate.
    final selected = <LessonTerm>[...explicitTerms];
    final start = (localLevel * 4).clamp(0, localTerms.length - 1);
    for (var offset = 0; offset < localTerms.length; offset++) {
      final term = localTerms[(start + offset) % localTerms.length];
      if (selected.any((item) => item.hil == term.hil)) continue;
      selected.add(term);
      if (selected.length >= math.min(12, localTerms.length)) break;
    }
    return selected;
  }

  static List<LessonTerm> _termsForUnitLessonScope(int level) {
    final localLesson = ((level - 1) % AppData.unitLevels) + 1;
    final unitTerms = _termsForActiveGradeUnit(unitForLevel(level));
    final scoped = unitTerms.where((term) {
      return term.lessonNumber == null || term.lessonNumber == localLesson;
    }).toList();
    if (scoped.isEmpty) {
      final laterLessonFallback = unitTerms
          .where((term) => term.lessonNumber == null || term.lessonNumber != 1)
          .toList();
      return localLesson == 1 || laterLessonFallback.isEmpty
          ? unitTerms
          : laterLessonFallback;
    }
    return scoped;
  }

  static LessonQuestion _missingWordQuestion(
    int level,
    List<LessonTerm> unitTerms,
    math.Random rng, {
    List<LessonTerm> unitFallbackTerms = const [],
    bool preferScenario = true,
  }) {
    var templates = preferScenario
        ? _assetBackedMissingTerms(unitTerms)
        : _plainMissingTerms(unitTerms);
    if (templates.isEmpty && unitFallbackTerms.isNotEmpty) {
      // Complete-the-sentence should remain image-backed. If the current local
      // level has no scenario asset, reuse the scenario asset from the same
      // unit, such as Unit 1 Level 1's complete-sentence picture.
      templates = preferScenario
          ? _assetBackedMissingTerms(unitFallbackTerms)
          : _plainMissingTerms(unitFallbackTerms);
    }
    if (templates.isEmpty && !preferScenario) {
      templates = _assetBackedMissingTerms(unitTerms);
    }
    if (templates.isEmpty && !preferScenario && unitFallbackTerms.isNotEmpty) {
      templates = _assetBackedMissingTerms(unitFallbackTerms);
    }
    if (!preferScenario &&
        templates.length == 1 &&
        !_isScenarioMissingTerm(templates.first)) {
      final term = unitTerms[level % unitTerms.length];
      return _generatedFillBlankQuestion(term, unitTerms, rng);
    }
    if (templates.isEmpty) {
      final plainTemplates = _uniqueTerms([
        ..._plainMissingTerms(unitTerms),
        ..._plainMissingTerms(unitFallbackTerms),
      ]);
      if (plainTemplates.isNotEmpty &&
          (plainTemplates.length > 1 || preferScenario)) {
        final term = plainTemplates[(level - 1) % plainTemplates.length];
        return _fillBlankQuestion(term, unitTerms, rng);
      }
      if (plainTemplates.length == 1 && !preferScenario) {
        final term = unitTerms[level % unitTerms.length];
        return _generatedFillBlankQuestion(term, unitTerms, rng);
      }
      final term = unitTerms.firstWhere(
        (term) => term.missingSentence != null && term.missingAnswer != null,
        orElse: () => unitTerms[level % unitTerms.length],
      );
      if (term.missingSentence != null && term.missingAnswer != null) {
        return _fillBlankQuestion(term, unitTerms, rng);
      }
      return _generatedFillBlankQuestion(term, unitTerms, rng);
    }
    final term = templates[(level - 1) % templates.length];
    return _fillBlankQuestion(term, unitTerms, rng);
  }

  static LessonQuestion _fillBlankQuestion(
    LessonTerm term,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    return LessonQuestion.fillBlank(
      prompt: 'Complete the sentence "${term.missingSentence}"',
      answer: term.missingAnswer!,
      choices: term.choices.isEmpty
          ? _missingChoices(term, unitTerms, rng)
          : term.choices,
      imagePath: term.imagePath ?? '',
      sentenceMeaning: term.eng,
      wordMeanings: term.wordMeanings,
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static LessonQuestion _generatedFillBlankQuestion(
    LessonTerm term,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    return LessonQuestion.fillBlank(
      prompt: 'Complete the sentence "${term.hil} ___"',
      answer: term.eng,
      choices: _optionsFor(
        answer: term.eng,
        values: unitTerms.map((term) => term.eng).toList(),
        fallbackValues: unitTerms.map((term) => term.eng).toList(),
        rng: rng,
      ),
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static List<LessonTerm> _assetBackedMissingTerms(List<LessonTerm> source) {
    return source.where(_isScenarioMissingTerm).toList();
  }

  static List<LessonTerm> _plainMissingTerms(List<LessonTerm> source) {
    return source
        .where(
          (term) =>
              term.missingSentence != null &&
              term.missingAnswer != null &&
              !_isScenarioMissingTerm(term),
        )
        .toList();
  }

  static List<LessonTerm> _uniqueTerms(List<LessonTerm> source) {
    final seen = <String>{};
    final unique = <LessonTerm>[];
    for (final term in source) {
      final key = _conceptKey(term);
      if (seen.add(key)) unique.add(term);
    }
    return unique;
  }

  static List<LessonTerm> _nonScenarioTerms(List<LessonTerm> source) {
    final terms = source
        .where((term) => !_isScenarioMissingTerm(term))
        .toList();
    return terms.isEmpty ? source : terms;
  }

  static bool _isScenarioMissingTerm(LessonTerm term) {
    return term.missingSentence != null &&
        term.missingAnswer != null &&
        term.imagePath != null &&
        term.imagePath!.contains('/complete_the_sentence/');
  }

  static LessonQuestion _translationChoiceQuestion({
    required LessonTerm term,
    required bool englishToHiligaynon,
    required List<LessonTerm> pool,
    required math.Random rng,
  }) {
    if (englishToHiligaynon) {
      return LessonQuestion.translationChoice(
        prompt: 'Translate: "${term.eng}"',
        answer: term.hil,
        choices: _optionsFor(
          answer: term.hil,
          values: pool.map((term) => term.hil).toList(),
          fallbackValues: pool.map((term) => term.hil).toList(),
          rng: rng,
        ),
        targetPhrase: term.eng,
        targetMeaning: term.hil,
        directionLabel: 'English to Hiligaynon',
      );
    }

    return LessonQuestion.translationChoice(
      prompt: 'Translate: "${term.hil}"',
      answer: term.eng,
      choices: _optionsFor(
        answer: term.eng,
        values: pool.map((term) => term.eng).toList(),
        fallbackValues: pool.map((term) => term.eng).toList(),
        rng: rng,
      ),
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static LessonQuestion _matchingQuestion(
    List<LessonTerm> source,
    List<LessonTerm> unitTerms,
    int seed,
  ) {
    // Matching pair activities stay word-based. The first pool keeps the
    // current lesson slice on-theme, and the second pool fills with other
    // word-like terms from the same unit if needed.
    final sourceWords = _matchingTerms(source);
    final unitWords = _matchingTerms(unitTerms);
    final selected = _takeUniqueTerms(sourceWords, 4, seed);
    for (
      var offset = 0;
      selected.length < 4 && offset < unitWords.length;
      offset++
    ) {
      final candidate = unitWords[(seed + offset) % unitWords.length];
      if (!selected.any((term) => term.hil == candidate.hil)) {
        selected.add(candidate);
      }
    }
    final globalWords = _matchingTerms(
      terms.where((term) => term.lessonNumber != 1).toList(),
    );
    for (
      var offset = 0;
      selected.length < 4 && offset < globalWords.length;
      offset++
    ) {
      final candidate = globalWords[(seed + offset) % globalWords.length];
      if (!selected.any((term) => term.hil == candidate.hil)) {
        selected.add(candidate);
      }
    }
    final rightItems = selected.map((term) => term.eng).toList()
      ..shuffle(math.Random(seed));
    return LessonQuestion.matching(
      prompt: 'Match each Hiligaynon word to English.',
      leftItems: selected.map((term) => term.hil).toList(),
      rightItems: rightItems,
    );
  }

  static LessonQuestion _arrangeWordsQuestion(
    int level,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    final practiceTerms = _nonScenarioTerms(unitTerms);
    final sentences = practiceTerms.where(_isSentenceTerm).toList();
    final source = sentences.isEmpty ? unitTerms : sentences;
    final term = source[(level - 1) % source.length];
    final answerWords = _words(term.hil);
    final configuredBlocks = term.wordBlocks.where((word) {
      return word.trim().isNotEmpty;
    });
    final distractors =
        practiceTerms
            .expand((term) => _words(term.hil))
            .where((word) => !answerWords.contains(word))
            .toSet()
            .toList()
          ..shuffle(rng);
    final blocks = <String>[
      ...(configuredBlocks.isEmpty ? answerWords : configuredBlocks),
      ...distractors.take(3),
    ]..shuffle(rng);
    return LessonQuestion.arrangeWords(
      prompt: 'Arrange the words to say: "${term.eng}"',
      answer: term.hil,
      sentenceWords: blocks,
      targetPhrase: term.eng,
      targetMeaning: term.hil,
      directionLabel: 'English to Hiligaynon',
    );
  }

  static LessonQuestion? _imageChoiceQuestion(
    List<LessonTerm> unitTerms,
    math.Random rng, {
    int seed = 0,
    String? avoidAnswer,
    bool allowGlobalFallback = false,
  }) {
    var imageTerms = unitTerms.where(_isImageChoiceTerm).toList();
    var imageSeed = seed;
    if (imageTerms.length < 4 && allowGlobalFallback) {
      final unitOffset = unitTerms.isEmpty ? 0 : unitTerms.first.unitNumber;
      imageSeed += unitOffset;
      imageTerms = terms
          .where(_isImageChoiceTerm)
          .where((term) => term.lessonNumber != 1)
          .toList();
    }
    imageTerms = _sameImageFolderTerms(imageTerms, imageSeed);
    if (imageTerms.length < 4) return null;
    imageTerms.shuffle(rng);
    final selected = _takeUniqueTerms(imageTerms, 4, imageSeed);
    final fallbackAnswer = selected[imageSeed.abs() % selected.length];
    final answer = avoidAnswer == null
        ? fallbackAnswer
        : selected.firstWhere(
            (term) => term.hil != avoidAnswer,
            orElse: () => fallbackAnswer,
          );
    return LessonQuestion.imageChoice(
      prompt: 'Which of these is "${answer.eng}"?',
      answer: answer.hil,
      imageChoices: selected..shuffle(rng),
      targetPhrase: answer.hil,
      targetMeaning: answer.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static List<LessonQuestion> _completeFlexibleQuestionSet(
    List<LessonQuestion> questions, {
    required int level,
    required List<LessonTerm> levelTerms,
    required List<LessonTerm> unitTerms,
    required List<LessonTerm> scenarioTerms,
    required List<LessonTerm> scenarioUnitTerms,
    required math.Random rng,
  }) {
    const targets = {
      QuestionType.translationChoice: 3,
      QuestionType.arrangeWords: 2,
      QuestionType.matching: 1,
      QuestionType.fillBlank: 2,
      QuestionType.imageChoice: 2,
    };
    final completed = <LessonQuestion>[];
    final seen = <String>{};
    final counts = <QuestionType, int>{};

    void addIfNeeded(LessonQuestion? question, {bool respectTargets = true}) {
      if (question == null) return;
      if (respectTargets) {
        final target = targets[question.type];
        if (target == null) return;
        if ((counts[question.type] ?? 0) >= target) return;
      }
      final key = _questionKey(question);
      if (!seen.add(key)) return;
      completed.add(question);
      counts[question.type] = (counts[question.type] ?? 0) + 1;
    }

    for (final question in questions) {
      addIfNeeded(question);
    }

    LessonQuestion? candidateFor(QuestionType type, int cursor) {
      final term = levelTerms[cursor % levelTerms.length];
      return switch (type) {
        QuestionType.translationChoice => _translationChoiceQuestion(
          term: term,
          englishToHiligaynon: cursor.isEven,
          pool: levelTerms,
          rng: rng,
        ),
        QuestionType.arrangeWords => _arrangeWordsQuestion(
          level + cursor,
          levelTerms,
          rng,
        ),
        QuestionType.matching => _matchingQuestion(
          levelTerms,
          unitTerms,
          level + cursor,
        ),
        QuestionType.fillBlank =>
          cursor < scenarioUnitTerms.length
              ? _missingWordQuestion(
                  level + cursor,
                  scenarioUnitTerms,
                  rng,
                  unitFallbackTerms: scenarioUnitTerms,
                  preferScenario: cursor.isEven,
                )
              : _generatedFillBlankQuestion(
                  scenarioUnitTerms[(level + cursor) %
                      scenarioUnitTerms.length],
                  scenarioUnitTerms,
                  rng,
                ),
        QuestionType.imageChoice => _imageChoiceQuestion(
          unitTerms,
          rng,
          seed: level + cursor,
          allowGlobalFallback: true,
        ),
        _ => null,
      };
    }

    for (final entry in targets.entries) {
      var cursor = 0;
      while ((counts[entry.key] ?? 0) < entry.value && cursor < 180) {
        addIfNeeded(candidateFor(entry.key, cursor));
        cursor++;
      }
    }

    const fallbackTypes = [
      QuestionType.translationChoice,
      QuestionType.arrangeWords,
      QuestionType.matching,
      QuestionType.fillBlank,
    ];
    var cursor = 0;
    while (completed.length < AppData.questionsPerUnit && cursor < 240) {
      final type = fallbackTypes[cursor % fallbackTypes.length];
      addIfNeeded(candidateFor(type, cursor), respectTargets: false);
      cursor++;
    }

    return completed.take(AppData.questionsPerUnit).toList();
  }

  static String _questionKey(LessonQuestion question) {
    return [
      question.type.name,
      question.prompt.trim().toLowerCase(),
      question.answer.trim().toLowerCase(),
      question.leftItems.join('|').toLowerCase(),
      question.imageChoices.map((term) => term.hil).join('|').toLowerCase(),
    ].join('::');
  }

  static GradeLessonDataset get _activeGradeDataset {
    return gradeDatasets[AppData.selectedGradeLevel] ?? grade1LessonDataset;
  }

  static String _applyGradeTemplate(
    String template, {
    required String unitTitle,
    required String focusWords,
  }) {
    return template
        .replaceAll('{unitTitle}', unitTitle)
        .replaceAll('{focusWords}', focusWords);
  }

  static String _joinQuoted(List<String> values) {
    final cleaned = values.where((value) => value.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return 'from this lesson';
    if (cleaned.length == 1) return '"${cleaned.first}"';
    if (cleaned.length == 2) {
      return '"${cleaned.first}" and "${cleaned.last}"';
    }
    final head = cleaned.take(cleaned.length - 1).map((value) => '"$value"');
    return '${head.join(', ')}, and "${cleaned.last}"';
  }

  static bool _isImageChoiceTerm(LessonTerm term) {
    final imagePath = term.imagePath;
    if (imagePath == null || imagePath.isEmpty) return false;
    // Keep image-choice questions to the approved visual vocabulary folders.
    // Scenario images under "complete the sentence" belong exclusively to
    // fill-blank activities.
    return imagePath.contains('/image_choice/') ||
        imagePath.contains('/animal/') ||
        imagePath.contains('/fruits/') ||
        imagePath.contains('/action/');
  }

  static List<LessonTerm> _sameImageFolderTerms(
    List<LessonTerm> imageTerms,
    int seed,
  ) {
    final grouped = <String, List<LessonTerm>>{};
    for (final term in imageTerms) {
      grouped.putIfAbsent(_imageFolderKey(term), () => []).add(term);
    }
    final groups = grouped.values.where((group) => group.length >= 4).toList();
    if (groups.isEmpty) return const [];
    groups.sort(
      (a, b) => _imageFolderKey(a.first).compareTo(_imageFolderKey(b.first)),
    );
    return groups[seed.abs() % groups.length];
  }

  static String _imageFolderKey(LessonTerm term) {
    final path = term.imagePath ?? '';
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return path;
    return path.substring(0, lastSlash);
  }

  static List<String> _missingChoices(
    LessonTerm term,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    final choices = <String>{term.missingAnswer!};
    final unitWords =
        unitTerms
            .expand((term) => _words(term.hil))
            .where((word) => !word.contains('?'))
            .toList()
          ..shuffle(rng);
    for (final word in unitWords) {
      if (choices.length >= 4) break;
      choices.add(word);
    }
    return choices.toList()..shuffle(rng);
  }

  static List<String> _optionsFor({
    required String answer,
    required List<String> values,
    required List<String> fallbackValues,
    required math.Random rng,
  }) {
    // Wrong choices prefer the current unit so lessons stay on-theme. Fallback
    // values are used only when there are not enough unique same-unit choices.
    final options = <String>{answer};
    final sameUnit = values.where((value) => value != answer).toList()
      ..shuffle(rng);
    for (final value in sameUnit) {
      if (options.length >= 4) break;
      options.add(value);
    }
    final fallback = fallbackValues.where((value) => value != answer).toList()
      ..shuffle(rng);
    for (final value in fallback) {
      if (options.length >= 4) break;
      options.add(value);
    }
    return options.toList()..shuffle(rng);
  }

  static List<LessonTerm> _takeUniqueTerms(
    List<LessonTerm> pool,
    int count,
    int seed,
  ) {
    final selected = <LessonTerm>[];
    var index = seed;
    while (selected.length < count && index < seed + pool.length * 2) {
      final term = pool[index % pool.length];
      if (!selected.any((item) => item.hil == term.hil)) selected.add(term);
      index++;
    }
    return selected;
  }

  static bool _isSentenceTerm(LessonTerm term) {
    final type = term.type;
    if (type != null) return type == LessonContentType.sentence;
    return term.hil.contains(' ') && term.eng.contains(' ');
  }

  static List<LessonTerm> _matchingTerms(List<LessonTerm> pool) {
    final words = pool.where(_isMatchingWordTerm).toList();
    if (words.length >= 4) return words;

    final phraseFallback = pool.where((term) {
      return !_isScenarioMissingTerm(term) &&
          term.imagePath == null &&
          !term.hil.contains('?') &&
          !term.eng.contains('?') &&
          term.hil.split(RegExp(r'\s+')).length <= 4 &&
          term.eng.split(RegExp(r'\s+')).length <= 4;
    });
    return _uniqueTerms([...words, ...phraseFallback]);
  }

  static bool _isMatchingWordTerm(LessonTerm term) {
    // Match tiles should be simple vocabulary cards such as Lakat, Kadto, or
    // Hambal. Multi-word phrases and questions belong in translation exercises.
    final type = term.type;
    if (type != null) return type == LessonContentType.word;
    return !term.hil.trim().contains(' ') &&
        !term.hil.contains('?') &&
        !term.eng.trim().contains(' ') &&
        !term.eng.contains('?');
  }

  static List<String> _words(String value) {
    return value
        .replaceAll(RegExp(r'[.!?"]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static String _conceptKey(LessonTerm term) {
    return '${term.unitNumber}|${term.hil.toLowerCase()}|${term.eng.toLowerCase()}';
  }
}
