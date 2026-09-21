/// One stored result for a lesson. It represents a completed and claimed
/// reward only: abandoned sessions are deliberately never written here.
class LessonCompletion {
  const LessonCompletion({
    required this.lessonId,
    required this.score,
    required this.accuracy,
    required this.mistakes,
    required this.duration,
    required this.completedAt,
    required this.rewardAsset,
  });

  final String lessonId;
  final int score;
  final double accuracy;
  final int mistakes;
  final Duration duration;
  final DateTime completedAt;
  final String rewardAsset;

  Map<String, Object?> toJson() => {
    'lessonId': lessonId,
    'score': score,
    'accuracy': accuracy,
    'mistakes': mistakes,
    'durationMs': duration.inMilliseconds,
    'completedAt': completedAt.toIso8601String(),
    'rewardAsset': rewardAsset,
  };

  factory LessonCompletion.fromJson(Map<String, Object?> json) {
    return LessonCompletion(
      lessonId: json['lessonId'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      mistakes: (json['mistakes'] as num?)?.toInt() ?? 0,
      duration: Duration(
        milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
      ),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      rewardAsset: json['rewardAsset'] as String? ?? '',
    );
  }
}

/// Versioned, per-learner lesson progression.
///
/// `initialized == false` distinguishes legacy saves from a learner who has
/// genuinely finished every lesson in the selected grade. The first startup
/// with a legacy save seeds that learner's first active lesson.
class LessonProgress {
  const LessonProgress({
    required this.version,
    required this.initialized,
    required this.completions,
    this.activeLessonId,
    this.lastFirstCompletionDate,
  });

  const LessonProgress.uninitialized()
    : version = 1,
      initialized = false,
      completions = const {},
      activeLessonId = null,
      lastFirstCompletionDate = null;

  static const currentVersion = 1;

  final int version;
  final bool initialized;
  final String? activeLessonId;
  final Map<String, LessonCompletion> completions;
  final DateTime? lastFirstCompletionDate;

  bool isComplete(String lessonId) => completions.containsKey(lessonId);

  LessonProgress copyWith({
    int? version,
    bool? initialized,
    String? activeLessonId,
    bool clearActiveLesson = false,
    Map<String, LessonCompletion>? completions,
    DateTime? lastFirstCompletionDate,
  }) {
    return LessonProgress(
      version: version ?? this.version,
      initialized: initialized ?? this.initialized,
      activeLessonId: clearActiveLesson
          ? null
          : activeLessonId ?? this.activeLessonId,
      completions: completions ?? this.completions,
      lastFirstCompletionDate:
          lastFirstCompletionDate ?? this.lastFirstCompletionDate,
    );
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'initialized': initialized,
    'activeLessonId': activeLessonId,
    'completions': completions.map(
      (id, completion) => MapEntry(id, completion.toJson()),
    ),
    'lastFirstCompletionDate': lastFirstCompletionDate?.toIso8601String(),
  };

  factory LessonProgress.fromJson(Object? raw) {
    if (raw is! Map) return const LessonProgress.uninitialized();
    final json = Map<String, Object?>.from(raw);
    final rawCompletions = json['completions'];
    final completions = <String, LessonCompletion>{};
    if (rawCompletions is Map) {
      for (final entry in rawCompletions.entries) {
        if (entry.key is! String || entry.value is! Map) continue;
        try {
          final completion = LessonCompletion.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
          if (completion.lessonId.isNotEmpty) {
            completions[entry.key as String] = completion;
          }
        } catch (_) {
          // A malformed one-off result must not stop the rest of this
          // learner profile from loading.
        }
      }
    }
    return LessonProgress(
      version: (json['version'] as num?)?.toInt() ?? currentVersion,
      initialized: json['initialized'] as bool? ?? false,
      activeLessonId: json['activeLessonId'] as String?,
      completions: Map.unmodifiable(completions),
      lastFirstCompletionDate: DateTime.tryParse(
        json['lastFirstCompletionDate'] as String? ?? '',
      ),
    );
  }
}
