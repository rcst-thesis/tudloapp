part of '../../level_game_page.dart';

class _GradeOneUnitOneLessonTwoNumberFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitOneLessonTwoNumberFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitOneLessonTwoNumberFlow> createState() =>
      _GradeOneUnitOneLessonTwoNumberFlowState();
}

class _GradeOneUnitOneLessonTwoNumberFlowState
    extends State<_GradeOneUnitOneLessonTwoNumberFlow> {
  static const _letters = ['I', 'D', 'O'];
  static const _buriedLetters = ['I', 'D', 'O', 'N'];
  int _stepIndex = 0;
  String? _selectedChoice;
  String? _wrongLetter;
  final Set<String> _foundLetters = {};
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
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _speakForStep() async {
    await TudloVoiceButton.speak(
      context,
      switch (_stepIndex) {
        0 => 'Balik-tuon. Pamatia ang tingog. Pili-a ang N.',
        1 => 'Ini si Bantay, ang ido!',
        2 => 'Pamatia ang I, D, kag O.',
        3 => 'Diin ang letra D?',
        4 => 'Ginlubong ni Bantay ang mga letra. Pangitaa sila.',
        _ => 'I, D, O. Ido! Nabasa mo ang imo una nga tinaga!',
      },
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _chooseReviewLetter(String letter) async {
    if (_selectedChoice != null) return;
    final correct = letter == 'N';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _selectedChoice = letter;
      _wrongLetter = correct ? null : letter;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (!correct) {
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        setState(() {
          _selectedChoice = null;
          _wrongLetter = null;
        });
      }
      return;
    }
    widget.onQuizCorrect(0);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) _goToStep(1);
  }

  Future<void> _playLetter(String letter) async {
    widget.onQuizAttempt(1, true);
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    await TudloVoiceButton.speak(
      context,
      '${_letterSoundText(letter)}... $letter! Ido!',
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    widget.onQuizCorrect(1);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) _goToStep(3);
  }

  Future<void> _chooseLetter(String letter) async {
    if (_selectedChoice != null) return;
    final correct = letter == 'D';
    widget.onQuizAttempt(2, correct);
    setState(() {
      _selectedChoice = letter;
      _wrongLetter = correct ? null : letter;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (!correct) {
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        setState(() {
          _selectedChoice = null;
          _wrongLetter = null;
        });
      }
      return;
    }
    widget.onQuizCorrect(2);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) _goToStep(4);
  }

  Future<void> _findBuriedLetter(String letter) async {
    if (_foundLetters.contains(letter)) return;
    widget.onQuizAttempt(3, true);
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() => _foundLetters.add(letter));
    await TudloVoiceButton.speak(
      context,
      _letterSoundText(letter),
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_foundLetters.length == _buriedLetters.length) {
      widget.onQuizCorrect(3);
      await Future<void>.delayed(_lessonCompletionHold);
      if (mounted) _goToStep(5);
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
        key: ValueKey('g1-u1-l2-flow-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _LessonTwoIntroStep(
            progress: _progress,
            selected: _selectedChoice,
            wrongLetter: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoice: _chooseReviewLetter,
          ),
          1 => _LessonTwoMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _LessonTwoTapTrailStep(
            progress: _progress,
            title: 'Pamatia ang I, D, kag O.',
            activeSequence: _letters,
            wrongNumber: null,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTap: _playLetter,
          ),
          3 => _LessonTwoTapTrailStep(
            progress: _progress,
            title: 'Diin ang letra /d/?',
            activeSequence: _letters,
            wrongNumber: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTap: _chooseLetter,
          ),
          4 => _LessonTwoArrangeStep(
            progress: _progress,
            arrangedNumbers: _foundLetters.toList(),
            wrongNumber: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTap: _findBuriedLetter,
          ),
          _ => _LessonTwoRewardStep(
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

class _LessonTwoBeachChrome extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;

  const _LessonTwoBeachChrome({
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
      backgroundAsset: 'assets/images/level_game/backgrounds/garden.svg',
      child: child,
    );
  }
}

class _LessonTwoIntroStep extends StatelessWidget {
  final double progress;
  final String? selected;
  final String? wrongLetter;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onChoice;

  const _LessonTwoIntroStep({
    required this.progress,
    required this.selected,
    required this.wrongLetter,
    required this.onExit,
    required this.onReplay,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonTwoBeachChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .08,
          view.height * .14,
          view.width * .08,
          view.height * .045,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Pamatia ang tingog. Pili-a ang N.',
              compact: true,
            ),
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: const Alignment(-.72, .18),
                    child: _LessonKokaMascot(
                      size: (view.width * .48).clamp(170.0, 245.0),
                      mood: KokaMood.idle,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LessonTwoNumberTile(
                  number: 'N',
                  used: selected == 'N',
                  wrong: wrongLetter == 'N',
                  onTap: () => onChoice('N'),
                ),
                SizedBox(width: view.width * .06),
                _LessonTwoNumberTile(
                  number: 'T',
                  used: selected == 'T',
                  wrong: wrongLetter == 'T',
                  onTap: () => onChoice('T'),
                ),
              ],
            ),
            SizedBox(height: view.height * .024),
            _LessonOneBlueButton(
              label: 'Sige',
              onTap: selected == 'N' ? () {} : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTwoMapStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _LessonTwoMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonTwoBeachChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .07,
          view.height * .14,
          view.width * .07,
          view.height * .045,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(message: 'Ini si Bantay - ang ido!'),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LessonKokaMascot(
                  size: (view.width * .40).clamp(140.0, 215.0),
                  mood: KokaMood.idle,
                ),
                SizedBox(width: view.width * .02),
                _LessonTwoDog(size: (view.width * .43).clamp(150.0, 225.0)),
              ],
            ),
            const Spacer(),
            _LessonOneBlueButton(
              label: 'Padayon',
              onTap: () async {
                await AppAudioService.instance.playCorrect();
                onNext();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTwoDog extends StatelessWidget {
  final double size;

  const _LessonTwoDog({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/level_game/animals/dog.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFCF7A),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.pets_rounded,
            size: size * .52,
            color: TudloColors.forest,
          ),
        ),
      ),
    );
  }
}

class _LessonTwoWordCard extends StatelessWidget {
  final double size;

  const _LessonTwoWordCard({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.72,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDF73), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final letter in const ['I', 'D', 'O'])
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * .025),
              child: Text(
                letter,
                style: GoogleFonts.nunito(
                  color: Colors.black,
                  fontSize: size * .52,
                  height: 1,
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

class _LessonTwoTapTrailStep extends StatelessWidget {
  final double progress;
  final String title;
  final List<String> activeSequence;
  final String? wrongNumber;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onTap;

  const _LessonTwoTapTrailStep({
    required this.progress,
    required this.title,
    required this.activeSequence,
    required this.wrongNumber,
    required this.onExit,
    required this.onReplay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final choiceMode = title.contains('/d/');
    return _LessonTwoBeachChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            top: view.height * .15,
            child: _LessonOneMessageCard(message: title, compact: true),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            top: view.height * (choiceMode ? .32 : .30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!choiceMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final letter in activeSequence)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: view.width * .015,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LessonTwoNumberTile(
                                number: letter,
                                used: false,
                                wrong: false,
                                onTap: () => onTap(letter),
                              ),
                              SizedBox(height: view.height * .012),
                              _ClassroomRoundSpeakerButton(
                                size: (view.width * .12).clamp(44.0, 58.0),
                                onTap: () => onTap(letter),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final letter in activeSequence)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: view.width * .015,
                          ),
                          child: _LessonTwoNumberTile(
                            number: letter,
                            used: false,
                            wrong: wrongNumber == letter,
                            onTap: () => onTap(letter),
                          ),
                        ),
                    ],
                  ),
                SizedBox(height: view.height * .035),
                _LessonTwoDog(size: (view.width * .40).clamp(132.0, 205.0)),
                SizedBox(height: view.height * .018),
                _LessonTwoWordCard(size: (view.width * .26).clamp(82.0, 112.0)),
              ],
            ),
          ),
          if (choiceMode)
            Positioned(
              left: -view.width * .07,
              bottom: view.height * .08,
              child: _LessonKokaMascot(
                size: (view.width * .44).clamp(150.0, 220.0),
                mood: KokaMood.idle,
              ),
            ),
          if (!choiceMode)
            Positioned(
              left: view.width * .07,
              right: view.width * .07,
              bottom: view.height * .045,
              child: _LessonOneBlueButton(
                label: 'Padayon',
                onTap: () => onTap('I'),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonTwoRewardStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _LessonTwoRewardStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonTwoBeachChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: _StickerUnlockRewardContent(
        fallback: _LessonTwoBadge(),
        message: 'I-D-O... IDO! Nabasa mo ang imo una nga tinaga!',
        onDone: onDone,
      ),
    );
  }
}

// ignore: unused_element
enum _LessonTwoNumberCircleState { done, current, upcoming, locked, wrong }

// ignore: unused_element
class _LessonTwoNumberCircle extends StatelessWidget {
  final String number;
  final _LessonTwoNumberCircleState state;
  final VoidCallback onTap;

  const _LessonTwoNumberCircle({
    required this.number,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = (width * .165).clamp(58.0, 86.0);
    final enabled =
        state == _LessonTwoNumberCircleState.current ||
        state == _LessonTwoNumberCircleState.upcoming ||
        state == _LessonTwoNumberCircleState.done;
    final color = switch (state) {
      _LessonTwoNumberCircleState.done => TudloColors.green,
      _LessonTwoNumberCircleState.current => const Color(0xFFFFD43B),
      _LessonTwoNumberCircleState.upcoming => const Color(0xFFB8B8B8),
      _LessonTwoNumberCircleState.locked => const Color(0xFF8E8E8E),
      _LessonTwoNumberCircleState.wrong => TudloColors.coral,
    };
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: state == _LessonTwoNumberCircleState.current ? 1.08 : 1,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color:
                    (state == _LessonTwoNumberCircleState.current
                            ? const Color(0xFFFFEA61)
                            : color)
                        .withValues(alpha: .45),
                blurRadius: state == _LessonTwoNumberCircleState.current
                    ? 20
                    : 8,
                spreadRadius: state == _LessonTwoNumberCircleState.current
                    ? 5
                    : 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                number,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: size * .48,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (state == _LessonTwoNumberCircleState.locked)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: .85),
                    size: size * .28,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTwoArrangeStep extends StatelessWidget {
  final double progress;
  final List<String> arrangedNumbers;
  final String? wrongNumber;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onTap;

  const _LessonTwoArrangeStep({
    required this.progress,
    required this.arrangedNumbers,
    required this.wrongNumber,
    required this.onExit,
    required this.onReplay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonTwoBeachChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .15,
          view.width * .06,
          view.height * .06,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(
              message: 'Ginlubong ni Bantay ang mga letra!',
              compact: true,
            ),
            SizedBox(height: view.height * .05),
            _LessonTwoDog(size: (view.width * .34).clamp(118.0, 180.0)),
            SizedBox(height: view.height * .03),
            _LessonTwoArrangeSlots(numbers: arrangedNumbers),
            const Spacer(),
            _LessonTwoBuriedLetterGarden(
              foundLetters: arrangedNumbers.toSet(),
              wrongLetter: wrongNumber,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTwoArrangeSlots extends StatelessWidget {
  final List<String> numbers;

  const _LessonTwoArrangeSlots({required this.numbers});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final slotSize = (width * .145).clamp(52.0, 78.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < 5; index++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: slotSize,
              height: slotSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: .45),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: index < numbers.length
                  ? _LessonTwoNumberImage(
                      number: numbers[index],
                      size: slotSize,
                    )
                  : null,
            ),
            if (index != 4) SizedBox(width: width * .018),
          ],
        ],
      ),
    );
  }
}

class _LessonTwoNumberTile extends StatelessWidget {
  final String number;
  final bool used;
  final bool wrong;
  final VoidCallback onTap;

  const _LessonTwoNumberTile({
    required this.number,
    required this.used,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = (width * .15).clamp(54.0, 82.0);
    return _FeedbackMotion(
      correct: used,
      wrong: wrong,
      child: GestureDetector(
        onTap: used ? null : onTap,
        child: AnimatedOpacity(
          opacity: used ? .20 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: wrong
                  ? const Color(0xFFFFE2E2)
                  : Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TudloColors.blue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _LessonTwoNumberImage(number: number, size: size),
          ),
        ),
      ),
    );
  }
}

class _LessonTwoNumberImage extends StatelessWidget {
  final String number;
  final double size;

  const _LessonTwoNumberImage({required this.number, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = _unitOneLetterAsset(number);
    if (asset == null) {
      return Center(
        child: Text(
          number,
          style: GoogleFonts.nunito(
            color: TudloColors.blue,
            fontSize: size * .62,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _LessonTwoBuriedLetterGarden extends StatelessWidget {
  final Set<String> foundLetters;
  final String? wrongLetter;
  final ValueChanged<String> onTap;

  const _LessonTwoBuriedLetterGarden({
    required this.foundLetters,
    required this.wrongLetter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final moundWidth = (view.width * .19).clamp(66.0, 92.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final letter
            in _GradeOneUnitOneLessonTwoNumberFlowState._buriedLetters)
          _FeedbackMotion(
            correct: foundLetters.contains(letter),
            wrong: wrongLetter == letter,
            child: GestureDetector(
              onTap: foundLetters.contains(letter) ? null : () => onTap(letter),
              child: SizedBox(
                width: moundWidth,
                height: moundWidth * 1.08,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: moundWidth,
                        height: moundWidth * .46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B572A),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .16),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      bottom: foundLetters.contains(letter)
                          ? moundWidth * .25
                          : moundWidth * .06,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: foundLetters.contains(letter) ? 1 : .68,
                        child: _LessonTwoNumberTile(
                          number: foundLetters.contains(letter) ? letter : '?',
                          used: foundLetters.contains(letter),
                          wrong: wrongLetter == letter,
                          onTap: () => onTap(letter),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LessonTwoBadge extends StatelessWidget {
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
        'Letter\nNest 2',
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

class _GradeOneUnitOneLessonFourHouseFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitOneLessonFourHouseFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitOneLessonFourHouseFlow> createState() =>
      _GradeOneUnitOneLessonFourHouseFlowState();
}

class _GradeOneUnitOneLessonFourHouseFlowState
    extends State<_GradeOneUnitOneLessonFourHouseFlow> {
  static const _letters = ['B', 'L', 'S'];
  int _stepIndex = 0;
  String? _selectedChoice;
  String? _wrongLetter;
  final Map<int, String> _signLetters = {};
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
      _selectedChoice = null;
      _wrongLetter = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _speakForStep() async {
    await TudloVoiceButton.speak(
      context,
      switch (_stepIndex) {
        0 => 'Balik-tuon. Pamatia ang /m/. Pili-a ang M.',
        1 => 'Balay, lola, kag isda. May B, L, kag S.',
        2 => 'Pamatia ang B, L, kag S.',
        3 => 'Diin ang letra sang balay?',
        4 => 'Ibalik ang mga letra sa sign sang balay.',
        _ => 'B, L, S! Madayo gid!',
      },
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _chooseReviewLetter(String letter) async {
    if (_selectedChoice != null) return;
    final correct = letter == 'M';
    widget.onQuizAttempt(0, correct);
    setState(() {
      _selectedChoice = letter;
      _wrongLetter = correct ? null : letter;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (!correct) {
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        setState(() {
          _selectedChoice = null;
          _wrongLetter = null;
        });
      }
      return;
    }
    widget.onQuizCorrect(0);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) _goToStep(1);
  }

  Future<void> _playLetter(String letter) async {
    widget.onQuizAttempt(1, true);
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    await TudloVoiceButton.speak(
      context,
      '${_letterSoundText(letter)}... $letter!',
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _chooseGuidedLetter(String letter) async {
    if (_selectedChoice != null) return;
    final correct = letter == 'B';
    widget.onQuizAttempt(2, correct);
    setState(() {
      _selectedChoice = letter;
      _wrongLetter = correct ? null : letter;
    });
    await (correct
        ? AppAudioService.instance.playCorrect()
        : AppAudioService.instance.playWrong());
    if (!mounted) return;
    if (!correct) {
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        setState(() {
          _selectedChoice = null;
          _wrongLetter = null;
        });
      }
      return;
    }
    widget.onQuizCorrect(2);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) _goToStep(4);
  }

  Future<void> _placeSignLetter(int index, String letter) async {
    final expected = _letters[index];
    final correct = letter == expected;
    widget.onQuizAttempt(3, correct);
    if (!correct) {
      setState(() => _wrongLetter = letter);
      await AppAudioService.instance.playWrong();
      if (!mounted) return;
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (mounted) setState(() => _wrongLetter = null);
      return;
    }
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() {
      _signLetters[index] = letter;
      _wrongLetter = null;
    });
    await TudloVoiceButton.speak(
      context,
      _letterSoundText(letter),
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_signLetters.length == _letters.length) {
      widget.onQuizCorrect(3);
      await Future<void>.delayed(_lessonCompletionHold);
      if (mounted) _goToStep(5);
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
        key: ValueKey('g1-u1-l4-flow-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _LessonFourReviewStep(
            progress: _progress,
            selected: _selectedChoice,
            wrongLetter: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoice: _chooseReviewLetter,
          ),
          1 => _LessonFourTeachStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _LessonFourListenStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlayLetter: _playLetter,
            onNext: () {
              widget.onQuizCorrect(1);
              _goToStep(3);
            },
          ),
          3 => _LessonFourGuidedStep(
            progress: _progress,
            selected: _selectedChoice,
            wrongLetter: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onChoice: _chooseGuidedLetter,
          ),
          4 => _LessonFourChallengeStep(
            progress: _progress,
            signLetters: _signLetters,
            wrongLetter: _wrongLetter,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlace: _placeSignLetter,
          ),
          _ => _LessonFourRewardStep(
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

class _LessonFourChrome extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;
  final String backgroundAsset;

  const _LessonFourChrome({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.child,
    this.backgroundAsset = 'assets/images/level_game/backgrounds/garden.svg',
  });

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      child: child,
    );
  }
}

class _LessonFourReviewStep extends StatelessWidget {
  final double progress;
  final String? selected;
  final String? wrongLetter;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onChoice;

  const _LessonFourReviewStep({
    required this.progress,
    required this.selected,
    required this.wrongLetter,
    required this.onExit,
    required this.onReplay,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonFourChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            top: view.height * .145,
            child: const _LessonOneMessageCard(
              message: 'Pamatia ang /m/. Pili-a ang M.',
              compact: true,
            ),
          ),
          Positioned(
            left: -view.width * .08,
            top: view.height * .31,
            child: _LessonKokaMascot(
              size: (view.width * .64).clamp(220.0, 330.0),
              mood: KokaMood.idle,
            ),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            bottom: view.height * .14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LessonTwoNumberTile(
                  number: 'M',
                  used: selected == 'M',
                  wrong: wrongLetter == 'M',
                  onTap: () => onChoice('M'),
                ),
                SizedBox(width: view.width * .08),
                _LessonTwoNumberTile(
                  number: 'K',
                  used: selected == 'K',
                  wrong: wrongLetter == 'K',
                  onTap: () => onChoice('K'),
                ),
              ],
            ),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .045,
            child: _LessonOneBlueButton(
              label: 'Sige',
              onTap: selected == 'M' ? () {} : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonFourChallengeStep extends StatelessWidget {
  final double progress;
  final Map<int, String> signLetters;
  final String? wrongLetter;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(int index, String letter) onPlace;

  const _LessonFourChallengeStep({
    required this.progress,
    required this.signLetters,
    required this.wrongLetter,
    required this.onExit,
    required this.onReplay,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonFourChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset:
          'assets/images/level_game/backgrounds/house-activity.svg',
      child: Stack(
        children: [
          Positioned(
            left: view.width * .06,
            right: view.width * .06,
            top: view.height * .13,
            child: const _LessonOneMessageCard(
              message: 'Ibalik ang mga letra sa sign sang balay!',
              compact: true,
            ),
          ),
          Positioned(
            left: view.width * .08,
            right: view.width * .08,
            top: view.height * .30,
            child: _LessonFourSign(signLetters: signLetters, onPlace: onPlace),
          ),
          Positioned(
            left: -view.width * .13,
            bottom: view.height * .20,
            child: _LessonKokaMascot(
              size: (view.width * .42).clamp(150.0, 220.0),
              mood: KokaMood.idle,
            ),
          ),
          Positioned(
            left: view.width * .05,
            right: view.width * .05,
            bottom: view.height * .13,
            child: _LessonFourDraggableLetters(
              usedLetters: signLetters.values.toSet(),
              wrongLetter: wrongLetter,
            ),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .045,
            child: _LessonOneBlueButton(
              label: 'Humanon',
              onTap: signLetters.length == 3 ? () {} : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonFourTeachStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _LessonFourTeachStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonFourChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .13,
          view.width * .06,
          view.height * .045,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(message: 'Balay, lola, kag isda!'),
            const Spacer(),
            _LessonFourScene(),
            const Spacer(),
            _LessonOneBlueButton(label: 'Padayon', onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _LessonFourListenStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onPlayLetter;
  final VoidCallback onNext;

  const _LessonFourListenStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onPlayLetter,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonFourChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .13,
          view.width * .06,
          view.height * .045,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(message: 'Pamatia ang B, L, kag S.'),
            const Spacer(),
            _LessonFourAnchorRow(onPlayLetter: onPlayLetter),
            SizedBox(height: view.height * .04),
            Align(
              alignment: Alignment.centerLeft,
              child: _LessonKokaMascot(
                size: (view.width * .34).clamp(120.0, 180.0),
                mood: KokaMood.idle,
              ),
            ),
            const Spacer(),
            _LessonOneBlueButton(label: 'Padayon', onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _LessonFourGuidedStep extends StatelessWidget {
  final double progress;
  final String? selected;
  final String? wrongLetter;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final ValueChanged<String> onChoice;

  const _LessonFourGuidedStep({
    required this.progress,
    required this.selected,
    required this.wrongLetter,
    required this.onExit,
    required this.onReplay,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _LessonFourChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          view.width * .06,
          view.height * .14,
          view.width * .06,
          view.height * .045,
        ),
        child: Column(
          children: [
            const _LessonOneMessageCard(message: 'Diin ang letra sang balay?'),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final letter
                    in _GradeOneUnitOneLessonFourHouseFlowState._letters)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: view.width * .012,
                    ),
                    child: _LessonTwoNumberTile(
                      number: letter,
                      used: selected == letter && wrongLetter != letter,
                      wrong: wrongLetter == letter,
                      onTap: () => onChoice(letter),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: _LessonKokaMascot(
                size: (view.width * .42).clamp(150.0, 220.0),
                mood: KokaMood.idle,
              ),
            ),
            const _LessonOneMessageCard(
              message: 'Pamatia ang /b/.',
              compact: true,
            ),
            SizedBox(height: view.height * .024),
            _LessonOneBlueButton(
              label: 'Sunod',
              onTap: selected == 'B' ? () {} : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonFourRewardStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _LessonFourRewardStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonFourChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: _StickerUnlockRewardContent(
        fallback: _LessonFourBadge(),
        message: 'B, L, S! Madayo gid!',
        onDone: onDone,
      ),
    );
  }
}

class _LessonFourScene extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return SizedBox(
      height: view.height * .44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: view.width * .02,
            top: view.height * .02,
            child: _LessonFourPicture(
              asset: 'assets/images/level_game/house.png',
              fallback: Icons.home_rounded,
              size: (view.width * .34).clamp(120.0, 175.0),
            ),
          ),
          Positioned(
            right: view.width * .05,
            top: view.height * .02,
            child: _LessonFourLola(
              size: (view.width * .28).clamp(105.0, 155.0),
            ),
          ),
          Positioned(
            right: view.width * .10,
            bottom: view.height * .01,
            child: _LessonFourFish(
              size: (view.width * .30).clamp(108.0, 160.0),
            ),
          ),
          Positioned(
            left: view.width * .16,
            bottom: 0,
            child: _LessonKokaMascot(
              size: (view.width * .36).clamp(130.0, 190.0),
              mood: KokaMood.idle,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonFourAnchorRow extends StatelessWidget {
  final ValueChanged<String> onPlayLetter;

  const _LessonFourAnchorRow({required this.onPlayLetter});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final item in const [('B', 'balay'), ('L', 'lola'), ('S', 'isda')])
          SizedBox(
            width: view.width * .265,
            child: _LessonFourAnchorCard(
              letter: item.$1,
              word: item.$2,
              onPlay: () => onPlayLetter(item.$1),
            ),
          ),
      ],
    );
  }
}

class _LessonFourAnchorCard extends StatelessWidget {
  final String letter;
  final String word;
  final VoidCallback onPlay;

  const _LessonFourAnchorCard({
    required this.letter,
    required this.word,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDF73), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .11),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IntroLetterArt(
            letter: letter,
            size: (width * .17).clamp(58.0, 86.0),
          ),
          SizedBox(height: width * .012),
          _ClassroomRoundSpeakerButton(
            size: (width * .115).clamp(42.0, 56.0),
            onTap: onPlay,
          ),
          SizedBox(height: width * .008),
          Text(
            word,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: (width * .042).clamp(15.0, 22.0),
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

class _LessonFourSign extends StatelessWidget {
  final Map<int, String> signLetters;
  final Future<void> Function(int index, String letter) onPlace;

  const _LessonFourSign({required this.signLetters, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final slotSize = (view.width * .18).clamp(62.0, 88.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8793A), width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < 3; index++) ...[
            _LessonFourSignSlot(
              index: index,
              letter: signLetters[index],
              size: slotSize,
              onPlace: onPlace,
            ),
            if (index != 2) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _LessonFourSignSlot extends StatelessWidget {
  final int index;
  final String? letter;
  final double size;
  final Future<void> Function(int index, String letter) onPlace;

  const _LessonFourSignSlot({
    required this.index,
    required this.letter,
    required this.size,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => unawaited(onPlace(index, details.data)),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .86),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? TudloColors.green
                  : TudloColors.muted.withValues(alpha: .35),
              width: 3,
            ),
          ),
          child: letter == null
              ? Text(
                  '.',
                  style: GoogleFonts.nunito(
                    color: TudloColors.muted.withValues(alpha: .55),
                    fontSize: size * .60,
                    height: .5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                )
              : _IntroLetterArt(letter: letter!, size: size * .84),
        );
      },
    );
  }
}

class _LessonFourDraggableLetters extends StatelessWidget {
  final Set<String> usedLetters;
  final String? wrongLetter;

  const _LessonFourDraggableLetters({
    required this.usedLetters,
    required this.wrongLetter,
  });

  @override
  Widget build(BuildContext context) {
    final letters = const ['L', 'S', 'K', 'B'];
    final view = MediaQuery.sizeOf(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: view.width * .035,
      runSpacing: 12,
      children: [
        for (final letter in letters)
          _FeedbackMotion(
            correct: usedLetters.contains(letter),
            wrong: wrongLetter == letter,
            child: Draggable<String>(
              data: letter,
              feedback: Material(
                color: Colors.transparent,
                child: _LessonTwoNumberTile(
                  number: letter,
                  used: false,
                  wrong: false,
                  onTap: () {},
                ),
              ),
              childWhenDragging: Opacity(
                opacity: .28,
                child: _LessonTwoNumberTile(
                  number: letter,
                  used: usedLetters.contains(letter),
                  wrong: wrongLetter == letter,
                  onTap: () {},
                ),
              ),
              child: _LessonTwoNumberTile(
                number: letter,
                used: usedLetters.contains(letter),
                wrong: wrongLetter == letter,
                onTap: () {},
              ),
            ),
          ),
      ],
    );
  }
}

// ignore: unused_element
class _LessonFourCompleteHouseSign extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Container(
      width: (view.width * .72).clamp(250.0, 360.0),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB8793A), width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .13),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final letter
              in _GradeOneUnitOneLessonFourHouseFlowState._letters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _IntroLetterArt(letter: letter, size: 74),
            ),
        ],
      ),
    );
  }
}

class _LessonFourPicture extends StatelessWidget {
  final String asset;
  final IconData fallback;
  final double size;

  const _LessonFourPicture({
    required this.asset,
    required this.fallback,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: _LessonPictureAsset(
        asset: asset,
        errorBuilder: (_) => DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7DF),
            shape: BoxShape.circle,
          ),
          child: Icon(fallback, size: size * .50, color: TudloColors.forest),
        ),
      ),
    );
  }
}

class _LessonFourLola extends StatelessWidget {
  final double size;

  const _LessonFourLola({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle, size: size, color: const Color(0xFFFFE1B5)),
          Icon(
            Icons.elderly_woman_rounded,
            size: size * .72,
            color: const Color(0xFF795548),
          ),
        ],
      ),
    );
  }
}

class _LessonFourFish extends StatelessWidget {
  final double size;

  const _LessonFourFish({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.water_drop_rounded,
            size: size,
            color: const Color(0xFF31B6FF),
          ),
          Icon(
            Icons.set_meal_rounded,
            size: size * .72,
            color: const Color(0xFF0D78D8),
          ),
        ],
      ),
    );
  }
}

class _LessonFourBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: (width * .62).clamp(220.0, 330.0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        'Letter Nest 4',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: (width * .06).clamp(22.0, 32.0),
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
