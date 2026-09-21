import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/shared/widgets/svg_text_overlay.dart';
import 'package:tudloapp/shared/widgets/tilt_thumbnail_tile.dart';

/// Artwork from the Figma card with the readable card copy rendered by Flutter.
class HomeWordOfTheDay extends StatefulWidget {
  const HomeWordOfTheDay({
    this.word = 'balay',
    this.example = 'naga istar ako sa akong balay',
    required this.isFavorited,
    this.onFavoriteChanged,
    this.onPronunciationRequested = _placeholderPronunciation,
    super.key,
  });

  final String word;
  final String example;

  /// Whether this word is currently favorited -- driven by the caller
  /// (the real, shared favorites set), not local state, so this card can
  /// never drift from it.
  final bool isFavorited;
  final ValueChanged<bool>? onFavoriteChanged;

  /// Inject the real pronunciation player here when its VO is available.
  final Future<void> Function() onPronunciationRequested;

  static Future<void> _placeholderPronunciation() async {}

  @override
  State<HomeWordOfTheDay> createState() => _HomeWordOfTheDayState();
}

class _HomeWordOfTheDayState extends State<HomeWordOfTheDay> {
  static const _backgroundColor = Color(0xFF8B5D2B);
  // A darker, fully opaque shade of the card's own brown -- the "backing
  // slab" this peeks out from behind, giving real boxy thickness instead
  // of a translucent drop shadow.
  static const _backingColor = Color(0xFF5C3D1C);
  static const _artboardWidth = 378.0;
  static const _artboardHeight = 216.0;
  static const _heartColor = Color(0xFFEB5050);
  static const _feedbackDuration = Duration(milliseconds: 160);

  Timer? _heartFeedbackTimer;
  Timer? _speakerFeedbackTimer;
  var _heartPopped = false;
  var _speakerPressed = false;

  void _toggleFavorite() {
    setState(() => _heartPopped = true);
    widget.onFavoriteChanged?.call(!widget.isFavorited);
    _heartFeedbackTimer?.cancel();
    _heartFeedbackTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _heartPopped = false);
    });
  }

  void _requestPronunciation() {
    setState(() => _speakerPressed = true);
    _speakerFeedbackTimer?.cancel();
    _speakerFeedbackTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _speakerPressed = false);
    });

    unawaited(widget.onPronunciationRequested());
  }

  @override
  void dispose() {
    _heartFeedbackTimer?.cancel();
    _speakerFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('home-word-of-the-day'),
      label: 'Word of the day: ${widget.word}. ${widget.example}',
      child: AspectRatio(
        aspectRatio: _artboardWidth / _artboardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / _artboardWidth;
            final cardHeight =
                constraints.maxWidth / _artboardWidth * _artboardHeight;
            // A solid, opaque "backing slab" the same shape as the card
            // (not a translucent drop shadow) -- the same sticker/box trick
            // used elsewhere in the app (e.g. the reset dialog's flat
            // shadow): the card reads as sitting on top of a second,
            // slightly-offset solid layer, giving real boxy thickness
            // instead of a soft halo peeking out from behind. It's inside
            // the same TiltThumbnailTile as the card's own face (not a
            // separate, static sibling), so the whole thing reads as one
            // rigid 3D block tilting together, not a card floating above a
            // shadow that stays put on the ground.
            return SizedBox(
              width: constraints.maxWidth,
              height: cardHeight,
              child: TiltThumbnailTile(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 10 * scale,
                      height: cardHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _backingColor,
                          borderRadius: BorderRadius.circular(17 * scale),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SvgPicture.asset(
                        'assets/images/home_word_of_the_day.svg',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    // The supplied SVG turns its labels into paths. These masks
                    // keep its card artwork while Flutter owns readable text.
                    SvgTextMask(
                      left: 40,
                      top: 5,
                      width: 300,
                      height: 46,
                      scale: scale,
                      color: _backgroundColor,
                    ),
                    SvgTextMask(
                      left: 80,
                      top: 92,
                      width: 218,
                      height: 78,
                      scale: scale,
                      color: _backgroundColor,
                    ),
                    SvgTextMask(
                      left: 76,
                      top: 174,
                      width: 226,
                      height: 24,
                      scale: scale,
                      color: _backgroundColor,
                    ),
                    SvgCardText(
                      text: 'word of the day',
                      left: 40,
                      top: 9,
                      width: 300,
                      height: 38,
                      scale: scale,
                      fontSize: 29,
                    ),
                    SvgCardText(
                      text: widget.word,
                      left: 80,
                      top: 94,
                      width: 218,
                      height: 74,
                      scale: scale,
                      fontSize: 58,
                      autoFit: true,
                    ),
                    SvgCardText(
                      text: widget.example,
                      left: 76,
                      top: 176,
                      width: 226,
                      height: 20,
                      scale: scale,
                      fontSize: 11,
                    ),
                    // Replace the SVG's static heart with an interactive Flutter
                    // control while preserving the card's original location.
                    SvgTextMask(
                      left: 304,
                      top: 158,
                      width: 58,
                      height: 48,
                      scale: scale,
                      color: _backgroundColor,
                    ),
                    Positioned(
                      left: 306 * scale,
                      top: 157 * scale,
                      width: 54 * scale,
                      height: 54 * scale,
                      child: _WordCardIconButton(
                        key: const Key('home-word-favorite-button'),
                        semanticLabel: widget.isFavorited
                            ? 'Remove ${widget.word} from favorites'
                            : 'Add ${widget.word} to favorites',
                        toggled: widget.isFavorited,
                        onTap: _toggleFavorite,
                        child: AnimatedScale(
                          scale: _heartPopped ? 1.12 : 1,
                          duration: _feedbackDuration,
                          curve: Curves.easeOutBack,
                          child: AnimatedSwitcher(
                            duration: _feedbackDuration,
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              widget.isFavorited
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(widget.isFavorited),
                              color: _heartColor,
                              size: 34 * scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 163 * scale,
                      top: 49 * scale,
                      width: 53 * scale,
                      height: 53 * scale,
                      child: _WordCardIconButton(
                        key: const Key('home-word-speaker-button'),
                        semanticLabel: 'Play pronunciation for ${widget.word}',
                        onTap: _requestPronunciation,
                        child: AnimatedScale(
                          scale: _speakerPressed ? .9 : 1,
                          duration: _feedbackDuration,
                          curve: Curves.easeOutCubic,
                          // Keep the visual circle at the SVG's original 35 x 35
                          // size; the surrounding 53 x 53 area remains tappable.
                          child: SizedBox(
                            width: 35 * scale,
                            height: 35 * scale,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: Color(0xFFB88956),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 20 * scale,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WordCardIconButton extends StatelessWidget {
  const _WordCardIconButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.toggled,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      toggled: toggled,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          containedInkWell: true,
          child: Center(child: child),
        ),
      ),
    );
  }
}
