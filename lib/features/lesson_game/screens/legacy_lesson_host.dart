import 'package:flutter/material.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

/// Supplies the lesson host contract for the standalone app.
///
/// Lessons are hosted everywhere now: Tudlo's learner flow provides its own
/// host, and this one lets the original app shell keep its behaviour without
/// the lesson screens having to know either shell exists.
class LegacyLessonHost extends StatelessWidget {
  final int level;

  const LegacyLessonHost({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return DevGLessonHostScope(
      startSourceLevel: (sourceLevel) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LegacyLessonHost(level: sourceLevel)),
      ),
      // Leaving early just unwinds to whatever opened the lesson.
      exitIncomplete: () async => Navigator.pop(context),
      // Finishing returns to the lesson dashboard tab, rebuilt so it picks up
      // the progress this attempt just wrote.
      exitAfterCompletion: () async => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 2)),
        (route) => false,
      ),
      // AppData already recorded the score here; Tudlo's host is the one that
      // needs a separate claim step.
      claimCompletion: (_) async {},
      child: LevelGamePage(level: level),
    );
  }
}
