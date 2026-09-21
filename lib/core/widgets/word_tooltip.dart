import 'package:flutter/material.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

String translatedMeaningFor(String text) {
  // Word tooltips use the dictionary dataset, not LessonBank. LessonBank may
  // contain full sentences, while this lookup should stay word/short-phrase
  // focused for dictionary-style hints.
  return DictionaryData.meaningFor(text);
}

/// Text shown inside the tap-to-translate tooltip.
class WordMeaning {
  final String word;
  final String meaning;
  final String note;

  const WordMeaning({
    required this.word,
    required this.meaning,
    this.note = 'Vocabulary hint',
  });
}

/// Renders a question sentence while making only the target phrase tappable.
///
/// Keeping one tappable phrase prevents multiple hints from appearing in one
/// prompt and avoids confusing hints such as Water -> Water.
class TapWordMeaningText extends StatefulWidget {
  final String fullQuestionText;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool includeKnownWords;

  const TapWordMeaningText({
    super.key,
    required this.fullQuestionText,
    required this.targetPhrase,
    required this.targetMeaning,
    required this.directionLabel,
    this.style,
    this.textAlign = TextAlign.start,
    this.includeKnownWords = false,
  });

  @override
  State<TapWordMeaningText> createState() => _TapWordMeaningTextState();
}

class _TapWordMeaningTextState extends State<TapWordMeaningText> {
  @override
  void dispose() {
    _MeaningTooltipOverlay.hide();
    super.dispose();
  }

  void _showTooltip(BuildContext wordContext, _TappableTextTarget target) {
    final word = widget.fullQuestionText.substring(target.start, target.end);
    _MeaningTooltipOverlay.show(
      context: context,
      anchorContext: wordContext,
      word: word,
      meaning: target.meaning,
      note: target.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        const TextStyle(
          color: TudloColors.ink,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w900,
        );

    final targets = _tappableTargets();
    if (targets.isEmpty) {
      return Text(
        widget.fullQuestionText,
        style: style,
        textAlign: widget.textAlign,
      );
    }

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final target in targets) {
      if (target.start > cursor) {
        children.add(
          TextSpan(
            text: widget.fullQuestionText.substring(cursor, target.start),
          ),
        );
      }
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Builder(
            builder: (wordContext) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showTooltip(wordContext, target),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: style.copyWith(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: TudloColors.brightGreen,
                    decorationThickness: 2,
                    backgroundColor: TudloColors.softGreen.withValues(
                      alpha: .42,
                    ),
                  ),
                  child: Text(
                    widget.fullQuestionText.substring(target.start, target.end),
                  ),
                ),
              );
            },
          ),
        ),
      );
      cursor = target.end;
    }
    if (cursor < widget.fullQuestionText.length) {
      children.add(TextSpan(text: widget.fullQuestionText.substring(cursor)));
    }

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(style: style, children: children),
    );
  }

  List<_TappableTextTarget> _tappableTargets() {
    // Prefer the lesson's target phrase. If the visible prompt only contains
    // part of that phrase, such as "Maayong ___", fall back to dictionary words
    // that are actually visible in the bubble.
    final phrase = widget.targetPhrase.trim();
    final targets = <_TappableTextTarget>[];
    if (phrase.isNotEmpty) {
      final targetMeaning = widget.targetMeaning.trim();
      final fallbackMeaning = translatedMeaningFor(phrase);
      final meaning = targetMeaning.isEmpty ? fallbackMeaning : targetMeaning;
      if (meaning.isNotEmpty) {
        for (final match in _phraseMatches(phrase)) {
          targets.add(
            _TappableTextTarget(
              start: match.start,
              end: match.end,
              meaning: meaning,
              note: widget.directionLabel,
            ),
          );
        }
      }
    }

    if (widget.includeKnownWords) {
      for (final match in _wordMatches(widget.fullQuestionText)) {
        final meaning = translatedMeaningFor(match.text);
        if (meaning.isEmpty) continue;
        final overlaps = targets.any((target) {
          return match.start < target.end && match.end > target.start;
        });
        if (overlaps) continue;
        targets.add(
          _TappableTextTarget(
            start: match.start,
            end: match.end,
            meaning: meaning,
            note: 'Vocabulary hint',
          ),
        );
      }
    }
    targets.sort((a, b) => a.start.compareTo(b.start));
    return targets;
  }

  List<_PhraseMatch> _phraseMatches(String phrase) {
    final escaped = RegExp.escape(phrase);
    final regex = RegExp(
      r'(?<![A-Za-z])' + escaped + r'(?![A-Za-z])',
      caseSensitive: false,
    );
    return [
      for (final match in regex.allMatches(widget.fullQuestionText))
        _PhraseMatch(
          start: match.start,
          end: match.end,
          text: widget.fullQuestionText.substring(match.start, match.end),
        ),
    ];
  }

  List<_PhraseMatch> _wordMatches(String text) {
    return [
      for (final match in RegExp(
        r"[A-Za-zÀ-ÿ]+(?:[-'][A-Za-zÀ-ÿ]+)*",
      ).allMatches(text))
        _PhraseMatch(
          start: match.start,
          end: match.end,
          text: text.substring(match.start, match.end),
        ),
    ];
  }
}

class _TappableTextTarget {
  final int start;
  final int end;
  final String meaning;
  final String note;

  const _TappableTextTarget({
    required this.start,
    required this.end,
    required this.meaning,
    required this.note,
  });
}

class _PhraseMatch {
  final int start;
  final int end;
  final String text;

  const _PhraseMatch({
    required this.start,
    required this.end,
    required this.text,
  });
}

class WordMeaningTooltipTarget extends StatefulWidget {
  final String meaning;
  final bool showOnTap;
  final Widget child;

  const WordMeaningTooltipTarget({
    super.key,
    required this.meaning,
    this.showOnTap = false,
    required this.child,
  });

  @override
  State<WordMeaningTooltipTarget> createState() =>
      _WordMeaningTooltipTargetState();
}

class _WordMeaningTooltipTargetState extends State<WordMeaningTooltipTarget> {
  @override
  void dispose() {
    _MeaningTooltipOverlay.hide();
    super.dispose();
  }

  void _showTooltip(BuildContext anchorContext) {
    _MeaningTooltipOverlay.show(
      context: context,
      anchorContext: anchorContext,
      meaning: widget.meaning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (anchorContext) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.showOnTap ? () => _showTooltip(anchorContext) : null,
          onLongPress: () => _showTooltip(anchorContext),
          child: widget.child,
        );
      },
    );
  }
}

enum _TooltipPlacement { left, below, above }

class _MeaningTooltipOverlay {
  static final List<OverlayEntry> _activeEntries = [];

  static void hide() {
    for (final entry in List<OverlayEntry>.from(_activeEntries)) {
      entry.remove();
    }
    _activeEntries.clear();
  }

  static void show({
    required BuildContext context,
    required BuildContext anchorContext,
    required String meaning,
    String word = '',
    String note = '',
  }) {
    // Only one tooltip is visible at a time. The overlay is positioned near
    // the tapped/long-pressed word and clamps to screen edges.
    hide();
    final cleanMeaning = meaning.trim();
    if (cleanMeaning.isEmpty) return;

    final overlay = Overlay.of(context);
    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) return;

    final anchorTopLeft = anchorBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final anchorSize = anchorBox.size;
    final screenSize = overlayBox.size;
    const tooltipWidth = 260.0;
    const tooltipHeight = 64.0;
    const gap = 4.0;
    const edge = 14.0;

    var placement = _TooltipPlacement.left;
    var left = anchorTopLeft.dx - tooltipWidth - gap;
    var top = anchorTopLeft.dy + (anchorSize.height - tooltipHeight) / 2;

    if (left < edge) {
      placement = anchorTopLeft.dy < tooltipHeight + 40
          ? _TooltipPlacement.below
          : _TooltipPlacement.above;
      left = anchorTopLeft.dx + anchorSize.width / 2 - tooltipWidth / 2;
      top = placement == _TooltipPlacement.below
          ? anchorTopLeft.dy + anchorSize.height + gap
          : anchorTopLeft.dy - tooltipHeight - gap;
    }

    left = left.clamp(edge, screenSize.width - tooltipWidth - edge).toDouble();
    top = top.clamp(edge, screenSize.height - tooltipHeight - edge).toDouble();
    final arrowCenter = (anchorTopLeft.dx + anchorSize.width / 2 - left)
        .clamp(22.0, tooltipWidth - 22)
        .toDouble();

    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: hide,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .92, end: 1),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Opacity(
                    opacity: ((scale - .92) / .08).clamp(0, 1),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: _WordMeaningTooltip(
                  meaning: WordMeaning(
                    word: word.trim(),
                    meaning: cleanMeaning,
                    note: note.trim(),
                  ),
                  width: tooltipWidth,
                  arrowCenter: arrowCenter,
                  placement: placement,
                ),
              ),
            ),
          ],
        );
      },
    );
    _activeEntries.add(entry);
    overlay.insert(entry);
  }
}

/// Duolingo-style tooltip card with a small arrow pointing back to the word.
class _WordMeaningTooltip extends StatelessWidget {
  final WordMeaning meaning;
  final double width;
  final double arrowCenter;
  final _TooltipPlacement placement;

  const _WordMeaningTooltip({
    required this.meaning,
    required this.width,
    required this.arrowCenter,
    required this.placement,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: TudloColors.brightGreen,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(child: _TooltipMeaningText(meaning.meaning)),
      ),
    );

    if (placement == _TooltipPlacement.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [card, const _TooltipSideArrow(pointsRight: true)],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (placement == _TooltipPlacement.below)
          _TooltipArrow(center: arrowCenter, pointsDown: false, width: width),
        card,
        if (placement == _TooltipPlacement.above)
          _TooltipArrow(center: arrowCenter, pointsDown: true, width: width),
      ],
    );
  }
}

class _TooltipMeaningText extends StatelessWidget {
  final String text;

  const _TooltipMeaningText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 23,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TooltipSideArrow extends StatelessWidget {
  final bool pointsRight;

  const _TooltipSideArrow({required this.pointsRight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 22,
      child: CustomPaint(
        painter: _TooltipSideArrowPainter(pointsRight: pointsRight),
      ),
    );
  }
}

class _TooltipSideArrowPainter extends CustomPainter {
  final bool pointsRight;

  const _TooltipSideArrowPainter({required this.pointsRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TudloColors.brightGreen
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsRight) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipSideArrowPainter oldDelegate) {
    return oldDelegate.pointsRight != pointsRight;
  }
}

class _TooltipArrow extends StatelessWidget {
  final double center;
  final bool pointsDown;
  final double width;

  const _TooltipArrow({
    required this.center,
    required this.pointsDown,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 10,
      child: CustomPaint(
        painter: _TooltipArrowPainter(center: center, pointsDown: pointsDown),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final double center;
  final bool pointsDown;

  const _TooltipArrowPainter({required this.center, required this.pointsDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TudloColors.brightGreen
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsDown) {
      path
        ..moveTo(center - 10, 0)
        ..lineTo(center + 10, 0)
        ..lineTo(center, size.height)
        ..close();
    } else {
      path
        ..moveTo(center, 0)
        ..lineTo(center - 10, size.height)
        ..lineTo(center + 10, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.pointsDown != pointsDown;
  }
}
