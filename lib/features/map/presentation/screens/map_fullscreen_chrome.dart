import 'package:flutter/services.dart';

/// Device orientation and system UI for the Map's landscape view.
///
/// Kept apart from the screen because it is the one part of fullscreen that
/// is not layout: it talks to SystemChrome, and the lesson map beat drives it
/// through the same calls the expand button does.
abstract final class MapFullscreenChrome {
  static const _portrait = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  static const _landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// Goes landscape and hides the system bars.
  static void enter() {
    SystemChrome.setPreferredOrientations(_landscape);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Returns to the app's usual portrait, edge-to-edge presentation.
  static void restorePortrait() {
    SystemChrome.setPreferredOrientations(_portrait);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
