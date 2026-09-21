part of '../../level_game_page.dart';

typedef _Grade3QuestionCompleted =
    void Function(
      int index, {
      required bool firstAttemptCorrect,
      required int attemptCount,
      required bool usedAudioSupport,
      required bool usedLookBackSupport,
    });

class _Grade3QuestionAttempt {
  final String lessonId;
  final String questionId;
  final String questionType;
  final bool firstAttemptCorrect;
  final int attemptCount;
  final bool usedAudioSupport;
  final bool usedLookBackSupport;
  final DateTime completedAt;

  const _Grade3QuestionAttempt({
    required this.lessonId,
    required this.questionId,
    required this.questionType,
    required this.firstAttemptCorrect,
    required this.attemptCount,
    required this.usedAudioSupport,
    required this.usedLookBackSupport,
    required this.completedAt,
  });
}

class _LessonAttemptTracker {
  final Map<String, _ActivityAttemptDraft> _activities = {};
  int expectedActivities = 0;

  bool hasActivity(String activityId) {
    return _activities.containsKey(activityId);
  }

  void recordAttempt({required String activityId, required bool correct}) {
    final activity = _activities.putIfAbsent(
      activityId,
      () => _ActivityAttemptDraft(activityId: activityId),
    );
    activity.record(correct);
  }

  LessonScoreStats toStats({
    required String lessonId,
    required int expectedActivities,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    final activities =
        _activities.values
            .map((activity) => activity.toScore(startedAt))
            .toList()
          ..sort((a, b) => a.activityId.compareTo(b.activityId));
    final attempts = activities.fold<int>(
      0,
      (total, activity) => total + activity.attempts,
    );
    final mistakes = activities.fold<int>(
      0,
      (total, activity) => total + activity.mistakes,
    );
    final correctAnswers = activities
        .where((activity) => activity.attempts > activity.mistakes)
        .length;
    final accuracy = attempts == 0
        ? 0
        : ((correctAnswers / attempts) * 100).round();

    return LessonScoreStats(
      lessonId: lessonId,
      totalActivities: expectedActivities > 0
          ? expectedActivities
          : this.expectedActivities,
      attempts: attempts,
      correctAnswers: correctAnswers,
      mistakes: mistakes,
      accuracy: accuracy,
      bestAccuracy: accuracy,
      replayCount: 0,
      timeTakenMs: completedAt.difference(startedAt).inMilliseconds,
      completionDate: completedAt,
      completed: true,
      activities: activities,
    );
  }
}

class _ActivityAttemptDraft {
  final String activityId;
  final DateTime startedAt = DateTime.now();
  int attempts = 0;
  int mistakes = 0;
  bool completed = false;
  DateTime? completedAt;

  _ActivityAttemptDraft({required this.activityId});

  void record(bool correct) {
    if (completed && correct) return;
    attempts++;
    if (correct) {
      completed = true;
      completedAt = DateTime.now();
      return;
    }
    mistakes++;
  }

  LessonActivityScore toScore(DateTime lessonStartedAt) {
    final endedAt = completedAt ?? DateTime.now();
    return LessonActivityScore(
      activityId: activityId,
      attempts: attempts,
      mistakes: mistakes,
      correctOnFirstTry: attempts == 1 && mistakes == 0 && completed,
      completionTimeMs: endedAt.difference(startedAt).inMilliseconds,
    );
  }
}

String _grade3QuestionTypeFor(LessonQuestion question) {
  final text = '${question.prompt} ${question.directionLabel}'.toLowerCase();
  if (text.contains('who') || text.contains('sin-o')) return 'who';
  if (text.contains('where') || text.contains('diin')) return 'where';
  if (text.contains('when') || text.contains('san-o')) return 'when';
  if (text.contains('why') || text.contains('ngaa')) return 'why';
  if (text.contains('how many') || text.contains('pila')) return 'howMany';
  if (text.contains('how much') || text.contains('bili')) return 'howMuch';
  if (text.contains('predict') || text.contains('matabo')) return 'prediction';
  if (question.type == QuestionType.matching) return 'sequence';
  if (question.type == QuestionType.imageChoice) return 'imageChoice';
  if (question.type == QuestionType.buildSentence ||
      question.type == QuestionType.arrangeWords) {
    return 'tileBuilder';
  }
  return 'what';
}

enum _Grade3FlowStepType {
  intro,
  warmUp,
  review,
  vocabulary,
  storyPage,
  question,
  productive,
  consolidation,
  completion,
}

class _Grade3FlowStep {
  final _Grade3FlowStepType type;
  final int index;

  const _Grade3FlowStep(this.type, [this.index = -1]);
}

class _Grade3StoryPageData {
  final String id;
  final String imagePath;
  final List<String> sentences;

  const _Grade3StoryPageData({
    required this.id,
    required this.imagePath,
    required this.sentences,
  });
}

const String _grade3MarketAssetRoot =
    'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets';
const String _grade3MarketBackgroundAsset =
    '$_grade3MarketAssetRoot/background/MarketLandscape.svg';
const String _grade3MarketFruitStallAsset =
    '$_grade3MarketAssetRoot/stalls/Stall_Fruit_Empty.svg';
const String _grade3MarketFishStallAsset =
    '$_grade3MarketAssetRoot/stalls/Stall_Fish_Empty.svg';
const String _grade3MarketFlowerStallAsset =
    '$_grade3MarketAssetRoot/stalls/Stall_Flower_Empty.svg';
const String _grade3MarketShellStallAsset =
    '$_grade3MarketAssetRoot/stalls/Stall_Shell_Empty.svg';
const String _grade3MarketInventoryStallAsset =
    '$_grade3MarketAssetRoot/stalls/Stall_Inventory_Empty.svg';
const String _grade3MarketCounterAsset =
    '$_grade3MarketAssetRoot/stalls/Market_Counter.svg';
const String _grade3MarketVendorAsset =
    '$_grade3MarketAssetRoot/people/Vendor_Female.svg';
const String _grade3MarketFishVendorAsset =
    '$_grade3MarketAssetRoot/people/Vendor_Fish_Male.svg';
const String _grade3MarketTrayAsset =
    '$_grade3MarketAssetRoot/inventory/Display_Tray_Empty.svg';
const String _grade3MarketCrateAsset =
    '$_grade3MarketAssetRoot/inventory/Produce_Crate_Empty.svg';
const String _grade3MarketPailEmptyAsset =
    '$_grade3MarketAssetRoot/inventory/Pail_Empty.svg';
const String _grade3MarketPailFullAsset =
    '$_grade3MarketAssetRoot/inventory/Pail_6_Shells.svg';
const String _grade3MarketMangoAsset =
    '$_grade3MarketAssetRoot/counting_objects/Mango.svg';
const String _grade3AppleAsset = 'assets/images/level_game/apple.png';
const String _grade3MarketFishAsset =
    '$_grade3MarketAssetRoot/counting_objects/Fish.svg';
const String _grade3MarketLilyPadAsset =
    '$_grade3MarketAssetRoot/counting_objects/Lily_Pad.svg';
const String _grade3MarketBookAsset =
    '$_grade3MarketAssetRoot/counting_objects/Book_Blue.svg';
const String _grade3MarketFlowerPinkAsset =
    '$_grade3MarketAssetRoot/counting_objects/Flower_Pink.svg';
const String _grade3MarketFlowerSunflowerAsset =
    '$_grade3MarketAssetRoot/counting_objects/Flower_Sunflower.svg';
const String _grade3MarketFlowerTulipAsset =
    '$_grade3MarketAssetRoot/counting_objects/Flower_Red_Tulip.svg';
const String _grade3MarketBananasAsset =
    '$_grade3MarketAssetRoot/inventory/Bananas_Bunch.svg';
const String _grade3MarketEggAsset =
    '$_grade3MarketAssetRoot/inventory/Egg.svg';
const String _grade3MarketCupAsset =
    '$_grade3MarketAssetRoot/inventory/Cup_Blue.svg';
const String _grade3MarketCandleAsset =
    '$_grade3MarketAssetRoot/inventory/Birthday_Candle.svg';
const List<String> _grade3MarketShellAssets = [
  '$_grade3MarketAssetRoot/shells/Shell_Pink.svg',
  '$_grade3MarketAssetRoot/shells/Shell_Orange.svg',
  '$_grade3MarketAssetRoot/shells/Shell_Purple.svg',
  '$_grade3MarketAssetRoot/shells/Shell_Yellow.svg',
  '$_grade3MarketAssetRoot/shells/Shell_Green_Spiral.svg',
  '$_grade3MarketAssetRoot/shells/Shell_Blue_Conch.svg',
];

bool _isGrade3MarketNumbersLesson(LevelContent content) {
  return content.gradeLevel == 3 &&
      content.unitNumber == 1 &&
      content.lessonNumber == 1;
}

class _GradeThreeLessonFlow extends StatefulWidget {
  final LevelContent content;
  final List<LessonQuestion> questions;
  final _Grade3QuestionCompleted onQuestionCompleted;
  final VoidCallback onLessonComplete;

  const _GradeThreeLessonFlow({
    required this.content,
    required this.questions,
    required this.onQuestionCompleted,
    required this.onLessonComplete,
  });

  @override
  State<_GradeThreeLessonFlow> createState() => _GradeThreeLessonFlowState();
}

class _GradeThreeLessonFlowState extends State<_GradeThreeLessonFlow> {
  int _stepIndex = 0;
  final Set<int> _completedQuestions = {};
  late final List<_Grade3StoryPageData> _storyPages = _grade3StoryPagesFor(
    widget.content,
  );

  List<_Grade3FlowStep> get _steps {
    final steps = <_Grade3FlowStep>[
      const _Grade3FlowStep(_Grade3FlowStepType.intro),
      const _Grade3FlowStep(_Grade3FlowStepType.warmUp),
      const _Grade3FlowStep(_Grade3FlowStepType.review),
    ];
    if (widget.content.examples.isNotEmpty) {
      steps.add(const _Grade3FlowStep(_Grade3FlowStepType.vocabulary));
    }
    final maxStorySteps = math.max(_storyPages.length, widget.questions.length);
    for (var index = 0; index < maxStorySteps; index++) {
      if (index < _storyPages.length) {
        steps.add(_Grade3FlowStep(_Grade3FlowStepType.storyPage, index));
      }
      if (index < widget.questions.length) {
        steps.add(_Grade3FlowStep(_Grade3FlowStepType.question, index));
      }
    }
    steps.addAll(const [
      _Grade3FlowStep(_Grade3FlowStepType.productive),
      _Grade3FlowStep(_Grade3FlowStepType.consolidation),
      _Grade3FlowStep(_Grade3FlowStepType.completion),
    ]);
    return steps;
  }

  void _next() {
    final maxIndex = _steps.length - 1;
    if (_stepIndex >= maxIndex) return;
    setState(() => _stepIndex++);
  }

  void _previous() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex--);
  }

  void _completeQuestion(
    int index, {
    required bool firstAttemptCorrect,
    required int attemptCount,
    required bool usedAudioSupport,
    required bool usedLookBackSupport,
  }) {
    if (_completedQuestions.add(index)) {
      widget.onQuestionCompleted(
        index,
        firstAttemptCorrect: firstAttemptCorrect,
        attemptCount: attemptCount,
        usedAudioSupport: usedAudioSupport,
        usedLookBackSupport: usedLookBackSupport,
      );
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = steps[_stepIndex.clamp(0, steps.length - 1)];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('${step.type}-${step.index}-$_stepIndex'),
        child: switch (step.type) {
          _Grade3FlowStepType.intro => _Grade3IntroStep(
            content: widget.content,
            onNext: _next,
          ),
          _Grade3FlowStepType.warmUp => _Grade3SimpleActionStep(
            title: 'Balikid Anay',
            message: _grade3WarmUpText(widget.content),
            icon: Icons.history_edu_rounded,
            buttonLabel: 'Padayon',
            onNext: _next,
          ),
          _Grade3FlowStepType.review => _Grade3SimpleActionStep(
            title: 'Review',
            message: 'Pili-a kag pamatii ang isa ka natun-an nga tinaga.',
            icon: Icons.school_rounded,
            buttonLabel: 'Padayon',
            onNext: _next,
          ),
          _Grade3FlowStepType.vocabulary => _Grade3VocabularyStep(
            examples: widget.content.examples,
            onNext: _next,
          ),
          _Grade3FlowStepType.storyPage => _Grade3StoryScreen(
            page: _storyPages[step.index],
            pageNumber: step.index + 1,
            pageCount: _storyPages.length,
            canGoBack: _stepIndex > 0,
            canGoNext: true,
            onBack: _previous,
            onNext: _next,
          ),
          _Grade3FlowStepType.question => _Grade3QuestionScreen(
            question: widget.questions[step.index],
            questionIndex: step.index,
            storyPage: _evidencePageForQuestion(step.index),
            onCompleted: _completeQuestion,
          ),
          _Grade3FlowStepType.productive => _Grade3SimpleActionStep(
            title: 'Himuon Ta',
            message: 'Basaha liwat ang pinakanami nga linya.',
            icon: Icons.record_voice_over_rounded,
            buttonLabel: 'Nahimo Ko',
            onNext: _next,
          ),
          _Grade3FlowStepType.consolidation => _Grade3SimpleActionStep(
            title: 'Pangitaa ang Sabat',
            message: 'Baliki ang sugilanon kag dumduma ang natun-an.',
            icon: Icons.extension_rounded,
            buttonLabel: 'Tapos Na',
            onNext: _next,
          ),
          _Grade3FlowStepType.completion => _Grade3CompletionStep(
            content: widget.content,
            onComplete: widget.onLessonComplete,
          ),
        },
      ),
    );
  }

  _Grade3StoryPageData _evidencePageForQuestion(int questionIndex) {
    if (_storyPages.isEmpty) {
      return _grade3FallbackStoryPage(widget.content, 0);
    }
    return _storyPages[questionIndex.clamp(0, _storyPages.length - 1)];
  }
}

class _Grade3IntroStep extends StatelessWidget {
  final LevelContent content;
  final VoidCallback onNext;

  const _Grade3IntroStep({required this.content, required this.onNext});

  @override
  Widget build(BuildContext context) {
    if (_isGrade3MarketNumbersLesson(content)) {
      return _Grade3MarketIntroStep(onNext: onNext);
    }

    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LessonKokaMascot(size: 150),
          const SizedBox(height: 18),
          Text(
            'Pamati kag Basaha',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _grade3CleanTitle(content.title),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          const _Grade3TipBubble(
            text: 'Basaha anay. Pindoton ang speaker kon gusto mo mamati.',
          ),
          const SizedBox(height: 28),
          _Grade3PrimaryButton(label: 'Sugdi', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3MarketIntroStep extends StatelessWidget {
  final VoidCallback onNext;

  const _Grade3MarketIntroStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final sceneHeight = (view.height * .62).clamp(420.0, 560.0);
    final kokaSize = (view.width * .34).clamp(132.0, 170.0);

    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: sceneHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: _LessonPictureAsset(
                      asset: _grade3MarketBackgroundAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_) => const _Grade3MarketSceneFallback(),
                    ),
                  ),
                  Positioned(
                    right: -18,
                    bottom: sceneHeight * .18,
                    width: view.width.clamp(260.0, 390.0),
                    height: sceneHeight * .44,
                    child: const _LessonPictureAsset(
                      asset: _grade3MarketFruitStallAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: sceneHeight * .15,
                    width: (view.width * .26).clamp(96.0, 136.0),
                    height: sceneHeight * .44,
                    child: const _LessonPictureAsset(
                      asset: _grade3MarketVendorAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: sceneHeight * .05,
                    child: _LessonKokaMascot(size: kokaSize, mood: KokaMood.hi),
                  ),
                  Positioned(
                    left: 118,
                    right: 16,
                    top: sceneHeight * .12,
                    child: const _Grade3MarketSpeechBubble(
                      text: 'Mag-ihap kita sa merkado!',
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 14,
                    child: _Grade3MarketLessonPanel(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Grade3PrimaryButton(label: 'Sugdi', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3MarketLessonPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GRADE 3 • UNIT 1 • LESSON 1.1',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.blue,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Numero sa Merkado',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Grade3MarketLearningChip(label: 'MGA NUMERO 1-10'),
              _Grade3MarketLearningChip(label: 'PILA?'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grade3MarketLearningChip extends StatelessWidget {
  final String label;

  const _Grade3MarketLearningChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFC93D), width: 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: TudloColors.forest,
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _Grade3MarketSpeechBubble extends StatelessWidget {
  final String text;

  const _Grade3MarketSpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCE9FF), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 24,
          height: 1.08,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _Grade3MarketSceneFallback extends StatelessWidget {
  const _Grade3MarketSceneFallback();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFCFF4FF));
  }
}

enum _G3MarketStep {
  intro,
  map,
  findFruitStall,
  countingIntro,
  tapNumbersOneTen,
  appleBasket,
  appleQuestion,
  countOneToFive,
  chooseFive,
  sixToTenIntro,
  tapSixToTen,
  arrangeIntro,
  arrangeSixToTen,
  reward,
}

class _GradeThreeMarketNumbersFlow extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onLessonComplete;

  const _GradeThreeMarketNumbersFlow({
    required this.onExit,
    required this.onLessonComplete,
  });

  @override
  State<_GradeThreeMarketNumbersFlow> createState() =>
      _GradeThreeMarketNumbersFlowState();
}

class _GradeThreeMarketNumbersFlowState
    extends State<_GradeThreeMarketNumbersFlow> {
  _G3MarketStep _step = _G3MarketStep.intro;
  final Set<int> _heardNumbers = {};
  final Set<int> _tappedSixToTen = {};
  final List<int?> _arrangedSixToTen = List<int?>.filled(5, null);
  final List<int> _arrangeChoices = const [8, 6, 10, 7, 9];
  int? _wrongChoice;
  int? _correctChoice;
  int _wrongPulse = 0;
  bool _inputLocked = false;

  double get _progress =>
      (_G3MarketStep.values.indexOf(_step) + 1) / _G3MarketStep.values.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playStepVoice();
    });
  }

  void _goNext() {
    final index = _G3MarketStep.values.indexOf(_step);
    if (index >= _G3MarketStep.values.length - 1) return;
    setState(() {
      _step = _G3MarketStep.values[index + 1];
      _wrongChoice = null;
      _correctChoice = null;
      _inputLocked = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playStepVoice();
    });
  }

  Future<void> _replay() async {
    await _playStepVoice();
  }

  int _voiceClipForStep() {
    return switch (_step) {
      _G3MarketStep.intro => 2,
      _G3MarketStep.map => 3,
      _G3MarketStep.findFruitStall => 4,
      _G3MarketStep.countingIntro => 6,
      _G3MarketStep.tapNumbersOneTen => 7,
      _G3MarketStep.appleBasket => 8,
      _G3MarketStep.appleQuestion => 10,
      _G3MarketStep.countOneToFive => 13,
      _G3MarketStep.chooseFive => 14,
      _G3MarketStep.sixToTenIntro => 16,
      _G3MarketStep.tapSixToTen => 17,
      _G3MarketStep.arrangeIntro => 20,
      _G3MarketStep.arrangeSixToTen => 21,
      _G3MarketStep.reward => 25,
    };
  }

  Future<void> _playClip(int clip) async {
    await AppAudioService.instance.lowerBackgroundVolume();
    try {
      await AppAudioService.instance.playVoiceAssets([
        'audio/VO-final/grade3/Gr_3_Les_1_1_$clip.wav',
      ]);
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  Future<void> _playStepVoice() => _playClip(_voiceClipForStep());

  Future<void> _choose(int choice, int answer) async {
    if (_inputLocked || _correctChoice != null) return;
    if (choice != answer) {
      setState(() {
        _wrongChoice = choice;
        _wrongPulse++;
      });
      unawaited(AppAudioService.instance.playWrong());
      await _playClip(12);
      if (mounted) setState(() => _wrongChoice = null);
      return;
    }

    setState(() {
      _inputLocked = true;
      _correctChoice = choice;
    });
    await AppAudioService.instance.playCorrect();
    await _playClip(_step == _G3MarketStep.appleQuestion ? 11 : 15);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => _inputLocked = false);
  }

  Future<void> _tapStall() async {
    if (_inputLocked) return;
    setState(() => _inputLocked = true);
    await AppAudioService.instance.playCorrect();
    await _playClip(5);
    if (!mounted) return;
    setState(() => _inputLocked = false);
    _goNext();
  }

  Future<void> _tapNumberOneTen(int number) async {
    setState(() => _heardNumbers.add(number));
    await playLessonNumberVoice(number);
  }

  Future<void> _tapSixToTen(int number) async {
    final expected = 6 + _tappedSixToTen.length;
    if (number != expected) {
      setState(() {
        _wrongChoice = number;
        _wrongPulse++;
      });
      await AppAudioService.instance.playWrong();
      await _playClip(19);
      if (mounted) setState(() => _wrongChoice = null);
      return;
    }
    setState(() => _tappedSixToTen.add(number));
    await playLessonNumberVoice(number);
    if (_tappedSixToTen.length == 5) {
      await AppAudioService.instance.playCorrect();
      await _playClip(18);
    }
  }

  Future<void> _placeArrangeNumber(int number, int slotIndex) async {
    final expected = 6 + slotIndex;
    if (number != expected) {
      setState(() => _wrongPulse++);
      unawaited(AppAudioService.instance.playWrong());
      await _playClip(23);
      await _playClip(24);
      return;
    }
    setState(() {
      final oldIndex = _arrangedSixToTen.indexOf(number);
      if (oldIndex != -1) _arrangedSixToTen[oldIndex] = null;
      _arrangedSixToTen[slotIndex] = number;
    });
    if (_arrangedSixToTen.indexed.every((entry) => entry.$2 == 6 + entry.$1)) {
      await AppAudioService.instance.playCorrect();
      await _playClip(22);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_g3MarketLegacyReferenceSink != null);
    return _G3MarketChrome(
      progress: _progress,
      onExit: widget.onExit,
      onReplay: _replay,
      child: switch (_step) {
        _G3MarketStep.intro => _G3MarketIntroPage(onNext: _goNext),
        _G3MarketStep.map => _G3MarketMapPage(onNext: _goNext),
        _G3MarketStep.findFruitStall => _G3FindFruitStallPage(
          onTapStall: _tapStall,
        ),
        _G3MarketStep.countingIntro => _G3SimpleMarketPage(
          prompt: 'Mag-ihap kita halin 1 tubtob 10.',
          onNext: _goNext,
          child: const _G3NumberLine(numbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
        ),
        _G3MarketStep.tapNumbersOneTen => _G3NumberReviewPage(
          heardNumbers: _heardNumbers,
          numbers: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          onTapNumber: (number) => unawaited(_tapNumberOneTen(number)),
          onNext: _heardNumbers.length == 10 ? _goNext : null,
        ),
        _G3MarketStep.appleBasket => _G3AppleBasketPage(
          onNext: () async {
            await _playClip(9);
            if (mounted) _goNext();
          },
        ),
        _G3MarketStep.appleQuestion => _G3CountingQuestionPage(
          prompt: 'How many apples are there?',
          objectAsset: _grade3AppleAsset,
          objectCount: 5,
          choices: const [4, 5, 6],
          answer: 5,
          baseAsset: _grade3MarketCrateAsset,
          altObjectAssets: null,
          stallAsset: null,
          vendorAsset: null,
          waterMode: false,
          wrongChoice: _wrongChoice,
          correctChoice: _correctChoice,
          wrongPulse: _wrongPulse,
          onChoose: _choose,
          onNext: _goNext,
        ),
        _G3MarketStep.countOneToFive => _G3SimpleMarketPage(
          prompt: '1, 2, 3, 4, 5',
          onNext: _goNext,
          child: const _G3NumberLine(numbers: [1, 2, 3, 4, 5]),
        ),
        _G3MarketStep.chooseFive => _G3ChooseNumberPage(
          prompt: 'Choose number 5.',
          choices: const [3, 5, 6],
          answer: 5,
          wrongChoice: _wrongChoice,
          correctChoice: _correctChoice,
          wrongPulse: _wrongPulse,
          onChoose: _choose,
          onNext: _goNext,
        ),
        _G3MarketStep.sixToTenIntro => _G3SimpleMarketPage(
          prompt: '6, 7, 8, 9, 10',
          onNext: _goNext,
          child: const _G3NumberLine(numbers: [6, 7, 8, 9, 10]),
        ),
        _G3MarketStep.tapSixToTen => _G3NumberReviewPage(
          heardNumbers: _tappedSixToTen,
          numbers: const [6, 7, 8, 9, 10],
          wrongChoice: _wrongChoice,
          wrongPulse: _wrongPulse,
          onTapNumber: (number) => unawaited(_tapSixToTen(number)),
          onNext: _tappedSixToTen.length == 5 ? _goNext : null,
        ),
        _G3MarketStep.arrangeIntro => _G3SimpleMarketPage(
          prompt: 'Pilia kag ihan-ay ang numero.',
          onNext: _goNext,
          child: _G3NumberLine(numbers: _arrangeChoices),
        ),
        _G3MarketStep.arrangeSixToTen => _G3ArrangeNumbersPage(
          slots: _arrangedSixToTen,
          choices: _arrangeChoices,
          wrongPulse: _wrongPulse,
          onPlace: (number, slotIndex) =>
              unawaited(_placeArrangeNumber(number, slotIndex)),
          onNext:
              _arrangedSixToTen.indexed.every(
                (entry) => entry.$2 == 6 + entry.$1,
              )
              ? _goNext
              : null,
        ),
        _G3MarketStep.reward => _G3MarketRewardPage(
          onComplete: widget.onLessonComplete,
        ),
      },
    );
  }
}

Object? get _g3MarketLegacyReferenceSink => (
  _grade3MarketFishStallAsset,
  _grade3MarketFlowerStallAsset,
  _grade3MarketFishVendorAsset,
  _grade3MarketFishAsset,
  _grade3MarketLilyPadAsset,
  _grade3MarketBookAsset,
  _grade3MarketFlowerPinkAsset,
  _grade3MarketFlowerSunflowerAsset,
  _grade3MarketFlowerTulipAsset,
  _G3ModelCountPage,
  _G3ListenChoosePage,
  _G3ShellRoundPage,
  _G3BuildSayPage,
  _g3InventoryRounds,
  _G3InventoryPage,
);

class _G3MarketMapPage extends StatelessWidget {
  final VoidCallback onNext;

  const _G3MarketMapPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Kadtuon ta ang merkado.',
      footer: _LessonOneBlueButton(label: 'Sige', onTap: onNext),
      child: SizedBox(
        height: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const _LessonPictureAsset(
              asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
              fit: BoxFit.cover,
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: TudloColors.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3FindFruitStallPage extends StatelessWidget {
  final VoidCallback onTapStall;

  const _G3FindFruitStallPage({required this.onTapStall});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'I-tap ang fruit stall.',
      footer: const SizedBox(height: 64),
      child: GestureDetector(
        onTap: onTapStall,
        child: const Column(
          children: [
            _LessonKokaMascot(size: 112, mood: KokaMood.hi),
            SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: _LessonPictureAsset(
                asset: _grade3MarketFruitStallAsset,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3SimpleMarketPage extends StatelessWidget {
  final String prompt;
  final Widget child;
  final VoidCallback onNext;

  const _G3SimpleMarketPage({
    required this.prompt,
    required this.child,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: prompt,
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LessonKokaMascot(size: 112, mood: KokaMood.hi),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _G3AppleBasketPage extends StatelessWidget {
  final Future<void> Function() onNext;

  const _G3AppleBasketPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Put the apples in the basket. Let us count them.',
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: () => unawaited(onNext()),
      ),
      child: const Column(
        children: [
          _G3ObjectTray(
            baseAsset: _grade3MarketCrateAsset,
            objectAssets: [
              _grade3AppleAsset,
              _grade3AppleAsset,
              _grade3AppleAsset,
              _grade3AppleAsset,
              _grade3AppleAsset,
            ],
          ),
          SizedBox(height: 12),
          _G3ResultText(text: '5 apples'),
        ],
      ),
    );
  }
}

class _G3ChooseNumberPage extends StatelessWidget {
  final String prompt;
  final List<int> choices;
  final int answer;
  final int? wrongChoice;
  final int? correctChoice;
  final int wrongPulse;
  final Future<void> Function(int choice, int answer) onChoose;
  final VoidCallback onNext;

  const _G3ChooseNumberPage({
    required this.prompt,
    required this.choices,
    required this.answer,
    required this.wrongChoice,
    required this.correctChoice,
    required this.wrongPulse,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: prompt,
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: correctChoice == null ? null : onNext,
      ),
      child: _G3AnswerRow(
        choices: choices,
        wrongChoice: wrongChoice,
        correctChoice: correctChoice,
        wrongPulse: wrongPulse,
        onChoose: (choice) => unawaited(onChoose(choice, answer)),
      ),
    );
  }
}

class _G3NumberLine extends StatelessWidget {
  final List<int> numbers;

  const _G3NumberLine({required this.numbers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final number in numbers)
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: _g3SoftPanelDecoration(borderColor: TudloColors.blue),
            child: Text(
              '$number',
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _G3ArrangeNumbersPage extends StatelessWidget {
  final List<int?> slots;
  final List<int> choices;
  final int wrongPulse;
  final void Function(int number, int slotIndex) onPlace;
  final VoidCallback? onNext;

  const _G3ArrangeNumbersPage({
    required this.slots,
    required this.choices,
    required this.wrongPulse,
    required this.onPlace,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final placed = slots.whereType<int>().toSet();
    return _G3MarketContentFrame(
      prompt: 'Ihan-ay ang 6, 7, 8, 9, 10.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < slots.length; index++) ...[
                Expanded(
                  child: _G3NumberDropSlot(
                    value: slots[index],
                    wrongPulse: wrongPulse,
                    onAccept: (number) => onPlace(number, index),
                  ),
                ),
                if (index < slots.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final number in choices)
                if (!placed.contains(number))
                  _G3DraggableNumber(number: number),
            ],
          ),
        ],
      ),
    );
  }
}

class _G3NumberDropSlot extends StatelessWidget {
  final int? value;
  final int wrongPulse;
  final ValueChanged<int> onAccept;

  const _G3NumberDropSlot({
    required this.value,
    required this.wrongPulse,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => value == null,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        return _FeedbackMotion(
          key: ValueKey('slot-$wrongPulse-$value'),
          correct: value != null,
          wrong: candidate.isNotEmpty,
          child: Container(
            height: 72,
            alignment: Alignment.center,
            decoration: _g3SoftPanelDecoration(
              fill: value == null ? Colors.white : const Color(0xFFE3FFD8),
              borderColor: value == null ? TudloColors.blue : TudloColors.green,
            ),
            child: Text(
              value == null ? '' : '$value',
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _G3DraggableNumber extends StatelessWidget {
  final int number;

  const _G3DraggableNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: _g3SoftPanelDecoration(borderColor: TudloColors.blue),
      child: Text(
        '$number',
        style: GoogleFonts.nunito(
          color: TudloColors.blue,
          fontSize: 34,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
    return Draggable<int>(
      data: number,
      feedback: Material(color: Colors.transparent, child: tile),
      childWhenDragging: Opacity(opacity: .35, child: tile),
      child: tile,
    );
  }
}

class _G3MarketChrome extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;

  const _G3MarketChrome({
    required this.progress,
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
      backgroundAsset: _grade3MarketBackgroundAsset,
      child: child,
    );
  }
}

class _G3MarketIntroPage extends StatelessWidget {
  final VoidCallback onNext;

  const _G3MarketIntroPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        view.width * .06,
        view.height * .13,
        view.width * .06,
        view.height * .035,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  right: -view.width * .10,
                  bottom: view.height * .10,
                  width: view.width * .78,
                  height: view.height * .34,
                  child: const _LessonPictureAsset(
                    asset: _grade3MarketFruitStallAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: -view.width * .06,
                  bottom: view.height * .02,
                  child: _LessonKokaMascot(
                    size: (view.width * .44).clamp(160.0, 230.0),
                    mood: KokaMood.hi,
                  ),
                ),
                Positioned(
                  left: view.width * .32,
                  right: 0,
                  top: view.height * .06,
                  child: const _Grade3MarketSpeechBubble(
                    text: 'Mag-ihap kita sa merkado!',
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _Grade3MarketLessonPanel(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LessonOneBlueButton(label: 'Sugdi', onTap: onNext),
        ],
      ),
    );
  }
}

class _G3NumberReviewPage extends StatelessWidget {
  final Set<int> heardNumbers;
  final List<int> numbers;
  final int? wrongChoice;
  final int wrongPulse;
  final ValueChanged<int> onTapNumber;
  final VoidCallback? onNext;

  const _G3NumberReviewPage({
    required this.heardNumbers,
    required this.numbers,
    required this.onTapNumber,
    required this.onNext,
    this.wrongChoice,
    this.wrongPulse = 0,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'Mag-ihap kita halin isa tubtob napulo.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        children: [
          const _LessonKokaMascot(size: 124, mood: KokaMood.hi),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final number in numbers)
                _FeedbackMotion(
                  key: ValueKey('g3-number-$number-$wrongPulse'),
                  correct: heardNumbers.contains(number),
                  wrong: wrongChoice == number,
                  child: GestureDetector(
                    onTap: heardNumbers.contains(number)
                        ? null
                        : () => onTapNumber(number),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: (view.width * .15).clamp(54.0, 70.0),
                      height: (view.width * .15).clamp(54.0, 70.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: heardNumbers.contains(number)
                            ? TudloColors.green
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: TudloColors.blue, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .10),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '$number',
                        style: GoogleFonts.nunito(
                          color: heardNumbers.contains(number)
                              ? Colors.white
                              : TudloColors.blue,
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _G3ModelCountPage extends StatelessWidget {
  final VoidCallback onNext;

  const _G3ModelCountPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Pila ka mangga?',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: const Column(
        children: [
          _G3MarketSceneLayer(stallAsset: _grade3MarketFruitStallAsset),
          SizedBox(height: 10),
          _G3ObjectTray(
            baseAsset: _grade3MarketTrayAsset,
            objectAssets: [
              _grade3MarketMangoAsset,
              _grade3MarketMangoAsset,
              _grade3MarketMangoAsset,
            ],
          ),
          SizedBox(height: 8),
          _G3ResultText(text: 'Three mangoes.'),
        ],
      ),
    );
  }
}

class _G3CountingQuestionPage extends StatelessWidget {
  final String prompt;
  final String objectAsset;
  final List<String>? altObjectAssets;
  final int objectCount;
  final List<int> choices;
  final int answer;
  final String? stallAsset;
  final String? vendorAsset;
  final String? baseAsset;
  final bool waterMode;
  final int? wrongChoice;
  final int? correctChoice;
  final int wrongPulse;
  final Future<void> Function(int choice, int answer) onChoose;
  final VoidCallback onNext;

  const _G3CountingQuestionPage({
    required this.prompt,
    required this.objectAsset,
    required this.objectCount,
    required this.choices,
    required this.answer,
    required this.wrongChoice,
    required this.correctChoice,
    this.wrongPulse = 0,
    required this.onChoose,
    required this.onNext,
    this.altObjectAssets,
    this.stallAsset,
    this.vendorAsset,
    this.baseAsset,
    this.waterMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final assets = [
      for (var index = 0; index < objectCount; index++)
        altObjectAssets == null
            ? objectAsset
            : altObjectAssets![index % altObjectAssets!.length],
    ];
    return _G3MarketContentFrame(
      prompt: prompt,
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: correctChoice == null ? null : onNext,
      ),
      child: Column(
        children: [
          if (stallAsset != null)
            _G3MarketSceneLayer(
              stallAsset: stallAsset!,
              vendorAsset: vendorAsset,
            ),
          const SizedBox(height: 8),
          _G3ObjectTray(
            baseAsset: baseAsset,
            objectAssets: assets,
            waterMode: waterMode,
          ),
          const SizedBox(height: 14),
          _G3AnswerRow(
            choices: choices,
            wrongChoice: wrongChoice,
            correctChoice: correctChoice,
            wrongPulse: wrongPulse,
            onChoose: (choice) => onChoose(choice, answer),
          ),
        ],
      ),
    );
  }
}

class _G3ListenChoosePage extends StatelessWidget {
  final String prompt;
  final String spoken;
  final String objectAsset;
  final List<int> groupCounts;
  final int answer;
  final int? wrongChoice;
  final int? correctChoice;
  final Future<void> Function(int choice, int answer) onChoose;
  final VoidCallback onNext;

  const _G3ListenChoosePage({
    required this.prompt,
    required this.spoken,
    required this.objectAsset,
    required this.groupCounts,
    required this.answer,
    required this.wrongChoice,
    required this.correctChoice,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: prompt,
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: correctChoice == null ? null : onNext,
      ),
      child: Column(
        children: [
          _G3ResultText(text: spoken),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final count in groupCounts) ...[
                Expanded(
                  child: _G3GroupChoiceCard(
                    count: count,
                    objectAsset: objectAsset,
                    selectedWrong: wrongChoice == count,
                    selectedCorrect: correctChoice == count,
                    onTap: () => onChoose(count, answer),
                  ),
                ),
                if (count != groupCounts.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _G3ShellRoundPage extends StatelessWidget {
  final String prompt;
  final Set<int> placedShells;
  final int? selectedShell;
  final ValueChanged<int> onSelectShell;
  final ValueChanged<int> onPlaceShell;
  final VoidCallback? onNext;
  final bool reversed;

  const _G3ShellRoundPage({
    required this.prompt,
    required this.placedShells,
    required this.selectedShell,
    required this.onSelectShell,
    required this.onPlaceShell,
    required this.onNext,
    required this.reversed,
  });

  @override
  Widget build(BuildContext context) {
    final shellOrder = reversed
        ? List<int>.generate(
            _grade3MarketShellAssets.length,
            (index) => index,
          ).reversed.toList()
        : List<int>.generate(_grade3MarketShellAssets.length, (index) => index);
    return _G3MarketContentFrame(
      prompt: prompt,
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        children: [
          const _G3MarketSceneLayer(stallAsset: _grade3MarketShellStallAsset),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _g3SoftPanelDecoration(),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final index in shellOrder)
                        if (!placedShells.contains(index))
                          _G3DraggableShell(
                            index: index,
                            selected: selectedShell == index,
                            onTap: () => onSelectShell(index),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: selectedShell == null
                      ? null
                      : () => onPlaceShell(selectedShell!),
                  child: DragTarget<int>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails: (details) =>
                        onPlaceShell(details.data),
                    builder: (context, candidate, rejected) {
                      final complete =
                          placedShells.length ==
                          _grade3MarketShellAssets.length;
                      return Container(
                        height: 168,
                        padding: const EdgeInsets.all(12),
                        decoration: _g3SoftPanelDecoration(
                          borderColor:
                              candidate.isNotEmpty || selectedShell != null
                              ? TudloColors.green
                              : TudloColors.blue,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _LessonPictureAsset(
                              asset: complete
                                  ? _grade3MarketPailFullAsset
                                  : _grade3MarketPailEmptyAsset,
                              fit: BoxFit.contain,
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: _G3ResultText(
                                text:
                                    '${placedShells.length}/${_grade3MarketShellAssets.length}',
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _G3DraggableShell extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _G3DraggableShell({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shell = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 58,
        height: 58,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7FFD9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TudloColors.green : const Color(0xFFBBD9EA),
            width: 3,
          ),
        ),
        child: _LessonPictureAsset(
          asset: _grade3MarketShellAssets[index],
          fit: BoxFit.contain,
        ),
      ),
    );
    return Draggable<int>(
      data: index,
      feedback: Material(color: Colors.transparent, child: shell),
      childWhenDragging: Opacity(opacity: .28, child: shell),
      child: shell,
    );
  }
}

class _G3BuildSayPage extends StatelessWidget {
  final List<String?> slots;
  final void Function(String tile, int slot) onPlaceTile;
  final VoidCallback? onNext;

  const _G3BuildSayPage({
    required this.slots,
    required this.onPlaceTile,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Ihan-ay: Six shells!',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 150,
                  child: _LessonPictureAsset(
                    asset: _grade3MarketPailFullAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var index = 0; index < slots.length; index++) ...[
                          Expanded(
                            child: _G3SentenceSlot(
                              value: slots[index],
                              onAccept: (tile) => onPlaceTile(tile, index),
                            ),
                          ),
                          if (index == 0) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final tile in const ['Six', 'shells!']) ...[
                          Expanded(child: _G3SentenceTile(label: tile)),
                          if (tile == 'Six') const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _G3ResultText(text: 'Hambala: How many? Six!'),
        ],
      ),
    );
  }
}

class _G3SentenceSlot extends StatelessWidget {
  final int? index;
  final String? value;
  final ValueChanged<String> onAccept;

  const _G3SentenceSlot({
    this.index,
    required this.value,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => value == null,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: 76,
              alignment: Alignment.center,
              decoration: _g3SoftPanelDecoration(
                fill: Colors.white.withValues(alpha: .94),
                borderColor: value == null
                    ? const Color(0xFF4AB7FF)
                    : TudloColors.green,
              ),
              child: Text(
                value ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.blue,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (index != null)
              Positioned(
                top: -18,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: TudloColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _G3SentenceTile extends StatelessWidget {
  final String label;
  final bool selected;

  const _G3SentenceTile({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      height: 66,
      alignment: Alignment.center,
      decoration: _g3SoftPanelDecoration(
        fill: selected ? const Color(0xFFE9F7FF) : Colors.white,
        borderColor: selected ? TudloColors.green : TudloColors.blue,
      ),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 22,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
    return Draggable<String>(
      data: label,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 170, child: tile),
      ),
      childWhenDragging: Opacity(opacity: .35, child: tile),
      child: tile,
    );
  }
}

class _G3InventoryRound {
  final String prompt;
  final String objectAsset;
  final int count;
  final List<int> choices;
  final int answer;

  const _G3InventoryRound({
    required this.prompt,
    required this.objectAsset,
    required this.count,
    required this.choices,
    required this.answer,
  });
}

const List<_G3InventoryRound> _g3InventoryRounds = [
  _G3InventoryRound(
    prompt: 'Pila ka saging?',
    objectAsset: _grade3MarketBananasAsset,
    count: 4,
    choices: [3, 4, 5],
    answer: 4,
  ),
  _G3InventoryRound(
    prompt: 'Pila ka itlog?',
    objectAsset: _grade3MarketEggAsset,
    count: 6,
    choices: [5, 6, 7],
    answer: 6,
  ),
  _G3InventoryRound(
    prompt: 'Pila ka tasa?',
    objectAsset: _grade3MarketCupAsset,
    count: 3,
    choices: [2, 3, 4],
    answer: 3,
  ),
  _G3InventoryRound(
    prompt: 'Pila ka kandila?',
    objectAsset: _grade3MarketCandleAsset,
    count: 5,
    choices: [4, 5, 6],
    answer: 5,
  ),
];

class _G3InventoryPage extends StatelessWidget {
  final _G3InventoryRound round;
  final String progressText;
  final int? wrongChoice;
  final int? correctChoice;
  final ValueChanged<int> onChoose;
  final VoidCallback? onNext;

  const _G3InventoryPage({
    required this.round,
    required this.progressText,
    required this.wrongChoice,
    required this.correctChoice,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Buligi ang tindera mag-ihap. $progressText',
      footer: _LessonOneBlueButton(label: 'Tapuson', onTap: onNext),
      child: Column(
        children: [
          const _G3MarketSceneLayer(
            stallAsset: _grade3MarketInventoryStallAsset,
            vendorAsset: _grade3MarketVendorAsset,
          ),
          const SizedBox(height: 8),
          _G3ResultText(text: round.prompt, compact: true),
          const SizedBox(height: 8),
          _G3ObjectTray(
            baseAsset: _grade3MarketCounterAsset,
            objectAssets: [
              for (var index = 0; index < round.count; index++)
                round.objectAsset,
            ],
          ),
          const SizedBox(height: 10),
          _G3AnswerRow(
            choices: round.choices,
            wrongChoice: wrongChoice,
            correctChoice: correctChoice,
            onChoose: onChoose,
          ),
        ],
      ),
    );
  }
}

class _G3MarketRewardPage extends StatelessWidget {
  final VoidCallback onComplete;

  const _G3MarketRewardPage({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Maayo gid!',
      footer: _LessonOneBlueButton(label: 'Padayon', onTap: onComplete),
      child: const Column(
        children: [
          SizedBox(height: 12),
          _LessonKokaMascot(size: 150, mood: KokaMood.hi),
          SizedBox(height: 8),
          Icon(Icons.star_rounded, color: TudloColors.gold, size: 112),
          SizedBox(height: 8),
          _G3ResultText(text: 'Natapos mo ang leksyon.'),
        ],
      ),
    );
  }
}

class _G3MarketContentFrame extends StatelessWidget {
  final String prompt;
  final Widget child;
  final Widget footer;
  final bool showContentPanel;

  const _G3MarketContentFrame({
    required this.prompt,
    required this.child,
    required this.footer,
    this.showContentPanel = true,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        view.width * .045,
        view.height * .12,
        view.width * .045,
        view.height * .032,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: view.width * .78,
              child: _LessonOneMessageCard(message: prompt, compact: true),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: showContentPanel
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .76),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: child,
                    )
                  : child,
            ),
          ),
          const SizedBox(height: 10),
          footer,
        ],
      ),
    );
  }
}

class _G3MarketSceneLayer extends StatelessWidget {
  final String stallAsset;
  final String? vendorAsset;

  const _G3MarketSceneLayer({required this.stallAsset, this.vendorAsset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: _LessonPictureAsset(asset: stallAsset, fit: BoxFit.contain),
          ),
          if (vendorAsset != null)
            Positioned(
              right: 8,
              bottom: 0,
              width: 82,
              child: _LessonPictureAsset(
                asset: vendorAsset!,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _G3ObjectTray extends StatelessWidget {
  final String? baseAsset;
  final List<String> objectAssets;
  final bool waterMode;

  const _G3ObjectTray({
    required this.objectAssets,
    this.baseAsset,
    this.waterMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(12),
      decoration: _g3SoftPanelDecoration(
        fill: waterMode ? const Color(0xFFBFEFFF) : Colors.white,
        borderColor: waterMode ? TudloColors.blue : const Color(0xFFBBD9EA),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (baseAsset != null)
            Positioned.fill(
              child: Opacity(
                opacity: .86,
                child: _LessonPictureAsset(
                  asset: baseAsset!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final asset in objectAssets)
                SizedBox(
                  width: objectAssets.length >= 8 ? 48 : 58,
                  height: objectAssets.length >= 8 ? 48 : 58,
                  child: _LessonPictureAsset(asset: asset, fit: BoxFit.contain),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _G3AnswerRow extends StatelessWidget {
  final List<int> choices;
  final int? wrongChoice;
  final int? correctChoice;
  final int wrongPulse;
  final ValueChanged<int> onChoose;

  const _G3AnswerRow({
    required this.choices,
    required this.wrongChoice,
    required this.correctChoice,
    this.wrongPulse = 0,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final choice in choices) ...[
          Expanded(
            child: _G3NumberAnswerButton(
              value: choice,
              wrong: wrongChoice == choice,
              correct: correctChoice == choice,
              pulse: wrongPulse,
              onTap: () => onChoose(choice),
            ),
          ),
          if (choice != choices.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _G3NumberAnswerButton extends StatelessWidget {
  final int value;
  final bool wrong;
  final bool correct;
  final int pulse;
  final VoidCallback onTap;

  const _G3NumberAnswerButton({
    required this.value,
    required this.wrong,
    required this.correct,
    this.pulse = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('g3-market-$value-$wrong-$correct-$pulse'),
      correct: correct,
      wrong: wrong,
      child: GestureDetector(
        onTap: correct ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 62,
          alignment: Alignment.center,
          decoration: _g3SoftPanelDecoration(
            fill: correct ? const Color(0xFFE3FFD8) : Colors.white,
            borderColor: correct ? TudloColors.green : TudloColors.blue,
          ),
          child: Text(
            '$value',
            style: GoogleFonts.nunito(
              color: correct ? TudloColors.green : TudloColors.blue,
              fontSize: 32,
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

class _G3GroupChoiceCard extends StatelessWidget {
  final int count;
  final String objectAsset;
  final bool selectedWrong;
  final bool selectedCorrect;
  final VoidCallback onTap;

  const _G3GroupChoiceCard({
    required this.count,
    required this.objectAsset,
    required this.selectedWrong,
    required this.selectedCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('g3-group-$count-$selectedWrong-$selectedCorrect'),
      correct: selectedCorrect,
      wrong: selectedWrong,
      child: GestureDetector(
        onTap: selectedCorrect ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 150,
          padding: const EdgeInsets.all(8),
          decoration: _g3SoftPanelDecoration(
            fill: selectedCorrect ? const Color(0xFFE3FFD8) : Colors.white,
            borderColor: selectedCorrect
                ? TudloColors.green
                : const Color(0xFFBBD9EA),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 3,
            runSpacing: 3,
            children: [
              for (var index = 0; index < count; index++)
                SizedBox(
                  width: count >= 9 ? 28 : 34,
                  height: count >= 9 ? 28 : 34,
                  child: _LessonPictureAsset(
                    asset: objectAsset,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _G3ResultText extends StatelessWidget {
  final String text;
  final bool compact;

  const _G3ResultText({required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBD9EA), width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: compact ? 18 : 23,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

BoxDecoration _g3SoftPanelDecoration({
  Color fill = Colors.white,
  Color borderColor = const Color(0xFFBBD9EA),
}) {
  return BoxDecoration(
    color: fill.withValues(alpha: .96),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor, width: 3),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .09),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

class _Grade3SimpleActionStep extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onNext;

  const _Grade3SimpleActionStep({
    required this.title,
    required this.message,
    required this.icon,
    required this.buttonLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: TudloColors.green, size: 96),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(text: message),
          const SizedBox(height: 28),
          _Grade3PrimaryButton(label: buttonLabel, onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3VocabularyStep extends StatelessWidget {
  final List<LessonExample> examples;
  final VoidCallback onNext;

  const _Grade3VocabularyStep({required this.examples, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final visibleExamples = examples
        .where((example) => example.hiligaynon.trim().isNotEmpty)
        .take(4)
        .toList();
    return _Grade3Stage(
      child: Column(
        children: [
          Text(
            'Bag-o nga Tinaga',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          for (final example in visibleExamples) ...[
            _Grade3VocabularyCard(example: example),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          _Grade3PrimaryButton(label: 'Padayon', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3VocabularyCard extends StatelessWidget {
  final LessonExample example;

  const _Grade3VocabularyCard({required this.example});

  @override
  Widget build(BuildContext context) {
    final word = _grade3DisplayText(example.hiligaynon);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              word,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          TudloVoiceButton(
            message: word,
            tooltip: 'Pamatii',
            size: 48,
            hiligaynon: true,
          ),
        ],
      ),
    );
  }
}

class _Grade3StoryScreen extends StatelessWidget {
  final _Grade3StoryPageData page;
  final int pageNumber;
  final int pageCount;
  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final int? highlightedSentenceIndex;

  const _Grade3StoryScreen({
    required this.page,
    required this.pageNumber,
    required this.pageCount,
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
    this.highlightedSentenceIndex,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Sugilanon',
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '$pageNumber / $pageCount',
                style: GoogleFonts.nunito(
                  color: TudloColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: (MediaQuery.sizeOf(context).height * .34).clamp(
                220.0,
                310.0,
              ),
              width: double.infinity,
              child: _LessonPictureAsset(
                asset: page.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_) => const _StoryImageFallback(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < page.sentences.length; index++) ...[
            _Grade3SentenceCard(
              sentence: page.sentences[index],
              highlighted: highlightedSentenceIndex == index,
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          _Grade3PageDots(current: pageNumber - 1, count: pageCount),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Grade3SecondaryButton(
                  label: 'Balik',
                  enabled: canGoBack,
                  onTap: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Grade3PrimaryButton(
                  label: canGoNext ? 'Sunod' : 'Tapos',
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grade3SentenceCard extends StatefulWidget {
  final String sentence;
  final bool highlighted;

  const _Grade3SentenceCard({
    required this.sentence,
    required this.highlighted,
  });

  @override
  State<_Grade3SentenceCard> createState() => _Grade3SentenceCardState();
}

class _Grade3SentenceCardState extends State<_Grade3SentenceCard> {
  bool _usedAudio = false;

  Future<void> _speak() async {
    setState(() => _usedAudio = true);
    await TudloVoiceButton.speak(context, widget.sentence, hiligaynon: true);
    if (mounted) setState(() => _usedAudio = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _speak,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: widget.highlighted
              ? const Color(0xFFFFF3A6)
              : Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.highlighted ? TudloColors.gold : TudloColors.ink)
                  .withValues(alpha: widget.highlighted ? .22 : .07),
              blurRadius: widget.highlighted ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.sentence,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: _usedAudio
                  ? const Icon(
                      Icons.graphic_eq_rounded,
                      key: ValueKey(true),
                      color: TudloColors.green,
                      size: 30,
                    )
                  : const TudloSpeakerIcon(key: ValueKey(false), size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grade3QuestionScreen extends StatefulWidget {
  final LessonQuestion question;
  final int questionIndex;
  final _Grade3StoryPageData storyPage;
  final _Grade3QuestionCompleted onCompleted;

  const _Grade3QuestionScreen({
    required this.question,
    required this.questionIndex,
    required this.storyPage,
    required this.onCompleted,
  });

  @override
  State<_Grade3QuestionScreen> createState() => _Grade3QuestionScreenState();
}

class _Grade3QuestionScreenState extends State<_Grade3QuestionScreen> {
  int _attemptCount = 0;
  int _shakeAttempt = 0;
  bool _usedAudioSupport = false;
  bool _usedLookBackSupport = false;
  bool _showLookBack = false;
  bool _correct = false;
  String? _selected;

  List<String> get _choices {
    final choices = widget.question.choices.isNotEmpty
        ? widget.question.choices
        : [widget.question.answer];
    return choices.toSet().toList();
  }

  Future<void> _speakPrompt() async {
    setState(() => _usedAudioSupport = true);
    await TudloVoiceButton.speak(
      context,
      _grade3QuestionPrompt(widget.question),
      hiligaynon: true,
    );
  }

  Future<void> _choose(String choice) async {
    if (_correct || _showLookBack) return;
    _attemptCount++;
    final correct = choice == widget.question.answer;
    setState(() {
      _selected = choice;
      _correct = correct;
      if (!correct) {
        _shakeAttempt++;
        _usedLookBackSupport = true;
        _showLookBack = true;
      }
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Balikan ta ang sugilanon.',
        hiligaynon: true,
      );
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        widget.storyPage.sentences.first,
        hiligaynon: true,
      );
      return;
    }
    await AppAudioService.instance.playCorrect();
    widget.onCompleted(
      widget.questionIndex,
      firstAttemptCorrect: _attemptCount == 1,
      attemptCount: _attemptCount,
      usedAudioSupport: _usedAudioSupport,
      usedLookBackSupport: _usedLookBackSupport,
    );
  }

  Future<void> _retry() async {
    setState(() {
      _showLookBack = false;
      _selected = null;
    });
    await TudloVoiceButton.speak(
      context,
      'Liwata. Pangitaa ang sabat sa sugilanon.',
      hiligaynon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLookBack) {
      return Column(
        children: [
          Expanded(
            child: _Grade3StoryScreen(
              page: widget.storyPage,
              pageNumber: 1,
              pageCount: 1,
              canGoBack: false,
              canGoNext: true,
              onBack: () {},
              onNext: _retry,
              highlightedSentenceIndex: 0,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _Grade3TipBubble(
              text: 'Liwata. Pangitaa ang sabat sa sugilanon.',
            ),
          ),
        ],
      );
    }

    return _Grade3Stage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pamangkot',
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Pamatii',
                onPressed: _speakPrompt,
                style: IconButton.styleFrom(
                  backgroundColor: TudloColors.softGreen,
                  foregroundColor: TudloColors.green,
                ),
                icon: const TudloSpeakerIcon(size: 26),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(text: _grade3QuestionPrompt(widget.question)),
          const SizedBox(height: 20),
          for (final choice in _choices) ...[
            _Grade3AnswerCard(
              label: _grade3ChoiceLabel(choice),
              selected: _selected == choice,
              correct: _correct && _selected == choice,
              shakeKey: _selected == choice ? _shakeAttempt : 0,
              onTap: () => _choose(choice),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          const _Grade3TipBubble(
            text: 'Kon indi sigurado, baliki ang sugilanon.',
          ),
        ],
      ),
    );
  }
}

class _Grade3AnswerCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final int shakeKey;
  final VoidCallback onTap;

  const _Grade3AnswerCard({
    required this.label,
    required this.selected,
    required this.correct,
    required this.shakeKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('g3-$label-$shakeKey'),
      correct: correct,
      wrong: shakeKey > 0 && !correct,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: correct
                ? TudloColors.green
                : selected
                ? TudloColors.gold
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: correct || selected ? Colors.white : TudloColors.ink,
              fontSize: 23,
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

class _Grade3CompletionStep extends StatelessWidget {
  final LevelContent content;
  final VoidCallback onComplete;

  const _Grade3CompletionStep({
    required this.content,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LessonKokaMascot(size: 150),
          const SizedBox(height: 16),
          Text(
            'Maayo Gid!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(
            text:
                'Na-unlock ang libro: ${_grade3CleanTitle(content.storyTitle ?? content.title)}.',
          ),
          const SizedBox(height: 26),
          _Grade3PrimaryButton(label: 'Kuh-a ang Ganti', onTap: onComplete),
        ],
      ),
    );
  }
}

class _Grade3Stage extends StatelessWidget {
  final Widget child;

  const _Grade3Stage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 22),
                ),
                child: IntrinsicHeight(child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Grade3TipBubble extends StatelessWidget {
  final String text;

  const _Grade3TipBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.questionBubble,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 54, 22),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 21,
                height: 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grade3PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Grade3PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: TudloColors.green,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: TudloColors.forest.withValues(alpha: .22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Grade3SecondaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _Grade3SecondaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: TudloColors.green,
          side: const BorderSide(color: TudloColors.green, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Grade3PageDots extends StatelessWidget {
  final int current;
  final int count;

  const _Grade3PageDots({required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: current == index ? 24 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: current == index ? TudloColors.green : TudloColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

List<_Grade3StoryPageData> _grade3StoryPagesFor(LevelContent content) {
  final imagePath = content.storyImageAsset?.trim().isNotEmpty == true
      ? content.storyImageAsset!.trim()
      : _storyImagePathForTitles(content.title, content.storyTitle);
  final sentences = _grade3SentencesFor(content);
  final pages = <_Grade3StoryPageData>[];
  for (var index = 0; index < sentences.length; index += 2) {
    pages.add(
      _Grade3StoryPageData(
        id: '${content.id}-page-${pages.length + 1}',
        imagePath: imagePath,
        sentences: sentences.skip(index).take(2).toList(),
      ),
    );
  }
  return pages.isEmpty ? [_grade3FallbackStoryPage(content, 0)] : pages;
}

_Grade3StoryPageData _grade3FallbackStoryPage(LevelContent content, int index) {
  return _Grade3StoryPageData(
    id: '${content.id}-fallback-$index',
    imagePath: content.storyImageAsset?.trim().isNotEmpty == true
        ? content.storyImageAsset!.trim()
        : _storyImagePathForTitles(content.title, content.storyTitle),
    sentences: [_grade3CleanTitle(content.title)],
  );
}

List<String> _grade3SentencesFor(LevelContent content) {
  final source = [
    content.story,
    content.lesson,
    for (final example in content.examples) example.hiligaynon,
  ].whereType<String>().join(' ');
  final quoted = RegExp(r'"([^"]+)"')
      .allMatches(source)
      .map((match) => _grade3DisplayText(match.group(1) ?? ''))
      .where((value) => value.isNotEmpty)
      .toList();
  final rawSentences = quoted.length >= 4
      ? quoted
      : RegExp(r'[^.!?\n]+[.!?]?')
            .allMatches(source)
            .map((match) => _grade3DisplayText(match.group(0) ?? ''))
            .where((value) => value.isNotEmpty)
            .toList();
  final cleaned = rawSentences
      .map(_grade3ShortenSentence)
      .where((value) => value.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return [_grade3CleanTitle(content.title)];
  return cleaned.take(8).toList();
}

String _grade3ShortenSentence(String value) {
  final cleaned = _grade3DisplayText(value)
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'^(Presentation|Warm-up|Productive):\s*'), '')
      .trim();
  final words = cleaned.split(RegExp(r'\s+'));
  if (words.length <= 9) return cleaned;
  return '${words.take(9).join(' ')}.';
}

String _grade3CleanTitle(String value) {
  return _grade3DisplayText(value)
      .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
      .replaceAll(
        RegExp(r'\b(New|Presentation|Productive)\b:?', caseSensitive: false),
        '',
      )
      .trim();
}

String _grade3DisplayText(String value) {
  return value
      .replaceAll('â€œ', '"')
      .replaceAll('â€', '"')
      .replaceAll('â€“', '-')
      .replaceAll('â€”', '-')
      .replaceAll('Â·', '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _grade3WarmUpText(LevelContent content) {
  if (content.unitNumber == 1 && content.lessonNumber == 1) {
    return 'Dumduma ang numero isa tubtob napulo.';
  }
  return 'Dumduma ang natun-an sa nagligad nga leksiyon.';
}

String _grade3QuestionPrompt(LessonQuestion question) {
  final prompt = _grade3DisplayText(question.prompt);
  final quoted = RegExp(r'"([^"]+)"').firstMatch(prompt)?.group(1);
  final text = quoted ?? prompt;
  if (text.toLowerCase().contains('how many')) {
    return text.replaceAll(RegExp('how many', caseSensitive: false), 'Pila');
  }
  if (text.toLowerCase().contains('how much')) {
    return text.replaceAll(
      RegExp('how much', caseSensitive: false),
      'Pila ang bili sang',
    );
  }
  if (text.toLowerCase().startsWith('reverse')) {
    return 'Pamatii kag pili-a ang husto.';
  }
  return text;
}

String _grade3ChoiceLabel(String choice) {
  final cleaned = _grade3DisplayText(choice);
  final number = RegExp(r'\b([0-9]{1,2})\b').firstMatch(cleaned)?.group(1);
  if (number != null) return number;
  return cleaned
      .replaceAll(
        RegExp(r'^(tap|count, tap|tap the)\s+', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s+-\s+.*$'), '')
      .trim();
}
