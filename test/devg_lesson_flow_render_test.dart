import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_mapping.dart';

/// The exception the test actually cares about.
///
/// Fonts are fetched at runtime by google_fonts and are not bundled, so with
/// fetching disabled every screen reports a missing font. That says nothing
/// about whether a lesson mounts, so it is filtered out here rather than
/// letting it mask -- or be mistaken for -- a real failure.
Object? _renderException(WidgetTester tester) {
  final error = tester.takeException();
  if (error != null && error.toString().contains('GoogleFonts')) return null;
  return error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // These lessons are being checked for layout, not typography or audio.
    // Left alone, google_fonts reaches for the network and audioplayers for
    // a platform that does not exist under `flutter test`, and both surface
    // as exceptions that have nothing to do with what this test asserts.
    GoogleFonts.config.allowRuntimeFetching = false;
    // These lessons run under a host, which owns audio. Attaching without a
    // controller is what a host does before one resolves, and keeps the
    // lessons silent instead of falling back to this service's own players.
    AppAudioService.instance.attach(null);
    addTearDown(AppAudioService.instance.detach);
    // Lessons that save an in-progress attempt reach for shared_preferences.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lesson loading card fits a short landscape viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 312);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppData.configureHostedSession(
      grade: 3,
      energy: 60,
      unlockedLevels: const [1],
      completed: const <int>[],
      stickers: const <int, String>{},
      catalogLevels: const [1],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          notifier: AppState()..username = 'Koka',
          child: const LevelGamePage(level: 1),
        ),
      ),
    );

    expect(find.text('Ginakuha ang leksiyon...'), findsOneWidget);
    expect(_renderException(tester), isNull);
  });

  testWidgets('lesson result scrolls above its actions in short landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 312);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonResultPage(
            backgroundAsset:
                'assets/images/level_game/backgrounds/classroom.svg',
            fullscreenResult: true,
            accuracy: 100,
            mistakes: 0,
            durationLabel: '1:00',
            onBackToMap: () {},
            onContinue: () {},
          ),
        ),
      ),
    );

    expect(find.text('Natapos mo na ang Leksyon!'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    expect(
      find.byKey(const Key('lesson-result-gallery-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('lesson-result-continue-button')),
      findsOneWidget,
    );
    expect(_renderException(tester), isNull);
  });

  testWidgets('all twelve preserved DevG activities mount in the Tudlo host', (
    tester,
  ) async {
    // The app locks portrait, so mount these at a real phone size. The
    // binding's default 800x600 landscape is a shape the lessons never have
    // to lay out for, and it overflows some of them by a pixel or two.
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final lesson in LessonCatalog.all) {
      final sourceLevel = DevGLessonMapping.sourceLevelFor(lesson);
      AppData.configureHostedSession(
        grade: lesson.grade,
        energy: 60,
        unlockedLevels: [sourceLevel],
        completed: const <int>[],
        stickers: const <int, String>{},
        catalogLevels: [sourceLevel],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            notifier: AppState()..username = 'Koka',
            child: DevGLessonHostScope(
              startSourceLevel: (_) {},
              exitIncomplete: () async {},
              exitAfterCompletion: () async {},
              claimCompletion: (_) async {},
              child: LevelGamePage(
                key: ValueKey<String>(lesson.id),
                level: sourceLevel,
              ),
            ),
          ),
        ),
      );
      // Content loading awaits real asset-bundle file I/O (dictionary JSON,
      // lesson bank data). The automated test binding's fake clock never
      // lets that real I/O resolve via tester.pump() alone, so every lesson
      // hangs on the loading card forever without this real-time wait.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Ginakuha ang leksiyon...'),
        findsNothing,
        reason: '${lesson.id} should leave the source loading card.',
      );
      expect(
        _renderException(tester),
        isNull,
        reason: '${lesson.id} should render through the Tudlo adapters.',
      );
    }
  });
}
