import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/domain/map_route_resolver.dart';
import 'package:tudloapp/features/map/presentation/screens/map_screen.dart';

/// The "tap the place on the map" beat several lessons share.
///
/// Every lesson that has this beat pushes Tudlo's one real [MapScreen] with
/// the same setup: an override so tapping the target pops straight back, a
/// temporary unlock so the target is reachable even when the learner has not
/// opened it yet, and the camera aimed at it. That was copied into six flows
/// and had already drifted -- the Grade 1 pair opened the map expanded while
/// the Grade 3 flows focused the camera instead -- so it lives here once.
///
/// The instruction card stays with each flow, because Grade 1 and Grade 3
/// draw it in their own style.
Future<void> pushLessonMapBeat(
  BuildContext context, {
  required MapLocation target,
  bool expanded = false,
}) {
  final overrides = MapEventOverrides()
    ..setOverride(target, const PopMapRouteAction());
  return Navigator.of(context).push(
    FadePageRoute<void>(
      page: MapScreen(
        eventOverrides: overrides,
        temporaryUnlockedLocations: {target},
        initialFocusLocation: target,
        startExpanded: expanded,
      ),
    ),
  );
}

/// The Grade 3 instruction card for the beat above.
Future<void> showGradeThreeMapInstructionDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: TudloColors.blue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 28,
                height: 1.08,
                fontWeight: FontWeight.w900,
                color: TudloColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 58,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: TudloColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.white, width: 3),
                ),
              ),
              child: const Text(
                'SIGE',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
