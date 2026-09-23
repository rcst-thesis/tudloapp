import 'package:flutter/widgets.dart';

import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/domain/map_route_resolver.dart';

/// The app's one long-lived source of Map progress: its shared
/// [MapEventOverrides] (so active-event routing survives leaving and
/// returning to the Map tab, since [MapScreen] itself is rebuilt fresh each
/// time), and every location a claimed lesson has permanently unlocked this
/// session.
///
/// This remains a short-lived visual projection, not persistence. The
/// learner-owned lesson progression restores it through
/// `LessonProgressController`; `MapScreen` is still the sole Rive bridge.
/// Keep this type free of learner and Rive dependencies.
class MapProgressController {
  final eventOverrides = MapEventOverrides();
  final unlockedLocations = <MapLocation>{};

  /// Records [location] as permanently unlocked. This is projected from
  /// learner state after a lesson reward is claimed; an event alone does not
  /// unlock a real map location.
  void unlock(MapLocation location) => unlockedLocations.add(location);

  /// Rebuilds the in-memory projection when a learner is restored or changed.
  void replaceUnlocked(Iterable<MapLocation> locations) {
    unlockedLocations
      ..clear()
      ..addAll(locations);
  }
}

/// Makes the app's one [MapProgressController] available to every screen,
/// without threading it through navigation call sites. Same pattern as
/// `AppAnimationScope` (`lib/core/motion/app_animation_controller.dart`).
class MapProgressScope extends InheritedWidget {
  const MapProgressScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final MapProgressController controller;

  /// Returns the shared controller if one is above [context], otherwise a
  /// fresh standalone one -- e.g. a widget test that pumps `MapScreen` (or
  /// a screen that navigates to it) inside a bare `MaterialApp` rather than
  /// the full `TudloApp` shell. That fallback instance isn't shared with
  /// anything else, so overrides/unlocks made through it only last as long
  /// as whatever holds onto it.
  static MapProgressController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MapProgressScope>();
    return scope?.controller ?? MapProgressController();
  }

  @override
  bool updateShouldNotify(MapProgressScope oldWidget) =>
      controller != oldWidget.controller;
}
