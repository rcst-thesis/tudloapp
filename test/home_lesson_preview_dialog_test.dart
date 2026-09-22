import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_preview_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  required HomeLessonStatus status,
  required VoidCallback onRetry,
  required VoidCallback onStart,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showHomeLessonPreviewDialog(
                context: context,
                lesson: HomeLessonPreview(
                  unitTitle: 'yunit 2',
                  category: 'MGA KULAY',
                  status: status,
                ),
                originRect: const Rect.fromLTWH(0, 0, 100, 100),
                onRetry: onRetry,
                onStart: onStart,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

double _unavailableNoticeOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.byKey(const Key('lesson-preview-action-unavailable-notice')),
    )
    .opacity;

void main() {
  testWidgets(
    'retry is unavailable for a lesson that has never been finished -- '
    'tapping it shows a notice instead of firing onRetry',
    (tester) async {
      var retried = false;
      await _openDialog(
        tester,
        status: HomeLessonStatus.available,
        onRetry: () => retried = true,
        onStart: () {},
      );

      expect(_unavailableNoticeOpacity(tester), 0);

      await tester.tap(find.byKey(const Key('lesson-preview-retry-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(retried, isFalse);
      expect(_unavailableNoticeOpacity(tester), 1);
      expect(find.text('wala pa natapos ang lesson'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retry fires onRetry for a lesson that has already been done', (
    tester,
  ) async {
    var retried = false;
    await _openDialog(
      tester,
      status: HomeLessonStatus.completed,
      onRetry: () => retried = true,
      onStart: () {},
    );

    await tester.tap(find.byKey(const Key('lesson-preview-retry-button')));
    await tester.pump();

    expect(retried, isTrue);
    expect(_unavailableNoticeOpacity(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suguran ta still fires onStart', (tester) async {
    var started = false;
    await _openDialog(
      tester,
      status: HomeLessonStatus.available,
      onRetry: () {},
      onStart: () => started = true,
    );

    await tester.tap(find.byKey(const Key('lesson-preview-start-button')));
    await tester.pump();

    expect(started, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'suguran ta is unavailable for a locked lesson (previous lesson not '
    'finished yet) -- tapping it shows a notice instead of firing onStart',
    (tester) async {
      var started = false;
      await _openDialog(
        tester,
        status: HomeLessonStatus.locked,
        onRetry: () {},
        onStart: () => started = true,
      );

      expect(_unavailableNoticeOpacity(tester), 0);

      await tester.tap(find.byKey(const Key('lesson-preview-start-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(started, isFalse);
      expect(_unavailableNoticeOpacity(tester), 1);
      expect(find.text('tapusa anay ang una nga lesson'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('suguran ta still fires onStart for a completed lesson', (
    tester,
  ) async {
    var started = false;
    await _openDialog(
      tester,
      status: HomeLessonStatus.completed,
      onRetry: () {},
      onStart: () => started = true,
    );

    await tester.tap(find.byKey(const Key('lesson-preview-start-button')));
    await tester.pump();

    expect(started, isTrue);
    expect(tester.takeException(), isNull);
  });
}
