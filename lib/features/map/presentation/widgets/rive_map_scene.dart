import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/features/map/domain/map_location.dart';
import 'package:tudloapp/features/map/domain/map_rive_asset.dart';

/// Lets a caller drive a location's Rive-visible state, and read back what
/// Flutter itself last set, without reaching into [RiveMapScene]'s
/// internals. Bound automatically once the scene's Rive file finishes
/// loading; calls made before that (or after the scene is disposed) are
/// silently no-ops, same as every other Rive input in this app that can be
/// asked for before its file is ready.
class RiveMapSceneController {
  _RiveMapSceneState? _state;

  void _attach(_RiveMapSceneState state) => _state = state;

  void _detach(_RiveMapSceneState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Sets `<location>/isUnlocked` -- Flutter-owned truth for whether
  /// [location] is currently reachable. Rive reads this to render the
  /// location gray/locked vs. full-color/accessible, and to play the
  /// locked-tap shake instead of the normal press feedback. Flutter is the
  /// sole owner: there's no Rive-side unlock logic to read back, unlike the
  /// previous map asset.
  void setUnlocked(MapLocation location, bool value) =>
      _state?._setUnlocked(location, value);

  /// Sets `<location>/hasEvent` -- Flutter-owned truth for whether
  /// [location] currently has an active lesson/event. Rive reads this to
  /// render the golden "active event" glow on top of that location's
  /// normal unlocked visual. Independent of [setUnlocked]: a location can
  /// be unlocked with no event, or (in principle) have an event flagged
  /// while still locked -- callers decide the actual combination.
  void setHasEvent(MapLocation location, bool value) =>
      _state?._setHasEvent(location, value);

  /// The unlocked state Flutter itself last set for [location] via
  /// [setUnlocked] (or `false` if the scene isn't ready yet, or nothing's
  /// been set for it yet) -- read this when handling a `locationTapped`
  /// event to decide whether to navigate or show a locked explanation.
  bool isUnlocked(MapLocation location) =>
      _state?._isUnlocked(location) ?? false;
}

/// Interactive Koka's barangay map (`toadlu_map.riv`, default artboard).
/// The Rive file owns the map art, each location's locked/unlocked and
/// active-event *visuals*, its own press/locked-tap feedback, and -- unlike
/// the previous map asset -- tap detection itself, via a `locationTapped`
/// trigger per location that fires from Rive's own internal Listener
/// components. Flutter never lays external tap zones over the art here.
///
/// Per the `MapState` view model's `LocationState` contract (see
/// `docs/RIVE_INTEGRATION.md#barangay-map-contract`):
/// - `<location>/isUnlocked` and `<location>/hasEvent` are Flutter-owned;
///   Rive only renders them (see [RiveMapSceneController.setUnlocked]/
///   [setHasEvent]).
/// - `<location>/locationTapped` is Rive-owned; Flutter only listens (see
///   [onLocationTapped] -- fires for every tap Rive detects, locked or not,
///   the caller decides what a locked tap should do).
/// - `<location>/pressTrigger` is internal to Rive's own press-feedback
///   animation. Flutter must never set or depend on it.
class RiveMapScene extends StatefulWidget {
  const RiveMapScene({
    required this.onLocationTapped,
    this.controller,
    this.onReady,
    super.key,
  });

  static const artboardWidth = 2400.0;
  static const artboardHeight = 1400.0;

  final Future<void> Function(MapLocation location) onLocationTapped;
  final RiveMapSceneController? controller;

  /// Called once the Rive file has finished loading and [controller]'s
  /// imperative methods (`setUnlocked`, `setHasEvent`) start actually doing
  /// something. Callers that need to sync state in from before the scene
  /// was ready (e.g. active-event overrides set while Map wasn't on screen)
  /// should do that sync here.
  final VoidCallback? onReady;

  @override
  State<RiveMapScene> createState() => _RiveMapSceneState();
}

class _RiveMapSceneState extends State<RiveMapScene> {
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  Object? _loadError;
  final _unlockedProps = <MapLocation, rive.ViewModelInstanceBoolean>{};
  final _hasEventProps = <MapLocation, rive.ViewModelInstanceBoolean>{};
  final _tappedTriggers = <MapLocation, rive.ViewModelInstanceTrigger>{};
  final _tappedListeners = <MapLocation, void Function(bool)>{};

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(RiveMapScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  Future<void> _load() async {
    // Shared, app-lifetime file -- decoded once (see MapRiveAsset), never
    // owned/disposed by this widget. This is what makes opening the Map tab
    // instant after the very first load instead of re-decoding a ~4.5MB
    // file on every tab switch.
    final rive.File? file;
    try {
      file = await MapRiveAsset.preload();
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
      }
      return;
    }
    if (!mounted || file == null) return;

    final rive.RiveWidgetController controller;
    final rive.ViewModelInstance viewModel;
    try {
      controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byDefault(),
        stateMachineSelector: rive.StateMachineSelector.byDefault(),
      );
      viewModel = controller.dataBind(rive.DataBind.auto());
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
      }
      return;
    }
    if (!mounted) {
      viewModel.dispose();
      controller.dispose();
      return;
    }

    final unlockedProps = <MapLocation, rive.ViewModelInstanceBoolean>{};
    final hasEventProps = <MapLocation, rive.ViewModelInstanceBoolean>{};
    final tappedTriggers = <MapLocation, rive.ViewModelInstanceTrigger>{};
    final tappedListeners = <MapLocation, void Function(bool)>{};
    for (final location in MapLocation.values) {
      final isUnlocked = viewModel.boolean('${location.riveId}/isUnlocked');
      if (isUnlocked != null) unlockedProps[location] = isUnlocked;
      final hasEvent = viewModel.boolean('${location.riveId}/hasEvent');
      if (hasEvent != null) hasEventProps[location] = hasEvent;

      final tapped = viewModel.trigger('${location.riveId}/locationTapped');
      if (tapped != null) {
        tappedTriggers[location] = tapped;
        void listener(bool _) => unawaited(widget.onLocationTapped(location));
        tapped.addListener(listener);
        tappedListeners[location] = listener;
      }
    }

    setState(() {
      _controller = controller;
      _viewModel = viewModel;
      _unlockedProps
        ..clear()
        ..addAll(unlockedProps);
      _hasEventProps
        ..clear()
        ..addAll(hasEventProps);
      _tappedTriggers
        ..clear()
        ..addAll(tappedTriggers);
      _tappedListeners
        ..clear()
        ..addAll(tappedListeners);
    });
    widget.onReady?.call();
  }

  void _setUnlocked(MapLocation location, bool value) {
    _unlockedProps[location]?.value = value;
  }

  void _setHasEvent(MapLocation location, bool value) {
    _hasEventProps[location]?.value = value;
  }

  bool _isUnlocked(MapLocation location) =>
      _unlockedProps[location]?.value ?? false;

  @override
  void dispose() {
    widget.controller?._detach(this);
    for (final entry in _tappedListeners.entries) {
      _tappedTriggers[entry.key]?.removeListener(entry.value);
    }
    _controller?.dispose();
    _viewModel?.dispose();
    // Deliberately not disposing a File here -- MapRiveAsset's cached file
    // is shared and app-lifetime, not owned by this widget.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SizedBox(
      width: RiveMapScene.artboardWidth,
      height: RiveMapScene.artboardHeight,
      child: _loadError != null
          ? const _RiveMapLoadFallback()
          : controller == null
          ? const SizedBox.shrink()
          : rive.RiveWidget(
              controller: controller,
              fit: rive.Fit.contain,
              alignment: Alignment.center,
              // Default is `opaque`, which claims every pointer straight
              // away regardless of whether it lands on a listener -- once
              // claimed, Flutter keeps routing every PointerMoveEvent for
              // that whole gesture to Rive, so a drag started on empty map
              // background still dispatches a native state-machine
              // pointerMove hit-test on every frame of the pan (this is
              // what was causing the pan/zoom lag: MapScreen's
              // InteractiveViewer sits *around* this widget and pans
              // regardless, so none of that dispatching was ever needed for
              // panning itself). `translucent` only claims a pointer when
              // it actually starts on a location's hit region, so a
              // location tap still fires `locationTapped` exactly as
              // before, but a pan starting on open map art never enters
              // Rive's hit-test/dispatch path at all.
              hitTestBehavior: rive.RiveHitTestBehavior.translucent,
            ),
    );
  }
}

class _RiveMapLoadFallback extends StatelessWidget {
  const _RiveMapLoadFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFB9DDA0),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Text(
              'Map is loading. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF12304A),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
