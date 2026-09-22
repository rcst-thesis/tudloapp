import 'package:flutter/widgets.dart';

import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_repository.dart';
import 'package:tudloapp/features/lesson/domain/lesson_progress.dart';
import 'package:tudloapp/features/settings/domain/app_settings.dart';

/// The app's one current [LearnerProfile], if any, and the single place
/// that creates/updates/persists it. `profile` is `null` until either
/// [loadSaved] finds one on disk or [createAndSave] makes a new one (e.g.
/// at the end of onboarding) -- screens should treat `null` as "nothing
/// loaded yet" and fall back to their own sensible defaults, not as an
/// error.
class LearnerController extends ChangeNotifier {
  LearnerController({LearnerRepository repository = const LearnerRepository()})
    : _repository = repository;

  final LearnerRepository _repository;
  LearnerProfile? _profile;

  LearnerProfile? get profile => _profile;

  /// Loads whatever learner was last saved as current, if any. Safe to call
  /// even if nothing has ever been saved, or if storage isn't available at
  /// all (e.g. a widget test with no `shared_preferences` mock set up) --
  /// either way [profile] is just left `null`, same as "nothing saved yet".
  Future<void> loadSaved() async {
    try {
      final loaded = await _repository.loadCurrent();
      if (loaded == null) return;
      _profile = loaded;
      notifyListeners();
    } catch (_) {
      // Storage unavailable/corrupt: proceed with no restored profile
      // rather than crashing startup over it.
    }
  }

  /// Creates a new learner from onboarding's collected data and makes it
  /// current immediately (so the rest of the app sees it right away), then
  /// best-effort persists it -- a failed save shouldn't block finishing
  /// onboarding, it just means the profile won't survive a restart.
  ///
  /// [initialSettings] seeds the new learner's own `LearnerProfile.settings`
  /// -- pass the current device-wide `AppSettingsController.settings` at
  /// the call site so a brand new learner starts from whatever was already
  /// configured at the main menu. This is a one-time copy, not a live
  /// link: once created, the learner's settings are fully independent from
  /// the device-wide ones and from every other learner's own copy. Omit it
  /// to fall back to [AppSettings.defaults].
  Future<void> createAndSave({
    required String name,
    required int grade,
    required int energy,
    AppSettings? initialSettings,
  }) async {
    final created = LearnerProfile(
      id: LearnerRepository.generateId(),
      name: name,
      grade: grade,
      energy: energy,
      createdAt: DateTime.now(),
      settings: initialSettings ?? AppSettings.defaults,
    );
    _profile = created;
    notifyListeners();
    try {
      await _repository.setCurrent(created);
    } catch (_) {
      // Best-effort: the app keeps using the in-memory profile either way.
    }
  }

  /// Logs out the current learner: clears it from memory immediately (so
  /// every screen watching [profile] sees `null` right away) and
  /// best-effort forgets it as "current" on disk too, so a fresh app
  /// launch doesn't silently resume this learner. A no-op if there's no
  /// current learner.
  Future<void> logOut() async {
    if (_profile == null) return;
    _profile = null;
    notifyListeners();
    try {
      await _repository.clearCurrent();
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// The most recently active learner, even after [logOut] -- unlike
  /// [profile], logging out does not clear this. Lets the main menu's
  /// "continue" keep naming whoever you'd resume, independent of whether
  /// anyone is actively signed in right now. `null` if nothing has ever
  /// been used on this device, or storage is unavailable.
  Future<LearnerProfile?> loadLastUsedProfile() async {
    try {
      return await _repository.loadLastUsed();
    } catch (_) {
      return null;
    }
  }

  /// Every learner profile currently saved on this device -- the Load
  /// screen's real save list.
  Future<List<LearnerProfile>> listSavedProfiles() async {
    try {
      return await _repository.listSavedProfiles();
    } catch (_) {
      return const [];
    }
  }

  /// Makes [profile] the current learner (e.g. picking a real save to load)
  /// -- same effect [createAndSave] has, just for an already-existing
  /// profile instead of a brand new one.
  Future<void> switchTo(LearnerProfile profile) async {
    _profile = profile;
    notifyListeners();
    try {
      await _repository.setCurrent(profile);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Deletes [id] outright. If it's the profile currently in memory, clears
  /// it (same in-memory effect as [logOut]) so nothing keeps reading a
  /// profile that no longer exists on disk.
  Future<void> deleteProfile(String id) async {
    if (_profile?.id == id) {
      _profile = null;
      notifyListeners();
    }
    try {
      await _repository.deleteProfile(id);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Renames the current learner (Me screen's Edit popup) and best-effort
  /// persists it. A no-op if there's no current learner yet.
  Future<void> updateName(String name) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(name: name);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Changes which `assets/images/avatar.riv` Artboard the current learner
  /// has picked (Me screen's Edit popup) and best-effort persists it. A
  /// no-op if there's no current learner yet.
  Future<void> updateAvatar(String avatarId) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(avatarId: avatarId);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Updates the current learner's energy level (10-100, in 10% steps --
  /// same range/step as onboarding's energy setter) and best-effort
  /// persists it. This is the "parent controlled" value the Learning &
  /// Energy settings panel edits, and what Home's lesson panel reads to
  /// cap how many lessons are available today
  /// (`home_lesson_panel.dart`'s `_availableLessons`). A no-op if there's
  /// no current learner yet.
  Future<void> setEnergy(int energy) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(energy: energy);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Replaces the current learner's own [AppSettings] (language, volumes,
  /// animation/quality preferences, lesson reminders) and best-effort
  /// persists it. This is what General/Sound & Voice/Display &
  /// Performance/Learning & Energy's "Lesson Reminders" write to while
  /// `insideLearnerProfile` is true, instead of the device-wide
  /// `AppSettingsController`. A no-op if there's no current learner yet.
  Future<void> updateSettings(AppSettings settings) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(settings: settings);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Records [locationId] (a `MapLocation.persistedId`) as permanently unlocked
  /// on the current learner and best-effort persists it. A no-op if there's
  /// no current learner yet, or it's already unlocked.
  Future<void> unlockMapLocation(String locationId) async {
    final current = _profile;
    if (current == null) return;
    if (current.unlockedMapLocations.contains(locationId)) return;
    final updated = current.copyWith(
      unlockedMapLocations: {...current.unlockedMapLocations, locationId},
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Seeds a backward-compatible profile with its grade's first active
  /// lesson. This is the one allowed pre-completion persistence write: old
  /// saves need an initial event after their first launch. Existing lesson
  /// progress is never overwritten.
  Future<void> seedLessonProgress({required String activeLessonId}) async {
    final current = _profile;
    if (current == null || current.lessonProgress.initialized) return;
    final updated = current.copyWith(
      lessonProgress: LessonProgress(
        version: LessonProgress.currentVersion,
        initialized: true,
        activeLessonId: activeLessonId,
        completions: current.lessonProgress.completions,
        lastFirstCompletionDate: current.lessonProgress.lastFirstCompletionDate,
      ),
      // An active event is visible to map logic, but it does not make the
      // physical location available. Completion is the permanent unlock.
      unlockedMapLocations: current.unlockedMapLocations,
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, consistent with the rest of learner persistence.
    }
  }

  /// Marks the day-streak check-in flow as shown for today, so
  /// [LearnerProfile.needsStreakCheckInToday] reports false for the rest of
  /// the calendar date -- called once, right when that flow is about to be
  /// shown, not after the learner finishes clicking through it, so an
  /// interrupted flow (app killed mid-way) still doesn't reappear later the
  /// same day.
  Future<void> recordStreakCheckIn({DateTime? now}) async {
    final current = _profile;
    if (current == null) return;
    final today = _dateOnly(now ?? DateTime.now());
    if (_sameDate(current.lastStreakCheckInDate, today)) return;
    final updated = current.copyWith(lastStreakCheckInDate: today);
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, consistent with the rest of learner persistence.
    }
  }

  /// Stores a completed/claimed lesson result and any progression it causes.
  ///
  /// A replay may replace a result only when it is genuinely better (higher
  /// accuracy, then fewer mistakes, then a higher score). It never increments
  /// finished lessons, stickers, or the daily streak a second time -- but
  /// every completion (including replays) spends 10 energy, same as the
  /// original DevG cost.
  Future<void> recordLessonCompletion({
    required LessonCompletion completion,
    required String? nextLessonId,
    required Set<String> unlockedLocationIds,
  }) async {
    final current = _profile;
    if (current == null) return;

    final existing = current.lessonProgress.completions[completion.lessonId];
    final firstCompletion = existing == null;
    final shouldReplace = existing == null || _isBetter(completion, existing);
    final completions = Map<String, LessonCompletion>.from(
      current.lessonProgress.completions,
    );
    if (shouldReplace) completions[completion.lessonId] = completion;

    final today = _dateOnly(completion.completedAt);
    final lastDate = current.lessonProgress.lastFirstCompletionDate;
    final countsForStreak = firstCompletion && !_sameDate(lastDate, today);
    // A real day streak, not just a running total of distinct active days:
    // only extend it when yesterday's the last time a lesson was first
    // completed. Any bigger gap means the streak already broke, so today's
    // completion starts a fresh one at 1 instead of resuming the old count.
    final yesterday = today.subtract(const Duration(days: 1));
    final continuesStreak = _sameDate(lastDate, yesterday);
    final nextStreak = !countsForStreak
        ? current.currentStreak
        : (continuesStreak ? current.currentStreak + 1 : 1);
    final progress = LessonProgress(
      version: LessonProgress.currentVersion,
      initialized: true,
      activeLessonId: nextLessonId,
      completions: Map.unmodifiable(completions),
      lastFirstCompletionDate: countsForStreak
          ? today
          : current.lessonProgress.lastFirstCompletionDate,
    );
    // 10 energy per finished lesson (replays cost the same as a first
    // completion), catching up any regen accrued since the last drain
    // first so a completion right after a regen tick doesn't lose it.
    final energyBeforeSpend = current.effectiveEnergy(completion.completedAt);
    final nextEnergy = (energyBeforeSpend - 10).clamp(0, current.energy);
    final updated = current.copyWith(
      lessonsFinished: current.lessonsFinished + (firstCompletion ? 1 : 0),
      stickersEarned: current.stickersEarned + (firstCompletion ? 1 : 0),
      currentStreak: nextStreak,
      lessonProgress: progress,
      unlockedMapLocations: {
        ...current.unlockedMapLocations,
        ...unlockedLocationIds,
      },
      currentEnergy: nextEnergy,
      lastEnergyDrainAt: completion.completedAt,
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Completion remains visible this run if storage is unavailable.
    }
  }

  static bool _isBetter(LessonCompletion candidate, LessonCompletion existing) {
    if (candidate.accuracy != existing.accuracy) {
      return candidate.accuracy > existing.accuracy;
    }
    if (candidate.mistakes != existing.mistakes) {
      return candidate.mistakes < existing.mistakes;
    }
    return candidate.score > existing.score;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _sameDate(DateTime? left, DateTime right) =>
      left != null &&
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  /// Toggles [wordId] (a `DictionaryEntry.id`) in the current learner's
  /// favorited words and best-effort persists it. A no-op if there's no
  /// current learner yet.
  Future<void> toggleFavoriteWord(String wordId) async {
    final current = _profile;
    if (current == null) return;
    final isFavorited = current.favoritedWords.contains(wordId);
    final updated = current.copyWith(
      favoritedWords: isFavorited
          ? ({...current.favoritedWords}..remove(wordId))
          : {...current.favoritedWords, wordId},
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Records [id] (a `DictionaryEntry.id`) as the current learner's word of
  /// the day for [date], plus the updated rotation [history], and
  /// best-effort persists it. A no-op if there's no current learner yet.
  Future<void> recordWordOfTheDay({
    required String id,
    required DateTime date,
    required Set<String> history,
  }) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(
      wordOfTheDayId: id,
      wordOfTheDayDate: date,
      wordOfTheDayHistory: history,
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Bumps [category]'s per-learner interest counter (used by
  /// `resolveFeatured` to rank which categories the featured tray should
  /// draw from) and best-effort persists it. A no-op if there's no current
  /// learner yet.
  Future<void> incrementCategorySearchCount(String category) async {
    final current = _profile;
    if (current == null) return;
    final count = (current.categorySearchCounts[category] ?? 0) + 1;
    final updated = current.copyWith(
      categorySearchCounts: {...current.categorySearchCounts, category: count},
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }

  /// Records [ids] (`DictionaryEntry.id`s) as the current learner's
  /// featured-tray picks for [date], plus the updated rotation [history],
  /// and best-effort persists it. A no-op if there's no current learner
  /// yet.
  ///
  /// [decayedCategoryCounts], when passed, replaces the stored
  /// `categorySearchCounts` in the same save -- `DictionaryBrowseScreen`
  /// passes `decayCategorySearchCounts(profile.categorySearchCounts)` here
  /// once a day (whenever this is a fresh pick, not a same-day cache hit)
  /// so old interest fades instead of accumulating forever. Omit it to
  /// leave the counts untouched.
  Future<void> recordFeatured({
    required List<String> ids,
    required DateTime date,
    required Set<String> history,
    Map<String, int>? decayedCategoryCounts,
  }) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.copyWith(
      featuredIds: ids,
      featuredDate: date,
      featuredHistory: history,
      categorySearchCounts: decayedCategoryCounts,
    );
    _profile = updated;
    notifyListeners();
    try {
      await _repository.save(updated);
    } catch (_) {
      // Best-effort, same as createAndSave.
    }
  }
}

/// Makes the app's one [LearnerController] available to every screen,
/// without threading it through navigation call sites. Same pattern as
/// `AppAnimationScope` (`lib/core/motion/app_animation_controller.dart`).
class LearnerScope extends InheritedNotifier<LearnerController> {
  const LearnerScope({
    required LearnerController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Returns the shared controller if one is above [context], otherwise a
  /// fresh standalone one with no loaded profile -- e.g. a widget test that
  /// pumps a screen inside a bare `MaterialApp` rather than the full
  /// `TudloApp` shell.
  static LearnerController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LearnerScope>();
    return scope?.notifier ?? LearnerController();
  }
}
