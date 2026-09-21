import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 200, child: child)),
  );

  testWidgets('fires onPressed on tap', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      wrap(
        StickerPressButton(
          label: 'go',
          frontColor: Colors.blue,
          depthColor: Colors.indigo,
          onPressed: () => pressed = true,
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets(
    'the front layer slides down to meet the depth layer while pressed, '
    'and springs back up on release',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          StickerPressButton(
            label: 'go',
            frontColor: Colors.blue,
            depthColor: Colors.indigo,
            restLift: 5,
            onPressed: () {},
          ),
        ),
      );

      Positioned frontPositioned() => tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(GestureDetector),
          matching: find.byType(Positioned),
        ),
      );

      // At rest: the front layer stops 5px short of the bottom, revealing
      // the depth layer's "lip" underneath.
      expect(frontPositioned().top, 0);
      expect(frontPositioned().bottom, 5);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('go')),
      );
      await tester.pumpAndSettle();

      // Pressed: the front layer has slid down to fully cover the depth
      // layer -- no lip visible.
      expect(frontPositioned().top, 5);
      expect(frontPositioned().bottom, 0);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(frontPositioned().top, 0);
      expect(frontPositioned().bottom, 5);
    },
  );

  testWidgets('renders child instead of label when supplied', (tester) async {
    await tester.pumpWidget(
      wrap(
        StickerPressButton(
          onPressed: () {},
          frontColor: Colors.blue,
          depthColor: Colors.indigo,
          child: const Icon(Icons.arrow_forward),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('disabled button ignores taps and does not fire onPressed', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      wrap(
        StickerPressButton(
          label: 'go',
          frontColor: Colors.blue,
          depthColor: Colors.indigo,
          enabled: false,
          onPressed: () => pressed = true,
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(pressed, isFalse);
  });
}
