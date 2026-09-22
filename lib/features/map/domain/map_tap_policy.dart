import 'package:tudloapp/features/map/domain/map_route_resolver.dart';

/// Decides whether a tap is allowed to leave the real Rive map.
///
/// A location's permanent visual availability remains [isUnlocked]. The
/// exceptions are the currently scheduled lesson event and a lesson's own
/// in-lesson map beat ([PopMapRouteAction]): both must be reachable before
/// completion/claim earns the location, but neither changes that flag.
class MapTapPolicy {
  const MapTapPolicy._();

  static bool canOpen({
    required bool isUnlocked,
    required MapRouteAction action,
  }) =>
      isUnlocked ||
      action is OpenActiveLessonRouteAction ||
      action is PopMapRouteAction;
}
