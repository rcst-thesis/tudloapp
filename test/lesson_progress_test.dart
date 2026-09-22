import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/lesson/domain/lesson_content.dart';
import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';
import 'package:tudloapp/features/lesson/domain/lesson_progress_controller.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/lesson_score.dart';
import 'package:tudloapp/features/home_map/screens/lessons_screen.dart'
    hide MapLocation;
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/lesson_game/screens/lesson_intro_page.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_mapping.dart';
import 'package:tudloapp/features/lesson/presentation/lesson_catalog_screen.dart';
import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/domain/map_progress.dart';
import 'package:tudloapp/features/map/domain/map_route_resolver.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('catalog contains the 12 approved flows in guided grade order', () {
    expect(LessonCatalog.all, hasLength(12));
    expect(LessonCatalog.forGrade(1).map((lesson) => lesson.id), [
      'g1_u1_l1',
      'g1_u1_l7',
      'g1_u2_l1',
      'g1_u2_l4',
    ]);
    expect(LessonCatalog.forGrade(2).map((lesson) => lesson.id), [
      'g2_u1_l1',
      'g2_u1_l2',
      'g2_u2_l1',
      'g2_u2_l2',
    ]);
    expect(LessonCatalog.forGrade(3).map((lesson) => lesson.id), [
      'g3_u1_l1',
      'g3_u1_l3',
      'g3_u2_l1',
      'g3_u2_l2',
    ]);
  });

  test('catalog location mapping and Grade 3 orientation are stable', () {
    expect(
      LessonCatalog.forLocation(
        grade: 1,
        location: MapLocation.school,
      ).map((lesson) => lesson.id),
      ['g1_u1_l1', 'g1_u1_l7'],
    );
    expect(
      LessonCatalog.forLocation(
        grade: 2,
        location: MapLocation.plaza,
      ).map((lesson) => lesson.id),
      ['g2_u2_l1', 'g2_u2_l2'],
    );
    expect(
      LessonCatalog.forLocation(
        grade: 3,
        location: MapLocation.market,
      ).map((lesson) => lesson.id),
      ['g3_u1_l1', 'g3_u1_l3', 'g3_u2_l2'],
    );
    expect(
      LessonCatalog.forGrade(
        3,
      ).every((lesson) => lesson.orientation == LessonOrientation.landscape),
      isTrue,
    );
    expect(
      LessonCatalog.all
          .map((lesson) => lesson.rewardAsset)
          .every(
            (asset) => asset.startsWith('assets/images/stickers/rewards/home/'),
          ),
      isTrue,
    );
  });

  test(
    'map defaults keep House as a chooser and mapped locations as catalogs',
    () {
      expect(
        MapDefaultRoutes.actionFor(MapLocation.house),
        isA<ShowHouseChoiceRouteAction>(),
      );
      expect(
        MapDefaultRoutes.actionFor(MapLocation.school),
        isA<OpenLessonCatalogRouteAction>().having(
          (action) => action.location,
          'location',
          MapLocation.school,
        ),
      );
      expect(
        MapDefaultRoutes.actionFor(MapLocation.farm),
        isA<PushScreenRouteAction>(),
      );
    },
  );

  test('every approved flow has loadable source content', () async {
    for (final definition in LessonCatalog.all) {
      final content = await LessonContentRepository.load(definition);
      expect(content.id, definition.id);
      expect(content.title, isNotEmpty);
      expect(content.questions, isNotEmpty);
    }
  });

  test('legacy learner JSON safely receives uninitialized lesson progress', () {
    final profile = LearnerProfile.fromJson({
      'id': 'legacy',
      'name': 'Koka',
      'grade': 2,
      'energy': 60,
      'createdAt': '2026-09-21T00:00:00.000',
    });

    expect(profile.lessonProgress.initialized, isFalse);
    expect(profile.lessonProgress.completions, isEmpty);
    expect(profile.lessonProgress.activeLessonId, isNull);
  });

  test(
    'first completion schedules one next event and replay does not count twice',
    () async {
      final learner = LearnerController();
      await learner.createAndSave(name: 'Koka', grade: 1, energy: 60);
      await learner.seedLessonProgress(activeLessonId: 'g1_u1_l1');
      final map = MapProgressController();
      final controller = LessonProgressController(
        learnerController: learner,
        mapProgress: map,
      );
      addTearDown(controller.dispose);

      // The real map never previews an active lesson's location with an event
      // glow -- that would spoil what to explore next. It only ever shows the
      // normal, ordinary state until the lesson is actually completed.
      expect(map.eventOverrides.overrideFor(MapLocation.school), isNull);
      expect(map.unlockedLocations, isNot(contains(MapLocation.school)));

      final first = LessonCatalog.byId('g1_u1_l1')!;
      await controller.completeAndClaim(
        lesson: first,
        score: 80,
        accuracy: .8,
        mistakes: 2,
        duration: const Duration(seconds: 30),
      );

      final afterFirst = learner.profile!;
      expect(afterFirst.lessonsFinished, 1);
      expect(afterFirst.stickersEarned, 1);
      expect(afterFirst.lessonProgress.activeLessonId, 'g1_u1_l7');
      expect(
        afterFirst.unlockedMapLocations,
        contains(MapLocation.school.persistedId),
      );
      // g1_u1_l7 is now active, but still no map event -- School stays
      // ordinary on the real map even though it's permanently unlocked now.
      expect(map.eventOverrides.overrideFor(MapLocation.school), isNull);

      await controller.completeAndClaim(
        lesson: first,
        score: 100,
        accuracy: 1,
        mistakes: 0,
        duration: const Duration(seconds: 20),
      );

      final afterReplay = learner.profile!;
      expect(afterReplay.lessonsFinished, 1);
      expect(afterReplay.stickersEarned, 1);
      expect(afterReplay.lessonProgress.completions[first.id]!.score, 100);

      final seventh = LessonCatalog.byId('g1_u1_l7')!;
      await controller.completeAndClaim(
        lesson: seventh,
        score: 100,
        accuracy: 1,
        mistakes: 0,
        duration: const Duration(seconds: 40),
      );
      final afterSeventh = learner.profile!;
      expect(
        afterSeventh.lessonProgress.completions[seventh.id]!.rewardAsset,
        'assets/images/stickers/rewards/home/cat-home-sticker.svg',
      );
      expect(afterSeventh.lessonProgress.activeLessonId, 'g1_u2_l1');
      expect(afterSeventh.stickersEarned, 2);
    },
  );

  test('active lesson restores from a persisted learner after restart, '
      'with no map event', () async {
    final original = LearnerController();
    await original.createAndSave(name: 'Koka', grade: 3, energy: 60);
    await original.seedLessonProgress(activeLessonId: 'g3_u1_l1');

    final restored = LearnerController();
    await restored.loadSaved();
    final map = MapProgressController();
    final controller = LessonProgressController(
      learnerController: restored,
      mapProgress: map,
    );
    addTearDown(controller.dispose);

    expect(restored.profile!.lessonProgress.activeLessonId, 'g3_u1_l1');
    expect(map.unlockedLocations, isNot(contains(MapLocation.market)));
    // Restoring an active lesson must not resurrect a map event either --
    // the real map stays ordinary regardless of session restarts.
    expect(map.eventOverrides.overrideFor(MapLocation.market), isNull);
  });

  test(
    'preserved source catalogue receives only a selected location’s levels',
    () {
      final school = LessonCatalog.forLocation(
        grade: 1,
        location: MapLocation.school,
      );
      AppData.configureHostedSession(
        grade: 1,
        energy: 60,
        unlockedLevels: [DevGLessonMapping.sourceLevelFor(school.first)],
        completed: const <int>[],
        stickers: const <int, String>{},
        catalogLevels: school.map(DevGLessonMapping.sourceLevelFor),
      );

      expect(AppData.catalogLevelsForUnit(AppData.unitForNumber(1)), [1, 7]);
      expect(AppData.catalogUnits.map((unit) => unit.number), [1]);
      expect(AppData.isLevelUnlocked(1), isTrue);
      expect(AppData.isLevelUnlocked(7), isFalse);
    },
  );

  testWidgets('a real-map location opens the preserved filtered card page', (
    tester,
  ) async {
    final learner = LearnerController();
    await learner.createAndSave(name: 'Koka', grade: 1, energy: 60);
    await learner.seedLessonProgress(activeLessonId: 'g1_u1_l1');
    final controller = LessonProgressController(
      learnerController: learner,
      mapProgress: MapProgressController(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LearnerScope(
          controller: learner,
          child: LessonProgressScope(
            controller: controller,
            child: const DevGLessonCatalogHost(location: MapLocation.school),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LessonsScreen), findsOneWidget);
    expect(AppData.catalogUnits.map((unit) => unit.number), [1]);
    expect(AppData.catalogLevelsForUnit(AppData.unitForNumber(1)), [1, 7]);
  });

  testWidgets('Lessons battery matches Home energy and 0-100 bar scale', (
    tester,
  ) async {
    final learner = LearnerController();
    await learner.createAndSave(name: 'Koka', grade: 1, energy: 30);
    final controller = LessonProgressController(
      learnerController: learner,
      mapProgress: MapProgressController(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LearnerScope(
          controller: learner,
          child: LessonProgressScope(
            controller: controller,
            child: const LessonCatalogScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('30%'), findsOneWidget);
    expect(find.byKey(const Key('grade-one-energy-indicator')), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      expect(find.byKey(Key('grade-one-energy-bar-$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('grade-one-energy-bar-3')), findsNothing);
  });

  testWidgets(
    'Lessons tab hides navigation during an activity and restores it on exit',
    (tester) async {
      final learner = LearnerController();
      await learner.createAndSave(name: 'Koka', grade: 1, energy: 60);
      await learner.seedLessonProgress(activeLessonId: 'g1_u1_l1');
      final controller = LessonProgressController(
        learnerController: learner,
        mapProgress: MapProgressController(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: LearnerScope(
            controller: learner,
            child: LessonProgressScope(
              controller: controller,
              child: const LessonCatalogScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppBottomTabNavigation), findsOneWidget);

      DevGLessonHostScope.of(
        tester.element(find.byType(LessonsScreen)),
      ).startSourceLevel(1);
      await tester.pump();
      expect(find.byType(LevelGamePage), findsOneWidget);
      expect(find.byType(AppBottomTabNavigation), findsNothing);

      await DevGLessonHostScope.of(
        tester.element(find.byType(LevelGamePage)),
      ).exitIncomplete();
      await tester.pump();
      expect(find.byType(LessonsScreen), findsOneWidget);
      expect(find.byType(AppBottomTabNavigation), findsOneWidget);
    },
  );

  testWidgets('continuing after lesson one opens the next lesson popup', (
    tester,
  ) async {
    final learner = LearnerController();
    await learner.createAndSave(name: 'Koka', grade: 1, energy: 60);
    await learner.seedLessonProgress(activeLessonId: 'g1_u1_l1');
    final controller = LessonProgressController(
      learnerController: learner,
      mapProgress: MapProgressController(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LearnerScope(
          controller: learner,
          child: LessonProgressScope(
            controller: controller,
            child: const LessonCatalogScreen(),
          ),
        ),
      ),
    );
    DevGLessonHostScope.of(
      tester.element(find.byType(LessonsScreen)),
    ).startSourceLevel(1);
    await tester.pump();

    final host = DevGLessonHostScope.of(
      tester.element(find.byType(LevelGamePage)),
    );
    await host.claimCompletion(
      const LessonScoreStats(
        lessonId: '1-1',
        totalActivities: 5,
        attempts: 5,
        correctAnswers: 5,
        mistakes: 0,
        accuracy: 100,
        bestAccuracy: 100,
        replayCount: 0,
        timeTakenMs: 30000,
        completionDate: null,
        completed: true,
        activities: [],
      ),
    );
    await host.continueToNextLesson!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(learner.profile!.lessonProgress.activeLessonId, 'g1_u1_l7');
    expect(find.byType(LevelGamePage), findsNothing);
    expect(find.byType(LessonsScreen), findsOneWidget);
    expect(
      find.byKey(const Key('lesson-start-popup-play-button')),
      findsOneWidget,
    );
    expect(find.byType(AppBottomTabNavigation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map-launched lesson continues into the Lessons gallery popup', (
    tester,
  ) async {
    final learner = LearnerController();
    await learner.createAndSave(name: 'Koka', grade: 1, energy: 60);
    await learner.seedLessonProgress(activeLessonId: 'g1_u1_l1');
    final controller = LessonProgressController(
      learnerController: learner,
      mapProgress: MapProgressController(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LearnerScope(
        controller: learner,
        child: LessonProgressScope(
          controller: controller,
          child: const MaterialApp(
            home: DevGLessonRunnerScreen(lessonId: 'g1_u1_l1'),
          ),
        ),
      ),
    );
    DevGLessonHostScope.of(
      tester.element(find.byType(LessonIntroPage)),
    ).startSourceLevel(1);
    await tester.pump();

    final host = DevGLessonHostScope.of(
      tester.element(find.byType(LevelGamePage)),
    );
    await host.claimCompletion(
      const LessonScoreStats(
        lessonId: '1-1',
        totalActivities: 5,
        attempts: 5,
        correctAnswers: 5,
        mistakes: 0,
        accuracy: 100,
        bestAccuracy: 100,
        replayCount: 0,
        timeTakenMs: 30000,
        completionDate: null,
        completed: true,
        activities: [],
      ),
    );
    await host.continueToNextLesson!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LessonCatalogScreen), findsOneWidget);
    expect(
      find.byKey(const Key('lesson-start-popup-play-button')),
      findsOneWidget,
    );
    expect(find.byType(AppBottomTabNavigation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Grade 3 catalogue helpers always expose the four approved lessons', () {
    AppData.configureHostedSession(
      grade: 3,
      energy: 60,
      unlockedLevels: const [1],
      completed: const <int>[],
      stickers: const <int, String>{},
      catalogLevels: const [1],
    );

    expect(AppData.catalogUnits.map((unit) => unit.number), [1, 2]);
    expect(AppData.catalogLevelsForUnit(AppData.unitForNumber(1)), [1, 3]);
    expect(AppData.catalogLevelsForUnit(AppData.unitForNumber(2)), [4, 5]);
    expect(AppData.catalogLevelCount, 4);
  });

  testWidgets(
    'a Grade 3 map catalog still shows all approved Grade 3 lessons',
    (tester) async {
      final learner = LearnerController();
      await learner.createAndSave(name: 'Koka', grade: 3, energy: 60);
      await learner.seedLessonProgress(activeLessonId: 'g3_u1_l1');
      final controller = LessonProgressController(
        learnerController: learner,
        mapProgress: MapProgressController(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: LearnerScope(
            controller: learner,
            child: LessonProgressScope(
              controller: controller,
              child: const DevGLessonCatalogHost(location: MapLocation.school),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LessonsScreen), findsOneWidget);
      expect(AppData.selectedGradeLevel, GradeLevel.grade3);
      expect(AppData.catalogUnits.map((unit) => unit.number), [1, 2]);
      expect(AppData.catalogLevelsForUnit(AppData.unitForNumber(1)), [1, 3]);
      expect(AppData.catalogLevelsForUnit(AppData.unitForNumber(2)), [4, 5]);
      expect(AppData.catalogLevelCount, 4);
    },
  );
}
