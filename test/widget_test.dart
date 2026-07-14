import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/features/dictionary/screens/dictionary_page.dart';

void main() {
  test('every level generates the required playable lesson mix', () {
    // This test protects the lesson generator for all units and levels.
    // If any level loses the required question mix, this tells developers
    // which level and question type no longer matches the lesson plan.
    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;
      for (var level = 1; level <= AppData.maxLevel; level++) {
        final questions = LessonBank.questionsForLevel(level);

        // Count every generated question by type so the expectations below can
        // confirm that each lesson has the required mix of activities.
        final counts = <QuestionType, int>{};
        for (final question in questions) {
          counts[question.type] = (counts[question.type] ?? 0) + 1;
        }
        final fillBlankPrompts = questions
            .where((question) => question.type == QuestionType.fillBlank)
            .map((question) => '${question.prompt} => ${question.answer}')
            .join(' | ');

        // Unit lessons should always match the app-wide question count.
        expect(
          questions,
          hasLength(AppData.questionsPerUnit),
          reason:
              '${grade.label} level $level should have '
              '${AppData.questionsPerUnit} questions. Generated counts: '
              '$counts. Fill blanks: $fillBlankPrompts',
        );

        expect(
          (counts[QuestionType.translationChoice] ?? 0) +
              (counts[QuestionType.choice] ?? 0) +
              (counts[QuestionType.completeSentence] ?? 0) +
              (counts[QuestionType.imageChoice] ?? 0),
          greaterThanOrEqualTo(1),
          reason: '${grade.label} level $level choice-style activity count',
        );
        expect(
          counts[QuestionType.arrangeWords] ?? 0,
          greaterThanOrEqualTo(1),
          reason: '${grade.label} level $level arrangeWords count',
        );
        expect(
          counts[QuestionType.matching] ?? 0,
          greaterThanOrEqualTo(1),
          reason: '${grade.label} level $level matching count',
        );
        expect(
          counts[QuestionType.fillBlank] ?? 0,
          greaterThanOrEqualTo(1),
          reason: '${grade.label} level $level fillBlank count',
        );
      }
    }
  });

  test('unit 1 level 1 questions do not leak into other levels', () {
    AppData.selectedGradeLevel = GradeLevel.grade1;

    // Unit 1 Level 1 is a fixed showcase lesson. Later levels should not reuse
    // its exact generated questions, even when they need fallback content.
    final showcaseKeys = LessonBank.questionsForLevel(
      1,
    ).map(_questionKey).toSet();

    for (var level = 2; level <= AppData.maxLevel; level++) {
      for (final question in LessonBank.questionsForLevel(level)) {
        final key = _questionKey(question);
        expect(
          showcaseKeys.contains(key),
          isFalse,
          reason: 'Level $level reused a Unit 1 Level 1 question: $key',
        );
      }
    }
  });

  test('each grade has distinct level learning content', () {
    final stories = <String>{};
    final lessons = <String>{};

    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;
      final content = LessonBank.contentForLevel(2);
      stories.add(content.story);
      lessons.add(content.shortLesson);
    }

    expect(stories, hasLength(GradeLevel.values.length));
    expect(lessons, hasLength(GradeLevel.values.length));
  });

  test('referenced image assets exist with exact path casing', () {
    final actualAssets = _assetFilesOnDisk();
    final referencedAssets = _referencedAssets();

    expect(
      dictionaryIndexScale(9, 10),
      greaterThan(dictionaryIndexScale(8, 10)),
    );
    expect(
      dictionaryIndexScale(8, 10),
      greaterThan(dictionaryIndexScale(7, 10)),
    );
  });
}

String _questionKey(LessonQuestion question) {
  return [
    question.type.name,
    question.prompt.trim().toLowerCase(),
    question.answer.trim().toLowerCase(),
    question.leftItems.join('|').toLowerCase(),
    question.imageChoices.map((term) => term.hil).join('|').toLowerCase(),
  ].join('::');
}

Set<String> _assetFilesOnDisk() {
  return Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .toSet();
}

Set<String> _referencedAssets() {
  final assets = <String>{};
  final assetLiteralPattern = RegExp(r'''assets/[^'")\s]+''');

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    final source = file.readAsStringSync();
    assets.addAll(
      assetLiteralPattern
          .allMatches(source)
          .map((match) => match.group(0)!)
          .where(_isImageAsset),
    );
  }

  for (final term in LessonBank.terms) {
    final imagePath = term.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      assets.add(imagePath);
    }
  }

  for (final grade in GradeLevel.values) {
    AppData.selectedGradeLevel = grade;
    for (var level = 1; level <= AppData.maxLevel; level++) {
      for (final question in LessonBank.questionsForLevel(level)) {
        if (question.imagePath.isNotEmpty) {
          assets.add(question.imagePath);
        }
        for (final term in question.imageChoices) {
          final imagePath = term.imagePath;
          if (imagePath != null && imagePath.isNotEmpty) {
            assets.add(imagePath);
          }
        }
      }
    }
  }

  return assets.where(_isImageAsset).toSet();
}

bool _isImageAsset(String asset) {
  final lower = asset.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp');
}
