import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

// Run with: flutter test scripts/export_lessons.dart
void main() => test('export lesson data to JSON assets', exportLessons);

void exportLessons() {
  final output = Directory(
    Platform.environment['LESSON_OUTPUT_DIR'] ?? 'assets/data',
  );
  output.createSync(recursive: true);

  for (final grade in GradeLevel.values) {
    AppData.selectedGradeLevel = grade;
    final lessons = [
      for (
        var level = 1;
        level <= AppData.units.length * AppData.unitLevels;
        level++
      )
        LessonBank.levelContentForLevel(level),
    ];
    final data = {
      'datasetName': '${grade.label} Lesson Dataset',
      'version': 1,
      'grades': [
        {
          'gradeLevel': grade.number,
          'units': [
            for (final unit in AppData.units)
              {
                'unitNumber': unit.number,
                'title': unit.title,
                'lessons': lessons
                    .where((lesson) => lesson.unitNumber == unit.number)
                    .map(_lessonToJson)
                    .toList(),
              },
          ],
        },
      ],
    };
    final file = File('${output.path}/grade${grade.number}_dataset.json');
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
    );
    _validate(file, grade.number, AppData.units.length);
    stdout.writeln('Wrote ${file.path} (${lessons.length} lessons)');
  }
}

Map<String, Object?> _lessonToJson(LevelContent lesson) => {
  'id': lesson.id,
  'gradeLevel': lesson.gradeLevel,
  'unitNumber': lesson.unitNumber,
  'lessonNumber': lesson.lessonNumber,
  'title': lesson.title,
  'storyTitle': lesson.storyTitle,
  'story': lesson.story,
  'storyImageAsset': lesson.storyImageAsset,
  'lesson': lesson.lesson,
  'examples': [
    for (final example in lesson.examples)
      {
        'category': example.category,
        'hiligaynon': example.hiligaynon,
        'english': example.english,
        'note': example.note,
        'imageAsset': example.imageAsset,
        'audioAsset': example.audioAsset,
      },
  ],
  'shortQuiz': [
    for (final quiz in lesson.quizItems)
      {
        'id': quiz.id,
        'type': quiz.type.name,
        'question': quiz.question,
        'choices': quiz.choices,
        'answer': quiz.answer,
        'audioAsset': quiz.audioAsset,
        'imageAsset': quiz.imageAsset,
        'leftItems': quiz.leftItems,
        'rightItems': quiz.rightItems,
        'pairs': quiz.matchingPairs,
      },
  ],
};

void _validate(File file, int grade, int expectedUnits) {
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final grades = decoded['grades'] as List<dynamic>;
  final gradeData = grades.single as Map<String, dynamic>;
  final units = gradeData['units'] as List<dynamic>;
  final lessonCount = units.fold<int>(
    0,
    (count, unit) =>
        count + ((unit as Map<String, dynamic>)['lessons'] as List).length,
  );
  if (gradeData['gradeLevel'] != grade ||
      units.length != expectedUnits ||
      lessonCount != expectedUnits * AppData.unitLevels) {
    throw FormatException('Invalid generated lesson data in ${file.path}.');
  }
}
