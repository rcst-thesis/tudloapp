import 'package:flutter/foundation.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/learner_profile.dart';
import 'package:tudloapp/features/energy/services/energy_storage.dart';

/// Shared in-app progress and energy state.
///
/// Energy is the only mechanic that gates lesson access.
class AppData {
  /// Helper overlay flags prevent one-time tips from showing repeatedly.
  static bool translateHelpDone = false;
  static bool mapHelpDone = false;

  static int get maxLevel => units.last.endLevel;

  /// Duolingo-style energy rules.
  ///
  /// A full unit/lesson has 10 questions, so starting requires 10 energy and
  /// each checked question deducts 1 energy.
  static const int maxEnergy = 30;
  static const int energyPerQuestion = 1;
  static const int questionsPerUnit = 10;
  static const int minimumEnergyToStartUnit = 10;
  static const Duration rechargeInterval = Duration(minutes: 24);
  static const Duration fullRechargeTime = Duration(hours: 12);

  /// Notifies energy widgets after recharge, spend, or restore.
  static final ValueNotifier<int> energyRevision = ValueNotifier<int>(0);

  /// Current saved energy. Use [refreshEnergy] before reading in UI flows that
  /// care about real elapsed time.
  static int currentEnergy = maxEnergy;
  static DateTime _lastEnergyAt = DateTime.now();

  static int streakDays = 0;
  static int unlockedLevel = 1;
  static GradeLevel selectedGradeLevel = GradeLevel.grade1;
  static final Map<int, int> levelStars = {};
  static final Set<int> completedLevels = {};

  /// Home Map unit definitions shared by the Map and Profile screens.
  ///
  /// These titles mirror `assets/data/tudlo_updated_lesson_dataset.json`.
  static List<AppUnit> get units => _unitsByGrade[selectedGradeLevel]!;

  static const Map<GradeLevel, List<AppUnit>> _unitsByGrade = {
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

  /// Loads energy from storage, then immediately applies real-time recharge.
  /// This is called before runApp so all screens see restored energy.
  static Future<void> initialize() async {
    final values = await EnergyStorage.read();
    currentEnergy =
        int.tryParse(
          values['currentEnergy'] ?? '',
        )?.clamp(0, maxEnergy).toInt() ??
        maxEnergy;
    _lastEnergyAt =
        DateTime.tryParse(values['lastEnergyAt'] ?? '') ?? DateTime.now();
    await refreshEnergy(save: true);
  }

  static void applyProfile(LearnerProfile profile) {
    streakDays = profile.streakDays;
    unlockedLevel = profile.unlockedLevel.clamp(1, maxLevel);
    selectedGradeLevel = profile.parsedGrade;
    currentEnergy = profile.currentEnergy.clamp(0, maxEnergy).toInt();
    _lastEnergyAt = DateTime.now();
    levelStars
      ..clear()
      ..addAll(profile.levelStars);
    completedLevels
      ..clear()
      ..addAll(profile.completedLevels);
    energyRevision.value++;
  }

  static LearnerProfile snapshotForProfile(LearnerProfile profile) {
    return profile.copyWith(
      unlockedLevel: unlockedLevel,
      streakDays: streakDays,
      currentEnergy: currentEnergy,
      levelStars: Map<int, int>.from(levelStars),
      completedLevels: Set<int>.from(completedLevels),
    );
  }

  static void clearLearningProgress() {
    streakDays = 0;
    unlockedLevel = 1;
    currentEnergy = maxEnergy;
    _lastEnergyAt = DateTime.now();
    levelStars.clear();
    completedLevels.clear();
    energyRevision.value++;
  }

  /// Recharges energy based on elapsed real time.
  ///
  /// The saved timestamp marks the last recharge boundary. If the app was
  /// closed for 72 minutes, this adds 3 energy because 72 / 24 = 3 intervals.
  static Future<void> refreshEnergy({DateTime? now, bool save = false}) async {
    final updatedAt = now ?? DateTime.now();
    final changed = _applyRecharge(updatedAt);
    if (save) await saveEnergyState();
    if (changed) energyRevision.value++;
  }

  static bool _applyRecharge(DateTime updatedAt) {
    if (currentEnergy >= maxEnergy) {
      currentEnergy = maxEnergy;
      _lastEnergyAt = updatedAt;
      return true;
    }

    final intervals =
        updatedAt.difference(_lastEnergyAt).inMinutes ~/
        rechargeInterval.inMinutes;
    if (intervals <= 0) return false;

    currentEnergy = (currentEnergy + intervals).clamp(0, maxEnergy).toInt();
    _lastEnergyAt = currentEnergy >= maxEnergy
        ? updatedAt
        : _lastEnergyAt.add(
            Duration(minutes: rechargeInterval.inMinutes * intervals),
          );
    return true;
  }

  /// Persists the current energy count and timestamp used for restore logic.
  static Future<void> saveEnergyState() {
    return EnergyStorage.write({
      'currentEnergy': '$currentEnergy',
      'lastEnergyAt': _lastEnergyAt.toIso8601String(),
    });
  }

  /// Unit start restriction. Home Map calls this before opening a lesson.
  static bool canStartUnit() {
    return currentEnergy >= minimumEnergyToStartUnit;
  }

  /// Deducts energy when a question is checked.
  ///
  /// This is intentionally separate from correctness. Trying a question costs
  /// energy once, whether the answer is right or wrong.
  static Future<bool> spendQuestionEnergy() async {
    await refreshEnergy();
    if (currentEnergy < energyPerQuestion) return false;
    currentEnergy = (currentEnergy - energyPerQuestion)
        .clamp(0, maxEnergy)
        .toInt();
    _lastEnergyAt = DateTime.now();
    await saveEnergyState();
    energyRevision.value++;
    return true;
  }

  static Duration timeUntilNextEnergy({DateTime? now}) {
    final updatedAt = now ?? DateTime.now();
    _applyRecharge(updatedAt);
    if (currentEnergy >= maxEnergy) return Duration.zero;
    final elapsed = updatedAt.difference(_lastEnergyAt);
    final remaining = rechargeInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Duration timeUntilFullEnergy({DateTime? now}) {
    _applyRecharge(now ?? DateTime.now());
    if (currentEnergy >= maxEnergy) return Duration.zero;
    final missing = maxEnergy - currentEnergy;
    return timeUntilNextEnergy(now: now) +
        Duration(minutes: rechargeInterval.inMinutes * (missing - 1));
  }

  static String formatDurationShort(Duration duration) {
    if (duration <= Duration.zero) return 'now';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static bool isUnitStartLevel(int level) {
    return units.any((unit) => unit.startLevel == level);
  }

  static bool isLevelUnlocked(int level) {
    if (level < 1 || level > maxLevel) return false;
    if (isUnitStartLevel(level)) return true;
    if (completedLevels.contains(level)) return true;
    final previousLevel = level - 1;
    final sameUnit = unitForLevel(previousLevel) == unitForLevel(level);
    return sameUnit && completedLevels.contains(previousLevel);
  }

  static int starsForLevel(int level) {
    return levelStars[level] ?? 0;
  }

  static AppUnit unitForNumber(int number) {
    return units.firstWhere((unit) => unit.number == number);
  }

  static AppUnit unitForLevel(int level) => units.firstWhere(
    (unit) => level >= unit.startLevel && level <= unit.endLevel,
  );

  static int lessonNumberForLevel(int level) {
    final unit = unitForLevel(level);
    return level - unit.startLevel + 1;
  }

  /// Converts a lesson score into 0-3 stars and keeps the best result.
  static void saveLevelScore(int level, int score, int total) {
    completedLevels.add(level);
    final percent = total == 0 ? 0.0 : score / total;
    final stars = percent >= .9
        ? 3
        : percent >= .7
        ? 2
        : percent >= .4
        ? 1
        : 0;
    final previous = levelStars[level] ?? 0;
    if (stars > previous) {
      levelStars[level] = stars;
    }
  }
}

class AppUnit {
  final int number;
  final int startLevel;
  final int lessonCount;
  final String title;

  const AppUnit({
    required this.number,
    required this.startLevel,
    required this.lessonCount,
    required this.title,
  });

  int get endLevel => startLevel + lessonCount - 1;
}
