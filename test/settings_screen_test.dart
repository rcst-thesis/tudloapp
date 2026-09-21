import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/core/motion/app_animation_controller.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';
import 'package:tudloapp/features/settings/presentation/settings_screen.dart';

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

  Future<LearnerController> signedInController() async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);
    return controller;
  }

  Widget withSignedInLearner(LearnerController controller) {
    return MaterialApp(
      home: LearnerScope(
        controller: controller,
        child: const SettingsScreen(insideLearnerProfile: true),
      ),
    );
  }

  Widget withAnimationController(AppAnimationController controller) {
    return MaterialApp(
      home: AppAnimationScope(
        controller: controller,
        child: const SettingsScreen(),
      ),
    );
  }

  /// The device-wide `AppSettingsScope`/`AppAnimationScope` fallbacks each
  /// `.of(context)` call gets when no ancestor is wrapped (`LearnerScope`
  /// and `AppSettingsScope.of` alike) create a *fresh* controller every
  /// time -- fine for a read that's never written back, but a write
  /// followed by a reread (a toggle actually changing, a language actually
  /// switching) needs the *same* controller instance across the whole
  /// pumped tree. These two helpers supply that explicitly.
  Widget withAppSettings(
    AppSettingsController controller, {
    bool insideLearnerProfile = false,
  }) {
    return MaterialApp(
      home: AppSettingsScope(
        controller: controller,
        child: SettingsScreen(insideLearnerProfile: insideLearnerProfile),
      ),
    );
  }

  Widget withAnimationAndAppSettings(
    AppAnimationController animation,
    AppSettingsController appSettings,
  ) {
    return MaterialApp(
      home: AppAnimationScope(
        controller: animation,
        child: AppSettingsScope(
          controller: appSettings,
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  /// The parent-gate question's operands are randomized per dialog, so
  /// tests read the rendered question back and compute the right answer
  /// instead of hardcoding one.
  int readParentGateAnswer(WidgetTester tester) {
    final questionText = tester
        .widgetList<Text>(find.textContaining('What is'))
        .single
        .data!;
    final match = RegExp(r'What is (\d+) × (\d+)\?').firstMatch(questionText)!;
    return int.parse(match.group(1)!) * int.parse(match.group(2)!);
  }

  testWidgets(
    "General expands in place to reveal the language picker, and doesn't "
    'navigate away',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      final general = find.byKey(const Key('settings-category-general'));
      expect(general, findsOneWidget);
      expect(find.text('Language'), findsNothing);

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Hiligaynon'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tapping English selects it and deselects Hiligaynon', (
    tester,
  ) async {
    setViewport(tester);
    await tester.pumpWidget(withAppSettings(AppSettingsController()));

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    DecoratedBox segmentBox(Key key) => tester.widget<DecoratedBox>(
      find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
    );

    final hiligaynonKey = const Key('settings-language-hiligaynon');
    final englishKey = const Key('settings-language-english');

    expect(
      (segmentBox(hiligaynonKey).decoration as BoxDecoration).color,
      const Color(0xFF68AA59),
    );
    expect(
      (segmentBox(englishKey).decoration as BoxDecoration).color,
      Colors.white,
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(
      (segmentBox(englishKey).decoration as BoxDecoration).color,
      const Color(0xFF68AA59),
    );
    expect(
      (segmentBox(hiligaynonKey).decoration as BoxDecoration).color,
      Colors.white,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping General again collapses it', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expanding General on a short viewport scrolls instead of '
      'overflowing (regression: IntrinsicHeight+Spacer could not cope with '
      "General's variable expanded height)", (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Sound & Voice expands in place to reveal Master Volume and the "
      "three audio channels, and doesn't navigate away", (tester) async {
    setViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('Master Volume'), findsNothing);

    await tester.tap(find.text('Sound & Voice'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Master Volume'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Voice-over'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toggling a channel mute shows the Muted label', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(withAppSettings(AppSettingsController()));

    await tester.tap(find.text('Sound & Voice'));
    await tester.pumpAndSettle();

    expect(find.text('Muted'), findsNothing);
    expect(find.text('On'), findsNWidgets(3));

    final toggle = find.byKey(const Key('settings-channel-music-toggle'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Muted'), findsOneWidget);
    expect(find.text('On'), findsNWidgets(2));

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Muted'), findsNothing);
    expect(find.text('On'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dragging the master volume slider updates the percentage', (
    tester,
  ) async {
    setViewport(tester);
    await tester.pumpWidget(withAppSettings(AppSettingsController()));

    await tester.tap(find.text('Sound & Voice'));
    await tester.pumpAndSettle();

    final slider = find.byKey(const Key('settings-master-volume-slider'));
    expect(find.text('80%'), findsOneWidget);

    await tester.drag(slider, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('80%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Learning & Energy is dimmed and inert from the main menu (not '
      'inside the learner profile)', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('Log in to a profile to unlock this'), findsOneWidget);

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();

    expect(find.text('Koka Energy · 60% · Up to 6 lessons'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Learning & Energy expands in place to reveal the energy summary, '
    "reminders toggle, and reset action, and doesn't navigate away",
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(insideLearnerProfile: true)),
      );

      expect(find.text('Koka Energy · 60% · Up to 6 lessons'), findsNothing);

      await tester.tap(find.text('Learning & Energy'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Koka Energy · 60% · Up to 6 lessons'), findsOneWidget);
      expect(find.text('Parent controlled'), findsOneWidget);
      expect(find.text('Lesson Reminders'), findsOneWidget);
      expect(find.text('Reset Lesson Progress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Toggling Lesson Reminders flips the switch', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(withSignedInLearner(await signedInController()));

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();

    bool toggleValue() {
      final toggle = find.byKey(const Key('settings-lesson-reminders-toggle'));
      final container = tester.widget<AnimatedContainer>(
        find.descendant(of: toggle, matching: find.byType(AnimatedContainer)),
      );
      return (container.decoration! as BoxDecoration).color ==
          const Color(0xFF4F893A);
    }

    expect(toggleValue(), isTrue);

    await tester.tap(find.byKey(const Key('settings-lesson-reminders-toggle')));
    await tester.pumpAndSettle();

    expect(toggleValue(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reset Lesson Progress asks for the parent gate before the reset '
      'confirmation shows up', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen(insideLearnerProfile: true)),
    );

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-reset-lesson-progress')));
    await tester.pumpAndSettle();

    final gate = find.byKey(const Key('settings-parent-gate-dialog'));
    final dialog = find.byKey(
      const Key('settings-reset-lesson-progress-dialog'),
    );
    expect(gate, findsOneWidget);
    expect(dialog, findsNothing);

    final correctAnswer = readParentGateAnswer(tester);
    await tester.enterText(
      find.byKey(const Key('settings-parent-gate-input')),
      '$correctAnswer',
    );
    await tester.tap(
      find.byKey(const Key('settings-parent-gate-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(gate, findsNothing);
    expect(dialog, findsOneWidget);
    expect(find.text('reset lesson progress?'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('settings-reset-lesson-cancel-button')),
    );
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cancelling the parent gate for Reset Lesson Progress never shows '
    'the reset confirmation',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(insideLearnerProfile: true)),
      );

      await tester.tap(find.text('Learning & Energy'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-reset-lesson-progress')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('settings-parent-gate-cancel-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings-parent-gate-dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('settings-reset-lesson-progress-dialog')),
        findsNothing,
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Change Energy Level opens the parent gate first', (
    tester,
  ) async {
    setViewport(tester);
    await tester.pumpWidget(withSignedInLearner(await signedInController()));

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-change-energy')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-parent-gate-dialog')),
      findsOneWidget,
    );
    expect(find.text('parents only'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-energy-editor-dialog')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A wrong parent gate answer stays on the gate instead of opening the '
    'editor',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(withSignedInLearner(await signedInController()));

      await tester.tap(find.text('Learning & Energy'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-change-energy')));
      await tester.pumpAndSettle();

      final correctAnswer = readParentGateAnswer(tester);
      await tester.enterText(
        find.byKey(const Key('settings-parent-gate-input')),
        '${correctAnswer + 1}',
      );
      await tester.tap(
        find.byKey(const Key('settings-parent-gate-continue-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('not quite -- try again'), findsOneWidget);
      expect(
        find.byKey(const Key('settings-parent-gate-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-energy-editor-dialog')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A correct parent gate answer opens the energy editor pre-filled '
      "with the learner's current energy", (tester) async {
    setViewport(tester);
    await tester.pumpWidget(withSignedInLearner(await signedInController()));

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-change-energy')));
    await tester.pumpAndSettle();

    final correctAnswer = readParentGateAnswer(tester);
    await tester.enterText(
      find.byKey(const Key('settings-parent-gate-input')),
      '$correctAnswer',
    );
    await tester.tap(
      find.byKey(const Key('settings-parent-gate-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-energy-editor-dialog')),
      findsOneWidget,
    );
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Up to 6 lessons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saving a new energy level in the editor persists it and updates '
      'the panel', (tester) async {
    setViewport(tester);
    final controller = await signedInController();
    await tester.pumpWidget(withSignedInLearner(controller));

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-change-energy')));
    await tester.pumpAndSettle();

    final correctAnswer = readParentGateAnswer(tester);
    await tester.enterText(
      find.byKey(const Key('settings-parent-gate-input')),
      '$correctAnswer',
    );
    await tester.tap(
      find.byKey(const Key('settings-parent-gate-continue-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-energy-minus-button')));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Up to 5 lessons'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-energy-save-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-energy-editor-dialog')),
      findsNothing,
    );
    expect(controller.profile?.energy, 50);
    expect(find.text('Koka Energy · 50% · Up to 5 lessons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelling the energy editor leaves the energy unchanged', (
    tester,
  ) async {
    setViewport(tester);
    final controller = await signedInController();
    await tester.pumpWidget(withSignedInLearner(controller));

    await tester.tap(find.text('Learning & Energy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-change-energy')));
    await tester.pumpAndSettle();

    final correctAnswer = readParentGateAnswer(tester);
    await tester.enterText(
      find.byKey(const Key('settings-parent-gate-input')),
      '$correctAnswer',
    );
    await tester.tap(
      find.byKey(const Key('settings-parent-gate-continue-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-energy-plus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-energy-cancel-button')));
    await tester.pumpAndSettle();

    expect(controller.profile?.energy, 60);
    expect(find.text('Koka Energy · 60% · Up to 6 lessons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Display & Performance expands in place to reveal the animation '
      'toggles and quality tiers, and doesn\'t navigate away', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(withAnimationController(AppAnimationController()));

    expect(find.text('Ambient Animations'), findsNothing);

    await tester.tap(find.text('Display & Performance'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Ambient Animations'), findsOneWidget);
    expect(find.text('Halt Animations'), findsOneWidget);
    expect(find.text('High Quality'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Battery Saver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Halt Animations toggles the real app-wide animation flag', (
    tester,
  ) async {
    setViewport(tester);
    final controller = AppAnimationController();
    await tester.pumpWidget(withAnimationController(controller));

    await tester.tap(find.text('Display & Performance'));
    await tester.pumpAndSettle();

    expect(controller.isEnabled, isTrue);
    await tester.tap(find.byKey(const Key('settings-animation-switch')));
    await tester.pumpAndSettle();

    expect(controller.isEnabled, isFalse);
    await tester.tap(find.byKey(const Key('settings-animation-switch')));
    await tester.pumpAndSettle();

    expect(controller.isEnabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ambient Animations toggles independently of Halt Animations', (
    tester,
  ) async {
    setViewport(tester);
    final controller = AppAnimationController();
    await tester.pumpWidget(withAnimationController(controller));

    await tester.tap(find.text('Display & Performance'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('settings-ambient-animations-toggle')),
    );
    await tester.pumpAndSettle();

    expect(controller.isEnabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Tapping a quality tier selects it and deselects the previous one',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        withAnimationAndAppSettings(
          AppAnimationController(),
          AppSettingsController(),
        ),
      );

      await tester.tap(find.text('Display & Performance'));
      await tester.pumpAndSettle();

      DecoratedBox tierBox(Key key) => tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      );

      final balancedKey = const Key('settings-quality-balanced');
      final highKey = const Key('settings-quality-high');

      expect(
        (tierBox(balancedKey).decoration as BoxDecoration).color,
        const Color(0xFF68AA59),
      );
      expect(
        (tierBox(highKey).decoration as BoxDecoration).color,
        const Color(0xFFEFF7E8),
      );

      await tester.tap(find.text('High Quality'));
      await tester.pumpAndSettle();

      expect(
        (tierBox(highKey).decoration as BoxDecoration).color,
        const Color(0xFF68AA59),
      );
      expect(
        (tierBox(balancedKey).decoration as BoxDecoration).color,
        const Color(0xFFEFF7E8),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A device-wide setting survives closing and reopening Settings '
      '(regression: previously local widget state, reset on every pop)', (
    tester,
  ) async {
    setViewport(tester);
    final appSettings = AppSettingsController();
    await tester.pumpWidget(withAppSettings(appSettings));

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(appSettings.settings.language, AppLanguage.english);

    // Simulate closing and reopening Settings -- pump a blank tree first
    // so the old SettingsScreen (and its General panel's local `_expanded`
    // state) is fully torn down, same as a real Navigator pop, before
    // pumping a fresh SettingsScreen under the same underlying
    // AppSettingsController (as TudloApp provides at its root).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(withAppSettings(appSettings));
    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    DecoratedBox segmentBox(Key key) => tester.widget<DecoratedBox>(
      find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
    );
    expect(
      (segmentBox(const Key('settings-language-english')).decoration
              as BoxDecoration)
          .color,
      const Color(0xFF68AA59),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A signed-in learner\'s own setting does not affect the device-wide '
    'copy the main menu reads',
    (tester) async {
      setViewport(tester);
      final appSettings = AppSettingsController();
      final learner = await signedInController();
      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScope(
            controller: appSettings,
            child: LearnerScope(
              controller: learner,
              child: const SettingsScreen(insideLearnerProfile: true),
            ),
          ),
        ),
      );

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(learner.profile!.settings.language, AppLanguage.english);
      expect(appSettings.settings.language, AppSettings.defaults.language);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "About expands in place to reveal its links and version, and doesn't "
    'navigate away',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('About Toadlu'), findsNothing);

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('About Toadlu'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Credits'), findsOneWidget);
      expect(find.text('Version 3 Alpha'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tapping About again collapses it', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('About Toadlu'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('About Toadlu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Help pushes its own placeholder screen', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-about-help')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.textContaining('Help\n'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expanding About (the last, bottom-most panel) scrolls its newly '
      'revealed content into view', (tester) async {
    // A short viewport, same as the General overflow-regression test --
    // at the default test height everything already fits without
    // scrolling, so there'd be nothing for this to prove.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.ensureVisible(find.text('About'));
    await tester.tap(find.text('About'));
    // The scroll-into-view is deliberately delayed (via a plain
    // Future.delayed, not tied to frame scheduling) until the panel's own
    // 200ms AnimatedSize finishes -- pumpAndSettle alone can return before
    // that real-time delay fires, so advance past it explicitly first.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Version 3 Alpha'), findsOneWidget);
    // The whole point: the bottom-most newly revealed line actually lands
    // on screen instead of past the edge of the viewport.
    final versionBottom = tester.getBottomLeft(find.text('Version 3 Alpha')).dy;
    expect(versionBottom, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The back button scrolls away with the content, same as Me screen\'s '
    'own settings button (me_screen.dart) -- not a fixed overlay',
    (tester) async {
      // Short viewport so there's actually something to scroll.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final backButton = find.byKey(const Key('load-back-button'));
      expect(backButton, findsOneWidget);
      final before = tester.getTopLeft(backButton).dy;

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(backButton).dy, lessThan(before));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("The back button's left inset tracks the centered content's own "
      'left edge, not the raw window edge (regression: it previously '
      'scaled off MediaQuery\'s full window width while nested inside a '
      "420-wide ConstrainedBox, drifting away from the content's actual "
      'left edge on any window wider than that)', (tester) async {
    tester.view.physicalSize = const Size(900, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    final backButtonLeft = tester
        .getTopLeft(find.byKey(const Key('load-back-button')))
        .dx;
    // The General panel stretches to the content column's full width, so
    // its own left edge is the true reference point -- unlike "General"
    // the text, which is center-aligned within it and tells us nothing
    // about where the column itself starts.
    final contentLeft = tester
        .getTopLeft(find.byKey(const Key('settings-category-general')))
        .dx;

    // The button's own left padding (16-32px) plus the content's own 18px
    // horizontal padding puts them within a small, bounded range of each
    // other -- not hundreds of pixels apart, which is what the old
    // MediaQuery-based calculation produced on a 900-wide window (it
    // clamped to a fixed 32px from the real window edge while the centered
    // 420-wide content itself started at (900-420)/2 = 240px in).
    expect((backButtonLeft - contentLeft).abs(), lessThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The back button sits near the top of the screen with every panel '
    'collapsed (regression: Center also centers vertically, and a '
    "SingleChildScrollView shrink-wraps to its content's height when "
    "given loose constraints -- with nothing expanded (the content's "
    "shortest state), that combination floated the whole column, back "
    "button included, toward the screen's vertical middle instead of "
    'its top)',
    (tester) async {
      // Taller than the collapsed content, so if it were vertically centered
      // there'd be real, measurable empty space above it.
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final backButtonTop = tester
          .getTopLeft(find.byKey(const Key('load-back-button')))
          .dy;

      // The button's own top inset clamps to at most 32px -- well under a
      // fraction of the 1400-tall screen a vertically-centered layout would
      // have pushed it down by instead.
      expect(backButtonTop, lessThan(100));
      expect(tester.takeException(), isNull);
    },
  );
}
