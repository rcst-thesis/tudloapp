part of '../../level_game_page.dart';

enum _G2BirthdayStep {
  invitation,
  map,
  balloons,
  askAge,
  seven,
  chooseSeven,
  buildAnswer,
  reward,
}

class _GradeTwoUnitOneLessonTwoBirthdayFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoUnitOneLessonTwoBirthdayFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoUnitOneLessonTwoBirthdayFlow> createState() =>
      _GradeTwoUnitOneLessonTwoBirthdayFlowState();
}

class _GradeTwoUnitOneLessonTwoBirthdayFlowState
    extends State<_GradeTwoUnitOneLessonTwoBirthdayFlow> {
  static const _voiceBase = 'audio/VO-final/grade2';
  static const _anaAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Full_Body_Character.svg';
  static const _anaCelebrateAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Celebrating_Age_Seven.svg';
  static const _introBackgroundAsset =
      'assets/images/level_game/grade2/backgrounds/Tudlo_Birthday_Background_Ana_Holding_Cake.svg';
  static const _activityBackgroundAsset = _g2BirthdayWithoutAnaBackground;
  static const _answerOrder = ['i_am', 'seven_years_old'];

  _G2BirthdayStep _step = _G2BirthdayStep.invitation;
  bool _voicePlaying = false;
  bool _invitationOpened = false;
  bool _questionHeard = false;
  final Set<int> _revealedBalloons = {};
  String? _selectedAgeId;
  String? _wrongAgeId;
  String? _wrongTileId;
  bool _completed = false;
  final List<String?> _answerSlots = List<String?>.filled(2, null);

  double get _progress =>
      (_G2BirthdayStep.values.indexOf(_step) + 1) /
      _G2BirthdayStep.values.length;

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

  void _goToStep(_G2BirthdayStep step) {
    if (_step == step) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _step = step;
      _selectedAgeId = null;
      _wrongAgeId = null;
      _wrongTileId = null;
      if (step == _G2BirthdayStep.balloons) _questionHeard = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_2_Les_1_2_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_step) {
      _G2BirthdayStep.invitation => const [2],
      _G2BirthdayStep.map => const [3],
      _G2BirthdayStep.balloons => const [4],
      _G2BirthdayStep.askAge => const [8],
      _G2BirthdayStep.seven => const [9],
      _G2BirthdayStep.chooseSeven => const [11, 12],
      _G2BirthdayStep.buildAnswer => const [17],
      _G2BirthdayStep.reward => const [16],
    };
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_step) {
          _G2BirthdayStep.invitation => 'May birthday invitation si Ana!',
          _G2BirthdayStep.map => 'I-tap ang Balay ni Koka.',
          _G2BirthdayStep.balloons => 'May mga balloon!',
          _G2BirthdayStep.askAge => 'How old are you?',
          _G2BirthdayStep.seven => 'Seven years old si Ana.',
          _G2BirthdayStep.chooseSeven => 'Pilia ang numbero seven.',
          _G2BirthdayStep.buildAnswer => 'Ihan-ay: I am seven years old.',
          _G2BirthdayStep.reward => 'Makasiling ka na sang imo edad!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted) setState(() => _voicePlaying = false);
    }
  }

  Future<void> _openInvitation() async {
    if (_voicePlaying || _invitationOpened) return;
    setState(() => _invitationOpened = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (mounted) _goToStep(_G2BirthdayStep.map);
  }

  Future<void> _revealBalloon(int number) async {
    if (_voicePlaying || _revealedBalloons.contains(number)) return;
    setState(() => _revealedBalloons.add(number));
    await AppAudioService.instance.playTap();
    await playLessonNumberVoice(number);
    if (_revealedBalloons.length >= 4) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) _goToStep(_G2BirthdayStep.chooseSeven);
    }
  }

  Future<void> _hearQuestion() async {
    if (_voicePlaying || _questionHeard) return;
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(const [5]);
      if (!mounted) return;
      setState(() => _questionHeard = true);
      await _playVoice(const [10]);
    } finally {
      if (mounted) setState(() => _voicePlaying = false);
    }
  }

  Future<void> _tapAnaForAge() async {
    if (_voicePlaying || !_questionHeard) return;
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(const [9]);
    } finally {
      if (mounted) setState(() => _voicePlaying = false);
    }
    if (mounted) _goToStep(_G2BirthdayStep.askAge);
  }

  Future<void> _chooseAge(_G2FriendChoice choice) async {
    if (_voicePlaying || _selectedAgeId != null) return;
    final correct = choice.id == 'age_7';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _selectedAgeId = choice.id;
      _wrongAgeId = correct ? null : choice.id;
    });
    final selectedNumber = int.tryParse(choice.label);
    if (selectedNumber != null) await playLessonNumberVoice(selectedNumber);
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(const [11]);
      await Future<void>.delayed(const Duration(milliseconds: 430));
      if (!mounted) return;
      setState(() {
        _selectedAgeId = null;
        _wrongAgeId = null;
      });
      return;
    }
    widget.onQuizCorrect(0);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) _goToStep(_G2BirthdayStep.buildAnswer);
  }

  Future<void> _placeAnswerTile(String tileId, int slotIndex) async {
    if (_voicePlaying || _answerSlots.contains(tileId)) return;
    setState(() => _answerSlots[slotIndex] = tileId);
    await AppAudioService.instance.playTap();
    if (_answerSlots.any((slot) => slot == null)) return;
    final correct = List.generate(
      _answerOrder.length,
      (index) => _answerSlots[index] == _answerOrder[index],
    ).every((match) => match);
    widget.onQuizAttempt(1, correct);
    if (!correct) {
      final wrongIds = <String>{
        for (var index = 0; index < _answerOrder.length; index++)
          if (_answerSlots[index] != _answerOrder[index]) _answerSlots[index]!,
      };
      setState(() => _wrongTileId = wrongIds.first);
      await AppAudioService.instance.playWrong();
      await _playVoice(const [20]);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        for (var index = 0; index < _answerSlots.length; index++) {
          if (_answerSlots[index] != _answerOrder[index]) {
            _answerSlots[index] = null;
          }
        }
        _wrongTileId = null;
      });
      return;
    }
    widget.onQuizCorrect(1);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [18, 19]);
    await Future<void>.delayed(_lessonCompletionHold);
    if (mounted) _goToStep(_G2BirthdayStep.reward);
  }

  Future<void> _tapAnswerTile(String tileId) async {
    final slotIndex = _answerSlots.indexWhere((slot) => slot == null);
    if (slotIndex == -1) return;
    await _placeAnswerTile(tileId, slotIndex);
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
        key: ValueKey('g2-u1-l2-$_step'),
        child: switch (_step) {
          _G2BirthdayStep.invitation => _G2BirthdayInvitationStep(
            progress: _progress,
            backgroundAsset: _introBackgroundAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onOpen: _openInvitation,
          ),
          _G2BirthdayStep.map => _G2BirthdayMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2BirthdayStep.balloons),
          ),
          _G2BirthdayStep.balloons => _G2BirthdayAskAgeStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaAsset,
            questionHeard: _questionHeard,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onQuestion: _hearQuestion,
            onTapAna: _tapAnaForAge,
          ),
          _G2BirthdayStep.askAge => _G2BirthdayBalloonsStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            revealed: _revealedBalloons,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onReveal: _revealBalloon,
          ),
          _G2BirthdayStep.seven => _G2BirthdaySevenStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaCelebrateAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2BirthdayStep.chooseSeven),
          ),
          _G2BirthdayStep.chooseSeven => _G2BirthdayChooseSevenStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            selectedId: _selectedAgeId,
            wrongId: _wrongAgeId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseAge,
          ),
          _G2BirthdayStep.buildAnswer => _G2BirthdayBuildAnswerStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaCelebrateAsset,
            slots: _answerSlots,
            wrongTileId: _wrongTileId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placeAnswerTile,
            onTapTile: _tapAnswerTile,
          ),
          _G2BirthdayStep.reward => _G2BirthdayRewardStep(
            progress: _progress,
            backgroundAsset: _activityBackgroundAsset,
            anaAsset: _anaCelebrateAsset,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _G2BirthdayInvitationStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function() onOpen;

  const _G2BirthdayInvitationStep({
    required this.progress,
    required this.backgroundAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .045,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LessonOneMessageCard(
                  message: 'May birthday invitation si Ana!',
                ),
                SizedBox(height: view.height * .02),
                _LessonOneBlueButton(
                  label: 'Sige',
                  onTap: inputReady ? () => unawaited(onOpen()) : null,
                ),
              ],
            ),
          ),
          Positioned(
            left: view.width * .21,
            right: view.width * .21,
            bottom: view.height * .245,
            child: GestureDetector(
              onTap: inputReady ? () => unawaited(onOpen()) : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFF8FC7),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8FC7).withValues(alpha: .28),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'Happy Birthday\nAna!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFE8489B),
                        fontSize: (view.width * .057).clamp(21.0, 30.0),
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (inputReady)
                    Positioned(
                      right: -view.width * .08,
                      bottom: -view.height * .025,
                      child: const _FamilyTapCue(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _G2BirthdayMapStep extends StatefulWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2BirthdayMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_G2BirthdayMapStep> createState() => _G2BirthdayMapStepState();
}

class _G2BirthdayMapStepState extends State<_G2BirthdayMapStep>
    with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  late final AnimationController _zoomController;
  Animation<Matrix4>? _zoomAnimation;
  Size? _lastView;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _zoomController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          final animation = _zoomAnimation;
          if (animation != null) _controller.value = animation.value;
        });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _focusHouse(Size view) {
    if (_lastView == view) return;
    _lastView = view;
    final target = Matrix4.identity()
      ..setEntry(0, 0, 1.28)
      ..setEntry(1, 1, 1.28)
      ..setEntry(0, 3, -view.width * .16)
      ..setEntry(1, 3, -view.height * .08);
    _zoomAnimation = Matrix4Tween(begin: Matrix4.identity(), end: target)
        .animate(
          CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
        );
    _zoomController.forward(from: 0);
  }

  Future<void> _tapHouse() async {
    if (_selected) return;
    setState(() => _selected = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (mounted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusHouse(view);
    });
    final mapSize = Size(view.width * 1.48, view.height * 1.16);
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/tudlomap.svg',
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _controller,
            minScale: .95,
            maxScale: 2.2,
            boundaryMargin: EdgeInsets.all(view.longestSide),
            panEnabled: true,
            scaleEnabled: true,
            constrained: false,
            child: SizedBox(
              width: mapSize.width,
              height: mapSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _LessonBackgroundAsset(
                    asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
                  ),
                  Positioned(
                    left: mapSize.width * .53,
                    top: mapSize.height * .31,
                    width: mapSize.width * .22,
                    height: mapSize.width * .22,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tapHouse,
                      child: const _LessonOneMapDestinationCue(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: view.width * .10,
            right: view.width * .10,
            bottom: view.height * .08,
            child: const _LessonOneMessageCard(
              message: 'I-tap ang Balay ni Koka.',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2BirthdayBalloonsStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final Set<int> revealed;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(int number) onReveal;

  const _G2BirthdayBalloonsStep({
    required this.progress,
    required this.backgroundAsset,
    required this.revealed,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final balloons = [
      (number: 5, alignment: const Alignment(-.62, -.52)),
      (number: 6, alignment: const Alignment(.62, -.48)),
      (number: 7, alignment: const Alignment(-.42, .26)),
      (number: 8, alignment: const Alignment(.48, .24)),
    ];
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .14,
          view.width * .06,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'May mga balloon!',
              compact: true,
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -view.width * .05,
                    bottom: view.height * .005,
                    child: _LessonKokaMascot(
                      size: (view.width * .62).clamp(235.0, 330.0),
                      mood: KokaMood.hi,
                    ),
                  ),
                  for (final balloon in balloons)
                    Align(
                      alignment: balloon.alignment,
                      child: _BirthdayBalloonCard(
                        number: balloon.number,
                        revealed: revealed.contains(balloon.number),
                        enabled: inputReady,
                        onTap: () => onReveal(balloon.number),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: view.height * .02),
          ],
        ),
      ),
    );
  }
}

class _BirthdayBalloonCard extends StatelessWidget {
  final int number;
  final bool revealed;
  final bool enabled;
  final VoidCallback onTap;

  const _BirthdayBalloonCard({
    required this.number,
    required this.revealed,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final width = (view.width * .34).clamp(126.0, 180.0);
    final height = (view.height * .29).clamp(198.0, 260.0);
    return GestureDetector(
      onTap: enabled && !revealed ? onTap : null,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _LessonPictureAsset(
              asset:
                  'assets/images/level_game/lesson-game-assets/Tudlo_Birthday_Balloon_$number.svg',
              fit: BoxFit.contain,
              errorBuilder: (_) => Icon(
                Icons.circle_rounded,
                color: TudloColors.coral,
                size: width * .78,
              ),
            ),
            Positioned(
              top: height * .26,
              child: Container(
                width: width * .42,
                height: width * .42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: revealed ? .94 : .82),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  revealed ? '$number' : '?',
                  style: GoogleFonts.nunito(
                    color: TudloColors.blue,
                    fontSize: (width * .30).clamp(28.0, 42.0),
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G2BirthdayAskAgeStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final bool questionHeard;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function() onQuestion;
  final Future<void> Function() onTapAna;

  const _G2BirthdayAskAgeStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.questionHeard,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onQuestion,
    required this.onTapAna,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .20,
            right: view.width * .20,
            top: view.height * .14,
            child: GestureDetector(
              onTap: inputReady ? () => unawaited(onQuestion()) : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const _LessonOneMessageCard(
                    message: 'How old are you?',
                    compact: true,
                  ),
                  if (inputReady && !questionHeard)
                    Positioned(
                      right: -view.width * .10,
                      bottom: -view.height * .02,
                      child: const _FamilyTapCue(),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: view.width * .04,
            right: view.width * .04,
            bottom: view.height * .19,
            height: view.height * .54,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -view.width * .03,
                  bottom: 0,
                  child: _LessonKokaMascot(
                    size: (view.width * .62).clamp(235.0, 330.0),
                    mood: KokaMood.idle,
                  ),
                ),
                Positioned(
                  right: -view.width * .02,
                  bottom: 0,
                  width: view.width * .62,
                  height: view.height * .54,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: inputReady && questionHeard
                        ? () => unawaited(onTapAna())
                        : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _LessonPictureAsset(
                          asset: anaAsset,
                          fit: BoxFit.contain,
                        ),
                        if (inputReady && questionHeard)
                          Positioned(
                            right: view.width * .02,
                            top: view.height * .04,
                            child: const _FamilyTapCue(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            bottom: view.height * .05,
            child: _LessonOneMessageCard(
              message: questionHeard
                  ? 'I-tap si Ana kag pamatii.'
                  : 'I-tap ang question bubble kag pamatii.',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2BirthdaySevenStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2BirthdaySevenStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(
        children: [
          Positioned(
            right: -view.width * .02,
            top: view.height * .20,
            width: view.width * .72,
            height: view.height * .48,
            child: Image.asset(
              'assets/images/level_game/numbers/7.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: -view.width * .03,
            top: view.height * .30,
            width: view.width * .72,
            height: view.height * .43,
            child: _LessonPictureAsset(asset: anaAsset, fit: BoxFit.contain),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            bottom: view.height * .125,
            child: const _LessonOneMessageCard(
              message: 'Seven years old si Ana.',
            ),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            bottom: view.height * .035,
            child: _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2BirthdayChooseSevenStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2BirthdayChooseSevenStep({
    required this.progress,
    required this.backgroundAsset,
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
    final choices = const [
      _G2FriendChoice('age_5', '5'),
      _G2FriendChoice('age_6', '6'),
      _G2FriendChoice('age_7', '7'),
      _G2FriendChoice('age_8', '8'),
    ];
    const balloonCenters = [.125, .375, .625, .875];
    final balloonSlotWidth = (view.width * .31).clamp(118.0, 156.0);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .22,
            right: view.width * .22,
            top: view.height * .15,
            child: const _LessonOneMessageCard(
              message: 'Pilia ang numbero seven.',
              compact: true,
            ),
          ),
          Positioned(
            left: -view.width * .08,
            bottom: view.height * .045,
            child: _LessonKokaMascot(
              size: (view.width * .66).clamp(250.0, 350.0),
              mood: KokaMood.hi,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: view.height * .34,
            height: view.height * .34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final entry in choices.indexed)
                  Positioned(
                    left:
                        (view.width * balloonCenters[entry.$1]) -
                        (balloonSlotWidth / 2),
                    top: entry.$1.isEven ? view.height * .018 : 0,
                    bottom: 0,
                    width: balloonSlotWidth,
                    child: _BirthdayAgeChoiceBalloon(
                      choice: entry.$2,
                      selected: selectedId == entry.$2.id,
                      wrong: wrongId == entry.$2.id,
                      enabled: inputReady && selectedId == null,
                      onTap: () => onChoose(entry.$2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayAgeChoiceBalloon extends StatelessWidget {
  final _G2FriendChoice choice;
  final bool selected;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _BirthdayAgeChoiceBalloon({
    required this.choice,
    required this.selected,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final number = choice.label;
    final view = MediaQuery.sizeOf(context);
    final balloonWidth = (view.width * .31).clamp(118.0, 156.0);
    final balloonHeight = (view.height * .33).clamp(225.0, 300.0);
    final numberCardWidth = balloonWidth * .47;
    final numberCardHeight = balloonWidth * .53;
    return _FeedbackMotion(
      correct: selected && choice.id == 'age_7',
      wrong: wrong,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: selected ? 1.12 : 1,
          child: SizedBox(
            width: balloonWidth,
            height: balloonHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 2,
                  child: _LessonPictureAsset(
                    asset:
                        'assets/images/level_game/lesson-game-assets/Tudlo_Birthday_Balloon_$number.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: balloonHeight * .23,
                  child: Container(
                    width: numberCardWidth,
                    height: numberCardHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: TudloColors.blue,
                        fontSize: balloonWidth * .33,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _G2BirthdayBuildAnswerStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final List<String?> slots;
  final String? wrongTileId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String tileId, int slotIndex) onPlace;
  final Future<void> Function(String tileId) onTapTile;

  const _G2BirthdayBuildAnswerStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.slots,
    required this.wrongTileId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onPlace,
    required this.onTapTile,
  });

  static const _tiles = [
    _G2FriendChoice('seven_years_old', 'seven years old.'),
    _G2FriendChoice('i_am', 'I am'),
  ];

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .13,
          view.width * .055,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'I am seven years old.',
              compact: true,
            ),
            SizedBox(height: view.height * .015),
            SizedBox(
              height: view.height * .24,
              child: _LessonPictureAsset(asset: anaAsset, fit: BoxFit.contain),
            ),
            _G2AgeAnswerTray(slots: slots, onPlace: onPlace),
            const Spacer(),
            Row(
              children: [
                for (final tile in _tiles)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: _G2AgeResponseTile(
                        tile: tile,
                        hidden: slots.contains(tile.id),
                        wrong: wrongTileId == tile.id,
                        enabled: inputReady,
                        onTap: () => onTapTile(tile.id),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _G2AgeAnswerTray extends StatelessWidget {
  final List<String?> slots;
  final Future<void> Function(String tileId, int slotIndex) onPlace;

  const _G2AgeAnswerTray({required this.slots, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TudloColors.green, width: 3),
      ),
      child: Row(
        children: [
          for (var index = 0; index < slots.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => slots[index] == null,
                  onAcceptWithDetails: (details) {
                    unawaited(onPlace(details.data, index));
                  },
                  builder: (context, _, __) {
                    final label = _g2AgeAnswerTileLabel(slots[index]);
                    return Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: label == null
                            ? Colors.white.withValues(alpha: .55)
                            : const Color(0xFFE5FFD5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: label == null
                              ? const Color(0xFFB8B8B8)
                              : TudloColors.green,
                          width: 2.5,
                        ),
                      ),
                      child: Text(
                        label ?? '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.blue,
                          fontSize: 17,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _G2AgeResponseTile extends StatelessWidget {
  final _G2FriendChoice tile;
  final bool hidden;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _G2AgeResponseTile({
    required this.tile,
    required this.hidden,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = _FeedbackMotion(
      correct: false,
      wrong: wrong,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: hidden ? .24 : 1,
        child: GestureDetector(
          onTap: enabled && !hidden ? onTap : null,
          child: Container(
            height: 70,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: wrong ? TudloColors.coral : TudloColors.blue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: TudloColors.blue.withValues(alpha: .18),
                  blurRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              tile.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
    if (hidden || !enabled) return child;
    return Draggable<String>(
      data: tile.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 170, child: child),
      ),
      childWhenDragging: Opacity(opacity: .35, child: child),
      child: child,
    );
  }
}

class _G2BirthdayRewardStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _G2BirthdayRewardStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'ABYAN\n2'),
        message: 'Makasiling ka na sang imo edad!',
        onDone: onDone,
      ),
    );
  }
}

String? _g2AgeAnswerTileLabel(String? id) {
  return switch (id) {
    'i_am' => 'I am',
    'seven_years_old' => 'seven years old.',
    _ => null,
  };
}
