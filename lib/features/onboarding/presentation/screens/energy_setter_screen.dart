import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/features/onboarding/presentation/screens/second_loading_screen.dart';
import 'package:tudloapp/features/onboarding/presentation/widgets/onboarding_koka_greeting.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';
import 'package:tudloapp/shared/widgets/rive_long_button.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

class EnergySetterScreen extends StatefulWidget {
  const EnergySetterScreen({
    required this.learnerName,
    required this.grade,
    this.initialEnergy = 60,
    this.voiceOverPlayer,
    super.key,
  }) : assert(initialEnergy >= 10 && initialEnergy <= 100);

  final String learnerName;
  final int grade;
  final int initialEnergy;
  final Future<void> Function()? voiceOverPlayer;

  @override
  State<EnergySetterScreen> createState() => _EnergySetterScreenState();
}

class _EnergySetterScreenState extends State<EnergySetterScreen> {
  late int _energy;
  bool _voiceOverPlaying = false;
  TudloAudioController? _audio;
  var _initialVoiceOverScheduled = false;

  @override
  void initState() {
    super.initState();
    _energy = (widget.initialEnergy / 10).round() * 10;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    audio.preloadVoiceOver(TudloAudioAssets.energySetterVoiceOver);
    if (_initialVoiceOverScheduled) return;
    _initialVoiceOverScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playVoiceOver());
    });
  }

  void _changeEnergy(int amount) {
    setState(() => _energy = (_energy + amount).clamp(10, 100));
  }

  Future<void> _playVoiceOver() async {
    if (_voiceOverPlaying) return;
    final player =
        widget.voiceOverPlayer ??
        () =>
            _audio?.playVoiceOverAndWait(
              TudloAudioAssets.energySetterVoiceOver,
            ) ??
            Future<void>.value();
    setState(() => _voiceOverPlaying = true);
    try {
      await player();
    } finally {
      if (mounted) setState(() => _voiceOverPlaying = false);
    }
  }

  void _continue() {
    unawaited(_stopVoiceOver());
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: SecondLoadingScreen(
          learnerName: widget.learnerName,
          grade: widget.grade,
          energy: _energy,
        ),
      ),
    );
  }

  Future<void> _stopVoiceOver() {
    return _audio?.stopVoiceOver(TudloAudioAssets.energySetterVoiceOver) ??
        Future<void>.value();
  }

  void _leaveEnergyScreen() {
    unawaited(_stopVoiceOver());
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    unawaited(_stopVoiceOver());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.mint,
              child: SafeArea(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      key: const Key('energy-setter-canvas'),
                      width: 412,
                      height: 917,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 30,
                            top: 116,
                            width: 352,
                            height: 86,
                            child: Image.asset(
                              'assets/images/energy_heading.png',
                              key: const Key('energy-heading-image'),
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                              semanticLabel: 'Energy setter heading',
                            ),
                          ),
                          Positioned(
                            left: 30,
                            top: 216,
                            width: 352,
                            height: 92,
                            child: CustomPaint(
                              painter: const _EnergyBubblePainter(),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 52,
                                    top: 12,
                                    width: 238,
                                    height: 50,
                                    child: Image.asset(
                                      'assets/images/energy_bubble_label.png',
                                      key: const Key(
                                        'energy-bubble-label-image',
                                      ),
                                      fit: BoxFit.contain,
                                      alignment: Alignment.centerLeft,
                                      filterQuality: FilterQuality.high,
                                      semanticLabel:
                                          'Energy voice-over message',
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 13,
                                    child: _EnergyVoiceButton(
                                      playing: _voiceOverPlaying,
                                      onPressed: _playVoiceOver,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 176,
                            top: 415,
                            width: 64,
                            height: 18,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0x706B6B6B),
                                borderRadius: BorderRadius.all(
                                  Radius.elliptical(32, 9),
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 168,
                            top: 325,
                            width: 76,
                            height: 108,
                            child: OnboardingKokaGreeting(),
                          ),
                          Positioned(
                            left: 140,
                            top: 450,
                            child: _EnergyValue(value: _energy),
                          ),
                          Positioned(
                            left: 30,
                            top: 506,
                            child: _BatteryControl(
                              energy: _energy,
                              onDecrease: () => _changeEnergy(-10),
                              onIncrease: () => _changeEnergy(10),
                            ),
                          ),
                          Positioned(
                            left: 30,
                            top: 661,
                            width: 352,
                            height: 129,
                            child: Image.asset(
                              'assets/images/energy_instructions.png',
                              key: const Key('energy-instructions-image'),
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.high,
                              semanticLabel:
                                  'Parent energy-setting instructions',
                            ),
                          ),
                          Positioned(
                            left: 30,
                            top: 807,
                            child: _EnergyNextButton(onPressed: _continue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: AdaptiveBackButtonPlacement(onPressed: _leaveEnergyScreen),
          ),
        ],
      ),
    );
  }
}

class _EnergyValue extends StatelessWidget {
  const _EnergyValue({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('energy-value'),
      width: 136,
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            top: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    '$value%',
                    key: ValueKey(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryControl extends StatelessWidget {
  const _BatteryControl({
    required this.energy,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int energy;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final filled = energy ~/ 10;
    return SizedBox(
      key: const Key('energy-battery'),
      width: 352,
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 4,
            width: 315,
            height: 112,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(29),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: 315,
            height: 112,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(29),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 40,
            width: 29,
            height: 42,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned.fill(
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 15,
            top: 14,
            width: 281,
            height: 86,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var index = 0; index < 10; index++)
                      _BatteryCell(
                        index: index,
                        filled: index < filled,
                        isDecrease: index == filled - 1,
                        isIncrease: index == filled && filled < 10,
                        decreaseEnabled: energy > 10,
                        onDecrease: onDecrease,
                        onIncrease: onIncrease,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryCell extends StatelessWidget {
  const _BatteryCell({
    required this.index,
    required this.filled,
    required this.isDecrease,
    required this.isIncrease,
    required this.decreaseEnabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int index;
  final bool filled;
  final bool isDecrease;
  final bool isIncrease;
  final bool decreaseEnabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final interactive = isIncrease || (isDecrease && decreaseEnabled);
    return Semantics(
      button: interactive,
      label: isIncrease
          ? 'Add 10 percent energy'
          : isDecrease
          ? 'Subtract 10 percent energy'
          : 'Energy cell ${index + 1}',
      child: SizedBox(
        width: 23,
        height: 81,
        child: interactive
            ? StickerPressButton(
                key: isIncrease
                    ? const Key('energy-plus-button')
                    : const Key('energy-minus-button'),
                onPressed: isIncrease ? onIncrease : onDecrease,
                frontColor: filled ? AppColors.green : const Color(0xFF797777),
                depthColor: filled
                    ? AppColors.darkGreen
                    : const Color(0xFF616161),
                restLift: 2,
                borderRadius: 10,
                child: isIncrease
                    ? const Icon(
                        Icons.add_rounded,
                        color: AppColors.green,
                        size: 20,
                      )
                    : const Icon(
                        Icons.remove_rounded,
                        key: Key('energy-minus-icon'),
                        color: Colors.white,
                        size: 20,
                      ),
              )
            : Stack(
                children: [
                  if (filled || isIncrease)
                    Positioned.fill(
                      top: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.darkGreen
                              : const Color(0xFF616161),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  if (filled || isIncrease)
                    Positioned.fill(
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.green
                              : const Color(0xFF797777),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EnergyNextButton extends StatelessWidget {
  const _EnergyNextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RiveLongButton(
      key: const Key('energy-next-button'),
      label: 'next',
      onPressed: onPressed,
    );
  }
}

class _EnergyVoiceButton extends StatelessWidget {
  const _EnergyVoiceButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Voice-over playing' : 'Play energy instructions',
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          key: const Key('energy-voice-button'),
          onTap: playing ? null : onPressed,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(
                  painter: _EnergySpeakerPainter(
                    color: playing ? AppColors.green : const Color(0xFF222222),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnergySpeakerPainter extends CustomPainter {
  const _EnergySpeakerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final speaker = Path()
      ..moveTo(3.158, 13.931)
      ..cubicTo(2.445, 12.742, 2.445, 11.258, 3.158, 10.069)
      ..cubicTo(3.376, 9.707, 3.736, 9.453, 4.151, 9.37)
      ..lineTo(5.844, 9.031)
      ..cubicTo(5.945, 9.011, 6.036, 8.957, 6.102, 8.878)
      ..lineTo(8.171, 6.395)
      ..cubicTo(9.353, 4.976, 9.945, 4.266, 10.472, 4.457)
      ..cubicTo(11, 4.648, 11, 5.572, 11, 7.419)
      ..lineTo(11, 16.581)
      ..cubicTo(11, 18.428, 11, 19.352, 10.472, 19.543)
      ..cubicTo(9.945, 19.734, 9.353, 19.024, 8.171, 17.605)
      ..lineTo(6.102, 15.122)
      ..cubicTo(6.036, 15.043, 5.945, 14.989, 5.844, 14.969)
      ..lineTo(4.151, 14.63)
      ..cubicTo(3.736, 14.547, 3.376, 14.293, 3.158, 13.931)
      ..close();
    canvas.drawPath(speaker, paint);
    canvas.drawPath(
      Path()
        ..moveTo(15.536, 8.464)
        ..cubicTo(16.468, 9.397, 16.995, 10.661, 17, 11.98)
        ..cubicTo(17.005, 13.3, 16.489, 14.567, 15.563, 15.508),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(19.657, 6.343)
        ..cubicTo(21.149, 7.836, 21.992, 9.858, 22, 11.969)
        ..cubicTo(22.008, 14.079, 21.182, 16.108, 19.701, 17.612),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergySpeakerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _EnergyBubblePainter extends CustomPainter {
  const _EnergyBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEBEBEB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, 79),
        const Radius.circular(21),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(40, 74)
        ..lineTo(70, size.height)
        ..quadraticBezierTo(77, size.height + 2, 73, 73)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyBubblePainter oldDelegate) => false;
}
