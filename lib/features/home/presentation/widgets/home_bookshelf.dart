import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';

class HomeBookshelf extends StatefulWidget {
  const HomeBookshelf({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<HomeBookshelf> createState() => _HomeBookshelfState();
}

class _HomeBookshelfState extends State<HomeBookshelf>
    with SingleTickerProviderStateMixin {
  static const _hintPhrases = ['lessons!', 'learn!', 'tap books!'];
  // Start after the door's cue, then repeat on the same interval so the two
  // environmental hints alternate instead of competing for attention.
  static const _initialHintDelay = Duration(seconds: 8);

  late final AnimationController _hintController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..addStatusListener(_repeatHint);
  Timer? _initialHintTimer;
  var _hintPhraseIndex = 0;
  var _reduceMotion = false;

  void _repeatHint(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || _reduceMotion) {
      return;
    }
    setState(() {
      _hintPhraseIndex = (_hintPhraseIndex + 1) % _hintPhrases.length;
    });
    _hintController.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A covered route has its ticker disabled. Reset the cue while Home is
    // hidden so it restarts after the door's cue when the user returns.
    _reduceMotion =
        !effectiveAmbientMotionEnabled(context) ||
        !TickerMode.valuesOf(context).enabled;
    if (_reduceMotion) {
      _initialHintTimer?.cancel();
      _initialHintTimer = null;
      _hintController
        ..stop()
        ..value = 0;
    } else if (!_hintController.isAnimating && _initialHintTimer == null) {
      _initialHintTimer = Timer(_initialHintDelay, () {
        _initialHintTimer = null;
        if (!mounted || _reduceMotion) return;
        _hintController.forward();
      });
    }
  }

  @override
  void dispose() {
    _initialHintTimer?.cancel();
    _hintController
      ..removeStatusListener(_repeatHint)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open lessons',
      child: AnimatedBuilder(
        animation: _hintController,
        builder: (context, child) {
          final progress = _hintController.value;
          final phrase = _phraseAnimation(progress);
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              child!,
              Transform.translate(
                key: const Key('home-bookshelf-hint-nudge'),
                offset: Offset(_bookshelfNudge(progress), 0),
                child: const _BookshelfBooksArtwork(),
              ),
              if (phrase.opacity > 0)
                Positioned(
                  top: 4,
                  left: 0,
                  right: -4,
                  child: Align(
                    // The books occupy the right side of this shelf SVG.
                    alignment: const Alignment(.55, 0),
                    child: IgnorePointer(
                      child: Opacity(
                        key: const Key('home-bookshelf-hint-phrase'),
                        opacity: phrase.opacity,
                        child: Transform.translate(
                          offset: Offset(0, phrase.verticalOffset),
                          child: Transform.scale(
                            scale: phrase.scale,
                            child: Text(
                              _hintPhrases[_hintPhraseIndex],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF754B2D),
                                fontFamily: 'ComicRelief',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Color(0xCCFBF3E4),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                'assets/images/home_bookshelf.svg',
                key: const Key('home-bookshelf'),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              // Hide the static book pixels. _BookshelfBooksArtwork redraws the
              // same original SVG region above this layer and is the only part
              // that receives the tiny nudge.
              Positioned(
                left: constraints.maxWidth * (96 / 160),
                top: constraints.maxHeight * (9 / 37),
                width: constraints.maxWidth * (51 / 160),
                height: constraints.maxHeight * (24.2 / 37),
                child: const ColoredBox(color: Color(0xFFEADF99)),
              ),
              // This maps to the existing SVG "books" group (x: 103–141,
              // y: 12–33 in its 160 x 37 viewBox), with a small tap padding.
              Positioned(
                left: constraints.maxWidth * (96 / 160),
                top: constraints.maxHeight * (7 / 37),
                width: constraints.maxWidth * (50 / 160),
                height: constraints.maxHeight * (30 / 37),
                child: Material(
                  color: Colors.transparent,
                  child: InkResponse(
                    key: const Key('home-bookshelf-books-button'),
                    onTap: widget.onTap,
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _bookshelfNudge(double progress) {
    const nudgeDuration = .14;
    const nudgeDistance = .8;
    if (progress >= nudgeDuration) return 0;

    final cycleProgress = progress / nudgeDuration;
    if (cycleProgress <= .18) {
      return -Curves.easeInOutSine.transform(cycleProgress / .18) *
          nudgeDistance;
    }
    if (cycleProgress <= .5) {
      final moveRight = Curves.easeInOutSine.transform(
        (cycleProgress - .18) / .32,
      );
      return -nudgeDistance + ((nudgeDistance * 2) * moveRight);
    }
    if (cycleProgress <= .82) {
      final moveLeft = Curves.easeInOutSine.transform(
        (cycleProgress - .5) / .32,
      );
      return nudgeDistance - ((nudgeDistance * 2) * moveLeft);
    }
    final returnCenter = Curves.easeInOutSine.transform(
      (cycleProgress - .82) / .18,
    );
    return -nudgeDistance + (nudgeDistance * returnCenter);
  }

  _PhraseAnimation _phraseAnimation(double progress) {
    if (progress < .16 || progress > .48) return _PhraseAnimation.hidden;
    final riseProgress = ((progress - .16) / .32).clamp(0.0, 1.0);
    final fadeIn = (riseProgress / .18).clamp(0.0, 1.0);
    final fadeOut = ((1 - riseProgress) / .35).clamp(0.0, 1.0);
    final popProgress = Curves.easeOutBack.transform(
      (riseProgress / .36).clamp(0.0, 1.0),
    );
    return _PhraseAnimation(
      opacity: Curves.easeOut.transform(fadeIn * fadeOut),
      verticalOffset: -18 * Curves.easeOutCubic.transform(riseProgress),
      scale: .9 + (.11 * popProgress),
    );
  }
}

class _BookshelfBooksArtwork extends StatelessWidget {
  const _BookshelfBooksArtwork();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = constraints.maxWidth * (96 / 160);
        final top = constraints.maxHeight * (9 / 37);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: left,
              top: top,
              width: constraints.maxWidth * (51 / 160),
              height: constraints.maxHeight * (24.2 / 37),
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(-left, -top),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: SvgPicture.asset(
                        'assets/images/home_bookshelf.svg',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhraseAnimation {
  const _PhraseAnimation({
    required this.opacity,
    required this.verticalOffset,
    required this.scale,
  });

  static const hidden = _PhraseAnimation(
    opacity: 0,
    verticalOffset: 0,
    scale: 1,
  );

  final double opacity;
  final double verticalOffset;
  final double scale;
}
