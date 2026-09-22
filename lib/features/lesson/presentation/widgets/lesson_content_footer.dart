import 'package:flutter/material.dart';

/// Decorative closing edge for the bottom of the Lessons screen's
/// scrollable content: a single wave, matching the same shape every other
/// screen's content footer uses (Home/Dictionary/Me), filled with this
/// screen's #00B4D8.
class LessonContentFooter extends StatelessWidget {
  const LessonContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        key: Key('lesson-content-footer'),
        painter: _LessonContentFooterPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _LessonContentFooterPainter extends CustomPainter {
  const _LessonContentFooterPainter();

  static const _waveTone = Color(0xFF00B4D8);

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
    canvas.drawPath(wave, Paint()..color = _waveTone);
  }

  @override
  bool shouldRepaint(_LessonContentFooterPainter oldDelegate) => false;
}
