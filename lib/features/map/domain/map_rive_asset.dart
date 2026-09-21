import 'package:rive/rive.dart' as rive;

/// Caches the map's decoded Rive [rive.File] for the app's lifetime, so
/// opening the Map tab is instant after the very first load. Without this,
/// `RiveMapScene` decoded the ~4.5MB `.riv` file from scratch every single
/// time the Map tab was opened (`AppBottomTabNavigation` rebuilds
/// `MapScreen`/`RiveMapScene` fresh on every tab switch), causing a visible
/// blank pause before the art appeared.
///
/// Call [preload] once, as early as possible (see `main.dart`, right after
/// `RiveNative.init()`), so decoding is already done -- or well underway,
/// overlapping with startup/onboarding -- by the time the learner first
/// taps the Map tab.
///
/// This [rive.File] is intentionally never disposed by screen-level code;
/// it lives for the app's lifetime, same as `MapProgressController`.
/// Multiple `RiveWidgetController`s can be created from the same decoded
/// file safely, so each `RiveMapScene` instance only disposes its own
/// controller/view-model instance, never this shared file.
abstract final class MapRiveAsset {
  static const _assetPath = 'assets/images/toadlu_map.riv';

  static Future<rive.File?>? _future;

  /// Starts loading (if not already started) and returns the shared
  /// future. Safe to call multiple times or concurrently -- the file is
  /// only ever decoded once.
  static Future<rive.File?> preload() {
    return _future ??= rive.File.asset(
      _assetPath,
      riveFactory: rive.Factory.flutter,
    );
  }
}
