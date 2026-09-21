import 'package:flutter/material.dart';

/// A small interactive tile that tilts in 3D toward wherever it's touched,
/// then springs back — the same touch-to-tilt contract as the learner
/// card, scaled down for thumbnail-sized content (Home's sticker grid,
/// Me's badge grid).
///
/// It intentionally owns only presentation motion; image/locked overlays
/// and any other state stay in the caller so this tile can be reused
/// unchanged wherever a thumbnail-sized tilt is needed.
class TiltThumbnailTile extends StatefulWidget {
  const TiltThumbnailTile({required this.child, super.key});

  final Widget child;

  @override
  State<TiltThumbnailTile> createState() => _TiltThumbnailTileState();
}

class _TiltThumbnailTileState extends State<TiltThumbnailTile>
    with SingleTickerProviderStateMixin {
  static const _tiltDuration = Duration(milliseconds: 850);
  // The learner card is far larger than a thumbnail. Keep its motion
  // profile while scaling only the rendered angle so the same response reads.
  static const _thumbnailTiltMultiplier = 2.4;

  late final AnimationController _tiltController = AnimationController(
    vsync: this,
    duration: _tiltDuration,
  );

  double _targetTiltX = 0;
  double _targetTiltY = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _tiltController
        ..stop()
        ..value = 0;
    }
  }

  void _tilt(Offset localPosition) {
    if (_reduceMotion) return;
    final box = context.findRenderObject()! as RenderBox;
    final normalizedX = (localPosition.dx / box.size.width - .5).clamp(-.5, .5);
    final normalizedY = (localPosition.dy / box.size.height - .5).clamp(
      -.5,
      .5,
    );
    // Match the learner card's touch-to-tilt contract exactly.
    _targetTiltX = normalizedY * .12;
    _targetTiltY = -normalizedX * .16;
    _tiltController.forward(from: 0);
  }

  double get _tiltStrength {
    final value = _tiltController.value;
    if (value <= .24) {
      return Curves.easeOutCubic.transform(value / .24);
    }
    return 1 - Curves.elasticOut.transform((value - .24) / .76);
  }

  @override
  void dispose() {
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _tilt(event.localPosition),
      child: AnimatedBuilder(
        animation: _tiltController,
        // Rasterize the content once into its own cached layer so the
        // per-frame Transform below repaints a stable bitmap instead of
        // re-tessellating live vector content (SVG badges) at a slightly
        // different perspective every frame, which reads as a flicker.
        child: RepaintBoundary(child: widget.child),
        builder: (context, child) {
          final strength = _tiltStrength;
          final tiltTransform = Matrix4.identity();
          if (strength.abs() > .0001) {
            tiltTransform
              ..setEntry(3, 2, .0012)
              ..rotateX(_targetTiltX * strength * _thumbnailTiltMultiplier)
              ..rotateY(_targetTiltY * strength * _thumbnailTiltMultiplier);
          }
          return Transform(
            alignment: Alignment.center,
            transform: tiltTransform,
            child: child,
          );
        },
      ),
    );
  }
}
