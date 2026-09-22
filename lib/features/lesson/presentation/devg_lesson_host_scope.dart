import 'package:flutter/widgets.dart';

import 'package:tudloapp/core/models/lesson_score.dart';

/// Boundary between preserved DevG visuals/mechanics and Tudlo application
/// ownership. Source screens call these semantic intents; they never navigate
/// to a DevG shell or write progress themselves.
class DevGLessonHostScope extends InheritedWidget {
  const DevGLessonHostScope({
    required this.startSourceLevel,
    required this.exitIncomplete,
    required this.exitAfterCompletion,
    required this.claimCompletion,
    required super.child,
    super.key,
  });

  final void Function(int sourceLevel) startSourceLevel;
  final Future<void> Function() exitIncomplete;
  final Future<void> Function() exitAfterCompletion;
  final Future<void> Function(LessonScoreStats score) claimCompletion;

  static DevGLessonHostScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DevGLessonHostScope>();

  static DevGLessonHostScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'A preserved DevG lesson requires a Tudlo host.');
    return scope!;
  }

  @override
  bool updateShouldNotify(DevGLessonHostScope oldWidget) => false;
}
