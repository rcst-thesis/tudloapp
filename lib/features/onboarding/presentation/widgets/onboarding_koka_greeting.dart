import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// A simple, non-interactive Koka for onboarding screens -- loops the
/// "Hi" greeting animation continuously. Unlike [HomeKokaMascot]
/// (`lib/features/home/presentation/widgets/home_koka_mascot.dart`), this
/// has no tap handling and never plays the curious/annoyed reactions;
/// onboarding just wants a friendly greeting standing in for the old
/// static `name_character.png` placeholder, not the Home screen's full
/// tap-to-react experience.
class OnboardingKokaGreeting extends StatefulWidget {
  const OnboardingKokaGreeting({this.fit = rive.Fit.contain, super.key});

  final rive.Fit fit;

  @override
  State<OnboardingKokaGreeting> createState() => _OnboardingKokaGreetingState();
}

class _OnboardingKokaGreetingState extends State<OnboardingKokaGreeting> {
  // The "Hi" trigger plays a single pass, not a loop -- the state machine
  // then just keeps reporting "Hi" as its current state without replaying
  // it (same behavior HomeKokaMascot's own comments describe). Re-firing
  // the trigger on this interval is what makes it loop. There's no
  // completion callback to react to instead (onStateChanged only fires on
  // state *entry*), so this is a generous fixed guess at the timeline's
  // length rather than an exact measurement.
  static const _loopInterval = Duration(milliseconds: 2200);

  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.TriggerInput? _hiTrigger;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRive());
  }

  Future<void> _loadRive() async {
    final file = await rive.File.asset(
      'assets/images/koka_mascot.riv',
      riveFactory: rive.Factory.flutter,
    );
    if (!mounted || file == null) {
      file?.dispose();
      return;
    }

    final controller = rive.RiveWidgetController(
      file,
      stateMachineSelector: rive.StateMachineSelector.byName('State Machine 1'),
    );
    // Same state machine contract as HomeKokaMascot -- legacy-input, named
    // triggers rather than inferred from animation names.
    // ignore: deprecated_member_use
    final hiTrigger = controller.stateMachine.trigger('Hi');
    if (!mounted) {
      controller.dispose();
      file.dispose();
      return;
    }
    setState(() {
      _file = file;
      _controller = controller;
      _hiTrigger = hiTrigger;
    });
    _fireHi();
    _loopTimer = Timer.periodic(_loopInterval, (_) => _fireHi());
  }

  void _fireHi() {
    // ignore: deprecated_member_use
    _hiTrigger?.fire();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _controller?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Semantics(
      label: 'Koka character',
      child: controller == null
          ? const SizedBox.expand()
          : rive.RiveWidget(
              controller: controller,
              fit: widget.fit,
              alignment: Alignment.center,
            ),
    );
  }
}
