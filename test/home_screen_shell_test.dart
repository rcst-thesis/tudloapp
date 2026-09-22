import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/tudlo.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_words.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_energy_indicator.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel.dart';
import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';

void main() {
  testWidgets('Home content scrolls while bottom navigation remains fixed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final navigation = find.byKey(const Key('home-bottom-navigation'));
    final navigationBefore = tester.getRect(navigation);
    final settings = find.byKey(const Key('home-settings-button'));
    final settingsBefore = tester.getRect(settings);
    final energy = find.byKey(const Key('home-energy-indicator'));
    final energyBefore = tester.getRect(energy);
    final lamp = find.byKey(const Key('home-lamp-button'));
    final lampBefore = tester.getRect(lamp);
    final window = find.byKey(const Key('home-animated-window'));
    final windowBefore = tester.getRect(window);
    final contentTopBefore = tester
        .getTopLeft(find.byKey(const Key('home-content-top')))
        .dy;

    await tester.drag(
      find.byKey(const Key('home-content-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pump();

    expect(tester.getRect(navigation), navigationBefore);
    expect(tester.getRect(settings), settingsBefore);
    expect(tester.getRect(energy), energyBefore);
    expect(tester.getRect(lamp).top, lessThan(lampBefore.top));
    expect(tester.getRect(window).top, lessThan(windowBefore.top));
    expect(
      tester.getTopLeft(find.byKey(const Key('home-content-top'))).dy,
      lessThan(contentTopBefore),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home upper navigation materializes as the floor is reached', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final navigationBar = find.byKey(const Key('home-upper-navigation-bar'));
    expect(tester.widget<Opacity>(navigationBar).opacity, 0);

    await tester.drag(
      find.byKey(const Key('home-content-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pump();

    final revealedOpacity = tester.widget<Opacity>(navigationBar).opacity;
    expect(revealedOpacity, greaterThan(0));
    expect(revealedOpacity, lessThan(.85));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shell avoids overflow on phone and tablet sizes', (
    tester,
  ) async {
    for (final size in const [
      Size(320, 480),
      Size(412, 917),
      Size(800, 1200),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Home shell at $size');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Home window uses the 412-wide Figma placement', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final window = find.byKey(const Key('home-animated-window'));
    expect(tester.getSize(window), const Size.square(128));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home bookshelf uses the 412-wide Figma placement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final bookshelf = find.byKey(const Key('home-bookshelf'));
    expect(tester.getSize(bookshelf), const Size(160, 37));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home standing lamp uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final lamp = find.byKey(const Key('home-standing-lamp'));
    expect(tester.getSize(lamp), const Size(36.25, 126));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home drawer uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final drawer = find.byKey(const Key('home-drawer'));
    expect(tester.getSize(drawer), const Size(52, 41));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home couch uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final couch = find.byKey(const Key('home-couch'));
    expect(tester.getSize(couch), const Size(152, 79));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home lily mat uses the chained Figma size', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final lilyMat = find.byKey(const Key('home-lily-mat'));
    expect(tester.getSize(lilyMat), const Size(361, 88));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Word of the Day uses the chained Figma size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final card = find.byKey(const Key('home-word-of-the-day'));
    expect(tester.getSize(card), const Size(378, 216));
    expect(find.text('word of the day'), findsOneWidget);
    // Any word with dedicated art is now eligible for rotation (not just
    // 'balay'), so assert against that pool instead of one fixed word.
    final eligibleWords = DictionaryWords.all
        .where((entry) => entry.frontCardImage != null)
        .map((entry) => entry.word)
        .toSet();
    final shown = tester
        .widget<Semantics>(card)
        .properties
        .label!
        .replaceFirst('Word of the day: ', '')
        .split('.')
        .first;
    expect(eligibleWords, contains(shown));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home lesson availability is derived from Energy, capped at the '
      "grade's real lesson count (regression: it used to pad extra slots "
      'with invented locked placeholders up to a flat cap of 6, even when '
      'the grade only has fewer real lessons)', (tester) async {
    final grade1LessonCount = LessonCatalog.forGrade(1).length;

    await tester.pumpWidget(const MaterialApp(home: HomeScreen(energy: 10)));
    expect(find.text('1 lesson subong nga adlaw!'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen(energy: 60)));
    expect(
      find.text('$grade1LessonCount lessons subong nga adlaw!'),
      findsOneWidget,
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen(energy: 100)));
    expect(
      find.text('$grade1LessonCount lessons subong nga adlaw!'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home lesson deck collapses from its section chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeLessonPanel(
              energy: 60,
              additionalLessons: [
                HomeLessonPreview(
                  unitTitle: 'yunit 2',
                  category: 'MGA KULAY',
                  status: HomeLessonStatus.available,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('home-lesson-card-0')), findsOneWidget);
    expect(find.byKey(const Key('home-lesson-deck-layer-1')), findsNothing);

    final toggle = find.byKey(const Key('home-lesson-collapse-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    expect(find.byKey(const Key('home-lesson-card')), findsOneWidget);
    expect(find.byKey(const Key('home-lesson-deck-layer-1')), findsOneWidget);
    expect(find.byKey(const Key('home-lesson-section-label')), findsNothing);
    expect(find.byKey(const Key('home-lesson-collapse-toggle')), findsNothing);
    expect(find.byKey(const Key('home-lesson-summary-title')), findsOneWidget);
    expect(
      find.byKey(const Key('home-lesson-summary-categories')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Lesson completed'), findsNothing);

    await tester.tap(
      find.byKey(const Key('home-lesson-collapsed-deck-toggle')),
    );
    await tester.pump();
    expect(find.byKey(const Key('home-lesson-card-0')), findsOneWidget);
    expect(find.byKey(const Key('home-lesson-deck-layer-1')), findsNothing);
    expect(find.byKey(const Key('home-lesson-section-label')), findsOneWidget);
    expect(find.byKey(const Key('home-lesson-summary-title')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Collapsing with several lessons then Energy dropping below 10 does '
    "not crash (regression: the collapsed deck called `.first` on "
    "_visibleLessons, which is empty once Energy makes zero lessons "
    'available)',
    (tester) async {
      Widget buildPanel(int energy) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeLessonPanel(
              energy: energy,
              additionalLessons: const [
                HomeLessonPreview(
                  unitTitle: 'yunit 2',
                  category: 'MGA KULAY',
                  status: HomeLessonStatus.available,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildPanel(60));
      final toggle = find.byKey(const Key('home-lesson-collapse-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      expect(find.byKey(const Key('home-lesson-card')), findsOneWidget);

      // Energy falls below 10 (e.g. spent down, or a new day) while the
      // panel is still collapsed from when there were several lessons.
      await tester.pumpWidget(buildPanel(5));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home-lesson-card')), findsNothing);
      expect(find.byKey(const Key('home-lesson-availability')), findsOneWidget);
      expect(find.text('0 lessons subong nga adlaw!'), findsOneWidget);
    },
  );

  testWidgets(
    'High energy never shows more slots than the real configured lessons '
    '(regression: a flat clamp(0, 6) used to pad the remainder with '
    "invented locked placeholders instead of stopping at what's real)",
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              child: HomeLessonPanel(
                energy: 100,
                additionalLessons: [
                  HomeLessonPreview(
                    unitTitle: 'yunit 2',
                    category: 'MGA KULAY',
                    status: HomeLessonStatus.available,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 lessons subong nga adlaw!'), findsOneWidget);
      expect(find.byKey(const Key('home-lesson-card-0')), findsOneWidget);
      expect(find.byKey(const Key('home-lesson-card-1')), findsOneWidget);
      expect(find.byKey(const Key('home-lesson-card-2')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A single available lesson has no collapse control', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(energy: 10)));

    expect(find.byKey(const Key('home-lesson-card-0')), findsOneWidget);
    expect(find.byKey(const Key('home-lesson-collapse-toggle')), findsNothing);
    expect(find.byKey(const Key('home-lesson-deck-layer-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping a lesson opens its preview and close dismisses it', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(energy: 10)));

    final lessonCard = find.byKey(const Key('home-lesson-card-0'));
    await tester.ensureVisible(lessonCard);
    await tester.tap(lessonCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('lesson mo subong nga adlaw'), findsOneWidget);

    // The dialog has no dedicated close control; tapping its barrier
    // dismisses it (`barrierDismissible: true`).
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('lesson mo subong nga adlaw'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home content footer closes the scrolling scene', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final footer = find.byKey(const Key('home-content-footer'));
    expect(tester.getSize(footer), const Size(412, 48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home footer meets the fixed navigation without a gap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('home-content-scroll-view')),
      const Offset(0, -2000),
    );
    await tester.pump();

    final footer = tester.getRect(find.byKey(const Key('home-content-footer')));
    final navigation = tester.getRect(
      find.byKey(const Key('home-bottom-navigation')),
    );
    expect(footer.bottom, moreOrLessEquals(navigation.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home room surfaces keep the cream border behind the floor', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final creamWall = tester.widget<ColoredBox>(
      find.byKey(const Key('home-cream-wall')),
    );
    final floor = tester.widget<ColoredBox>(
      find.byKey(const Key('home-floor')),
    );
    expect(creamWall.color, const Color(0xFFFBF3E4));
    expect(floor.color, const Color(0xFFB88956));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home settings button opens the Settings category picker, which leads '
    'to the animation toggle under Display & Performance',
    (tester) async {
      final animationController = AppAnimationController();
      await tester.pumpWidget(
        AppAnimationScope(
          controller: animationController,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      final settingsButton = find.byKey(const Key('home-settings-button'));
      expect(settingsButton, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(settingsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final displayPerformanceCard = find.byKey(
        const Key('settings-category-display-performance'),
      );
      expect(displayPerformanceCard, findsOneWidget);
      await tester.ensureVisible(displayPerformanceCard);
      await tester.tap(find.text('Display & Performance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Halt Animations'), findsOneWidget);
      expect(
        find.byKey(const Key('settings-animation-switch')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings animation switch controls app-wide motion', (
    tester,
  ) async {
    final animationController = AppAnimationController();
    await tester.pumpWidget(
      AppAnimationScope(
        controller: animationController,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    final displayPerformanceCard = find.byKey(
      const Key('settings-category-display-performance'),
    );
    await tester.ensureVisible(displayPerformanceCard);
    await tester.tap(find.text('Display & Performance'));
    // pumpAndSettle, not a fixed pump -- expanding also scrolls the panel
    // into view (settings_screen.dart's _scrollExpandedPanelIntoView),
    // and tapping mid-scroll can miss the toggle entirely as it moves.
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-animation-switch')));
    await tester.pump();

    expect(animationController.isEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home door opens the Map screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.byKey(const Key('home-door')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-door-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('map-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home bookshelf books open the lesson catalog destination', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-bookshelf-books-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('lesson-catalog-screen')), findsOneWidget);
    final lessonsTile = tester.widget<Material>(
      find.byKey(const Key('home-nav-tile-lessons')),
    );
    expect(lessonsTile.color, const Color(0xFF54D3EA));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Map navigation opens the Map screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-nav-map')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('map-screen')), findsOneWidget);
    expect(find.byKey(const Key('home-bottom-navigation')), findsOneWidget);
    final mapTile = tester.widget<Material>(
      find.byKey(const Key('home-nav-tile-map')),
    );
    expect(mapTile.color, const Color(0xFFD2C15D));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home navigation tabs do not stack Lessons behind Map', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-nav-lessons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('lesson-catalog-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-nav-map')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('map-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-nav-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    expect(find.byKey(const Key('lesson-catalog-screen')), findsNothing);
    expect(find.byKey(const Key('map-screen')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home door repeats a short exploration hint', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    final nudge = tester.widget<Transform>(
      find.byKey(const Key('home-door-hint-nudge')),
    );
    expect(nudge.transform.storage[12], 0);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('home-door-hint-nudge')))
          .transform
          .storage[12]
          .abs(),
      greaterThan(0),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('explore!'), findsOneWidget);
    expect(find.byKey(const Key('home-door-hint-phrase')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home energy indicator uses a Flutter percentage label', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byKey(const Key('home-energy-indicator')), findsOneWidget);
    expect(find.byKey(const Key('home-energy-label')), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home energy indicator on the real Home screen reflects a non-default '
    'energy value',
    (tester) async {
      // Regression: HomeEnergyIndicator() was constructed with no `energy:`
      // argument at its call site in HomeScreen, so it silently always used
      // its own default (60) no matter what the learner's real energy was.
      await tester.pumpWidget(const MaterialApp(home: HomeScreen(energy: 30)));

      expect(find.text('30%'), findsOneWidget);
      expect(find.text('60%'), findsNothing);
      for (var index = 0; index < 3; index++) {
        expect(find.byKey(Key('home-energy-bar-$index')), findsOneWidget);
      }
      expect(find.byKey(const Key('home-energy-bar-3')), findsNothing);
    },
  );

  testWidgets(
    'Home energy indicator fills a number of bars proportional to energy '
    '(one bar per 10%)',
    (tester) async {
      Future<void> pumpEnergy(int energy) => tester.pumpWidget(
        MaterialApp(home: HomeEnergyIndicator(energy: energy)),
      );

      // 0/10 bars.
      await pumpEnergy(0);
      expect(find.byKey(const Key('home-energy-bar-0')), findsNothing);

      // 5/10 bars (50%).
      await pumpEnergy(50);
      for (var index = 0; index < 5; index++) {
        expect(find.byKey(Key('home-energy-bar-$index')), findsOneWidget);
      }
      expect(find.byKey(const Key('home-energy-bar-5')), findsNothing);

      // 10/10 bars (100%).
      await pumpEnergy(100);
      for (var index = 0; index < 10; index++) {
        expect(find.byKey(Key('home-energy-bar-$index')), findsOneWidget);
      }

      // Out-of-range values still clamp sanely instead of over/under-filling.
      await pumpEnergy(150);
      for (var index = 0; index < 10; index++) {
        expect(find.byKey(Key('home-energy-bar-$index')), findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home lamp toggles its light effect', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final lamp = find.byKey(const Key('home-lamp-button'));
    final lightEffect = find.byKey(const Key('home-lamp-light-effect'));
    expect(lamp, findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(lightEffect).opacity, 0);

    await tester.tap(lamp);
    await tester.pump();

    expect(tester.widget<AnimatedOpacity>(lightEffect).opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home navigation shows six tappable items with Home selected', (
    tester,
  ) async {
    var tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavigation(
            onItemTapped: (index) => tappedIndex = index,
          ),
        ),
      ),
    );
    await tester.pump();

    for (final label in const [
      'home',
      'translate',
      'lessons',
      'map',
      'dictionary',
      'me',
    ]) {
      expect(find.byKey(Key('home-nav-$label')), findsOneWidget);
    }

    final labelSizes = <double?>{
      for (final label in const [
        'home',
        'translate',
        'lessons',
        'map',
        'dictionary',
        'me',
      ])
        tester
            .widget<Text>(find.byKey(Key('home-nav-label-$label')))
            .style
            ?.fontSize,
    };
    expect(labelSizes, hasLength(1));

    await tester.tap(find.byKey(const Key('home-nav-map')));
    expect(tappedIndex, 3);
    expect(tester.takeException(), isNull);
  });
}
