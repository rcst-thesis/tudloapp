import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

class HomeDoor extends StatefulWidget {
  const HomeDoor({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<HomeDoor> createState() => _HomeDoorState();
}

class _HomeDoorState extends State<HomeDoor>
    with SingleTickerProviderStateMixin {
  static const _hintPhrases = ['explore!', 'tap me!', 'open map!'];
  static const _initialHintDelay = Duration(seconds: 4);

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

  void _handleTap() {
    final audio = TudloAudioScope.maybeOf(context);
    if (audio != null) {
      unawaited(audio.playSoundEffect(TudloAudioAssets.homeDoorSoundEffect));
    }
    widget.onTap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A covered route has its ticker disabled. Reset the cue while Home is
    // hidden so it restarts in its intended sequence when the user returns.
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
      label: 'Open map',
      child: AnimatedBuilder(
        animation: _hintController,
        builder: (context, child) {
          final progress = _hintController.value;
          final nudge = _doorNudge(progress);
          final phrase = _phraseAnimation(progress);
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                key: const Key('home-door-hint-nudge'),
                offset: Offset(nudge, 0),
                child: child,
              ),
              if (phrase.opacity > 0)
                Positioned(
                  top: 8,
                  left: -14,
                  right: -14,
                  child: IgnorePointer(
                    child: Opacity(
                      key: const Key('home-door-hint-phrase'),
                      opacity: phrase.opacity,
                      child: Transform.translate(
                        offset: Offset(0, phrase.verticalOffset),
                        child: Transform.scale(
                          key: const Key('home-door-hint-pop'),
                          scale: phrase.scale,
                          child: Text(
                            _hintPhrases[_hintPhraseIndex],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFF754B2D),
                              fontFamily: 'ComicRelief',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: Color(0xCCFBF3E4), blurRadius: 2),
                              ],
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
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            key: const Key('home-door-button'),
            onTap: _handleTap,
            radius: 48,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: SvgPicture.asset(
              'assets/images/home_door.svg',
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }

  double _doorNudge(double progress) {
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
