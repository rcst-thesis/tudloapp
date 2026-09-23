import 'dart:ui';

/// Data passed from Home's learner/progress layer into the visual lesson deck.
class HomeLessonPreview {
  const HomeLessonPreview({
    required this.unitTitle,
    required this.category,
    required this.status,
    this.lessonId,
    this.unitNumber = 1,
  });

  final String unitTitle;
  final String category;
  final HomeLessonStatus status;
  final String? lessonId;

  /// Which unit this lesson belongs to -- picks the right category icon
  /// (each unit has its own). Defaults to 1 for callers that don't track it.
  final int unitNumber;
}

/// Visual state only. The actual unlock decision remains LessonProgress-owned.
enum HomeLessonStatus { completed, available, locked }

typedef HomeLessonTapCallback =
    Future<void> Function(HomeLessonPreview lesson, Rect originRect);
