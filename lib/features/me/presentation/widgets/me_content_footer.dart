import 'package:flutter/material.dart';

/// Decorative closing edge for the bottom of the Me screen's scrollable
/// content: a single wave, matching the lowest/front wave shape from
/// Home's content footer, filled with this screen's #9D7C21.
class MeContentFooter extends StatelessWidget {
  const MeContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        key: Key('me-content-footer'),
        painter: _MeContentFooterPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _MeContentFooterPainter extends CustomPainter {
  const _MeContentFooterPainter();

  static const _waveTone = Color(0xFF9D7C21);

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
  bool shouldRepaint(_MeContentFooterPainter oldDelegate) => false;
}
