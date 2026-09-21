import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/features/onboarding/screens/grade_level_screen.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  static const _prompt = 'Hi, abyan! Ano imo ngalan?';
  final TextEditingController controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(TudloVoiceButton.speak(context, _prompt, hiligaynon: true));
    });
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    controller.dispose();
    super.dispose();
  }

  void _continue() {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final appState = AppStateScope.of(context);
    if (appState.isUsernameTaken(name)) {
      setState(() => _errorText = 'Username is taken');
      return;
    }
    setState(() => _errorText = null);
    unawaited(AppAudioService.instance.playTap());
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GradeLevelScreen(learnerName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasName = controller.text.trim().isNotEmpty;

    return _GreenOnboardingScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 680;
          final eyesWidth = (constraints.maxWidth * .92).clamp(280.0, 430.0);
          final fieldWidth = (constraints.maxWidth * .76).clamp(230.0, 360.0);
          final nextSize = compact ? 82.0 : 100.0;

          return Center(
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
                    SizedBox(height: compact ? 32 : 52),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _prompt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.words,
                        cursorColor: const Color(0xFF237915),
                        style: const TextStyle(
                          color: Color(0xFF237915),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: compact ? 17 : 21,
                          ),
                          border: _pillBorder(),
                          enabledBorder: _pillBorder(),
                          focusedBorder: _pillBorder(width: 4),
                        ),
                        onSubmitted: (_) => _continue(),
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 42 : 64),
                    _RoundNextButton(
                      enabled: hasName,
                      size: nextSize,
                      onTap: _continue,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GreenOnboardingScaffold extends StatelessWidget {
  final Widget child;

  const _GreenOnboardingScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2FAA1F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: child,
        ),
      ),
    );
  }
}

class _RoundNextButton extends StatelessWidget {
  final bool enabled;
  final double size;
  final VoidCallback onTap;

  const _RoundNextButton({
    required this.enabled,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () async {
                  await AppAudioService.instance.playTap();
                  onTap();
                }
              : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.chevron_right_rounded,
              color: Color.fromARGB(255, 37, 125, 24),
              size: size * .70,
            ),
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _pillBorder({double width = 3}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(999),
    borderSide: BorderSide(color: const Color(0xFF239015), width: width),
  );
}
