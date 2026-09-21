import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';

/// Renders the looping ambient background behind a learner's [RiveAvatar] --
/// one of three grade-specific `.riv` files (`assets/images/
/// avatar_bg_grade1.riv`/`_grade2.riv`/`_grade3.riv`), selected by
/// [grade] (`1`-`3`, the only values the app produces --
/// `grade_selection_screen.dart`'s fixed 3-choice carousel). Each file has
/// no ViewModel/data binding (`viewModelCount` is 0), same as `avatar.riv`
/// itself -- just one self-contained Artboard with an ambient
/// diagonal-scroll loop that runs on its own once its state machine starts,
/// so this never calls `dataBind` and never sets/reads any input.
///
/// This native Rive loop is the heaviest ambient effect in the app (a
/// continuously-running engine state machine, not just a cheap Flutter
/// `AnimationController`), so it's the one effect gated by
/// [effectiveHeavyAmbientMotionEnabled] specifically -- only High Quality
/// keeps it loaded/running; every other tier (or the toggle/reduce-motion
/// falling through [effectiveAmbientMotionEnabled]) shows [_BackgroundFallback]
/// instead, same flat-cream visual already used while the file loads.
class RiveAvatarBackground extends StatefulWidget {
  const RiveAvatarBackground({required this.grade, super.key});

  final int grade;

  static String _assetPathFor(int grade) =>
      'assets/images/avatar_bg_grade$grade.riv';

  static String _artboardNameFor(int grade) => 'Grade${grade}_Background';

  // Shared across every `RiveAvatarBackground` instance (the learner card
  // and the Edit popup both want the same grade's file) so each file is
  // only ever decoded once -- same "shared, never disposed" reasoning
  // `RiveAvatar` uses: loading the same file concurrently from multiple
  // call sites previously deadlocked the native Rive backend for that
  // widget, so this cache is required, not just an optimization.
  static final Map<String, Future<rive.File?>> _fileCache = {};

  static Future<rive.File?> _loadFile(String assetPath) {
    return _fileCache[assetPath] ??= rive.File.asset(
      assetPath,
      riveFactory: rive.Factory.flutter,
    );
  }

  @override
  State<RiveAvatarBackground> createState() => _RiveAvatarBackgroundState();
}

class _RiveAvatarBackgroundState extends State<RiveAvatarBackground> {
  rive.RiveWidgetController? _controller;
  var _heavyAmbientEnabled = false;
  var _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also covers the very first resolution after `initState` (guaranteed
    // to run once before the first build) -- there's no separate
    // `initState`-triggered load here, since `effectiveHeavyAmbientMotionEnabled`
    // needs an inherited-widget lookup that isn't safe in `initState` yet.
    final heavyAmbientEnabled = effectiveHeavyAmbientMotionEnabled(context);
    if (_heavyAmbientEnabled == heavyAmbientEnabled) return;
    _heavyAmbientEnabled = heavyAmbientEnabled;
    if (!heavyAmbientEnabled) {
      // Swaps to `_BackgroundFallback` below -- same flat-cream visual
      // already shown while the file loads, just as a deliberate "lighter
      // tier" choice here rather than a loading state.
      _controller?.dispose();
      setState(() => _controller = null);
    } else if (_controller == null && !_loading) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(covariant RiveAvatarBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grade != widget.grade) {
      _controller?.dispose();
      _controller = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (!_heavyAmbientEnabled) return;
    _loading = true;
    try {
      final assetPath = RiveAvatarBackground._assetPathFor(widget.grade);
      final file = await RiveAvatarBackground._loadFile(assetPath);
      if (file == null || !mounted || !_heavyAmbientEnabled) return;

      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardNamed(
          RiveAvatarBackground._artboardNameFor(widget.grade),
        ),
      );
      setState(() => _controller = controller);
    } catch (_) {
      // Best-effort -- a missing asset, an unrecognized grade, or no
      // native backend (e.g. some widget tests) falls back to the plain
      // placeholder below rather than crashing.
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    // Only this instance's own Artboard/StateMachine -- never the shared
    // `File` itself, which other `RiveAvatarBackground` instances may
    // still be using.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return controller == null
        ? const _BackgroundFallback()
        : rive.RiveWidget(
            controller: controller,
            fit: rive.Fit.cover,
            alignment: Alignment.center,
          );
  }
}

/// Same flat cream this background replaced -- shown while the Rive asset
/// initializes, and if it never can (missing asset, no native backend).
class _BackgroundFallback extends StatelessWidget {
  const _BackgroundFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFFFE49A)),
    );
  }
}
