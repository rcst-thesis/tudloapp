import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/domain/map_route_resolver.dart';
import 'package:tudloapp/features/map/domain/map_tap_policy.dart';
import 'package:tudloapp/features/map/presentation/screens/map_screen.dart';

void main() {
  test(
    'only an active lesson event can temporarily open a locked location',
    () {
      expect(
        MapTapPolicy.canOpen(
          isUnlocked: false,
          action: MapDefaultRoutes.actionFor(MapLocation.school),
        ),
        isFalse,
      );
      expect(
        MapTapPolicy.canOpen(
          isUnlocked: false,
          action: const OpenActiveLessonRouteAction('g1_u1_l1'),
        ),
        isTrue,
      );
      expect(
        MapTapPolicy.canOpen(
          isUnlocked: true,
          action: MapDefaultRoutes.actionFor(MapLocation.school),
        ),
        isTrue,
      );
    },
  );

  // These deliberately never call tester.pumpAndSettle(): MapScreen loads a
  // real Rive asset in the background (unawaited, fire-and-forget from
  // initState -- see RiveMapScene/MapRiveAsset), which never resolves under
  // the headless widget-test binding. Nothing in the widget tree's build
  // phase awaits that future, so a single pumpWidget()+pump() is safe and
  // fast regardless; don't add a pumpAndSettle() here.

  testWidgets(
    'MapScreen does not crash when laid out with a zero-size viewport '
    '(regression: _framedOn divided by zero and threw on the resulting '
    'clamp)',
    (tester) async {
      // A 0x0 physical size forces MapScreen's LayoutBuilder to see zero
      // constraints on at least the first frame.
      tester.view.physicalSize = Size.zero;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('MapScreen does not crash on an extreme tall/narrow viewport '
      '(regression: a valid but extreme-aspect-ratio viewport made the '
      'computed crop taller than the map itself, driving a clamp\'s upper '
      'bound negative)', (tester) async {
    // Finite, positive, and a realistic phone width (so this doesn't also
    // trip an unrelated bottom-nav-bar overflow), but tall enough that
    // _framedOn's computed cropHeight (viewport.height /
    // (viewport.width / portraitCropWidth)) exceeds the map's own
    // 1400-unit height -- portraitCropWidth is 420, so any height:width
    // ratio above 1400/420 (~3.33) triggers it; 1400:400 (3.5) clears that.
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('MapScreen renders at a normal viewport size without error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pump();

    expect(find.byKey(const Key('map-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
