import 'package:flutter/material.dart';

import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/placeholder/presentation/placeholder_screen.dart';

/// What happens when a map location's tap resolves. Most locations push a
/// screen; House's default action displays a destination chooser, so it is
/// modeled separately from a push.
sealed class MapRouteAction {
  const MapRouteAction();
}

/// Pops back to the app's root route, same as tapping the Home tab.
class GoHomeRouteAction extends MapRouteAction {
  const GoHomeRouteAction();
}

/// Displays House's two child-friendly destinations: Home or House lessons.
/// Active lesson events bypass this route and use [OpenActiveLessonRouteAction].
class ShowHouseChoiceRouteAction extends MapRouteAction {
  const ShowHouseChoiceRouteAction();
}

/// Opens the grade-aware lessons catalog filtered to [location].
class OpenLessonCatalogRouteAction extends MapRouteAction {
  const OpenLessonCatalogRouteAction(this.location);

  final MapLocation location;
}

/// Opens the active lesson identified by a stable Flutter catalog ID.
/// The ID is never read from or written to Rive.
class OpenActiveLessonRouteAction extends MapRouteAction {
  const OpenActiveLessonRouteAction(this.lessonId);

  final String lessonId;
}

/// Pushes the screen built by [builder].
class PushScreenRouteAction extends MapRouteAction {
  const PushScreenRouteAction(this.builder);

  final WidgetBuilder builder;
}

/// Pops the current [MapScreen] route instead of navigating onward.
///
/// Used when a lesson step pushes the real [MapScreen] as a one-off,
/// in-lesson "tap the map" beat (its own standalone [MapEventOverrides]
/// instance, not the app's shared one) rather than the persistent Map tab:
/// tapping the target location should resume the lesson step that pushed
/// it, not open a new lesson/catalog/screen.
class PopMapRouteAction extends MapRouteAction {
  const PopMapRouteAction();
}

/// Flutter-owned default destination for each map location. Lesson-mapped
/// locations share the catalog used by the Lessons tab; unrelated locations
/// keep their existing temporary shells.
class MapDefaultRoutes {
  const MapDefaultRoutes._();

  static const Map<MapLocation, MapRouteAction> _actions = {
    MapLocation.house: ShowHouseChoiceRouteAction(),
    MapLocation.school: OpenLessonCatalogRouteAction(MapLocation.school),
    MapLocation.plaza: OpenLessonCatalogRouteAction(MapLocation.plaza),
    MapLocation.market: OpenLessonCatalogRouteAction(MapLocation.market),
    MapLocation.farm: PushScreenRouteAction(_farm),
    MapLocation.beach: PushScreenRouteAction(_beach),
    MapLocation.church: PushScreenRouteAction(_church),
    MapLocation.hospital: PushScreenRouteAction(_hospital),
  };

  static MapRouteAction actionFor(MapLocation location) =>
      _actions[location] ?? const GoHomeRouteAction();

  static Widget _farm(BuildContext context) => const PlaceholderScreen(
    title: 'Farm',
    description: 'Temporary Farm shell',
    icon: Icons.agriculture_rounded,
  );

  static Widget _beach(BuildContext context) => const PlaceholderScreen(
    title: 'Beach',
    description: 'Temporary Beach shell',
    icon: Icons.beach_access_rounded,
  );

  static Widget _church(BuildContext context) => const PlaceholderScreen(
    title: 'Church',
    description: 'Temporary Church shell',
    icon: Icons.church_rounded,
  );

  static Widget _hospital(BuildContext context) => const PlaceholderScreen(
    title: 'Hospital',
    description: 'Temporary Hospital shell',
    icon: Icons.local_hospital_rounded,
  );
}

/// Flutter-owned truth for any lesson/event that currently overrides a map
/// location's default destination. Empty by default (no active event), in
/// which case every location resolves to [MapDefaultRoutes]. A caller (the
/// future lesson/event system) sets an override while its lesson/event is
/// active and clears it when that lesson/event ends, restoring the default.
class MapEventOverrides extends ChangeNotifier {
  final Map<MapLocation, MapRouteAction> _overrides = {};

  MapRouteAction? overrideFor(MapLocation location) => _overrides[location];

  /// Resolves [location]'s current destination: its active-event override
  /// if one is set, otherwise its default route.
  MapRouteAction resolve(MapLocation location) =>
      _overrides[location] ?? MapDefaultRoutes.actionFor(location);

  void setOverride(MapLocation location, MapRouteAction action) {
    _overrides[location] = action;
    notifyListeners();
  }

  void clearOverride(MapLocation location) {
    if (_overrides.remove(location) != null) notifyListeners();
  }

  /// Clears every override, e.g. when the active event ends. All locations
  /// return to their default routes.
  void clearAll() {
    if (_overrides.isEmpty) return;
    _overrides.clear();
    notifyListeners();
  }
}
