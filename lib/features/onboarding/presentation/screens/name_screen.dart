import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/features/onboarding/presentation/screens/grade_selection_screen.dart';
import 'package:tudloapp/features/onboarding/presentation/widgets/onboarding_koka_greeting.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';
import 'package:tudloapp/shared/widgets/rive_long_button.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({this.voiceOverPlayer, super.key});

  final Future<void> Function()? voiceOverPlayer;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  // GlobalKey, not a plain Key -- this lets the same live TextField
  // element (and its in-progress keyboard connection) move to a different
  // parent in the tree (canvas slot <-> elevated overlay slot) without
  // losing focus or state. See _buildNameField/_isEditing below.
  final _nameFieldKey = GlobalKey();
  bool _voiceOverPlaying = false;
  bool _isEditing = false;
  TudloAudioController? _audio;
  var _initialVoiceOverScheduled = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_handleFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    audio.preloadVoiceOver(TudloAudioAssets.nameScreenVoiceOver);
    if (_initialVoiceOverScheduled) return;
    _initialVoiceOverScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playVoiceOver());
    });
  }

  void _handleFocusChanged() {
    setState(() => _isEditing = _nameFocus.hasFocus);
  }

  Future<void> _playVoiceOver() async {
    if (_voiceOverPlaying) return;
    final player =
        widget.voiceOverPlayer ??
        () =>
            _audio?.playVoiceOverAndWait(
              TudloAudioAssets.nameScreenVoiceOver,
            ) ??
            Future<void>.value();
    setState(() => _voiceOverPlaying = true);
    try {
      await player();
    } finally {
      if (mounted) setState(() => _voiceOverPlaying = false);
    }
  }

  @override
  void dispose() {
    unawaited(_stopVoiceOver());
    _nameFocus.removeListener(_handleFocusChanged);
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    unawaited(_stopVoiceOver());
    Navigator.of(
      context,
    ).push(FadePageRoute<void>(page: GradeSelectionScreen(learnerName: name)));
  }

  Future<void> _stopVoiceOver() {
    return _audio?.stopVoiceOver(TudloAudioAssets.nameScreenVoiceOver) ??
        Future<void>.value();
  }

  Widget _buildNameField() {
    // KeyedSubtree carries the stable, findable ValueKey (used by
    // existing tests/tooling); the GlobalKey underneath it is what lets
    // the actual TextField element move between the canvas slot and the
    // elevated overlay slot without losing focus/state -- GlobalKeys
    // aren't meant to double as a public lookup key, so the two are kept
    // separate deliberately.
    return KeyedSubtree(
      key: const Key('name-input'),
      child: TextField(
        key: _nameFieldKey,
        controller: _nameController,
        focusNode: _nameFocus,
        autofocus: false,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.name],
        maxLength: 24,
        maxLines: 1,
        decoration: InputDecoration(
          counterText: '',
          hintText: 'isulat ang ngalan mo',
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.42),
            fontSize: 18,
          ),
          filled: true,
          fillColor: const Color(0xFFD9D9D9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 19,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(21),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // false -- the fixed-design canvas below is scaled uniformly via
      // FittedBox; letting the Scaffold shrink its body when the keyboard
      // opens would shrink that whole canvas along with it. Instead the
      // canvas keeps its full size and the name field relocates itself
      // above the keyboard (see _isEditing/_buildNameField) while a dim
      // scrim covers everything else.
      resizeToAvoidBottomInset: false,
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
                      key: const Key('name-page-canvas'),
                      width: 412,
                      height: 917,
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 45,
                            top: 120,
                            width: 322,
                            child: Text(
                              'gusto ni koka ma bal an\nimo ngalan',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 29,
                            top: 216,
                            width: 352,
                            height: 92,
                            child: CustomPaint(
                              painter: const _SpeechBubblePainter(),
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        18,
                                        8,
                                        54,
                                        21,
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'hey, hey, hey! abyan, ano imo ngalan?\n'
                                            'ano gusto mo nga tawagon kita?',
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            softWrap: false,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              height: 1.35,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 15,
                                    child: _VoiceOverButton(
                                      playing: _voiceOverPlaying,
                                      onPressed: _playVoiceOver,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 164,
                            top: 462,
                            width: 86,
                            height: 22,
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
                            left: 154,
                            top: 342,
                            width: 104,
                            height: 134,
                            // `contain`, not `fill` -- unlike the old
                            // static placeholder image, stretching Rive's
                            // own artwork non-uniformly visibly distorts
                            // the character.
                            child: OnboardingKokaGreeting(),
                          ),
                          Positioned(
                            left: 29,
                            top: 488,
                            width: 352,
                            height: 67,
                            // While editing, the real field is relocated
                            // to the elevated overlay above the keyboard
                            // (see build()'s outer Stack) -- an empty
                            // placeholder of the same size holds this
                            // slot's layout so nothing else in the canvas
                            // shifts.
                            child: _isEditing
                                ? const SizedBox.shrink()
                                : _buildNameField(),
                          ),
                          Positioned(
                            left: 30,
                            top: 807,
                            width: 352,
                            height: 70,
                            child: _NextButton(onPressed: _continue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isEditing) ...[
            // Dims everything behind the elevated field while typing;
            // tapping it unfocuses (dismissing the keyboard), which puts
            // the field back in its normal canvas spot.
            Positioned.fill(
              child: GestureDetector(
                key: const Key('name-field-scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: _nameFocus.unfocus,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
            // Real screen coordinates (not the scaled canvas's design
            // units) -- this is what makes it reliably sit above the
            // keyboard regardless of how the canvas itself is scaled.
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              child: _buildNameField(),
            ),
          ],
          SafeArea(
            child: AdaptiveBackButtonPlacement(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RiveLongButton(
      key: const Key('name-next-button'),
      label: 'next',
      buttonHeight: 70,
      fallbackFontSize: 19,
      onPressed: onPressed,
    );
  }
}

class _VoiceOverButton extends StatelessWidget {
  const _VoiceOverButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Voice-over playing' : 'Play voice-over',
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          key: const Key('name-voice-over-button'),
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
                  painter: _SpeakerPainter(
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

class _SpeakerPainter extends CustomPainter {
  const _SpeakerPainter({required this.color});

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

    final innerWave = Path()
      ..moveTo(15.536, 8.464)
      ..cubicTo(16.468, 9.397, 16.995, 10.661, 17, 11.98)
      ..cubicTo(17.005, 13.3, 16.489, 14.567, 15.563, 15.508);
    canvas.drawPath(innerWave, paint);

    final outerWave = Path()
      ..moveTo(19.657, 6.343)
      ..cubicTo(21.149, 7.836, 21.992, 9.858, 22, 11.969)
      ..cubicTo(22.008, 14.079, 21.182, 16.108, 19.701, 17.612);
    canvas.drawPath(outerWave, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeakerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEBEBEB);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, 79),
      const Radius.circular(21),
    );
    canvas.drawRRect(body, paint);
    final tail = Path()
      ..moveTo(size.width / 2 - 16, 74)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 16, 74)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) => false;
}
