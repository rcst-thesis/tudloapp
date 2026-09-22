part of '../../level_game_page.dart';

enum _G2ParkDialogueStep {
  intro,
  map,
  findBench,
  question,
  chooseAnswer,
  model,
  arrange,
  reward,
}

class _GradeTwoUnitTwoLessonTwoParkDialogueFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoUnitTwoLessonTwoParkDialogueFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoUnitTwoLessonTwoParkDialogueFlow> createState() =>
      _GradeTwoUnitTwoLessonTwoParkDialogueFlowState();
}

class _GradeTwoUnitTwoLessonTwoParkDialogueFlowState
    extends State<_GradeTwoUnitTwoLessonTwoParkDialogueFlow> {
  static const _voiceBase = 'audio/VO-final/grade2';
  static const _backgroundAsset =
      'assets/images/level_game/grade2/backgrounds/Tudlo_G2_U2_L2.1_Park_Intro_Background.svg';
  static const _anaAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Full_Body_Character_Facing_Left.svg';
  static const _anaSmileAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Half_Body_Eyes_Closed_Smiling.svg';
  static const _benchAsset =
      'assets/images/level_game/grade2/lesson-game-assets/Tudlo_Park_Wooden_Bench_Exact.svg';
  static const _dialogueOrder = ['how_are_you', 'fine_thank_you'];

  _G2ParkDialogueStep _step = _G2ParkDialogueStep.intro;
  bool _voicePlaying = false;
  bool _benchFound = false;
  String? _selectedAnswerId;
  String? _wrongAnswerId;
  String? _wrongTileId;
  bool _completed = false;
  final List<String?> _dialogueSlots = List<String?>.filled(2, null);

  double get _progress =>
      (_G2ParkDialogueStep.values.indexOf(_step) + 1) /
      _G2ParkDialogueStep.values.length;

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

  void _goToStep(_G2ParkDialogueStep step) {
    if (_step == step) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _step = step;
      _selectedAnswerId = null;
      _wrongAnswerId = null;
      _wrongTileId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_2_Les_2_2_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_step) {
      _G2ParkDialogueStep.intro => const [2],
      _G2ParkDialogueStep.map => const [3],
      _G2ParkDialogueStep.findBench => const [4],
      _G2ParkDialogueStep.question => const [5, 6, 7, 8],
      _G2ParkDialogueStep.chooseAnswer => const [8],
      _G2ParkDialogueStep.model => const [10],
      _G2ParkDialogueStep.arrange => const [11, 12],
      _G2ParkDialogueStep.reward => const [20],
    };
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_step) {
          _G2ParkDialogueStep.intro =>
            'Nakita ko si Ana sa Park. Kumustahon ta siya.',
          _G2ParkDialogueStep.map => 'I-tap ang Park.',
          _G2ParkDialogueStep.findBench => 'Pangitaa si Ana sa bangko.',
          _G2ParkDialogueStep.question => 'How are you?',
          _G2ParkDialogueStep.chooseAnswer =>
            'Pilia ang husto nga sabat ni Ana.',
          _G2ParkDialogueStep.model => 'How are you? I am fine, thank you.',
          _G2ParkDialogueStep.arrange => 'Ihan-ay ang pamangkot kag sabat.',
          _G2ParkDialogueStep.reward =>
            'Nahimo mo ang bug-os nga greeting exchange!',
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
    if (_voicePlaying) return;
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) _goToStep(_G2ParkDialogueStep.findBench);
  }

  Future<void> _findBench() async {
    if (_voicePlaying || _benchFound) return;
    setState(() => _benchFound = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) _goToStep(_G2ParkDialogueStep.question);
  }

  Future<void> _chooseAnswer(_G2FriendChoice choice) async {
    if (_voicePlaying || _selectedAnswerId != null) return;
    final correct = choice.id == 'fine_thank_you';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _selectedAnswerId = choice.id;
      _wrongAnswerId = correct ? null : choice.id;
    });
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(const [16]);
      await Future<void>.delayed(const Duration(milliseconds: 460));
      if (!mounted) return;
      setState(() {
        _selectedAnswerId = null;
        _wrongAnswerId = null;
      });
      return;
    }
    widget.onQuizCorrect(0);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [13]);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) _goToStep(_G2ParkDialogueStep.model);
  }

  Future<void> _placeDialogueTile(String tileId, int slotIndex) async {
    if (_voicePlaying || _dialogueSlots.contains(tileId)) return;
    setState(() => _dialogueSlots[slotIndex] = tileId);
    await AppAudioService.instance.playTap();
    if (_dialogueSlots.any((slot) => slot == null)) return;
    final correct = List.generate(
      _dialogueOrder.length,
      (index) => _dialogueSlots[index] == _dialogueOrder[index],
    ).every((match) => match);
    widget.onQuizAttempt(1, correct);
    if (!correct) {
      final wrongIds = <String>{
        for (var index = 0; index < _dialogueOrder.length; index++)
          if (_dialogueSlots[index] != _dialogueOrder[index])
            _dialogueSlots[index]!,
      };
      setState(() => _wrongTileId = wrongIds.first);
      await AppAudioService.instance.playWrong();
      await _playVoice(const [16]);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        for (var index = 0; index < _dialogueSlots.length; index++) {
          if (_dialogueSlots[index] != _dialogueOrder[index]) {
            _dialogueSlots[index] = null;
          }
        }
        _wrongTileId = null;
      });
      return;
    }
    widget.onQuizCorrect(1);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [14, 18]);
    await Future<void>.delayed(_lessonCompletionHold);
    if (mounted) _goToStep(_G2ParkDialogueStep.reward);
  }

  Future<void> _tapDialogueTile(String tileId) async {
    final slotIndex = _dialogueSlots.indexWhere((slot) => slot == null);
    if (slotIndex == -1) return;
    await _placeDialogueTile(tileId, slotIndex);
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
        key: ValueKey('g2-u2-l2-$_step'),
        child: switch (_step) {
          _G2ParkDialogueStep.intro => _G2ParkDialogueIntroStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkDialogueStep.map),
          ),
          _G2ParkDialogueStep.map => _G2ParkDialogueMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: _tapPark,
          ),
          _G2ParkDialogueStep.findBench => _G2ParkFindAnaStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            benchAsset: _benchAsset,
            anaAsset: _anaAsset,
            benchFound: _benchFound,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onFind: _findBench,
          ),
          _G2ParkDialogueStep.question => _G2ParkQuestionStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            anaAsset: _anaAsset,
            selectedId: _selectedAnswerId,
            wrongId: _wrongAnswerId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseAnswer,
          ),
          _G2ParkDialogueStep.chooseAnswer => _G2ParkAnswerChoiceStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            anaAsset: _anaAsset,
            selectedId: _selectedAnswerId,
            wrongId: _wrongAnswerId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseAnswer,
          ),
          _G2ParkDialogueStep.model => _G2ParkDialogueModelStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            anaAsset: _anaSmileAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2ParkDialogueStep.arrange),
          ),
          _G2ParkDialogueStep.arrange => _G2ParkDialogueArrangeStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            slots: _dialogueSlots,
            wrongTileId: _wrongTileId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placeDialogueTile,
            onTapTile: _tapDialogueTile,
          ),
          _G2ParkDialogueStep.reward => _G2ParkDialogueRewardStep(
            progress: _progress,
            backgroundAsset: _backgroundAsset,
            anaAsset: _anaSmileAsset,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _G2ParkDialogueIntroStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkDialogueIntroStep({
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .04,
        ),
        child: Column(
          children: [
            const Spacer(),
            _LessonKokaMascot(
              size: (view.width * .46).clamp(165.0, 240.0),
              mood: KokaMood.idle,
            ),
            const Spacer(),
            const _LessonOneMessageCard(
              message: 'Nakita ko si Ana sa Park. Kumustahon ta siya.',
            ),
            SizedBox(height: view.height * .018),
            _LessonOneBlueButton(
              label: 'Sige',
              onTap: inputReady ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkDialogueMapStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkDialogueMapStep({
    required this.progress,
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
      backgroundAsset: 'assets/images/level_game/backgrounds/tudlomap.svg',
      child: Stack(
        children: [
          Positioned(
            left: view.width * .36,
            top: view.height * .36,
            width: view.width * .34,
            height: view.width * .34,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNext,
              child: const _LessonOneMapDestinationCue(),
            ),
          ),
          Positioned(
            left: view.width * .12,
            right: view.width * .12,
            top: view.height * .13,
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

class _G2ParkFindAnaStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String benchAsset;
  final String anaAsset;
  final bool benchFound;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onFind;

  const _G2ParkFindAnaStep({
    required this.progress,
    required this.backgroundAsset,
    required this.benchAsset,
    required this.anaAsset,
    required this.benchFound,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onFind,
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
            left: view.width * .08,
            right: view.width * .08,
            top: view.height * .14,
            child: const _LessonOneMessageCard(
              message: 'Pangitaa si Ana sa bangko.',
              compact: true,
            ),
          ),
          Positioned(
            right: view.width * .06,
            bottom: view.height * .37,
            width: view.width * .44,
            height: view.height * .18,
            child: _ParkBenchPicture(asset: benchAsset, mirrored: true),
          ),
          Positioned(
            left: view.width * .06,
            bottom: view.height * .37,
            width: view.width * .44,
            height: view.height * .18,
            child: GestureDetector(
              onTap: inputReady ? onFind : null,
              child: _FeedbackMotion(
                correct: benchFound,
                wrong: false,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (!benchFound)
                      Positioned.fill(
                        child: LessonAssetGlow(
                          asset: benchAsset,
                          fallbackIcon: Icons.weekend_rounded,
                          fallbackSize: view.width * .24,
                        ),
                      ),
                    _ParkBenchPicture(asset: benchAsset),
                    if (benchFound)
                      Positioned(
                        right: -view.width * .02,
                        bottom: view.height * .04,
                        width: view.width * .30,
                        height: view.height * .30,
                        child: _LessonPictureAsset(
                          asset: anaAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (!benchFound)
                      Positioned(
                        left: view.width * .10,
                        bottom: -view.height * .005,
                        child: const _FamilyTapCue(),
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

class _ParkBenchPicture extends StatelessWidget {
  final String asset;
  final bool mirrored;

  const _ParkBenchPicture({required this.asset, this.mirrored = false});

  @override
  Widget build(BuildContext context) {
    final bench = _LessonPictureAsset(asset: asset, fit: BoxFit.contain);
    if (!mirrored) return bench;
    return Transform.scale(scaleX: -1, child: bench);
  }
}

class _G2ParkQuestionStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2ParkQuestionStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
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
    const choices = [
      _G2FriendChoice('fine_thank_you', "I'm fine, thank you."),
      _G2FriendChoice('my_name_is_ana', 'My name is Ana.'),
      _G2FriendChoice('good_evening', 'Good evening.'),
    ];
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .125,
          view.width * .055,
          view.height * .035,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(message: 'How are you?', compact: true),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    left: -view.width * .02,
                    bottom: view.height * .01,
                    child: _LessonKokaMascot(
                      size: (view.width * .46).clamp(168.0, 228.0),
                      mood: KokaMood.idle,
                    ),
                  ),
                  Positioned(
                    right: view.width * .04,
                    bottom: 0,
                    width: view.width * .46,
                    height: view.height * .44,
                    child: _LessonPictureAsset(
                      asset: anaAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            for (final choice in choices) ...[
              _ParkGreetingCard(
                label: choice.label,
                correct:
                    selectedId == choice.id && choice.id == 'fine_thank_you',
                wrong: wrongId == choice.id,
                enabled: inputReady && selectedId == null,
                onTap: () => onChoose(choice),
              ),
              SizedBox(height: view.height * .012),
            ],
          ],
        ),
      ),
    );
  }
}

class _G2ParkAnswerChoiceStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2ParkAnswerChoiceStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
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
    const choices = [
      _G2FriendChoice('fine_thank_you', "I'm fine, thank you."),
      _G2FriendChoice('my_name_is_ana', 'My name is Ana.'),
      _G2FriendChoice('good_evening', 'Good evening.'),
    ];
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .12,
          view.width * .055,
          view.height * .035,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Ano ang husto nga sabat?',
              compact: true,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LessonKokaMascot(
                    size: (view.width * .34).clamp(120.0, 175.0),
                    mood: KokaMood.idle,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: view.width * .44,
                    height: view.height * .42,
                    child: _LessonPictureAsset(
                      asset: anaAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            for (final choice in choices) ...[
              _ParkGreetingCard(
                label: choice.label,
                correct:
                    selectedId == choice.id && choice.id == 'fine_thank_you',
                wrong: wrongId == choice.id,
                enabled: inputReady && selectedId == null,
                onTap: () => onChoose(choice),
              ),
              SizedBox(height: view.height * .012),
            ],
          ],
        ),
      ),
    );
  }
}

class _G2ParkDialogueModelStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2ParkDialogueModelStep({
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
    return _G2ParkScene(
      progress: progress,
      backgroundAsset: backgroundAsset,
      time: null,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .13,
          view.width * .055,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(message: 'How are you?', compact: true),
            SizedBox(height: view.height * .02),
            const _LessonOneMessageCard(
              message: "I'm fine, thank you.",
              compact: true,
            ),
            const Spacer(),
            SizedBox(
              width: view.width * .48,
              height: view.height * .42,
              child: _LessonPictureAsset(asset: anaAsset, fit: BoxFit.contain),
            ),
            const Spacer(),
            _LessonOneBlueButton(
              label: 'Ihan-ay',
              onTap: inputReady ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2ParkDialogueArrangeStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final List<String?> slots;
  final String? wrongTileId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String tileId, int slotIndex) onPlace;
  final Future<void> Function(String tileId) onTapTile;

  const _G2ParkDialogueArrangeStep({
    required this.progress,
    required this.backgroundAsset,
    required this.slots,
    required this.wrongTileId,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onPlace,
    required this.onTapTile,
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          view.height * .12,
          view.width * .055,
          view.height * .035,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Ihan-ay ang pamangkot kag sabat.',
              compact: true,
            ),
            SizedBox(height: view.height * .03),
            _G2ParkDialogueTray(slots: slots, onPlace: onPlace),
            const Spacer(),
            Row(
              children: [
                for (final tile in const [
                  _G2FriendChoice('fine_thank_you', "I'm fine, thank you."),
                  _G2FriendChoice('how_are_you', 'How are you?'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: _G2ParkDialogueTile(
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

class _G2ParkDialogueRewardStep extends StatelessWidget {
  final double progress;
  final String backgroundAsset;
  final String anaAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _G2ParkDialogueRewardStep({
    required this.progress,
    required this.backgroundAsset,
    required this.anaAsset,
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
        fallback: const _FamilyReferenceBadge(label: 'PANAMYAW\n2'),
        message: 'Nahimo mo ang bug-os nga greeting exchange!',
        onDone: onDone,
      ),
    );
  }
}

class _G2ParkDialogueTray extends StatelessWidget {
  final List<String?> slots;
  final Future<void> Function(String tileId, int slotIndex) onPlace;

  const _G2ParkDialogueTray({required this.slots, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TudloColors.green, width: 3),
      ),
      child: Column(
        children: [
          for (var index = 0; index < slots.length; index++) ...[
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: TudloColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (_) => slots[index] == null,
                    onAcceptWithDetails: (details) {
                      unawaited(onPlace(details.data, index));
                    },
                    builder: (context, _, __) {
                      final label = _g2ParkDialogueTileLabel(slots[index]);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: (width * .16).clamp(58.0, 74.0),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: label == null
                              ? Colors.white.withValues(alpha: .60)
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
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (index != slots.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _G2ParkDialogueTile extends StatelessWidget {
  final _G2FriendChoice tile;
  final bool hidden;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _G2ParkDialogueTile({
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
            height: 76,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                fontSize: 18,
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

String? _g2ParkDialogueTileLabel(String? id) {
  return switch (id) {
    'how_are_you' => 'How are you?',
    'fine_thank_you' => "I'm fine, thank you.",
    _ => null,
  };
}
