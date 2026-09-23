import 'package:flutter/material.dart';

/// Covers a region of an exported SVG where text was baked into vector
/// paths, so a matching-colored patch can sit under real Flutter text.
class SvgTextMask extends StatelessWidget {
  const SvgTextMask({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.scale,
    required this.color,
    super.key,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: width * scale,
      height: height * scale,
      child: ColoredBox(color: color),
    );
  }
}

/// Real, accessible Flutter text placed at an exported SVG card's original
/// (masked) text position, scaled with the rest of the artwork.
class SvgCardText extends StatelessWidget {
  const SvgCardText({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.scale,
    required this.fontSize,
    this.color = Colors.white,
    this.fontWeight = FontWeight.w700,
    this.autoFit = false,
    this.alignment = Alignment.center,
    super.key,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
  final double scale;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final bool autoFit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: width * scale,
      height: height * scale,
      child: autoFit
          ? FittedBox(fit: BoxFit.scaleDown, child: _textWidget())
          : Align(alignment: alignment, child: _textWidget()),
    );
  }

  Widget _textWidget() {
    return Text(
      text,
      textAlign: alignment == Alignment.centerLeft
          ? TextAlign.left
          : TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontFamily: 'ComicRelief',
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        height: 1,
      ),
    );
  }
}
