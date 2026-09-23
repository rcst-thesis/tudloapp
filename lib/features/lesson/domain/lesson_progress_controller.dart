import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';
import 'package:tudloapp/features/lesson/domain/lesson_progress.dart';
import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/domain/map_progress.dart';

/// Flutter's single owner of lesson progression and map-event scheduling.
///
/// It deliberately never talks to Rive. It persists through
/// [LearnerController], sets a semantic map route override, and lets
/// `MapScreen`'s documented bridge project that state into `isUnlocked` and
/// `hasEvent`.
class LessonProgressController extends ChangeNotifier {
  LessonProgressController({
    required LearnerController learnerController,
    required MapProgressController mapProgress,
  }) : _learnerController = learnerController,
       _mapProgress = mapProgress {
    _learnerController.addListener(_synchronizeFromLearner);
    _synchronizeFromLearner();
  }

  final LearnerController _learnerController;
  final MapProgressController _mapProgress;
  bool _isSeeding = false;

  LessonProgress get progress =>
      _learnerController.profile?.lessonProgress ??
      const LessonProgress.uninitialized();

  LessonDefinition? get activeLesson =>
      LessonCatalog.byId(progress.activeLessonId);

  bool isUnlocked(LessonDefinition definition) =>
      definition.id == progress.activeLessonId ||
      progress.isComplete(definition.id);

  bool isComplete(LessonDefinition definition) =>
      progress.isComplete(definition.id);

  void _synchronizeFromLearner() {
    final profile = _learnerController.profile;
    if (profile == null) {
      _mapProgress.eventOverrides.clearAll();
      _mapProgress.replaceUnlocked(const <MapLocation>{});
      notifyListeners();
      return;
    }

    final saved = profile.lessonProgress;
    if (!saved.initialized && !_isSeeding) {
      final first = LessonCatalog.firstForGrade(profile.grade);
      if (first != null) {
        _isSeeding = true;
        unawaited(
          _learnerController
              .seedLessonProgress(activeLessonId: first.id)
              .whenComplete(() => _isSeeding = false),
        );
      }
      return;
    }

    _mapProgress.replaceUnlocked(const <MapLocation>{});
    for (final id in profile.unlockedMapLocations) {
      final location = MapLocation.fromPersistedId(id);
      if (location != null) _mapProgress.unlock(location);
    }

    // The real Map tab deliberately never previews an active lesson's
    // location with an event glow -- that would spoil what to explore next
    // before the child has actually played the lesson. A location's map
    // event only exists ephemerally inside that lesson's own flow (see
    // grade_one_letter_flow.dart's _LessonOneMapStep), never here. This
    // controller's only lasting effect on the map is the permanent unlock
    // written by completeAndClaim below.
    _mapProgress.eventOverrides.clearAll();
    notifyListeners();
  }

  /// Writes a reward claim and schedules the next guided lesson. The caller
  /// invokes this only from a successful completion/reward screen; closing a
  /// session without calling it leaves the active map event untouched.
  Future<void> completeAndClaim({
    required LessonDefinition lesson,
    required int score,
    required double accuracy,
    required int mistakes,
    required Duration duration,
  }) async {
    final next = LessonCatalog.nextAfter(lesson);
    await _learnerController.recordLessonCompletion(
      completion: LessonCompletion(
        lessonId: lesson.id,
        score: score,
        accuracy: accuracy.clamp(0, 1).toDouble(),
        mistakes: mistakes < 0 ? 0 : mistakes,
        duration: duration.isNegative ? Duration.zero : duration,
        completedAt: DateTime.now(),
        rewardAsset: lesson.rewardAsset,
      ),
      nextLessonId: next?.id,
      unlockedLocationIds: {lesson.location.persistedId},
    );
  }

  @override
  void dispose() {
    _learnerController.removeListener(_synchronizeFromLearner);
    super.dispose();
  }
}

/// Makes the app-owned lesson controller available without prop drilling.
class LessonProgressScope extends InheritedNotifier<LessonProgressController> {
  const LessonProgressScope({
    required LessonProgressController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  // Bare widget tests sometimes construct a screen below only MaterialApp.
  // Retain one inert fallback instead of creating a listening controller on
  // every build. Production always receives the app-owned controller above.
  static final _fallback = LessonProgressController(
    learnerController: LearnerController(),
    mapProgress: MapProgressController(),
  );

  static LessonProgressController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LessonProgressScope>();
    return scope?.notifier ?? _fallback;
  }
}
