import 'package:flutter/material.dart';

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

class GradeThreePressable extends StatefulWidget {
  const GradeThreePressable({
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.playButtonSound = true,
    this.borderRadius = 18,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool playButtonSound;
  final double borderRadius;

  @override
  State<GradeThreePressable> createState() => _GradeThreePressableState();
}

class _GradeThreePressableState extends State<GradeThreePressable> {
  static const _duration = Duration(milliseconds: 80);

  var _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_interactive) return;
    if (widget.playButtonSound) {
      TudloAudioScope.maybeOf(context)?.playButtonTapSound();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .965 : 1,
      duration: _duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _pressed ? const Offset(0, .035) : Offset.zero,
        duration: _duration,
        curve: Curves.easeOut,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _interactive ? (_) => _setPressed(true) : null,
          onTapCancel: _interactive ? () => _setPressed(false) : null,
          onTapUp: _interactive ? (_) => _setPressed(false) : null,
          onTap: _interactive ? _handleTap : null,
          child: widget.child,
        ),
      ),
    );
  }
}
