import 'package:flutter/material.dart';

/// Decorative closing edge for the bottom of the Dictionary screens'
/// scrollable content: a single wave, matching the same shape every other
/// screen's content footer uses (Home/Me), filled with this screen's
/// #FF667D.
class DictionaryContentFooter extends StatelessWidget {
  const DictionaryContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        key: Key('dictionary-content-footer'),
        painter: _DictionaryContentFooterPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _DictionaryContentFooterPainter extends CustomPainter {
  const _DictionaryContentFooterPainter();

  static const _waveTone = Color(0xFFFF667D);

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
  bool shouldRepaint(_DictionaryContentFooterPainter oldDelegate) => false;
}
