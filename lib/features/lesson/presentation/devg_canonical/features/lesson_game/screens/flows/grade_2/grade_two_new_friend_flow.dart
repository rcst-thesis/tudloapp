part of '../../level_game_page.dart';

const String _g2ClassroomWithoutAnaBackground =
    'assets/images/level_game/grade2/backgrounds/Tudlo_Classroom_Background_Without_Ana.svg';
const String _g2BirthdayWithoutAnaBackground =
    'assets/images/level_game/grade2/backgrounds/Tudlo_Birthday_Background_Without_Ana.svg';

enum _G2NewFriendStep {
  intro,
  map,
  meetAna,
  hello,
  askName,
  anaAnswers,
  buildResponse,
  reward,
}

class _GradeTwoUnitOneLessonOneNewFriendFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoUnitOneLessonOneNewFriendFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoUnitOneLessonOneNewFriendFlow> createState() =>
      _GradeTwoUnitOneLessonOneNewFriendFlowState();
}

class _GradeTwoUnitOneLessonOneNewFriendFlowState
    extends State<_GradeTwoUnitOneLessonOneNewFriendFlow> {
  static const _voiceBase = 'audio/VO-final/grade2';
  static const _anaAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Full_Body_Character_Facing_Left.svg';
  static const _anaSmilingAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Correct_Response_Smiling_Facing_Left.svg';
  static const _anaAnswerAsset =
      'assets/images/level_game/grade2/people/Tudlo_Ana_Half_Body_Eyes_Closed_Smiling.svg';
  static const _responseOrder = ['my_name_is', 'ana'];

  _G2NewFriendStep _step = _G2NewFriendStep.intro;
  bool _voicePlaying = false;
  bool _anaFound = false;
  bool _helloDone = false;
  bool _questionDone = false;
  bool _responseHeard = false;
  bool _completed = false;
  String? _selectedChoiceId;
  String? _wrongChoiceId;
  String? _wrongTileId;
  final List<String?> _responseSlots = List<String?>.filled(2, null);

  double get _progress =>
      (_G2NewFriendStep.values.indexOf(_step) + 1) /
      _G2NewFriendStep.values.length;

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

  void _goToStep(_G2NewFriendStep step) {
    if (_step == step) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _step = step;
      _selectedChoiceId = null;
      _wrongChoiceId = null;
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
      for (final clip in clips) '$_voiceBase/Gr_2_Les_1_1_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_step) {
      _G2NewFriendStep.intro => const [2],
      _G2NewFriendStep.map => const [3],
      _G2NewFriendStep.meetAna => const [4],
      _G2NewFriendStep.hello => const [5, 6, 7],
      _G2NewFriendStep.askName => const [11, 12],
      _G2NewFriendStep.anaAnswers => const [14],
      _G2NewFriendStep.buildResponse => const [16],
      _G2NewFriendStep.reward => const [20],
    };
    setState(() => _voicePlaying = true);
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_step) {
          _G2NewFriendStep.intro => 'May bag-o kita nga abyan.',
          _G2NewFriendStep.map => 'I-tap ang School.',
          _G2NewFriendStep.meetAna => 'I-tap si Ana.',
          _G2NewFriendStep.hello => 'Pilia ang Hello.',
          _G2NewFriendStep.askName => 'Pilia ang pamangkot sang ngalan.',
          _G2NewFriendStep.anaAnswers => 'Hello! My name is Ana.',
          _G2NewFriendStep.buildResponse => 'Ihan-ay ang My name is kag Ana.',
          _G2NewFriendStep.reward =>
            'Nakapakilala na kita sang bag-o nga abyan!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted) setState(() => _voicePlaying = false);
    }
  }

  Future<void> _tapAna() async {
    if (_voicePlaying || _anaFound) return;
    setState(() => _anaFound = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) _goToStep(_G2NewFriendStep.hello);
  }

  Future<void> _chooseHello(_G2FriendChoice choice) async {
    if (_voicePlaying || _helloDone || _selectedChoiceId != null) return;
    final correct = choice.id == 'hello';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _selectedChoiceId = choice.id;
      _wrongChoiceId = correct ? null : choice.id;
    });
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(const [10]);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _selectedChoiceId = null;
        _wrongChoiceId = null;
      });
      return;
    }
    _helloDone = true;
    widget.onQuizCorrect(0);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [9, 8]);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) _goToStep(_G2NewFriendStep.askName);
  }

  Future<void> _chooseQuestion(_G2FriendChoice choice) async {
    if (_voicePlaying || _questionDone || _selectedChoiceId != null) return;
    final correct = choice.id == 'what_name';
    widget.onQuizAttempt(1, correct);
    setState(() {
      _selectedChoiceId = choice.id;
      _wrongChoiceId = correct ? null : choice.id;
    });
    if (!correct) {
      await AppAudioService.instance.playWrong();
      await _playVoice(const [15]);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _selectedChoiceId = null;
        _wrongChoiceId = null;
      });
      return;
    }
    _questionDone = true;
    widget.onQuizCorrect(1);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [13]);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (mounted) _goToStep(_G2NewFriendStep.anaAnswers);
  }

  Future<void> _continueAfterAna() async {
    if (_voicePlaying) return;
    _responseHeard = true;
    await AppAudioService.instance.playCorrect();
    if (mounted) _goToStep(_G2NewFriendStep.buildResponse);
  }

  Future<void> _placeResponseTile(String tileId, int slotIndex) async {
    if (_voicePlaying || _responseSlots.contains(tileId)) return;
    setState(() => _responseSlots[slotIndex] = tileId);
    await AppAudioService.instance.playTap();
    if (_responseSlots.any((slot) => slot == null)) return;
    final correct = List.generate(
      _responseOrder.length,
      (index) => _responseSlots[index] == _responseOrder[index],
    ).every((match) => match);
    widget.onQuizAttempt(2, correct);
    if (!correct) {
      final wrongIds = <String>{
        for (var index = 0; index < _responseOrder.length; index++)
          if (_responseSlots[index] != _responseOrder[index])
            _responseSlots[index]!,
      };
      setState(() => _wrongTileId = wrongIds.first);
      await AppAudioService.instance.playWrong();
      await _playVoice(const [19]);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        for (var index = 0; index < _responseSlots.length; index++) {
          if (_responseSlots[index] != _responseOrder[index]) {
            _responseSlots[index] = null;
          }
        }
        _wrongTileId = null;
      });
      return;
    }
    widget.onQuizCorrect(2);
    await AppAudioService.instance.playCorrect();
    await _playVoice(const [18, 17]);
    await Future<void>.delayed(_lessonCompletionHold);
    if (mounted) _goToStep(_G2NewFriendStep.reward);
  }

  Future<void> _tapTile(String tileId) async {
    final slotIndex = _responseSlots.indexWhere((slot) => slot == null);
    if (slotIndex == -1) return;
    await _placeResponseTile(tileId, slotIndex);
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
        key: ValueKey('g2-u1-l1-$_step'),
        child: switch (_step) {
          _G2NewFriendStep.intro => _G2NewFriendIntroStep(
            progress: _progress,
            anaAsset: _anaAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2NewFriendStep.map),
          ),
          _G2NewFriendStep.map => _G2NewFriendMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(_G2NewFriendStep.meetAna),
          ),
          _G2NewFriendStep.meetAna => _G2MeetAnaStep(
            progress: _progress,
            anaAsset: _anaAsset,
            anaFound: _anaFound,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTapAna: _tapAna,
          ),
          _G2NewFriendStep.hello => _G2FriendChoiceStep(
            progress: _progress,
            anaAsset: _selectedChoiceId == 'hello'
                ? _anaSmilingAsset
                : _anaAsset,
            prompt: 'Hello!',
            showPrompt: _selectedChoiceId == 'hello',
            choices: const [
              _G2FriendChoice('hello', 'Hello!'),
              _G2FriendChoice('goodbye', 'Goodbye!'),
              _G2FriendChoice('how_are_you', 'How are you?'),
            ],
            correctId: 'hello',
            selectedId: _selectedChoiceId,
            wrongId: _wrongChoiceId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseHello,
          ),
          _G2NewFriendStep.askName => _G2FriendChoiceStep(
            progress: _progress,
            anaAsset: _anaAsset,
            prompt: 'What is your name?',
            showPrompt: _selectedChoiceId == 'what_name',
            choices: const [
              _G2FriendChoice('what_name', 'What is your name?'),
              _G2FriendChoice('how_old', 'How old are you?'),
              _G2FriendChoice('goodbye', 'Goodbye!'),
            ],
            correctId: 'what_name',
            selectedId: _selectedChoiceId,
            wrongId: _wrongChoiceId,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseQuestion,
          ),
          _G2NewFriendStep.anaAnswers => _G2AnaAnswerStep(
            progress: _progress,
            anaAsset: _anaAnswerAsset,
            inputReady: !_voicePlaying,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: _continueAfterAna,
          ),
          _G2NewFriendStep.buildResponse => _G2BuildResponseStep(
            progress: _progress,
            anaAsset: _anaAnswerAsset,
            slots: _responseSlots,
            wrongTileId: _wrongTileId,
            inputReady: !_voicePlaying && _responseHeard,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placeResponseTile,
            onTapTile: _tapTile,
          ),
          _G2NewFriendStep.reward => _G2NewFriendRewardStep(
            progress: _progress,
            anaAsset: _anaAsset,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _G2FriendChoice {
  final String id;
  final String label;

  const _G2FriendChoice(this.id, this.label);
}

class _G2NewFriendIntroStep extends StatelessWidget {
  final double progress;
  final String anaAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2NewFriendIntroStep({
    required this.progress,
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
      backgroundAsset: _g2ClassroomWithoutAnaBackground,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .16,
            right: view.width * .16,
            bottom: view.height * .125,
            height: view.height * .66,
            child: _LessonPictureAsset(
              asset: anaAsset,
              fit: BoxFit.contain,
              errorBuilder: (_) => Icon(
                Icons.face_3_rounded,
                color: TudloColors.blue,
                size: view.width * .36,
              ),
            ),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .17,
            child: const _LessonOneMessageCard(
              message: 'May bag-o kita nga abyan.',
            ),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .045,
            child: _LessonOneBlueButton(
              label: 'Sige',
              onTap: inputReady ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2NewFriendMapStep extends StatefulWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _G2NewFriendMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_G2NewFriendMapStep> createState() => _G2NewFriendMapStepState();
}

class _G2NewFriendMapStepState extends State<_G2NewFriendMapStep>
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

  void _focusSchool(Size view) {
    if (_lastView == view) return;
    _lastView = view;
    final target = Matrix4.identity()
      ..setEntry(0, 0, 1.38)
      ..setEntry(1, 1, 1.38)
      ..setEntry(0, 3, -view.width * .24)
      ..setEntry(1, 3, -view.height * .11);
    _zoomAnimation = Matrix4Tween(begin: Matrix4.identity(), end: target)
        .animate(
          CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
        );
    _zoomController.forward(from: 0);
  }

  Future<void> _tapSchool() async {
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
      if (mounted) _focusSchool(view);
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
                    left: mapSize.width * .38,
                    top: mapSize.height * .30,
                    width: mapSize.width * .21,
                    height: mapSize.width * .21,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tapSchool,
                      child: const _LessonOneMapDestinationCue(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: view.width * .12,
            right: view.width * .12,
            top: MediaQuery.paddingOf(context).top + view.height * .10,
            child: const _LessonOneMessageCard(
              message: 'I-tap ang School.',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _G2MeetAnaStep extends StatelessWidget {
  final double progress;
  final String anaAsset;
  final bool anaFound;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onTapAna;

  const _G2MeetAnaStep({
    required this.progress,
    required this.anaAsset,
    required this.anaFound,
    required this.inputReady,
    required this.onExit,
    required this.onReplay,
    required this.onTapAna,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: _g2ClassroomWithoutAnaBackground,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: anaFound ? .0 : .25),
            ),
          ),
          Positioned(
            left: view.width * .12,
            right: view.width * .12,
            top: MediaQuery.paddingOf(context).top + view.height * .10,
            child: const _LessonOneMessageCard(
              message: 'I-tap si Ana.',
              compact: true,
            ),
          ),
          Positioned(
            left: view.width * .12,
            right: view.width * .12,
            bottom: view.height * .12,
            height: view.height * .62,
            child: GestureDetector(
              onTap: inputReady ? onTapAna : null,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (!anaFound)
                    SizedBox(
                      width: view.width * .52,
                      height: view.height * .42,
                      child: LessonAssetGlow(
                        asset: anaAsset,
                        fallbackIcon: Icons.face_3_rounded,
                        fallbackSize: view.width * .28,
                      ),
                    ),
                  _LessonPictureAsset(
                    asset: anaAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_) => Icon(
                      Icons.face_3_rounded,
                      color: TudloColors.blue,
                      size: view.width * .28,
                    ),
                  ),
                  if (!anaFound)
                    Positioned(
                      right: view.width * .03,
                      bottom: view.height * .09,
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

class _G2FriendChoiceStep extends StatelessWidget {
  final double progress;
  final String anaAsset;
  final String prompt;
  final bool showPrompt;
  final List<_G2FriendChoice> choices;
  final String correctId;
  final String? selectedId;
  final String? wrongId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_G2FriendChoice choice) onChoose;

  const _G2FriendChoiceStep({
    required this.progress,
    required this.anaAsset,
    required this.prompt,
    this.showPrompt = true,
    required this.choices,
    required this.correctId,
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
    final top = MediaQuery.paddingOf(context).top;
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: _g2ClassroomWithoutAnaBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          top + view.height * .11,
          view.width * .055,
          view.height * .04,
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: showPrompt
                  ? _LessonOneMessageCard(message: prompt, compact: true)
                  : SizedBox(
                      key: const ValueKey('g2-choice-prompt-hidden'),
                      height: (view.width * .05).clamp(12.0, 24.0),
                    ),
            ),
            SizedBox(height: view.height * .012),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: -view.width * .18,
                    bottom: -view.height * .03,
                    child: _LessonKokaMascot(
                      size: (view.width * .82).clamp(320.0, 470.0),
                      mood: KokaMood.idle,
                    ),
                  ),
                  Positioned(
                    right: -view.width * .10,
                    bottom: -view.height * .02,
                    width: view.width * .70,
                    height: view.height * .60,
                    child: _LessonPictureAsset(
                      asset: anaAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_) => Icon(
                        Icons.face_3_rounded,
                        color: TudloColors.blue,
                        size: view.width * .24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final choice in choices)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _G2FriendChoiceCard(
                        choice: choice,
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
          ],
        ),
      ),
    );
  }
}

class _G2FriendChoiceCard extends StatelessWidget {
  final _G2FriendChoice choice;
  final bool correct;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _G2FriendChoiceCard({
    required this.choice,
    required this.correct,
    required this.wrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final label = _g2FriendChoiceDisplayLabel(choice.label);
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: (width * .39).clamp(142.0, 188.0),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: correct ? const Color(0xFFE5FFD5) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: correct
                  ? TudloColors.green
                  : wrong
                  ? TudloColors.coral
                  : const Color(0xFFD8E8F6),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  style: GoogleFonts.nunito(
                    color: TudloColors.blue,
                    fontSize: 24,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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

String _g2FriendChoiceDisplayLabel(String label) {
  return switch (label) {
    'How are you?' => 'How\nare\nyou?',
    'What is your name?' => 'What is\nyour name?',
    'How old are you?' => 'How old\nare you?',
    _ => label,
  };
}

class _G2AnaAnswerStep extends StatelessWidget {
  final double progress;
  final String anaAsset;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function() onNext;

  const _G2AnaAnswerStep({
    required this.progress,
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
      backgroundAsset: _g2ClassroomWithoutAnaBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .07,
          view.height * .14,
          view.width * .07,
          view.height * .045,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Hello! My name is Ana.',
              compact: true,
            ),
            const Spacer(),
            SizedBox(
              height: view.height * .52,
              child: _LessonPictureAsset(
                asset: anaAsset,
                fit: BoxFit.contain,
                errorBuilder: (_) => Icon(
                  Icons.face_3_rounded,
                  color: TudloColors.blue,
                  size: view.width * .30,
                ),
              ),
            ),
            const Spacer(),
            _LessonOneBlueButton(
              label: 'Padayon',
              onTap: inputReady ? () => unawaited(onNext()) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _G2BuildResponseStep extends StatelessWidget {
  final double progress;
  final String anaAsset;
  final List<String?> slots;
  final String? wrongTileId;
  final bool inputReady;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String tileId, int slotIndex) onPlace;
  final Future<void> Function(String tileId) onTapTile;

  const _G2BuildResponseStep({
    required this.progress,
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
    _G2FriendChoice('my_name_is', 'My name is'),
    _G2FriendChoice('ana', 'Ana'),
  ];

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final sentenceCorrect =
        slots.length == _tiles.length &&
        slots[0] == _tiles[0].id &&
        slots[1] == _tiles[1].id;
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: _g2ClassroomWithoutAnaBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          top + view.height * .11,
          view.width * .055,
          view.height * .04,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Kompletuhon ta!',
              compact: true,
            ),
            const Spacer(),
            SizedBox(
              height: view.height * .30,
              child: _LessonPictureAsset(
                asset: anaAsset,
                fit: BoxFit.contain,
                errorBuilder: (_) => Icon(
                  Icons.face_3_rounded,
                  color: TudloColors.blue,
                  size: view.width * .30,
                ),
              ),
            ),
            SizedBox(height: view.height * .02),
            Align(
              alignment: Alignment.center,
              child: _G2ResponseTray(
                slots: slots,
                complete: sentenceCorrect,
                onPlace: onPlace,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                for (final tile in _tiles)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: _G2ResponseTile(
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

class _G2ResponseTray extends StatelessWidget {
  final List<String?> slots;
  final bool complete;
  final Future<void> Function(String tileId, int slotIndex) onPlace;

  const _G2ResponseTray({
    required this.slots,
    required this.complete,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: math.min(width * .86, 410.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: complete ? TudloColors.green : const Color(0xFFC9D2D7),
            width: 3,
          ),
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
                      final label = _g2ResponseTileLabel(slots[index]);
                      return Container(
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: complete
                              ? const Color(0xFFE5FFD5)
                              : Colors.white.withValues(alpha: .64),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: complete
                                ? TudloColors.green
                                : const Color(0xFFB8B8B8),
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
              ),
          ],
        ),
      ),
    );
  }
}

class _G2ResponseTile extends StatelessWidget {
  final _G2FriendChoice tile;
  final bool hidden;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  const _G2ResponseTile({
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
        child: SizedBox(width: 150, child: child),
      ),
      childWhenDragging: Opacity(opacity: .35, child: child),
      child: child,
    );
  }
}

class _G2NewFriendRewardStep extends StatelessWidget {
  final double progress;
  final String anaAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _G2NewFriendRewardStep({
    required this.progress,
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
      backgroundAsset: _g2ClassroomWithoutAnaBackground,
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'ABYAN\n1'),
        message: 'Nakilala mo ang bag-o nga abyan!',
        onDone: onDone,
      ),
    );
  }
}

String? _g2ResponseTileLabel(String? id) {
  return switch (id) {
    'my_name_is' => 'My name is',
    'ana' => 'Ana',
    _ => null,
  };
}

class _GradeTwoTalkBuildSolveLesson extends StatefulWidget {
  final LevelContent content;
  final VoidCallback onExit;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoTalkBuildSolveLesson({
    required this.content,
    required this.onExit,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoTalkBuildSolveLesson> createState() =>
      _GradeTwoTalkBuildSolveLessonState();
}

class _GradeTwoTalkBuildSolveLessonState
    extends State<_GradeTwoTalkBuildSolveLesson> {
  late final _GradeTwoPlan _plan = _gradeTwoPlanFor(widget.content);
  int _step = 0;
  int _reported = 0;
  bool _finished = false;

  double get _progress => (_step + 1) / 3;

  void _advance() {
    _reportOne();
    if (!mounted) return;
    if (_step >= 2) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _reportOne() {
    if (_reported >= _lessonQuizCount) return;
    widget.onQuizCorrect(_reported);
    _reported++;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    while (_reported < _lessonQuizCount) {
      widget.onQuizCorrect(_reported);
      _reported++;
    }
  }

  void _replayCurrentStep() {
    final message = switch (_step) {
      0 => _plan.tapInstruction,
      1 => _plan.buildPrompt,
      _ => _plan.choicePrompt,
    };
    unawaited(TudloVoiceButton.speak(context, message, hiligaynon: true));
  }

  String get _backgroundAsset {
    if (widget.content.unitNumber == 1 && widget.content.lessonNumber == 2) {
      return _g2BirthdayWithoutAnaBackground;
    }
    if (widget.content.unitNumber == 2) {
      return 'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Intro_Background.svg';
    }
    return _g2ClassroomWithoutAnaBackground;
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      widget.content.unitNumber == 1 && widget.content.lessonNumber == 2
          ? _GradeTwoBirthdayCandleCard(plan: _plan, onDone: _advance)
          : _GradeTwoSceneCard(plan: _plan, onDone: _advance),
      _GradeTwoSentenceBuilderCard(plan: _plan, onDone: _advance),
      _GradeTwoDialogueChoiceCard(plan: _plan, onDone: _advance),
    ];

    return _LessonOneChrome(
      progress: _progress,
      onExit: widget.onExit,
      onReplay: _replayCurrentStep,
      backgroundAsset: _backgroundAsset,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_step), child: cards[_step]),
      ),
    );
  }
}

class _GradeTwoPlan {
  final String sceneTitle;
  final String sceneLine;
  final String tapInstruction;
  final String phrase;
  final String phraseSpeech;
  final String buildPrompt;
  final String buildQuestion;
  final String? buildCharacterAsset;
  final String buildAnswer;
  final List<String> buildTiles;
  final String choicePrompt;
  final List<String> choices;
  final String answer;
  final String missionTitle;
  final String missionPrompt;
  final List<_GradeTwoMissionChoice> missionChoices;
  final String missionAnswer;
  final String reward;
  final String? imageAsset;
  final IconData icon;
  final Color color;

  const _GradeTwoPlan({
    required this.sceneTitle,
    required this.sceneLine,
    required this.tapInstruction,
    required this.phrase,
    required this.phraseSpeech,
    required this.buildPrompt,
    required this.buildQuestion,
    this.buildCharacterAsset,
    required this.buildAnswer,
    required this.buildTiles,
    required this.choicePrompt,
    required this.choices,
    required this.answer,
    required this.missionTitle,
    required this.missionPrompt,
    required this.missionChoices,
    required this.missionAnswer,
    required this.reward,
    this.imageAsset,
    required this.icon,
    required this.color,
  });
}

class _GradeTwoMissionChoice {
  final String label;
  final String? visualLabel;
  final String? imageAsset;
  final bool isKoka;
  final IconData icon;

  const _GradeTwoMissionChoice({
    required this.label,
    this.visualLabel,
    this.imageAsset,
    this.isKoka = false,
    required this.icon,
  });
}

class _GradeTwoTileVisual {
  final String label;
  final String? imageAsset;
  final bool isKoka;
  final IconData icon;
  final Color color;

  const _GradeTwoTileVisual({
    required this.label,
    this.imageAsset,
    this.isKoka = false,
    required this.icon,
    required this.color,
  });
}

class _GradeTwoSceneCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoSceneCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoSceneCard> createState() => _GradeTwoSceneCardState();
}

class _GradeTwoSceneCardState extends State<_GradeTwoSceneCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.plan.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapScene() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(context, widget.plan.phraseSpeech);
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GradeTwoStage(
      mascotMessage: _tapped
          ? 'Koka: ${widget.plan.phrase}'
          : 'Koka: ${widget.plan.tapInstruction}',
      child: Column(
        children: [
          Text(
            widget.plan.sceneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tapScene,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _GradeTwoArt(plan: widget.plan, size: 270),
                  if (_tapped) const _AnimalSparkles(size: 300),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _GradeTwoSpeechBubble(text: widget.plan.phrase, onTap: _tapScene),
        ],
      ),
    );
  }
}

class _GradeTwoBirthdayCandleCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoBirthdayCandleCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoBirthdayCandleCard> createState() =>
      _GradeTwoBirthdayCandleCardState();
}

class _GradeTwoBirthdayCandleCardState
    extends State<_GradeTwoBirthdayCandleCard> {
  int _candles = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang pito ka kandila pakadto sa cake.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _addCandle() async {
    if (_done) return;
    setState(() => _candles = (_candles + 1).clamp(0, 7));
    if (_candles < 7) return;
    _done = true;
    await TudloVoiceButton.speak(
      context,
      'Husto! Pito ka kandila.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GradeTwoStage(
      mascotMessage: 'Koka: Guyoda ang pito ka kandila pakadto sa cake.',
      child: Column(
        children: [
          Text(
            widget.plan.sceneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const _GradeTwoSpeechBubble(text: 'Pito ka kandila'),
          const SizedBox(height: 12),
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !_done,
            onAcceptWithDetails: (_) => _addCandle(),
            builder: (context, candidates, rejected) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: candidates.isNotEmpty ? 1.04 : 1,
                child: SizedBox(
                  width: 320,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/level_game/cake.png',
                        width: 280,
                        height: 220,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      Positioned(
                        top: 26,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            for (var index = 0; index < _candles; index++)
                              Image.asset(
                                'assets/images/level_game/candle.png',
                                width: 28,
                                height: 54,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: TudloColors.coral,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            '$_candles / 7',
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          if (!_done)
            Draggable<String>(
              data: 'candle',
              feedback: Material(
                color: Colors.transparent,
                child: Image.asset(
                  'assets/images/level_game/candle.png',
                  width: 52,
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: .35,
                child: _CandleButton(color: widget.plan.color),
              ),
              child: _CandleButton(color: widget.plan.color),
            ),
        ],
      ),
    );
  }
}

class _CandleButton extends StatelessWidget {
  final Color color;

  const _CandleButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/level_game/candle.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.local_fire_department_rounded, color: color, size: 52),
      ),
    );
  }
}

class _GradeTwoSentenceBuilderCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoSentenceBuilderCard({
    required this.plan,
    required this.onDone,
  });

  @override
  State<_GradeTwoSentenceBuilderCard> createState() =>
      _GradeTwoSentenceBuilderCardState();
}

class _GradeTwoSentenceBuilderCardState
    extends State<_GradeTwoSentenceBuilderCard> {
  final List<String> _built = [];
  bool _done = false;

  Future<void> _addTile(String tile) async {
    if (_done || _built.contains(tile)) return;
    await TudloVoiceButton.speak(
      context,
      _gradeTwoTileVisualFor(tile).label,
      hiligaynon: true,
    );
    if (!mounted) return;
    setState(() => _built.add(tile));
    if (_normalizedSentence(_built.join(' ')) ==
        _normalizedSentence(widget.plan.buildAnswer)) {
      _done = true;
      await TudloVoiceButton.speak(
        context,
        widget.plan.phraseSpeech,
        hiligaynon: true,
      );
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.plan.buildTiles
        .where((tile) => !_built.contains(tile))
        .toList();
    final focus = _gradeTwoBuildFocusFor(widget.plan);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              Text(
                widget.plan.buildPrompt,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              _GradeTwoQuestionCharacter(
                question: widget.plan.buildQuestion,
                imageAsset: widget.plan.buildCharacterAsset,
                color: widget.plan.color,
              ),
              if (focus != null) ...[
                const SizedBox(height: 10),
                _GradeTwoFocusPicture(visual: focus, color: widget.plan.color),
              ],
              const SizedBox(height: 16),
              _GradeTwoBuildTray(
                words: _built,
                target: widget.plan.buildAnswer,
                color: widget.plan.color,
                onRemove: (index) {
                  if (_done) return;
                  setState(() => _built.removeAt(index));
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in remaining)
                    _GradeTwoTile(
                      label: tile,
                      color: widget.plan.color,
                      onTap: () => _addTile(tile),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoDialogueChoiceCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoDialogueChoiceCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoDialogueChoiceCard> createState() =>
      _GradeTwoDialogueChoiceCardState();
}

class _GradeTwoDialogueChoiceCardState
    extends State<_GradeTwoDialogueChoiceCard> {
  String? _selected;
  int _attempt = 0;

  Future<void> _choose(String choice) async {
    if (_selected == widget.plan.answer) return;
    await TudloVoiceButton.speak(context, choice, hiligaynon: true);
    if (!mounted) return;
    final correct = choice == widget.plan.answer;
    setState(() {
      _selected = choice;
      _attempt++;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pili-a ang husto nga sabat.',
        hiligaynon: true,
      );
      return;
    }
    unawaited(AppAudioService.instance.playCorrect());
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              _GradeTwoSpeechBubble(text: widget.plan.choicePrompt),
              const SizedBox(height: 18),
              _GradeTwoAnswerBubble(text: _selected ?? ''),
              const SizedBox(height: 8),
              const _LessonKokaMascot(size: 190),
              const SizedBox(height: 16),
              for (final choice in widget.plan.choices) ...[
                _GradeTwoChoiceButton(
                  key: ValueKey('$choice-$_attempt'),
                  label: choice,
                  selected: _selected == choice,
                  correct: choice == widget.plan.answer,
                  checked: _selected == choice,
                  color: widget.plan.color,
                  onTap: () => _choose(choice),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoMissionCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoMissionCard> createState() => _GradeTwoMissionCardState();
}

class _GradeTwoMissionCardState extends State<_GradeTwoMissionCard> {
  String? _selected;
  int _attempt = 0;

  Future<void> _choose(_GradeTwoMissionChoice choice) async {
    if (_selected == widget.plan.missionAnswer) return;
    await TudloVoiceButton.speak(context, choice.label);
    if (!mounted) return;
    final correct = choice.label == widget.plan.missionAnswer;
    setState(() {
      _selected = choice.label;
      _attempt++;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Liwata. Tan-awa liwat ang sitwasyon.',
        hiligaynon: true,
      );
      return;
    }
    unawaited(AppAudioService.instance.playCorrect());
    await TudloVoiceButton.speak(
      context,
      'Husto! ${widget.plan.reward}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              const _LessonKokaMascot(size: 148),
              const SizedBox(height: 12),
              _GradeTwoSpeechBubble(text: widget.plan.missionPrompt),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final choice in widget.plan.missionChoices)
                    _GradeTwoMissionOption(
                      key: ValueKey('${choice.label}-$_attempt'),
                      choice: choice,
                      color: widget.plan.color,
                      selected: _selected == choice.label,
                      correct: choice.label == widget.plan.missionAnswer,
                      checked: _selected == choice.label,
                      onTap: () => _choose(choice),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _GradeTwoStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 260),
                    child: child,
                  ),
                ),
                Positioned(
                  right: -22,
                  bottom: -18,
                  child: IgnorePointer(
                    child: _AlphabetMascotBubble(message: mascotMessage),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GradeTwoArt extends StatelessWidget {
  final _GradeTwoPlan plan;
  final double size;

  const _GradeTwoArt({required this.plan, required this.size});

  @override
  Widget build(BuildContext context) {
    if (plan.imageAsset != null) {
      return Image.asset(
        plan.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _GradeTwoIconArt(plan: plan, size: size),
      );
    }
    return _GradeTwoIconArt(plan: plan, size: size);
  }
}

class _GradeTwoIconArt extends StatelessWidget {
  final _GradeTwoPlan plan;
  final double size;

  const _GradeTwoIconArt({required this.plan, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: plan.color.withValues(alpha: .16),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: .16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(plan.icon, color: plan.color, size: size * .54),
    );
  }
}

class _GradeTwoSpeechBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _GradeTwoSpeechBubble({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 86),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.speechBubble,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 25,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return bubble;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: bubble,
      ),
    );
  }
}

class _GradeTwoAnswerBubble extends StatelessWidget {
  final String text;

  const _GradeTwoAnswerBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: hasText
            ? TudloColors.softGreen
            : Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: hasText ? .20 : .10),
            blurRadius: hasText ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            hasText ? text : ' ',
            key: ValueKey(text),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: hasText ? TudloColors.ink : TudloColors.muted,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeTwoQuestionCharacter extends StatelessWidget {
  final String question;
  final String? imageAsset;
  final Color color;

  const _GradeTwoQuestionCharacter({
    required this.question,
    required this.imageAsset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 142,
          height: 178,
          child: imageAsset == null
              ? Icon(Icons.face_rounded, color: color, size: 112)
              : Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.face_rounded, color: color, size: 112),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _GradeTwoSpeechBubble(text: question)),
      ],
    );
  }
}

class _GradeTwoFocusPicture extends StatelessWidget {
  final _GradeTwoTileVisual visual;
  final Color color;

  const _GradeTwoFocusPicture({required this.visual, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      height: 194,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (visual.isKoka)
            const _LessonKokaMascot(size: 132, mood: KokaMood.idle)
          else if (visual.imageAsset != null)
            Image.asset(
              visual.imageAsset!,
              width: 166,
              height: 126,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Icon(visual.icon, color: color, size: 96),
            )
          else
            Icon(visual.icon, color: visual.color, size: 80),
          const SizedBox(height: 6),
          Text(
            visual.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeTwoBuildTray extends StatelessWidget {
  final List<String> words;
  final String target;
  final Color color;
  final ValueChanged<int> onRemove;

  const _GradeTwoBuildTray({
    required this.words,
    required this.target,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final complete =
        _normalizedSentence(words.join(' ')) == _normalizedSentence(target);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: complete
            ? TudloColors.softGreen.withValues(alpha: .90)
            : Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: words.isEmpty
          ? Center(
              child: Text(
                'Ibutang diri ang imo sabat',
                style: GoogleFonts.nunito(
                  color: TudloColors.muted,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < words.length; index++)
                  _GradeTwoBuiltWord(
                    label: words[index],
                    color: color,
                    onTap: () => onRemove(index),
                  ),
              ],
            ),
    );
  }
}

class _GradeTwoTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _gradeTwoTileVisualFor(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: visual.imageAsset == null ? 144 : 138,
          height: visual.imageAsset == null ? 76 : 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .28),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (visual.isKoka) ...[
                const _LessonKokaMascot(size: 82, mood: KokaMood.idle),
                const SizedBox(height: 6),
              ] else if (visual.imageAsset != null) ...[
                Image.asset(
                  visual.imageAsset!,
                  width: 72,
                  height: 82,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(visual.icon, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 6),
              ] else if (visual.icon != Icons.text_fields_rounded) ...[
                Icon(visual.icon, color: Colors.white, size: 38),
                const SizedBox(height: 4),
              ],
              FittedBox(
                child: Text(
                  visual.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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

class _GradeTwoBuiltWord extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoBuiltWord({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _gradeTwoTileVisualFor(label);
    return ActionChip(
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: .16),
      side: BorderSide.none,
      label: Text(
        visual.label,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GradeTwoChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool checked;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.correct,
    required this.checked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = checked && !correct;
    final visual = _gradeTwoTileVisualFor(label);
    final hasArt =
        visual.isKoka ||
        visual.imageAsset != null ||
        visual.icon != Icons.text_fields_rounded;
    final activeColor = wrong
        ? const Color(0xFFE53935)
        : checked && correct
        ? TudloColors.green
        : color;
    return _FeedbackMotion(
      correct: checked && correct,
      wrong: wrong,
      child: SizedBox(
        width: double.infinity,
        height: hasArt ? 102 : 76,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            elevation: selected ? 8 : 4,
            shadowColor: activeColor.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.nunito(
              fontSize: 23,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          child: hasArt
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visual.isKoka)
                      const _LessonKokaMascot(size: 58, mood: KokaMood.idle)
                    else if (visual.imageAsset != null)
                      Image.asset(
                        visual.imageAsset!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) =>
                            Icon(visual.icon, color: Colors.white, size: 44),
                      )
                    else
                      Icon(visual.icon, color: Colors.white, size: 42),
                    const SizedBox(width: 14),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(visual.label, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                )
              : FittedBox(
                  child: Text(visual.label, textAlign: TextAlign.center),
                ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionOption extends StatelessWidget {
  final _GradeTwoMissionChoice choice;
  final Color color;
  final bool selected;
  final bool correct;
  final bool checked;
  final VoidCallback onTap;

  const _GradeTwoMissionOption({
    super.key,
    required this.choice,
    required this.color,
    required this.selected,
    required this.correct,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = checked && !correct;
    return _FeedbackMotion(
      correct: checked && correct,
      wrong: wrong,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 168,
          height: 194,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: wrong
                ? const Color(0xFFFFE7E7)
                : checked && correct
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (selected ? color : TudloColors.forest).withValues(
                  alpha: selected ? .22 : .10,
                ),
                blurRadius: selected ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GradeTwoMissionArt(choice: choice, color: color, size: 112),
              const SizedBox(height: 12),
              Text(
                choice.visualLabel ?? choice.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: wrong ? const Color(0xFFE53935) : TudloColors.ink,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionArt extends StatelessWidget {
  final _GradeTwoMissionChoice choice;
  final Color color;
  final double size;

  const _GradeTwoMissionArt({
    required this.choice,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (choice.isKoka) {
      return _LessonKokaMascot(size: size, mood: KokaMood.idle);
    }
    if (choice.imageAsset != null) {
      return Image.asset(
        choice.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(choice.icon, color: color, size: size * .72),
      );
    }
    return Icon(choice.icon, color: color, size: size * .72);
  }
}

String _normalizedSentence(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[.!?"]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

_GradeTwoTileVisual? _gradeTwoBuildFocusFor(_GradeTwoPlan plan) {
  for (final tile in plan.buildTiles) {
    final visual = _gradeTwoTileVisualFor(tile);
    if ((visual.isKoka || visual.imageAsset != null) &&
        plan.buildAnswer.contains(tile)) {
      return visual;
    }
  }
  for (final tile in plan.buildTiles) {
    final visual = _gradeTwoTileVisualFor(tile);
    if (visual.icon != Icons.text_fields_rounded &&
        plan.buildAnswer.contains(tile)) {
      return visual;
    }
  }
  return null;
}

_GradeTwoTileVisual _gradeTwoTileVisualFor(String value) {
  const grade2 = 'assets/images/level_game';
  final key = value.trim().toLowerCase();
  return switch (key) {
    'my name is' => const _GradeTwoTileVisual(
      label: 'Ako si',
      icon: Icons.badge_rounded,
      color: TudloColors.green,
    ),
    'koka' => const _GradeTwoTileVisual(
      label: 'Koka',
      isKoka: true,
      icon: Icons.face_rounded,
      color: TudloColors.green,
    ),
    'hello' => const _GradeTwoTileVisual(
      label: 'Kumusta',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'kumusta' || 'kumusta!' => const _GradeTwoTileVisual(
      label: 'Kumusta',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'paalam' || 'paalam!' => const _GradeTwoTileVisual(
      label: 'Paalam',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.blue,
    ),
    'goodbye' || 'goodbye!' => const _GradeTwoTileVisual(
      label: 'Paalam',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.blue,
    ),
    'koka ang ngalan ko' || 'koka ang ngalan ko.' => const _GradeTwoTileVisual(
      label: 'Koka ang ngalan ko',
      isKoka: true,
      icon: Icons.face_rounded,
      color: TudloColors.green,
    ),
    'i am' => const _GradeTwoTileVisual(
      label: 'Ako',
      icon: Icons.person_rounded,
      color: TudloColors.green,
    ),
    'seven' => const _GradeTwoTileVisual(
      label: 'pito',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'six' => const _GradeTwoTileVisual(
      label: 'anum',
      icon: Icons.looks_6_rounded,
      color: TudloColors.orange,
    ),
    'years old' => const _GradeTwoTileVisual(
      label: 'ka tuig',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'pito ka tuig ako' || 'pito ka tuig ako.' => const _GradeTwoTileVisual(
      label: 'Pito ka tuig ako',
      imageAsset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'this is my' => const _GradeTwoTileVisual(
      label: 'Amo ini',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'this is a' => const _GradeTwoTileVisual(
      label: 'Ini ang',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'it is a' => const _GradeTwoTileVisual(
      label: 'Ini ang',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'touch your' => const _GradeTwoTileVisual(
      label: 'Tanduga ang',
      icon: Icons.touch_app_rounded,
      color: TudloColors.coral,
    ),
    'mother' => const _GradeTwoTileVisual(
      label: 'nanay',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'nanay' => const _GradeTwoTileVisual(
      label: 'nanay',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'father' => const _GradeTwoTileVisual(
      label: 'tatay',
      imageAsset: 'assets/images/level_game/people/tatay.png',
      icon: Icons.man_rounded,
      color: TudloColors.green,
    ),
    'tatay' => const _GradeTwoTileVisual(
      label: 'tatay',
      imageAsset: 'assets/images/level_game/people/tatay.png',
      icon: Icons.man_rounded,
      color: TudloColors.green,
    ),
    'amo ini ang akon nanay' ||
    'amo ini ang akon nanay.' => const _GradeTwoTileVisual(
      label: 'Amo ini ang akon nanay',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'book' => const _GradeTwoTileVisual(
      label: 'libro',
      imageAsset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
    ),
    'libro' => const _GradeTwoTileVisual(
      label: 'libro',
      imageAsset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
    ),
    'pencil' => const _GradeTwoTileVisual(
      label: 'lapis',
      imageAsset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
    ),
    'lapis' => const _GradeTwoTileVisual(
      label: 'lapis',
      imageAsset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
    ),
    'bag' => const _GradeTwoTileVisual(
      label: 'bag',
      imageAsset: '$grade2/bag.png',
      icon: Icons.backpack_rounded,
      color: TudloColors.coral,
    ),
    'chair' => const _GradeTwoTileVisual(
      label: 'pulungkuan',
      imageAsset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
    ),
    'pulungkuan' => const _GradeTwoTileVisual(
      label: 'pulungkuan',
      imageAsset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
    ),
    'plate' => const _GradeTwoTileVisual(
      label: 'plato',
      imageAsset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
    ),
    'plato' => const _GradeTwoTileVisual(
      label: 'plato',
      imageAsset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
    ),
    'glass' => const _GradeTwoTileVisual(
      label: 'baso',
      imageAsset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
    ),
    'baso' => const _GradeTwoTileVisual(
      label: 'baso',
      imageAsset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
    ),
    'spoon' => const _GradeTwoTileVisual(
      label: 'kutsara',
      imageAsset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
    ),
    'kutsara' => const _GradeTwoTileVisual(
      label: 'kutsara',
      imageAsset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
    ),
    'tree' => const _GradeTwoTileVisual(
      label: 'kahoy',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    'kahoy' => const _GradeTwoTileVisual(
      label: 'kahoy',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    'flower' => const _GradeTwoTileVisual(
      label: 'bulak',
      icon: Icons.local_florist_rounded,
      color: TudloColors.coral,
    ),
    'bulak' => const _GradeTwoTileVisual(
      label: 'bulak',
      icon: Icons.local_florist_rounded,
      color: TudloColors.coral,
    ),
    'rock' => const _GradeTwoTileVisual(
      label: 'bato',
      icon: Icons.landscape_rounded,
      color: TudloColors.muted,
    ),
    'good' => const _GradeTwoTileVisual(
      label: 'maayo',
      icon: Icons.thumb_up_rounded,
      color: TudloColors.green,
    ),
    'maayo man, salamat' || 'maayo man, salamat.' => const _GradeTwoTileVisual(
      label: 'Maayo man, salamat',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    "i'm fine" => const _GradeTwoTileVisual(
      label: 'Maayo man',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    'thank' => const _GradeTwoTileVisual(
      label: 'sala',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'you' => const _GradeTwoTileVisual(
      label: 'mat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'thank you' => const _GradeTwoTileVisual(
      label: 'Salamat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'salamat' || 'salamat.' => const _GradeTwoTileVisual(
      label: 'Salamat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'please' => const _GradeTwoTileVisual(
      label: 'Palihog',
      icon: Icons.volunteer_activism_rounded,
      color: TudloColors.green,
    ),
    'sorry' => const _GradeTwoTileVisual(
      label: 'Pasensya',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: TudloColors.orange,
    ),
    'morning' => const _GradeTwoTileVisual(
      label: 'aga',
      imageAsset: 'assets/images/level_game/sunrise.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'maayong aga' || 'maayong aga!' => const _GradeTwoTileVisual(
      label: 'Maayong aga',
      imageAsset: 'assets/images/level_game/sunrise.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'good morning' => const _GradeTwoTileVisual(
      label: 'Maayong aga',
      imageAsset: 'assets/images/level_game/sunrise.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'evening' => const _GradeTwoTileVisual(
      label: 'gab-i',
      imageAsset: 'assets/images/level_game/moon.png',
      icon: Icons.dark_mode_rounded,
      color: TudloColors.blue,
    ),
    'maayong gab-i' || 'maayong gab-i!' => const _GradeTwoTileVisual(
      label: 'Maayong gab-i',
      imageAsset: 'assets/images/level_game/moon.png',
      icon: Icons.dark_mode_rounded,
      color: TudloColors.blue,
    ),
    'head' || 'ulo' => const _GradeTwoTileVisual(
      label: 'ulo',
      icon: Icons.face_rounded,
      color: TudloColors.coral,
    ),
    'feet' || 'tiil' => const _GradeTwoTileVisual(
      label: 'tiil',
      icon: Icons.directions_walk_rounded,
      color: TudloColors.green,
    ),
    'eyes' || 'mata' => const _GradeTwoTileVisual(
      label: 'mata',
      icon: Icons.visibility_rounded,
      color: TudloColors.blue,
    ),
    'dog' || 'ido' => const _GradeTwoTileVisual(
      label: 'ido',
      imageAsset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.pets_rounded,
      color: TudloColors.orange,
    ),
    'cat' || 'kuring' => const _GradeTwoTileVisual(
      label: 'kuring',
      imageAsset: 'assets/images/level_game/animals/cat.png',
      icon: Icons.pets_rounded,
      color: TudloColors.blue,
    ),
    'pig' || 'baboy' => const _GradeTwoTileVisual(
      label: 'baboy',
      imageAsset: 'assets/images/level_game/animals/pig.png',
      icon: Icons.pets_rounded,
      color: TudloColors.coral,
    ),
    'mat' || 'banig' => const _GradeTwoTileVisual(
      label: 'banig',
      icon: Icons.crop_square_rounded,
      color: TudloColors.green,
    ),
    'fish' || 'isda' => const _GradeTwoTileVisual(
      label: 'isda',
      imageAsset: 'assets/images/level_game/animals/fish.png',
      icon: Icons.water_rounded,
      color: TudloColors.blue,
    ),
    'sun' || 'adlaw' => const _GradeTwoTileVisual(
      label: 'adlaw',
      imageAsset: 'assets/images/level_game/sun.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'jump' || 'lumpat' => const _GradeTwoTileVisual(
      label: 'lumpat',
      icon: Icons.keyboard_arrow_up_rounded,
      color: TudloColors.coral,
    ),
    'wave' || 'paypay' => const _GradeTwoTileVisual(
      label: 'paypay',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'turn' || 'liko' => const _GradeTwoTileVisual(
      label: 'liko',
      icon: Icons.rotate_right_rounded,
      color: TudloColors.blue,
    ),
    'happy' || 'malipayon' => const _GradeTwoTileVisual(
      label: 'malipayon',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    'to my' => const _GradeTwoTileVisual(
      label: 'sa akon',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'my' => const _GradeTwoTileVisual(
      label: 'akon',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'sits' => const _GradeTwoTileVisual(
      label: 'nagapungko',
      icon: Icons.event_seat_rounded,
      color: TudloColors.blue,
    ),
    'i can' => const _GradeTwoTileVisual(
      label: 'Maka',
      icon: Icons.directions_run_rounded,
      color: TudloColors.coral,
    ),
    'is' => const _GradeTwoTileVisual(
      label: 'nga',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'merkado' => const _GradeTwoTileVisual(
      label: 'merkado',
      imageAsset: 'assets/images/level_game/tinda.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
    ),
    _ => _GradeTwoTileVisual(
      label: value,
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
  };
}

_GradeTwoPlan _gradeTwoPlanFor(LevelContent content) {
  const grade2 = 'assets/images/level_game';

  _GradeTwoPlan plan({
    required String sceneTitle,
    required String sceneLine,
    required String tapInstruction,
    required String phrase,
    required String phraseSpeech,
    required String buildPrompt,
    required String buildQuestion,
    String? buildCharacterAsset,
    required String buildAnswer,
    required List<String> buildTiles,
    required String choicePrompt,
    required List<String> choices,
    required String answer,
    required String missionTitle,
    required String missionPrompt,
    required List<_GradeTwoMissionChoice> missionChoices,
    required String missionAnswer,
    required String reward,
    String? imageAsset,
    required IconData icon,
    required Color color,
  }) {
    return _GradeTwoPlan(
      sceneTitle: sceneTitle,
      sceneLine: sceneLine,
      tapInstruction: tapInstruction,
      phrase: phrase,
      phraseSpeech: phraseSpeech,
      buildPrompt: buildPrompt,
      buildQuestion: buildQuestion,
      buildCharacterAsset: buildCharacterAsset,
      buildAnswer: buildAnswer,
      buildTiles: buildTiles,
      choicePrompt: choicePrompt,
      choices: choices,
      answer: answer,
      missionTitle: missionTitle,
      missionPrompt: missionPrompt,
      missionChoices: missionChoices,
      missionAnswer: missionAnswer,
      reward: reward,
      imageAsset: imageAsset,
      icon: icon,
      color: color,
    );
  }

  return switch ((content.unitNumber, content.lessonNumber)) {
    (1, 1) => plan(
      sceneTitle: 'Bag-o nga Abyan',
      sceneLine: 'May bag-o nga abyan sa eskwelahan.',
      tapInstruction: 'Ipindot ang Kumusta!',
      phrase: 'Kumusta!',
      phraseSpeech: 'Kumusta!',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang ngalan mo?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Koka ang ngalan ko',
      buildTiles: const ['Koka ang ngalan ko', 'Kumusta', 'Paalam'],
      choicePrompt: 'Ano ang imo ngalan?',
      choices: const ['Kumusta!', 'Koka ang ngalan ko.', 'Paalam!'],
      answer: 'Koka ang ngalan ko.',
      missionTitle: 'Kilalaha si Ana',
      missionPrompt: 'Pili-a ang sabat ni Koka.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'Koka ang ngalan ko.',
          isKoka: true,
          icon: Icons.face_rounded,
        ),
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Salamat!', icon: Icons.favorite),
      ],
      missionAnswer: 'Koka ang ngalan ko.',
      reward: 'Abyan na kamo!',
      imageAsset: '$grade2/school-entrance.png',
      icon: Icons.school_rounded,
      color: TudloColors.green,
    ),
    (1, 2) => plan(
      sceneTitle: 'Kaadlawan ni Juan',
      sceneLine: 'Tan-awa ang kandila.',
      tapInstruction: 'Ipindot ang pito ka kandila.',
      phrase: 'Pito ka tuig ako.',
      phraseSpeech: 'Pito ka tuig ako.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Pila ka tuig ka na?',
      buildCharacterAsset: 'assets/images/level_game/people/boy-juan.png',
      buildAnswer: 'Pito ka tuig ako',
      buildTiles: const ['Pito', 'ka tuig', 'ako', 'anum'],
      choicePrompt: 'Pila ka tuig ka na?',
      choices: const [
        'Pito ka tuig ako.',
        'Koka ang ngalan ko.',
        'Maayong aga!',
      ],
      answer: 'Pito ka tuig ako.',
      missionTitle: 'Palupad Lobo',
      missionPrompt: 'Ano ang sabat?',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'Pito ka tuig ako.',
          visualLabel: '7',
          imageAsset: '$grade2/ballons.png',
          icon: Icons.celebration_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'Anum ka tuig ako.',
          visualLabel: '6',
          icon: Icons.looks_6,
        ),
        _GradeTwoMissionChoice(label: 'Kumusta!', icon: Icons.chat_bubble),
      ],
      missionAnswer: 'Pito ka tuig ako.',
      reward: 'Nagsaka ang mga lobo!',
      imageAsset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    (1, 3) => plan(
      sceneTitle: 'Adlaw sang Pamilya',
      sceneLine: 'Kilalaha ang pamilya.',
      tapInstruction: 'Ipindot si Nanay.',
      phrase: 'Amo ini ang akon nanay.',
      phraseSpeech: 'Amo ini ang akon nanay.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Sin-o ini?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Amo ini ang akon nanay',
      buildTiles: const ['Amo ini ang', 'akon nanay', 'akon tatay', 'Paalam'],
      choicePrompt: 'Sin-o ini?',
      choices: const [
        'Amo ini ang akon nanay.',
        'Pito ka tuig ako.',
        'Paalam!',
      ],
      answer: 'Amo ini ang akon nanay.',
      missionTitle: 'Album sang Pamilya',
      missionPrompt: 'Pangitaa si Nanay.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'nanay',
          imageAsset: 'assets/images/level_game/people/nanay.png',
          icon: Icons.woman_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'tatay',
          imageAsset: 'assets/images/level_game/people/tatay.png',
          icon: Icons.man_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'bata',
          imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
          icon: Icons.child_care_rounded,
        ),
      ],
      missionAnswer: 'nanay',
      reward: 'Kompleto ang album.',
      imageAsset: 'assets/images/level_game/people/pamilya.png',
      icon: Icons.family_restroom_rounded,
      color: TudloColors.blue,
    ),
    (2, 1) => plan(
      sceneTitle: 'Adlaw ni Koka',
      sceneLine: 'Magbati sa aga, hapon, kag gab-i.',
      tapInstruction: 'Ipindot ang adlaw.',
      phrase: 'Maayong aga!',
      phraseSpeech: 'Maayong aga!',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Aga na. Ano ang hambalon mo?',
      buildCharacterAsset: 'assets/images/level_game/people/boy-juan.png',
      buildAnswer: 'Maayong aga',
      buildTiles: const ['Maayong', 'aga', 'gab-i', 'Kumusta'],
      choicePrompt: 'Aga na. Ano ang hambalon ni Koka?',
      choices: const ['Maayong aga!', 'Maayong gab-i!', 'Paalam!'],
      answer: 'Maayong aga!',
      missionTitle: 'Batia si Nanay',
      missionPrompt: 'Ano ang bati sa aga?',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Maayong aga!', icon: Icons.wb_sunny),
        _GradeTwoMissionChoice(label: 'Maayong gab-i!', icon: Icons.dark_mode),
        _GradeTwoMissionChoice(
          label: 'Pasensya.',
          icon: Icons.sentiment_dissatisfied,
        ),
      ],
      missionAnswer: 'Maayong aga!',
      reward: 'Maayo nga aga!',
      imageAsset: '$grade2/school-entrance.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    (2, 2) => plan(
      sceneTitle: 'Kamusta Ka?',
      sceneLine: 'Nangamusta si Koka.',
      tapInstruction: 'Ipindot ang malipayon nga nawong.',
      phrase: 'Maayo man, salamat.',
      phraseSpeech: 'Maayo man, salamat.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Kamusta ka?',
      buildCharacterAsset: 'assets/images/level_game/people/girl1.png',
      buildAnswer: 'Maayo man salamat',
      buildTiles: const ['Maayo man', 'salamat', 'Paalam', 'Pasensya'],
      choicePrompt: 'Kamusta ka?',
      choices: const [
        'Maayo man, salamat.',
        'Maayong gab-i!',
        'Koka ang ngalan ko.',
      ],
      answer: 'Maayo man, salamat.',
      missionTitle: 'Magpaalam',
      missionPrompt: 'Magpaalam.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Maayo man.', icon: Icons.mood),
        _GradeTwoMissionChoice(
          label: 'Palihog.',
          icon: Icons.volunteer_activism,
        ),
      ],
      missionAnswer: 'Paalam!',
      reward: 'Nagpaalam ka sing maayo.',
      imageAsset: 'assets/images/level_game/people/girl1.png',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    (2, 3) => plan(
      sceneTitle: 'Sa Tinda',
      sceneLine: 'Gamita ang matinahuron nga tinaga.',
      tapInstruction: 'Ipindot ang mangga.',
      phrase: 'Palihog.',
      phraseSpeech: 'Palihog.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ginhatagan ka sang mangga.',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Salamat',
      buildTiles: const ['Salamat', 'Palihog', 'Pasensya', 'Paalam'],
      choicePrompt: 'Ginhatagan ka sang mangga. Ano ang hambalon mo?',
      choices: const ['Salamat.', 'Maayong aga!', 'Koka ang ngalan ko.'],
      answer: 'Salamat.',
      missionTitle: 'Pasensya',
      missionPrompt: 'Magsiling sang pasensya.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Pasensya.', icon: Icons.favorite),
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Maayong gab-i!', icon: Icons.dark_mode),
      ],
      missionAnswer: 'Pasensya.',
      reward: 'Nagpatawad ang tindera.',
      imageAsset: '$grade2/mango.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
    ),
    (3, 1) => plan(
      sceneTitle: 'Sa Klase',
      sceneLine: 'Pangitaa ang gamit sa klase.',
      tapInstruction: 'Pangitaa ang libro.',
      phrase: 'Ini ang libro.',
      phraseSpeech: 'Ini ang libro.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: 'assets/images/level_game/people/boy-juan.png',
      buildAnswer: 'Ini ang libro',
      buildTiles: const ['Ini ang', 'libro', 'lapis', 'pulungkuan'],
      choicePrompt: 'Pangitaa ang libro.',
      choices: const ['libro', 'lapis', 'bag'],
      answer: 'libro',
      missionTitle: 'Pangitaa ang Butang',
      missionPrompt: 'Pangitaa ang libro.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'libro',
          imageAsset: '$grade2/book.png',
          icon: Icons.menu_book_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'lapis',
          imageAsset: '$grade2/pencil.png',
          icon: Icons.edit_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'bag',
          imageAsset: '$grade2/bag.png',
          icon: Icons.backpack_rounded,
        ),
      ],
      missionAnswer: 'libro',
      reward: 'Nakita mo ang libro.',
      imageAsset: '$grade2/classroom.png',
      icon: Icons.search_rounded,
      color: TudloColors.blue,
    ),
    (3, 2) => plan(
      sceneTitle: 'Sa Lamesa',
      sceneLine: 'Pangitaa ang gamit sa lamesa.',
      tapInstruction: 'Ipindot ang plato.',
      phrase: 'Ini ang plato.',
      phraseSpeech: 'Ini ang plato.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Ini ang plato',
      buildTiles: const ['Ini ang', 'plato', 'baso', 'kutsara'],
      choicePrompt: 'Ano ang ibutang sa lamesa?',
      choices: const ['plato', 'libro', 'bag'],
      answer: 'plato',
      missionTitle: 'Bulig sa Lamesa',
      missionPrompt: 'Pangitaa ang kutsara.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'plato',
          imageAsset: '$grade2/plate.png',
          icon: Icons.dinner_dining,
        ),
        _GradeTwoMissionChoice(
          label: 'baso',
          imageAsset: '$grade2/glass.png',
          icon: Icons.local_drink,
        ),
        _GradeTwoMissionChoice(
          label: 'kutsara',
          imageAsset: '$grade2/spoon.png',
          icon: Icons.restaurant,
        ),
      ],
      missionAnswer: 'kutsara',
      reward: 'Handa na ang lamesa.',
      imageAsset: '$grade2/table.png',
      icon: Icons.table_restaurant_rounded,
      color: TudloColors.green,
    ),
    (3, 3) => plan(
      sceneTitle: 'Himoa ang Parke',
      sceneLine: 'Dugangi ang parke.',
      tapInstruction: 'Ipindot ang kahoy.',
      phrase: 'Ini ang kahoy.',
      phraseSpeech: 'Ini ang kahoy.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: 'assets/images/level_game/people/boy1.png',
      buildAnswer: 'Ini ang kahoy',
      buildTiles: const ['Ini ang', 'kahoy', 'bulak', 'bato'],
      choicePrompt: 'Ano ang nagahatag landong?',
      choices: const ['kahoy', 'baso', 'kutsara'],
      answer: 'kahoy',
      missionTitle: 'Himoa ang Parke',
      missionPrompt: 'Pangitaa ang bulak.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'kahoy', icon: Icons.park_rounded),
        _GradeTwoMissionChoice(label: 'bulak', icon: Icons.local_florist),
        _GradeTwoMissionChoice(label: 'bato', icon: Icons.landscape),
      ],
      missionAnswer: 'bulak',
      reward: 'Nami ang parke.',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    (4, 1) => plan(
      sceneTitle: 'Kanta kag Hulag',
      sceneLine: 'Nagakanta kag nagahulag si Koka.',
      tapInstruction: 'Ipindot ang ulo.',
      phrase: 'Tanduga ang imo ulo.',
      phraseSpeech: 'Tanduga ang imo ulo.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang tandugon mo?',
      buildCharacterAsset: 'assets/images/level_game/people/girl1.png',
      buildAnswer: 'Tanduga ang imo ulo',
      buildTiles: const ['Tanduga ang', 'imo ulo', 'imo tiil', 'imo mata'],
      choicePrompt: 'Ano ang imo tandugon?',
      choices: const ['ulo', 'libro', 'merkado'],
      answer: 'ulo',
      missionTitle: 'Tapik sa Ritmo',
      missionPrompt: 'Ipindot ang tambol.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'tambol', icon: Icons.music_note_rounded),
        _GradeTwoMissionChoice(label: 'pulungkuan', icon: Icons.chair_rounded),
        _GradeTwoMissionChoice(label: 'bag', icon: Icons.backpack_rounded),
      ],
      missionAnswer: 'tambol',
      reward: 'Nagsayaw si Koka.',
      imageAsset: '$grade2/microphone.png',
      icon: Icons.music_note_rounded,
      color: TudloColors.coral,
    ),
    (4, 2) => plan(
      sceneTitle: 'Paktakon',
      sceneLine: 'Pamatii ang palatandaan kag sabta.',
      tapInstruction: 'Pamatii ang paktakon.',
      phrase: 'Ido ini.',
      phraseSpeech: 'Ido ini.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang sabat sa paktakon?',
      buildCharacterAsset: 'assets/images/level_game/people/boy2.png',
      buildAnswer: 'Ido ini',
      buildTiles: const ['Ido', 'ini', 'kuring', 'baboy'],
      choicePrompt: 'May apat ka tiil kag nagatahol.',
      choices: const ['ido', 'kuring', 'baboy'],
      answer: 'ido',
      missionTitle: 'Paktakon',
      missionPrompt: 'Pangitaa ang ido.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'ido',
          imageAsset: 'assets/images/level_game/animals/dog.png',
          icon: Icons.pets,
        ),
        _GradeTwoMissionChoice(
          label: 'kuring',
          imageAsset: 'assets/images/level_game/animals/cat.png',
          icon: Icons.pets,
        ),
        _GradeTwoMissionChoice(
          label: 'baboy',
          imageAsset: 'assets/images/level_game/animals/pig.png',
          icon: Icons.pets,
        ),
      ],
      missionAnswer: 'ido',
      reward: 'Nasabat mo ang paktakon.',
      imageAsset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.psychology_rounded,
      color: TudloColors.orange,
    ),
    (4, 3) => plan(
      sceneTitle: 'Mini Konsyerto',
      sceneLine: 'Kantaha ang pagbati.',
      tapInstruction: 'Ipindot ang mikropono.',
      phrase: 'Maayong aga sa akon nanay.',
      phraseSpeech: 'Maayong aga sa akon nanay.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang linya sang kanta?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Maayong aga sa akon nanay',
      buildTiles: const ['Maayong aga', 'sa akon', 'nanay', 'tatay'],
      choicePrompt: 'Sin-o ang ara sa kanta?',
      choices: const ['nanay', 'kutsara', 'pulungkuan'],
      answer: 'nanay',
      missionTitle: 'Konsyerto',
      missionPrompt: 'Ipindot ang manugkanta.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'manugkanta',
          imageAsset: '$grade2/microphone.png',
          icon: Icons.mic_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'libro',
          imageAsset: '$grade2/book.png',
          icon: Icons.menu_book,
        ),
        _GradeTwoMissionChoice(
          label: 'mangga',
          imageAsset: '$grade2/mango.png',
          icon: Icons.storefront,
        ),
      ],
      missionAnswer: 'manugkanta',
      reward: 'Nagpalakpak ang klase.',
      imageAsset: '$grade2/school-stage.png',
      icon: Icons.mic_rounded,
      color: TudloColors.green,
    ),
    (5, 1) => plan(
      sceneTitle: 'Binalaybay',
      sceneLine: 'Pamatii ang pareho nga tunog.',
      tapInstruction: 'Ipindot ang kuring.',
      phrase: 'Nagapungko ang kuring.',
      phraseSpeech: 'Nagapungko ang kuring.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang una nga linya?',
      buildCharacterAsset: 'assets/images/level_game/people/girl1.png',
      buildAnswer: 'Nagapungko ang kuring',
      buildTiles: const ['Nagapungko ang', 'kuring', 'ido', 'isda'],
      choicePrompt: 'Ano ang kapareho tunog?',
      choices: const ['banig', 'isda', 'adlaw'],
      answer: 'banig',
      missionTitle: 'Pareho nga Tunog',
      missionPrompt: 'Pili-a ang kapareho tunog.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'banig', icon: Icons.crop_square),
        _GradeTwoMissionChoice(
          label: 'isda',
          imageAsset: 'assets/images/level_game/animals/fish.png',
          icon: Icons.water,
        ),
        _GradeTwoMissionChoice(
          label: 'adlaw',
          imageAsset: '$grade2/sun.png',
          icon: Icons.wb_sunny,
        ),
      ],
      missionAnswer: 'banig',
      reward: 'Pareho ang tunog.',
      imageAsset: 'assets/images/level_game/animals/cat.png',
      icon: Icons.auto_stories_rounded,
      color: TudloColors.blue,
    ),
    (5, 2) => plan(
      sceneTitle: 'Binalaybay nga May Hulag',
      sceneLine: 'Maghulag samtang nagabasa.',
      tapInstruction: 'Ipindot ang bata nga nagalumpat.',
      phrase: 'Makalumpat ako.',
      phraseSpeech: 'Makalumpat ako.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano nga hulag ang himuon?',
      buildCharacterAsset: 'assets/images/level_game/people/boy1.png',
      buildAnswer: 'Makalumpat ako',
      buildTiles: const ['Makalumpat', 'ako', 'paypay', 'liko'],
      choicePrompt: 'Ano nga hulag ang ginpamati?',
      choices: const ['lumpat', 'libro', 'plato'],
      answer: 'lumpat',
      missionTitle: 'Hulaga ang Linya',
      missionPrompt: 'Pili-a ang paypay.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'lumpat', icon: Icons.keyboard_arrow_up),
        _GradeTwoMissionChoice(label: 'paypay', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'liko', icon: Icons.rotate_right),
      ],
      missionAnswer: 'paypay',
      reward: 'Handa ka na magbasa.',
      imageAsset: 'assets/images/level_game/people/boy1.png',
      icon: Icons.directions_run_rounded,
      color: TudloColors.coral,
    ),
    _ => plan(
      sceneTitle: 'Himoa ang Binalaybay',
      sceneLine: 'Pili tinaga kag basahon ni Koka.',
      tapInstruction: 'Ipindot ang ido.',
      phrase: 'Malipayon ang akon ido.',
      phraseSpeech: 'Malipayon ang akon ido.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang imo binalaybay?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Malipayon ang akon ido',
      buildTiles: const ['Malipayon ang', 'akon ido', 'kuring', 'masubo'],
      choicePrompt: 'Diin ang pareho sa binalaybay?',
      choices: const [
        'Malipayon ang akon ido.',
        'Pulungkuan kutsara baso.',
        'Paalam merkado.',
      ],
      answer: 'Malipayon ang akon ido.',
      missionTitle: 'Himoa ang Binalaybay',
      missionPrompt: 'Pili-a ang malipayon.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'malipayon', icon: Icons.mood),
        _GradeTwoMissionChoice(label: 'pulungkuan', icon: Icons.chair),
        _GradeTwoMissionChoice(label: 'kutsara', icon: Icons.restaurant),
      ],
      missionAnswer: 'malipayon',
      reward: 'Nabasa ni Koka ang imo binalaybay.',
      imageAsset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.auto_stories_rounded,
      color: TudloColors.forest,
    ),
  };
}
