import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';
import 'package:tudloapp/vendor/devg/core/data/app_data.dart';
import 'package:tudloapp/vendor/devg/core/state/app_state.dart';
import 'package:tudloapp/vendor/devg/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_mapping.dart';

void main() {
  testWidgets('all twelve preserved DevG activities mount in the Tudlo host', (
    tester,
  ) async {
    for (final lesson in LessonCatalog.all) {
      final sourceLevel = DevGLessonMapping.sourceLevelFor(lesson);
      AppData.configure(
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
            notifier: AppState(username: 'Koka'),
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
        tester.takeException(),
        isNull,
        reason: '${lesson.id} should render through the Tudlo adapters.',
      );
    }
  });
}
