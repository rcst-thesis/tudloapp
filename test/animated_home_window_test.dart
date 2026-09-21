import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/features/home/presentation/widgets/animated_home_window.dart';

void main() {
  testWidgets('Home window clouds use the Welcome ten-second ambient motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: SizedBox(width: 128, child: AnimatedHomeWindow())),
      ),
    );
    await tester.pump();

    Transform cloudTransform() => tester.widget<Transform>(
      find.byKey(const Key('home-window-cloud-motion')),
    );

    expect(cloudTransform().transform.storage[12], closeTo(0, .01));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(cloudTransform().transform.storage[12], closeTo(3, .05));
    final sunRotation = tester.widget<Transform>(
      find.byKey(const Key('home-window-sun-rotation')),
    );
    expect(sunRotation.transform.storage[0], closeTo(0, .05));
    expect(sunRotation.transform.storage[1], closeTo(1, .05));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home window respects reduced-motion accessibility', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Center(
            child: SizedBox(width: 128, child: AnimatedHomeWindow()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2500));

    final transform = tester.widget<Transform>(
      find.byKey(const Key('home-window-cloud-motion')),
    );
    expect(transform.transform.storage[12], closeTo(0, .01));
    expect(tester.takeException(), isNull);
  });
}
