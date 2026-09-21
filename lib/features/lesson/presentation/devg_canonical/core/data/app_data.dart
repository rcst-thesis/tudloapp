import 'package:flutter/foundation.dart';

import 'package:tudloapp/features/lesson/presentation/devg_canonical/core/models/grade_level.dart';
import 'package:tudloapp/features/lesson/presentation/devg_canonical/core/models/lesson_score.dart';

/// Compatibility facade for code copied from DevG lesson screens.
///
/// It contains only ephemeral presentation state. Tudlo's learner controller
/// remains the only persistent source of lesson, map, reward, and energy data.
class AppData {
  static const maxEnergy = 100;
  static const minimumEnergyToStartUnit = 10;
  static final energyRevision = ValueNotifier<int>(0);

  static bool developerMode = false;
  static bool mapHelpDone = true;
  static int currentEnergy = maxEnergy;
  static int streakDays = 0;
  static GradeLevel selectedGradeLevel = GradeLevel.grade1;
  static int? activeLessonLevel;
  static int? lessonDashboardFocusLevel;
  static int unlockedLevel = 1;
  static final levelStars = <int, int>{};
  static final lessonStickers = <int, String>{};
  static final lessonScores = <String, LessonScoreStats>{};
  static final completedLevels = <int>{};
  static Set<int> _unlockedLevels = {1};
  static Set<int> _catalogLevels = {1};

  static List<AppUnit> get units => _units[selectedGradeLevel]!;
  static int get maxLevel => units.last.endLevel;
  static int get completedLevelCount => completedLevels.length;
  static int get catalogLevelCount => _catalogLevels.length;

  /// Units with one or more cards allowed in the current Tudlo entry point.
  /// The original dashboard can therefore remain visually intact while a
  /// real-map location shows only its own production lessons.
  static List<AppUnit> get catalogUnits =>
      units.where((unit) => catalogLevelsForUnit(unit).isNotEmpty).toList();

  /// Synchronizes source visual state from the active Tudlo learner profile.
  /// No value supplied here is written by this class.
  static void configure({
    required int grade,
    required int energy,
    required Iterable<int> unlockedLevels,
    required Iterable<int> completed,
    required Map<int, String> stickers,
    required Iterable<int> catalogLevels,
  }) {
    selectedGradeLevel = switch (grade) {
      2 => GradeLevel.grade2,
      3 => GradeLevel.grade3,
      _ => GradeLevel.grade1,
    };
    currentEnergy = energy.clamp(10, maxEnergy).toInt();
    _unlockedLevels = {...unlockedLevels};
    _catalogLevels = {
      for (final level in catalogLevels)
        if (isProductionLessonAvailable(level)) level,
    };
    completedLevels
      ..clear()
      ..addAll(completed);
    levelStars
      ..clear()
      ..addEntries(completedLevels.map((level) => MapEntry(level, 1)));
    lessonStickers
      ..clear()
      ..addAll(stickers);
    unlockedLevel = firstUnlockedIncompleteLevel;
    energyRevision.value++;
  }

  static bool isCatalogLevel(int level) => _catalogLevels.contains(level);

  static List<int> catalogLevelsForUnit(AppUnit unit) => [
    for (var level = unit.startLevel; level <= unit.endLevel; level++)
      if (isCatalogLevel(level)) level,
  ];

  /// Chooses a sensible first card for a filtered catalogue. Prefer an active
  /// incomplete card, then any card so a child can see locked future lessons.
  static int get firstCatalogLevel {
    for (final unit in catalogUnits) {
      for (final level in catalogLevelsForUnit(unit)) {
        if (isLevelUnlocked(level) && !completedLevels.contains(level)) {
          return level;
        }
      }
    }
    for (final unit in catalogUnits) {
      final levels = catalogLevelsForUnit(unit);
      if (levels.isNotEmpty) return levels.first;
    }
    return 1;
  }

  /// Tudlo displays its existing 10–100 energy but never spends or recharges
  /// it on lesson start/checks. These methods keep source call sites harmless.
  static Future<void> refreshEnergy({DateTime? now, bool save = false}) async {}
  static Future<bool> spendLessonEnergy() async => true;
  static Future<bool> spendQuestionEnergy() async => true;
  static Duration timeUntilNextEnergy({DateTime? now}) => Duration.zero;
  static Duration timeUntilFullEnergy({DateTime? now}) => Duration.zero;
  static String formatDurationShort(Duration duration) => 'now';

  static bool recordLessonStreakForToday({DateTime? now}) => false;

  static bool isProductionLessonAvailable(int level) {
    if (level < 1 || level > maxLevel) return false;
    final unit = unitForLevel(level);
    final lesson = lessonNumberForLevel(level);
    return switch ((selectedGradeLevel, unit.number, lesson)) {
      (GradeLevel.grade1, 1, 1) ||
      (GradeLevel.grade1, 1, 7) ||
      (GradeLevel.grade1, 2, 1) ||
      (GradeLevel.grade1, 2, 4) ||
      (GradeLevel.grade2, 1, 1) ||
      (GradeLevel.grade2, 1, 2) ||
      (GradeLevel.grade2, 2, 1) ||
      (GradeLevel.grade2, 2, 2) ||
      (GradeLevel.grade3, 1, 1) ||
      (GradeLevel.grade3, 1, 3) ||
      (GradeLevel.grade3, 2, 1) ||
      (GradeLevel.grade3, 2, 2) => true,
      _ => false,
    };
  }

  static bool isLevelUnlocked(int level) =>
      isProductionLessonAvailable(level) &&
      (developerMode || _unlockedLevels.contains(level));

  static int get firstUnlockedIncompleteLevel {
    for (var level = 1; level <= maxLevel; level++) {
      if (isLevelUnlocked(level) && !completedLevels.contains(level)) {
        return level;
      }
    }
    return _unlockedLevels.isEmpty ? 1 : _unlockedLevels.first;
  }

  static AppUnit unitForNumber(int number) =>
      units.firstWhere((unit) => unit.number == number);
  static AppUnit unitForLevel(int level) => units.firstWhere(
    (unit) => level >= unit.startLevel && level <= unit.endLevel,
  );
  static int lessonNumberForLevel(int level) =>
      level - unitForLevel(level).startLevel + 1;
  static String lessonIdForLevel(int level) =>
      '${unitForLevel(level).number}-${lessonNumberForLevel(level)}';

  /// Holds the source visual score only. The host converts this final score to
  /// a Tudlo [LessonCompletion] when the learner claims the reward.
  static void saveLevelScore(int level, LessonScoreStats stats) {
    completedLevels.add(level);
    lessonScores[lessonIdForLevel(level)] = stats.mergeBestFrom(
      lessonScores[lessonIdForLevel(level)],
    );
  }

  static const _units = <GradeLevel, List<AppUnit>>{
    GradeLevel.grade1: [
      AppUnit(
        number: 1,
        startLevel: 1,
        lessonCount: 9,
        title: 'ALPHABETO KAG NUMERO',
      ),
      AppUnit(
        number: 2,
        startLevel: 10,
        lessonCount: 4,
        title: 'MIYEMBRO SANG PAMILYA',
      ),
      AppUnit(
        number: 3,
        startLevel: 14,
        lessonCount: 4,
        title: 'MGA COMMUNITY',
      ),
      AppUnit(
        number: 4,
        startLevel: 18,
        lessonCount: 4,
        title: 'MGA SAPAT SA PALIBOT',
      ),
      AppUnit(
        number: 5,
        startLevel: 22,
        lessonCount: 4,
        title: 'MGA LUGAR SA PALIBOT',
      ),
    ],
    GradeLevel.grade2: [
      AppUnit(number: 1, startLevel: 1, lessonCount: 3, title: 'PAGPAKILALA'),
      AppUnit(
        number: 2,
        startLevel: 4,
        lessonCount: 3,
        title: 'GREETINGS AND POLITE',
      ),
      AppUnit(number: 3, startLevel: 7, lessonCount: 3, title: 'PANGALAN'),
      AppUnit(
        number: 4,
        startLevel: 10,
        lessonCount: 3,
        title: 'SONGS AND RIDDLES',
      ),
      AppUnit(number: 5, startLevel: 13, lessonCount: 3, title: 'POEMS'),
    ],
    GradeLevel.grade3: [
      AppUnit(number: 1, startLevel: 1, lessonCount: 3, title: 'NUMBERS'),
      AppUnit(number: 2, startLevel: 4, lessonCount: 3, title: 'STORIES'),
      AppUnit(number: 3, startLevel: 7, lessonCount: 3, title: 'FABLES'),
      AppUnit(
        number: 4,
        startLevel: 10,
        lessonCount: 3,
        title: 'STORY DETECTIVES',
      ),
      AppUnit(number: 5, startLevel: 13, lessonCount: 3, title: 'WORD POWER'),
    ],
  };
}

class AppUnit {
  const AppUnit({
    required this.number,
    required this.startLevel,
    required this.lessonCount,
    required this.title,
  });

  final int number;
  final int startLevel;
  final int lessonCount;
  final String title;
  int get endLevel => startLevel + lessonCount - 1;
}
