import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/translation/screens/translation_page.dart';
import 'package:tudloapp/features/translation/services/child_safety_filter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DictionaryData.initialize();
    await ChildSafetyFilter.initialize();
  });

  setUp(() {
    AppData.translateHelpDone = true;
    AppData.profanityFilterEnabledNotifier.value = true;
    AppData.dictionaryFallbackEnabledNotifier.value = true;
  });

  testWidgets('uses the model for known phrases', (tester) async {
    final requests = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (text) async {
            requests.add(text);
            return 'maayong aga';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'good morning');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();

    expect(requests, ['good morning']);
    expect(find.text('maayong aga'), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
  });

  testWidgets('swaps the translated text into Hiligaynon input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(translateEnglish: (_) async => 'maayong aga'),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'good morning');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    await tester.tap(find.byTooltip('Swap languages'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Type Hiligaynon');
    expect(field.controller?.text, 'maayong aga');
    expect(find.text('good morning'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ari ako sa balay');
    await tester.pump();
    expect(find.text('I am at home'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ako, balay!');
    await tester.pump();
    expect(find.text('I, house; home!'), findsOneWidget);
  });

  testWidgets('debounces NMT and ignores stale results', (tester) async {
    final requests = <String>[];
    final completions = <Completer<String>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (text) {
            requests.add(text);
            final completion = Completer<String>();
            completions.add(completion);
            return completion.future;
          },
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      'Type English',
    );
    await tester.enterText(find.byType(TextField), 'qzxv blorf');
    await tester.pump(const Duration(milliseconds: 449));
    expect(requests, isEmpty);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(requests, ['qzxv blorf']);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wugga zibble');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    completions.first.complete('stale result');
    await tester.pump();

    expect(find.text('stale result'), findsNothing);
    expect(requests, ['qzxv blorf', 'wugga zibble']);

    completions.last.complete('bag-o nga sabat');
    await tester.pump();
    expect(find.text('bag-o nga sabat'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('blocks unsafe input and model output', (tester) async {
    var nmtCalls = 0;
    var modelOutput = 'safe';
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (text) async {
            nmtCalls++;
            return modelOutput;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'f@ck!');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(ChildSafetyFilter.blockedMessage), findsOneWidget);
    expect(nmtCalls, 0);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Listen').first,
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'qzxv blorf');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(nmtCalls, 1);

    modelOutput = 'yawa';
    await tester.enterText(find.byType(TextField), 'wugga zibble');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(find.text(ChildSafetyFilter.blockedMessage), findsOneWidget);
    expect(find.text('yawa'), findsNothing);
  });

  testWidgets('allows unsafe text when the profanity filter is off', (
    tester,
  ) async {
    AppData.profanityFilterEnabledNotifier.value = false;
    await tester.pumpWidget(
      MaterialApp(home: TranslationPage(translateEnglish: (_) async => 'yawa')),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'f@ck!');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();

    expect(find.text('yawa'), findsOneWidget);
    expect(find.text(ChildSafetyFilter.blockedMessage), findsNothing);
  });

  testWidgets('uses dictionary fallback only when enabled', (tester) async {
    Future<String> failModel(String _) => Future.error('offline');
    await tester.pumpWidget(
      MaterialApp(home: TranslationPage(translateEnglish: failModel)),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'good morning');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(find.text('maayong aga'), findsOneWidget);

    AppData.dictionaryFallbackEnabledNotifier.value = false;
    await tester.enterText(find.byType(TextField), 'good afternoon');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(find.text('maayong hapon'), findsNothing);
    expect(
      find.text('Offline translation unavailable. Try again.'),
      findsOneWidget,
    );
  });

  test('matches unsafe whole words without blocking safe substrings', () {
    expect(ChildSafetyFilter.isUnsafe('YAWA!'), isTrue);
    expect(ChildSafetyFilter.isUnsafe('f@ck!'), isTrue);
    expect(ChildSafetyFilter.isUnsafe('I'), isFalse);
    expect(ChildSafetyFilter.isUnsafe('classroom grass'), isFalse);
  });
}
