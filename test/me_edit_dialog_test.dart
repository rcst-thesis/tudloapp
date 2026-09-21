import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/me/presentation/screens/me_screen.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_learner_card.dart';
import 'package:tudloapp/shared/widgets/rive_avatar.dart';

// None of the testWidgets below use pumpAndSettle -- the avatar's own
// blink/pupil-follow state machine animates continuously once loaded, so
// settling never actually finishes. Bounded pumps only, throughout this
// file (see docs/RIVE_INTEGRATION.md's avatar contract section).

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'tapping edit opens the popup pre-filled with the current learner',
    (tester) async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Anna', grade: 2, energy: 60);

      await tester.pumpWidget(
        MaterialApp(
          home: LearnerScope(controller: controller, child: const MeScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('me-edit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final dialog = find.byKey(const Key('me-edit-dialog'));
      expect(dialog, findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('me-edit-name-field')),
      );
      expect(field.controller?.text, 'Anna');
      // Scoped to the dialog -- MeLearnerCard behind it bakes its own "grade
      // N"/user-code text too.
      expect(
        find.descendant(of: dialog, matching: find.text('grade 2')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(controller.profile!.id),
        ),
        findsOneWidget,
      );
      // Only one Artboard exists in avatar.riv today -- exactly one tile,
      // pre-selected as the learner's current avatar.
      expect(
        find.byKey(
          const Key('me-edit-avatar-tile-${LearnerProfile.defaultAvatarId}'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('editing the name and tapping save persists the new name', (
    tester,
  ) async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 2, energy: 60);

    await tester.pumpWidget(
      MaterialApp(
        home: LearnerScope(controller: controller, child: const MeScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('me-edit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.enterText(
      find.byKey(const Key('me-edit-name-field')),
      'Bella',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('me-edit-save-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('me-edit-dialog')), findsNothing);
    expect(controller.profile?.name, 'Bella');
    // The learner card behind the (now-closed) popup reflects the rename.
    expect(find.byKey(const Key('me-learner-card-name')), findsOneWidget);
    expect(find.text('Bella'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dismissing the popup without saving leaves the learner unchanged',
    (tester) async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Anna', grade: 2, energy: 60);

      await tester.pumpWidget(
        MaterialApp(
          home: LearnerScope(controller: controller, child: const MeScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('me-edit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.enterText(
        find.byKey(const Key('me-edit-name-field')),
        'Bella',
      );
      await tester.pump();
      // Tap the barrier (top-left corner, well outside the centered card) to
      // dismiss instead of saving.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('me-edit-dialog')), findsNothing);
      expect(controller.profile?.name, 'Anna');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("MeLearnerCard renders the learner's avatar over the header's "
      'placeholder rectangle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 374,
            child: MeLearnerCard(
              learnerName: 'Anna',
              grade: 2,
              userCode: 'abc123',
              avatarId: LearnerProfile.defaultAvatarId,
              selectedTab: MeCardTab.about,
              onTabSelected: (_) {},
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('me-learner-card-avatar')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('me-learner-card-avatar')),
        matching: find.byType(RiveAvatar),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
