part of '../../level_game_page.dart';

enum _G2ParkGreetingStep {
  intro,
  map,
  morningTeach,
  morningPractice,
  afternoonTeach,
  afternoonPractice,
  eveningTeach,
  eveningPractice,
  review,
  match,
  reward,
}

class _GradeTwoUnitTwoLessonOneParkGreetingFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoUnitTwoLessonOneParkGreetingFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoUnitTwoLessonOneParkGreetingFlow> createState() =>
      _GradeTwoUnitTwoLessonOneParkGreetingFlowState();
}

class _GradeTwoUnitTwoLessonOneParkGreetingFlowState
    extends State<_GradeTwoUnitTwoLessonOneParkGreetingFlow> {
  static const _voiceBase = 'audio/VO-final/grade2';
  static const _backgroundAsset =
      'assets/images/level_game/grade2/backgrounds/Tudlo_G2_U2_L2.1_Park_Intro_Background.svg';
  static const _friendGirlOne =
      'assets/images/level_game/grade2/people/Tudlo_Park_Friend_Girl_1.svg';
  static const _friendBoy =
      'assets/images/level_game/grade2/people/Tudlo_Park_Friend_Boy.svg';
  static const _friendGirlTwo =
      'assets/images/level_game/grade2/people/Tudlo_Park_Friend_Girl_2.svg';
  static const _answerByTime = {
    'morning': 'good_morning',
    'afternoon': 'good_afternoon',
    'evening': 'good_evening',
  };

  _G2ParkGreetingStep _step = _G2ParkGreetingStep.intro;
  bool _voicePlaying = false;
  bool _parkSelected = false;
  String? _selectedGreetingId;
  String? _wrongGreetingId;
  String? _activeMatchTimeId;
  String? _wrongMatchGreetingId;
  bool _completed = false;
  final Set<String> _completedTimes = {};
  final Set<String> _reviewedTimes = {};
  final Map<String, String> _matchedGreetings = {};

  double get _progress =>
      (_G2ParkGreetingStep.values.indexOf(_step) + 1) /
      _G2ParkGreetingStep.values.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _goToStep(_G2ParkGreetingStep step) {
    if (_step == step) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _step = step;
      _selectedGreetingId = null;
      _wrongGreetingId = null;
      _wrongMatchGreetingId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_2_Les_2_1_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_step) {
      _G2ParkGreetingStep.intro => const [2],
      _G2ParkGreetingStep.map => const [3],
      _G2ParkGreetingStep.morningTeach => const [4],
      _G2ParkGreetingStep.morningPractice => const [5, 6],
      _G2ParkGreetingStep.afternoonTeach => const [9],
      _G2ParkGreetingStep.afternoonPractice => const [10, 11],
      _G2ParkGreetingStep.eveningTeach => const [14],
      _G2ParkGreetingStep.eveningPractice => const [15, 16],
      _G2ParkGreetingStep.review => const [19],
      _G2ParkGreetingStep.match => const [19],
      _G2ParkGreetingStep.reward => const [22],
    };
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_step) {
          _G2ParkGreetingStep.intro =>
            'Maglibot kita sa Park halin aga tubtob gab-i!',
          _G2ParkGreetingStep.map => 'I-tap ang Park sa mapa.',
          _G2ParkGreetingStep.morningTeach => 'Good morning sa aga.',
          _G2ParkGreetingStep.morningPractice => 'Pilia ang Good morning.',
          _G2ParkGreetingStep.afternoonTeach => 'Good afternoon sa hapon.',
          _G2ParkGreetingStep.afternoonPractice => 'Pilia ang Good afternoon.',
          _G2ParkGreetingStep.eveningTeach => 'Good evening sa gab-i.',
          _G2ParkGreetingStep.eveningPractice => 'Pilia ang Good evening.',
          _G2ParkGreetingStep.review =>
            'Ipares ang greeting sa aga, hapon, kag gab-i.',
          _G2ParkGreetingStep.match =>
            'Ipares ang greeting sa aga, hapon, kag gab-i.',
          _G2ParkGreetingStep.reward =>
            'Kabalo ka na mag-greet sa nagkalain-lain nga tion!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted) setState(() => _voicePlaying = false);
    }
  }

  Future<void> _tapPark() async {
    if (_voicePlaying || _parkSelected) return;
    setState(() => _parkSelected = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) _goToStep(_G2ParkGreetingStep.morningTeach);
  }

  Future<void> _chooseGreeting(String timeId, _G2FriendChoice choice) async {
    if (_voicePlaying || _selectedGreetingId != null) {
      return;
    }
    final quizIndex = switch (timeId) {
      'morning' => 0,
      'afternoon' => 1,
      _ => 2,
    };
    final correct = _answerByTime[timeId] == choice.id;
    widget.onQuizAttempt(quizIndex, correct);
    setState(() {
      _selectedGreetingId = choice.id;
      _wrongGreetingId = correct ? null : choice.id;
    });
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(switch (timeId) {
        'morning' => const [8],
        'afternoon' => const [13],
        _ => const [18],
      });
      await Future<void>.delayed(const Duration(milliseconds: 460));
      if (!mounted) return;
      setState(() {
        _selectedGreetingId = null;
        _wrongGreetingId = null;
      });
      return;
    }
    widget.onQuizCorrect(quizIndex);
    setState(() => _completedTimes.add(timeId));
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    _goToStep(switch (timeId) {
      'morning' => _G2ParkGreetingStep.afternoonTeach,
      'afternoon' => _G2ParkGreetingStep.eveningTeach,
      _ => _G2ParkGreetingStep.match,
    });
  }

  Future<void> _reviewTime(String timeId) async {
    if (_voicePlaying) return;
    setState(() => _reviewedTimes.add(timeId));
    await _playVoice(switch (timeId) {
      'morning' => const [6],
      'afternoon' => const [8],
      _ => const [10],
    });
  }

  Future<void> _matchGreeting(String greetingId, String timeId) async {
    if (_voicePlaying || _matchedGreetings.containsKey(timeId)) return;
    final correct = _answerByTime[timeId] == greetingId;
    widget.onQuizAttempt(3, correct);
    if (!correct) {
      setState(() => _wrongMatchGreetingId = greetingId);
      await AppAudioService.instance.playWrong();
      await _playVoice(const [21]);
      await Future<void>.delayed(const Duration(milliseconds: 430));
      if (mounted) setState(() => _wrongMatchGreetingId = null);
      return;
    }
    setState(() {
      _matchedGreetings[timeId] = greetingId;
      _activeMatchTimeId = null;
    });
    await AppAudioService.instance.playCorrect();
    if (_matchedGreetings.length == 3) {
      widget.onQuizCorrect(3);
      await _playVoice(const [20]);
      await Future<void>.delayed(_lessonCompletionHold);
      if (mounted) _goToStep(_G2ParkGreetingStep.reward);
    }
  }

  Future<void> _tapGreetingForMatch(String greetingId) async {
    final timeId = _activeMatchTimeId;
    if (timeId == null) return;
    await _matchGreeting(greetingId, timeId);
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('g2-u2-l1-$_step'),
        child: switch (_step) {
          _G2ParkGreetingStep.intro => _G2ParkGreetingIntroStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.map),
          ),
          _G2ParkGreetingStep.map => _G2ParkGreetingMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: _tapPark,
          ),
          _G2ParkGreetingStep.morningTeach => _G2ParkGreetingTeachStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[0].backgroundAsset,
            time: _parkGreetingTimes[0],
            characterAsset: _friendGirlOne,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.morningPractice),
          ),
          _G2ParkGreetingStep.morningPractice => _G2ParkGreetingPracticeStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[0].backgroundAsset,
            time: _parkGreetingTimes[0],
            characterAsset: _friendGirlOne,
            completedTimes: _completedTimes,
            selectedId: _selectedGreetingId,
            wrongId: _wrongGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: (choice) => _chooseGreeting('morning', choice),
          ),
          _G2ParkGreetingStep.afternoonTeach => _G2ParkGreetingTeachStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[1].backgroundAsset,
            time: _parkGreetingTimes[1],
            characterAsset: _friendBoy,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.afternoonPractice),
          ),
          _G2ParkGreetingStep.afternoonPractice => _G2ParkGreetingPracticeStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[1].backgroundAsset,
            time: _parkGreetingTimes[1],
            characterAsset: _friendBoy,
            completedTimes: _completedTimes,
            selectedId: _selectedGreetingId,
            wrongId: _wrongGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: (choice) => _chooseGreeting('afternoon', choice),
          ),
          _G2ParkGreetingStep.eveningTeach => _G2ParkGreetingTeachStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[2].backgroundAsset,
            time: _parkGreetingTimes[2],
            characterAsset: _friendGirlTwo,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkGreetingStep.eveningPractice),
          ),
          _G2ParkGreetingStep.eveningPractice => _G2ParkGreetingPracticeStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[2].backgroundAsset,
            time: _parkGreetingTimes[2],
            characterAsset: _friendGirlTwo,
            completedTimes: _completedTimes,
            selectedId: _selectedGreetingId,
            wrongId: _wrongGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: (choice) => _chooseGreeting('evening', choice),
          ),
          _G2ParkGreetingStep.review => _G2ParkGreetingReviewStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            reviewedTimes: _reviewedTimes,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onReviewTime: _reviewTime,
            onNext: () => _goToStep(_G2ParkGreetingStep.match),
          ),
          _G2ParkGreetingStep.match => _G2ParkGreetingMatchStep(
            progress: _progress,
            backgroundAsset: _parkGreetingTimes[0].backgroundAsset,
            activeTimeId: _activeMatchTimeId,
            matchedGreetings: _matchedGreetings,
            wrongGreetingId: _wrongMatchGreetingId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onSelectTime: (timeId) =>
                setState(() => _activeMatchTimeId = timeId),
            onMatch: _matchGreeting,
            onTapGreeting: _tapGreetingForMatch,
          ),
          _G2ParkGreetingStep.reward => _G2ParkGreetingRewardStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _ParkGreetingTime {
  final String id;
  final String timeLabel;
  final String localLabel;
  final String greeting;
  final String backgroundAsset;
  final String stickerAsset;
  final IconData icon;
  final Color color;
  final Color tint;

  const _ParkGreetingTime({
    required this.id,
    required this.timeLabel,
    required this.localLabel,
    required this.greeting,
    required this.backgroundAsset,
    required this.stickerAsset,
    required this.icon,
    required this.color,
    required this.tint,
  });
}

const _parkGreetingTimes = [
  _ParkGreetingTime(
    id: 'morning',
    timeLabel: 'Morning',
    localLabel: 'aga',
    greeting: 'Good morning',
    backgroundAsset:
        'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Morning_Background.svg',
    stickerAsset:
        'assets/images/level_game/grade2/lesson-game-assets/Tudlo_Morning_Sunrise_Sticker.svg',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFFC928),
    tint: Color(0x22FFD35C),
  ),
  _ParkGreetingTime(
    id: 'afternoon',
    timeLabel: 'Afternoon',
    localLabel: 'hapon',
    greeting: 'Good afternoon',
    backgroundAsset:
        'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Afternoon_Background.svg',
    stickerAsset:
        'assets/images/level_game/grade2/lesson-game-assets/Tudlo_Afternoon_High_Sun_Sticker.svg',
    icon: Icons.light_mode_rounded,
    color: Color(0xFF1EA7FF),
    tint: Color(0x33FF9F43),
  ),
  _ParkGreetingTime(
    id: 'evening',
    timeLabel: 'Evening',
    localLabel: 'gab-i',
    greeting: 'Good evening',
    backgroundAsset:
        'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Night_Background.svg',
    stickerAsset:
        'assets/images/level_game/grade2/lesson-game-assets/Tudlo_Evening_Sunset_Sticker.svg',
    icon: Icons.dark_mode_rounded,
    color: Color(0xFF7C4DFF),
    tint: Color(0x44304B9B),
  ),
];

const _parkGreetingChoices = [
  _G2FriendChoice('good_morning', 'Good morning'),
  _G2FriendChoice('good_afternoon', 'Good afternoon'),
  _G2FriendChoice('good_evening', 'Good evening'),
];

const _parkGreetingMatchChoices = [
  _G2FriendChoice('good_evening', 'Good evening'),
  _G2FriendChoice('good_morning', 'Good morning'),
  _G2FriendChoice('good_afternoon', 'Good afternoon'),
];

class _G2ParkScene extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final _ParkGreetingTime? time;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;

  const _G2ParkScene({
    required this.progress,
    required this.backgroundAsset,
    required this.time,
    required this.onExit,
    required this.onReplay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(children: [child]),
    );
  }
}

class _G2ParkGreetingIntroStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkGreetingIntroStep({
    required this.progress,
    required this.backgroundAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: view.height * .24,
            height: (view.width * .27).clamp(105.0, 144.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final entry in _parkGreetingTimes.indexed)
                  Align(
                    alignment: const [
                      Alignment(-.78, 0),
                      Alignment(0, 0),
                      Alignment(.78, 0),
                    ][entry.$1],
                    child: SizedBox(
                      width: (view.width * .27).clamp(105.0, 144.0),
                      height: (view.width * .27).clamp(105.0, 144.0),
                      child: _ParkIntroTimeSticker(time: entry.$2),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: view.height * .205,
            child: Center(
              child: _LessonKokaMascot(
                size: (view.width * .78).clamp(295.0, 385.0),
                mood: KokaMood.idle,
              ),
            ),
          ),
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            bottom: view.height * .04,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LessonOneMessageCard(
                  message: 'Maglibot kita sa Park halin aga tubtob gab-i!',
                ),
                SizedBox(height: view.height * .018),
                _LessonOneBlueButton(
                  label: 'Libot ta',
                  onTap: inputReady ? onNext : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkIntroTimeSticker extends StatelessWidget {
  final _ParkGreetingTime time;

  const _ParkIntroTimeSticker({required this.time});

  @override
  Widget build(BuildContext context) {
    return _LessonPictureAsset(
      asset: time.stickerAsset,
      fit: BoxFit.contain,
      errorBuilder: (_) => Icon(time.icon, color: time.color, size: 58),
    );
  }
}

class _G2ParkGreetingMapStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkGreetingMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final mapSize = Size(view.width * 1.34, view.height * 1.06);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/tudlomap.svg',
      child: Stack(
        children: [
          SizedBox(
            width: mapSize.width,
            height: mapSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _LessonBackgroundAsset(
                  asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
                ),
                Positioned(
                  left: mapSize.width * .40,
                  top: mapSize.height * .42,
                  width: mapSize.width * .22,
                  height: mapSize.width * .22,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNext,
                    child: const _LessonOneMapDestinationCue(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: view.width * .12,
            right: view.width * .12,
            bottom: view.height * .06,
            child: const _LessonOneMessageCard(
              message: 'I-tap ang Park.',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2ParkGreetingTeachStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final _ParkGreetingTime time;
  final String characterAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkGreetingTeachStep({
    required this.progress,
    required this.backgroundAsset,
    required this.time,
    required this.characterAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: time,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .045,
        ),
        child: Column(
          children: [
            Expanded(
              child: _ParkCharacterGreetingStage(
                time: time,
                characterAsset: characterAsset,
                greeting: time.greeting,
              ),
            ),
            _LessonOneMessageCard(
              message: '${time.greeting} sa ${time.localLabel}.',
              compact: true,
            ),
            SizedBox(height: view.height * .018),
            _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkGreetingPracticeStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final _ParkGreetingTime time;
  final String characterAsset;
  final Set<String> completedTimes;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2ParkGreetingPracticeStep({
    required this.progress,
    required this.backgroundAsset,
    required this.time,
    required this.characterAsset,
    required this.completedTimes,
    required this.selectedId,
    required this.wrongId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final correctId =
        _GradeTwoUnitTwoLessonOneParkGreetingFlowState._answerByTime[time.id]!;
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: time,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .13,
          view.width * .055,
          view.height * .035,
        ),
        child: Column(
          children: [
            Expanded(
              child: _ParkCharacterGreetingStage(
                time: time,
                characterAsset: characterAsset,
                greeting: time.greeting,
                showGreeting: selectedId == correctId,
                active: selectedId == correctId,
              ),
            ),
            Column(
              children: [
                for (final choice in _parkGreetingChoices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: _ParkGreetingCard(
                        label: choice.label,
                        correct:
                            selectedId == choice.id && choice.id == correctId,
                        wrong: wrongId == choice.id,
                        enabled: inputReady && selectedId == null,
                        onTap: () => onChoose(choice),
                      ),
                    ),
                  ),
              ],
            ),
            if (time.id != 'morning') ...[
              SizedBox(height: view.height * .01),
              _ParkTimeReviewStrip(completedTimes: completedTimes),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParkCharacterGreetingStage extends StatelessWidget {
  final _ParkGreetingTime time;
  final String characterAsset;
  final String greeting;
  final bool showGreeting;
  final bool active;

  const _ParkCharacterGreetingStage({
    required this.time,
    required this.characterAsset,
    required this.greeting,
    this.showGreeting = false,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          bottom: view.height * .015,
          width: view.width * .58,
          height: view.height * .40,
          child: Center(
            child: _LessonKokaMascot(
              size: (view.width * .80).clamp(300.0, 410.0),
              mood: KokaMood.idle,
            ),
          ),
        ),
        Positioned(
          right: view.width * .03,
          bottom: view.height * .02,
          width: view.width * .42,
          height: view.height * .40,
          child: _FeedbackMotion(
            correct: active,
            wrong: false,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _LessonPictureAsset(
                  asset: characterAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_) => Icon(
                    Icons.person_rounded,
                    color: TudloColors.blue,
                    size: view.width * .28,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showGreeting)
          Positioned(
            left: view.width * .12,
            top: view.height * .055,
            width: view.width * .40,
            child: _LessonOneMessageCard(message: greeting, compact: true),
          ),
      ],
    );
  }
}

class _G2ParkGreetingReviewStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final Set<String> reviewedTimes;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String timeId) onReviewTime;
  final VoidCallback onNext;

  const _G2ParkGreetingReviewStep({
    required this.progress,
    required this.backgroundAsset,
    required this.reviewedTimes,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onReviewTime,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final canContinue = reviewedTimes.length == 3;
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Pamatian liwat ang mga greeting.',
              compact: true,
            ),
            SizedBox(height: view.height * .035),
            for (final time in _parkGreetingTimes) ...[
              GestureDetector(
                onTap: inputReady ? () => onReviewTime(time.id) : null,
                child: _ParkTimeGreetingRow(
                  time: time,
                  reviewed: reviewedTimes.contains(time.id),
                ),
              ),
              SizedBox(height: view.height * .02),
            ],
            const Spacer(),
            _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady && canContinue ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkGreetingMatchStep extends StatefulWidget {
  final double progress;
  final String backgroundAsset;
  final String? activeTimeId;
  final Map<String, String> matchedGreetings;
  final String? wrongGreetingId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onSelectTime;
  final Future<void> Function(String greetingId, String timeId) onMatch;
  final Future<void> Function(String greetingId) onTapGreeting;

  const _G2ParkGreetingMatchStep({
    required this.progress,
    required this.backgroundAsset,
    required this.activeTimeId,
    required this.matchedGreetings,
    required this.wrongGreetingId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onSelectTime,
    required this.onMatch,
    required this.onTapGreeting,
  });

  @override
  State<_G2ParkGreetingMatchStep> createState() =>
      _G2ParkGreetingMatchStepState();
}

class _G2ParkGreetingMatchStepState extends State<_G2ParkGreetingMatchStep> {
  String? _dragTimeId;
  String? _dragGreetingId;
  Color? _dragColor;
  Offset? _dragStart;
  Offset? _dragEnd;

  _ParkGreetingTime _timeForGreeting(String greetingId) {
    final choice = _parkGreetingChoices.firstWhere(
      (choice) => choice.id == greetingId,
    );
    return _parkGreetingTimes.firstWhere(
      (time) => time.greeting == choice.label,
    );
  }

  int? _cardIndexAt(Offset point, double cardHeight, double gap) {
    for (var i = 0; i < _parkGreetingTimes.length; i++) {
      final top = i * (cardHeight + gap);
      if (point.dy >= top && point.dy <= top + cardHeight) return i;
    }
    return null;
  }

  void _startLine(
    DragStartDetails details,
    double boardWidth,
    double cardHeight,
    double gap,
    double spacer,
  ) {
    if (!widget.inputReady) return;
    final point = details.localPosition;
    final columnWidth = (boardWidth - spacer) / 2;
    final rightStart = columnWidth + spacer;
    const stickerSize = 132.0;
    final leftAnchorX = ((columnWidth + stickerSize) / 2).clamp(
      0.0,
      columnWidth,
    );
    final index = _cardIndexAt(point, cardHeight, gap);
    if (index == null) return;

    if (point.dx <= columnWidth) {
      final time = _parkGreetingTimes[index];
      if (widget.matchedGreetings.containsKey(time.id)) return;
      setState(() {
        _dragTimeId = time.id;
        _dragGreetingId = null;
        _dragColor = time.color;
        _dragStart = Offset(
          leftAnchorX,
          index * (cardHeight + gap) + cardHeight / 2,
        );
        _dragEnd = point;
      });
      return;
    }

    if (point.dx < rightStart) return;
    final choice = _parkGreetingMatchChoices[index];
    if (widget.matchedGreetings.values.contains(choice.id)) return;
    final time = _timeForGreeting(choice.id);
    setState(() {
      _dragTimeId = null;
      _dragGreetingId = choice.id;
      _dragColor = time.color;
      _dragStart = Offset(
        rightStart,
        index * (cardHeight + gap) + cardHeight / 2,
      );
      _dragEnd = point;
    });
  }

  void _updateLine(DragUpdateDetails details) {
    if (_dragTimeId == null && _dragGreetingId == null) return;
    setState(() => _dragEnd = details.localPosition);
  }

  void _finishLine(
    DragEndDetails details,
    double boardWidth,
    double cardHeight,
    double gap,
    double spacer,
  ) {
    final timeId = _dragTimeId;
    final greetingId = _dragGreetingId;
    final end = _dragEnd;
    setState(() {
      _dragTimeId = null;
      _dragGreetingId = null;
      _dragColor = null;
      _dragStart = null;
      _dragEnd = null;
    });
    if (end == null || !widget.inputReady) return;
    final columnWidth = (boardWidth - spacer) / 2;
    final rightStart = columnWidth + spacer;
    final index = _cardIndexAt(end, cardHeight, gap);
    if (index == null) return;

    if (timeId != null) {
      if (end.dx < rightStart) return;
      final choice = _parkGreetingMatchChoices[index];
      if (widget.matchedGreetings.values.contains(choice.id)) return;
      unawaited(widget.onMatch(choice.id, timeId));
      return;
    }

    if (greetingId != null) {
      if (end.dx > columnWidth) return;
      final time = _parkGreetingTimes[index];
      if (widget.matchedGreetings.containsKey(time.id)) return;
      unawaited(widget.onMatch(greetingId, time.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final usedGreetingIds = widget.matchedGreetings.values.toSet();
    return _G2ParkScene(
      progress: widget.progress,
      backgroundAsset: widget.backgroundAsset,
      time: null,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          view.height * .13,
          view.width * .045,
          view.height * .035,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Ipares ang greeting sa aga, hapon, kag gab-i.',
              compact: true,
            ),
            SizedBox(height: view.height * .018),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cardHeight = 132.0;
                  const stickerSize = 132.0;
                  final gap = view.height * .012;
                  final spacer = view.width * .15;
                  final columnWidth = (constraints.maxWidth - spacer) / 2;
                  final leftAnchorX = ((columnWidth + stickerSize) / 2).clamp(
                    0.0,
                    columnWidth,
                  );
                  final rightAnchorX = columnWidth + spacer;
                  final boardHeight = (cardHeight * 3) + (gap * 2);
                  return Center(
                    child: SizedBox(
                      height: boardHeight,
                      child: LayoutBuilder(
                        builder: (context, boardConstraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) => _startLine(
                              details,
                              boardConstraints.maxWidth,
                              cardHeight,
                              gap,
                              spacer,
                            ),
                            onPanUpdate: _updateLine,
                            onPanEnd: (details) => _finishLine(
                              details,
                              boardConstraints.maxWidth,
                              cardHeight,
                              gap,
                              spacer,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _ParkGreetingMatchLinePainter(
                                      matchedGreetings: widget.matchedGreetings,
                                      choices: _parkGreetingMatchChoices,
                                      gap: gap,
                                      cardHeight: cardHeight,
                                      leftX: leftAnchorX,
                                      rightX: rightAnchorX,
                                      activeTimeId: _dragTimeId,
                                      activeColor: _dragColor,
                                      activeStart: _dragStart,
                                      activeEnd: _dragEnd,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          for (final time
                                              in _parkGreetingTimes) ...[
                                            SizedBox(
                                              height: cardHeight,
                                              child: _ParkTimeMatchCard(
                                                time: time,
                                                active:
                                                    _dragTimeId == time.id ||
                                                    widget.activeTimeId ==
                                                        time.id,
                                                greetingId: widget
                                                    .matchedGreetings[time.id],
                                                inputReady: widget.inputReady,
                                              ),
                                            ),
                                            if (time != _parkGreetingTimes.last)
                                              SizedBox(height: gap),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: spacer),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          for (final choice
                                              in _parkGreetingMatchChoices) ...[
                                            SizedBox(
                                              height: cardHeight,
                                              child: _StaticGreetingMatchCard(
                                                choice: choice,
                                                hidden: usedGreetingIds
                                                    .contains(choice.id),
                                                wrong:
                                                    widget.wrongGreetingId ==
                                                    choice.id,
                                                enabled: widget.inputReady,
                                                onTap: () => widget
                                                    .onTapGreeting(choice.id),
                                              ),
                                            ),
                                            if (choice !=
                                                _parkGreetingMatchChoices.last)
                                              SizedBox(height: gap),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkGreetingMatchLinePainter extends CustomPainter {
  final Map<String, String> matchedGreetings;
  final List<_G2FriendChoice> choices;
  final double gap;
  final double cardHeight;
  final double leftX;
  final double rightX;
  final String? activeTimeId;
  final Color? activeColor;
  final Offset? activeStart;
  final Offset? activeEnd;

  const _ParkGreetingMatchLinePainter({
    required this.matchedGreetings,
    required this.choices,
    required this.gap,
    required this.cardHeight,
    required this.leftX,
    required this.rightX,
    this.activeTimeId,
    this.activeColor,
    this.activeStart,
    this.activeEnd,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final timeIndex = {
      for (var i = 0; i < _parkGreetingTimes.length; i++)
        _parkGreetingTimes[i].id: i,
    };
    final choiceIndex = {
      for (var i = 0; i < choices.length; i++) choices[i].id: i,
    };
    final timeColor = {
      for (final time in _parkGreetingTimes) time.id: time.color,
    };
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 7;

    for (final match in matchedGreetings.entries) {
      final fromIndex = timeIndex[match.key];
      final toIndex = choiceIndex[match.value];
      if (fromIndex == null || toIndex == null) continue;
      final fromY = (fromIndex * (cardHeight + gap)) + (cardHeight / 2);
      final toY = (toIndex * (cardHeight + gap)) + (cardHeight / 2);
      final color = timeColor[match.key] ?? TudloColors.blue;

      paint.color = color.withValues(alpha: .2);
      paint.strokeWidth = 13;
      canvas.drawLine(Offset(leftX, fromY), Offset(rightX, toY), paint);
      paint.color = color;
      paint.strokeWidth = 7;
      canvas.drawLine(Offset(leftX, fromY), Offset(rightX, toY), paint);

      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(leftX, fromY), 7, dotPaint);
      canvas.drawCircle(Offset(rightX, toY), 7, dotPaint);
    }

    final activeStart = this.activeStart;
    final activeEnd = this.activeEnd;
    if (activeStart != null && activeEnd != null) {
      final color = activeColor ?? timeColor[activeTimeId] ?? TudloColors.blue;
      paint.color = color.withValues(alpha: .22);
      paint.strokeWidth = 13;
      canvas.drawLine(activeStart, activeEnd, paint);
      paint.color = color;
      paint.strokeWidth = 7;
      canvas.drawLine(activeStart, activeEnd, paint);
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(activeStart, 7, dotPaint);
      canvas.drawCircle(activeEnd, 7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParkGreetingMatchLinePainter oldDelegate) {
    return oldDelegate.matchedGreetings != matchedGreetings ||
        oldDelegate.choices != choices ||
        oldDelegate.gap != gap ||
        oldDelegate.cardHeight != cardHeight ||
        oldDelegate.leftX != leftX ||
        oldDelegate.rightX != rightX ||
        oldDelegate.activeTimeId != activeTimeId ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStart != activeStart ||
        oldDelegate.activeEnd != activeEnd;
  }
}

class _G2ParkGreetingRewardStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _G2ParkGreetingRewardStep({
    required this.progress,
    required this.backgroundAsset,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'PANAMYAW\n1'),
        message: 'Kabalo ka na mag-greet sa nagkalain-lain nga tion!',
        onDone: onDone,
      ),
    );
  }
}

class _ParkTimeCard extends StatelessWidget {
  final _ParkGreetingTime time;
  final bool selected;
  final bool checked;

  const _ParkTimeCard({
    required this.time,
    required this.selected,
    this.checked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: _LessonPictureAsset(
            asset: time.stickerAsset,
            fit: BoxFit.contain,
            errorBuilder: (_) => Icon(time.icon, color: time.color, size: 68),
          ),
        ),
        if (checked)
          Positioned(
            right: 4,
            bottom: 6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: TudloColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
      ],
    );
  }
}

class _ParkTimeReviewStrip extends StatelessWidget {
  final Set<String> completedTimes;

  const _ParkTimeReviewStrip({required this.completedTimes});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final time in _parkGreetingTimes)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 92,
                child: _ParkTimeCard(
                  time: time,
                  selected: false,
                  checked: completedTimes.contains(time.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParkGreetingCard extends StatelessWidget {
  final String label;
  final bool correct;
  final bool wrong;
  final bool enabled;
  final double height;
  final VoidCallback onTap;

  const _ParkGreetingCard({
    required this.label,
    required this.correct,
    required this.wrong,
    required this.enabled,
    this.height = 82,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: correct ? const Color(0xFFE8FFD8) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: correct
                  ? TudloColors.green
                  : wrong
                  ? TudloColors.coral
                  : TudloColors.blue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .14),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: 23,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParkTimeGreetingRow extends StatelessWidget {
  final _ParkGreetingTime time;
  final bool reviewed;

  const _ParkTimeGreetingRow({required this.time, required this.reviewed});

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: reviewed,
      wrong: false,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: reviewed ? TudloColors.green : const Color(0xFFD8E8F6),
            width: 3,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 116,
              child: _ParkTimeCard(time: time, selected: reviewed),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                time.greeting,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.blue,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(
              reviewed ? Icons.check_circle_rounded : Icons.volume_up_rounded,
              color: reviewed ? TudloColors.green : TudloColors.blue,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkTimeMatchCard extends StatelessWidget {
  final _ParkGreetingTime time;
  final bool active;
  final String? greetingId;
  final bool inputReady;

  const _ParkTimeMatchCard({
    required this.time,
    required this.active,
    required this.greetingId,
    required this.inputReady,
  });

  @override
  Widget build(BuildContext context) {
    final locked = greetingId != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: locked ? .75 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: _LessonPictureAsset(
              asset: time.stickerAsset,
              fit: BoxFit.contain,
              errorBuilder: (_) => Icon(time.icon, color: time.color, size: 92),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticGreetingMatchCard extends StatelessWidget {
  final _G2FriendChoice choice;
  final bool hidden;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _StaticGreetingMatchCard({
    required this.choice,
    required this.hidden,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: hidden ? .45 : 1,
      child: _ParkGreetingCard(
        label: choice.label,
        correct: false,
        wrong: wrong,
        enabled: enabled && !hidden,
        height: 132,
        onTap: onTap,
      ),
    );
  }
}
