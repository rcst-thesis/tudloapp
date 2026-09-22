import 'dart:ui';

import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/presentation/widgets/rive_map_scene.dart';

/// Where the Map's camera sits, in the map artwork's own coordinates.
///
/// Separate from the screen because these are properties of the art and of
/// each framing (portrait, fullscreen, a lesson's focus), not of the widget
/// that renders them.
abstract final class MapCamera {
  static const mapWidth = RiveMapScene.artboardWidth;
  static const mapHeight = RiveMapScene.artboardHeight;

  /// Koka's house sits roughly here in the map art; frames portrait by default.
  static const houseCenterX = 2085.0;
  static const houseCenterY = 1064.5;
  static const portraitCropWidth = 420.0;
  static const portraitVerticalAnchor = 0.42;

  /// A lesson pointing at a location pulls back a little further than the
  /// default portrait framing so the target sits in context.
  static const lessonFocusCropWidth = 520.0;
  static const lessonFocusVerticalAnchor = 0.48;

  /// Fullscreen/landscape zooms out to show nearly the whole map instead.
  static const fullscreenCropWidth = mapWidth * 0.96;
  static const fullscreenCenterX = mapWidth / 2;
  static const fullscreenCenterY = mapHeight / 2;

  static const focusCenters = <MapLocation, Offset>{
    MapLocation.house: Offset(houseCenterX, houseCenterY),
    MapLocation.school: Offset(1280, 1160),
    MapLocation.market: Offset(1990, 455),
    MapLocation.farm: Offset(2170, 930),
  };
}
