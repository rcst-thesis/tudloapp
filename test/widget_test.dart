import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every level loads playable JSON content', () async {
    for (final grade in GradeLevel.values) {
      AppData.selectedGradeLevel = grade;
      final contents = await LessonBank.loadAllLevelContentForActiveGrade();

      expect(contents, hasLength(AppData.maxLevel));
      for (var index = 0; index < contents.length; index++) {
        final content = contents[index];
        final level = index + 1;
        expect(content.gradeLevel, grade.number);
        expect(content.unitNumber, LessonBank.unitForLevel(level));
        expect(content.lessonNumber, ((level - 1) % AppData.unitLevels) + 1);
        expect(content.quizItems, isNotEmpty);
      }
    }
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
