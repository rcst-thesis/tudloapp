class LessonActivityScore {
  final String activityId;
  final int attempts;
  final int mistakes;
  final bool correctOnFirstTry;
  final int completionTimeMs;

  const LessonActivityScore({
    required this.activityId,
    required this.attempts,
    required this.mistakes,
    required this.correctOnFirstTry,
    required this.completionTimeMs,
  });

  factory LessonActivityScore.fromJson(Map<String, dynamic> json) {
    return LessonActivityScore(
      activityId: json['activityId'] as String? ?? '',
      attempts: json['attempts'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      correctOnFirstTry: json['correctOnFirstTry'] as bool? ?? false,
      completionTimeMs: json['completionTimeMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'attempts': attempts,
      'mistakes': mistakes,
      'correctOnFirstTry': correctOnFirstTry,
      'completionTimeMs': completionTimeMs,
    };
  }
}

class LessonScoreStats {
  final String lessonId;
  final int totalActivities;
  final int attempts;
  final int correctAnswers;
  final int mistakes;
  final int accuracy;
  final int bestAccuracy;
  final int replayCount;
  final int timeTakenMs;
  final DateTime? completionDate;
  final bool completed;
  final List<LessonActivityScore> activities;

  const LessonScoreStats({
    required this.lessonId,
    required this.totalActivities,
    required this.attempts,
    required this.correctAnswers,
    required this.mistakes,
    required this.accuracy,
    required this.bestAccuracy,
    required this.replayCount,
    required this.timeTakenMs,
    required this.completionDate,
    required this.completed,
    required this.activities,
  });

  factory LessonScoreStats.fromJson(Map<String, dynamic> json) {
    final completionDateValue = json['completionDate'] as String?;
    return LessonScoreStats(
      lessonId: json['lessonId'] as String? ?? '',
      totalActivities: json['totalActivities'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      bestAccuracy: json['bestAccuracy'] as int? ?? 0,
      replayCount: json['replayCount'] as int? ?? 0,
      timeTakenMs: json['timeTakenMs'] as int? ?? 0,
      completionDate: completionDateValue == null
          ? null
          : DateTime.tryParse(completionDateValue),
      completed: json['completed'] as bool? ?? false,
      activities: [
        for (final value in (json['activities'] as List<dynamic>? ?? []))
          if (value is Map<String, dynamic>)
            LessonActivityScore.fromJson(value),
      ],
    );
  }

  LessonScoreStats mergeBestFrom(LessonScoreStats? previous) {
    if (previous == null) return this;
    return copyWith(
      bestAccuracy: accuracy > previous.bestAccuracy
          ? accuracy
          : previous.bestAccuracy,
      replayCount: previous.completed ? previous.replayCount + 1 : 0,
    );
  }

  LessonScoreStats copyWith({int? bestAccuracy, int? replayCount}) {
    return LessonScoreStats(
      lessonId: lessonId,
      totalActivities: totalActivities,
      attempts: attempts,
      correctAnswers: correctAnswers,
      mistakes: mistakes,
      accuracy: accuracy,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      replayCount: replayCount ?? this.replayCount,
      timeTakenMs: timeTakenMs,
      completionDate: completionDate,
      completed: completed,
      activities: activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'totalActivities': totalActivities,
      'attempts': attempts,
      'correctAnswers': correctAnswers,
      'mistakes': mistakes,
      'accuracy': accuracy,
      'bestAccuracy': bestAccuracy,
      'replayCount': replayCount,
      'timeTakenMs': timeTakenMs,
      'completionDate': completionDate?.toIso8601String(),
      'completed': completed,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }
}
