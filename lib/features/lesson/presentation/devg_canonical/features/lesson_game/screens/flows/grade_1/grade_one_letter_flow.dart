part of '../../level_game_page.dart';

String _letterSoundText(String letter) {
  return switch (letter.trim().toUpperCase()) {
    'A' => 'Ah',
    'E' => 'e',
    'I' => 'i',
    'O' => 'o',
    'U' => 'u',
    'N' => 'n',
    'T' => 't',
    'Y' => 'y',
    'D' => 'd',
    'G' => 'g',
    'K' => 'k',
    'L' => 'l',
    'M' => 'm',
    'P' => 'p',
    'R' => 'r',
    'S' => 's',
    'W' => 'w',
    _ => letter.trim().toLowerCase(),
  };
}

String? _unitOneLetterAsset(String letter) {
  return const {
    'A': 'assets/images/level_game/letters/A.png',
    'B': 'assets/images/level_game/letters/B.png',
    'C': 'assets/images/level_game/letters/C.png',
    'D': 'assets/images/level_game/letters/D.png',
    'E': 'assets/images/level_game/letters/E.png',
    'F': 'assets/images/level_game/letters/F.png',
    'G': 'assets/images/level_game/letters/G.png',
    'H': 'assets/images/level_game/letters/H.png',
    'I': 'assets/images/level_game/letters/I.png',
    'K': 'assets/images/level_game/letters/K.png',
    'L': 'assets/images/level_game/letters/L.png',
    'M': 'assets/images/level_game/letters/M.png',
    'N': 'assets/images/level_game/letters/N.png',
    'O': 'assets/images/level_game/letters/O.png',
    'P': 'assets/images/level_game/letters/P-stage.png',
    'R': 'assets/images/level_game/letters/R.png',
    'S': 'assets/images/level_game/letters/S.png',
    'T': 'assets/images/level_game/letters/T.png',
    'U': 'assets/images/level_game/letters/U.png',
    'W': 'assets/images/level_game/letters/W.png',
    'Y': 'assets/images/level_game/letters/Y.png',
  }[letter.toUpperCase()];
}

String? _unitOneNumberAsset(String number) {
  return const {
    '0': 'assets/images/level_game/numbers/0.png',
    '1': 'assets/images/level_game/numbers/1.png',
    '2': 'assets/images/level_game/numbers/2.png',
    '3': 'assets/images/level_game/numbers/3.png',
    '4': 'assets/images/level_game/numbers/4.png',
    '5': 'assets/images/level_game/numbers/5.png',
    '6': 'assets/images/level_game/numbers/6.png',
    '7': 'assets/images/level_game/numbers/7.png',
    '8': 'assets/images/level_game/numbers/8.png',
    '9': 'assets/images/level_game/numbers/9.png',
    '10': null,
  }[number];
}

class _GradeOneAlphabetLesson extends StatefulWidget {
  final LevelContent content;
  final VoidCallback onExit;
  final ValueChanged<bool> onPresentationChromeChanged;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAlphabetLesson({
    required this.content,
    required this.onExit,
    required this.onPresentationChromeChanged,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneAlphabetLesson> createState() =>
      _GradeOneAlphabetLessonState();
}

class _GradeOneAlphabetLessonState extends State<_GradeOneAlphabetLesson> {
  int _stepIndex = 0;
  late final List<String> _quizTargets;
  bool? _lastPresentationChrome;

  @override
  void initState() {
    super.initState();
    final targets = _targetLettersFor(
      widget.content,
    ).map((target) => target.toUpperCase()).toSet().toList();
    _quizTargets = _shuffledChoices(
      targets.isNotEmpty ? targets : const ['A', 'N', 'T', 'Y'],
    );
  }

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() => _stepIndex = next);
    _notifyPresentationChrome(next);
  }

  void _notifyPresentationChrome([int? stepIndex]) {
    final shouldShow = true;
    if (_lastPresentationChrome == shouldShow) return;
    _lastPresentationChrome = shouldShow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPresentationChromeChanged(shouldShow);
    });
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    _lastPresentationChrome = false;
    widget.onPresentationChromeChanged(false);
    super.dispose();
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _finishQuiz() {
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.unitNumber == 1 && widget.content.lessonNumber == 1) {
      _notifyPresentationChrome();
      return _GradeOneUnitOneLessonOneFlow(
        onExit: widget.onExit,
        onQuizAttempt: widget.onQuizAttempt,
        onQuizCorrect: widget.onQuizCorrect,
      );
    }
    if (widget.content.unitNumber == 1 && widget.content.lessonNumber == 2) {
      _notifyPresentationChrome();
      return _GradeOneUnitOneLessonTwoNumberFlow(
        onExit: widget.onExit,
        onQuizAttempt: widget.onQuizAttempt,
        onQuizCorrect: widget.onQuizCorrect,
      );
    }
    if (widget.content.unitNumber == 1 && widget.content.lessonNumber == 4) {
      _notifyPresentationChrome();
      return _GradeOneUnitOneLessonFourHouseFlow(
        onExit: widget.onExit,
        onQuizAttempt: widget.onQuizAttempt,
        onQuizCorrect: widget.onQuizCorrect,
      );
    }

    final anchors = _alphabetAnchorsFor(widget.content.lessonNumber);
    final targets = _targetLettersFor(widget.content);
    var maxIndex = 0;
    final spellingAnchor = anchors.isNotEmpty
        ? anchors.first
        : const _AlphabetAnchor(
            word: 'NANAY',
            meaning: 'nanay',
            targets: ['N', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/people/nanay.png',
            icon: Icons.family_restroom_rounded,
          );
    final secondTarget = _quizTargets.length > 1
        ? _quizTargets[1]
        : _quizTargets.first;
    final secondAnchor = _bestAnchorForTarget(anchors, secondTarget);
    final animalAnchors = anchors
        .where(
          (anchor) =>
              anchor.imageAsset?.contains('/animals/') == true &&
              anchor.targets.isNotEmpty,
        )
        .toList();
    final quizActivities = [
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-tap-${widget.content.id}'),
        prompt: 'Pamatii ang tingog. Pindoton ang husto nga letra.',
        listenText: _letterSoundText(_quizTargets.first),
        showSpeakerHint: widget.content.lessonNumber == 1,
        progress: 1 / _lessonQuizCount,
        choices: _shuffledChoices([
          _quizTargets.first,
          ..._quizTargets.skip(1).take(2),
        ]),
        answer: _quizTargets.first,
        isLetter: true,
        imageAsset: _bestAnchorForTarget(
          anchors,
          _quizTargets.first,
        ).imageAsset,
        icon: _bestAnchorForTarget(anchors, _quizTargets.first).icon,
        onAttempt: (correct) => widget.onQuizAttempt(0, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneSpellingActivity(
        key: ValueKey('unit1-spell-${widget.content.id}'),
        prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
        progress: 2 / _lessonQuizCount,
        word: spellingAnchor.word,
        imageAsset: spellingAnchor.imageAsset,
        icon: spellingAnchor.icon,
        showDragTutorial:
            widget.content.unitNumber == 1 && widget.content.lessonNumber == 1,
        onAttempt: (correct) => widget.onQuizAttempt(1, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneHiddenSearchActivity(
        key: ValueKey('unit1-search-${widget.content.id}'),
        prompt: 'Unahon ta pangitaon ang letra nga mabatian mo.',
        progress: 3 / _lessonQuizCount,
        targetLetters: _quizTargets,
        onAttempt: (correct) => widget.onQuizAttempt(2, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      animalAnchors.length >= 2
          ? _UnitOneSubjectMatchActivity(
              key: ValueKey('unit1-match-${widget.content.id}'),
              prompt: 'Ipares ang sapat sa iya ngalan.',
              progress: 4 / _lessonQuizCount,
              anchors: animalAnchors,
              onAttempt: (correct) => widget.onQuizAttempt(3, correct),
              onDone: () => _advanceAfterCorrect(maxIndex),
            )
          : _UnitOneTapChoiceActivity(
              key: ValueKey('unit1-second-tap-${widget.content.id}'),
              prompt:
                  'Diin ang letra sang ${secondAnchor.meaning}? Pindoton ang $secondTarget.',
              progress: 4 / _lessonQuizCount,
              choices: _shuffledChoices([
                secondTarget,
                ..._quizTargets.where((item) => item != secondTarget).take(2),
              ]),
              answer: secondTarget,
              isLetter: true,
              imageAsset: secondAnchor.imageAsset,
              icon: secondAnchor.icon,
              onAttempt: (correct) => widget.onQuizAttempt(3, correct),
              onDone: () => _advanceAfterCorrect(maxIndex),
            ),
      _UnitOneDragFillActivity(
        key: ValueKey('unit1-drag-${widget.content.id}'),
        prompt: 'Guyoda ang mga letra para matapos ang tinaga.',
        progress: 5 / _lessonQuizCount,
        word: spellingAnchor.word,
        imageAsset: spellingAnchor.imageAsset,
        icon: spellingAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(4, correct),
        onDone: () {
          _finishQuiz();
          _advanceAfterCorrect(maxIndex);
        },
      ),
    ];

    final introTargets = targets
        .map((target) => target.toUpperCase())
        .toSet()
        .map(
          (target) => MapEntry(target, _bestAnchorForTarget(anchors, target)),
        )
        .toList();

    final presentationTargets = introTargets
        .map(
          (entry) => _AlphabetPresentationTarget.fromAnchor(
            letter: entry.key,
            anchor: _presentationAnchorForTarget(entry.key, entry.value),
          ),
        )
        .toList();
    final presentationSlides = [
      for (var index = 0; index < presentationTargets.length; index++) ...[
        _AlphabetPresentationSlideData(
          target: presentationTargets[index],
          type: _AlphabetPresentationSlideType.letter,
        ),
        if (index == 0)
          _AlphabetPresentationSlideData(
            target: presentationTargets[index],
            type: _AlphabetPresentationSlideType.word,
          ),
        _AlphabetPresentationSlideData(
          target: presentationTargets[index],
          type: _AlphabetPresentationSlideType.highlight,
        ),
        if (_shouldShowSingleContinuePrompt(presentationTargets, index))
          _AlphabetPresentationSlideData(
            target: presentationTargets[index],
            type: _AlphabetPresentationSlideType.continuePrompt,
          ),
      ],
    ];

    _notifyPresentationChrome();

    final steps = [
      for (var index = 0; index < presentationSlides.length; index++)
        _AlphabetFadeStep(
          child: _AlphabetPresentationSlide(
            key: ValueKey('alphabet-presentation-${widget.content.id}-$index'),
            data: presentationSlides[index],
            stepNumber: index + 1,
            totalSteps: presentationSlides.length,
            canGoBack: index > 0,
            onExit: widget.onExit,
            onBack: () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizActivities) _AlphabetFadeStep(child: card),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('alphabet-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: activeStep.child,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _shouldShowSingleContinuePrompt(
    List<_AlphabetPresentationTarget> targets,
    int index,
  ) {
    final nanayNIndex = targets.indexWhere(
      (target) =>
          target.word.toUpperCase() == 'NANAY' &&
          target.letter.toUpperCase() == 'N',
    );
    if (nanayNIndex != -1) return index == nanayNIndex;
    return index == 0;
  }

  _AlphabetAnchor _presentationAnchorForTarget(
    String target,
    _AlphabetAnchor fallback,
  ) {
    if (widget.content.lessonNumber == 1 && target.toUpperCase() == 'Y') {
      return const _AlphabetAnchor(
        word: 'NANAY KAG TATAY',
        meaning: 'nanay kag tatay',
        targets: ['Y'],
        imageAsset: null,
        imageAssets: [
          'assets/images/level_game/people/tatay.png',
          'assets/images/level_game/people/nanay.png',
        ],
        icon: Icons.family_restroom_rounded,
      );
    }
    return fallback;
  }

  List<String> _targetLettersFor(LevelContent content) {
    final titleTargets = RegExp(
      r'\b[A-Z]\b',
    ).allMatches(content.title).map((match) => match.group(0)!).toList();
    if (titleTargets.isNotEmpty) return titleTargets;
    return _alphabetAnchorsFor(
      content.lessonNumber,
    ).expand((anchor) => anchor.targets).toSet().toList();
  }

  _AlphabetAnchor _bestAnchorForTarget(
    List<_AlphabetAnchor> anchors,
    String target, {
    String prompt = '',
  }) {
    if (anchors.isEmpty) {
      return const _AlphabetAnchor(
        word: 'NANAY',
        meaning: 'nanay',
        targets: ['N', 'A', 'Y'],
        imageAsset: 'assets/images/level_game/people/nanay.png',
        icon: Icons.family_restroom_rounded,
      );
    }
    final lowerPrompt = prompt.toLowerCase();
    for (final anchor in anchors) {
      if (lowerPrompt.contains(anchor.word.toLowerCase())) return anchor;
    }
    return anchors.firstWhere(
      (anchor) => anchor.word.contains(target),
      orElse: () => anchors.first,
    );
  }

  List<_AlphabetAnchor> _alphabetAnchorsFor(int lessonNumber) {
    switch (lessonNumber) {
      case 1:
        return const [
          _AlphabetAnchor(
            word: 'NANAY',
            meaning: 'nanay',
            targets: ['N', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/people/nanay.png',
            icon: Icons.family_restroom_rounded,
          ),
          _AlphabetAnchor(
            word: 'TATAY',
            meaning: 'tatay',
            targets: ['T', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/people/tatay.png',
            icon: Icons.family_restroom_rounded,
          ),
        ];
      case 2:
        return const [
          _AlphabetAnchor(
            word: 'IDO',
            meaning: 'ido',
            targets: ['I', 'D', 'O'],
            imageAsset: 'assets/images/level_game/animals/dog.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 3:
        return const [
          _AlphabetAnchor(
            word: 'MANOK',
            meaning: 'manok',
            targets: ['M', 'K'],
            imageAsset: 'assets/images/level_game/animals/chicken.png',
            icon: Icons.egg_alt_rounded,
          ),
          _AlphabetAnchor(
            word: 'KURING',
            meaning: 'kuring',
            targets: ['K', 'U'],
            imageAsset: 'assets/images/level_game/animals/cat.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 4:
        return const [
          _AlphabetAnchor(
            word: 'BALAY',
            meaning: 'balay',
            targets: ['B', 'L'],
            imageAsset: 'assets/images/level_game/house.png',
            icon: Icons.home_rounded,
          ),
          _AlphabetAnchor(
            word: 'LOLA',
            meaning: 'lola',
            targets: ['L'],
            icon: Icons.elderly_woman_rounded,
          ),
          _AlphabetAnchor(
            word: 'ISDA',
            meaning: 'isda',
            targets: ['S'],
            imageAsset: 'assets/images/level_game/animals/fish.png',
            icon: Icons.water_rounded,
          ),
        ];
      case 5:
        return const [
          _AlphabetAnchor(
            word: 'ESKWELAHAN',
            meaning: 'eskwelahan',
            targets: ['E'],
            imageAsset: 'assets/images/level_game/eskwelahan.png',
            icon: Icons.school_rounded,
          ),
          _AlphabetAnchor(
            word: 'GATAS',
            meaning: 'gatas',
            targets: ['G'],
            imageAsset: 'assets/images/level_game/milk.png',
            icon: Icons.local_drink_rounded,
          ),
          _AlphabetAnchor(
            word: 'PAMILYA',
            meaning: 'pamilya',
            targets: ['P'],
            imageAsset: 'assets/images/level_game/people/pamilya.png',
            icon: Icons.diversity_3_rounded,
          ),
        ];
      case 6:
      default:
        return const [
          _AlphabetAnchor(
            word: 'DOKTOR',
            meaning: 'doktor',
            targets: ['R'],
            imageAsset: 'assets/images/level_game/people/doktor.png',
            icon: Icons.medical_services_rounded,
          ),
          _AlphabetAnchor(
            word: 'HOSPITAL',
            meaning: 'ospital',
            targets: ['H'],
            imageAsset: 'assets/images/level_game/ospital.png',
            icon: Icons.local_hospital_rounded,
          ),
          _AlphabetAnchor(
            word: 'KARBAW',
            meaning: 'karbaw',
            targets: ['W'],
            imageAsset: 'assets/images/level_game/animals/carabao.png',
            icon: Icons.agriculture_rounded,
          ),
        ];
    }
  }
}

class _AlphabetAnchor {
  final String word;
  final String meaning;
  final List<String> targets;
  final String? imageAsset;
  final List<String> imageAssets;
  final IconData icon;

  const _AlphabetAnchor({
    required this.word,
    required this.meaning,
    required this.targets,
    required this.icon,
    this.imageAsset,
    this.imageAssets = const [],
  });
}

List<_AlphabetAnchor> _unitOneAlphabetAnchorsFor(int lessonNumber) {
  switch (lessonNumber) {
    case 1:
      return const [
        _AlphabetAnchor(
          word: 'NANAY',
          meaning: 'nanay',
          targets: ['N', 'A', 'Y'],
          imageAsset: 'assets/images/level_game/people/nanay.png',
          icon: Icons.family_restroom_rounded,
        ),
        _AlphabetAnchor(
          word: 'TATAY',
          meaning: 'tatay',
          targets: ['T', 'A', 'Y'],
          imageAsset: 'assets/images/level_game/people/tatay.png',
          icon: Icons.family_restroom_rounded,
        ),
      ];
    case 2:
      return const [
        _AlphabetAnchor(
          word: 'IDO',
          meaning: 'ido',
          targets: ['I', 'D', 'O'],
          imageAsset: 'assets/images/level_game/animals/dog.png',
          icon: Icons.pets_rounded,
        ),
      ];
    case 3:
      return const [
        _AlphabetAnchor(
          word: 'MANOK',
          meaning: 'manok',
          targets: ['M', 'K'],
          imageAsset: 'assets/images/level_game/animals/chicken.png',
          icon: Icons.egg_alt_rounded,
        ),
        _AlphabetAnchor(
          word: 'KURING',
          meaning: 'kuring',
          targets: ['K', 'U'],
          imageAsset: 'assets/images/level_game/animals/cat.png',
          icon: Icons.pets_rounded,
        ),
      ];
    case 4:
      return const [
        _AlphabetAnchor(
          word: 'BALAY',
          meaning: 'balay',
          targets: ['B', 'L'],
          imageAsset: 'assets/images/level_game/house.png',
          icon: Icons.home_rounded,
        ),
        _AlphabetAnchor(
          word: 'LOLA',
          meaning: 'lola',
          targets: ['L'],
          icon: Icons.elderly_woman_rounded,
        ),
        _AlphabetAnchor(
          word: 'ISDA',
          meaning: 'isda',
          targets: ['S'],
          imageAsset: 'assets/images/level_game/animals/fish.png',
          icon: Icons.water_rounded,
        ),
      ];
    case 5:
      return const [
        _AlphabetAnchor(
          word: 'ESKWELAHAN',
          meaning: 'eskwelahan',
          targets: ['E'],
          imageAsset: 'assets/images/level_game/eskwelahan.png',
          icon: Icons.school_rounded,
        ),
        _AlphabetAnchor(
          word: 'GATAS',
          meaning: 'gatas',
          targets: ['G'],
          imageAsset: 'assets/images/level_game/milk.png',
          icon: Icons.local_drink_rounded,
        ),
        _AlphabetAnchor(
          word: 'PAMILYA',
          meaning: 'pamilya',
          targets: ['P'],
          imageAsset: 'assets/images/level_game/people/pamilya.png',
          icon: Icons.diversity_3_rounded,
        ),
      ];
    case 6:
    default:
      return const [
        _AlphabetAnchor(
          word: 'DOKTOR',
          meaning: 'doktor',
          targets: ['R'],
          imageAsset: 'assets/images/level_game/people/doktor.png',
          icon: Icons.medical_services_rounded,
        ),
        _AlphabetAnchor(
          word: 'HOSPITAL',
          meaning: 'ospital',
          targets: ['H'],
          imageAsset: 'assets/images/level_game/ospital.png',
          icon: Icons.local_hospital_rounded,
        ),
        _AlphabetAnchor(
          word: 'KARBAW',
          meaning: 'karbaw',
          targets: ['W'],
          imageAsset: 'assets/images/level_game/animals/carabao.png',
          icon: Icons.agriculture_rounded,
        ),
      ];
  }
}

class _GradeOneUnitOneLessonOneFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitOneLessonOneFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitOneLessonOneFlow> createState() =>
      _GradeOneUnitOneLessonOneFlowState();
}

class _GradeOneUnitOneLessonOneFlowState
    extends State<_GradeOneUnitOneLessonOneFlow> {
  static const _voiceBase = 'audio/VO-final/grade1';
  static const _letters = ['A', 'N', 'T'];
  static const _choiceQuestions = [
    _LessonOneChoiceQuestion(
      word: 'NANAY',
      answer: 'N',
      prompt: 'Ano ang una nga letra sang nanay?',
      imageAsset:
          'assets/images/level_game/grade1/people/Tudlo_Nanay_Half_Body_Exact.svg',
      highlightIndex: 0,
    ),
  ];
  static const _arrangeQuestions = [
    _LessonOneArrangeQuestion(
      prompt: 'Ihan-ay ang N, A, kag T.',
      word: 'NAT',
      fixedLetters: {},
      missingLetters: ['N', 'A', 'T'],
    ),
  ];
  int _stepIndex = 0;
  final List<String> _foundLetters = [];
  String? _selectedChoice;
  final List<String> _arrangedLetters = [];
  String? _wrongLetter;
  int _choiceIndex = 0;
  int _arrangeIndex = 0;
  bool _completed = false;

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

  double get _progress => (_stepIndex + 1) / 6;

  void _goToStep(int index) {
    final next = index.clamp(0, 5);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() {
      _stepIndex = next;
      _selectedChoice = null;
      _wrongLetter = null;
      if (next == 3) _choiceIndex = 0;
      if (next == 4) {
        _arrangeIndex = 0;
        _arrangedLetters.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _speakForStep() async {
    final assets = switch (_stepIndex) {
      0 => const [2],
      1 => const [3],
      2 => const [4, 8],
      3 => const [9],
      4 => const [12, 13],
      _ => const [14],
    };
    try {
      await _playLessonOneVoice(assets);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_stepIndex) {
          0 => 'Ay! Nadula ang A, N, kag T. Buligi ako mangita.',
          1 => 'I-tap ang eskwelahan sa mapa. Didto ta mangita.',
          2 => 'Pangitaa ang tatlo ka card sang letra.',
          3 => _choiceQuestions[_choiceIndex].prompt,
          4 => _arrangeQuestions[_arrangeIndex].prompt,
          _ => 'Yehey! Nabalik na ang mga letra!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  Future<void> _playLessonOneVoice(List<int> clipNumbers) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clipNumbers) '$_voiceBase/Gr_1_Les_1_1_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  int? _letterSearchVoiceClip(String letter) {
    return switch (letter) {
      'A' => 5,
      'N' => 6,
      'T' => 7,
      _ => null,
    };
  }

  Future<void> _tapFoundLetter(String letter) async {
    final clip = _letterSearchVoiceClip(letter);
    if (_foundLetters.contains(letter)) {
      if (clip != null) {
        await _playLessonOneVoice([clip]);
      }
      return;
    }
    widget.onQuizAttempt(0, true);
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() => _foundLetters.add(letter));
    if (clip != null) {
      await _playLessonOneVoice([clip]);
    }
  }

  Future<void> _chooseFirstLetter(String letter) async {
    if (_selectedChoice != null) return;
    final question = _choiceQuestions[_choiceIndex];
    final correct = letter == question.answer;
    final quizIndex = math.min(_choiceIndex + 1, _lessonQuizCount - 1);
    widget.onQuizAttempt(quizIndex, correct);
    setState(() {
      _selectedChoice = letter;
      _wrongLetter = correct ? null : letter;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (correct) {
      await _playLessonOneVoice([10]);
      if (!mounted) return;
      widget.onQuizCorrect(quizIndex);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      if (_choiceIndex >= _choiceQuestions.length - 1) {
        _goToStep(4);
      } else {
        setState(() {
          _choiceIndex++;
          _selectedChoice = null;
          _wrongLetter = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _speakForStep();
        });
      }
    } else {
      await _playLessonOneVoice([11]);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        setState(() {
          _selectedChoice = null;
          _wrongLetter = null;
        });
      }
    }
  }

  Future<void> _addArrangeLetter(String letter) async {
    final question = _arrangeQuestions[_arrangeIndex];
    if (_arrangedLetters.length >= question.missingLetters.length) {
      return;
    }
    final expectedLetter = question.missingLetters[_arrangedLetters.length];
    final correct = letter == expectedLetter;
    widget.onQuizAttempt(_lessonQuizCount - 1, correct);
    if (!correct) {
      setState(() => _wrongLetter = letter);
      await AppAudioService.instance.playWrong();
      if (!mounted) return;
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) setState(() => _wrongLetter = null);
      return;
    }
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() {
      _arrangedLetters.add(letter);
      _wrongLetter = null;
    });
    if (_arrangedLetters.length == question.missingLetters.length) {
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      if (_arrangeIndex >= _arrangeQuestions.length - 1) {
        widget.onQuizCorrect(_lessonQuizCount - 1);
        _goToStep(5);
      } else {
        setState(() {
          _arrangeIndex++;
          _arrangedLetters.clear();
          _wrongLetter = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _speakForStep();
        });
      }
    }
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
        key: ValueKey('g1-u1-l1-flow-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _LessonOneIntroStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(1),
          ),
          1 => _LessonOneMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _LessonOneSearchStep(
            progress: _progress,
            letters: _letters,
            foundLetters: _foundLetters,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onLetterTap: _tapFoundLetter,
            onNext: _foundLetters.length == _letters.length
                ? () => _goToStep(3)
                : null,
          ),
          3 => _LessonOneChoiceStep(
            progress: _progress,
            question: _choiceQuestions[_choiceIndex],
            choices: _letters,
            selected: _selectedChoice,
            wrongLetter: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoice: _chooseFirstLetter,
          ),
          4 => _LessonOneArrangeStep(
            progress: _progress,
            question: _arrangeQuestions[_arrangeIndex],
            arrangedLetters: _arrangedLetters,
            wrongLetter: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onLetterTap: _addArrangeLetter,
          ),
          _ => _LessonOneRewardStep(
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

class _LessonOneChoiceQuestion {
  final String word;
  final String answer;
  final String prompt;
  final String imageAsset;
  final int highlightIndex;

  const _LessonOneChoiceQuestion({
    required this.word,
    required this.answer,
    required this.prompt,
    required this.imageAsset,
    required this.highlightIndex,
  });
}

class _LessonOneArrangeQuestion {
  final String prompt;
  final String word;
  final Map<int, String> fixedLetters;
  final List<String> missingLetters;

  const _LessonOneArrangeQuestion({
    required this.prompt,
    required this.word,
    required this.fixedLetters,
    required this.missingLetters,
  });
}

class _LessonOneChrome extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;
  final String backgroundAsset;
  final BoxFit backgroundFit;

  const _LessonOneChrome({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.child,
    this.backgroundAsset =
        'assets/images/level_game/lesson-game-assets/levelgame-bg.png',
    this.backgroundFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final buttonSize = math
        .min(view.width * .14, view.height * .074)
        .clamp(48.0, 68.0)
        .toDouble();
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LessonBackgroundAsset(asset: backgroundAsset, fit: backgroundFit),
          child,
          Positioned(
            left: view.width * .055,
            top: safeTop + view.height * .025,
            child: _PresentationImageButton(
              asset: '$_assetBase/exit-page.png',
              size: buttonSize,
              onTap: onExit,
              tooltip: 'Balik',
            ),
          ),
          Positioned(
            left: view.width * .30,
            right: view.width * .30,
            top: safeTop + view.height * .047,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1).toDouble(),
                minHeight: (view.height * .018).clamp(12.0, 20.0),
                backgroundColor: Colors.white,
                color: TudloColors.green,
              ),
            ),
          ),
          Positioned(
            right: view.width * .06,
            top: safeTop + view.height * .022,
            child: _ClassroomRoundSpeakerButton(
              size: buttonSize * 1.05,
              onTap: onReplay,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonOneBlueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _LessonOneBlueButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () async {
              await AppAudioService.instance.playTap();
              onTap!();
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onTap == null ? .48 : 1,
        child: Container(
          width: double.infinity,
          height: (width * .145).clamp(56.0, 72.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TudloColors.blue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .22),
                blurRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: (width * .075).clamp(26.0, 36.0),
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonBackgroundAsset extends StatelessWidget {
  final String asset;
  final BoxFit fit;

  const _LessonBackgroundAsset({required this.asset, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(asset, fit: fit, alignment: Alignment.center);
    }

    return Image.asset(
      asset,
      fit: fit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
    );
  }
}

class _LessonPictureAsset extends StatelessWidget {
  final String asset;
  final BoxFit fit;
  final Widget Function(BuildContext context)? errorBuilder;

  const _LessonPictureAsset({
    required this.asset,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        fit: fit,
        alignment: Alignment.center,
        placeholderBuilder: errorBuilder,
      );
    }

    return Image.asset(
      asset,
      fit: fit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: errorBuilder == null
          ? null
          : (_, __, ___) => errorBuilder!(context),
    );
  }
}

class _LessonOneIntroStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _LessonOneIntroStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  // The mascot/question-marks/mystery-card stage's "natural" size and
  // offsets, evaluated once at the app's own 412x917 reference composition
  // (AGENTS.md baseline) from what used to be pure view.width/view.height
  // fractions. Wrapping this fixed-size stage in FittedBox(scaleDown) below
  // reproduces the original design pixel-for-pixel at 412x917 and anything
  // larger/taller, and only shrinks it uniformly on shorter/narrower
  // screens -- fits every frame without ever needing to scroll or overflow.
  static const _stageWidth = 412.0 * .86; // content width after .07 padding
  static const _stageHeight = 917.0 * .45;
  static const _mascotLeft = -412.0 * .08;
  static const _mascotSize = 412.0 * .72; // within the 275-380 clamp range
  static const _questionLeft = 412.0 * .40;
  static const _questionTop = 917.0 * .02;
  static const _questionSize = 412.0 * .18;
  static const _cardsRight = 412.0 * .03;
  static const _cardsBottom = 917.0 * .02;

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/lesson1-popup.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .07,
          view.height * .14,
          view.width * .07,
          view.height * .045,
        ),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: _stageWidth,
                    height: _stageHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: _mascotLeft,
                          bottom: 0,
                          child: _LessonKokaMascot(
                            size: _mascotSize,
                            mood: KokaMood.idle,
                          ),
                        ),
                        Positioned(
                          left: _questionLeft,
                          top: _questionTop,
                          child: _LessonOneQuestionMarks(size: _questionSize),
                        ),
                        Positioned(
                          right: _cardsRight,
                          bottom: _cardsBottom,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LessonOneMysteryCard(compact: true),
                              SizedBox(width: 9),
                              _LessonOneMysteryCard(compact: true),
                              SizedBox(width: 9),
                              _LessonOneMysteryCard(compact: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: view.height * .03),
            const _LessonOneMessageCard(message: 'Ay! Nadula ang A, N, kag T.'),
            SizedBox(height: view.height * .025),
            _LessonOneBlueButton(label: 'Sige', onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _LessonOneMapStep extends StatefulWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _LessonOneMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_LessonOneMapStep> createState() => _LessonOneMapStepState();
}

class _LessonOneMapStepState extends State<_LessonOneMapStep> {
  // Pushes Tudlo's one real Map screen -- the same MapScreen the Map tab
  // uses -- instead of rebuilding a second map widget around the bare Rive
  // scene. Its own standalone MapEventOverrides (not MapProgressScope's
  // shared instance) glows only School for the length of this push and
  // pops back into this lesson step once School is tapped; every other
  // location keeps its real unlocked/locked behavior untouched.
  final _overrides = tudlo_map.MapEventOverrides()
    ..setOverride(
      tudlo_map.MapLocation.school,
      const tudlo_map.PopMapRouteAction(),
    );
  var _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openMap());
  }

  Future<void> _openMap() async {
    if (_opened || !mounted) return;
    _opened = true;
    await _showMapBeatInstructionDialog(
      context,
      message: 'I-tap ang eskwelahan sa mapa. Didto ta mangita.',
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      FadePageRoute<void>(
        page: tudlo_map.MapScreen(
          eventOverrides: _overrides,
          temporaryUnlockedLocations: const {tudlo_map.MapLocation.school},
        ),
      ),
    );
    if (!mounted) return;
    await AppAudioService.instance.playCorrect();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      child: const SizedBox.shrink(),
    );
  }
}

/// Instruction dialog shown right before a lesson pushes the real
/// [tudlo_map.MapScreen] for its "tap the map" beat -- the standard fix
/// pattern from `docs/LESSON_MAP_STEP_FIX.md`. The real map has no room for
/// an in-scene message card the way the old fake-pin placeholder did, so
/// this dialog is the visual instruction; `_speakForStep` still narrates
/// the same beat through its normal voice-over/TTS seam independently.
Future<void> _showMapBeatInstructionDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LessonOneMessageCard(message: message),
          const SizedBox(height: 16),
          _LessonOneBlueButton(
            label: 'Sige',
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    ),
  );
}

// Still used as the fake/decorative map pin by other lesson flows in this
// library (grade_one_family_flow, grade_two_new_friend_flow,
// grade_two_birthday_flow, grade_two_park_greeting_flow,
// grade_two_park_dialogue_flow) even though _LessonOneMapStep above and
// _BeachMapStep in grade_one_greeting_flow.dart no longer use it -- these
// `part of` files share one library namespace, so this "private" class is
// shared library-wide, not exclusive to this file. Do not delete without
// checking every flow.
class _LessonOneMapDestinationCue extends StatefulWidget {
  const _LessonOneMapDestinationCue();

  @override
  State<_LessonOneMapDestinationCue> createState() =>
      _LessonOneMapDestinationCueState();
}

class _LessonOneMapDestinationCueState
    extends State<_LessonOneMapDestinationCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + t * .12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD33D).withValues(alpha: .75),
                      blurRadius: 28,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: TudloColors.blue.withValues(alpha: .35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -42 - (t * 10),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: TudloColors.blue,
                size: 72,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: .9),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LessonOneSearchStep extends StatelessWidget {
  final double progress;
  final List<String> letters;
  final List<String> foundLetters;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String letter) onLetterTap;
  final VoidCallback? onNext;

  const _LessonOneSearchStep({
    required this.progress,
    required this.letters,
    required this.foundLetters,
    required this.onExit,
    required this.onReplay,
    required this.onLetterTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final letterSize = (view.width * .25).clamp(92.0, 138.0).toDouble();
    final positions = {
      'A': Rect.fromLTWH(view.width * .13, view.height * .58, 1, 1),
      'N': Rect.fromLTWH(view.width * .68, top + view.height * .34, 1, 1),
      'T': Rect.fromLTWH(view.width * .47, view.height * .68, 1, 1),
    };
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/classroom.svg',
      child: Stack(
        children: [
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            top: top + view.height * .125,
            child: const _LessonOneMessageCard(
              message: 'Pangitaa ang tatlo ka card sang letra.',
            ),
          ),
          for (final letter in letters)
            Positioned(
              left: positions[letter]!.left,
              top: positions[letter]!.top,
              child: _LessonOneHotspotLetter(
                letter: letter,
                size: letterSize,
                found: foundLetters.contains(letter),
                onTap: () => onLetterTap(letter),
              ),
            ),
          Positioned(
            left: -view.width * .08,
            top: top + view.height * .20,
            child: _LessonKokaMascot(
              size: (view.width * .66).clamp(260.0, 360.0),
              mood: KokaMood.idle,
            ),
          ),
          Positioned(
            left: view.width * .035,
            right: view.width * .035,
            bottom: view.height * .02,
            child: _LessonOneSearchTray(
              letters: letters,
              foundLetters: foundLetters,
              onNext: onNext,
              onLetterTap: onLetterTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonOneChoiceStep extends StatelessWidget {
  final double progress;
  final _LessonOneChoiceQuestion question;
  final List<String> choices;
  final String? selected;
  final String? wrongLetter;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String letter) onChoice;

  const _LessonOneChoiceStep({
    required this.progress,
    required this.question,
    required this.choices,
    required this.selected,
    required this.wrongLetter,
    required this.onExit,
    required this.onReplay,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/classroom.svg',
      child: Center(
        child: Container(
          width: view.width * .86,
          padding: EdgeInsets.symmetric(
            horizontal: view.width * .05,
            vertical: view.height * .032,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E6).withValues(alpha: .96),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: (view.height * .25).clamp(180.0, 275.0),
                child: _LessonPictureAsset(
                  asset: question.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_) => Icon(
                    Icons.family_restroom_rounded,
                    color: TudloColors.forest,
                    size: view.width * .20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _LessonOneHighlightedWord(
                word: question.word,
                highlightIndex: selected == question.answer
                    ? question.highlightIndex
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                question.prompt,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: (view.width * .06).clamp(22.0, 30.0),
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: view.height * .03),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final letter in choices)
                    _LessonOneChoiceLetter(
                      letter: letter,
                      selected:
                          selected == letter && selected == question.answer,
                      wrong: wrongLetter == letter,
                      onTap: () => onChoice(letter),
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

class _LessonOneArrangeStep extends StatelessWidget {
  final double progress;
  final _LessonOneArrangeQuestion question;
  final List<String> arrangedLetters;
  final String? wrongLetter;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(String letter) onLetterTap;

  const _LessonOneArrangeStep({
    required this.progress,
    required this.question,
    required this.arrangedLetters,
    required this.wrongLetter,
    required this.onExit,
    required this.onReplay,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/classroom.svg',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .07,
          view.height * .14,
          view.width * .07,
          view.height * .04,
        ),
        child: Column(
          children: [
            _LessonOneMessageCard(message: question.prompt),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _LessonOneArrangeSlots(
                    question: question,
                    letters: arrangedLetters,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final letter in const ['N', 'A', 'T'])
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _LessonOneDraggableLetter(
                            letter: letter,
                            used: arrangedLetters.contains(letter),
                            wrong: wrongLetter == letter,
                            onTap: () => onLetterTap(letter),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonOneRewardStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _LessonOneRewardStep({
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
      backgroundAsset: 'assets/images/level_game/backgrounds/classroom.svg',
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'LETTER\nFINDER'),
        message: 'Yehey! Nabalik na ang mga letra!',
        onDone: onDone,
      ),
    );
  }
}

class _StickerUnlockRewardContent extends StatefulWidget {
  final Widget fallback;
  final String message;
  final String buttonLabel;
  final VoidCallback onDone;

  const _StickerUnlockRewardContent({
    required this.fallback,
    required this.message,
    this.buttonLabel = 'OK',
    required this.onDone,
  });

  @override
  State<_StickerUnlockRewardContent> createState() =>
      _StickerUnlockRewardContentState();
}

class _StickerUnlockRewardContentState
    extends State<_StickerUnlockRewardContent> {
  late final String _selectedStickerAsset = _activeLessonStickerAsset();

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final landscapeSticker = AppData.selectedGradeLevel == GradeLevel.grade3;
    const portraitStickerRatio = 60 / 118;
    final stickerWidth = landscapeSticker
        ? (view.width * .74).clamp(230.0, 340.0).toDouble()
        : (view.width * .56).clamp(190.0, 270.0).toDouble();
    final stickerHeight = landscapeSticker
        ? stickerWidth * .64
        : stickerWidth / portraitStickerRatio;
    final glowWidth = stickerWidth * 1.24;
    final glowHeight = stickerHeight * (landscapeSticker ? 1.42 : 1.2);
    final stickerRadius = landscapeSticker ? 12.0 : 22.0;
    final stickerFit = landscapeSticker ? BoxFit.contain : BoxFit.cover;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: .56)),
        ),
        Align(
          alignment: const Alignment(0, -.08),
          child: GestureDetector(
            onTap: widget.onDone,
            child: SizedBox(
              width: glowWidth,
              height: glowHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: glowWidth,
                    height: glowHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: RadialGradient(
                          radius: .84,
                          colors: [
                            const Color(0xFFFFF0A8).withValues(alpha: .48),
                            const Color(0xFFFFD33D).withValues(alpha: .25),
                            Colors.transparent,
                          ],
                          stops: const [0, .50, 1],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: stickerWidth,
                    height: stickerHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(stickerRadius),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFF3A6,
                            ).withValues(alpha: .66),
                            blurRadius: 26,
                            spreadRadius: 7,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFFFFB800,
                            ).withValues(alpha: .35),
                            blurRadius: 48,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: stickerWidth,
                    height: stickerHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(stickerRadius),
                      child: _StickerRewardAsset(
                        asset: _selectedStickerAsset,
                        fit: stickerFit,
                        fallback: widget.fallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: view.width * .08,
          right: view.width * .08,
          top: view.height * .13,
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: (view.width * .064).clamp(23.0, 34.0),
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  color: TudloColors.ink,
                  offset: Offset(0, 3),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: view.width * .14,
          right: view.width * .14,
          bottom: view.height * .055,
          child: _StickerUnlockOkButton(
            label: widget.buttonLabel,
            onTap: widget.onDone,
          ),
        ),
      ],
    );
  }
}

class _StickerUnlockOkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StickerUnlockOkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD431), Color(0xFFFFA300)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6E4B00), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 34,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: const [
              Shadow(color: TudloColors.ink, offset: Offset(0, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerRewardAsset extends StatelessWidget {
  static final Map<String, Future<Uint8List?>> _embeddedImageCache = {};

  final String asset;
  final BoxFit fit;
  final Widget? fallback;

  const _StickerRewardAsset({
    required this.asset,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  static Future<Uint8List?> _loadEmbeddedImage(String asset) {
    return _embeddedImageCache.putIfAbsent(asset, () async {
      if (!asset.toLowerCase().endsWith('.svg')) return null;
      final svg = await rootBundle.loadString(asset);
      final match = RegExp(
        r'(?:xlink:href|href)="data:image/[^;]+;base64,([^"]+)"',
        dotAll: true,
      ).firstMatch(svg);
      final encoded = match?.group(1);
      if (encoded == null || encoded.isEmpty) return null;
      return base64Decode(encoded.replaceAll(RegExp(r'\s+'), ''));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!asset.toLowerCase().endsWith('.svg')) {
      return Image.asset(
        asset,
        fit: fit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: fallback == null ? null : (_, __, ___) => fallback!,
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _loadEmbeddedImage(asset),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: fit,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          );
        }

        if (snapshot.hasError && fallback != null) return fallback!;
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        return SvgPicture.asset(
          asset,
          fit: fit,
          alignment: Alignment.center,
          placeholderBuilder: fallback == null ? null : (_) => fallback!,
        );
      },
    );
  }
}

class _LessonOneMessageCard extends StatelessWidget {
  final String message;
  final bool compact;
  final double? fontSize;

  const _LessonOneMessageCard({
    required this.message,
    this.compact = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 22,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
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
          fontSize:
              fontSize ?? (width * (compact ? .064 : .074)).clamp(22.0, 38.0),
          height: 1.12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LessonOneMysteryCard extends StatelessWidget {
  final bool compact;

  const _LessonOneMysteryCard({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = (width * (compact ? .155 : .20)).clamp(
      compact ? 50.0 : 66.0,
      compact ? 68.0 : 90.0,
    );
    return Container(
      width: size,
      height: size * 1.22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: .65),
          width: 2.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Text(
        '?',
        style: GoogleFonts.nunito(
          color: Colors.grey,
          fontSize: size * .50,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LessonOneQuestionMarks extends StatelessWidget {
  final double size;

  const _LessonOneQuestionMarks({required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '?',
          style: GoogleFonts.nunito(
            color: TudloColors.blue,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        Text(
          '?',
          style: GoogleFonts.nunito(
            color: TudloColors.blue,
            fontSize: size * .72,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LessonOneSearchTraySlot extends StatelessWidget {
  final String letter;
  final bool found;
  final double size;
  final Future<void> Function()? onTap;

  const _LessonOneSearchTraySlot({
    required this.letter,
    required this.found,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: found && onTap != null ? () => unawaited(onTap!()) : null,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .56),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.withValues(alpha: .55),
            width: 2,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: found ? 1 : 0,
          child: Text(
            letter,
            style: GoogleFonts.nunito(
              color: TudloColors.blue,
              fontSize: size * .58,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonOneHotspotLetter extends StatelessWidget {
  final String letter;
  final double size;
  final bool found;
  final Future<void> Function() onTap;

  const _LessonOneHotspotLetter({
    required this.letter,
    required this.size,
    required this.found,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (found) return const SizedBox.shrink();

    return GestureDetector(
      onTap: found ? null : () => unawaited(onTap()),
      child: _IntroLetterArt(letter: letter, size: size),
    );
  }
}

class _LessonOneHighlightedWord extends StatelessWidget {
  final String word;
  final int? highlightIndex;

  const _LessonOneHighlightedWord({required this.word, this.highlightIndex});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = (width * .115).clamp(42.0, 64.0);
    return RichText(
      text: TextSpan(
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        children: [
          for (var index = 0; index < word.length; index++)
            TextSpan(
              text: word[index],
              style: TextStyle(
                color: index == highlightIndex
                    ? TudloColors.blue
                    : TudloColors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonOneSearchTray extends StatelessWidget {
  final List<String> letters;
  final List<String> foundLetters;
  final VoidCallback? onNext;
  final Future<void> Function(String letter) onLetterTap;

  const _LessonOneSearchTray({
    required this.letters,
    required this.foundLetters,
    required this.onNext,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final trayHeight = (view.height * .125).clamp(94.0, 128.0).toDouble();
    final slotSize = (view.width * .17).clamp(58.0, 78.0).toDouble();
    final arrowSize = (view.width * .18).clamp(64.0, 88.0).toDouble();

    return Container(
      height: trayHeight,
      padding: EdgeInsets.symmetric(
        horizontal: view.width * .035,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var index = 0; index < letters.length; index++)
                  _LessonOneSearchTraySlot(
                    letter: index < foundLetters.length
                        ? foundLetters[index]
                        : '',
                    found: index < foundLetters.length,
                    size: slotSize,
                    onTap: index < foundLetters.length
                        ? () => onLetterTap(foundLetters[index])
                        : null,
                  ),
              ],
            ),
          ),
          SizedBox(width: view.width * .018),
          _PresentationImageButton(
            asset:
                'assets/images/level_game/lesson-game-assets/next-lesson.png',
            size: arrowSize,
            enabled: onNext != null,
            tooltip: 'Padayon',
            onTap: onNext ?? () {},
          ),
        ],
      ),
    );
  }
}

class _LessonOneChoiceLetter extends StatelessWidget {
  final String letter;
  final bool selected;
  final bool wrong;
  final Future<void> Function() onTap;

  const _LessonOneChoiceLetter({
    required this.letter,
    required this.selected,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * .19).clamp(64.0, 92.0);
    return _FeedbackMotion(
      correct: selected && !wrong,
      wrong: wrong,
      child: GestureDetector(
        onTap: () => unawaited(onTap()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected && !wrong
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected && !wrong
                  ? TudloColors.green
                  : TudloColors.blue.withValues(alpha: .55),
              width: 3,
            ),
            boxShadow: [
              if (selected && !wrong)
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .36),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Text(
            letter,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: size * .62,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonOneArrangeSlots extends StatelessWidget {
  final _LessonOneArrangeQuestion question;
  final List<String> letters;

  const _LessonOneArrangeSlots({required this.question, required this.letters});

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * .23).clamp(82.0, 114.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < question.word.length; i++) ...[
            _LessonOneArrangeSlot(
              letter: question.fixedLetters[i] ?? _placedLetterForSlot(i),
              size: size,
              fixed: question.fixedLetters.containsKey(i),
              filled:
                  question.fixedLetters.containsKey(i) ||
                  _placedLetterForSlot(i).isNotEmpty,
            ),
            if (i != question.word.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  String _placedLetterForSlot(int wordIndex) {
    var missingBefore = 0;
    for (var i = 0; i <= wordIndex; i++) {
      if (!question.fixedLetters.containsKey(i)) missingBefore++;
    }
    final placedIndex = missingBefore - 1;
    if (placedIndex < 0 || placedIndex >= letters.length) return '';
    return letters[placedIndex];
  }
}

class _LessonOneArrangeSlot extends StatelessWidget {
  final String letter;
  final double size;
  final bool fixed;
  final bool filled;

  const _LessonOneArrangeSlot({
    required this.letter,
    required this.size,
    required this.fixed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fixed
            ? Colors.white.withValues(alpha: .80)
            : filled
            ? TudloColors.softGreen
            : Colors.white.withValues(alpha: .54),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fixed
              ? TudloColors.blue.withValues(alpha: .28)
              : filled
              ? TudloColors.green
              : Colors.grey.withValues(alpha: .55),
          width: 3,
        ),
      ),
      child: letter.isEmpty
          ? const SizedBox.shrink()
          : Text(
              letter,
              style: GoogleFonts.nunito(
                color: fixed ? TudloColors.ink : TudloColors.blue,
                fontSize: size * .58,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
    );
  }
}

class _LessonOneDraggableLetter extends StatelessWidget {
  final String letter;
  final bool used;
  final bool wrong;
  final Future<void> Function() onTap;

  const _LessonOneDraggableLetter({
    required this.letter,
    required this.used,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * .28).clamp(108.0, 148.0);
    return _FeedbackMotion(
      correct: false,
      wrong: wrong,
      child: GestureDetector(
        onTap: used ? null : () => unawaited(onTap()),
        child: Visibility(
          visible: !used,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: _IntroLetterArt(letter: letter, size: size),
        ),
      ),
    );
  }
}

class _LessonOneSticker extends StatefulWidget {
  final double size;
  final VoidCallback onTap;

  const _LessonOneSticker({required this.size, required this.onTap});

  @override
  State<_LessonOneSticker> createState() => _LessonOneStickerState();
}

class _LessonOneStickerState extends State<_LessonOneSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final String _stickerAsset = _activeLessonStickerAsset();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _scale = Tween<double>(
      begin: .22,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landscapeSticker = AppData.selectedGradeLevel == GradeLevel.grade3;
    const portraitStickerRatio = 60 / 118;
    final stickerWidth = landscapeSticker ? widget.size : widget.size * .62;
    final stickerHeight = landscapeSticker
        ? widget.size * .64
        : stickerWidth / portraitStickerRatio;
    final stickerRadius = landscapeSticker ? 10.0 : 18.0;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () async {
          await AppAudioService.instance.playTap();
          widget.onTap();
        },
        child: SizedBox(
          width: stickerWidth,
          height: stickerHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(stickerRadius),
            child: _StickerRewardAsset(
              asset: _stickerAsset,
              fit: landscapeSticker ? BoxFit.contain : BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
