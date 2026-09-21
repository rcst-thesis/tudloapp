import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';
import 'package:tudloapp/features/onboarding/screens/onboarding_screen.dart';

class GradeLevelScreen extends StatefulWidget {
  final String? learnerName;

  const GradeLevelScreen({super.key, this.learnerName});

  @override
  State<GradeLevelScreen> createState() => _GradeLevelScreenState();
}

class _GradeLevelScreenState extends State<GradeLevelScreen> {
  static const _prompt = 'Abyan, sa ano nga grado ka na?';
  GradeOption? selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(TudloVoiceButton.speak(context, _prompt, hiligaynon: true));
    });
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  Future<void> _continue() async {
    final selectedGrade = selected;
    if (selectedGrade == null) return;
    final appState = AppStateScope.of(context);
    final name = widget.learnerName?.trim();
    await AppAudioService.instance.playTap();
    if (name != null && name.isNotEmpty) {
      if (appState.isUsernameTaken(name)) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Username is taken')));
        return;
      }
      await appState.addProfile(name: name, grade: selectedGrade.label);
    } else {
      appState.setGradeLevel(selectedGrade.label);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => name != null && name.isNotEmpty
            ? const OnboardingScreen()
            : const AppShell(initialIndex: 0),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2FAA1F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final eyesWidth = (constraints.maxWidth * (compact ? .78 : .92))
                .clamp(260.0, 430.0);
            final titleGap = compact ? 30.0 : 50.0;
            final buttonGap = compact ? 12.0 : 18.0;
            final arrowSize = compact ? 82.0 : 106.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: compact ? 20 : 34),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - (compact ? 40 : 68))
                          .clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/onbaording/eyes.png',
                          width: eyesWidth,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: titleGap),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _prompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 42 : 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 26),
                        for (final option in gradeOptions) ...[
                          _GradeButton(
                            label: option.label,
                            selected: selected == option,
                            compact: compact,
                            onTap: () => setState(() => selected = option),
                          ),
                          SizedBox(height: buttonGap),
                        ],
                        SizedBox(height: compact ? 32 : 50),
                        _RoundNextButton(
                          size: arrowSize,
                          enabled: selected != null,
                          onTap: _continue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradeButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _GradeButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_GradeButton> createState() => _GradeButtonState();
}

class _GradeButtonState extends State<_GradeButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glowing = _pressed || widget.selected;
    final buttonHeight = widget.compact ? 68.0 : 86.0;
    final width =
        (MediaQuery.sizeOf(context).width * (widget.compact ? .76 : .70))
            .clamp(230.0, 380.0)
            .toDouble();
    final borderColor = glowing ? const Color(0xFFFFE45C) : Colors.white;

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        scale: _pressed ? .96 : 1,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: () async {
            await AppAudioService.instance.playTap();
            widget.onTap();
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: glowing ? 1 : 0,
                    child: OverflowBox(
                      maxWidth: width + 180,
                      maxHeight: buttonHeight + 150,
                      child: CustomPaint(
                        size: Size(width + 180, buttonHeight + 150),
                        painter: _PillGlowPainter(
                          pressed: _pressed,
                          buttonSize: Size(width, buttonHeight),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: width,
                height: buttonHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: widget.compact ? 10 : 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: borderColor,
                    width: glowing ? 6 : 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: glowing
                          ? const Color(0xFF0B7F18)
                          : const Color(0xFF237915),
                      fontSize: widget.compact ? 35 : 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillGlowPainter extends CustomPainter {
  final bool pressed;
  final Size buttonSize;

  const _PillGlowPainter({required this.pressed, required this.buttonSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: buttonSize.width + (pressed ? 28 : 22),
      height: buttonSize.height + (pressed ? 18 : 14),
    );
    final radius = Radius.circular(rect.height / 2);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    final outer = Paint()
      ..color = const Color(0xFFFFF06A).withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pressed ? 26 : 22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(rrect, outer);

    final inner = Paint()
      ..color = const Color(0xFFFFF06A).withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pressed ? 14 : 11
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rrect, inner);
  }

  @override
  bool shouldRepaint(covariant _PillGlowPainter oldDelegate) {
    return oldDelegate.pressed != pressed ||
        oldDelegate.buttonSize != buttonSize;
  }
}

class _RoundNextButton extends StatelessWidget {
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundNextButton({
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : .42,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: enabled ? 3 : 0,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF237915),
              size: size * .70,
            ),
          ),
        ),
      ),
    );
  }
}
