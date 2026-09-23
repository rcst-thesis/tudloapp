part of '../../level_game_page.dart';

class _GradeOneUnitTwoLessonOneFamilyReferenceFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitTwoLessonOneFamilyReferenceFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitTwoLessonOneFamilyReferenceFlow> createState() =>
      _GradeOneUnitTwoLessonOneFamilyReferenceFlowState();
}

class _GradeOneUnitTwoLessonOneFamilyReferenceFlowState
    extends State<_GradeOneUnitTwoLessonOneFamilyReferenceFlow> {
  static const _voiceBase = 'audio/VO-final/grade1';
  static const _members = [
    _FamilyWord(
      hil: 'nanay',
      eng: 'mother',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
    ),
    _FamilyWord(
      hil: 'tatay',
      eng: 'father',
      imageAsset: 'assets/images/level_game/people/tatay.png',
      icon: Icons.man_rounded,
    ),
    _FamilyWord(
      hil: 'bata',
      eng: 'child',
      imageAsset: 'assets/images/level_game/people/bata-nga-lalaki.png',
      icon: Icons.child_care_rounded,
    ),
  ];

  int _stepIndex = 0;
  final Set<String> _learned = {};
  String? _activeChoice;
  String? _wrongChoice;
  final Map<String, String> _labelMatches = {};
  String? _wrongLabel;
  bool _completed = false;

  double get _progress => (_stepIndex + 1) / 7;

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

  void _goToStep(int index) {
    final next = index.clamp(0, 6);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _stepIndex = next;
      _activeChoice = null;
      _wrongChoice = null;
      _wrongLabel = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playFamilyVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_1_Les_2_1_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_stepIndex) {
      0 => const [3],
      1 => const <int>[],
      2 => const [4, 5, 6, 7],
      3 => const [8],
      4 => const [12, 13],
      5 => const [15],
      _ => const [17],
    };
    if (clips.isEmpty) return;
    try {
      await _playFamilyVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_stepIndex) {
          0 => 'I-tap ang laragway agod magsugod.',
          1 => 'Tap ang Balay ni Koka.',
          2 => 'Kilalahon ta ang pamilya.',
          3 => 'Pangitaa si nanay.',
          4 => 'Sino ang bata?',
          5 => 'Ipares ang mga ngalan.',
          _ => 'Yehey! Kompleto na ang litrato!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  int _memberVoiceClip(_FamilyWord member) {
    return switch (member.hil) {
      'nanay' => 4,
      'tatay' => 5,
      'bata' => 6,
      _ => 7,
    };
  }

  Future<void> _learnMember(_FamilyWord member) async {
    if (_learned.contains(member.hil)) {
      await _playFamilyVoice([_memberVoiceClip(member)]);
      return;
    }
    final wasIncomplete = _learned.length < _members.length;
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() => _learned.add(member.hil));
    await _playFamilyVoice([_memberVoiceClip(member)]);
    if (!mounted) return;
    if (wasIncomplete && _learned.length == _members.length) {
      await _playFamilyVoice(const [7]);
    }
  }

  Future<void> _choose({
    required _FamilyWord member,
    required String answer,
    required int quizIndex,
    required int nextStep,
  }) async {
    if (_activeChoice != null) return;
    final correct = member.hil == answer;
    widget.onQuizAttempt(quizIndex, correct);
    setState(() {
      _activeChoice = member.hil;
      _wrongChoice = correct ? null : member.hil;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (correct) {
      widget.onQuizCorrect(quizIndex);
      await _playFamilyVoice([answer == 'bata' ? 14 : 9]);
      await Future<void>.delayed(const Duration(milliseconds: 760));
      if (mounted) _goToStep(nextStep);
      return;
    }
    await _playFamilyVoice(answer == 'nanay' ? const [10, 11] : const [10]);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() {
      _activeChoice = null;
      _wrongChoice = null;
    });
  }

  Future<void> _placeLabel(String slotHil, String labelHil) async {
    if (_labelMatches.containsKey(slotHil) ||
        _labelMatches.containsValue(labelHil) ||
        _wrongLabel != null) {
      return;
    }
    final correct = slotHil == labelHil;
    widget.onQuizAttempt(2, correct);
    if (!correct) {
      setState(() => _wrongLabel = labelHil);
      await AppAudioService.instance.playWrong();
      await _playFamilyVoice(const [16]);
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (mounted) setState(() => _wrongLabel = null);
      return;
    }

    setState(() => _labelMatches[slotHil] = labelHil);
    await AppAudioService.instance.playCorrect();
    await _playFamilyVoice([_memberVoiceClip(_memberForHil(labelHil))]);
    if (!mounted) return;
    if (_members.every((member) => _labelMatches[member.hil] == member.hil)) {
      widget.onQuizCorrect(2);
      await Future<void>.delayed(_lessonCompletionHold);
      if (mounted) _goToStep(6);
    }
  }

  _FamilyWord _memberForHil(String hil) {
    return _members.firstWhere(
      (member) => member.hil == hil,
      orElse: () => _members.first,
    );
  }

  void _finishLesson() {
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
        key: ValueKey('g1-u2-l1-reference-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _FamilyReferenceIntroStep(
            progress: _progress,
            message: 'I-tap ang laragway agod magsugod.',
            showCoveredPhoto: true,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(1),
          ),
          1 => _FamilyReferenceMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _FamilyReferenceLearnStep(
            progress: _progress,
            learned: _learned,
            members: _members,
            portraitAsset:
                'assets/images/level_game/people/family-portrait.svg',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTap: _learnMember,
            onContinue: () => _goToStep(3),
          ),
          3 => _FamilyReferenceFindStep(
            progress: _progress,
            members: _members,
            prompt: 'Pangitaa si nanay.',
            answer: 'nanay',
            activeChoice: _activeChoice,
            wrongChoice: _wrongChoice,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: (member) => _choose(
              member: member,
              answer: 'nanay',
              quizIndex: 0,
              nextStep: 4,
            ),
          ),
          4 => _FamilyReferenceFindStep(
            progress: _progress,
            members: _members,
            prompt: 'Sino ang bata?',
            answer: 'bata',
            activeChoice: _activeChoice,
            wrongChoice: _wrongChoice,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: (member) => _choose(
              member: member,
              answer: 'bata',
              quizIndex: 1,
              nextStep: 5,
            ),
          ),
          5 => _FamilyLabelMatchingStep(
            progress: _progress,
            members: _members,
            matches: _labelMatches,
            wrongLabel: _wrongLabel,
            portraitAsset:
                'assets/images/level_game/people/family-portrait.svg',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placeLabel,
          ),
          _ => _FamilyReferenceRewardStep(
            progress: _progress,
            members: _members,
            portraitAsset:
                'assets/images/level_game/people/family-portrait.svg',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finishLesson,
            buttonLabel: 'Kolektahon',
          ),
        },
      ),
    );
  }
}

class _GradeOneUnitTwoLessonTwoVisitorFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitTwoLessonTwoVisitorFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitTwoLessonTwoVisitorFlow> createState() =>
      _GradeOneUnitTwoLessonTwoVisitorFlowState();
}

class _GradeOneUnitTwoLessonTwoVisitorFlowState
    extends State<_GradeOneUnitTwoLessonTwoVisitorFlow> {
  static const _lola = _FamilyWord(
    hil: 'lola',
    eng: 'grandmother',
    imageAsset: 'assets/images/level_game/people/lola.png',
    icon: Icons.elderly_woman_rounded,
  );
  static const _lolo = _FamilyWord(
    hil: 'lolo',
    eng: 'grandfather',
    imageAsset: 'assets/images/level_game/people/lolo.png',
    icon: Icons.elderly_rounded,
  );
  static const _nanay = _FamilyWord(
    hil: 'nanay',
    eng: 'mother',
    imageAsset: 'assets/images/level_game/people/nanay.png',
    icon: Icons.woman_rounded,
  );
  static const _learnMembers = [_lola, _lolo];
  static const _choiceMembers = [_lola, _lolo, _nanay];

  int _stepIndex = 0;
  final Set<String> _learned = {};
  String? _activeChoice;
  String? _wrongChoice;
  bool _completed = false;

  double get _progress => (_stepIndex + 1) / 6;

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

  void _goToStep(int index) {
    final next = index.clamp(0, 5);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _stepIndex = next;
      _activeChoice = null;
      _wrongChoice = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _speakForStep() async {
    await TudloVoiceButton.speak(
      context,
      switch (_stepIndex) {
        0 => 'May bisita kita!',
        1 => 'I-tap ang balay sa mapa. Didto ta makilala sa bisita.',
        2 => 'Kilalahon ta si lola kag lolo.',
        3 => 'Pangitaa si lola.',
        4 => 'Ipares ang husto nga tinaga.',
        _ => 'Yehey! Kilala ko si lola kag lolo!',
      },
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _learnMember(_FamilyWord member) async {
    if (_learned.contains(member.hil)) return;
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() => _learned.add(member.hil));
    await TudloVoiceButton.speak(
      context,
      '${member.hil}. ${member.eng}.',
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_learned.length == _learnMembers.length) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) _goToStep(3);
    }
  }

  Future<void> _choose(_FamilyWord member) async {
    if (_activeChoice != null) return;
    final correct = member.hil == 'lola';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _activeChoice = member.hil;
      _wrongChoice = correct ? null : member.hil;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (correct) {
      widget.onQuizCorrect(0);
      await Future<void>.delayed(const Duration(milliseconds: 760));
      if (mounted) _goToStep(4);
      return;
    }
    await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() {
      _activeChoice = null;
      _wrongChoice = null;
    });
  }

  void _finishLesson() {
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
        key: ValueKey('g1-u2-l2-visitors-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _FamilyReferenceIntroStep(
            progress: _progress,
            message: 'May bisita kita!',
            backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(1),
          ),
          1 => _FamilyReferenceMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _FamilyReferenceLearnStep(
            progress: _progress,
            learned: _learned,
            members: _learnMembers,
            prompt: 'Kilalahon ta si lola kag lolo.',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTap: _learnMember,
          ),
          3 => _FamilyReferenceFindStep(
            progress: _progress,
            members: _choiceMembers,
            prompt: 'Pangitaa si lola.',
            answer: 'lola',
            activeChoice: _activeChoice,
            wrongChoice: _wrongChoice,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _choose,
          ),
          4 => _FamilyReferenceMatchingStep(
            progress: _progress,
            words: _choiceMembers,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onAttempt: (word, correct) => widget.onQuizAttempt(1, correct),
            onCorrect: () {
              widget.onQuizCorrect(1);
              Future<void>.delayed(_lessonCompletionHold, () {
                if (mounted) _goToStep(5);
              });
            },
          ),
          _ => _FamilyReferenceRewardStep(
            progress: _progress,
            members: _learnMembers,
            message: 'Yehey! Kilala ko si lola kag lolo!',
            badgeLabel: 'Pamilya\n2',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finishLesson,
          ),
        },
      ),
    );
  }
}

class _GradeOneUnitTwoLessonThreePortraitFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitTwoLessonThreePortraitFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitTwoLessonThreePortraitFlow> createState() =>
      _GradeOneUnitTwoLessonThreePortraitFlowState();
}

class _GradeOneUnitTwoLessonThreePortraitFlowState
    extends State<_GradeOneUnitTwoLessonThreePortraitFlow> {
  static const _magulang = _FamilyWord(
    hil: 'magulang',
    eng: 'older sibling',
    imageAsset: 'assets/images/level_game/people/bata-nga-lalaki.png',
    icon: Icons.escalator_warning_rounded,
  );
  static const _manghod = _FamilyWord(
    hil: 'manghod',
    eng: 'younger sibling',
    imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
    icon: Icons.child_friendly_rounded,
  );
  static const _lola = _FamilyWord(
    hil: 'lola',
    eng: 'grandmother',
    imageAsset: 'assets/images/level_game/people/lola.png',
    icon: Icons.elderly_woman_rounded,
  );
  static const _tatay = _FamilyWord(
    hil: 'tatay',
    eng: 'father',
    imageAsset: 'assets/images/level_game/people/tatay.png',
    icon: Icons.man_rounded,
  );
  static const _learnMembers = [_magulang, _manghod];
  static const _choiceMembers = [_magulang, _manghod, _lola];
  static const _photoMembers = [_magulang, _manghod, _lola, _tatay];

  int _stepIndex = 0;
  final Set<String> _learned = {};
  String? _activeChoice;
  String? _wrongChoice;
  bool _completed = false;

  double get _progress => (_stepIndex + 1) / 6;

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

  void _goToStep(int index) {
    final next = index.clamp(0, 5);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _stepIndex = next;
      _activeChoice = null;
      _wrongChoice = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _speakForStep() async {
    await TudloVoiceButton.speak(
      context,
      switch (_stepIndex) {
        0 => 'Maghimo kita sang litrato!',
        1 => 'I-tap ang balay sa mapa. Didto ta maghimo sang litrato.',
        2 => 'Kilalahon ta ang magulang kag manghod.',
        3 => 'Pangitaa ang magulang.',
        4 => 'Ibutang ang pamilya sa litrato.',
        _ => 'Yehey! Kompleto ang litrato!',
      },
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _learnMember(_FamilyWord member) async {
    if (_learned.contains(member.hil)) return;
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() => _learned.add(member.hil));
    await TudloVoiceButton.speak(
      context,
      '${member.hil}. ${member.eng}.',
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_learned.length == _learnMembers.length) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) _goToStep(3);
    }
  }

  Future<void> _choose(_FamilyWord member) async {
    if (_activeChoice != null) return;
    final correct = member.hil == 'magulang';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _activeChoice = member.hil;
      _wrongChoice = correct ? null : member.hil;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (correct) {
      widget.onQuizCorrect(0);
      await Future<void>.delayed(const Duration(milliseconds: 760));
      if (mounted) _goToStep(4);
      return;
    }
    await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() {
      _activeChoice = null;
      _wrongChoice = null;
    });
  }

  void _finishLesson() {
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
        key: ValueKey('g1-u2-l3-portrait-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _FamilyReferenceIntroStep(
            progress: _progress,
            message: 'Maghimo kita sang litrato!',
            backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(1),
          ),
          1 => _FamilyReferenceMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _FamilyReferenceLearnStep(
            progress: _progress,
            learned: _learned,
            members: _learnMembers,
            prompt: 'Kilalahon ta ang magulang kag manghod.',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTap: _learnMember,
          ),
          3 => _FamilyReferenceFindStep(
            progress: _progress,
            members: _choiceMembers,
            prompt: 'Pangitaa ang magulang.',
            answer: 'magulang',
            activeChoice: _activeChoice,
            wrongChoice: _wrongChoice,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _choose,
          ),
          4 => _FamilyReferencePhotoActivityStep(
            progress: _progress,
            members: _photoMembers,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onAttempt: (correct) => widget.onQuizAttempt(1, correct),
            onCorrect: () {
              widget.onQuizCorrect(1);
              Future<void>.delayed(_lessonCompletionHold, () {
                if (mounted) _goToStep(5);
              });
            },
          ),
          _ => _FamilyReferenceRewardStep(
            progress: _progress,
            members: _photoMembers,
            message: 'Yehey! Kompleto ang litrato!',
            badgeLabel: 'Pamilya\n3',
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finishLesson,
          ),
        },
      ),
    );
  }
}

class _FamilyReferenceIntroStep extends StatefulWidget {
  final double progress;
  final String message;
  final String backgroundAsset;
  final bool showCoveredPhoto;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _FamilyReferenceIntroStep({
    required this.progress,
    this.message = 'May bag-o ako nga litrato!',
    this.backgroundAsset =
        'assets/images/level_game/backgrounds/lesson2-popup.svg',
    this.showCoveredPhoto = false,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_FamilyReferenceIntroStep> createState() =>
      _FamilyReferenceIntroStepState();
}

class _FamilyReferenceIntroStepState extends State<_FamilyReferenceIntroStep> {
  bool _revealed = false;

  Future<void> _revealPortrait() async {
    if (_revealed) return;
    setState(() => _revealed = true);
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final showBackgroundPhotoFrame = widget.showCoveredPhoto;
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      backgroundAsset: widget.backgroundAsset,
      child: Stack(
        children: [
          if (showBackgroundPhotoFrame)
            Positioned(
              left: view.width * .32,
              right: -view.width * .02,
              top: view.height * .17,
              height: view.height * .20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _revealPortrait,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _revealed ? 1 : 0,
                        duration: const Duration(milliseconds: 320),
                        child: const _LessonPictureAsset(
                          asset:
                              'assets/images/level_game/people/family-portrait.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (!_revealed)
                      Positioned(
                        right: view.width * .04,
                        bottom: -view.height * .01,
                        child: const _FamilyTapCue(),
                      ),
                  ],
                ),
              ),
            ),
          if (!showBackgroundPhotoFrame)
            Positioned(
              left: view.width * .22,
              right: view.width * .22,
              top: view.height * .18,
              child: _LessonKokaMascot(
                size: (view.width * .42).clamp(150.0, 215.0),
                mood: KokaMood.idle,
              ),
            ),
          if (showBackgroundPhotoFrame)
            Positioned(
              left: view.width * .02,
              bottom: view.height * .19,
              child: _LessonKokaMascot(
                size: (view.width * .88).clamp(300.0, 430.0),
                mood: KokaMood.idle,
              ),
            ),
          Positioned(
            left: showBackgroundPhotoFrame
                ? view.width * .055
                : view.width * .07,
            right: showBackgroundPhotoFrame
                ? view.width * .055
                : view.width * .07,
            bottom: view.height * .14,
            child: showBackgroundPhotoFrame
                ? _LargeFamilyIntroMessageCard(message: widget.message)
                : _LessonOneMessageCard(message: widget.message),
          ),
          if (!showBackgroundPhotoFrame)
            Positioned(
              left: view.width * .07,
              right: view.width * .07,
              bottom: view.height * .045,
              child: _LessonOneBlueButton(label: 'Sige', onTap: widget.onNext),
            ),
        ],
      ),
    );
  }
}

class _LargeFamilyIntroMessageCard extends StatelessWidget {
  final String message;

  const _LargeFamilyIntroMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .11),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: (width * .075).clamp(28.0, 38.0),
          height: 1.02,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FamilyReferencePortraitImage extends StatelessWidget {
  final String asset;
  final double height;

  const _FamilyReferencePortraitImage({
    required this.asset,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonPictureAsset(
      asset: asset,
      fit: BoxFit.contain,
      errorBuilder: (_) => Icon(
        Icons.family_restroom_rounded,
        color: TudloColors.forest,
        size: height * .42,
      ),
    );
  }
}

class _FamilyTapCue extends StatefulWidget {
  const _FamilyTapCue();

  @override
  State<_FamilyTapCue> createState() => _FamilyTapCueState();
}

class _FamilyTapCueState extends State<_FamilyTapCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: .92,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Icon(
        Icons.touch_app_rounded,
        color: const Color(0xFFFFB323),
        size: MediaQuery.sizeOf(context).width * .17,
        shadows: [
          Shadow(color: Colors.white.withValues(alpha: .9), blurRadius: 8),
        ],
      ),
    );
  }
}

class _FamilyReferenceMapStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _FamilyReferenceMapStep({
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
            left: view.width * .55,
            top: view.height * .31,
            width: view.width * .30,
            height: view.height * .22,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await AppAudioService.instance.playCorrect();
                onNext();
              },
              child: const _LessonOneMapDestinationCue(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyReferenceLearnStep extends StatelessWidget {
  final double progress;
  final Set<String> learned;
  final List<_FamilyWord> members;
  final String prompt;
  final String? portraitAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_FamilyWord member) onTap;
  final VoidCallback? onContinue;

  const _FamilyReferenceLearnStep({
    required this.progress,
    required this.learned,
    required this.members,
    this.prompt = 'Kilalahon ta ang pamilya.',
    this.portraitAsset,
    required this.onExit,
    required this.onReplay,
    required this.onTap,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final orderedMembers = _familyReferenceCardOrder(members);
    final cardRowHeight = (view.height * .21).clamp(178.0, 220.0).toDouble();
    final canContinue =
        onContinue != null &&
        members.every((member) => learned.contains(member.hil));
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
      child: Stack(
        children: [
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            top: top + view.height * .12,
            child: _LessonOneMessageCard(message: prompt),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            top: view.height * .25,
            child: _FamilyReferencePhotoFrame(
              members: members,
              portraitAsset: portraitAsset,
            ),
          ),
          Positioned(
            left: view.width * .025,
            right: view.width * .025,
            bottom: view.height * .055,
            height: cardRowHeight,
            child: Row(
              children: [
                for (final member in orderedMembers)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _FamilyReferenceMemberCard(
                        member: member,
                        selected: learned.contains(member.hil),
                        onTap: () => onTap(member),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: view.width * .16,
            right: view.width * .16,
            bottom: view.height * .055 + cardRowHeight + view.height * .014,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: canContinue
                  ? _LessonOneBlueButton(label: 'Sunod', onTap: onContinue)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyReferenceFindStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> members;
  final String prompt;
  final String answer;
  final String? activeChoice;
  final String? wrongChoice;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_FamilyWord member) onChoose;

  const _FamilyReferenceFindStep({
    required this.progress,
    required this.members,
    required this.prompt,
    required this.answer,
    required this.activeChoice,
    required this.wrongChoice,
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
      backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .055,
          top + view.height * .13,
          view.width * .055,
          view.height * .045,
        ),
        child: Column(
          children: [
            const Spacer(),
            _LessonOneMessageCard(message: prompt),
            SizedBox(height: view.height * .025),
            _FamilyReferenceChoiceFrame(
              members: members,
              answer: answer,
              activeChoice: activeChoice,
              wrongChoice: wrongChoice,
              onChoose: onChoose,
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

List<_FamilyWord> _familyReferenceCardOrder(List<_FamilyWord> members) {
  final byName = {for (final member in members) member.hil: member};
  return [
    if (byName['nanay'] != null) byName['nanay']!,
    if (byName['bata'] != null) byName['bata']!,
    if (byName['tatay'] != null) byName['tatay']!,
    for (final member in members)
      if (!{'nanay', 'bata', 'tatay'}.contains(member.hil)) member,
  ];
}

String _familyReferenceFullBodyAssetFor(_FamilyWord member) {
  return switch (member.hil) {
    'nanay' =>
      'assets/images/level_game/grade1/people/Tudlo_Nanay_Full_Body_Exact.svg',
    'tatay' =>
      'assets/images/level_game/grade1/people/Tudlo_Tatay_Full_Body_Exact.svg',
    'bata' =>
      'assets/images/level_game/grade1/people/Tudlo_Bata_Full_Body_Exact.svg',
    _ => member.imageAsset,
  };
}

double _familyReferenceFindScaleFor(String hil) {
  return switch (hil) {
    'nanay' || 'tatay' => 1.12,
    'bata' => 1.04,
    _ => 1,
  };
}

class _FamilyReferenceChoiceFrame extends StatelessWidget {
  final List<_FamilyWord> members;
  final String answer;
  final String? activeChoice;
  final String? wrongChoice;
  final Future<void> Function(_FamilyWord member) onChoose;

  const _FamilyReferenceChoiceFrame({
    required this.members,
    required this.answer,
    required this.activeChoice,
    required this.wrongChoice,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final height = (view.height * .48).clamp(320.0, 470.0);
    final ordered = _familyReferenceCardOrder(members);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final member in ordered)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _FamilyReferenceInlineChoiceCard(
                  member: member,
                  correct: activeChoice == member.hil && member.hil == answer,
                  wrong: wrongChoice == member.hil,
                  onTap: () => onChoose(member),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilyReferenceInlineChoiceCard extends StatelessWidget {
  final _FamilyWord member;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  const _FamilyReferenceInlineChoiceCard({
    required this.member,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : TudloColors.gold;
    final showGlow = correct || wrong;
    return LayoutBuilder(
      builder: (context, constraints) {
        return _FeedbackMotion(
          correct: correct,
          wrong: wrong,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: constraints.maxHeight * .09,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: showGlow ? 1 : 0,
                    child: Container(
                      width: constraints.maxWidth * .9,
                      height: constraints.maxHeight * .46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: .42),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: glowColor.withValues(alpha: .24),
                            blurRadius: 54,
                            spreadRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Transform.scale(
                    scale: _familyReferenceFindScaleFor(member.hil),
                    alignment: Alignment.bottomCenter,
                    child: _LessonPictureAsset(
                      asset: _familyReferenceFullBodyAssetFor(member),
                      fit: BoxFit.contain,
                      errorBuilder: (_) =>
                          Icon(member.icon, color: TudloColors.forest),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FamilyReferenceRewardStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> members;
  final String? portraitAsset;
  final String message;
  final String badgeLabel;
  final String buttonLabel;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _FamilyReferenceRewardStep({
    required this.progress,
    required this.members,
    this.portraitAsset,
    this.message = 'Yehey! Kompleto na ang litrato!',
    this.badgeLabel = 'Family\nFriend',
    this.buttonLabel = 'Padayon',
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
      backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
      child: _StickerUnlockRewardContent(
        fallback: _FamilyReferenceBadge(label: badgeLabel),
        message: message,
        buttonLabel: buttonLabel,
        onDone: onDone,
      ),
    );
  }
}

class _FamilyReferencePhotoFrame extends StatelessWidget {
  final List<_FamilyWord> members;
  final String? portraitAsset;

  const _FamilyReferencePhotoFrame({required this.members, this.portraitAsset});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final height = (view.height * .25).clamp(140.0, 235.0);
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD2B171), width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (portraitAsset != null)
            Expanded(
              child: _FamilyReferencePortraitImage(
                asset: portraitAsset!,
                height: height,
              ),
            )
          else
            for (final member in members)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _LessonPictureAsset(
                    asset: member.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_) => Icon(
                      member.icon,
                      color: TudloColors.forest,
                      size: height * .42,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _FamilyReferenceMemberCard extends StatelessWidget {
  final _FamilyWord member;
  final bool selected;
  final VoidCallback onTap;

  const _FamilyReferenceMemberCard({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5FFD5) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? TudloColors.green : const Color(0xFFD8E8F6),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _LessonPictureAsset(
                  asset: member.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_) =>
                      Icon(member.icon, color: TudloColors.forest),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.hil,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: (view.width * .047).clamp(17.0, 23.0),
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            TudloVoiceButton(
              message: '${member.hil}. ${member.eng}.',
              hiligaynon: true,
              tooltip: 'Pamatii',
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyReferenceMatchingStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> words;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final void Function(_FamilyWord word, bool correct) onAttempt;
  final VoidCallback onCorrect;

  const _FamilyReferenceMatchingStep({
    required this.progress,
    required this.words,
    required this.onExit,
    required this.onReplay,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          top + view.height * .105,
          view.width * .045,
          view.height * .025,
        ),
        child: _FamilyMatchingCard(
          words: words,
          onAttempt: onAttempt,
          onCorrect: onCorrect,
        ),
      ),
    );
  }
}

class _FamilyLabelMatchingStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> members;
  final Map<String, String> matches;
  final String? wrongLabel;
  final String portraitAsset;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String slotHil, String labelHil) onPlace;

  const _FamilyLabelMatchingStep({
    required this.progress,
    required this.members,
    required this.matches,
    required this.wrongLabel,
    required this.portraitAsset,
    required this.onExit,
    required this.onReplay,
    required this.onPlace,
  });

  List<_FamilyWord> get _slotMembers {
    final byName = {for (final member in members) member.hil: member};
    return [
      if (byName['nanay'] != null) byName['nanay']!,
      if (byName['bata'] != null) byName['bata']!,
      if (byName['tatay'] != null) byName['tatay']!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final slots = _slotMembers;
    final available = members
        .where((member) => !matches.containsValue(member.hil))
        .toList(growable: false);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          top + view.height * .12,
          view.width * .045,
          view.height * .035,
        ),
        child: Column(
          children: [
            _LessonOneMessageCard(message: 'Ipares ang mga ngalan.'),
            SizedBox(height: view.height * .018),
            Expanded(
              child: _FamilyLabelPhotoBoard(
                members: slots,
                matches: matches,
                portraitAsset: portraitAsset,
                onPlace: onPlace,
              ),
            ),
            SizedBox(height: view.height * .018),
            Row(
              children: [
                for (final member in members)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _FamilyLabelTile(
                        member: member,
                        hidden: !available.contains(member),
                        wrong: wrongLabel == member.hil,
                        onTap: () {},
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

class _FamilyLabelPhotoBoard extends StatelessWidget {
  final List<_FamilyWord> members;
  final Map<String, String> matches;
  final String portraitAsset;
  final Future<void> Function(String slotHil, String labelHil) onPlace;

  const _FamilyLabelPhotoBoard({
    required this.members,
    required this.matches,
    required this.portraitAsset,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: (view.height * .49).clamp(390.0, 500.0),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6).withValues(alpha: .95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD2B171), width: 5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 8,
              right: 8,
              top: (view.height * .11).clamp(76.0, 105.0),
              height: (view.height * .24).clamp(170.0, 220.0),
              child: _LessonPictureAsset(
                asset: portraitAsset,
                fit: BoxFit.contain,
                errorBuilder: (_) => Icon(
                  Icons.family_restroom_rounded,
                  color: TudloColors.forest,
                  size: view.width * .24,
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: (view.height * .025).clamp(18.0, 30.0),
              child: Row(
                children: [
                  for (final member in members)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _FamilyLabelSlot(
                          member: member,
                          label: matches[member.hil],
                          onAccept: (labelHil) => onPlace(member.hil, labelHil),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyLabelSlot extends StatelessWidget {
  final _FamilyWord member;
  final String? label;
  final Future<void> Function(String labelHil) onAccept;

  const _FamilyLabelSlot({
    required this.member,
    required this.label,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final filled = label != null;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !filled,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, _, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled
                ? const Color(0xFFE5FFD5)
                : Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: filled ? TudloColors.green : const Color(0xFFB8B8B8),
              width: 3,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Text(
            filled ? label! : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: TudloColors.blue,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        );
      },
    );
  }
}

class _FamilyLabelTile extends StatelessWidget {
  final _FamilyWord member;
  final bool hidden;
  final bool wrong;
  final VoidCallback onTap;

  const _FamilyLabelTile({
    required this.member,
    required this.hidden,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _FeedbackMotion(
      correct: hidden,
      wrong: wrong,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: hidden ? 0 : 1,
        child: GestureDetector(
          onTap: hidden ? null : onTap,
          child: Container(
            height: 64,
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
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              member.hil,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    if (hidden) return IgnorePointer(child: tile);
    return Draggable<String>(
      data: member.hil,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 110, child: tile),
      ),
      childWhenDragging: Opacity(opacity: .35, child: tile),
      child: tile,
    );
  }
}

class _FamilyReferencePhotoActivityStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> members;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyReferencePhotoActivityStep({
    required this.progress,
    required this.members,
    required this.onExit,
    required this.onReplay,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/house.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          top + view.height * .105,
          view.width * .045,
          view.height * .025,
        ),
        child: _FamilyPhotoQuizActivity(
          progress: progress,
          members: members,
          onAttempt: onAttempt,
          onCorrect: onCorrect,
        ),
      ),
    );
  }
}

class _FamilyReferenceBadge extends StatelessWidget {
  final String label;

  const _FamilyReferenceBadge({this.label = 'Family\nFriend'});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: (width * .62).clamp(220.0, 330.0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD94B), width: 5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD94B).withValues(alpha: .55),
            blurRadius: 28,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.blue,
          fontSize: (width * .065).clamp(24.0, 34.0),
          height: .95,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GradeOneUnitTwoLessonFourPicnicFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;
  final VoidCallback onLessonComplete;

  const _GradeOneUnitTwoLessonFourPicnicFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
    required this.onLessonComplete,
  });

  @override
  State<_GradeOneUnitTwoLessonFourPicnicFlow> createState() =>
      _GradeOneUnitTwoLessonFourPicnicFlowState();
}

class _GradeOneUnitTwoLessonFourPicnicFlowState
    extends State<_GradeOneUnitTwoLessonFourPicnicFlow> {
  static const _voiceBase = 'audio/VO-final/grade1';
  static final Map<String, String> _savedPicnicSlots = {};
  static const _members = [
    _FamilyWord(
      hil: 'nanay',
      eng: 'mother',
      imageAsset: 'assets/images/level_game/people/nanay.svg',
      icon: Icons.woman_rounded,
    ),
    _FamilyWord(
      hil: 'tatay',
      eng: 'father',
      imageAsset: 'assets/images/level_game/people/tatay.svg',
      icon: Icons.man_rounded,
    ),
    _FamilyWord(
      hil: 'bata',
      eng: 'child',
      imageAsset: 'assets/images/level_game/people/bata.svg',
      icon: Icons.child_care_rounded,
    ),
    _FamilyWord(
      hil: 'lola',
      eng: 'grandmother',
      imageAsset: 'assets/images/level_game/people/lola.svg',
      icon: Icons.elderly_woman_rounded,
    ),
    _FamilyWord(
      hil: 'lolo',
      eng: 'grandfather',
      imageAsset: 'assets/images/level_game/people/lolo.svg',
      icon: Icons.elderly_rounded,
    ),
  ];

  int _stepIndex = 0;
  final Set<String> _pickedFamily = {};
  final Set<String> _pickedGrandparents = {};
  late final Map<String, String> _picnicSlots = Map.of(_savedPicnicSlots);
  String? _selectedPicnicCard;
  late final List<_FamilyWord> _picnicOptionMembers = _shuffledChoices(
    _members
        .where(
          (member) => const {'nanay', 'tatay', 'bata'}.contains(member.hil),
        )
        .toList(),
  );
  String? _activeCorrectChoice;
  String? _wrongChoice;
  String? _wrongSeat;
  bool _picnicFeedbackActive = false;
  bool _completed = false;

  double get _progress => (_stepIndex + 1) / 8;

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

  void _goToStep(int index) {
    final next = index.clamp(0, 7);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _stepIndex = next;
      _activeCorrectChoice = null;
      _wrongChoice = null;
      _wrongSeat = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _speakForStep() async {
    final clips = switch (_stepIndex) {
      0 => const [2],
      1 => const [3],
      2 => const [4],
      3 => const [4, 5],
      4 => const [9, 11],
      5 => const [12, 13],
      6 => const [18],
      _ => const [21],
    };
    try {
      await _playPicnicVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_stepIndex) {
          0 => 'Nagtipon ang pamilya sa picnic!',
          1 => 'I-tap ang Park sa mapa.',
          2 => 'Kilalahon ta sila.',
          3 => 'Sin-o ang mother kag father?',
          4 => 'Husto! Nanay kag tatay.',
          5 => 'Pangitaa si lola kag si lolo.',
          6 => 'Ibutang sila sa husto nga pulungkuan.',
          _ => 'Kompleto na ang pamilya ni Koka!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  Future<void> _playPicnicVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_1_Les_2_4_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  _FamilyWord _member(String hil) =>
      _members.firstWhere((member) => member.hil == hil);

  Future<void> _chooseFamilyMember(_FamilyWord member) async {
    if (_picnicFeedbackActive) return;
    final required = _stepIndex == 3
        ? const ['nanay', 'tatay']
        : const ['lola', 'lolo'];
    final selected = _stepIndex == 3 ? _pickedFamily : _pickedGrandparents;
    if (selected.contains(member.hil)) return;

    final correct = required.contains(member.hil);
    final expected = required.elementAt(selected.length);
    if (correct && member.hil != expected) {
      setState(() => _wrongChoice = member.hil);
      await AppAudioService.instance.playWrong();
      await _playPicnicVoice(_stepIndex == 3 ? const [10] : const [17]);
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (mounted) setState(() => _wrongChoice = null);
      return;
    }
    final quizIndex = switch (member.hil) {
      'nanay' => 0,
      'tatay' => 1,
      'lola' => 2,
      'lolo' => 3,
      _ => 4,
    };
    widget.onQuizAttempt(quizIndex, correct);

    if (correct) {
      setState(() {
        _activeCorrectChoice = member.hil;
        _wrongChoice = null;
        _picnicFeedbackActive = true;
      });
      widget.onQuizCorrect(quizIndex);
      await AppAudioService.instance.playCorrect();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 480));
      if (!mounted) return;
      setState(() {
        selected.add(member.hil);
        _activeCorrectChoice = null;
        _picnicFeedbackActive = false;
      });
      if (selected.length == required.length) {
        if (_stepIndex == 5) {
          await _playPicnicVoice(const [16]);
        }
        final delay = _stepIndex == 3
            ? const Duration(milliseconds: 260)
            : const Duration(milliseconds: 780);
        await Future<void>.delayed(delay);
        if (mounted) _goToStep(_stepIndex + 1);
      } else {
        final nextTarget = required.elementAt(selected.length);
        await _playPicnicVoice([
          nextTarget == 'tatay'
              ? 6
              : nextTarget == 'lola'
              ? 8
              : nextTarget == 'lolo'
              ? 15
              : 5,
          if (nextTarget == 'tatay') 8,
        ]);
      }
      return;
    }

    setState(() => _wrongChoice = member.hil);
    await AppAudioService.instance.playWrong();
    await _playPicnicVoice(_stepIndex == 3 ? const [10] : const [17]);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) setState(() => _wrongChoice = null);
  }

  Future<void> _placePicnicMember(String slot, String value) async {
    if (_picnicSlots.containsKey(slot) ||
        _picnicSlots.containsValue(value) ||
        _wrongSeat != null ||
        _picnicFeedbackActive) {
      return;
    }
    final correct = slot == value;
    widget.onQuizAttempt(4, correct);
    if (!correct) {
      setState(() {
        _wrongSeat = value;
        _picnicFeedbackActive = true;
      });
      await AppAudioService.instance.playWrong();
      await _playPicnicVoice(const [20]);
      if (mounted) {
        setState(() {
          _wrongSeat = null;
          _selectedPicnicCard = null;
          _picnicFeedbackActive = false;
        });
      }
      return;
    }

    setState(() {
      _picnicSlots[slot] = value;
      _savedPicnicSlots[slot] = value;
      _selectedPicnicCard = null;
      _picnicFeedbackActive = true;
    });
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    if (_picnicSlots.length == 3) {
      widget.onQuizCorrect(4);
      await _playPicnicVoice(const [19]);
    }
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (mounted) setState(() => _picnicFeedbackActive = false);
  }

  void _selectPicnicCard(_FamilyWord member) {
    if (_picnicFeedbackActive ||
        _picnicSlots.containsValue(member.hil) ||
        _wrongSeat != null) {
      return;
    }
    setState(() {
      _selectedPicnicCard = _selectedPicnicCard == member.hil
          ? null
          : member.hil;
    });
  }

  void _placeSelectedPicnicCard(String slot) {
    final selected = _selectedPicnicCard;
    if (selected == null) return;
    unawaited(_placePicnicMember(slot, selected));
  }

  void _finishLesson() {
    if (_completed) return;
    _completed = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
    widget.onLessonComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('g1-u2-l4-picnic-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _PicnicIntroStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(1),
          ),
          1 => _PicnicMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(3),
          ),
          2 => _PicnicSceneScanStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(3),
          ),
          3 => _PicnicMemberGridStep(
            progress: _progress,
            members: _members,
            targetOrder: const ['nanay', 'tatay'],
            selected: _pickedFamily,
            activeCorrectChoice: _activeCorrectChoice,
            wrongChoice: _wrongChoice,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseFamilyMember,
          ),
          4 => _PicnicParentsJoinStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(5),
          ),
          5 => _PicnicMemberGridStep(
            progress: _progress,
            members: _members,
            targetOrder: const ['lola', 'lolo'],
            selected: _pickedGrandparents,
            activeCorrectChoice: _activeCorrectChoice,
            wrongChoice: _wrongChoice,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoose: _chooseFamilyMember,
          ),
          6 => _PicnicArrangeStep(
            progress: _progress,
            members: [_member('nanay'), _member('bata'), _member('tatay')],
            optionMembers: _picnicOptionMembers,
            placements: _picnicSlots,
            selectedCard: _selectedPicnicCard,
            wrongSeat: _wrongSeat,
            inputLocked: _picnicFeedbackActive,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placePicnicMember,
            onSelectCard: _selectPicnicCard,
            onPlaceSelected: _placeSelectedPicnicCard,
            onContinue: () => _goToStep(7),
          ),
          _ => _PicnicRewardStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finishLesson,
          ),
        },
      ),
    );
  }
}

class _PicnicIntroStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _PicnicIntroStep({
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
      backgroundAsset:
          'assets/images/level_game/grade1/backgrounds/lesson4-familypicnic.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .07,
          view.height * .13,
          view.width * .07,
          view.height * .04,
        ),
        child: Column(
          children: [
            const Spacer(),
            _LessonOneMessageCard(message: 'Nagtipon ang pamilya sa picnic!'),
            SizedBox(height: view.height * .022),
            _LessonOneBlueButton(label: 'Sige', onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _PicnicMapStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _PicnicMapStep({
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
            left: view.width * .40,
            top: view.height * .42,
            width: view.width * .26,
            height: view.width * .26,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await AppAudioService.instance.playCorrect();
                onNext();
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TudloColors.green.withValues(alpha: .55),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -view.width * .13,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: TudloColors.blue,
                      size: view.width * .18,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: .9),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.location_on_rounded,
                    color: const Color(0xFFFF4F64),
                    size: view.width * .18,
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

class _PicnicSceneScanStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _PicnicSceneScanStep({
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
      backgroundAsset:
          'assets/images/level_game/grade1/backgrounds/lesson4-familypicnic.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .14,
          view.width * .06,
          view.height * .05,
        ),
        child: Column(
          children: [
            const Spacer(),
            const Spacer(),
            _LessonOneMessageCard(message: 'Kilalahon ta sila.'),
            SizedBox(height: view.height * .02),
            _LessonOneBlueButton(label: 'Sige', onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _PicnicMemberGridStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> members;
  final List<String> targetOrder;
  final Set<String> selected;
  final String? activeCorrectChoice;
  final String? wrongChoice;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(_FamilyWord member) onChoose;

  const _PicnicMemberGridStep({
    required this.progress,
    required this.members,
    required this.targetOrder,
    required this.selected,
    required this.activeCorrectChoice,
    required this.wrongChoice,
    required this.onExit,
    required this.onReplay,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final orderedMembers = [
      for (final name in const ['lolo', 'lola', 'bata', 'nanay', 'tatay'])
        members.firstWhere((member) => member.hil == name),
    ];
    final prompt = 'I-tap si ${_currentTargetLabel()}.';
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/picnic.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          top + view.height * .13,
          view.width * .045,
          view.height * .035,
        ),
        child: Column(
          children: [
            _LessonOneMessageCard(message: prompt),
            SizedBox(height: view.height * .025),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, -view.height * .045),
                  child: SizedBox(
                    width: double.infinity,
                    height: (view.height * .52).clamp(350.0, 480.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (
                          var index = 0;
                          index < orderedMembers.length;
                          index++
                        )
                          _PicnicStandingMemberButton(
                            member: orderedMembers[index],
                            index: index,
                            selected: selected.contains(
                              orderedMembers[index].hil,
                            ),
                            highlighted:
                                activeCorrectChoice ==
                                orderedMembers[index].hil,
                            wrong: wrongChoice == orderedMembers[index].hil,
                            onTap: () => onChoose(orderedMembers[index]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currentTargetLabel() {
    final target = targetOrder.firstWhere(
      (name) => !selected.contains(name),
      orElse: () => targetOrder.last,
    );
    return '${target[0].toUpperCase()}${target.substring(1)}';
  }
}

class _PicnicStandingMemberButton extends StatelessWidget {
  final _FamilyWord member;
  final int index;
  final bool selected;
  final bool highlighted;
  final bool wrong;
  final VoidCallback onTap;

  const _PicnicStandingMemberButton({
    required this.member,
    required this.index,
    required this.selected,
    required this.highlighted,
    required this.wrong,
    required this.onTap,
  });

  static const _alignments = [
    Alignment(-1.6, -.18),
    Alignment(-.78, -.2),
    Alignment(0, -.16),
    Alignment(.78, -.2),
    Alignment(1.6, -.18),
  ];

  static const _sizeFactors = [.42, .42, .37, .43, .43];
  static const _hitWidthFactors = [.48, .48, .52, .48, .48];

  static String _assetFor(String hil) {
    return switch (hil) {
      'lolo' =>
        'assets/images/level_game/grade1/people/Tudlo_Lolo_Full_Body_Exact.svg',
      'lola' =>
        'assets/images/level_game/grade1/people/Tudlo_Lola_Full_Body_Exact.svg',
      'bata' =>
        'assets/images/level_game/grade1/people/Tudlo_Bata_Full_Body_Exact.svg',
      'nanay' =>
        'assets/images/level_game/grade1/people/Tudlo_Nanay_Full_Body_Exact.svg',
      'tatay' =>
        'assets/images/level_game/grade1/people/Tudlo_Tatay_Full_Body_Exact.svg',
      _ => memberFallbackAsset,
    };
  }

  static String get memberFallbackAsset =>
      'assets/images/level_game/people/bata.svg';

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final width = view.width * _sizeFactors[index];
    final height = (view.height * .56).clamp(370.0, 500.0);
    final asset = _assetFor(member.hil);
    return Align(
      alignment: _alignments[index],
      child: SizedBox(
        width: width,
        height: height,
        child: _FeedbackMotion(
          correct: highlighted && !wrong,
          wrong: wrong,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (highlighted && !wrong)
                      Padding(
                        padding: EdgeInsets.only(
                          top: selected ? 0 : height * .025,
                        ),
                        child: _PicnicCharacterGlow(
                          asset: asset,
                          fallbackIcon: member.icon,
                          fallbackSize: width * .75,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: selected ? 0 : height * .025,
                      ),
                      child: _LessonPictureAsset(
                        asset: asset,
                        fit: BoxFit.contain,
                        errorBuilder: (_) => Icon(
                          member.icon,
                          color: TudloColors.forest,
                          size: width * .75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                width: width * _hitWidthFactors[index],
                height: height * .78,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PicnicCharacterGlow extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final double fallbackSize;

  const _PicnicCharacterGlow({
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackSize,
  });

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFFFFD447);
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          _PicnicGlowLayer(
            asset: asset,
            fallbackIcon: fallbackIcon,
            fallbackSize: fallbackSize,
            color: glowColor,
            scale: 1.08,
            blur: 4.5,
            opacity: .78,
          ),
          _PicnicGlowLayer(
            asset: asset,
            fallbackIcon: fallbackIcon,
            fallbackSize: fallbackSize,
            color: glowColor,
            scale: 1.16,
            blur: 11,
            opacity: .44,
          ),
        ],
      ),
    );
  }
}

class _PicnicGlowLayer extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final double fallbackSize;
  final Color color;
  final double scale;
  final double blur;
  final double opacity;

  const _PicnicGlowLayer({
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackSize,
    required this.color,
    required this.scale,
    required this.blur,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: _LessonPictureAsset(
              asset: asset,
              fit: BoxFit.contain,
              errorBuilder: (_) =>
                  Icon(fallbackIcon, color: color, size: fallbackSize),
            ),
          ),
        ),
      ),
    );
  }
}

class _PicnicParentsJoinStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _PicnicParentsJoinStep({
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
      backgroundAsset: 'assets/images/level_game/backgrounds/picnic.svg',
      child: Stack(
        children: [
          Positioned(
            left: -view.width * .05,
            right: -view.width * .05,
            top: view.height * .275,
            height: (view.height * .44).clamp(330.0, 440.0),
            child: _LessonPictureAsset(
              asset:
                  'assets/images/level_game/grade1/people/Tudlo_Nanay_Tatay_Holding_Hands_Picnic.png',
              fit: BoxFit.contain,
              errorBuilder: (_) => Icon(
                Icons.family_restroom_rounded,
                color: TudloColors.forest,
                size: view.width * .32,
              ),
            ),
          ),
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            bottom: view.height * .14,
            child: _LessonOneMessageCard(message: 'Husto! Nanay kag tatay.'),
          ),
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            bottom: view.height * .045,
            child: _LessonOneBlueButton(label: 'Sige', onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _PicnicArrangeStep extends StatelessWidget {
  final double progress;
  final List<_FamilyWord> members;
  final List<_FamilyWord> optionMembers;
  final Map<String, String> placements;
  final String? selectedCard;
  final String? wrongSeat;
  final bool inputLocked;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String slot, String value) onPlace;
  final ValueChanged<_FamilyWord> onSelectCard;
  final ValueChanged<String> onPlaceSelected;
  final VoidCallback onContinue;

  const _PicnicArrangeStep({
    required this.progress,
    required this.members,
    required this.optionMembers,
    required this.placements,
    required this.selectedCard,
    required this.wrongSeat,
    required this.inputLocked,
    required this.onExit,
    required this.onReplay,
    required this.onPlace,
    required this.onSelectCard,
    required this.onPlaceSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final complete = members.every(
      (member) => placements[member.hil] == member.hil,
    );
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/picnic.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .045,
          top + view.height * .13,
          view.width * .045,
          view.height * .035,
        ),
        child: Column(
          children: [
            _LessonOneMessageCard(message: 'Ibutang sila sa ila nga lugar.'),
            SizedBox(height: view.height * .012),
            SizedBox(
              width: double.infinity,
              height: (view.height * .34).clamp(240.0, 340.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  for (var index = 0; index < members.length; index++)
                    Align(
                      alignment: [
                        const Alignment(-.82, .72),
                        const Alignment(0, .78),
                        const Alignment(.82, .72),
                      ][index],
                      child: _PicnicDropSlot(
                        member: members[index],
                        placed:
                            placements[members[index].hil] ==
                            members[index].hil,
                        selected: selectedCard != null,
                        inputLocked: inputLocked,
                        onPlace: onPlace,
                        onTap: () => onPlaceSelected(members[index].hil),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                for (final member in optionMembers)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _PicnicDraggableCard(
                        member: member,
                        enabled:
                            !inputLocked &&
                            placements[member.hil] != member.hil,
                        placed: placements[member.hil] == member.hil,
                        selected: selectedCard == member.hil,
                        wrong: wrongSeat == member.hil,
                        onTap: () => onSelectCard(member),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: view.height * .014),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: complete
                  ? _LessonOneBlueButton(label: 'Sige', onTap: onContinue)
                  : SizedBox(height: (view.height * .075).clamp(58.0, 72.0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PicnicDropSlot extends StatelessWidget {
  final _FamilyWord member;
  final bool placed;
  final bool selected;
  final bool inputLocked;
  final Future<void> Function(String slot, String value) onPlace;
  final VoidCallback onTap;

  const _PicnicDropSlot({
    required this.member,
    required this.placed,
    required this.selected,
    required this.inputLocked,
    required this.onPlace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        if (!inputLocked) onPlace(member.hil, details.data);
      },
      builder: (context, candidates, rejected) {
        final active = selected && !placed && !inputLocked;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: inputLocked ? null : onTap,
          child: SizedBox(
            width: (view.width * .35).clamp(118.0, 158.0),
            height: (view.height * .26).clamp(188.0, 252.0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                if (active)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TudloColors.blue.withValues(alpha: .35),
                          blurRadius: 22,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const SizedBox(width: 62, height: 62),
                  ),
                _PicnicSeatedCharacter(
                  member: member,
                  mode: placed
                      ? _PicnicSeatedCharacterMode.fullColor
                      : _PicnicSeatedCharacterMode.silhouette,
                ),
                if (placed) const Positioned.fill(child: _PicnicSlotSparkle()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Text(
                    member.hil,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: (view.width * .043).clamp(16.0, 21.0),
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: const [
                        Shadow(
                          color: TudloColors.ink,
                          offset: Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PicnicDraggableCard extends StatelessWidget {
  final _FamilyWord member;
  final bool enabled;
  final bool placed;
  final bool selected;
  final bool wrong;
  final VoidCallback onTap;

  const _PicnicDraggableCard({
    required this.member,
    required this.enabled,
    required this.placed,
    required this.selected,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final card = _FeedbackMotion(
      correct: false,
      wrong: wrong,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: placed ? .24 : 1,
        child: _PicnicOptionCard(
          member: member,
          selected: selected,
          onTap: enabled ? onTap : null,
        ),
      ),
    );
    if (!enabled) return card;

    return Draggable<String>(
      data: member.hil,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: view.width * .34,
          child: _PicnicOptionCard(
            member: member,
            selected: true,
            onTap: () {},
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: card),
      child: card,
    );
  }
}

class _PicnicOptionCard extends StatelessWidget {
  final _FamilyWord member;
  final bool selected;
  final VoidCallback? onTap;

  const _PicnicOptionCard({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: (view.height * .18).clamp(140.0, 194.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (selected)
              Positioned(
                bottom: 8,
                child: Container(
                  width: view.width * .17,
                  height: view.width * .17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TudloColors.blue.withValues(alpha: .34),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: _picnicSeatedChoiceScaleFor(member.hil),
                alignment: Alignment.bottomCenter,
                child: _LessonPictureAsset(
                  asset: _picnicSeatedAssetFor(member.hil),
                  fit: BoxFit.contain,
                  errorBuilder: (_) =>
                      Icon(member.icon, color: TudloColors.forest),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PicnicSeatedCharacterMode { silhouette, fullColor }

String _picnicSeatedAssetFor(String hil) {
  return switch (hil) {
    'nanay' =>
      'assets/images/level_game/grade1/people/Tudlo_Nanay_Sitting_Picnic_Exact.svg',
    'bata' =>
      'assets/images/level_game/grade1/people/Tudlo_Bata_Sitting_Picnic_Exact.svg',
    'tatay' =>
      'assets/images/level_game/grade1/people/Tudlo_Tatay_Sitting_Picnic_Exact.svg',
    _ =>
      'assets/images/level_game/grade1/people/Tudlo_Bata_Sitting_Picnic_Exact.svg',
  };
}

double _picnicSeatedScaleFor(String hil) {
  return switch (hil) {
    'nanay' || 'tatay' => 1.12,
    _ => 1,
  };
}

double _picnicSeatedChoiceScaleFor(String hil) {
  return switch (hil) {
    'nanay' || 'tatay' => 1.34,
    _ => 1.18,
  };
}

class _PicnicSeatedCharacter extends StatelessWidget {
  final _FamilyWord member;
  final _PicnicSeatedCharacterMode mode;

  const _PicnicSeatedCharacter({required this.member, required this.mode});

  @override
  Widget build(BuildContext context) {
    final asset = _picnicSeatedAssetFor(member.hil);
    final childScale = _picnicSeatedScaleFor(member.hil);
    if (mode == _PicnicSeatedCharacterMode.fullColor) {
      return Transform.scale(
        scale: childScale,
        alignment: Alignment.bottomCenter,
        child: SvgPicture.asset(
          asset,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      );
    }

    return Transform.scale(
      scale: childScale,
      alignment: Alignment.bottomCenter,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Transform.scale(
            scale: 1.045,
            child: SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            colorFilter: const ColorFilter.mode(
              Color(0xFF8F969B),
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

class _PicnicSlotSparkle extends StatelessWidget {
  const _PicnicSlotSparkle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          final opacity = (1 - value).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                for (final sparkle in const [
                  (Alignment(-.52, -.42), 16.0),
                  (Alignment(.48, -.24), 13.0),
                  (Alignment(-.12, -.70), 11.0),
                ])
                  Align(
                    alignment: sparkle.$1,
                    child: Transform.scale(
                      scale: .65 + value * .7,
                      child: Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFFFE45C),
                        size: sparkle.$2,
                        shadows: const [
                          Shadow(color: Color(0xAA8A5A00), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PicnicRewardStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _PicnicRewardStep({
    required this.progress,
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
      backgroundAsset:
          'assets/images/level_game/grade1/backgrounds/lesson4-familypicnic.svg',
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'PAMILYA'),
        message: 'Kompleto na ang pamilya ni Koka!',
        onDone: onDone,
      ),
    );
  }
}

class _AlphabetFadeStep {
  final Widget child;

  const _AlphabetFadeStep({required this.child});
}
