import 'package:flutter/material.dart';

class AnimatedPointFinger extends StatefulWidget {
  final String asset;
  final double size;
  final double angle;
  final Offset tapOffset;
  final double pressedScale;
  final Duration duration;

  const AnimatedPointFinger({
    super.key,
    required this.asset,
    required this.size,
    this.angle = -0.55,
    this.tapOffset = const Offset(-8, -8),
    this.pressedScale = .86,
    this.duration = const Duration(milliseconds: 780),
  });

  @override
  State<AnimatedPointFinger> createState() => _AnimatedPointFingerState();
}

class _AnimatedPointFingerState extends State<AnimatedPointFinger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1, end: widget.pressedScale).animate(curve);
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: widget.tapOffset,
    ).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _offset.value,
          child: Transform.scale(
            scale: _scale.value,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: Transform.rotate(
        angle: widget.angle,
        child: Image.asset(
          widget.asset,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
