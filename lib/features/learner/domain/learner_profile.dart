import 'package:tudloapp/features/lesson/domain/lesson_progress.dart';
import 'package:tudloapp/features/settings/domain/app_settings.dart';

/// A saved learner: everything onboarding collects, plus progression data
/// that accumulates afterward (lessons, stickers, badges, streak, and which
/// map locations earned by claimed lesson completions or other milestones).
///
/// Deliberately holds no dependency on any other feature's domain types --
/// [unlockedMapLocations] stores raw location ids (`MapLocation.persistedId`
/// strings), not `MapLocation` values, so this stays a plain, storable data
/// shape that `map`'s domain doesn't need to know exists and vice versa.
/// Whatever bridges the two lives in presentation code (`MapScreen`).
class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.energy,
    required this.createdAt,
    this.avatarId = defaultAvatarId,
    this.lessonsFinished = 0,
    this.stickersEarned = 0,
    this.badgesEarned = 0,
    this.currentStreak = 1,
    this.unlockedMapLocations = const {},
    this.lessonProgress = const LessonProgress.uninitialized(),
    this.favoritedWords = const {},
    this.wordOfTheDayId,
    this.wordOfTheDayDate,
    this.wordOfTheDayHistory = const {},
    this.categorySearchCounts = const {},
    this.featuredIds = const [],
    this.featuredDate,
    this.featuredHistory = const {},
    this.lastStreakCheckInDate,
    this.currentEnergy,
    this.lastEnergyDrainAt,
    this.settings = AppSettings.defaults,
  });

  final String id;
  final String name;
  final int grade;

  /// The parent-configured energy level (Onboarding's/Settings' "battery"
  /// picker, 10-100 in steps of 10) -- the ceiling [effectiveEnergy]
  /// recharges up to, not a live spendable count on its own.
  final int energy;
  final DateTime createdAt;

  /// Which of `assets/images/avatar.riv`'s Artboards this learner has
  /// picked (Me screen's Edit popup) -- stored as the Artboard's own name so
  /// looking it up at render time is just `file.artboard(avatarId)`, no
  /// separate index-to-name table to keep in sync. Defaults to the file's
  /// only Artboard today; more will be added to the same file later.
  final String avatarId;
  static const defaultAvatarId = 'Ok_Color';
  final int lessonsFinished;
  final int stickersEarned;
  final int badgesEarned;
  final int currentStreak;
  final Set<String> unlockedMapLocations;

  /// Versioned completion results and the one currently scheduled lesson.
  /// Keeping this immutable value in the existing learner save means lesson
  /// state remains learner-owned, restart-safe, and independent of Rive.
  final LessonProgress lessonProgress;
  final Set<String> favoritedWords;

  /// The currently-selected word-of-the-day entry's id (a
  /// `DictionaryEntry.id`), the calendar date that selection was made for
  /// (compared by year/month/day only), and which ids have already been
  /// shown this rotation cycle. Same "raw id, not the other feature's
  /// domain type" rule as [unlockedMapLocations] -- the rotation logic
  /// lives in `dictionary`'s domain, not here.
  final String? wordOfTheDayId;
  final DateTime? wordOfTheDayDate;
  final Set<String> wordOfTheDayHistory;

  /// Per-category interest counter for this learner (bumped by search
  /// queries, category chip taps, and word lookups in the browse screen)
  /// -- drives which categories `resolveFeatured` prioritizes. Same
  /// same-day-lock-in + rotation-history shape as the word-of-the-day
  /// fields above, for the browse screen's featured tray specifically.
  final Map<String, int> categorySearchCounts;
  final List<String> featuredIds;
  final DateTime? featuredDate;
  final Set<String> featuredHistory;

  /// The calendar date (year/month/day only) the day-streak check-in flow
  /// (`DailyCheckInScreen` -> `DailyStreakScreen`) was last shown to this
  /// learner, right before Home -- so it only pops up once per day rather
  /// than every time "continue"/"load" is tapped. `null` means it has never
  /// been shown yet.
  final DateTime? lastStreakCheckInDate;

  /// The learner's actual spendable energy right now, as of
  /// [lastEnergyDrainAt] -- drains by 10 per completed lesson
  /// (`LearnerScope.spendLessonEnergy`) and regenerates by 10 every 4 hours
  /// after that, capped at [energy]. `null` means never drained yet, i.e.
  /// full. Use [effectiveEnergy] to read the regen-adjusted value -- this
  /// raw field goes stale between drains, same reasoning as
  /// [currentStreak]/[effectiveStreak].
  final int? currentEnergy;
  final DateTime? lastEnergyDrainAt;

  /// This learner's own Settings values (language, volumes, animation/
  /// quality preferences, lesson reminders) -- seeded once from the
  /// device-wide `AppSettingsController` at creation
  /// (`LearnerController.createAndSave`'s `initialSettings` param), then
  /// fully independent from it and from every other learner's own copy.
  final AppSettings settings;

  /// The streak as it should actually display right now, not just whatever
  /// [currentStreak] was last saved as. [currentStreak] only ever advances
  /// when a lesson is first-completed (see `LearnerScope.recordLessonCompletion`),
  /// so on its own it never reflects a streak the learner has since broken
  /// by skipping a day -- this catches that up at read time instead of
  /// requiring some background job to notice and reset it.
  int effectiveStreak([DateTime? now]) {
    final last = lessonProgress.lastFirstCompletionDate;
    // Never completed a lesson yet -- keep the day-one default rather than
    // treating "no history" as a broken streak.
    if (last == null) return currentStreak;
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(last.year, last.month, last.day);
    final daysSince = todayDate.difference(lastDate).inDays;
    // Still today or as recent as yesterday -- the streak is intact (today's
    // completion may not have landed yet). Anything older means at least one
    // full day was skipped.
    return daysSince <= 1 ? currentStreak : 0;
  }

  /// The energy that should actually display/be spendable right now --
  /// [currentEnergy] plus every whole 4-hour block that's passed since
  /// [lastEnergyDrainAt], capped at [energy] (never above the parent-set
  /// level). Never drained yet (either field `null`) reads as full.
  int effectiveEnergy([DateTime? now]) {
    final stored = currentEnergy;
    final anchor = lastEnergyDrainAt;
    if (stored == null || anchor == null) return energy;
    final elapsedHours = (now ?? DateTime.now()).difference(anchor).inHours;
    final ticks = elapsedHours ~/ 4;
    if (ticks <= 0) return stored;
    return (stored + ticks * 10).clamp(0, energy);
  }

  /// Whether the day-streak check-in flow should show before Home right
  /// now -- true the first time this learner is resumed on a given
  /// calendar date, false for every later "continue"/"load" that same day.
  bool needsStreakCheckInToday([DateTime? now]) {
    final last = lastStreakCheckInDate;
    if (last == null) return true;
    final today = now ?? DateTime.now();
    return !(last.year == today.year &&
        last.month == today.month &&
        last.day == today.day);
  }

  LearnerProfile copyWith({
    String? name,
    int? energy,
    String? avatarId,
    int? lessonsFinished,
    int? stickersEarned,
    int? badgesEarned,
    int? currentStreak,
    Set<String>? unlockedMapLocations,
    LessonProgress? lessonProgress,
    Set<String>? favoritedWords,
    String? wordOfTheDayId,
    DateTime? wordOfTheDayDate,
    Set<String>? wordOfTheDayHistory,
    Map<String, int>? categorySearchCounts,
    List<String>? featuredIds,
    DateTime? featuredDate,
    Set<String>? featuredHistory,
    DateTime? lastStreakCheckInDate,
    int? currentEnergy,
    DateTime? lastEnergyDrainAt,
    AppSettings? settings,
  }) {
    return LearnerProfile(
      id: id,
      name: name ?? this.name,
      grade: grade,
      energy: energy ?? this.energy,
      createdAt: createdAt,
      avatarId: avatarId ?? this.avatarId,
      lessonsFinished: lessonsFinished ?? this.lessonsFinished,
      stickersEarned: stickersEarned ?? this.stickersEarned,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedMapLocations: unlockedMapLocations ?? this.unlockedMapLocations,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      favoritedWords: favoritedWords ?? this.favoritedWords,
      wordOfTheDayId: wordOfTheDayId ?? this.wordOfTheDayId,
      wordOfTheDayDate: wordOfTheDayDate ?? this.wordOfTheDayDate,
      wordOfTheDayHistory: wordOfTheDayHistory ?? this.wordOfTheDayHistory,
      categorySearchCounts: categorySearchCounts ?? this.categorySearchCounts,
      featuredIds: featuredIds ?? this.featuredIds,
      featuredDate: featuredDate ?? this.featuredDate,
      featuredHistory: featuredHistory ?? this.featuredHistory,
      lastStreakCheckInDate:
          lastStreakCheckInDate ?? this.lastStreakCheckInDate,
      currentEnergy: currentEnergy ?? this.currentEnergy,
      lastEnergyDrainAt: lastEnergyDrainAt ?? this.lastEnergyDrainAt,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'grade': grade,
    'energy': energy,
    'createdAt': createdAt.toIso8601String(),
    'avatarId': avatarId,
    'lessonsFinished': lessonsFinished,
    'stickersEarned': stickersEarned,
    'badgesEarned': badgesEarned,
    'currentStreak': currentStreak,
    'unlockedMapLocations': unlockedMapLocations.toList(),
    'lessonProgress': lessonProgress.toJson(),
    'favoritedWords': favoritedWords.toList(),
    'wordOfTheDayId': wordOfTheDayId,
    'wordOfTheDayDate': wordOfTheDayDate?.toIso8601String(),
    'wordOfTheDayHistory': wordOfTheDayHistory.toList(),
    'categorySearchCounts': categorySearchCounts,
    'featuredIds': featuredIds,
    'featuredDate': featuredDate?.toIso8601String(),
    'featuredHistory': featuredHistory.toList(),
    'lastStreakCheckInDate': lastStreakCheckInDate?.toIso8601String(),
    'currentEnergy': currentEnergy,
    'lastEnergyDrainAt': lastEnergyDrainAt?.toIso8601String(),
    'settings': settings.toJson(),
  };

  factory LearnerProfile.fromJson(Map<String, Object?> json) {
    return LearnerProfile(
      id: json['id']! as String,
      name: json['name']! as String,
      grade: json['grade']! as int,
      energy: json['energy']! as int,
      createdAt: DateTime.parse(json['createdAt']! as String),
      avatarId: json['avatarId'] as String? ?? defaultAvatarId,
      lessonsFinished: json['lessonsFinished'] as int? ?? 0,
      stickersEarned: json['stickersEarned'] as int? ?? 0,
      badgesEarned: json['badgesEarned'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 1,
      unlockedMapLocations:
          (json['unlockedMapLocations'] as List<Object?>? ?? const [])
              .cast<String>()
              .toSet(),
      lessonProgress: LessonProgress.fromJson(json['lessonProgress']),
      favoritedWords: (json['favoritedWords'] as List<Object?>? ?? const [])
          .cast<String>()
          .toSet(),
      wordOfTheDayId: json['wordOfTheDayId'] as String?,
      wordOfTheDayDate: json['wordOfTheDayDate'] != null
          ? DateTime.parse(json['wordOfTheDayDate']! as String)
          : null,
      wordOfTheDayHistory:
          (json['wordOfTheDayHistory'] as List<Object?>? ?? const [])
              .cast<String>()
              .toSet(),
      categorySearchCounts:
          (json['categorySearchCounts'] as Map<String, Object?>? ?? const {})
              .map((key, value) => MapEntry(key, value! as int)),
      featuredIds: (json['featuredIds'] as List<Object?>? ?? const [])
          .cast<String>(),
      featuredDate: json['featuredDate'] != null
          ? DateTime.parse(json['featuredDate']! as String)
          : null,
      featuredHistory: (json['featuredHistory'] as List<Object?>? ?? const [])
          .cast<String>()
          .toSet(),
      lastStreakCheckInDate: json['lastStreakCheckInDate'] != null
          ? DateTime.parse(json['lastStreakCheckInDate']! as String)
          : null,
      currentEnergy: json['currentEnergy'] as int?,
      lastEnergyDrainAt: json['lastEnergyDrainAt'] != null
          ? DateTime.parse(json['lastEnergyDrainAt']! as String)
          : null,
      settings: json['settings'] != null
          ? AppSettings.fromJson(json['settings']! as Map<String, Object?>)
          : AppSettings.defaults,
    );
  }
}
