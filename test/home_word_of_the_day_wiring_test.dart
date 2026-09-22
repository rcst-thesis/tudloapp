import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/home/presentation/screens/home_screen.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';

Future<LearnerController> _controllerWithProfile() async {
  final controller = LearnerController();
  await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);
  return controller;
}

Widget _wrap(LearnerController controller) {
  return MaterialApp(
    home: LearnerScope(controller: controller, child: const HomeScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    "Home shows the learner's already-recorded word-of-the-day, not the "
    'hardcoded placeholder',
    (tester) async {
      setViewport(tester);
      final controller = await _controllerWithProfile();
      // "balay" is one of the eligible word-of-the-day entries. This test
      // records it explicitly, so Home must show that recorded word rather
      // than resolving a fresh one.
      await controller.recordWordOfTheDay(
        id: 'balay',
        date: DateTime.now(),
        history: {'balay'},
      );

      await tester.pumpWidget(_wrap(controller));
      await tester.pump();

      expect(find.text('balay'), findsOneWidget);
      expect(find.text('naga istar ako sa akon balay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home resolves and persists a word-of-the-day when none is recorded '
    'yet',
    (tester) async {
      setViewport(tester);
      final controller = await _controllerWithProfile();
      expect(controller.profile!.wordOfTheDayId, isNull);

      await tester.pumpWidget(_wrap(controller));
      await tester.pump();

      // Home shuffles the eligible pool, so assert what must hold for any
      // pick: it persisted one of the entries it is allowed to choose.
      final eligibleIds = DictionaryWords.all
          .where((entry) => entry.frontCardImage != null)
          .map((entry) => entry.id)
          .toSet();
      expect(eligibleIds, isNotEmpty);
      expect(controller.profile!.wordOfTheDayId, isNotNull);
      expect(eligibleIds, contains(controller.profile!.wordOfTheDayId));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "Home's heart already reflects a word favorited from the Dictionary",
    (tester) async {
      setViewport(tester);
      final controller = await _controllerWithProfile();
      await controller.recordWordOfTheDay(
        id: 'balay',
        date: DateTime.now(),
        history: {'balay'},
      );
      await controller.toggleFavoriteWord('balay');

      await tester.pumpWidget(_wrap(controller));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    },
  );

  testWidgets(
    "Tapping Home's heart toggles the same favorites set the Dictionary "
    'reads',
    (tester) async {
      setViewport(tester);
      final controller = await _controllerWithProfile();
      await controller.recordWordOfTheDay(
        id: 'balay',
        date: DateTime.now(),
        history: {'balay'},
      );
      expect(controller.profile!.favoritedWords, isEmpty);

      await tester.pumpWidget(_wrap(controller));
      await tester.pump();

      await tester.tap(find.byKey(const Key('home-word-favorite-button')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.profile!.favoritedWords, contains('balay'));
      expect(tester.takeException(), isNull);
    },
  );
}
