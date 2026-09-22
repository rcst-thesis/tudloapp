import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';
import 'package:tudloapp/features/lesson/domain/lesson_progress_controller.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/lesson_score.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/home_map/screens/lessons_screen.dart'
    hide MapLocation;
import 'package:tudloapp/features/lesson_game/screens/lesson_intro_page.dart';
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_mapping.dart';
import 'package:tudloapp/features/lesson/presentation/lesson_catalog_screen.dart';
import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

/// Hosts the preserved DevG lesson-card page inside Tudlo.
///
/// Its artwork, carousel, card narration, and interaction mechanics remain
/// source-authentic. Navigation, persistence, energy, and audio are projected
/// from Tudlo at this boundary rather than imported from DevG.
class DevGLessonCatalogHost extends StatefulWidget {
  const DevGLessonCatalogHost({
    this.location,
    this.initialLessonId,
    this.onActivityChanged,
    super.key,
  });

  final MapLocation? location;
  final String? initialLessonId;
  final ValueChanged<bool>? onActivityChanged;

  @override
  State<DevGLessonCatalogHost> createState() => _DevGLessonCatalogHostState();
}

class _DevGLessonCatalogHostState extends State<DevGLessonCatalogHost> {
  LessonDefinition? _running;
  Future<void>? _completion;
  bool _openInitialPopup = true;
  String? _pendingPopupLessonId;

  void _startSourceLevel(int sourceLevel) {
    final grade = LearnerScope.of(context).profile?.grade ?? 1;
    final lesson = DevGLessonMapping.definitionFor(
      grade: grade,
      sourceLevel: sourceLevel,
    );
    if (lesson == null) return;
    AppData.lessonDashboardFocusLevel = sourceLevel;
    _openInitialPopup = false;
    _pendingPopupLessonId = null;
    setState(() => _running = lesson);
    widget.onActivityChanged?.call(true);
  }

  Future<void> _claim(LessonScoreStats score) {
    final running = _running;
    if (running == null) return Future.value();
    return _completion ??= _completeLesson(context, running, score);
  }

  Future<void> _returnToCards({bool waitForCompletion = false}) async {
    if (waitForCompletion) await (_completion ?? Future<void>.value());
    if (!mounted) return;
    setState(() {
      _running = null;
      _completion = null;
      _pendingPopupLessonId = null;
    });
    widget.onActivityChanged?.call(false);
  }

  Future<void> _continueToNextLesson() async {
    await (_completion ?? Future<void>.value());
    if (!mounted) return;
    final next = _running == null ? null : LessonCatalog.nextAfter(_running!);
    if (next != null) {
      AppData.lessonDashboardFocusLevel = DevGLessonMapping.sourceLevelFor(
        next,
      );
    }
    setState(() {
      _running = null;
      _completion = null;
      _pendingPopupLessonId = next?.id;
    });
    widget.onActivityChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final running = _running;
    final learnerGrade = LearnerScope.of(context).profile?.grade ?? 1;
    final popupLesson = LessonCatalog.byId(
      _pendingPopupLessonId ??
          (_openInitialPopup ? widget.initialLessonId : null),
    );
    final initialSourceLevel = popupLesson?.grade == learnerGrade
        ? DevGLessonMapping.sourceLevelFor(popupLesson!)
        : null;
    return _DevGLessonEnvironment(
      running: running,
      catalogLocation: widget.location,
      onStartSourceLevel: _startSourceLevel,
      onClaim: _claim,
      onExitIncomplete: _returnToCards,
      onExitAfterCompletion: () => _returnToCards(waitForCompletion: true),
      onExitToLessonsGallery: () => _returnToCards(waitForCompletion: true),
      onContinueToNextLesson: _continueToNextLesson,
      child: running == null
          ? LessonsScreen(initialSourceLevel: initialSourceLevel)
          : LevelGamePage(level: DevGLessonMapping.sourceLevelFor(running)),
    );
  }
}

/// Opens one preserved flow from Home or the real Rive map. Closing it always
/// returns to the route that launched it; there is no DevG navigation shell.
class DevGLessonRunnerScreen extends StatefulWidget {
  const DevGLessonRunnerScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<DevGLessonRunnerScreen> createState() => _DevGLessonRunnerScreenState();
}

class _DevGLessonRunnerScreenState extends State<DevGLessonRunnerScreen> {
  Future<void>? _completion;
  var _activityStarted = false;

  LessonDefinition? get _lesson => LessonCatalog.byId(widget.lessonId);

  Future<void> _claim(LessonScoreStats score) {
    final lesson = _lesson;
    if (lesson == null) return Future.value();
    return _completion ??= _completeLesson(context, lesson, score);
  }

  Future<void> _exit({required bool waitForCompletion}) async {
    if (waitForCompletion) await (_completion ?? Future<void>.value());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openLessonsGallery({bool openNextLesson = false}) async {
    await (_completion ?? Future<void>.value());
    if (!mounted) return;
    final next = openNextLesson && _lesson != null
        ? LessonCatalog.nextAfter(_lesson!)
        : null;
    unawaited(
      Navigator.of(context).pushReplacement<void, void>(
        FadePageRoute<void>(
          page: LessonCatalogScreen(initialLessonId: next?.id),
        ),
      ),
    );
  }

  void _startSourceLevel(int sourceLevel) {
    final lesson = _lesson;
    if (lesson == null ||
        sourceLevel != DevGLessonMapping.sourceLevelFor(lesson)) {
      return;
    }
    // Keeps the Lessons dashboard focused on this same lesson (its unit and
    // card) the next time it's opened, even though it was launched from
    // Home rather than from the dashboard's own grid.
    AppData.lessonDashboardFocusLevel = sourceLevel;
    setState(() => _activityStarted = true);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (lesson == null) {
      return const Scaffold(
        body: Center(child: Text('Wala nakita ang leksiyon.')),
      );
    }
    return _DevGLessonEnvironment(
      running: lesson,
      catalogLocation: null,
      onStartSourceLevel: _startSourceLevel,
      onClaim: _claim,
      onExitIncomplete: () => _exit(waitForCompletion: false),
      onExitAfterCompletion: () => _exit(waitForCompletion: true),
      onExitToLessonsGallery: _openLessonsGallery,
      onContinueToNextLesson: () => _openLessonsGallery(openNextLesson: true),
      child: _activityStarted
          ? LevelGamePage(level: DevGLessonMapping.sourceLevelFor(lesson))
          : LessonIntroPage(level: DevGLessonMapping.sourceLevelFor(lesson)),
    );
  }
}

class _DevGLessonEnvironment extends StatefulWidget {
  const _DevGLessonEnvironment({
    required this.running,
    required this.catalogLocation,
    required this.onStartSourceLevel,
    required this.onClaim,
    required this.onExitIncomplete,
    required this.onExitAfterCompletion,
    required this.onExitToLessonsGallery,
    required this.onContinueToNextLesson,
    required this.child,
  });

  final LessonDefinition? running;
  final MapLocation? catalogLocation;
  final void Function(int) onStartSourceLevel;
  final Future<void> Function(LessonScoreStats) onClaim;
  final Future<void> Function() onExitIncomplete;
  final Future<void> Function() onExitAfterCompletion;
  final Future<void> Function() onExitToLessonsGallery;
  final Future<void> Function() onContinueToNextLesson;
  final Widget child;

  @override
  State<_DevGLessonEnvironment> createState() => _DevGLessonEnvironmentState();
}

class _DevGLessonEnvironmentState extends State<_DevGLessonEnvironment> {
  AppState? _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appState != null) return;
    final learner = LearnerScope.of(context).profile;
    _appState = AppState()
      ..username = learner?.name ?? 'Abyan'
      ..activeProfileId = learner?.id;
  }

  @override
  void dispose() {
    AppData.endHostedSession();
    AppAudioService.instance.detach();
    _appState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learner = LearnerScope.of(context).profile;
    final progress = LessonProgressScope.of(context);
    final grade = learner?.grade ?? 1;
    final unlocked = <int>[];
    final completed = <int>[];
    final stickers = <int, String>{};
    final catalogLessons = widget.running != null
        ? <LessonDefinition>[widget.running!]
        : widget.catalogLocation == null
        ? LessonCatalog.forGrade(grade)
        : LessonCatalog.forLocation(
            grade: grade,
            location: widget.catalogLocation!,
          );

    for (final lesson in LessonCatalog.forGrade(grade)) {
      final sourceLevel = DevGLessonMapping.sourceLevelFor(lesson);
      if (progress.isUnlocked(lesson)) unlocked.add(sourceLevel);
      final completion = progress.progress.completions[lesson.id];
      if (completion != null) {
        completed.add(sourceLevel);
        stickers[sourceLevel] = completion.rewardAsset;
      }
    }
    AppData.configureHostedSession(
      grade: grade,
      energy: learner?.effectiveEnergy() ?? AppData.maxEnergy,
      unlockedLevels: unlocked,
      completed: completed,
      stickers: stickers,
      catalogLevels: catalogLessons.map(DevGLessonMapping.sourceLevelFor),
    );
    AppAudioService.instance.attach(TudloAudioScope.maybeOf(context));

    return AppStateScope(
      notifier: _appState!,
      child: DevGLessonHostScope(
        startSourceLevel: widget.onStartSourceLevel,
        exitIncomplete: widget.onExitIncomplete,
        exitAfterCompletion: widget.onExitAfterCompletion,
        exitToLessonsGallery: widget.onExitToLessonsGallery,
        continueToNextLesson: widget.onContinueToNextLesson,
        claimCompletion: widget.onClaim,
        child: widget.child,
      ),
    );
  }
}

Future<void> _completeLesson(
  BuildContext context,
  LessonDefinition lesson,
  LessonScoreStats score,
) {
  return LessonProgressScope.of(context).completeAndClaim(
    lesson: lesson,
    score: score.accuracy,
    accuracy: (score.accuracy / 100).clamp(0, 1).toDouble(),
    mistakes: score.mistakes,
    duration: Duration(milliseconds: score.timeTakenMs),
  );
}
