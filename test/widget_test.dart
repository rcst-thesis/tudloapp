import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/features/dictionary/screens/dictionary_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every level loads playable JSON content', () async {
    const expectedCounts = {1: 25, 2: 15, 3: 15};
    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;
      final contents = await LessonBank.loadAllLevelContentForActiveGrade();

      expect(contents, hasLength(expectedCounts[grade.number]));
      expect(
        contents.map((content) => content.id).toSet(),
        hasLength(contents.length),
      );
      for (var index = 0; index < contents.length; index++) {
        final content = contents[index];
        final level = index + 1;
        expect(content.gradeLevel, grade.number);
        expect(content.unitNumber, LessonBank.unitForLevel(level));
        expect(content.lessonNumber, AppData.lessonNumberForLevel(level));
        expect(content.quizItems, isNotEmpty);
        expect(
          content.quizItems.every((quiz) => quiz.choices.isNotEmpty),
          isTrue,
        );
        expect(
          content.quizItems.every((quiz) => quiz.answer.isNotEmpty),
          isTrue,
        );
      }
    }
  });

  test('dictionary loads the formatted JSON asset', () async {
    await DictionaryData.initialize();

    expect(DictionaryData.entries, hasLength(963));
    expect(DictionaryData.meaningFor('abogado'), contains('lawyer'));
  });

  test('dictionary index follows the section nearest the top', () {
    expect(
      activeDictionarySection(const [
        MapEntry('A', 80),
        MapEntry('B', 180),
        MapEntry('C', 280),
      ]),
      'B',
    );
  });

  test('dictionary index scale tapers symmetrically', () {
    expect(dictionaryIndexScale(10, 10), 1.55);
    expect(dictionaryIndexScale(9, 10), dictionaryIndexScale(11, 10));
    expect(
      dictionaryIndexScale(9, 10),
      greaterThan(dictionaryIndexScale(8, 10)),
    );
    expect(
      dictionaryIndexScale(8, 10),
      greaterThan(dictionaryIndexScale(7, 10)),
    );
  });

  test('referenced image assets exist with exact path casing', () async {
    final actualAssets = Directory('assets')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .toSet();
    final referencedAssets = <String>{};

    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;
      for (final content
          in await LessonBank.loadAllLevelContentForActiveGrade()) {
        if (content.storyImageAsset case final path?) {
          referencedAssets.add(path);
        }
        for (final example in content.examples) {
          if (example.imageAsset case final path?) referencedAssets.add(path);
        }
        for (final quiz in content.quizItems) {
          if (quiz.imageAsset case final path?) referencedAssets.add(path);
        }
      }
    }

    expect(
      referencedAssets.where((asset) => !actualAssets.contains(asset)),
      isEmpty,
    );
  });
}
