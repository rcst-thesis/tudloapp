import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';

/// Ink-fill text with a white outline, via a stacked stroke-then-fill
/// `Text` pair -- the same technique `DictionaryHeader` used for its title
/// art before that became an SVG. Used for word/phonetic/definition text
/// that needs the white stroke; plain faded text (example, "tap to flip")
/// doesn't use this.
class DictionaryStrokedText extends StatelessWidget {
  const DictionaryStrokedText(
    this.text, {
    required this.fontSize,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.textAlign = TextAlign.start,
    this.strokeWidth,
    super.key,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final TextAlign textAlign;

  /// Defaults to a width proportional to [fontSize] when omitted.
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'ComicRelief',
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontSize: fontSize,
      height: 1.2,
    );
    final resolvedStrokeWidth = strokeWidth ?? fontSize / 10;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text,
              textAlign: textAlign,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = resolvedStrokeWidth
                  ..color = Colors.white,
              ),
            ),
            Text(
              text,
              textAlign: textAlign,
              style: style.copyWith(color: DictionaryColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
