import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';

/// Converts stable Tudlo lesson IDs to DevG's per-grade dashboard positions.
/// These numbers are an adapter detail only; they are never persisted.
class DevGLessonMapping {
  const DevGLessonMapping._();

  static int sourceLevelFor(LessonDefinition lesson) =>
      switch ((lesson.grade, lesson.unit, lesson.lesson)) {
        (1, 1, final sourceLesson) => sourceLesson,
        (1, 2, final sourceLesson) => 9 + sourceLesson,
        (2, 1, final sourceLesson) => sourceLesson,
        (2, 2, final sourceLesson) => 3 + sourceLesson,
        (3, 1, final sourceLesson) => sourceLesson,
        (3, 2, final sourceLesson) => 3 + sourceLesson,
        _ => throw ArgumentError.value(
          lesson.id,
          'lesson',
          'Unsupported DevG flow',
        ),
      };

  static LessonDefinition? definitionFor({
    required int grade,
    required int sourceLevel,
  }) {
    for (final lesson in LessonCatalog.forGrade(grade)) {
      if (sourceLevelFor(lesson) == sourceLevel) return lesson;
    }
    return null;
  }
}
