import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

class InteractiveHomeLamp extends StatefulWidget {
  const InteractiveHomeLamp({
    this.initiallyOn = false,
    this.onChanged,
    super.key,
  });

  final bool initiallyOn;
  final ValueChanged<bool>? onChanged;

  @override
  State<InteractiveHomeLamp> createState() => _InteractiveHomeLampState();
}

class _InteractiveHomeLampState extends State<InteractiveHomeLamp> {
  late bool _isOn = widget.initiallyOn;

  void _toggle() {
    setState(() => _isOn = !_isOn);
    final audio = TudloAudioScope.maybeOf(context);
    if (audio != null) {
      unawaited(
        audio.playSoundEffect(TudloAudioAssets.homeLampSwitchSoundEffect),
      );
    }
    widget.onChanged?.call(_isOn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // `left`/`right: 0` (not a fixed width) -- so the beam's own
        // container fills however wide this whole widget is given (the
        // full home scene width, per home_screen.dart's `Positioned(left:
        // 0, right: 0, ...)` around InteractiveHomeLamp), and the fraction-
        // based `_LampBeamClipper` shape below flares out to reach both
        // edges of the screen while staying centered/narrow right under
        // the bulb, at any screen width.
        Positioned(
          top: 94,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              key: const Key('home-lamp-light-effect'),
              opacity: _isOn ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ClipPath(
                clipper: _LampBeamClipper(),
                child: Container(
                  height: 330,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99FFF4B8),
                        Color(0x4DFFF1AD),
                        Color(0x00FFF1AD),
                      ],
                      stops: [0, .62, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          toggled: _isOn,
          label: _isOn ? 'Turn lamp off' : 'Turn lamp on',
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              key: const Key('home-lamp-button'),
              onTap: _toggle,
              radius: 32,
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: SvgPicture.asset(
                'assets/images/home_lamp.svg',
                width: 60,
                height: 112,
                fit: BoxFit.contain,
                semanticsLabel: 'Ceiling lamp',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LampBeamClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * .47, 0)
      ..lineTo(size.width * .53, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
