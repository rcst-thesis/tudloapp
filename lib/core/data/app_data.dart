import 'package:flutter/foundation.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/learner_profile.dart';
import 'package:tudloapp/core/models/lesson_score.dart';
import 'package:tudloapp/core/services/app_storage.dart';
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
  static String? lastDailyStreakDate;
  static int unlockedLevel = 1;
  static bool developerMode = false;
  static int dailyWordDemoOffset = 0;
  static final ValueNotifier<bool> profanityFilterEnabledNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<bool> dictionaryFallbackEnabledNotifier =
      ValueNotifier<bool>(true);
  static bool get profanityFilterEnabled =>
      profanityFilterEnabledNotifier.value;
  static bool get dictionaryFallbackEnabled =>
      dictionaryFallbackEnabledNotifier.value;
  static GradeLevel selectedGradeLevel = GradeLevel.grade1;
  static int? activeLessonLevel;
  static int? lessonDashboardFocusLevel;
  static final Map<int, int> levelStars = {};
  static final Map<int, String> lessonStickers = {};
  static final Map<String, LessonScoreStats> lessonScores = {};
  static final Set<int> completedLevels = {};

  /// Home Map unit definitions shared by the Map and Profile screens.
  ///
  /// These titles mirror the current grade lesson dataset structure.
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
    final devValues = await AppStorage.readDeveloperSettings();
    developerMode = devValues['developerMode'] == true;
    dailyWordDemoOffset = (devValues['dailyWordDemoOffset'] as int?) ?? 0;
    final translationValues = await AppStorage.readTranslationSettings();
    profanityFilterEnabledNotifier.value =
        translationValues['profanityFilterEnabled'] ?? true;
    dictionaryFallbackEnabledNotifier.value =
        translationValues['dictionaryFallbackEnabled'] ?? true;

    final values = await EnergyStorage.read();
    currentEnergy =
        int.tryParse(
          values['currentEnergy'] ?? '',
        )?.clamp(0, maxEnergy).toInt() ??
        maxEnergy;
    _lastEnergyAt =
        DateTime.tryParse(values['lastEnergyAt'] ?? '') ?? DateTime.now();
    if (developerMode) currentEnergy = maxEnergy;
    await refreshEnergy(save: true);
  }

  static Future<void> setDeveloperMode(bool enabled) async {
    developerMode = enabled;
    if (developerMode) currentEnergy = maxEnergy;
    await AppStorage.writeDeveloperSettings(
      developerMode: developerMode,
      dailyWordDemoOffset: dailyWordDemoOffset,
    );
    await saveEnergyState();
    energyRevision.value++;
  }

  static Future<void> setDailyWordDemoOffset(int offset) async {
    dailyWordDemoOffset = offset;
    await AppStorage.writeDeveloperSettings(
      developerMode: developerMode,
      dailyWordDemoOffset: dailyWordDemoOffset,
    );
    energyRevision.value++;
  }

  static Future<void> setProfanityFilterEnabled(bool enabled) async {
    profanityFilterEnabledNotifier.value = enabled;
    await _saveTranslationSettings();
  }

  static Future<void> setDictionaryFallbackEnabled(bool enabled) async {
    dictionaryFallbackEnabledNotifier.value = enabled;
    await _saveTranslationSettings();
  }

  static Future<void> _saveTranslationSettings() {
    return AppStorage.writeTranslationSettings(
      profanityFilterEnabled: profanityFilterEnabled,
      dictionaryFallbackEnabled: dictionaryFallbackEnabled,
    );
  }

  static DateTime dailyWordNow() {
    return DateTime.now().add(Duration(days: dailyWordDemoOffset));
  }

  static String dateKeyFor(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Whether a Tudlo lesson host is driving this session.
  ///
  /// The DevG lesson screens call these statics directly. When Tudlo hosts
  /// them, it owns progress and energy itself, so the writes below become
  /// no-ops and the unlock/catalogue state is projected from the active
  /// learner profile through [configureHostedSession] instead.
  static bool hostedSession = false;
  static Set<int> _hostedUnlockedLevels = {1};
  static Set<int> _hostedCatalogLevels = {1};

  /// Projects the active Tudlo learner profile onto the statics the DevG
  /// screens read. No value supplied here is written back by this class.
  static void configureHostedSession({
    required int grade,
    required int energy,
    required Iterable<int> unlockedLevels,
    required Iterable<int> completed,
    required Map<int, String> stickers,
    required Iterable<int> catalogLevels,
  }) {
    hostedSession = true;
    selectedGradeLevel = GradeLevel.values.firstWhere(
      (value) => value.number == grade,
      orElse: () => GradeLevel.grade1,
    );
    currentEnergy = energy.clamp(0, maxEnergy).toInt();
    _hostedUnlockedLevels = unlockedLevels.toSet();
    _hostedCatalogLevels = catalogLevels.toSet();
    completedLevels
      ..clear()
      ..addAll(completed);
    lessonStickers
      ..clear()
      ..addAll(stickers);
    unlockedLevel = _hostedUnlockedLevels.isEmpty
        ? 1
        : _hostedUnlockedLevels.reduce((a, b) => a > b ? a : b);
  }

  /// Hands progress and energy back to the app when a lesson host goes away.
  ///
  /// Without this the writes above stay suppressed for the rest of the
  /// process, so the app's own energy would never recharge again after the
  /// first hosted lesson.
  static void endHostedSession() {
    hostedSession = false;
    _hostedUnlockedLevels = {1};
    _hostedCatalogLevels = {1};
  }

  /// Units holding at least one card the current entry point allows, so the
  /// DevG dashboard stays visually intact while a map location shows only
  /// its own lessons.
  static List<AppUnit> get catalogUnits => hostedSession
      ? units.where((unit) => catalogLevelsForUnit(unit).isNotEmpty).toList()
      : units;

  static int get catalogLevelCount =>
      hostedSession ? _hostedCatalogLevels.length : maxLevel;

  static bool isCatalogLevel(int level) =>
      !hostedSession || _hostedCatalogLevels.contains(level);

  static List<int> catalogLevelsForUnit(AppUnit unit) => [
    for (var level = unit.startLevel; level <= unit.endLevel; level++)
      if (isCatalogLevel(level)) level,
  ];

  /// A sensible first card for a filtered catalogue: an active incomplete
  /// card when there is one, otherwise any card, so a child can still see
  /// locked future lessons.
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

  static bool recordLessonStreakForToday({DateTime? now}) {
    if (hostedSession) return false;
    final today = dateKeyFor(now ?? DateTime.now());
    if (lastDailyStreakDate == today) return false;
    streakDays = streakDays <= 0 ? 1 : streakDays + 1;
    lastDailyStreakDate = today;
    return true;
  }

  static void applyProfile(LearnerProfile profile) {
    streakDays = profile.streakDays;
    lastDailyStreakDate = profile.lastDailyStreakDate;
    selectedGradeLevel = profile.parsedGrade;
    lessonDashboardFocusLevel = null;
    mapHelpDone = profile.mapHelpDone;
    unlockedLevel = profile.unlockedLevel.clamp(1, maxLevel);
    currentEnergy = profile.currentEnergy.clamp(0, maxEnergy).toInt();
    _lastEnergyAt = DateTime.now();
    levelStars
      ..clear()
      ..addAll(profile.levelStars);
    lessonStickers
      ..clear()
      ..addAll(profile.lessonStickers);
    lessonScores
      ..clear()
      ..addAll(profile.lessonScores);
    completedLevels
      ..clear()
      ..addAll(profile.completedLevels);
    energyRevision.value++;
  }

  static LearnerProfile snapshotForProfile(LearnerProfile profile) {
    return profile.copyWith(
      unlockedLevel: unlockedLevel,
      streakDays: streakDays,
      lastDailyStreakDate: lastDailyStreakDate,
      currentEnergy: currentEnergy,
      levelStars: Map<int, int>.from(levelStars),
      lessonStickers: Map<int, String>.from(lessonStickers),
      lessonScores: Map<String, LessonScoreStats>.from(lessonScores),
      completedLevels: Set<int>.from(completedLevels),
      mapHelpDone: mapHelpDone,
    );
  }

  static void clearLearningProgress() {
    streakDays = 0;
    lastDailyStreakDate = null;
    unlockedLevel = 1;
    lessonDashboardFocusLevel = null;
    currentEnergy = maxEnergy;
    _lastEnergyAt = DateTime.now();
    levelStars.clear();
    lessonStickers.clear();
    lessonScores.clear();
    completedLevels.clear();
    mapHelpDone = false;
    energyRevision.value++;
  }

  /// Recharges energy based on elapsed real time.
  ///
  /// The saved timestamp marks the last recharge boundary. If the app was
  /// closed for 72 minutes, this adds 3 energy because 72 / 24 = 3 intervals.
  static Future<void> refreshEnergy({DateTime? now, bool save = false}) async {
    if (hostedSession) return;
    if (developerMode) {
      final changed = currentEnergy != maxEnergy;
      currentEnergy = maxEnergy;
      _lastEnergyAt = now ?? DateTime.now();
      if (save) await saveEnergyState();
      if (changed) energyRevision.value++;
      return;
    }
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
    if (developerMode) return true;
    return currentEnergy >= minimumEnergyToStartUnit;
  }

  /// Deducts the fixed lesson-start cost. Individual quiz attempts do not
  /// spend energy, so one lesson always costs exactly 10 energy.
  static Future<bool> spendLessonEnergy() async {
    if (hostedSession) return true;
    await refreshEnergy();
    if (developerMode) return true;
    if (currentEnergy < minimumEnergyToStartUnit) return false;
    currentEnergy = (currentEnergy - minimumEnergyToStartUnit)
        .clamp(0, maxEnergy)
        .toInt();
    _lastEnergyAt = DateTime.now();
    await saveEnergyState();
    energyRevision.value++;
    return true;
  }

  /// Deducts energy when a question is checked.
  ///
  /// Kept for existing quiz call sites, but the current rule spends energy
  /// once when the lesson starts instead of per question.
  static Future<bool> spendQuestionEnergy() async {
    await refreshEnergy();
    return true;
  }

  static Duration timeUntilNextEnergy({DateTime? now}) {
    if (hostedSession) return Duration.zero;
    final updatedAt = now ?? DateTime.now();
    _applyRecharge(updatedAt);
    if (currentEnergy >= maxEnergy) return Duration.zero;
    final elapsed = updatedAt.difference(_lastEnergyAt);
    final remaining = rechargeInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Duration timeUntilFullEnergy({DateTime? now}) {
    if (hostedSession) return Duration.zero;
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
    if (level < 1 || level > maxLevel) return false;
    return lessonNumberForLevel(level) == 1;
  }

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

  static bool isLevelUnlocked(int level) {
    if (level < 1 || level > maxLevel) return false;
    if (!isProductionLessonAvailable(level)) return false;
    if (developerMode) return true;
    if (hostedSession) return _hostedUnlockedLevels.contains(level);
    return true;
  }

  static String lessonIdForLevel(int level) {
    final unit = unitForLevel(level);
    return '${unit.number}-${lessonNumberForLevel(level)}';
  }

  static Map<int, Set<int>> get completedLessonsByUnit {
    final grouped = <int, Set<int>>{};
    for (final level in completedLevels) {
      if (level < 1 || level > maxLevel) continue;
      final unit = unitForLevel(level);
      grouped.putIfAbsent(unit.number, () => <int>{});
      grouped[unit.number]!.add(lessonNumberForLevel(level));
    }
    return grouped;
  }

  static int get firstUnlockedIncompleteLevel {
    for (final unit in units) {
      for (var level = unit.startLevel; level <= unit.endLevel; level++) {
        if (isProductionLessonAvailable(level) &&
            isLevelUnlocked(level) &&
            !completedLevels.contains(level)) {
          return level;
        }
      }
    }
    return 1;
  }

  static int get completedLevelCount =>
      completedLevels.where((level) => level >= 1 && level <= maxLevel).length;

  static double get overallProgress {
    if (maxLevel <= 0) return 0;
    return (completedLevelCount / maxLevel).clamp(0.0, 1.0);
  }

  static int get overallProgressPercent => (overallProgress * 100).round();

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

  /// Converts a lesson accuracy into 0-3 stars and keeps the best result.
  static void saveLevelScore(int level, LessonScoreStats stats) {
    completedLevels.add(level);
    final lessonId = lessonIdForLevel(level);
    final savedStats = stats.mergeBestFrom(lessonScores[lessonId]);
    lessonScores[lessonId] = savedStats;
    final stars = savedStats.bestAccuracy == 100
        ? 3
        : savedStats.bestAccuracy >= 90
        ? 2
        : savedStats.bestAccuracy >= 75
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
