import 'package:flutter/widgets.dart';

import 'package:tudloapp/features/lesson/presentation/devg_lesson_host.dart';

/// Stable Tudlo route name for the original DevG intro and activity flow.
///
/// Callers keep one route target while the host renders the supplied DevG
/// visual intro, then its original game mechanics and reward screen.
class LessonIntroScreen extends StatelessWidget {
  const LessonIntroScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context) =>
      DevGLessonRunnerScreen(lessonId: lessonId);
}
