import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart' as rive;

class HomeKokaMascot extends StatefulWidget {
  const HomeKokaMascot({required this.learnerName, super.key});

  final String learnerName;

  @override
  State<HomeKokaMascot> createState() => _HomeKokaMascotState();
}

class _HomeKokaMascotState extends State<HomeKokaMascot> {
  // Repeated taps are measured as one short burst, not across a whole visit.
  static const int tapsBeforeCurious = 3;
  static const int tapsBeforeAnnoyed = 5;
  static const repeatedTapWindow = Duration(seconds: 4);
  static const resetDuration = Duration(seconds: 6);
  // State Machine 1 keeps reporting its last reaction state after the visual
  // timeline settles. This lock prevents overlapping triggers without guessing
  // that a queued reaction can safely start on its own.
  static const reactionLockDuration = Duration(seconds: 4);
  static const speechDuration = Duration(milliseconds: 2600);

  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.TriggerInput? _hiTrigger;
  rive.TriggerInput? _curiousTrigger;
  rive.TriggerInput? _annoyedTrigger;
  rive.CallbackHandler? _stateChangeHandler;
  Timer? _resetTimer;
  Timer? _reactionTimer;
  Timer? _speechTimer;
  DateTime? _lastTapAt;
  _KokaReaction? _queuedReaction;
  _KokaReaction? _requestedReaction;
  String? _speech;
  var _tapCount = 0;
  var _isReacting = false;
  var _reactionSerial = 0;

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

    final bindings = _createRiveBindings(file);

    if (!mounted) {
      bindings.dispose();
      file.dispose();
      return;
    }
    setState(() {
      _file = file;
      _applyRiveBindings(bindings);
    });
  }

  _KokaRiveBindings _createRiveBindings(rive.File file) {
    final controller = rive.RiveWidgetController(
      file,
      stateMachineSelector: rive.StateMachineSelector.byName('State Machine 1'),
    );
    // State Machine 1 is a legacy-input state machine. These names are read
    // from the supplied .riv contract test, not inferred from animation names.
    // ignore: deprecated_member_use
    final hiTrigger = controller.stateMachine.trigger('Hi');
    // ignore: deprecated_member_use
    final curiousTrigger = controller.stateMachine.trigger('Curious');
    // ignore: deprecated_member_use
    final annoyedTrigger = controller.stateMachine.trigger('Annoyed');
    // The speech bubble follows the state machine's actual state change.
    // ignore: deprecated_member_use, invalid_use_of_internal_member
    final stateChangeHandler = controller.stateMachine.onStateChanged(
      _handleRiveStateChanged,
    );
    return _KokaRiveBindings(
      controller: controller,
      hiTrigger: hiTrigger,
      curiousTrigger: curiousTrigger,
      annoyedTrigger: annoyedTrigger,
      stateChangeHandler: stateChangeHandler,
    );
  }

  void _applyRiveBindings(_KokaRiveBindings bindings) {
    _controller = bindings.controller;
    _hiTrigger = bindings.hiTrigger;
    _curiousTrigger = bindings.curiousTrigger;
    _annoyedTrigger = bindings.annoyedTrigger;
    _stateChangeHandler = bindings.stateChangeHandler;
  }

  String get _addressee {
    final learnerName = widget.learnerName.trim();
    return learnerName.isEmpty ? 'abyan' : learnerName;
  }

  bool get _hasLearnerName => widget.learnerName.trim().isNotEmpty;

  _KokaReaction _reactionForTapCount() {
    if (_tapCount >= tapsBeforeAnnoyed) return _KokaReaction.annoyed;
    if (_tapCount >= tapsBeforeCurious) return _KokaReaction.curious;
    return _KokaReaction.friendly;
  }

  void _handleTap() {
    if (_controller == null) return;

    final now = DateTime.now();
    if (_lastTapAt == null || now.difference(_lastTapAt!) > repeatedTapWindow) {
      _tapCount = 0;
    }
    _tapCount++;
    _lastTapAt = now;
    _resetTimer?.cancel();
    _resetTimer = Timer(resetDuration, _resetTapBurst);

    final reaction = _reactionForTapCount();
    if (_isReacting) {
      if ((_queuedReaction?.index ?? -1) < reaction.index) {
        _queuedReaction = reaction;
      }
      return;
    }
    _playReaction(reaction);
  }

  void _playReaction(_KokaReaction reaction) {
    final trigger = switch (reaction) {
      _KokaReaction.friendly => _hiTrigger,
      _KokaReaction.curious => _curiousTrigger,
      _KokaReaction.annoyed => _annoyedTrigger,
    };
    if (trigger == null) return;

    _isReacting = true;
    _queuedReaction = null;
    _requestedReaction = reaction;
    // ignore: deprecated_member_use
    trigger.fire();
    _reactionTimer?.cancel();
    _reactionTimer = Timer(reactionLockDuration, () {
      if (!mounted) return;
      _restartStateMachineAtIdle();
    });
  }

  void _restartStateMachineAtIdle() {
    final file = _file;
    if (file == null) return;

    final bindings = _createRiveBindings(file);
    final previousController = _controller;
    final previousStateChangeHandler = _stateChangeHandler;
    setState(() {
      _applyRiveBindings(bindings);
      _isReacting = false;
      _requestedReaction = null;
    });
    previousStateChangeHandler?.dispose();
    previousController?.dispose();

    final queuedReaction = _queuedReaction;
    _queuedReaction = null;
    if (queuedReaction != null) {
      // Let the restarted controller report its own initial layer states
      // first. Some decorative Rive layers share names such as "Curious";
      // firing after this frame ensures only the requested reaction can own
      // the next matching state callback and speech bubble.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _controller != bindings.controller) return;
        _playReaction(queuedReaction);
      });
    }
  }

  void _handleRiveStateChanged(String stateName) {
    if (!mounted) return;

    final requestedReaction = _requestedReaction;
    if (requestedReaction != null && stateName == requestedReaction.stateName) {
      _requestedReaction = null;
      _showSpeechFor(requestedReaction);
    }
  }

  void _showSpeechFor(_KokaReaction reaction) {
    final serial = ++_reactionSerial;
    // Rive reports this callback while its widget can be building. Schedule
    // the Flutter bubble for the next frame instead of rebuilding mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || serial != _reactionSerial) return;
      setState(() => _speech = _speechFor(reaction));

      _speechTimer?.cancel();
      _speechTimer = Timer(speechDuration, () {
        if (!mounted || serial != _reactionSerial) return;
        setState(() => _speech = null);
      });
    });
  }

  String _speechFor(_KokaReaction reaction) => switch (reaction) {
    _KokaReaction.friendly =>
      _hasLearnerName ? 'Hi, $_addressee!' : 'Hi abyan!',
    _KokaReaction.curious => 'Ano problema, $_addressee?',
    _KokaReaction.annoyed => 'Tama dun na, $_addressee.',
  };

  void _resetTapBurst() {
    _tapCount = 0;
    _lastTapAt = null;
    _queuedReaction = null;
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _reactionTimer?.cancel();
    _speechTimer?.cancel();
    _stateChangeHandler?.dispose();
    _controller?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Talk to Koka',
            child: GestureDetector(
              key: const Key('home-koka-tap-target'),
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              child: controller == null
                  ? const SizedBox.expand()
                  : rive.RiveWidget(
                      controller: controller,
                      fit: rive.Fit.contain,
                      alignment: Alignment.center,
                    ),
            ),
          ),
        ),
        if (_speech case final speech?)
          Positioned(
            top: -50,
            left: 0,
            right: -48,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: _KokaSpeechBubble(text: speech),
              ),
            ),
          ),
      ],
    );
  }
}

class _KokaSpeechBubble extends StatelessWidget {
  const _KokaSpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // The SVG has a 352 × 105 view box. Scaling both dimensions from its
    // width keeps its rounded body and tail proportioned.
    return SizedBox(
      key: const Key('home-koka-speech-bubble'),
      width: 176,
      height: 52.5,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/home_koka_speech_bubble.svg',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 11,
            right: 11,
            top: 7,
            height: 29,
            child: Center(
              child: Text(
                text,
                key: const Key('home-koka-speech-text'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'ComicRelief',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _KokaReaction {
  // These are the actual State Machine 1 state names reported at runtime.
  // Their attached timeline animations are named Hi9, Curious9, and Annoyed9.
  friendly('Hi'),
  curious('Curious'),
  annoyed('Annoyed');

  const _KokaReaction(this.stateName);

  final String stateName;
}

class _KokaRiveBindings {
  const _KokaRiveBindings({
    required this.controller,
    required this.hiTrigger,
    required this.curiousTrigger,
    required this.annoyedTrigger,
    required this.stateChangeHandler,
  });

  final rive.RiveWidgetController controller;
  final rive.TriggerInput? hiTrigger;
  final rive.TriggerInput? curiousTrigger;
  final rive.TriggerInput? annoyedTrigger;
  final rive.CallbackHandler stateChangeHandler;

  void dispose() {
    stateChangeHandler.dispose();
    controller.dispose();
  }
}
