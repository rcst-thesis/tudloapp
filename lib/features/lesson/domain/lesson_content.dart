import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';

/// The small, neutral slice of DevG's lesson dataset the Tudlo session needs.
/// Activity-specific source screens can grow behind this interface without
/// coupling Home, Map, or learner persistence to their presentation details.
class LessonContent {
  const LessonContent({
    required this.id,
    required this.title,
    required this.lessonText,
    required this.story,
    required this.examples,
    required this.questions,
  });

  final String id;
  final String title;
  final String lessonText;
  final String? story;
  final List<LessonExample> examples;
  final List<LessonQuestion> questions;
}

class LessonExample {
  const LessonExample({
    required this.hiligaynon,
    this.english,
    this.imageAsset,
    this.audioAsset,
  });

  final String hiligaynon;
  final String? english;
  final String? imageAsset;
  final String? audioAsset;
}

class LessonQuestion {
  const LessonQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.choices,
    required this.answer,
    this.imageAsset,
    this.audioAsset,
  });

  final String id;
  final String type;
  final String question;
  final List<String> choices;
  final String answer;
  final String? imageAsset;
  final String? audioAsset;
}

/// Loads the authorized DevG curriculum dataset once. It is intentionally
/// data-only: no DevG AppData, audio service, or persistence code comes
/// across this boundary.
class LessonContentRepository {
  const LessonContentRepository._();

  static const _assetPath = 'assets/data/tudlo_updated_lesson_dataset.json';
  static Future<Map<String, LessonContent>>? _cache;

  static Future<LessonContent> load(LessonDefinition definition) async {
    final all = await (_cache ??= _loadAll());
    return all[definition.id] ??
        LessonContent(
          id: definition.id,
          title: definition.title,
          lessonText: definition.title,
          story: null,
          examples: const [],
          questions: const [],
        );
  }

  static Future<Map<String, LessonContent>> _loadAll() async {
    final decoded = jsonDecode(await rootBundle.loadString(_assetPath));
    if (decoded is! Map) return const {};
    final result = <String, LessonContent>{};
    final grades = decoded['grades'];
    if (grades is! List) return result;
    for (final grade in grades) {
      if (grade is! Map) continue;
      final units = grade['units'];
      if (units is! List) continue;
      for (final unit in units) {
        if (unit is! Map) continue;
        final lessons = unit['lessons'];
        if (lessons is! List) continue;
        for (final rawLesson in lessons) {
          if (rawLesson is! Map) continue;
          final lesson = Map<String, Object?>.from(rawLesson);
          final id = lesson['id'] as String?;
          if (id == null || id.isEmpty) continue;
          result[id] = LessonContent(
            id: id,
            title: lesson['title'] as String? ?? id,
            lessonText: lesson['lesson'] as String? ?? '',
            story: lesson['story'] as String?,
            examples: _examples(lesson['examples']),
            questions: _questions(lesson['shortQuiz']),
          );
        }
      }
    }
    return result;
  }

  static List<LessonExample> _examples(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) {
          final value = Map<String, Object?>.from(entry);
          return LessonExample(
            hiligaynon: value['hiligaynon'] as String? ?? '',
            english: value['english'] as String?,
            imageAsset: value['imageAsset'] as String?,
            audioAsset: value['audioAsset'] as String?,
          );
        })
        .toList(growable: false);
  }

  static List<LessonQuestion> _questions(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .expand((entry) {
          final value = Map<String, Object?>.from(entry);
          final question = LessonQuestion(
            id: value['id'] as String? ?? '',
            type: value['type'] as String? ?? 'tapChoice',
            question: value['question'] as String? ?? '',
            choices: (value['choices'] as List<Object?>? ?? const [])
                .whereType<String>()
                .toList(growable: false),
            answer: value['answer'] as String? ?? '',
            imageAsset: value['imageAsset'] as String?,
            audioAsset: value['audioAsset'] as String?,
          );
          if (question.choices.isNotEmpty) return [question];
          if (question.type != 'activity') return const <LessonQuestion>[];

          final expanded = _activityQuestions(
            id: question.id,
            raw: value['raw'] as String? ?? '',
          );
          // A source activity without structured choices still gets one
          // explicit ready interaction. It follows the ordinary
          // reward-claim persistence boundary; no DevG scheduler is revived.
          return expanded.isEmpty
              ? [
                  LessonQuestion(
                    id: question.id,
                    type: 'activity',
                    question: question.question,
                    choices: const ['Handa na ako'],
                    answer: 'Handa na ako',
                  ),
                ]
              : expanded;
        })
        .toList(growable: false);
  }

  /// Converts story-style source activities with prompt/choices embedded in
  /// prose into ordinary tappable questions. The extracted answers remain
  /// source data; the only adapter is their neutral Tudlo presentation.
  static List<LessonQuestion> _activityQuestions({
    required String id,
    required String raw,
  }) {
    final pattern = RegExp(
      r'→\s*tap\s+([^\(\n]+?)\s*\(choices:\s*([^\)]+)\)',
      caseSensitive: false,
      multiLine: true,
    );
    final questions = <LessonQuestion>[];
    for (final match in pattern.allMatches(raw)) {
      final answer = match.group(1)?.trim();
      final choiceText = match.group(2);
      if (answer == null || answer.isEmpty || choiceText == null) continue;
      final choices = choiceText
          .split('/')
          .map((choice) => choice.trim())
          .where((choice) => choice.isNotEmpty)
          .toList(growable: false);
      if (choices.isEmpty) continue;
      final answerIndex = choices.indexWhere(
        (choice) => choice.toLowerCase() == answer.toLowerCase(),
      );
      if (answerIndex < 0) continue;
      questions.add(
        LessonQuestion(
          id: '$id-${questions.length + 1}',
          type: 'tapChoice',
          question: 'Pili-a ang husto nga sabat.',
          choices: choices,
          answer: choices[answerIndex],
        ),
      );
    }
    return questions;
  }
}
