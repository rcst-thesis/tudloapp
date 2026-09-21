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
    this.settings = AppSettings.defaults,
  });

  final String id;
  final String name;
  final int grade;
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

  /// This learner's own Settings values (language, volumes, animation/
  /// quality preferences, lesson reminders) -- seeded once from the
  /// device-wide `AppSettingsController` at creation
  /// (`LearnerController.createAndSave`'s `initialSettings` param), then
  /// fully independent from it and from every other learner's own copy.
  final AppSettings settings;

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
      settings: json['settings'] != null
          ? AppSettings.fromJson(json['settings']! as Map<String, Object?>)
          : AppSettings.defaults,
    );
  }
}
