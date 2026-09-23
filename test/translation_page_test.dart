import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_search.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_word_grid_card.dart';
import 'package:tudloapp/features/translation/screens/translation_page.dart';
import 'package:tudloapp/features/translation/services/child_safety_filter.dart';
import 'package:tudloapp/features/translation/services/translation_history.dart';

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

  testWidgets('uses the model for Hiligaynon input when available', (
    tester,
  ) async {
    final hiligaynonRequests = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (_) async => 'maayong aga',
          translateHiligaynon: (text) async {
            hiligaynonRequests.add(text);
            return 'good morning from the model';
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Swap languages'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'maayong aga');
    await tester.pump();
    expect(find.text('good morning'), findsOneWidget);
    expect(hiligaynonRequests, isEmpty);

    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(hiligaynonRequests, ['maayong aga']);
    expect(find.text('good morning from the model'), findsOneWidget);
  });

  testWidgets('source chevron switches direction but keeps the text', (
    tester,
  ) async {
    final hiligaynonRequests = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (_) async => 'maayong aga',
          translateHiligaynon: (text) async {
            hiligaynonRequests.add(text);
            return 'good morning';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'maayong aga');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    await tester.tap(find.byTooltip('Switch input language'));
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Type Hiligaynon');
    expect(field.controller?.text, 'maayong aga');
    expect(hiligaynonRequests, ['maayong aga']);
    expect(find.text('good morning'), findsOneWidget);
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

  testWidgets('done moves the pair into a recent card and favorites', (
    tester,
  ) async {
    final history = TranslationHistory.instance..reset();
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(translateEnglish: (_) async => 'maayong aga'),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'good morning');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(find.byTooltip('Add to favorites'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
    expect(find.text('good morning'), findsOneWidget);
    expect(find.text('maayong aga'), findsOneWidget);
    expect(history.recents.single.target, 'maayong aga');

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    expect(history.favorites, hasLength(1));
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    history.reset();
  });

  testWidgets('swiping a recent card removes it or saves it', (tester) async {
    final history = TranslationHistory.instance..reset();
    const first = TranslationEntry(
      source: 'day',
      target: 'adlaw',
      fromEnglish: true,
    );
    const second = TranslationEntry(
      source: 'night',
      target: 'gab-i',
      fromEnglish: true,
    );
    history
      ..addRecent(first)
      ..addRecent(second);
    await tester.pumpWidget(
      MaterialApp(home: TranslationPage(translateEnglish: (_) async => '')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('gab-i'), findsOneWidget);
    expect(find.text('adlaw'), findsOneWidget);

    await tester.drag(find.text('gab-i'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('gab-i'), findsNothing);
    expect(history.recents, [first]);
    expect(history.favorites, isEmpty);

    await tester.drag(find.text('adlaw'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('adlaw'), findsOneWidget);
    expect(history.recents, [first]);
    expect(history.favorites, [first]);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    history.reset();
  });

  test('recents expire after the TTL and are not persisted', () {
    var now = DateTime(2026, 1, 1, 12);
    final history = TranslationHistory(clock: () => now);
    const entry = TranslationEntry(
      source: 'day',
      target: 'adlaw',
      fromEnglish: true,
    );
    history.addRecent(entry);
    expect(history.recents, [entry]);

    now = now.add(TranslationHistory.recentTtl + const Duration(seconds: 1));
    expect(history.recents, isEmpty);
    history.dispose();
  });

  test('matches unsafe whole words without blocking safe substrings', () {
    expect(ChildSafetyFilter.isUnsafe('YAWA!'), isTrue);
    expect(ChildSafetyFilter.isUnsafe('f@ck!'), isTrue);
    expect(ChildSafetyFilter.isUnsafe('I'), isFalse);
    expect(ChildSafetyFilter.isUnsafe('classroom grass'), isFalse);
  });

  testWidgets(
    'the meaning drawer lists every dictionary word in the Hiligaynon text',
    (tester) async {
      // The card's dictionary action awaits a tap sound first, so without an
      // audio platform that await never completes and the sheet never opens.
      // Attaching without a controller is the hosted-silent path: the await
      // resolves immediately and no player is ever built.
      AppAudioService.instance.attach(null);
      addTearDown(AppAudioService.instance.detach);
      final history = TranslationHistory.instance..reset();
      await tester.pumpWidget(
        MaterialApp(
          home: TranslationPage(
            translateEnglish: (_) async => 'maayong aga sa imo balay',
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'good morning');
      await tester.pump(const Duration(milliseconds: 451));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Dictionary').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Several words are found, wherever they sit in the phrase -- not just
      // a leading one -- and each gets its own dictionary card.
      final cards = find.byType(DictionaryWordGridCard);
      expect(cards, findsWidgets);
      expect(tester.widgetList(cards).length, greaterThan(1));
      final words = tester
          .widgetList<DictionaryWordGridCard>(cards)
          .map((card) => stripAccentsLower(card.entry.word))
          .toList();
      expect(words, contains('aga'));
      expect(words, contains('balay'));
      expect(words, contains('imo'));
      // Cancels the recents TTL timer the added pair started.
      history.reset();
    },
  );

  testWidgets('the header shows the translate wordmark beside its button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: TranslationPage(translateEnglish: (_) async => 'aga')),
    );
    await tester.pump();

    final wordmark = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/images/translate_title.png',
    );
    expect(wordmark, findsOneWidget);
    final button = find.byTooltip('Favorites and recents');
    expect(button, findsOneWidget);

    // Centred on the screen, not merely placed right of the button: its
    // midpoint sits on the screen's, within a pixel.
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final box = tester.getRect(wordmark);
    expect(box.center.dx, closeTo(screenWidth / 2, 1));
    expect(box.left, greaterThan(tester.getRect(button).right));
    expect(tester.takeException(), isNull);
  });
}
