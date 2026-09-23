import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;
import 'package:tudloapp/shared/widgets/rive_long_button.dart';

void main() {
  testWidgets('long button exports its data-binding contract', (tester) async {
    final file = await rive.File.asset(
      'assets/images/longbtn.riv',
      riveFactory: rive.Factory.flutter,
    );
    expect(file, isNotNull);

    final controller = rive.RiveWidgetController(file!);
    final viewModel = controller.dataBind(rive.DataBind.auto());
    addTearDown(viewModel.dispose);
    addTearDown(controller.dispose);
    addTearDown(file.dispose);

    final label = viewModel.string('buttonLabel');
    expect(label, isNotNull);
    expect(viewModel.trigger('activated'), isNotNull);

    label!.value = 'Padayon';
    expect(label.value, 'Padayon');
  });

  testWidgets('long button keeps the Flutter action reachable', (tester) async {
    var activations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiveLongButton(
            label: 'Padayon',
            onPressed: () => activations++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(RiveLongButton));
    expect(activations, 1);
  });
}
