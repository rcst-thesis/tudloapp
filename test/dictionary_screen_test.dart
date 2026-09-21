import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_words.dart';
import 'package:tudloapp/features/dictionary/presentation/screens/dictionary_browse_screen.dart';
import 'package:tudloapp/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_bento_grid.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_header.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_heart_icon.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_lookup_page.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_word_grid_card.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';

/// A small, fixed dataset for these widget tests -- deliberately not
/// [DictionaryWords.all] (real, ~900-word content that changes over time
/// and isn't something tests should be coupled to). Mirrors the shape of
/// the old placeholder dataset so every existing assertion (ids, examples,
/// categories, the "animals" chip being in the chips row's initial scroll
/// viewport, "balay" being the only art-eligible entry) still holds.
const _testEntries = [
  DictionaryEntry(
    id: 'balay',
    word: 'balay',
    phonetic: '/ba-lay/',
    definition:
        'n. ang balay ay isa ka pisikal nga tinukod ukon estraktura nga '
        'gindesinyo kag gintukod para istaran sang mga tawo.',
    example: 'naga istar ako sa akon balay',
    category: 'home',
    frontCardImage: 'assets/images/balay_dictionary.png',
    favThumbImage: 'assets/images/balay_dictionary_fav_thumb.png',
  ),
  DictionaryEntry(
    id: 'ido',
    word: 'ido',
    phonetic: '/i-do/',
    definition: 'n. ang ido isa ka sapat nga sagad ginabantayan sang tawo.',
    example: 'nagahulat ang akon ido sa balay',
    category: 'animals',
  ),
  DictionaryEntry(
    id: 'kuring',
    word: 'kuring',
    phonetic: '/ku-ring/',
    definition:
        'n. ang kuring isa ka gamay nga sapat nga sagad ginaatipan '
        'sa balay.',
    example: 'nagatulog ang kuring sa ibabaw sang lamesa',
    category: 'animals',
  ),
  DictionaryEntry(
    id: 'iloy',
    word: 'iloy',
    phonetic: '/i-loy/',
    definition: 'n. ang iloy amo ang babaye nga ginikanan.',
    example: 'nagabasa sang libro ang akon iloy para sa akon',
    category: 'family',
  ),
  DictionaryEntry(
    id: 'amay',
    word: 'amay',
    phonetic: '/a-may/',
    definition: 'n. ang amay amo ang lalaki nga ginikanan.',
    example: 'nagatudlo ang akon amay sa akon magbisikleta',
    category: 'family',
  ),
  DictionaryEntry(
    id: 'tubig',
    word: 'tubig',
    phonetic: '/tu-big/',
    definition: 'n. ang tubig isa ka likido nga kinahanglanon sa kabuhi.',
    example: 'nagainom ako sang tubig kada adlaw',
    category: 'nature',
  ),
  DictionaryEntry(
    id: 'uma',
    word: 'uma',
    phonetic: '/u-ma/',
    definition: 'n. ang uma isa ka lugar nga ginatamnan sang mga pananom.',
    example: 'nagatrabaho ang akon lolo sa uma',
    category: 'nature',
  ),
  DictionaryEntry(
    id: 'kan-on',
    word: 'kan-on',
    phonetic: '/kan-on/',
    definition: 'n. ang kan-on isa ka pagkaon nga halin sa bugas.',
    example: 'nagakaon kami sang kan-on sa paniudto',
    category: 'food',
  ),
  DictionaryEntry(
    id: 'tinapay',
    word: 'tinapay',
    phonetic: '/ti-na-pay/',
    definition: 'n. ang tinapay isa ka pagkaon nga ginluto halin sa arina.',
    example: 'nagapamalit kami sang tinapay sa tinda',
    category: 'food',
  ),
  DictionaryEntry(
    id: 'simbahan',
    word: 'simbahan',
    phonetic: '/sim-ba-han/',
    definition:
        'n. ang simbahan isa ka lugar nga ginasimbahan sang mga '
        'tawo.',
    example: 'nagasimba kami sa simbahan kada Domingo',
    category: 'places',
  ),
  DictionaryEntry(
    id: 'parke',
    word: 'parke',
    phonetic: '/par-ke/',
    definition: 'n. ang parke isa ka lugar nga ginadulaan sang mga bata.',
    example: 'nagadula kami sa parke pagkatapos sang klase',
    category: 'places',
  ),
  DictionaryEntry(
    id: 'eskwelahan',
    word: 'eskwelahan',
    phonetic: '/es-kwe-la-han/',
    definition:
        'n. ang eskwelahan isa ka lugar nga ginatun-an sang mga '
        'bata.',
    example: 'nagatambong ako sa eskwelahan kada adlaw',
    category: 'places',
  ),
];

Future<LearnerController> _controllerWithProfile() async {
  final controller = LearnerController();
  await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);
  // Pin word-of-the-day to "balay" so existing tests stay deterministic --
  // without this, resolveWordOfTheDay would pick a random pool entry on
  // first render since no rotation history is stored yet.
  await controller.recordWordOfTheDay(
    id: 'balay',
    date: DateTime.now(),
    history: {'balay'},
  );
  // Pin the featured tray to "balay" too (today's only art-eligible entry
  // for the featured slot) so existing tests stay deterministic.
  await controller.recordFeatured(
    ids: ['balay'],
    date: DateTime.now(),
    history: {'balay'},
  );
  return controller;
}

Widget _wrap(Widget child, LearnerController controller) {
  return MaterialApp(
    home: LearnerScope(controller: controller, child: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setLargeViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Dictionary screen renders header, search, word card, and favorites',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dictionary-header')), findsOneWidget);
      expect(find.byKey(const Key('dictionary-search-field')), findsOneWidget);
      expect(find.byKey(const Key('dictionary-word-card')), findsOneWidget);
      expect(find.text('my favorites'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dictionary bottom nav renders at index 4', (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    final nav = tester.widget<AppBottomTabNavigation>(
      find.byType(AppBottomTabNavigation),
    );
    expect(nav.currentIndex, 4);
  });

  testWidgets(
    'Main screen search bar is a decoy -- typing does nothing, tapping it opens the browse screen',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dictionary-search-field')),
        'ido',
      );
      await tester.pumpAndSettle();
      // readOnly: typed text never lands in the field.
      final field = tester.widget<TextField>(
        find.byKey(const Key('dictionary-search-field')),
      );
      expect(field.controller, isNull);

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
    },
  );

  testWidgets('Tapping the word-of-the-day card flips to the back face', (
    tester,
  ) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('naga istar ako sa akon balay'), findsNothing);

    await tester.tap(find.byKey(const Key('dictionary-word-card')));
    await tester.pumpAndSettle();

    expect(find.text('naga istar ako sa akon balay'), findsOneWidget);
  });

  testWidgets(
    'Favoriting the word-of-the-day toggles the heart and persists on the learner',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      // Flip to the back face where the favorite button lives.
      await tester.tap(find.byKey(const Key('dictionary-word-card')));
      await tester.pumpAndSettle();

      expect(controller.profile!.favoritedWords, isEmpty);
      expect(
        tester
            .widget<DictionaryHeartIcon>(find.byType(DictionaryHeartIcon))
            .favorited,
        isFalse,
      );

      await tester.tap(
        find.byKey(const Key('dictionary-word-favorite-button')),
      );
      await tester.pumpAndSettle();

      expect(controller.profile!.favoritedWords, contains('balay'));
      expect(
        tester
            .widget<DictionaryHeartIcon>(find.byType(DictionaryHeartIcon))
            .favorited,
        isTrue,
      );
    },
  );

  testWidgets(
    'Browse screen shows a featured bento tile and a catalog card for every word',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
      expect(
        find.byKey(const Key('dictionary-bento-tile-balay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dictionary-catalog-card-ido')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dictionary-catalog-card-balay')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'The full, unfiltered catalog only builds cards near the viewport '
    '(regression: shrinkWrap + NeverScrollableScrollPhysics previously '
    'forced all ~940 cards to build immediately on first open)',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      // The real, full dataset -- not the small test fixture -- since the
      // bug only manifests with a catalog large enough that eagerly building
      // every card is actually expensive.
      await tester.pumpWidget(
        _wrap(const DictionaryBrowseScreen(), controller),
      );
      await tester.pumpAndSettle();

      final builtCards = find.byType(DictionaryWordGridCard).evaluate().length;
      expect(builtCards, lessThan(DictionaryWords.all.length));
    },
  );

  testWidgets(
    'Search bar and category chips stay put while the catalog scrolls '
    '(fixed above the scroll view, not part of it)',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryBrowseScreen(), controller),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dictionary-browse-search-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dictionary-category-chips')),
        findsOneWidget,
      );

      final scrollable = find
          .descendant(
            of: find.byKey(const Key('dictionary-browse-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dictionary-browse-search-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dictionary-category-chips')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'A category with more words than the preview cap shows a "see all" '
    "link, which selects that category (same as tapping its chip)",
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      // "general" has 257 words in the real dataset -- comfortably over the
      // 6-word preview cap.
      await tester.pumpWidget(
        _wrap(const DictionaryBrowseScreen(), controller),
      );
      await tester.pumpAndSettle();

      final seeAllGeneral = find.byKey(const Key('dictionary-see-all-general'));
      await tester.scrollUntilVisible(
        seeAllGeneral,
        500,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('dictionary-browse-scroll-view')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(seeAllGeneral, findsOneWidget);

      await tester.tap(seeAllGeneral);
      await tester.pumpAndSettle();

      // Selecting via "see all" is the same as tapping the category chip --
      // the chip now shows "general" as selected, and the cap no longer
      // applies (no "see all" link left, since only one category is shown).
      expect(find.byKey(const Key('dictionary-see-all-general')), findsNothing);
    },
  );

  testWidgets(
    'Selecting a word in the browse screen shows its card inline, without leaving the screen',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-catalog-card-ido')));
      await tester.pumpAndSettle();

      // Still the browse screen -- just showing the selected word's plain
      // lookup page now, not the flip card.
      expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
      expect(find.byType(DictionaryLookupPage), findsOneWidget);
      expect(find.byKey(const Key('dictionary-browse-list')), findsNothing);
    },
  );

  testWidgets(
    'Typing in the browse screen\'s own search bar filters the catalog',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dictionary-browse-search-field')),
        'ido',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dictionary-catalog-card-ido')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dictionary-catalog-card-balay')),
        findsNothing,
      );
      // Featured section hides while actively searching.
      expect(find.byType(DictionaryBentoGrid), findsNothing);
    },
  );

  testWidgets('Clearing a search restores the full catalog '
      '(regression: filtered/grouped results were cached, must not go stale)', (
    tester,
  ) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('dictionary-browse-search-field')),
      'ido',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('dictionary-browse-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dictionary-catalog-card-ido')),
      findsOneWidget,
    );
  });

  testWidgets('Typing a prefix shows a faded inline autocomplete suggestion', (
    tester,
  ) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    // "balay" is the only fixture word starting with "bal".
    await tester.enterText(
      find.byKey(const Key('dictionary-browse-search-field')),
      'bal',
    );
    await tester.pumpAndSettle();

    final ghost = tester.widget<Text>(
      find.byKey(const Key('dictionary-search-ghost-text')),
    );
    final spans = (ghost.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans[0].text, 'bal');
    expect(spans[1].text, 'ay');
  });

  testWidgets(
    'The autocomplete suggestion disappears once the query exactly matches a word',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dictionary-browse-search-field')),
        'balay',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dictionary-search-ghost-text')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'The search field keeps its live element (and keyboard connection) '
    'when the ghost suggestion appears and disappears mid-typing '
    '(regression: swapping between a bare TextField and a Stack-wrapped '
    "one tore down the field's keyboard connection, dismissing the "
    'keyboard out from under the learner)',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      final fieldFinder = find.byKey(
        const Key('dictionary-browse-search-field'),
      );

      // "bal" has a plausible completion ("balay") -- ghost text shows.
      await tester.enterText(fieldFinder, 'bal');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dictionary-search-ghost-text')),
        findsOneWidget,
      );
      final editableTextBefore = tester.state<EditableTextState>(
        find.descendant(of: fieldFinder, matching: find.byType(EditableText)),
      );

      // "balay" exactly matches -- ghost text disappears, changing the
      // search bar's internal tree shape.
      await tester.enterText(fieldFinder, 'balay');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dictionary-search-ghost-text')),
        findsNothing,
      );

      final editableTextAfter = tester.state<EditableTextState>(
        find.descendant(of: fieldFinder, matching: find.byType(EditableText)),
      );
      expect(
        identical(editableTextBefore, editableTextAfter),
        isTrue,
        reason:
            "the search field's element must survive the ghost text "
            'toggling on and off, not be torn down and recreated',
      );
    },
  );

  testWidgets(
    'The decoy search bar on the main screen never shows an autocomplete suggestion',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      // Decoy bar is readOnly -- enterText can't actually put text in it, but
      // confirm there's no ghost-text layer at all regardless.
      expect(
        find.byKey(const Key('dictionary-search-ghost-text')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'A typo\'d search shows "did you mean" suggestions, tapping one opens its definition',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      // "balat" is a one-letter typo of "balay" -- no exact/substring match,
      // but close enough to suggest.
      await tester.enterText(
        find.byKey(const Key('dictionary-browse-search-field')),
        'balat',
      );
      await tester.pumpAndSettle();

      expect(find.text('no words found'), findsOneWidget);
      expect(find.text('did you mean:'), findsOneWidget);
      expect(
        find.byKey(const Key('dictionary-suggestion-balay')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('dictionary-suggestion-balay')));
      await tester.pumpAndSettle();

      expect(find.byType(DictionaryLookupPage), findsOneWidget);
    },
  );

  testWidgets('A search with no close matches shows no suggestions', (
    tester,
  ) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('dictionary-browse-search-field')),
      'zzzzzzzzzz',
    );
    await tester.pumpAndSettle();

    expect(find.text('no words found'), findsOneWidget);
    expect(find.text('did you mean:'), findsNothing);
  });

  testWidgets(
    'Searching a term that only appears in a definition still finds that word',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      // "tawo" (person) appears in balay's definition but isn't a word
      // itself.
      await tester.enterText(
        find.byKey(const Key('dictionary-browse-search-field')),
        'tawo',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dictionary-catalog-card-balay')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Category chip narrows the catalog to that category', (
    tester,
  ) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    // "animals" is within the chip row's initial scroll viewport; "food"
    // contains kan-on/tinapay, not ido.
    await tester.tap(find.byKey(const Key('dictionary-category-chip-animals')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dictionary-catalog-card-ido')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dictionary-catalog-card-balay')),
      findsNothing,
    );
  });

  testWidgets('Browse screen also shows the bottom nav at index 4', (
    tester,
  ) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    final navs = tester.widgetList<AppBottomTabNavigation>(
      find.byType(AppBottomTabNavigation),
    );
    expect(navs, isNotEmpty);
    expect(navs.every((nav) => nav.currentIndex == 4), isTrue);
  });

  testWidgets(
    'Back pill returns to the catalog from a word\'s detail, then exits the browse screen',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-catalog-card-ido')));
      await tester.pumpAndSettle();
      expect(find.byType(DictionaryLookupPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('dictionary-browse-back-pill')));
      await tester.pumpAndSettle();
      expect(find.byType(DictionaryLookupPage), findsNothing);
      expect(find.byKey(const Key('dictionary-browse-list')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dictionary-browse-back-pill')));
      await tester.pumpAndSettle();
      expect(find.byType(DictionaryBrowseScreen), findsNothing);
    },
  );

  testWidgets('Back pill and search bar are the same height', (tester) async {
    await setLargeViewport(tester);
    final controller = await _controllerWithProfile();
    await tester.pumpWidget(
      _wrap(const DictionaryScreen(entries: _testEntries), controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dictionary-search-bar-tap')));
    await tester.pumpAndSettle();

    final backPillHeight = tester
        .getSize(find.byKey(const Key('dictionary-browse-back-pill')))
        .height;
    final searchFieldHeight = tester
        .getSize(find.byKey(const Key('dictionary-browse-search-field')))
        .height;
    expect(backPillHeight, closeTo(searchFieldHeight, 0.5));
  });

  testWidgets(
    'Bento tray shows just a single hero compartment when only one entry is featured',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      const entries = [
        DictionaryEntry(
          id: 'solo',
          word: 'solo',
          phonetic: '/so-lo/',
          definition: 'n. test entry.',
          example: 'test',
          category: 'test',
          favThumbImage: 'assets/images/home_sticker_house.png',
        ),
      ];
      await tester.pumpWidget(
        _wrap(const DictionaryBrowseScreen(entries: entries), controller),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dictionary-bento-tile-solo')),
        findsOneWidget,
      );
      // No blank/placeholder compartments -- the tray only ever renders as
      // many tappable compartments as there are real entries.
      expect(
        find.descendant(
          of: find.byType(DictionaryBentoGrid),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Bento tray grows a compartment per entry, up to all of them, with no blanks',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      const entries = [
        DictionaryEntry(
          id: 'one',
          word: 'one',
          phonetic: '/one/',
          definition: 'n. test entry one.',
          example: 'test',
          category: 'test',
          favThumbImage: 'assets/images/home_sticker_house.png',
        ),
        DictionaryEntry(
          id: 'two',
          word: 'two',
          phonetic: '/two/',
          definition: 'n. test entry two.',
          example: 'test',
          category: 'test',
          favThumbImage: 'assets/images/home_sticker_dog.png',
        ),
        DictionaryEntry(
          id: 'three',
          word: 'three',
          phonetic: '/three/',
          definition: 'n. test entry three.',
          example: 'test',
          category: 'test',
          favThumbImage: 'assets/images/home_sticker_cat.png',
        ),
      ];
      await tester.pumpWidget(
        _wrap(const DictionaryBrowseScreen(entries: entries), controller),
      );
      await tester.pumpAndSettle();

      for (final id in ['one', 'two', 'three']) {
        expect(find.byKey(Key('dictionary-bento-tile-$id')), findsOneWidget);
      }
      expect(
        find.descendant(
          of: find.byType(DictionaryBentoGrid),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(3),
      );
    },
  );

  testWidgets(
    'Catalog card does not overflow when the word is long (real dictionary content)',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      const entries = [
        DictionaryEntry(
          id: 'eskwelahan',
          word: 'eskweláhan',
          phonetic: '/es-kwe-la-han/',
          definition: 'n. School-house, school.',
          example: 'test',
          category: 'places',
        ),
        DictionaryEntry(
          id: 'arroz-caldo',
          word: 'arroz caldo',
          phonetic: '/ar-roz-cal-do/',
          definition:
              'n. Porridge cooked with spring onions, ginger and chicken.',
          example: 'test',
          category: 'food',
        ),
      ];
      await tester.pumpWidget(
        _wrap(const DictionaryBrowseScreen(entries: entries), controller),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tapping a word in "my favorites" opens straight to its definition page',
    (tester) async {
      await setLargeViewport(tester);
      final controller = await _controllerWithProfile();
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      // Favorite "balay" via the word-of-the-day card.
      await tester.tap(find.byKey(const Key('dictionary-word-card')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('dictionary-word-favorite-button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dictionary-favorite-tile-balay')));
      await tester.pumpAndSettle();

      expect(find.byType(DictionaryBrowseScreen), findsOneWidget);
      expect(find.byType(DictionaryLookupPage), findsOneWidget);
      expect(find.byKey(const Key('dictionary-browse-list')), findsNothing);
      // Definition view shows only the back pill -- no header/search bar.
      expect(
        find.descendant(
          of: find.byType(DictionaryBrowseScreen),
          matching: find.byType(DictionaryHeader),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const Key('dictionary-browse-search-field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('dictionary-browse-back-pill')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'With no word-of-the-day history yet, some valid pool entry renders',
    (tester) async {
      await setLargeViewport(tester);
      // A fresh profile with no recordWordOfTheDay call yet -- unlike
      // _controllerWithProfile(), which pins it to "balay" for the other
      // tests here.
      final controller = LearnerController();
      await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);
      await tester.pumpWidget(
        _wrap(const DictionaryScreen(entries: _testEntries), controller),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dictionary-word-card')), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Something was picked and persisted -- not left unresolved.
      expect(controller.profile!.wordOfTheDayId, isNotNull);
    },
  );
}
