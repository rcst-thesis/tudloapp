import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;
import 'package:tudloapp/features/home/presentation/widgets/home_koka_mascot.dart';

void main() {
  testWidgets('Koka mascot exposes its State Machine 1 contract', (
    tester,
  ) async {
    final file = await rive.File.asset(
      'assets/images/koka_mascot.riv',
      riveFactory: rive.Factory.flutter,
    );
    expect(file, isNotNull);

    final controller = rive.RiveWidgetController(
      file!,
      stateMachineSelector: rive.StateMachineSelector.byName('State Machine 1'),
    );
    addTearDown(controller.dispose);
    addTearDown(file.dispose);

    // ignore: deprecated_member_use
    final inputs = controller.stateMachine.inputs;
    expect(controller.stateMachine.name, 'State Machine 1');
    expect(
      inputs.map((input) => input.name),
      containsAll(['Hi', 'Curious', 'Annoyed']),
    );
  });

  testWidgets('Koka prioritizes the learner name and escalates repeated taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 220,
            child: HomeKokaMascot(learnerName: 'Maya'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final koka = find.byKey(const Key('home-koka-tap-target'));
    await tester.tap(koka);
    await tester.pump();
    await tester.pump();
    expect(find.text('Hi, Maya!'), findsOneWidget);

    await tester.tap(koka);
    await tester.tap(koka);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Ano problema, Maya?'), findsOneWidget);

    await tester.tap(koka);
    await tester.tap(koka);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Tama dun na, Maya.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
