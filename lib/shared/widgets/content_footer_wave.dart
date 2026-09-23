import 'package:flutter/material.dart';

/// The single wave that closes the bottom of a screen's scrollable content.
///
/// Home, Dictionary, Lessons, Me and Translate all end on the same shape in
/// their own tone, so the path lives here once. Each screen keeps its own
/// wrapper widget and key; only the colour differs.
class ContentFooterWave extends StatelessWidget {
  final Color color;

  /// Key for the painted layer, so a screen's own test can still find it.
  final Key? paintKey;

  const ContentFooterWave({super.key, required this.color, this.paintKey});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        key: paintKey,
        painter: _ContentFooterWavePainter(color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ContentFooterWavePainter extends CustomPainter {
  final Color color;

  const _ContentFooterWavePainter(this.color);

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
  bool shouldRepaint(_ContentFooterWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
