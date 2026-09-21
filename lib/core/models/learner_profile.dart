import 'dart:convert';

import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/lesson_score.dart';

class LearnerProfile {
  final String id;
  final String name;
  final String gradeLevel;
  final int unlockedLevel;
  final int streakDays;
  final String? lastDailyStreakDate;
  final int currentEnergy;
  final Map<int, int> levelStars;
  final Map<String, LessonScoreStats> lessonScores;
  final Set<int> completedLevels;
  final Set<String> favoriteWords;
  final String avatarAsset;
  final bool hasSeenOnboarding;
  final bool mapHelpDone;

  const LearnerProfile({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.unlockedLevel,
    required this.streakDays,
    required this.lastDailyStreakDate,
    required this.currentEnergy,
    required this.levelStars,
    required this.lessonScores,
    required this.completedLevels,
    required this.favoriteWords,
    required this.avatarAsset,
    required this.hasSeenOnboarding,
    required this.mapHelpDone,
  });

  factory LearnerProfile.newProfile({
    required String name,
    required String gradeLevel,
  }) {
    return LearnerProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Learner' : name.trim(),
      gradeLevel: gradeLevel,
      unlockedLevel: 1,
      streakDays: 0,
      lastDailyStreakDate: null,
      currentEnergy: AppData.maxEnergy,
      levelStars: const {},
      lessonScores: const {},
      completedLevels: const {},
      favoriteWords: const {},
      avatarAsset: '',
      hasSeenOnboarding: false,
      mapHelpDone: false,
    );
  }

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Learner',
      gradeLevel: json['gradeLevel'] as String? ?? 'Grade 1',
      unlockedLevel: json['unlockedLevel'] as int? ?? 1,
      streakDays: json['streakDays'] as int? ?? 0,
      lastDailyStreakDate: json['lastDailyStreakDate'] as String?,
      currentEnergy: json['currentEnergy'] as int? ?? AppData.maxEnergy,
      levelStars: _intMap(json['levelStars']),
      lessonScores: _lessonScoreMap(json['lessonScores']),
      completedLevels: {
        for (final value in (json['completedLevels'] as List<dynamic>? ?? []))
          if (value is int) value,
      },
      favoriteWords: {
        for (final value in (json['favoriteWords'] as List<dynamic>? ?? []))
          if (value is String) value,
      },
      avatarAsset: json['avatarAsset'] as String? ?? '',
      hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? true,
      mapHelpDone: json['mapHelpDone'] as bool? ?? true,
    );
  }

  LearnerProfile copyWith({
    String? name,
    String? gradeLevel,
    int? unlockedLevel,
    int? streakDays,
    Object? lastDailyStreakDate = _unchanged,
    int? currentEnergy,
    Map<int, int>? levelStars,
    Map<String, LessonScoreStats>? lessonScores,
    Set<int>? completedLevels,
    Set<String>? favoriteWords,
    String? avatarAsset,
    bool? hasSeenOnboarding,
    bool? mapHelpDone,
  }) {
    return LearnerProfile(
      id: id,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      streakDays: streakDays ?? this.streakDays,
      lastDailyStreakDate: identical(lastDailyStreakDate, _unchanged)
          ? this.lastDailyStreakDate
          : lastDailyStreakDate as String?,
      currentEnergy: currentEnergy ?? this.currentEnergy,
      levelStars: levelStars ?? this.levelStars,
      lessonScores: lessonScores ?? this.lessonScores,
      completedLevels: completedLevels ?? this.completedLevels,
      favoriteWords: favoriteWords ?? this.favoriteWords,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      mapHelpDone: mapHelpDone ?? this.mapHelpDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gradeLevel': gradeLevel,
      'unlockedLevel': unlockedLevel,
      'streakDays': streakDays,
      'lastDailyStreakDate': lastDailyStreakDate,
      'currentEnergy': currentEnergy,
      'levelStars': {
        for (final entry in levelStars.entries) '${entry.key}': entry.value,
      },
      'lessonScores': {
        for (final entry in lessonScores.entries)
          entry.key: entry.value.toJson(),
      },
      'completedLevels': completedLevels.toList()..sort(),
      'favoriteWords': favoriteWords.toList()..sort(),
      'avatarAsset': avatarAsset,
      'hasSeenOnboarding': hasSeenOnboarding,
      'mapHelpDone': mapHelpDone,
    };
  }

  String get summary => '$name - $gradeLevel - Level $unlockedLevel';
  GradeLevel get parsedGrade => gradeLevelFromLabel(gradeLevel);

  static Map<int, int> _intMap(dynamic value) {
    final source = value is Map ? value : const {};
    return {
      for (final entry in source.entries)
        if (int.tryParse('${entry.key}') != null && entry.value is int)
          int.parse('${entry.key}'): entry.value as int,
    };
  }

  static Map<String, LessonScoreStats> _lessonScoreMap(dynamic value) {
    final source = value is Map ? value : const {};
    return {
      for (final entry in source.entries)
        if (entry.value is Map<String, dynamic>)
          '${entry.key}': LessonScoreStats.fromJson(entry.value),
    };
  }
}

const Object _unchanged = Object();

String encodeProfiles(List<LearnerProfile> profiles, String? activeProfileId) {
  return jsonEncode({
    'activeProfileId': activeProfileId,
    'profiles': profiles.map((profile) => profile.toJson()).toList(),
  });
}

({List<LearnerProfile> profiles, String? activeProfileId}) decodeProfiles(
  String value,
) {
  if (value.trim().isEmpty) return (profiles: const [], activeProfileId: null);
  final data = jsonDecode(value) as Map<String, dynamic>;
  final profiles = (data['profiles'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(LearnerProfile.fromJson)
      .toList();
  return (
    profiles: profiles,
    activeProfileId: data['activeProfileId'] as String?,
  );
}
