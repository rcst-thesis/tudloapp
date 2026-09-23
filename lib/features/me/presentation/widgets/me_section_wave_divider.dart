import 'package:flutter/material.dart';

/// Wavy transition between the Me screen's two background bands, replacing
/// a flat horizontal cut. Same single-wave shape as [MeContentFooter]; only
/// the wave itself is painted; everything else in its bounds stays
/// transparent so the section above shows through above the curve.
class MeSectionWaveDivider extends StatelessWidget {
  const MeSectionWaveDivider({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        key: const Key('me-section-wave-divider'),
        painter: _MeSectionWaveDividerPainter(color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MeSectionWaveDividerPainter extends CustomPainter {
  const _MeSectionWaveDividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final wave = Path()
      ..moveTo(0, height * .52)
      ..cubicTo(
        width * .15,
        height * .39,
        width * .29,
        height * .45,
        width * .43,
        height * .53,
      )
      ..cubicTo(
        width * .58,
        height * .63,
        width * .70,
        height * .58,
        width * .81,
        height * .45,
      )
      ..cubicTo(
        width * .90,
        height * .34,
        width * .96,
        height * .35,
        width,
        height * .31,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(wave, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MeSectionWaveDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
