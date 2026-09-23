import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Renders one avatar by its public [artboardId] -- the learner's chosen
/// Koka avatar (Me screen's own preview, and the Edit popup's bigger preview
/// and per-tile thumbnails). Every avatar's own `.riv` file has no
/// ViewModel/data binding (just one self-contained Artboard per file, with
/// its own blink/pupil-follow state machine), so unlike
/// [RiveLongButton]/[RiveLoadNavButton] this never calls `dataBind` -- it
/// only ever needs to select an Artboard by name and let its own state
/// machine run.
class RiveAvatar extends StatefulWidget {
  const RiveAvatar({required this.artboardId, super.key});

  static const _basePath = 'assets/images/avatar.riv';

  /// Extra avatars that live in their own single-Artboard `.riv` files
  /// rather than as additional Artboards inside `avatar.riv` (unlike that
  /// file, these can't be re-exported/renamed right now). Keys are the
  /// public id used everywhere else in the app -- persistence, grid
  /// `Key`s, semantics labels; values point at the file plus that file's
  /// internal Artboard name, which is **only ever used for this one Rive
  /// lookup** and must never be surfaced in UI, semantics, logs, or
  /// persisted data. Some of these internal Artboard names are offensive
  /// (ethnic-stereotype/slur labels baked into the export by whoever made
  /// it) -- kept out of this file's comments deliberately; see the
  /// mapping itself only if you need the exact strings.
  static const _extraSources = <String, _AvatarSource>{
    'avatar_2': _AvatarSource('assets/images/avatar_2.riv', 'Sub_Nigga_Color'),
    'avatar_3': _AvatarSource('assets/images/avatar_3.riv', 'Nigga_Color'),
    'avatar_4': _AvatarSource(
      'assets/images/avatar_4.riv',
      'African_Nigga_Color',
    ),
    'avatar_5': _AvatarSource('assets/images/avatar_5.riv', 'Great_Color'),
    'avatar_6': _AvatarSource('assets/images/avatar_6.riv', 'Indian_Color'),
    'avatar_7': _AvatarSource('assets/images/avatar_7.riv', 'Filipino_Color'),
    'avatar_8': _AvatarSource('assets/images/avatar_8.riv', 'ChingChong_Color'),
  };

  final String artboardId;

  // Shared across every `RiveAvatar` instance (the header preview and each
  // grid tile all want the same files) and by [availableArtboardIds], so
  // each file is only ever decoded once. Loading a given file concurrently
  // from multiple call sites previously deadlocked the native Rive backend
  // -- caching the in-flight/decoded `File` per path here means later
  // callers just await the same `Future` instead of triggering their own
  // concurrent decode. Never disposed: meant to live for the app's
  // lifetime, same as a cached font or image asset.
  static final Map<String, Future<rive.File?>> _fileCache = {};

  static Future<rive.File?> _loadFile(String assetPath) {
    return _fileCache[assetPath] ??= rive.File.asset(
      assetPath,
      riveFactory: rive.Factory.flutter,
    );
  }

  /// Resolves a public [artboardId] to the file/Artboard-name it actually
  /// lives at: [_extraSources] for the ids listed there, otherwise
  /// `avatar.riv` itself (where today the Artboard's own name -- e.g.
  /// `Ok_Color` -- doubles as the public id, since that file's Artboards
  /// are all neutrally named already).
  static _AvatarSource _resolve(String artboardId) =>
      _extraSources[artboardId] ?? _AvatarSource(_basePath, artboardId);

  /// Every available avatar id, in a stable order -- every Artboard
  /// currently in `avatar.riv` (read from the file itself rather than a
  /// hardcoded count, so the grid grows automatically as more Artboards are
  /// added to that file later), followed by every id in [_extraSources].
  /// Returns just the extra ids if `avatar.riv` can't be read (e.g. no
  /// native Rive backend available, such as some widget tests).
  static Future<List<String>> availableArtboardIds() async {
    final ids = <String>[];
    try {
      final file = await _loadFile(_basePath);
      if (file != null) {
        var index = 0;
        while (true) {
          final artboard = file.artboardAt(index);
          if (artboard == null) break;
          ids.add(artboard.name);
          index++;
        }
      }
    } catch (_) {
      // Best-effort -- fall through to just the extra ids below.
    }
    ids.addAll(_extraSources.keys);
    return ids;
  }

  @override
  State<RiveAvatar> createState() => _RiveAvatarState();
}

/// Where one public avatar id's Artboard actually lives: which `.riv`
/// [assetPath], and that file's own internal [artboardName] -- see
/// [RiveAvatar._extraSources] for why these two are sometimes different.
class _AvatarSource {
  const _AvatarSource(this.assetPath, this.artboardName);

  final String assetPath;
  final String artboardName;
}

class _RiveAvatarState extends State<RiveAvatar> {
  rive.RiveWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant RiveAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artboardId != widget.artboardId) {
      // Keeps the *old* controller on screen (not disposed/nulled here)
      // until `_load` actually has the new one ready -- switching avatars
      // (e.g. tapping a different tile in the Edit popup's grid) used to
      // dispose+null immediately, which meant `build` briefly rendered
      // `_AvatarFallback`'s flat cream over whatever now sits behind this
      // widget (e.g. a grade background) instead of the avatar itself.
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    try {
      final source = RiveAvatar._resolve(widget.artboardId);
      final file = await RiveAvatar._loadFile(source.assetPath);
      if (file == null || !mounted) return;

      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardNamed(source.artboardName),
      );
      final oldController = _controller;
      setState(() => _controller = controller);
      oldController?.dispose();
    } catch (_) {
      // Best-effort -- a missing asset, an unknown artboardId, or no
      // native backend (e.g. some widget tests) falls back to the plain
      // placeholder below rather than crashing.
    }
  }

  @override
  void dispose() {
    // Only this instance's own Artboard/StateMachine -- never the shared
    // `File` itself, which other `RiveAvatar` instances may still be using.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return controller == null
        ? const _AvatarFallback()
        : rive.RiveWidget(
            controller: controller,
            fit: rive.Fit.contain,
            alignment: Alignment.center,
          );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFFFE49A),
        shape: BoxShape.circle,
      ),
    );
  }
}
