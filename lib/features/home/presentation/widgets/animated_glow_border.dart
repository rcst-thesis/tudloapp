import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';

/// A reusable rounded border with a continuously travelling gradient glow.
class AnimatedGlowBorder extends StatefulWidget {
  const AnimatedGlowBorder({
    required this.child,
    this.strokeWidth = 1.5,
    this.gradientColors = const [
      Color(0xFFF9C1CB),
      Color(0xFFCBEAFA),
      Color(0xFF98EF6F),
    ],
    this.duration = const Duration(seconds: 4),
    this.borderRadius = 11,
    super.key,
  }) : assert(strokeWidth > 0),
       assert(gradientColors.length > 0),
       assert(borderRadius >= 0);

  final Widget child;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Duration duration;
  final double borderRadius;

  @override
  State<AnimatedGlowBorder> createState() => _AnimatedGlowBorderState();
}

class _AnimatedGlowBorderState extends State<AnimatedGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!effectiveAmbientMotionEnabled(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration == oldWidget.duration) return;
    _controller.duration = widget.duration;
    if (effectiveAmbientMotionEnabled(context) && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _GlowBorderPainter(
          progress: _controller,
          strokeWidth: widget.strokeWidth,
          gradientColors: widget.gradientColors,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  const _GlowBorderPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.borderRadius,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double strokeWidth;
  final List<Color> gradientColors;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const glowSpread = 3.5;
    // Keep the crisp trail centered on the supplied frame's outer perimeter.
    // The wider blurred pass is allowed to feather around that same path.
    final inset = strokeWidth / 2;
    final borderRect = Offset.zero & size;
    final paintRect = borderRect.deflate(inset);
    if (paintRect.width <= 0 || paintRect.height <= 0) return;

    final radius = math.max(0, borderRadius - inset).toDouble();
    final border = RRect.fromRectAndRadius(paintRect, Radius.circular(radius));

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + glowSpread
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
      ..shader = _perimeterShader(borderRect, .38);
    canvas.drawRRect(border, glowPaint);

    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = _perimeterShader(borderRect, 1);
    canvas.drawRRect(border, trailPaint);
  }

  Shader _perimeterShader(Rect rect, double opacity) {
    final colors = <Color>[
      ...gradientColors.map((color) => color.withValues(alpha: opacity)),
      gradientColors.first.withValues(alpha: opacity),
    ];
    final stops = List<double>.generate(
      colors.length,
      (index) => index / (colors.length - 1),
    );

    return SweepGradient(
      colors: colors,
      stops: stops,
      transform: GradientRotation(progress.value * math.pi * 2),
    ).createShader(rect);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) {
    return strokeWidth != oldDelegate.strokeWidth ||
        borderRadius != oldDelegate.borderRadius ||
        !_sameColors(gradientColors, oldDelegate.gradientColors);
  }

  bool _sameColors(List<Color> left, List<Color> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
