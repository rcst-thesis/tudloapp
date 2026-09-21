import 'package:tudloapp/features/map/domain/map_route_resolver.dart';

/// Decides whether a tap is allowed to leave the real Rive map.
///
/// A location's permanent visual availability remains [isUnlocked]. The one
/// exception is the currently scheduled lesson event: it must be reachable
/// before its completion earns the location, but it never changes that flag.
class MapTapPolicy {
  const MapTapPolicy._();

  static bool canOpen({
    required bool isUnlocked,
    required MapRouteAction action,
  }) => isUnlocked || action is OpenActiveLessonRouteAction;
}
