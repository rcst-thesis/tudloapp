part of '../../level_game_page.dart';

class _GradeOneUnitOneLessonSevenBeachFlow extends StatefulWidget {
  final VoidCallback onExit;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitOneLessonSevenBeachFlow({
    required this.onExit,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitOneLessonSevenBeachFlow> createState() =>
      _GradeOneUnitOneLessonSevenBeachFlowState();
}

class _GradeOneUnitOneLessonSevenBeachFlowState
    extends State<_GradeOneUnitOneLessonSevenBeachFlow> {
  static const _voiceBase = 'audio/VO-final/grade1';
  static const _numbers = [1, 2, 3, 4, 5];
  int _stepIndex = 0;
  int _expectedStep = 1;
  int _kokaPosition = 0;
  bool _wrongTap = false;
  bool _arrangeComplete = false;
  bool _completed = false;
  late final List<int> _tiles = _shuffledChoices(_numbers);
  final List<int?> _slots = List<int?>.filled(5, null);
  int? _wrongTile;

  @override
  void initState() {
    super.initState();
    if (_tiles.indexed.every((entry) => entry.$2 == _numbers[entry.$1])) {
      final first = _tiles.removeAt(0);
      _tiles.add(first);
    }
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
    unawaited(_goToStepAfterStoppingAudio(index));
  }

  Future<void> _goToStepAfterStoppingAudio(int index) async {
    final next = index.clamp(0, 5);
    if (next == _stepIndex) return;
    await TudloVoiceButton.stop();
    if (!mounted || next == _stepIndex) return;
    setState(() {
      _stepIndex = next;
      _wrongTap = false;
      _wrongTile = null;
      if (next == 4) _arrangeComplete = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakForStep();
    });
  }

  Future<void> _playVoice(List<int> clips) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    await AppAudioService.instance.playVoiceAssets([
      for (final clip in clips) '$_voiceBase/Gr_1_Les_1_7_$clip.wav',
    ]);
    await AppAudioService.instance.restoreBackgroundVolume();
  }

  Future<void> _speakForStep() async {
    final clips = switch (_stepIndex) {
      0 => const [2],
      1 => const [3],
      2 => const [4, 5],
      3 => const [8],
      4 => const [11],
      _ => const [12],
    };
    if (clips.isEmpty) return;
    try {
      await _playVoice(clips);
    } catch (_) {
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        switch (_stepIndex) {
          0 => 'Init gid ang balas! Buligi ako makalab-ot sa payong.',
          1 => 'I-tap ang Beach sa mapa.',
          2 => 'I-tap ang 1, dayon ang 2.',
          3 => 'Sunod, i-tap ang 3, 4, kag 5.',
          4 => 'Ihan-ay ang 1, 2, 3, 4, kag 5.',
          _ => 'Yehey! Nakaabot kita sa payong!',
        },
        hiligaynon: true,
        waitForCompletion: true,
      );
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  Future<void> _tapPathNumber(int number) async {
    if (number != _expectedStep) {
      setState(() => _wrongTap = true);
      await AppAudioService.instance.playWrong();
      try {
        await _playVoice([7]);
      } catch (_) {
        if (mounted) {
          await TudloVoiceButton.speak(
            context,
            'Hmmm, hindi amo na.',
            hiligaynon: true,
          );
        }
      }
      if (!mounted) return;
      setState(() => _wrongTap = false);
      return;
    }
    widget.onQuizAttempt((number - 1).clamp(0, 4), true);
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() {
      _kokaPosition = number;
      _expectedStep = number + 1;
    });
    await TudloVoiceButton.speak(
      context,
      _hiligaynonNumberWord('$number'),
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (number == 2) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      try {
        await _playVoice([6]);
      } catch (_) {}
      if (mounted) _goToStep(3);
      return;
    }
    if (number == 4) {
      try {
        await _playVoice([9]);
      } catch (_) {}
    }
    if (number == 5) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) _goToStep(4);
    }
  }

  Future<void> _placeTile(int number) async {
    if (_arrangeComplete) return;
    final slotIndex = _slots.indexWhere((value) => value == null);
    if (slotIndex == -1) return;
    final correct = number == slotIndex + 1;
    widget.onQuizAttempt(4, correct);
    if (!correct) {
      setState(() => _wrongTile = number);
      await AppAudioService.instance.playWrong();
      try {
        await _playVoice([10]);
      } catch (_) {
        if (mounted) {
          await TudloVoiceButton.speak(
            context,
            'Hmmm, hindi amo na.',
            hiligaynon: true,
          );
        }
      }
      if (mounted) setState(() => _wrongTile = null);
      return;
    }
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    setState(() {
      _slots[slotIndex] = number;
    });
    if (_slots.indexed.every((entry) => entry.$2 == entry.$1 + 1)) {
      widget.onQuizCorrect(4);
      setState(() => _arrangeComplete = true);
      await Future<void>.delayed(_lessonCompletionHold);
      if (!mounted) return;
      if (mounted) _goToStep(5);
    }
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
        key: ValueKey('g1-u1-l7-$_stepIndex'),
        child: switch (_stepIndex) {
          0 => _BeachIntroStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(1),
          ),
          1 => _BeachMapStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onNext: () => _goToStep(2),
          ),
          2 => _BeachPathStep(
            progress: _progress,
            message: 'I-tap ang 1, dayon ang 2.',
            enabledNumbers: const {1, 2},
            completedUpTo: _kokaPosition,
            expectedNumber: _expectedStep,
            wrong: _wrongTap,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTapNumber: _tapPathNumber,
          ),
          3 => _BeachPathStep(
            progress: _progress,
            message: 'Sunod ang 3, 4, kag 5.',
            enabledNumbers: const {3, 4, 5},
            completedUpTo: _kokaPosition,
            expectedNumber: _expectedStep,
            wrong: _wrongTap,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onTapNumber: _tapPathNumber,
          ),
          4 => _BeachArrangeStep(
            progress: _progress,
            tiles: _tiles,
            slots: _slots,
            wrongTile: _wrongTile,
            complete: _arrangeComplete,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onPlaceTile: _placeTile,
          ),
          _ => _BeachRewardStep(
            progress: _progress,
            onExit: widget.onExit,
            onReplay: _speakForStep,
            onDone: _finish,
          ),
        },
      ),
    );
  }
}

class _BeachLessonChrome extends StatelessWidget {
  static const _mascotLeftFraction = .03;
  static const _mascotTopFraction = .30;
  static const _mascotWidthFraction = .50;
  static const _mascotMinSize = 185.0;
  static const _mascotMaxSize = 255.0;

  static const originalBackground =
      'assets/images/level_game/backgrounds/beach_with_number_path.svg';
  static const cleanBackground =
      'assets/images/level_game/backgrounds/beach_clean_path.svg';

  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;
  final String backgroundAsset;

  const _BeachLessonChrome({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.child,
    this.backgroundAsset = cleanBackground,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: backgroundAsset,
      backgroundFit: BoxFit.fill,
      child: child,
    );
  }
}

class _BeachIntroStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _BeachIntroStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _BeachLessonChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      backgroundAsset: _BeachLessonChrome.originalBackground,
      child: Stack(
        children: [
          Positioned(
            left: view.width * _BeachLessonChrome._mascotLeftFraction,
            top: view.height * _BeachLessonChrome._mascotTopFraction,
            child: _LessonKokaMascot(
              size: (view.width * _BeachLessonChrome._mascotWidthFraction)
                  .clamp(
                    _BeachLessonChrome._mascotMinSize,
                    _BeachLessonChrome._mascotMaxSize,
                  ),
              mood: KokaMood.idle,
            ),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .14,
            child: _LessonOneMessageCard(message: 'Init gid ang balas!'),
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .045,
            child: _LessonOneBlueButton(label: 'Sige', onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _BeachMapStep extends StatefulWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _BeachMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_BeachMapStep> createState() => _BeachMapStepState();
}

class _BeachMapStepState extends State<_BeachMapStep> {
  // Under a Tudlo host this beat uses Tudlo's one real Map screen rather than
  // the inline map below. Its own standalone overrides (not
  // MapProgressScope's shared instance) glow only Beach for the length of
  // that push and pop back here once Beach is tapped; every other location
  // keeps its real locked/unlocked behaviour. Mirrors _LessonOneMapStep in
  // grade_one_letter_flow.dart, which targets School.
  var _openedHostedMap = false;
  bool _hosted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hosted = DevGLessonHostScope.maybeOf(context) != null;
    if (_hosted && !_openedHostedMap) {
      _openedHostedMap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openHostedMap());
    }
  }

  Future<void> _openHostedMap() async {
    if (!mounted) return;
    await _showMapBeatInstructionDialog(
      context,
      message: 'I-tap ang Beach sa mapa.',
    );
    if (!mounted) return;
    await pushLessonMapBeat(
      context,
      target: tudlo_map.MapLocation.beach,
      expanded: true,
    );
    if (!mounted) return;
    await AppAudioService.instance.playCorrect();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    if (_hosted) {
      // The real map is a pushed route, so this step itself shows only chrome.
      return _LessonOneChrome(
        progress: widget.progress,
        onExit: widget.onExit,
        onReplay: widget.onReplay,
        child: const SizedBox.shrink(),
      );
    }
    final view = MediaQuery.sizeOf(context);
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      backgroundAsset: 'assets/images/level_game/backgrounds/tudlomap.svg',
      child: Stack(
        children: [
          const Positioned.fill(
            child: _LessonBackgroundAsset(
              asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
            ),
          ),
          Positioned(
            right: view.width * .10,
            bottom: view.height * .18,
            width: view.width * .30,
            height: view.width * .30,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await AppAudioService.instance.playCorrect();
                widget.onNext();
              },
              child: const _LessonOneMapDestinationCue(),
            ),
          ),
          Positioned(
            left: view.width * .10,
            right: view.width * .10,
            bottom: view.height * .08,
            child: const _LessonOneMessageCard(message: 'Tap ang Beach.'),
          ),
        ],
      ),
    );
  }
}

class _BeachPathStep extends StatelessWidget {
  final double progress;
  final String message;
  final Set<int> enabledNumbers;
  final int completedUpTo;
  final int expectedNumber;
  final bool wrong;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(int number) onTapNumber;

  const _BeachPathStep({
    required this.progress,
    required this.message,
    required this.enabledNumbers,
    required this.completedUpTo,
    required this.expectedNumber,
    required this.wrong,
    required this.onExit,
    required this.onReplay,
    required this.onTapNumber,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _BeachLessonChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Stack(
        children: [
          _BeachNumberPathScene(
            completedUpTo: completedUpTo,
            expectedNumber: expectedNumber,
            enabledNumbers: enabledNumbers,
            wrong: wrong,
            onTapNumber: onTapNumber,
          ),
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            bottom: view.height * .055,
            child: _LessonOneMessageCard(message: message),
          ),
        ],
      ),
    );
  }
}

class _BeachNumberPathScene extends StatelessWidget {
  static const _rockPoints = [
    Offset(.20, .64),
    Offset(.38, .64),
    Offset(.56, .62),
    Offset(.73, .58),
    Offset(.87, .52),
  ];

  final int completedUpTo;
  final int expectedNumber;
  final Set<int> enabledNumbers;
  final bool wrong;
  final Future<void> Function(int number) onTapNumber;

  const _BeachNumberPathScene({
    required this.completedUpTo,
    required this.expectedNumber,
    required this.enabledNumbers,
    required this.wrong,
    required this.onTapNumber,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rockWidth = math
            .min(size.width * .21, size.height * .096)
            .clamp(76.0, 104.0);
        final kokaSize = math
            .min(size.width * .58, size.height * .27)
            .clamp(240.0, 330.0);
        final kokaNumber = completedUpTo > 0
            ? completedUpTo.clamp(1, 5)
            : expectedNumber.clamp(1, 5);
        final kokaCenter = _pointForNumber(kokaNumber, size);
        final kokaLeft = (kokaCenter.dx - (kokaSize * .68)).clamp(
          8.0,
          size.width - kokaSize - 8,
        );
        final rockTop = kokaCenter.dy - (rockWidth * .48);
        final kokaTop = (rockTop - kokaSize - 18).clamp(
          size.height * .13,
          size.height - kokaSize - 120,
        );

        return Stack(
          children: [
            for (final number
                in _GradeOneUnitOneLessonSevenBeachFlowState._numbers)
              _BeachNumberPathRock(
                center: _pointForNumber(number, size),
                number: number,
                completed: number <= completedUpTo,
                active:
                    enabledNumbers.contains(number) && number == expectedNumber,
                enabled: enabledNumbers.contains(number),
                wrong: wrong && enabledNumbers.contains(number),
                size: rockWidth,
                stageWidth: size.width,
                onTap: () => onTapNumber(number),
              ),
            Positioned(
              left: kokaLeft,
              top: kokaTop,
              child: _LessonKokaMascot(size: kokaSize, mood: KokaMood.idle),
            ),
          ],
        );
      },
    );
  }

  Offset _pointForNumber(int number, Size size) {
    final point = _rockPoints[(number - 1).clamp(0, _rockPoints.length - 1)];
    return Offset(point.dx * size.width, point.dy * size.height);
  }
}

class _BeachNumberPathRock extends StatelessWidget {
  final Offset center;
  final int number;
  final bool completed;
  final bool active;
  final bool enabled;
  final bool wrong;
  final double size;
  final double stageWidth;
  final VoidCallback onTap;

  const _BeachNumberPathRock({
    required this.center,
    required this.number,
    required this.completed,
    required this.active,
    required this.enabled,
    required this.wrong,
    required this.size,
    required this.stageWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (center.dx - (size / 2)).clamp(8.0, stageWidth - size - 8),
      top: center.dy - (size * .48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _BeachStepRock(
            number: number,
            completed: completed,
            active: active,
            enabled: enabled,
            wrong: wrong,
            size: size,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _BeachArrangeStep extends StatelessWidget {
  final double progress;
  final List<int> tiles;
  final List<int?> slots;
  final int? wrongTile;
  final bool complete;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Future<void> Function(int number) onPlaceTile;

  const _BeachArrangeStep({
    required this.progress,
    required this.tiles,
    required this.slots,
    required this.wrongTile,
    required this.complete,
    required this.onExit,
    required this.onReplay,
    required this.onPlaceTile,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final placed = slots.whereType<int>().toSet();
    return _BeachLessonChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: Stack(
        children: [
          Positioned(
            left: view.width * .07,
            right: view.width * .07,
            top: view.height * .35,
            child: const _LessonOneMessageCard(
              message: 'Ihan-ay ang 1 pakadto 5.',
            ),
          ),
          Positioned(
            left: view.width * .025,
            right: view.width * .025,
            top: view.height * .53,
            child: _BeachArrangeSlots(
              slots: slots,
              complete: complete,
              onPlaceTile: onPlaceTile,
            ),
          ),
          if (!complete)
            Positioned(
              left: view.width * .08,
              right: view.width * .08,
              bottom: view.height * .045,
              child: _BeachNumberChoiceGrid(
                tiles: tiles,
                placed: placed,
                wrongTile: wrongTile,
                onPlaceTile: onPlaceTile,
              ),
            ),
        ],
      ),
    );
  }
}

class _BeachRewardStep extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  const _BeachRewardStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return _BeachLessonChrome(
      progress: progress,
      onExit: onExit,
      onReplay: onReplay,
      child: _StickerUnlockRewardContent(
        fallback: const _FamilyReferenceBadge(label: 'NUMBER\nEXPLORER'),
        message: 'Yehey! Nakaabot kita sa payong!',
        stickerAsset: 'assets/images/home_sticker_cat.png',
        portraitStickerRatio: 248 / 472,
        stickerScale: .82,
        stickerAlignmentY: .13,
        messageStickerGap: 30,
        floatSticker: true,
        showOkButton: false,
        onDone: onDone,
      ),
    );
  }
}

enum _BeachNumberRockTone { normal, active, completed }

class _BeachStepRock extends StatelessWidget {
  final int number;
  final bool completed;
  final bool active;
  final bool enabled;
  final bool wrong;
  final double size;
  final VoidCallback onTap;

  const _BeachStepRock({
    required this.number,
    required this.completed,
    required this.active,
    required this.enabled,
    required this.wrong,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = completed
        ? _BeachNumberRockTone.completed
        : active
        ? _BeachNumberRockTone.active
        : _BeachNumberRockTone.normal;
    return _FeedbackMotion(
      correct: completed,
      wrong: wrong && active,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: size * .92,
                  height: size * .58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    color: const Color(0xFFFFE67A).withValues(alpha: .14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD33D).withValues(alpha: .62),
                        blurRadius: size * .22,
                        spreadRadius: size * .06,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFF4AE).withValues(alpha: .34),
                        blurRadius: size * .34,
                        spreadRadius: size * .02,
                      ),
                    ],
                  ),
                ),
              ),
              _BeachNumberRockSprite(number: number, tone: tone, width: size),
              IgnorePointer(
                child: Text(
                  '$number',
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: size * .38,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: .78),
                        blurRadius: 3,
                      ),
                    ],
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

class _BeachNumberRockSprite extends StatelessWidget {
  static const _asset =
      'assets/images/level_game/number_rocks_normal_yellow_green.svg';
  static const _sourceWidth = 980.0;
  static const _sourceHeight = 560.0;
  static const _cropWidth = 158.0;
  static const _cropHeight = 120.0;
  static const _rockX = [120.0, 280.0, 440.0, 600.0, 760.0];
  static const _normalY = [83.0, 79.0, 65.0, 49.0, 35.0];

  final int number;
  final _BeachNumberRockTone tone;
  final double width;

  const _BeachNumberRockSprite({
    required this.number,
    required this.tone,
    required this.width,
  });

  Rect get _sourceRect {
    final index = (number - 1).clamp(0, _rockX.length - 1);
    final rowOffset = switch (tone) {
      _BeachNumberRockTone.normal => 0.0,
      _BeachNumberRockTone.active => 170.0,
      _BeachNumberRockTone.completed => 340.0,
    };
    return Rect.fromLTWH(
      _rockX[index] - 14,
      _normalY[index] + rowOffset - 18,
      _cropWidth,
      _cropHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = _sourceRect;
    final scale = width / source.width;
    final height = source.height * scale;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _sourceWidth * scale,
          maxWidth: _sourceWidth * scale,
          minHeight: _sourceHeight * scale,
          maxHeight: _sourceHeight * scale,
          child: Transform.translate(
            offset: Offset(-source.left * scale, -source.top * scale),
            child: SvgPicture.asset(
              _asset,
              width: _sourceWidth * scale,
              height: _sourceHeight * scale,
              fit: BoxFit.fill,
              semanticsLabel: 'Number $number rock',
            ),
          ),
        ),
      ),
    );
  }
}

class _BeachArrangeSlots extends StatelessWidget {
  final List<int?> slots;
  final bool complete;
  final Future<void> Function(int number) onPlaceTile;

  const _BeachArrangeSlots({
    required this.slots,
    required this.complete,
    required this.onPlaceTile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width * .88;
        final padding = (width * .022).clamp(6.0, 10.0);
        final gap = (width * .008).clamp(3.0, 5.0);
        final innerWidth = width - (padding * 2) - 8;
        final maxSlotSize = (innerWidth - (gap * 4)) / 5;
        final slotSize = maxSlotSize.clamp(40.0, 86.0);
        return Container(
          width: width,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E6).withValues(alpha: .90),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD7A65F), width: 3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < slots.length; index++) ...[
                DragTarget<int>(
                  onWillAcceptWithDetails: (_) =>
                      !complete && slots[index] == null,
                  onAcceptWithDetails: (details) {
                    unawaited(onPlaceTile(details.data));
                  },
                  builder: (context, candidateData, rejectedData) {
                    final number = slots[index];
                    return Container(
                      width: slotSize,
                      height: slotSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: number == null
                            ? Colors.white.withValues(alpha: .66)
                            : complete
                            ? TudloColors.softGreen
                            : Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: number == null
                              ? Colors.grey.withValues(alpha: .62)
                              : complete
                              ? TudloColors.green
                              : TudloColors.blue,
                          width: 3,
                        ),
                        boxShadow: number == null
                            ? null
                            : [
                                BoxShadow(
                                  color: TudloColors.blue.withValues(
                                    alpha: .14,
                                  ),
                                  blurRadius: 0,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: number == null
                          ? const SizedBox.shrink()
                          : Text(
                              '$number',
                              style: GoogleFonts.nunito(
                                color: complete
                                    ? TudloColors.green
                                    : _numberTileColor(number),
                                fontSize: slotSize * .46,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                    );
                  },
                ),
                if (index != slots.length - 1) SizedBox(width: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BeachNumberChoiceGrid extends StatelessWidget {
  final List<int> tiles;
  final Set<int> placed;
  final int? wrongTile;
  final Future<void> Function(int number) onPlaceTile;

  const _BeachNumberChoiceGrid({
    required this.tiles,
    required this.placed,
    required this.wrongTile,
    required this.onPlaceTile,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tileSize = (width * .19).clamp(72.0, 96.0);
    final firstRow = tiles.take(3).toList(growable: false);
    final secondRow = tiles.skip(3).take(2).toList(growable: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final tile in firstRow) ...[
              Visibility(
                visible: !placed.contains(tile),
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: _BeachNumberTile(
                  number: tile,
                  wrong: wrongTile == tile,
                  size: tileSize,
                  onTap: () => onPlaceTile(tile),
                ),
              ),
              if (tile != firstRow.last) SizedBox(width: width * .035),
            ],
          ],
        ),
        SizedBox(height: width * .035),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final tile in secondRow) ...[
              Visibility(
                visible: !placed.contains(tile),
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: _BeachNumberTile(
                  number: tile,
                  wrong: wrongTile == tile,
                  size: tileSize,
                  onTap: () => onPlaceTile(tile),
                ),
              ),
              if (tile != secondRow.last) SizedBox(width: width * .035),
            ],
          ],
        ),
      ],
    );
  }
}

class _BeachNumberTile extends StatelessWidget {
  final int number;
  final bool wrong;
  final double? size;
  final VoidCallback onTap;

  const _BeachNumberTile({
    required this.number,
    required this.wrong,
    this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize =
        size ?? (MediaQuery.sizeOf(context).width * .16).clamp(56.0, 76.0);
    final tile = _FeedbackMotion(
      correct: false,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: tileSize,
          height: tileSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TudloColors.blue, width: 3),
            boxShadow: [
              BoxShadow(
                color: TudloColors.blue.withValues(alpha: .18),
                blurRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            '$number',
            style: GoogleFonts.nunito(
              color: _numberTileColor(number),
              fontSize: tileSize * .48,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
    return Draggable<int>(
      data: number,
      feedback: Material(color: Colors.transparent, child: tile),
      childWhenDragging: Opacity(opacity: .28, child: tile),
      child: tile,
    );
  }
}

Color _numberTileColor(int number) {
  return switch (number) {
    1 => const Color(0xFFE93545),
    2 => TudloColors.green,
    3 => const Color(0xFFF47E20),
    4 => TudloColors.blue,
    5 => const Color(0xFF7D36D6),
    _ => TudloColors.ink,
  };
}

class _NumberExplorerSticker extends StatefulWidget {
  final double size;
  final VoidCallback onTap;

  const _NumberExplorerSticker({required this.size, required this.onTap});

  @override
  State<_NumberExplorerSticker> createState() => _NumberExplorerStickerState();
}

class _NumberExplorerStickerState extends State<_NumberExplorerSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

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
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () async {
          await AppAudioService.instance.playTap();
          widget.onTap();
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size * .74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFFFD33D),
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: .90),
                      blurRadius: 14,
                    ),
                    Shadow(
                      color: const Color(0xFFFF9C00).withValues(alpha: .45),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: widget.size * .10,
                right: widget.size * .10,
                bottom: widget.size * .06,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD92B3A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFF1A3),
                      width: 3,
                    ),
                  ),
                  child: Text(
                    'Number\nExplorer',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: (widget.size * .105).clamp(22.0, 34.0),
                      height: .9,
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
    );
  }
}

class _GradeOneNumberLesson extends StatefulWidget {
  final LevelContent content;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneNumberLesson({
    required this.content,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneNumberLesson> createState() => _GradeOneNumberLessonState();
}

class _GradeOneNumberLessonState extends State<_GradeOneNumberLesson> {
  int _stepIndex = 0;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() => _stepIndex = next);
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
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
    var maxIndex = 0;
    final numbers = _numbersForUnitOneLesson(widget.content.lessonNumber);
    final numberValues = numbers.map(int.parse).toList();
    final soloNumbers = numberValues.take(4).toList();
    double quizProgress(int quizIndex) {
      return (quizIndex + 1) / _lessonQuizCount;
    }

    final steps = [
      for (final entry in numbers.asMap().entries)
        _AlphabetFadeStep(
          child: _NumberFruitPresentationSlide(
            number: int.parse(entry.value),
            progress: (entry.key + 1) / numbers.length,
            showSpeakerHint: widget.content.lessonNumber == 1,
            onBack: entry.key == 0
                ? null
                : () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          progress: 0,
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneTapChoiceActivity(
          prompt: 'Pamatii ang numero.',
          listenText: _hiligaynonNumberWord('${soloNumbers[0]}'),
          showSpeakerHint: false,
          progress: quizProgress(0),
          choices: _numberWordChoices(soloNumbers[0], numberValues),
          answer: _hiligaynonNumberWord('${soloNumbers[0]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[0]}'),
          icon: Icons.filter_1_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(0, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneSpellingActivity(
          prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
          progress: quizProgress(1),
          word: _hiligaynonNumberWord('${soloNumbers[1]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[1]}'),
          icon: Icons.filter_2_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneTapChoiceActivity(
          prompt: 'Ano ni siya nga numero?',
          progress: quizProgress(2),
          choices: _numberWordChoices(soloNumbers[2], numberValues),
          answer: _hiligaynonNumberWord('${soloNumbers[2]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[2]}'),
          icon: Icons.filter_3_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(2, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneTapChoiceActivity(
          prompt: 'Pilia ang ngalan sang numero.',
          progress: quizProgress(3),
          choices: _numberWordChoices(soloNumbers[3], numberValues),
          answer: _hiligaynonNumberWord('${soloNumbers[3]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[3]}'),
          icon: Icons.filter_4_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(3, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneNumberMatchingActivity(
          prompt: 'Ipares kung ano ang sakto.',
          numbers: numbers.take(5).map(int.parse).toList(),
          progress: 1,
          showHint: widget.content.lessonNumber == 1,
          onAttempt: (correct) => widget.onQuizAttempt(4, correct),
          onDone: () {
            _finishQuiz();
            _advanceAfterCorrect(maxIndex);
          },
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('unit1-number-${widget.content.id}-$_stepIndex'),
        child: steps[_stepIndex.clamp(0, maxIndex)].child,
      ),
    );
  }

  List<String> _numbersForUnitOneLesson(int lessonNumber) {
    return lessonNumber == 8
        ? const ['6', '7', '8', '9', '10']
        : const ['1', '2', '3', '4', '5'];
  }

  List<String> _numberWordChoices(int answer, List<int> pool) {
    return _shuffledChoices([
      _hiligaynonNumberWord('$answer'),
      ...pool
          .where((number) => number != answer)
          .take(2)
          .map((number) => _hiligaynonNumberWord('$number')),
    ]).toList();
  }
}

class _GradeOneUnitOneReviewLesson extends StatefulWidget {
  final LevelContent content;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitOneReviewLesson({
    required this.content,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitOneReviewLesson> createState() =>
      _GradeOneUnitOneReviewLessonState();
}

class _GradeOneUnitOneReviewLessonState
    extends State<_GradeOneUnitOneReviewLesson> {
  static const int _reviewQuizCount = 10;
  static const List<String> _allReviewLetters = [
    'A',
    'N',
    'T',
    'Y',
    'I',
    'D',
    'O',
    'M',
    'K',
    'U',
    'B',
    'L',
    'S',
    'E',
    'G',
    'P',
    'R',
    'H',
    'W',
  ];
  static const List<int> _allReviewNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  int _stepIndex = 0;
  late final List<String> _reviewLetters = _shuffledChoices(_allReviewLetters);
  late final List<int> _reviewNumbers = _shuffledChoices(_allReviewNumbers);

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() => _stepIndex = next);
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _finishQuiz() {
    for (var index = 0; index < _reviewQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  List<String> _letterChoices(String answer, List<String> pool) {
    return _shuffledChoices([
      answer,
      ...pool.where((letter) => letter != answer).take(2),
    ]).toList();
  }

  List<String> _numberWordChoices(int answer, List<int> pool) {
    return _shuffledChoices([
      _hiligaynonNumberWord('$answer'),
      ...pool
          .where((number) => number != answer)
          .take(2)
          .map((number) => _hiligaynonNumberWord('$number')),
    ]).toList();
  }

  _AlphabetAnchor _anchorForLetter(String letter) {
    final anchors = [
      for (var lesson = 1; lesson <= 6; lesson++)
        ..._unitOneAlphabetAnchorsFor(lesson),
    ];
    final target = letter.toUpperCase();
    return anchors.firstWhere(
      (anchor) =>
          anchor.word.contains(target) || anchor.targets.contains(target),
      orElse: () => anchors.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    var maxIndex = 0;
    final firstLetter = _reviewLetters[0];
    final spellingAnchor = _anchorForLetter(_reviewLetters[1]);
    final hiddenLetters = _reviewLetters.skip(2).take(3).toList();
    final fourthLetter = _reviewLetters[5];
    final dragAnchor = _anchorForLetter(_reviewLetters[6]);
    final firstAnchor = _anchorForLetter(firstLetter);
    final fourthAnchor = _anchorForLetter(fourthLetter);
    final firstNumber = _reviewNumbers[0];
    final spellingNumber = _reviewNumbers[1];
    final thirdNumber = _reviewNumbers[2];
    final fourthNumber = _reviewNumbers[3];
    final matchingNumbers = _reviewNumbers.take(5).toList();
    final steps = [
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-tap-$firstLetter-${widget.content.id}'),
        prompt: 'Pamatii ang tingog. Pindoton ang husto nga letra.',
        listenText: _letterSoundText(firstLetter),
        showSpeakerHint: false,
        progress: 1 / _reviewQuizCount,
        choices: _letterChoices(firstLetter, _allReviewLetters),
        answer: firstLetter,
        isLetter: true,
        imageAsset: firstAnchor.imageAsset,
        icon: firstAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(0, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneSpellingActivity(
        key: ValueKey(
          'unit1-review-spell-${spellingAnchor.word}-${widget.content.id}',
        ),
        prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
        progress: 2 / _reviewQuizCount,
        word: spellingAnchor.word,
        imageAsset: spellingAnchor.imageAsset,
        icon: spellingAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(1, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneHiddenSearchActivity(
        key: ValueKey('unit1-review-search-${widget.content.id}'),
        prompt: 'Unahon ta pangitaon ang letra nga mabatian mo.',
        progress: 3 / _reviewQuizCount,
        targetLetters: hiddenLetters,
        onAttempt: (correct) => widget.onQuizAttempt(2, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey(
          'unit1-review-${fourthAnchor.meaning}-${widget.content.id}',
        ),
        prompt:
            'Diin ang letra sang ${fourthAnchor.meaning}? Pindoton ang $fourthLetter.',
        progress: 4 / _reviewQuizCount,
        choices: _letterChoices(fourthLetter, _allReviewLetters),
        answer: fourthLetter,
        isLetter: true,
        imageAsset: fourthAnchor.imageAsset,
        icon: fourthAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(3, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneDragFillActivity(
        key: ValueKey(
          'unit1-review-drag-${dragAnchor.word}-${widget.content.id}',
        ),
        prompt: 'Guyoda ang mga letra para matapos ang tinaga.',
        progress: 5 / _reviewQuizCount,
        word: dragAnchor.word,
        imageAsset: dragAnchor.imageAsset,
        icon: dragAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(4, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-num-$firstNumber-${widget.content.id}'),
        prompt:
            'Pamatii ang numero. Pindoton ang ${_hiligaynonNumberWord('$firstNumber')}.',
        listenText: _hiligaynonNumberWord('$firstNumber'),
        showSpeakerHint: false,
        progress: 6 / _reviewQuizCount,
        choices: _numberWordChoices(firstNumber, _allReviewNumbers),
        answer: _hiligaynonNumberWord('$firstNumber'),
        imageAsset: _unitOneNumberAsset('$firstNumber'),
        icon: Icons.filter_1_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(5, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneSpellingActivity(
        key: ValueKey('unit1-review-num-$spellingNumber-${widget.content.id}'),
        prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
        progress: 7 / _reviewQuizCount,
        word: _hiligaynonNumberWord('$spellingNumber'),
        imageAsset: _unitOneNumberAsset('$spellingNumber'),
        icon: Icons.filter_2_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(6, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-num-$thirdNumber-${widget.content.id}'),
        prompt: 'Ano ni siya nga numero?',
        progress: 8 / _reviewQuizCount,
        choices: _numberWordChoices(thirdNumber, _allReviewNumbers),
        answer: _hiligaynonNumberWord('$thirdNumber'),
        imageAsset: _unitOneNumberAsset('$thirdNumber'),
        icon: Icons.filter_3_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(7, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-num-$fourthNumber-${widget.content.id}'),
        prompt: 'Pilia ang ngalan sang numero.',
        progress: 9 / _reviewQuizCount,
        choices: _numberWordChoices(fourthNumber, _allReviewNumbers),
        answer: _hiligaynonNumberWord('$fourthNumber'),
        imageAsset: _unitOneNumberAsset('$fourthNumber'),
        icon: Icons.filter_4_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(8, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneNumberMatchingActivity(
        key: ValueKey('unit1-review-match-numbers-${widget.content.id}'),
        prompt: 'Ipares kung ano ang sakto.',
        progress: 1,
        numbers: matchingNumbers,
        onAttempt: (correct) => widget.onQuizAttempt(9, correct),
        onDone: () {
          _finishQuiz();
          _advanceAfterCorrect(maxIndex);
        },
      ),
    ];
    maxIndex = steps.length - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('unit1-review-${widget.content.id}-$_stepIndex'),
        child: steps[_stepIndex.clamp(0, maxIndex)],
      ),
    );
  }
}

class _NumberFruitPresentationSlide extends StatelessWidget {
  final int number;
  final double progress;
  final bool showSpeakerHint;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _NumberFruitPresentationSlide({
    required this.number,
    required this.progress,
    this.showSpeakerHint = false,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final numberWord = _numberWordFor(number);
    return _UnitOneQuizStage(
      prompt: 'Pamatii ang numero',
      mascotMessage: 'Numero $numberWord',
      progress: progress,
      child: _NumberFruitContent(
        number: number,
        showSpeakerHint: showSpeakerHint,
        onBack: onBack,
        onNext: onNext,
      ),
    );
  }
}

class _NumberFruitContent extends StatefulWidget {
  final int number;
  final bool showSpeakerHint;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _NumberFruitContent({
    required this.number,
    required this.showSpeakerHint,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_NumberFruitContent> createState() => _NumberFruitContentState();
}

class _NumberFruitContentState extends State<_NumberFruitContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;
  Timer? _hideHintTimer;
  Timer? _numberPopTimer;
  Timer? _fruitPopTimer;
  late bool _showSpeakerHint = widget.showSpeakerHint;
  bool _showNumber = false;
  bool _showFruits = false;

  @override
  void initState() {
    super.initState();
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    _startContentAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playNumberVoice();
      if (_showSpeakerHint) {
        _hideHintTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showSpeakerHint = false);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NumberFruitContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _startContentAnimation();
    }
  }

  void _startContentAnimation() {
    _numberPopTimer?.cancel();
    _fruitPopTimer?.cancel();
    _showNumber = false;
    _showFruits = false;
    _numberPopTimer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _showNumber = true);
    });
    _fruitPopTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _showFruits = true);
    });
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _numberPopTimer?.cancel();
    _fruitPopTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  Future<void> _playNumberVoice() async {
    final word = _numberWordFor(widget.number);
    await TudloVoiceButton.speak(
      context,
      'Pamatii ang tunog sang numero $word.',
      hiligaynon: true,
    );
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await playLessonNumberVoice(widget.number);
  }

  Future<void> _replayNumberVoice() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    setState(() => _showSpeakerHint = false);
    await playLessonNumberVoice(widget.number);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final number = widget.number;
    final numberAsset = _unitOneNumberAsset('$number');
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (width * .11).clamp(32.0, 58.0),
          ),
          child: SizedBox(
            height: (width * .5).clamp(198.0, 320.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 11,
                  child: AnimatedScale(
                    scale: _showNumber ? 1 : .35,
                    duration: const Duration(milliseconds: 460),
                    curve: Curves.elasticOut,
                    child: AnimatedOpacity(
                      opacity: _showNumber ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: numberAsset == null
                          ? FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                '$number',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            )
                          : Image.asset(
                              numberAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                    ),
                  ),
                ),
                SizedBox(width: (width * .025).clamp(8.0, 16.0)),
                Expanded(
                  flex: 9,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _AnimatedFruitCount(
                      number: number,
                      start: _showFruits,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _titleCase(_numberWordFor(number)),
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: (width * .155).clamp(58.0, 96.0),
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0xFF459B27),
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PresentationSpeakerHint(
          size: (width * .22).clamp(86.0, 118.0),
          showFinger: _showSpeakerHint,
          tapScale: _tapScale,
          tapOffset: _tapOffset,
          onTap: () => unawaited(_replayNumberVoice()),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: widget.onBack == null ? .35 : 1,
              child: _PresentationImageButton(
                asset:
                    'assets/images/level_game/lesson-game-assets/back-lesson.png',
                size: (width * .18).clamp(70.0, 100.0),
                enabled: widget.onBack != null,
                onTap: widget.onBack ?? () {},
                tooltip: 'Balik',
              ),
            ),
            SizedBox(width: (width * .16).clamp(56.0, 92.0)),
            _PresentationImageButton(
              asset:
                  'assets/images/level_game/lesson-game-assets/next-lesson.png',
              size: (width * .18).clamp(70.0, 100.0),
              onTap: widget.onNext,
              tooltip: 'Padayon',
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _AnimatedFruitCount extends StatefulWidget {
  final int number;
  final bool start;

  const _AnimatedFruitCount({required this.number, required this.start});

  @override
  State<_AnimatedFruitCount> createState() => _AnimatedFruitCountState();
}

class _AnimatedFruitCountState extends State<_AnimatedFruitCount> {
  int _visibleCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.start) {
      _startFruitAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedFruitCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _startFruitAnimation();
      return;
    }
    if (!oldWidget.start && widget.start) {
      _startFruitAnimation();
    }
  }

  void _startFruitAnimation() {
    _timer?.cancel();
    _visibleCount = 0;
    if (!widget.start) {
      if (mounted) setState(() {});
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      if (_visibleCount >= widget.number) {
        timer.cancel();
        return;
      }
      setState(() => _visibleCount++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.number.clamp(1, 10).toInt();
    final columns = count <= 2
        ? count
        : count <= 5
        ? 2
        : 3;
    final rows = (count / columns).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 5.0;
        final maxFruitWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        final maxFruitHeight =
            (constraints.maxHeight - (rows - 1) * spacing) / rows;
        final fruitSize = math
            .min(maxFruitWidth, maxFruitHeight)
            .clamp(44.0, 140.0)
            .toDouble();
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var index = 0; index < count; index++)
                AnimatedScale(
                  scale: index < _visibleCount ? 1 : .35,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.elasticOut,
                  child: AnimatedOpacity(
                    opacity: index < _visibleCount ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: SizedBox(
                      width: fruitSize,
                      height: fruitSize,
                      child: Image.asset(
                        _fruitAssetForNumber(widget.number),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _fruitAssetForNumber(int number) {
  return 'assets/images/level_game/apple.png';
}

String _numberMatchingFruitAsset() {
  return 'assets/images/level_game/apple.png';
}

String _numberWordFor(int number) {
  return _hiligaynonNumberWord('$number');
}

String _hiligaynonNumberWord(String number) {
  return const {
        '1': 'isa',
        '2': 'duwa',
        '3': 'tatlo',
        '4': 'apat',
        '5': 'lima',
        '6': 'anum',
        '7': 'pito',
        '8': 'walo',
        '9': 'siyam',
        '10': 'napulo',
      }[number] ??
      number;
}

class _UnitOneQuizStage extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final String prompt;
  final String mascotMessage;
  final double progress;
  final Widget child;

  const _UnitOneQuizStage({
    required this.prompt,
    required this.mascotMessage,
    this.progress = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final width = view.width;
    final height = view.height;
    final safeTop = MediaQuery.paddingOf(context).top;
    final topButtonSize = math
        .min(width * .13, height * .08)
        .clamp(48.0, 64.0)
        .toDouble();
    final mascotSize = math
        .min(width * .42, height * .26)
        .clamp(148.0, 232.0)
        .toDouble();
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            '$_assetBase/levelgame-bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Positioned(
            left: width * .06,
            top: safeTop + height * .025,
            child: _PresentationImageButton(
              asset: '$_assetBase/exit-page.png',
              size: topButtonSize,
              onTap: () => unawaited(_exitLessonFromContext(context)),
              tooltip: 'Balik',
            ),
          ),
          Positioned(
            left: width * .28,
            right: width * .27,
            top: safeTop + height * .045,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1).toDouble(),
                minHeight: (height * .023).clamp(16.0, 24.0),
                backgroundColor: Colors.white,
                color: TudloColors.green,
              ),
            ),
          ),
          Positioned(
            right: width * .055,
            top: safeTop + height * .026,
            child: Transform.scale(
              scale: .78,
              alignment: Alignment.topRight,
              child: const EnergyIndicator(),
            ),
          ),
          Positioned(
            left: width * .005,
            top: safeTop + height * .115,
            child: _LessonKokaMascot(size: mascotSize, mood: KokaMood.idle),
          ),
          Positioned(
            left: width * .31,
            right: width * .035,
            top: safeTop + height * .108,
            child: _PresentationInstructionText(
              message: prompt,
              fontSize: (width * .068).clamp(23.0, 39.0),
              onReplay: () {
                unawaited(
                  TudloVoiceButton.speak(context, prompt, hiligaynon: true),
                );
              },
            ),
          ),
          Positioned(
            left: width * .06,
            right: width * .06,
            top: height * .31,
            bottom: height * .02,
            child: child,
          ),
        ],
      ),
    );
  }
}

bool _isLivingSubjectAsset(String? imageAsset, IconData icon) {
  final asset = imageAsset?.toLowerCase() ?? '';
  if (asset.contains('/people/') || asset.contains('/animals/')) return true;
  return icon == Icons.family_restroom_rounded ||
      icon == Icons.pets_rounded ||
      icon == Icons.egg_alt_rounded ||
      icon == Icons.elderly_woman_rounded ||
      icon == Icons.elderly_rounded;
}

String _subjectQuestionFor(String? imageAsset, IconData icon) {
  return _isLivingSubjectAsset(imageAsset, icon)
      ? 'Sino ni siya?'
      : 'Ano ni siya?';
}

class _SubjectQuestionLabel extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;

  const _SubjectQuestionLabel({required this.imageAsset, required this.icon});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Text(
      _subjectQuestionFor(imageAsset, icon),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: (width * .065).clamp(24.0, 36.0),
        height: 1,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        shadows: const [
          Shadow(color: Color(0xFF459B27), blurRadius: 0, offset: Offset(2, 2)),
          Shadow(color: Colors.white, blurRadius: 1),
        ],
      ),
    );
  }
}

class _UnitOneTapChoiceActivity extends StatefulWidget {
  final String prompt;
  final String? listenText;
  final bool showSpeakerHint;
  final double progress;
  final List<String> choices;
  final String answer;
  final bool isLetter;
  final String? imageAsset;
  final IconData icon;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneTapChoiceActivity({
    super.key,
    required this.prompt,
    this.listenText,
    this.showSpeakerHint = true,
    this.progress = 0,
    required this.choices,
    required this.answer,
    this.isLetter = false,
    this.imageAsset,
    this.icon = Icons.text_fields_rounded,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneTapChoiceActivity> createState() =>
      _UnitOneTapChoiceActivityState();
}

class _UnitOneTapChoiceActivityState extends State<_UnitOneTapChoiceActivity>
    with SingleTickerProviderStateMixin {
  String? _selected;
  bool _wrong = false;
  bool _done = false;
  bool _showSpeakerHint = false;
  Timer? _hideHintTimer;
  Timer? _inactiveHintTimer;
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;

  @override
  void initState() {
    super.initState();
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showHintBriefly();
      unawaited(_playPrompt());
    });
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  void _showHintBriefly() {
    if (!widget.showSpeakerHint || widget.listenText == null || _done) return;
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted) setState(() => _showSpeakerHint = true);
    _hideHintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showSpeakerHint = false);
    });
    _inactiveHintTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  void _hideHintUntilInactive() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (!widget.showSpeakerHint || widget.listenText == null || _done) return;
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  Future<void> _playPrompt() async {
    await TudloVoiceButton.speak(context, widget.prompt);
    if (!mounted || widget.listenText == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    await TudloVoiceButton.speak(context, widget.listenText!, hiligaynon: true);
  }

  Future<void> _replayListenText() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    _hideHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      widget.listenText ?? widget.prompt,
      hiligaynon: true,
    );
  }

  Future<void> _choose(String choice) async {
    if (_done) return;
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    setState(() {
      _selected = choice;
      _wrong = false;
    });
    final spokenChoice = widget.isLetter ? _letterSoundText(choice) : choice;
    unawaited(TudloVoiceButton.speak(context, spokenChoice, hiligaynon: true));
  }

  Future<void> _submit() async {
    if (_done || _selected == null) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = _selected == widget.answer;
    widget.onAttempt(correct);
    setState(() {
      _wrong = !correct;
      _done = correct;
      if (correct) _showSpeakerHint = false;
    });
    unawaited(
      correct
          ? AppAudioService.instance.playCorrect()
          : AppAudioService.instance.playWrong(),
    );
    await TudloVoiceButton.speak(
      context,
      correct ? 'Husto! $_selected.' : 'Suliton liwat.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (correct) {
      _hideHintTimer?.cancel();
      _inactiveHintTimer?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted && _done) widget.onDone();
      });
    } else {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_done) {
          setState(() {
            _selected = null;
            _wrong = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto! Maayo gid.'
          : _wrong
          ? 'Koka: Suliton liwat.'
          : 'Koka: Pindoton ang husto nga sabat.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final imageHeight = (height * .34).clamp(145.0, 205.0);
          final imageWidth = (width * .66).clamp(210.0, 270.0);
          final speakerSize = (width * .20).clamp(72.0, 86.0);
          final choiceSize = (width * .27).clamp(92.0, 112.0);
          return Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.listenText == null) ...[
                        _SubjectQuestionLabel(
                          imageAsset: widget.imageAsset,
                          icon: widget.icon,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Flexible(
                        child: widget.imageAsset == null
                            ? Icon(
                                widget.icon,
                                color: TudloColors.green,
                                size: imageHeight * .84,
                              )
                            : Image.asset(
                                widget.imageAsset!,
                                width: imageWidth,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.icon,
                                  color: TudloColors.green,
                                  size: imageHeight * .74,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.listenText != null)
                SizedBox(
                  height: speakerSize * .98,
                  child: Center(
                    child: _PresentationSpeakerHint(
                      size: speakerSize,
                      showFinger: _showSpeakerHint,
                      tapScale: _tapScale,
                      tapOffset: _tapOffset,
                      onTap: _replayListenText,
                    ),
                  ),
                ),
              SizedBox(height: (height * .035).clamp(14.0, 24.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final choice in widget.choices.take(3))
                    Flexible(
                      child: _UnitOneSymbolButton(
                        label: choice,
                        isLetter: widget.isLetter,
                        assetSize: widget.isLetter ? choiceSize : null,
                        selected: _selected == choice,
                        correct: _selected == choice && _done,
                        wrong: _selected == choice && _wrong,
                        onTap: () => _choose(choice),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              _UnitOneSubmitButton(
                enabled: _selected != null && !_done,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnitOneSubmitButton extends StatelessWidget {
  final bool enabled;
  final FutureOr<void> Function() onPressed;

  const _UnitOneSubmitButton({required this.enabled, required this.onPressed});

  Future<void> _handleTap() async {
    if (!enabled) return;
    await AppAudioService.instance.playTap();
    await onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: 1,
      child: GestureDetector(
        onTap: enabled ? _handleTap : null,
        child: Container(
          width: double.infinity,
          height: 58,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: enabled
                ? TudloColors.blue
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: TudloColors.forest.withValues(alpha: .22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Text(
            'Ipasa',
            style: GoogleFonts.nunito(
              color: enabled ? Colors.white : TudloColors.muted,
              fontSize: 28,
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

class _UnitOneNumberMatchingActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final List<int> numbers;
  final bool showHint;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneNumberMatchingActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.numbers,
    this.showHint = false,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneNumberMatchingActivity> createState() =>
      _UnitOneNumberMatchingActivityState();
}

enum _NumberMatchDragSide { left, right }

class _UnitOneNumberMatchingActivityState
    extends State<_UnitOneNumberMatchingActivity>
    with SingleTickerProviderStateMixin {
  late final List<int> _leftNumbers = _shuffledChoices(widget.numbers);
  late final List<int> _rightNumbers = _shuffledChoices(widget.numbers);
  final Map<int, int> _connections = {};
  final GlobalKey _matchAreaKey = GlobalKey();
  _NumberMatchDragSide? _dragSide;
  int? _dragNumber;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _submittedWrong = false;
  bool _done = false;
  late bool _showHint = widget.showHint;
  Timer? _hideHintTimer;
  late final AnimationController _hintController;
  late final Animation<double> _hintScale;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOut,
    );
    _hintScale = Tween<double>(begin: 1, end: .86).animate(curve);
    if (_showHint) {
      _hideHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _hintController.dispose();
    super.dispose();
  }

  bool get _allConnected => _connections.length >= widget.numbers.length;

  bool get _allCorrect =>
      _allConnected &&
      _connections.entries.every((entry) => entry.key == entry.value);

  void _hideHint() {
    _hideHintTimer?.cancel();
    if (_showHint) {
      setState(() => _showHint = false);
    }
  }

  void _connect(int leftNumber, int rightNumber) {
    setState(() {
      _connections.removeWhere(
        (left, right) => left == leftNumber || right == rightNumber,
      );
      _connections[leftNumber] = rightNumber;
      _dragSide = null;
      _dragNumber = null;
      _dragStart = null;
      _dragCurrent = null;
      _submittedWrong = false;
    });
  }

  Offset _toMatchLocal(Offset globalPosition) {
    final box = _matchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition) ?? Offset.zero;
  }

  int? _numberAtY(double y, List<int> numbers, double height) {
    if (numbers.isEmpty || y < 0 || y > height) return null;
    final rawIndex = (y / height * numbers.length).floor();
    final index = rawIndex.clamp(0, numbers.length - 1).toInt();
    return numbers[index];
  }

  void _startDrag({
    required _NumberMatchDragSide side,
    required int number,
    required Offset anchor,
    required Offset globalPosition,
  }) {
    if (_done) return;
    _hideHint();
    unawaited(AppAudioService.instance.playTap());
    setState(() {
      _dragSide = side;
      _dragNumber = number;
      _dragStart = anchor;
      _dragCurrent = _toMatchLocal(globalPosition);
      _submittedWrong = false;
    });
  }

  void _updateDrag(Offset globalPosition) {
    if (_done || _dragStart == null) return;
    setState(() => _dragCurrent = _toMatchLocal(globalPosition));
  }

  void _cancelDrag() {
    if (_done) return;
    setState(() {
      _dragSide = null;
      _dragNumber = null;
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _endDrag(double height) {
    if (_done || _dragSide == null || _dragNumber == null) return;
    final local = _dragCurrent;
    if (local == null) return;
    final side = _dragSide!;
    final number = _dragNumber!;
    final target = side == _NumberMatchDragSide.left
        ? _numberAtY(local.dy, _rightNumbers, height)
        : _numberAtY(local.dy, _leftNumbers, height);
    if (target == null) {
      setState(() {
        _dragSide = null;
        _dragNumber = null;
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }
    if (side == _NumberMatchDragSide.left) {
      _connect(number, target);
    } else {
      _connect(target, number);
    }
  }

  Future<void> _submit() async {
    if (_done || !_allConnected) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }

    final correct = _allCorrect;
    widget.onAttempt(correct);
    if (correct) {
      setState(() => _done = true);
      unawaited(AppAudioService.instance.playCorrect());
      await TudloVoiceButton.speak(context, 'Husto!', hiligaynon: true);
      if (!mounted) return;
      widget.onDone();
      return;
    }

    setState(() => _submittedWrong = true);
    unawaited(AppAudioService.instance.playWrong());
    await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
  }

  double _rowCenterY(int index, int count, double height) {
    return ((index + .5) / count) * height;
  }

  int get _hintTargetNumber {
    return widget.numbers.contains(1) ? 1 : _leftNumbers.first;
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto!'
          : 'Koka: Ipares ang numero kag prutas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wordFont = (width * .082).clamp(29.0, 42.0);
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, area) {
                    final height = area.maxHeight;
                    final leftX = width * .16;
                    final rightX = width * .70;
                    final leftIndexes = {
                      for (var i = 0; i < _leftNumbers.length; i++)
                        _leftNumbers[i]: i,
                    };
                    final rightIndexes = {
                      for (var i = 0; i < _rightNumbers.length; i++)
                        _rightNumbers[i]: i,
                    };
                    final lineEntries = _connections.entries
                        .where(
                          (entry) =>
                              leftIndexes.containsKey(entry.key) &&
                              rightIndexes.containsKey(entry.value),
                        )
                        .map(
                          (entry) => _NumberMatchLine(
                            start: Offset(
                              leftX + width * .10,
                              _rowCenterY(
                                leftIndexes[entry.key]!,
                                _leftNumbers.length,
                                height,
                              ),
                            ),
                            end: Offset(
                              rightX - width * .10,
                              _rowCenterY(
                                rightIndexes[entry.value]!,
                                _rightNumbers.length,
                                height,
                              ),
                            ),
                            colorKey: entry.key,
                            correct: entry.key == entry.value,
                          ),
                        )
                        .toList();
                    final activeLine =
                        _dragStart != null &&
                            _dragCurrent != null &&
                            _dragNumber != null
                        ? _NumberMatchLine(
                            start: _dragStart!,
                            end: _dragCurrent!,
                            colorKey: _dragNumber!,
                            correct: true,
                          )
                        : null;
                    return Stack(
                      key: _matchAreaKey,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _NumberMatchLinePainter(
                              lines: [
                                ...lineEntries,
                                if (activeLine != null) activeLine,
                              ],
                              showCorrectness: _submittedWrong || _done,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          right: width * .58,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final number in _leftNumbers)
                                _NumberMatchWord(
                                  label: _titleCase(
                                    _hiligaynonNumberWord('$number'),
                                  ),
                                  fontSize: wordFont,
                                  selected:
                                      _dragSide == _NumberMatchDragSide.left &&
                                      _dragNumber == number,
                                  connected: _connections.containsKey(number),
                                  wrong:
                                      _submittedWrong &&
                                      _connections[number] != null &&
                                      _connections[number] != number,
                                  onPanStart: (details) => _startDrag(
                                    side: _NumberMatchDragSide.left,
                                    number: number,
                                    anchor: Offset(
                                      leftX + width * .10,
                                      _rowCenterY(
                                        leftIndexes[number]!,
                                        _leftNumbers.length,
                                        height,
                                      ),
                                    ),
                                    globalPosition: details.globalPosition,
                                  ),
                                  onPanUpdate: (details) =>
                                      _updateDrag(details.globalPosition),
                                  onPanEnd: (_) => _endDrag(height),
                                  onPanCancel: () => _cancelDrag(),
                                ),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          left: width * .50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (final number in _rightNumbers)
                                _NumberFruitMatchGroup(
                                  count: number,
                                  selected:
                                      _dragSide == _NumberMatchDragSide.right &&
                                      _dragNumber == number,
                                  connected: _connections.containsValue(number),
                                  wrong:
                                      _submittedWrong &&
                                      _connections.entries.any(
                                        (entry) =>
                                            entry.value == number &&
                                            entry.key != number,
                                      ),
                                  onPanStart: (details) => _startDrag(
                                    side: _NumberMatchDragSide.right,
                                    number: number,
                                    anchor: Offset(
                                      rightX - width * .10,
                                      _rowCenterY(
                                        rightIndexes[number]!,
                                        _rightNumbers.length,
                                        height,
                                      ),
                                    ),
                                    globalPosition: details.globalPosition,
                                  ),
                                  onPanUpdate: (details) =>
                                      _updateDrag(details.globalPosition),
                                  onPanEnd: (_) => _endDrag(height),
                                  onPanCancel: () => _cancelDrag(),
                                ),
                            ],
                          ),
                        ),
                        if (_showHint &&
                            leftIndexes.containsKey(_hintTargetNumber) &&
                            rightIndexes.containsKey(_hintTargetNumber))
                          _NumberMatchGestureHint(
                            scale: _hintScale,
                            start: Offset(
                              leftX,
                              _rowCenterY(
                                leftIndexes[_hintTargetNumber]!,
                                _leftNumbers.length,
                                height,
                              ),
                            ),
                            end: Offset(
                              rightX - width * .14,
                              _rowCenterY(
                                rightIndexes[_hintTargetNumber]!,
                                _rightNumbers.length,
                                height,
                              ),
                            ),
                            size: (width * .16).clamp(54.0, 72.0),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _UnitOneSubmitButton(
                enabled: _allConnected && !_done,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberMatchLine {
  final Offset start;
  final Offset end;
  final int colorKey;
  final bool correct;

  const _NumberMatchLine({
    required this.start,
    required this.end,
    required this.colorKey,
    required this.correct,
  });
}

class _NumberMatchLinePainter extends CustomPainter {
  final List<_NumberMatchLine> lines;
  final bool showCorrectness;

  const _NumberMatchLinePainter({
    required this.lines,
    required this.showCorrectness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final color = showCorrectness
          ? line.correct
                ? TudloColors.green
                : TudloColors.coral
          : _numberMatchColor(line.colorKey);
      final paint = Paint()
        ..color = color.withValues(alpha: .92)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(line.start, line.end, paint);
      canvas.drawCircle(line.start, 5, paint);
      canvas.drawCircle(line.end, 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NumberMatchLinePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.showCorrectness != showCorrectness;
  }
}

Color _numberMatchColor(int number) {
  return const [
    Color(0xFFFFD43B),
    Color(0xFF29B6F6),
    Color(0xFFFF7A59),
    Color(0xFFB86BFF),
    Color(0xFF16C784),
  ][number.abs() % 5];
}

class _NumberMatchGestureHint extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final Animation<double> scale;
  final Offset start;
  final Offset end;
  final double size;

  const _NumberMatchGestureHint({
    required this.scale,
    required this.start,
    required this.end,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2200),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            final position = Offset.lerp(start, end, value)!;
            return Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy - size * .18,
                  child: AnimatedBuilder(
                    animation: scale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: scale.value,
                        alignment: Alignment.topLeft,
                        child: child,
                      );
                    },
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: AnimatedPointFinger(
            asset: '$_assetBase/point-finger.png',
            size: size,
          ),
        ),
      ),
    );
  }
}

class _NumberMatchWord extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool selected;
  final bool connected;
  final bool wrong;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  const _NumberMatchWord({
    required this.label,
    required this.fontSize,
    required this.selected,
    required this.connected,
    required this.wrong,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color = wrong ? const Color(0xFFFFE2E2) : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.08 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? TudloColors.blue.withValues(alpha: .32)
                : connected
                ? Colors.white.withValues(alpha: .16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: fontSize,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  color: Color(0xFF459B27),
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberFruitMatchGroup extends StatelessWidget {
  final int count;
  final bool selected;
  final bool connected;
  final bool wrong;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  const _NumberFruitMatchGroup({
    required this.count,
    required this.selected,
    required this.connected,
    required this.wrong,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final compact = count > 5;
    final columns = compact ? 5 : math.min(3, count);
    final rows = (count / columns).ceil();
    final fruitSize = compact ? 34.0 : 46.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.08 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected
                ? TudloColors.blue.withValues(alpha: .20)
                : connected
                ? Colors.white.withValues(alpha: .10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: wrong
                  ? TudloColors.coral
                  : selected
                  ? TudloColors.blue
                  : Colors.transparent,
              width: selected || wrong ? 3 : 0,
            ),
          ),
          child: SizedBox(
            width: columns * (fruitSize + 3),
            height: rows * (fruitSize + 3),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 3,
              children: [
                for (var index = 0; index < count; index++)
                  Image.asset(
                    _numberMatchingFruitAsset(),
                    width: fruitSize,
                    height: fruitSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitOneSpellingActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final String word;
  final String? imageAsset;
  final IconData icon;
  final bool showDragTutorial;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneSpellingActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.word,
    this.imageAsset,
    required this.icon,
    this.showDragTutorial = false,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneSpellingActivity> createState() =>
      _UnitOneSpellingActivityState();
}

class _UnitOneSpellingActivityState extends State<_UnitOneSpellingActivity>
    with SingleTickerProviderStateMixin {
  String? _selectedChoice;
  Set<String> _wrongChoices = const {};
  late int _activeMissingIndex;
  final Map<int, String> _filledLetters = {};
  bool _done = false;
  bool _showSpeakerHint = true;
  bool _showDragTutorialHint = false;
  Timer? _hideHintTimer;
  Timer? _inactiveHintTimer;
  Timer? _dragTutorialTimer;
  Timer? _inactiveDragTutorialTimer;
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;

  late final List<String> _letters = () {
    final letters = widget.word
        .replaceAll(RegExp(r'\s+'), '')
        .characters
        .map((letter) => letter.toUpperCase())
        .toList();
    return letters.isEmpty ? ['A'] : letters;
  }();
  late final List<int> _missingIndexes = _buildMissingIndexes();
  late final Set<String> _missingLetters = {
    for (final index in _missingIndexes) _letters[index],
  };

  late final List<String> _choices = _shuffledChoices(
    {
      ..._missingLetters,
      ...const ['A', 'N', 'T', 'Y', 'I', 'D', 'O', 'M', 'K', 'U'],
    }.take(5),
  ).toList();

  @override
  void initState() {
    super.initState();
    _activeMissingIndex = _missingIndexes.first;
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showHintBriefly();
      _queueDragTutorial(const Duration(milliseconds: 850));
      unawaited(TudloVoiceButton.speak(context, widget.prompt));
    });
  }

  void _queueDragTutorial(Duration delay) {
    if (!widget.showDragTutorial || _done) return;
    _dragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer = Timer(delay, () {
      _showDragTutorialBriefly();
    });
  }

  void _showDragTutorialBriefly() {
    if (!mounted || _done || !widget.showDragTutorial) return;
    setState(() => _showDragTutorialHint = true);
    _dragTutorialTimer?.cancel();
    _dragTutorialTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showDragTutorialHint = false);
      _queueDragTutorial(const Duration(seconds: 8));
    });
  }

  List<int> _buildMissingIndexes() {
    if (_letters.isEmpty) return const [0];
    if (_letters.length <= 2) return const [0];
    final shouldUseTwoBlanks =
        _letters.length >= 5 &&
        widget.word.codeUnits.fold<int>(0, (sum, code) => sum + code).isEven;
    final first = _letters.length ~/ 2;
    if (!shouldUseTwoBlanks) return [first];

    final second = math.max(0, _letters.length - 1);
    if (second == first) return [first];
    return [first, second]..sort();
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    _dragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  void _dismissDragTutorial() {
    _dragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer?.cancel();
    if (_showDragTutorialHint && mounted) {
      setState(() => _showDragTutorialHint = false);
    }
    if (!_done) _queueDragTutorial(const Duration(seconds: 8));
  }

  void _showHintBriefly() {
    if (_done) return;
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted) setState(() => _showSpeakerHint = true);
    _hideHintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSpeakerHint = false);
    });
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  void _hideHintUntilInactive() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (_done) return;
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  Future<void> _playWord() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    _dismissDragTutorial();
    _hideHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      widget.word,
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _selectLetter(String letter) async {
    if (_done) return;
    _dismissDragTutorial();
    await AppAudioService.instance.playTap();
    setState(() {
      final targetIndex = _filledLetters.containsKey(_activeMissingIndex)
          ? _firstEmptyMissingIndex() ?? _activeMissingIndex
          : _activeMissingIndex;
      _filledLetters[targetIndex] = letter;
      _selectedChoice = letter;
      _wrongChoices = const {};
      _activeMissingIndex = _firstEmptyMissingIndex() ?? targetIndex;
    });
  }

  int? _firstEmptyMissingIndex() {
    for (final index in _missingIndexes) {
      if (!_filledLetters.containsKey(index)) return index;
    }
    return null;
  }

  void _clearSlot(int index) {
    if (_done) return;
    _dismissDragTutorial();
    setState(() {
      _filledLetters.remove(index);
      _activeMissingIndex = index;
      _selectedChoice = null;
      _wrongChoices = const {};
    });
  }

  Future<void> _submitLetter() async {
    if (_done || _filledLetters.length < _missingIndexes.length) return;
    _dismissDragTutorial();
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = _missingIndexes.every(
      (index) => _filledLetters[index] == _letters[index],
    );
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _wrongChoices = const {};
        _done = true;
        _showSpeakerHint = false;
      });
      _hideHintTimer?.cancel();
      _inactiveHintTimer?.cancel();
      _dragTutorialTimer?.cancel();
      _inactiveDragTutorialTimer?.cancel();
      unawaited(AppAudioService.instance.playCorrect());
      await TudloVoiceButton.speak(
        context,
        '${_titleCase(widget.word)}. Husto!',
        hiligaynon: true,
      );
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted && _done) widget.onDone();
      });
    } else {
      final wrongEntries = _filledLetters.entries
          .where((entry) => entry.value != _letters[entry.key])
          .toList();
      setState(() {
        _wrongChoices = {for (final entry in wrongEntries) entry.value};
        for (final entry in wrongEntries) {
          _filledLetters.remove(entry.key);
        }
        _activeMissingIndex = wrongEntries.isNotEmpty
            ? wrongEntries.first.key
            : _missingIndexes.first;
        _selectedChoice = null;
      });
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrongChoices = const {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Nabuo mo ang ${_titleCase(widget.word)}!'
          : _wrongChoices.isNotEmpty
          ? 'Koka: Suliton liwat.'
          : 'Koka: Pamatia anay ang tinaga, dayon pilia ang kulang nga letra.',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              SizedBox(
                height: 238,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SubjectQuestionLabel(
                        imageAsset: widget.imageAsset,
                        icon: widget.icon,
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: widget.imageAsset == null
                            ? Icon(
                                widget.icon,
                                color: TudloColors.green,
                                size: 145,
                              )
                            : Image.asset(
                                widget.imageAsset!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.icon,
                                  color: TudloColors.green,
                                  size: 140,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      _PresentationSpeakerHint(
                        size: 72,
                        showFinger: false,
                        tapScale: _tapScale,
                        tapOffset: _tapOffset,
                        onTap: _playWord,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _letters.length; i++)
                    if (_missingIndexes.contains(i))
                      DragTarget<String>(
                        onWillAcceptWithDetails: (_) => !_done,
                        onAcceptWithDetails: (details) {
                          _activeMissingIndex = i;
                          unawaited(_selectLetter(details.data));
                        },
                        builder: (context, candidates, rejected) {
                          return AnimatedScale(
                            duration: const Duration(milliseconds: 140),
                            scale: candidates.isNotEmpty ? 1.08 : 1,
                            child: GestureDetector(
                              onTap: () => _clearSlot(i),
                              child: _MissingLetterUnderlineSlot(
                                label: _done
                                    ? _letters[i]
                                    : _filledLetters[i] ?? '',
                                lineColor: _quizLineColorAt(i),
                                active:
                                    candidates.isNotEmpty ||
                                    _activeMissingIndex == i ||
                                    _filledLetters.containsKey(i),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _PlainAnswerLetter(label: _letters[i]),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 0,
                    children: [
                      for (final letter in _choices)
                        Draggable<String>(
                          data: letter,
                          feedback: Material(
                            color: Colors.transparent,
                            child: _UnitOneSymbolButton(
                              label: letter,
                              isLetter: true,
                              assetSize: 82,
                              onTap: () {},
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: .35,
                            child: _UnitOneSymbolButton(
                              label: letter,
                              isLetter: true,
                              assetSize: 82,
                              onTap: () {},
                            ),
                          ),
                          child: _UnitOneSymbolButton(
                            label: letter,
                            isLetter: true,
                            assetSize: 82,
                            selected: _selectedChoice == letter,
                            wrong: _wrongChoices.contains(letter),
                            onTap: () => _selectLetter(letter),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              _UnitOneSubmitButton(
                enabled:
                    _filledLetters.length == _missingIndexes.length && !_done,
                onPressed: _submitLetter,
              ),
            ],
          ),
          if (_showDragTutorialHint && !_done)
            Positioned.fill(
              child: _DragLetterTutorialHint(
                choiceIndex: _choices.indexOf(_letters[_activeMissingIndex]),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitOneHiddenSearchActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final List<String> targetLetters;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneHiddenSearchActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.targetLetters,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneHiddenSearchActivity> createState() =>
      _UnitOneHiddenSearchActivityState();
}

class _DragLetterTutorialHint extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final int choiceIndex;

  const _DragLetterTutorialHint({required this.choiceIndex});

  Offset _choiceAnchor(double width, double height) {
    final index = choiceIndex < 0 ? 0 : choiceIndex;
    final anchors = [
      Offset(width * .20, height * .68),
      Offset(width * .47, height * .68),
      Offset(width * .74, height * .68),
      Offset(width * .34, height * .86),
      Offset(width * .61, height * .86),
    ];
    return anchors[index.clamp(0, anchors.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2600),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              final begin = _choiceAnchor(width, height);
              final end = Offset(width * .48, height * .42);
              final position = Offset.lerp(begin, end, value)!;
              final pulse = math.sin(value * math.pi * 3).abs() * .08;
              return Stack(
                children: [
                  Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: Transform.rotate(
                      angle: -.35,
                      child: Transform.scale(
                        scale: 1 + pulse,
                        alignment: Alignment.topLeft,
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            },
            child: AnimatedPointFinger(
              asset: '$_assetBase/point-finger.png',
              size: (MediaQuery.sizeOf(context).width * .18).clamp(64.0, 92.0),
              angle: 0,
            ),
          );
        },
      ),
    );
  }
}

class _UnitOneHiddenSearchActivityState
    extends State<_UnitOneHiddenSearchActivity>
    with SingleTickerProviderStateMixin {
  final Set<String> _found = {};
  String? _wrong;
  bool _done = false;
  bool _showSpeakerHint = true;
  Timer? _hideHintTimer;
  Timer? _inactiveHintTimer;
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;

  late final List<String> _targets = widget.targetLetters
      .map((letter) => letter.toUpperCase())
      .toSet()
      .toList();
  late final List<String> _hiddenLetters = _shuffledChoices([
    ..._targets,
    ...const [
      'B',
      'L',
      'S',
      'I',
      'D',
      'O',
      'M',
      'K',
      'U',
    ].where((letter) => !_targets.contains(letter)).take(3),
  ]);

  String? get _currentTarget => _done || _found.length >= _targets.length
      ? null
      : _targets[_found.length];

  @override
  void initState() {
    super.initState();
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Unahon ta pangitaon ang letra nga mabatian mo.',
          hiligaynon: true,
        ),
      );
      _showHintBriefly();
    });
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  void _showHintBriefly() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted) setState(() => _showSpeakerHint = true);
    _hideHintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSpeakerHint = false);
    });
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  void _hideHintUntilInactive() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (_done) return;
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  Future<void> _playCurrentLetter() async {
    await AppAudioService.instance.playTap();
    final target = _currentTarget;
    if (!mounted || target == null) return;
    _hideHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      _letterSoundText(target),
      hiligaynon: true,
    );
  }

  Future<void> _tapHidden(String letter) async {
    if (_done || _found.contains(letter)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = letter == _currentTarget;
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _found.add(letter);
        _wrong = null;
        _done = _found.length == _targets.length;
        _showSpeakerHint = !_done;
      });
      unawaited(AppAudioService.instance.playCorrect());
      if (_done) {
        _hideHintTimer?.cancel();
        _inactiveHintTimer?.cancel();
        await TudloVoiceButton.speak(
          context,
          'Ara na tanan nga letra!',
          hiligaynon: true,
          waitForCompletion: true,
        );
      } else {
        _showHintBriefly();
      }
    } else {
      setState(() => _wrong = letter);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrong = null);
      });
      _showHintBriefly();
    }
  }

  bool get _usesClassroomLetterHunt {
    if (_targets.length != 3) return false;
    const classroomLetters = {'A', 'N', 'T'};
    return _targets.every(classroomLetters.contains);
  }

  Widget _buildClassroomLetterHunt(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final width = view.width;
    final height = view.height;
    final safeTop = MediaQuery.paddingOf(context).top;
    final controlSize = math
        .min(width * .14, height * .075)
        .clamp(48.0, 70.0)
        .toDouble();
    final progressHeight = (height * .018).clamp(13.0, 20.0).toDouble();
    final kokaSize = math
        .min(width * .36, height * .20)
        .clamp(110.0, 190.0)
        .toDouble();
    final letterSize = math
        .min(width * .23, height * .11)
        .clamp(74.0, 118.0)
        .toDouble();

    final placements = <String, Offset>{
      'A': Offset(width * .13, height * .63),
      'N': Offset(width * .73, height * .47),
      'T': Offset(width * .56, height * .76),
    };

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/level_game/classroom.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Image.asset(
              '${_UnitOneQuizStage._assetBase}/levelgame-bg.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: width * .055,
            top: safeTop + height * .022,
            child: _PresentationImageButton(
              asset: '${_UnitOneQuizStage._assetBase}/exit-page.png',
              size: controlSize,
              onTap: () => unawaited(_exitLessonFromContext(context)),
              tooltip: 'Balik',
            ),
          ),
          Positioned(
            left: width * .24,
            right: width * .24,
            top: safeTop + height * .042,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: widget.progress.clamp(0, 1).toDouble(),
                minHeight: progressHeight,
                backgroundColor: Colors.white,
                color: TudloColors.green,
              ),
            ),
          ),
          Positioned(
            right: width * .055,
            top: safeTop + height * .022,
            child: _ClassroomRoundSpeakerButton(
              size: controlSize * 1.15,
              onTap: _playCurrentLetter,
            ),
          ),
          Positioned(
            left: width * .06,
            right: width * .06,
            top: safeTop + height * .105,
            child: _ClassroomSpeechBubble(
              message: 'Pangitaa ang nadula nga mga letra!',
              fontSize: (width * .065).clamp(24.0, 44.0),
            ),
          ),
          Positioned(
            left: -width * .025,
            bottom: height * .04,
            child: _LessonKokaMascot(size: kokaSize, mood: KokaMood.idle),
          ),
          for (final letter in _hiddenLetters.where(_targets.contains))
            Positioned(
              left: placements[letter]!.dx,
              top: placements[letter]!.dy,
              child: _ClassroomHiddenLetterButton(
                letter: letter,
                size: letterSize,
                found: _found.contains(letter),
                wrong: _wrong == letter,
                onTap: () => _tapHidden(letter),
              ),
            ),
          Positioned(
            left: width * .045,
            right: width * .045,
            bottom: height * .03,
            child: _ClassroomFoundLettersTray(
              targets: _targets,
              found: _found,
              enabled: _done,
              onNext: widget.onDone,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesClassroomLetterHunt) {
      return _buildClassroomLetterHunt(context);
    }

    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Nakita mo sila tanan!'
          : _wrong != null
          ? 'Koka: Indi ina ang ginapangita.'
          : 'Koka: Unahon ta pangitaon ang letra nga mabatian mo.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 290,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                const letterPlacements = [
                  Offset(.00, .18),
                  Offset(.64, .02),
                  Offset(.83, .34),
                  Offset(.18, .56),
                  Offset(.50, .62),
                  Offset(.03, .44),
                  Offset(.68, .68),
                ];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var index = 0; index < _hiddenLetters.length; index++)
                      Positioned(
                        left:
                            width *
                            letterPlacements[index % letterPlacements.length]
                                .dx,
                        top:
                            height *
                            letterPlacements[index % letterPlacements.length]
                                .dy,
                        child: _HiddenLetterButton(
                          letter: _hiddenLetters[index],
                          found: _found.contains(_hiddenLetters[index]),
                          wrong: _wrong == _hiddenLetters[index],
                          onTap: () => _tapHidden(_hiddenLetters[index]),
                        ),
                      ),
                    Positioned(
                      left: -width * .03,
                      top: height * .47,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/tree1.png',
                        width: 154,
                      ),
                    ),
                    Positioned(
                      right: -width * .02,
                      top: height * .16,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/tree2.png',
                        width: 160,
                      ),
                    ),
                    Positioned(
                      left: width * .00,
                      bottom: height * .06,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/grass.png',
                        width: 152,
                      ),
                    ),
                    Positioned(
                      right: width * .02,
                      bottom: height * .10,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/rock.png',
                        width: 126,
                      ),
                    ),
                    Positioned(
                      left: width * .53,
                      top: height * .58,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/grass.png',
                        width: 118,
                      ),
                    ),
                    Positioned(
                      right: width * .16,
                      top: height * .43,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/rock.png',
                        width: 92,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          _PresentationSpeakerHint(
            size: 108,
            showFinger: _showSpeakerHint && !_done,
            tapScale: _tapScale,
            tapOffset: _tapOffset,
            onTap: _playCurrentLetter,
          ),
          const SizedBox(height: 0),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              for (final target in _targets)
                _LetterSlot(
                  label: _found.contains(target) ? target : '',
                  large: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _UnitOneSubmitButton(enabled: _done, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _UnitOneSubjectMatchActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final List<_AlphabetAnchor> anchors;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneSubjectMatchActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.anchors,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneSubjectMatchActivity> createState() =>
      _UnitOneSubjectMatchActivityState();
}

class _UnitOneSubjectMatchActivityState
    extends State<_UnitOneSubjectMatchActivity> {
  _AlphabetAnchor? _selected;
  final Set<String> _matched = {};
  bool _wrong = false;
  bool _done = false;

  int get _targetMatchCount => math.min(3, widget.anchors.length);

  Future<void> _selectName(_AlphabetAnchor anchor) async {
    if (_done || _matched.contains(anchor.word)) return;
    setState(() {
      _selected = anchor;
      _wrong = false;
    });
  }

  Future<void> _tapImage(_AlphabetAnchor anchor) async {
    if (_done || _matched.contains(anchor.word) || _selected == null) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = _selected!.word == anchor.word;
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _matched.add(anchor.word);
        _selected = null;
        _wrong = false;
        _done = _matched.length == _targetMatchCount;
      });
      unawaited(AppAudioService.instance.playCorrect());
      if (_done) {
        await TudloVoiceButton.speak(context, 'Husto! Naipares mo tanan.');
      }
    } else {
      setState(() => _wrong = true);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchors = widget.anchors.take(3).toList();
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto tanan!'
          : _wrong
          ? 'Koka: Suliton liwat.'
          : 'Koka: Pili-a ang ngalan, dayon pindoton ang sapat.',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final anchor in anchors)
                _MatchImageTile(
                  anchor: anchor,
                  selected: _selected?.word == anchor.word,
                  matched: _matched.contains(anchor.word),
                  wrong: _wrong && _selected != null,
                  onTap: () => _tapImage(anchor),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final anchor in anchors)
                _MatchNameButton(
                  label: _titleCase(anchor.meaning),
                  selected: _selected?.word == anchor.word,
                  matched: _matched.contains(anchor.word),
                  onTap: () => _selectName(anchor),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _UnitOneSubmitButton(enabled: _done, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _UnitOneDragFillActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final String word;
  final String? imageAsset;
  final IconData icon;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneDragFillActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.word,
    this.imageAsset,
    required this.icon,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneDragFillActivity> createState() =>
      _UnitOneDragFillActivityState();
}

class _UnitOneDragFillActivityState extends State<_UnitOneDragFillActivity> {
  final List<String> _filled = [];
  String? _wrong;
  bool _done = false;

  late final List<String> _targets = widget.word
      .replaceAll(RegExp(r'\s+'), '')
      .characters
      .map((letter) => letter.toUpperCase())
      .toList();
  late final List<String> _choices = _shuffledChoices(_targets.toSet());

  Future<void> _drop(String value) async {
    if (_done) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final expected = _targets[_filled.length];
    final correct = value == expected;
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _filled.add(value);
        _wrong = null;
        _done = _filled.length == _targets.length;
      });
      unawaited(AppAudioService.instance.playCorrect());
      if (_done) {
        await TudloVoiceButton.speak(
          context,
          'Husto! Natapos mo.',
          hiligaynon: true,
          waitForCompletion: true,
        );
      }
    } else {
      setState(() => _wrong = value);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto! Natapos mo.'
          : _wrong != null
          ? 'Koka: Suliton liwat.'
          : 'Koka: Guyoda ang husto sa kahon.',
      child: Column(
        children: [
          SizedBox(
            height: widget.imageAsset == null ? 142 : 190,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SubjectQuestionLabel(
                  imageAsset: widget.imageAsset,
                  icon: widget.icon,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: widget.imageAsset == null
                      ? Icon(widget.icon, color: TudloColors.green, size: 110)
                      : Image.asset(
                          widget.imageAsset!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Icon(
                            widget.icon,
                            color: TudloColors.green,
                            size: 110,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _targets.length; i++)
                DragTarget<String>(
                  onWillAcceptWithDetails: (_) => !_done,
                  onAcceptWithDetails: (details) => _drop(details.data),
                  builder: (context, candidates, rejected) {
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 140),
                      scale: candidates.isNotEmpty ? 1.08 : 1,
                      child: _LetterSlot(
                        label: i < _filled.length ? _filled[i] : '',
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: [
                  for (final value in _choices)
                    Draggable<String>(
                      data: value,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _UnitOneSymbolButton(
                          label: value,
                          isLetter: true,
                          assetSize: 82,
                          onTap: () {},
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .35,
                        child: _UnitOneSymbolButton(
                          label: value,
                          isLetter: true,
                          assetSize: 82,
                          onTap: () {},
                        ),
                      ),
                      child: _UnitOneSymbolButton(
                        label: value,
                        isLetter: true,
                        assetSize: 82,
                        wrong: _wrong == value,
                        onTap: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _UnitOneSubmitButton(enabled: _done, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _UnitOneSymbolButton extends StatelessWidget {
  final String label;
  final bool isLetter;
  final bool selected;
  final bool correct;
  final bool wrong;
  final double? assetSize;
  final VoidCallback onTap;

  const _UnitOneSymbolButton({
    required this.label,
    required this.onTap,
    this.isLetter = false,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
    this.assetSize,
  });

  @override
  Widget build(BuildContext context) {
    final asset = isLetter ? _unitOneLetterAsset(label) : null;
    final usesAssetChoice = asset != null && isLetter;
    final color = wrong
        ? TudloColors.coral
        : correct
        ? TudloColors.green
        : selected
        ? TudloColors.blue
        : Colors.white;
    final feedbackColor = wrong
        ? TudloColors.coral
        : correct
        ? TudloColors.green
        : selected
        ? TudloColors.blue
        : TudloColors.green;
    final choiceSize =
        assetSize ?? (usesAssetChoice ? 116.0 : (isLetter ? 100.0 : 112.0));
    final choiceHeight =
        assetSize ?? (usesAssetChoice ? 116.0 : (isLetter ? 100.0 : 70.0));
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: selected || correct ? 1.08 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: choiceSize,
            height: choiceHeight,
            alignment: Alignment.center,
            padding: EdgeInsets.all(usesAssetChoice ? 0 : 8),
            decoration: BoxDecoration(
              color: usesAssetChoice ? Colors.transparent : color,
              borderRadius: BorderRadius.circular(24),
              border: usesAssetChoice
                  ? null
                  : Border.all(
                      color: wrong
                          ? TudloColors.coral
                          : correct
                          ? TudloColors.green
                          : selected
                          ? TudloColors.blue
                          : TudloColors.green.withValues(alpha: .28),
                      width: selected || correct || wrong ? 4 : 2,
                    ),
              boxShadow: usesAssetChoice
                  ? [
                      if (selected || correct || wrong)
                        BoxShadow(
                          color: feedbackColor.withValues(alpha: .62),
                          blurRadius: selected ? 34 : 26,
                          spreadRadius: selected ? 9 : 5,
                        ),
                      if (selected)
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .75),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                    ]
                  : [
                      BoxShadow(
                        color: feedbackColor.withValues(
                          alpha: selected || correct || wrong ? .36 : .10,
                        ),
                        blurRadius: selected || correct || wrong ? 22 : 10,
                        spreadRadius: selected ? 3 : 0,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: asset == null
                ? Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: color == Colors.white
                          ? TudloColors.ink
                          : Colors.white,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  )
                : Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Text(
                      label,
                      style: GoogleFonts.nunito(
                        color: wrong ? TudloColors.coral : TudloColors.blue,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LetterSlot extends StatelessWidget {
  final String label;
  final bool large;

  const _LetterSlot({required this.label, this.large = false});

  @override
  Widget build(BuildContext context) {
    final width = large ? 72.0 : 58.0;
    final height = large ? 76.0 : 64.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: label.isEmpty
            ? Colors.white.withValues(alpha: .92)
            : TudloColors.softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: label.isEmpty
              ? TudloColors.green.withValues(alpha: .35)
              : TudloColors.green,
          width: 3,
        ),
      ),
      child: label.isEmpty
          ? const SizedBox.shrink()
          : Text(
              label,
              style: GoogleFonts.nunito(
                color: TudloColors.forest,
                fontSize: large ? 38 : 32,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
    );
  }
}

class _PlainAnswerLetter extends StatelessWidget {
  final String label;

  const _PlainAnswerLetter({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 62,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 46,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0xFF459B27),
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
              Shadow(color: Colors.white, blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingLetterUnderlineSlot extends StatelessWidget {
  final String label;
  final Color lineColor;
  final bool active;

  const _MissingLetterUnderlineSlot({
    required this.label,
    required this.lineColor,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final filled = label.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 60,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: lineColor, width: active ? 7 : 6),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: lineColor.withValues(alpha: .34),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: filled
          ? Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 46,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: const [
                  Shadow(
                    color: Color(0xFF459B27),
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                  Shadow(color: Colors.white, blurRadius: 1),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

Color _quizLineColorAt(int index) {
  const colors = [
    Color(0xFF1EA7FF),
    Color(0xFFFFC928),
    Color(0xFFFF6B57),
    Color(0xFF8C5CFF),
    Color(0xFF00BFA6),
  ];
  return colors[index % colors.length];
}

class _ClassroomSpeechBubble extends StatelessWidget {
  final String message;
  final double fontSize;

  const _ClassroomSpeechBubble({required this.message, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ClassroomBubbleTailPainter(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * .95,
          vertical: fontSize * .72,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            color: const Color(0xFF006B56),
            fontSize: fontSize,
            height: 1.06,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ClassroomBubbleTailPainter extends CustomPainter {
  const _ClassroomBubbleTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF8E6)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * .30, size.height - 2)
      ..quadraticBezierTo(
        size.width * .30,
        size.height + 46,
        size.width * .22,
        size.height + 58,
      )
      ..quadraticBezierTo(
        size.width * .34,
        size.height + 52,
        size.width * .37,
        size.height - 2,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClassroomRoundSpeakerButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _ClassroomRoundSpeakerButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AppAudioService.instance.playTap();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Image.asset(
          '${_UnitOneQuizStage._assetBase}/speaker.png',
          width: size * .58,
          height: size * .58,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(
            Icons.volume_up_rounded,
            color: TudloColors.green,
            size: size * .48,
          ),
        ),
      ),
    );
  }
}

class _ClassroomHiddenLetterButton extends StatelessWidget {
  final String letter;
  final double size;
  final bool found;
  final bool wrong;
  final VoidCallback onTap;

  const _ClassroomHiddenLetterButton({
    required this.letter,
    required this.size,
    required this.found,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: found ? null : onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: found ? .68 : 1,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: found ? .18 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (wrong ? TudloColors.coral : const Color(0xFFFFE96B))
                        .withValues(alpha: wrong ? .52 : .72),
                    blurRadius: wrong ? 18 : 26,
                    spreadRadius: wrong ? 3 : 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: .55),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _IntroLetterArt(letter: letter, size: size),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassroomFoundLettersTray extends StatelessWidget {
  final List<String> targets;
  final Set<String> found;
  final bool enabled;
  final VoidCallback onNext;

  const _ClassroomFoundLettersTray({
    required this.targets,
    required this.found,
    required this.enabled,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final slotSize = (view.width * .16).clamp(54.0, 92.0).toDouble();
    final nextSize = (view.width * .20).clamp(66.0, 108.0).toDouble();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (view.width * .055).clamp(14.0, 28.0),
        vertical: (view.height * .018).clamp(12.0, 22.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6).withValues(alpha: .95),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: (view.width * .045).clamp(12.0, 28.0),
              runSpacing: 10,
              children: [
                for (final target in targets)
                  _ClassroomLetterTraySlot(
                    letter: found.contains(target) ? target : '',
                    size: slotSize,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Opacity(
            opacity: enabled ? 1 : .45,
            child: _PresentationImageButton(
              asset: '${_UnitOneQuizStage._assetBase}/next-lesson.png',
              size: nextSize,
              enabled: enabled,
              tooltip: 'Padayon',
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomLetterTraySlot extends StatelessWidget {
  final String letter;
  final double size;

  const _ClassroomLetterTraySlot({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: .42), width: 2),
      ),
      child: letter.isEmpty
          ? Text(
              letter,
              style: GoogleFonts.nunito(
                color: Colors.grey.withValues(alpha: .45),
                fontSize: size * .52,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            )
          : _IntroLetterArt(letter: letter, size: size * .72),
    );
  }
}

class _HiddenSceneCover extends StatelessWidget {
  final String asset;
  final double width;

  const _HiddenSceneCover({required this.asset, required this.width});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Image.asset(
        asset,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _HiddenLetterButton extends StatelessWidget {
  final String letter;
  final bool found;
  final bool wrong;
  final VoidCallback onTap;

  const _HiddenLetterButton({
    required this.letter,
    required this.found,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: found ? null : onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: found ? .72 : 1,
          child: AnimatedOpacity(
            opacity: found ? .22 : 1,
            duration: const Duration(milliseconds: 160),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (wrong)
                    BoxShadow(
                      color: TudloColors.coral.withValues(alpha: .36),
                      blurRadius: 22,
                      spreadRadius: 4,
                    )
                  else
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .24),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: _IntroLetterArt(letter: letter, size: 82),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchImageTile extends StatelessWidget {
  final _AlphabetAnchor anchor;
  final bool selected;
  final bool matched;
  final bool wrong;
  final VoidCallback onTap;

  const _MatchImageTile({
    required this.anchor,
    required this.selected,
    required this.matched,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: matched,
      wrong: wrong && selected,
      child: GestureDetector(
        onTap: matched ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 138,
          height: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: matched
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected || matched
                  ? TudloColors.green
                  : TudloColors.line.withValues(alpha: .35),
              width: selected || matched ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.green.withValues(alpha: .12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: anchor.imageAsset == null
              ? Icon(anchor.icon, color: TudloColors.green, size: 92)
              : Image.asset(
                  anchor.imageAsset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(anchor.icon, color: TudloColors.green, size: 92),
                ),
        ),
      ),
    );
  }
}

class _MatchNameButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;

  const _MatchNameButton({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: matched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 132,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: matched || selected ? TudloColors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TudloColors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: TudloColors.green.withValues(alpha: .12),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: matched || selected ? Colors.white : TudloColors.forest,
              fontSize: 22,
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

enum _AlphabetPresentationSlideType { letter, word, highlight, continuePrompt }

class _AlphabetPresentationTarget {
  final String letter;
  final String word;
  final String meaning;
  final List<String> imageAssets;
  final IconData icon;

  const _AlphabetPresentationTarget({
    required this.letter,
    required this.word,
    required this.meaning,
    required this.imageAssets,
    required this.icon,
  });

  factory _AlphabetPresentationTarget.fromAnchor({
    required String letter,
    required _AlphabetAnchor anchor,
  }) {
    final imageAssets = anchor.imageAssets.isNotEmpty
        ? anchor.imageAssets
        : [if (anchor.imageAsset != null) anchor.imageAsset!];
    return _AlphabetPresentationTarget(
      letter: letter.toUpperCase(),
      word: anchor.word,
      meaning: anchor.meaning,
      imageAssets: imageAssets,
      icon: anchor.icon,
    );
  }

  String get displayWord => _titleCase(word);
  String get speechWord => meaning.isEmpty ? word.toLowerCase() : meaning;
}

class _AlphabetPresentationSlideData {
  final _AlphabetPresentationTarget target;
  final _AlphabetPresentationSlideType type;

  const _AlphabetPresentationSlideData({
    required this.target,
    required this.type,
  });

  String get voiceText {
    final letter = target.letter;
    return switch (type) {
      _AlphabetPresentationSlideType.letter =>
        'Ang tunog sang letra nga $letter amo ang...',
      _AlphabetPresentationSlideType.word =>
        'Abyan, kilala mo kon sin-o ini? Siya si...',
      _AlphabetPresentationSlideType.highlight =>
        'May ara letra nga $letter sa may ${target.speechWord}.',
      _AlphabetPresentationSlideType.continuePrompt =>
        'Maayo gid abyan, padayon kita.',
    };
  }

  String get dialogueText {
    final letter = target.letter;
    final word = target.speechWord;
    return switch (type) {
      _AlphabetPresentationSlideType.letter =>
        'Ang tunog sang letra nga "$letter" amo ang...',
      _AlphabetPresentationSlideType.word =>
        'Abyan, kilala mo kon sin-o ini? Siya si...',
      _AlphabetPresentationSlideType.highlight =>
        'May ara letra nga "$letter" sa may $word',
      _AlphabetPresentationSlideType.continuePrompt =>
        'Maayo gid abyan, padayon kita',
    };
  }

  String get soundText {
    return switch (type) {
      _AlphabetPresentationSlideType.letter => _letterSoundText(target.letter),
      _AlphabetPresentationSlideType.word ||
      _AlphabetPresentationSlideType.highlight => target.speechWord,
      _AlphabetPresentationSlideType.continuePrompt => voiceText,
    };
  }

  bool get darkenCard => type == _AlphabetPresentationSlideType.highlight;
  bool get showWord => type != _AlphabetPresentationSlideType.letter;
  bool get showLetter => type == _AlphabetPresentationSlideType.letter;
  bool get showTapHint => type == _AlphabetPresentationSlideType.highlight;
}

class _AlphabetPresentationSlide extends StatefulWidget {
  final _AlphabetPresentationSlideData data;
  final int stepNumber;
  final int totalSteps;
  final bool canGoBack;
  final VoidCallback onExit;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _AlphabetPresentationSlide({
    super.key,
    required this.data,
    required this.stepNumber,
    required this.totalSteps,
    required this.canGoBack,
    required this.onExit,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_AlphabetPresentationSlide> createState() =>
      _AlphabetPresentationSlideState();
}

class _AlphabetPresentationSlideState extends State<_AlphabetPresentationSlide>
    with SingleTickerProviderStateMixin {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';
  AnimationController? _tapHintController;
  Animation<double>? _tapScale;
  Animation<Offset>? _tapOffset;
  Timer? _hideSpeakerHintTimer;
  Timer? _inactiveSpeakerHintTimer;
  bool _showSpeakerHint = false;

  Animation<double> get _safeTapScale =>
      _tapScale ?? const AlwaysStoppedAnimation<double>(1);

  Animation<Offset> get _safeTapOffset =>
      _tapOffset ?? const AlwaysStoppedAnimation<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();
    final tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _tapHintController = tapHintController;
    final curve = CurvedAnimation(
      parent: tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    _configureSpeakerHint();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) unawaited(_speak());
      });
    });
  }

  @override
  void didUpdateWidget(covariant _AlphabetPresentationSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepNumber != widget.stepNumber ||
        oldWidget.data.type != widget.data.type) {
      _configureSpeakerHint();
    }
  }

  @override
  void dispose() {
    _hideSpeakerHintTimer?.cancel();
    _inactiveSpeakerHintTimer?.cancel();
    _tapHintController?.dispose();
    super.dispose();
  }

  void _configureSpeakerHint() {
    _hideSpeakerHintTimer?.cancel();
    _inactiveSpeakerHintTimer?.cancel();
    final shouldShow = widget.stepNumber == 1;
    _showSpeakerHint = shouldShow;
    if (shouldShow) {
      _hideSpeakerHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSpeakerHint = false);
      });
    }
  }

  void _hideSpeakerHintUntilInactive() {
    _hideSpeakerHintTimer?.cancel();
    _inactiveSpeakerHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (widget.stepNumber != 1) return;
    _inactiveSpeakerHintTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() => _showSpeakerHint = true);
      _hideSpeakerHintTimer?.cancel();
      _hideSpeakerHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSpeakerHint = false);
      });
    });
  }

  Future<void> _speak() async {
    await TudloVoiceButton.speak(
      context,
      widget.data.voiceText,
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _speakSoundOnly() async {
    _hideSpeakerHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      widget.data.soundText,
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.sizeOf(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.height;
        final safeTop = MediaQuery.paddingOf(context).top;
        final mascotSize = math
            .min(width * .42, height * .26)
            .clamp(148.0, 232.0)
            .toDouble();
        final topButtonSize = math
            .min(width * .14, height * .075)
            .clamp(48.0, 66.0)
            .toDouble();
        final navButtonSize = math
            .min(width * .27, height * .15)
            .clamp(110.0, 160.0)
            .toDouble();
        final isContinuePrompt =
            data.type == _AlphabetPresentationSlideType.continuePrompt;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  '$_assetBase/levelgame-bg.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                left: width * .06,
                top: safeTop + height * .025,
                child: _PresentationImageButton(
                  asset: '$_assetBase/exit-page.png',
                  size: topButtonSize,
                  onTap: widget.onExit,
                  tooltip: 'Balik',
                ),
              ),
              Positioned(
                left: width * .28,
                right: width * .27,
                top: safeTop + height * .045,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.totalSteps == 0
                        ? 0
                        : widget.stepNumber / widget.totalSteps,
                    minHeight: (height * .023).clamp(16.0, 24.0),
                    backgroundColor: Colors.white,
                    color: TudloColors.green,
                  ),
                ),
              ),
              if (!isContinuePrompt) ...[
                Positioned(
                  left: width * .005,
                  top: safeTop + height * .115,
                  child: _LessonKokaMascot(
                    size: mascotSize,
                    mood: KokaMood.idle,
                  ),
                ),
                Positioned(
                  left: width * .31,
                  right: width * .035,
                  top: safeTop + height * .108,
                  child: _PresentationInstructionText(
                    message: data.dialogueText,
                    fontSize: (width * .073).clamp(26.0, 42.0),
                    onReplay: _speak,
                  ),
                ),
                Positioned(
                  left: width * .04,
                  right: width * .04,
                  top: height * .29,
                  bottom: height * .235,
                  child: _AlphabetPresentationBoard(
                    data: data,
                    showSpeakerHint: _showSpeakerHint,
                    tapScale: _safeTapScale,
                    tapOffset: _safeTapOffset,
                    onReplay: _speakSoundOnly,
                  ),
                ),
              ] else ...[
                Positioned(
                  left: width * .12,
                  right: width * .12,
                  top: height * .285,
                  child: Center(
                    child: _PresentationInstructionText(
                      message: data.dialogueText,
                      fontSize: (width * .078).clamp(28.0, 44.0),
                      textAlign: TextAlign.center,
                      onReplay: _speak,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * .39,
                  child: Center(
                    child: _LessonKokaMascot(
                      size: (mascotSize * 1.72).clamp(230.0, 380.0),
                      mood: KokaMood.idle,
                    ),
                  ),
                ),
              ],
              Positioned(
                left: width * .19,
                bottom: height * .09,
                child: _PresentationImageButton(
                  asset: '$_assetBase/back-lesson.png',
                  size: navButtonSize,
                  onTap: widget.onBack,
                  enabled: widget.canGoBack,
                  tooltip: 'Balik',
                ),
              ),
              Positioned(
                right: width * .19,
                bottom: height * .09,
                child: _PresentationImageButton(
                  asset: '$_assetBase/next-lesson.png',
                  size: navButtonSize,
                  onTap: widget.onNext,
                  tooltip: 'Sunod',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresentationImageButton extends StatelessWidget {
  final String asset;
  final double size;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _PresentationImageButton({
    required this.asset,
    required this.size,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .34,
      child: GestureDetector(
        onTap: enabled
            ? () async {
                await AppAudioService.instance.playTap();
                onTap();
              }
            : null,
        child: Tooltip(
          message: tooltip,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              tooltip == 'Balik'
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
              size: size * .74,
              color: TudloColors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresentationInstructionText extends StatelessWidget {
  final String message;
  final double fontSize;
  final TextAlign textAlign;
  final VoidCallback onReplay;

  const _PresentationInstructionText({
    required this.message,
    required this.fontSize,
    this.textAlign = TextAlign.start,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.nunito(
      color: Colors.white,
      fontSize: fontSize,
      height: 1.18,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: .08),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );

    final iconSize = (fontSize * 1.15).clamp(30.0, 44.0);
    return RichText(
      textAlign: textAlign,
      maxLines: 4,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: '$message '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () async {
                await AppAudioService.instance.playTap();
                onReplay();
              },
              child: Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: TudloColors.green,
                  size: (fontSize * .70).clamp(20.0, 30.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlphabetPresentationBoard extends StatelessWidget {
  final _AlphabetPresentationSlideData data;
  final bool showSpeakerHint;
  final Animation<double> tapScale;
  final Animation<Offset> tapOffset;
  final VoidCallback onReplay;

  const _AlphabetPresentationBoard({
    required this.data,
    required this.showSpeakerHint,
    required this.tapScale,
    required this.tapOffset,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final target = data.target;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final stageHeight = constraints.maxHeight;
        final letterSize = math
            .min(stageWidth * .60, stageHeight * .54)
            .clamp(190.0, 310.0)
            .toDouble();
        final artSize = math
            .min(stageWidth * .82, stageHeight * .66)
            .clamp(180.0, 330.0)
            .toDouble();
        final speakerSize = math
            .min(stageWidth * .44, stageHeight * .30)
            .clamp(122.0, 176.0)
            .toDouble();
        return SizedBox(
          width: stageWidth,
          height: stageHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (data.showWord)
                Positioned(
                  top: 0,
                  left: stageWidth * .02,
                  right: stageWidth * .02,
                  child: _PresentationWordTitle(
                    word: target.displayWord,
                    highlightLetter: data.showTapHint ? target.letter : null,
                  ),
                ),
              Align(
                alignment: data.showLetter
                    ? const Alignment(0, -.05)
                    : const Alignment(0, -.10),
                child: data.showLetter
                    ? _PresentationLetterPair(
                        letter: target.letter,
                        color: Colors.white,
                        size: letterSize,
                      )
                    : Padding(
                        padding: EdgeInsets.only(
                          top: data.showWord ? stageHeight * .12 : 0,
                          bottom: stageHeight * .10,
                        ),
                        child: _PresentationAssetArt(
                          target: target,
                          size: artSize,
                          maxWidth: stageWidth * .94,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                child: _PresentationSpeakerHint(
                  size: speakerSize,
                  showFinger: showSpeakerHint,
                  tapScale: tapScale,
                  tapOffset: tapOffset,
                  onTap: () {
                    unawaited(AppAudioService.instance.playTap());
                    onReplay();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresentationWordTitle extends StatelessWidget {
  final String word;
  final String? highlightLetter;

  const _PresentationWordTitle({required this.word, this.highlightLetter});

  @override
  Widget build(BuildContext context) {
    if (highlightLetter != null) {
      return _PresentationOutlinedWord(
        word: word,
        highlightLetter: highlightLetter,
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        word,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: Colors.white.withValues(alpha: .78),
          fontSize: word.length > 11 ? 38 : 52,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          shadows: const [
            Shadow(
              color: Color(0xFF2A6655),
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
            Shadow(color: Colors.white, blurRadius: 1),
          ],
        ),
      ),
    );
  }
}

class _PresentationOutlinedWord extends StatelessWidget {
  final String word;
  final String? highlightLetter;

  const _PresentationOutlinedWord({
    required this.word,
    required this.highlightLetter,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final letter in letters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
              decoration: letter.toUpperCase() == highlightLetter
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: TudloColors.blue,
                          width: word.length > 11 ? 5 : 7,
                        ),
                      ),
                    )
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.transparent, width: 7),
                      ),
                    ),
              child: Text(
                letter,
                style: GoogleFonts.nunito(
                  color: Colors.transparent,
                  fontSize: word.length > 11 ? 34 : 50,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(1.5, 0),
                    ),
                    Shadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(3, 3),
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

class _PresentationLetterPair extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;

  const _PresentationLetterPair({
    required this.letter,
    this.color = const Color(0xFF416F61),
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PresentationOutlinedLetter(
            letter: letter.toUpperCase(),
            size: size,
            color: color,
          ),
          SizedBox(width: size * .12),
          _PresentationOutlinedLetter(
            letter: letter.toLowerCase(),
            size: size,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _PresentationOutlinedLetter extends StatelessWidget {
  final String letter;
  final double size;
  final Color color;

  const _PresentationOutlinedLetter({
    required this.letter,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.nunito(
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    );
    return Stack(
      children: [
        Text(
          letter,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = Colors.white,
          ),
        ),
        Text(
          letter,
          style: style.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresentationSpeakerHint extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final double size;
  final bool showFinger;
  final Animation<double> tapScale;
  final Animation<Offset> tapOffset;
  final VoidCallback onTap;

  const _PresentationSpeakerHint({
    required this.size,
    required this.showFinger,
    required this.tapScale,
    required this.tapOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size * .86,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Image.asset(
              '$_assetBase/speaker.png',
              width: size * .58,
              height: size * .58,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(
                width: size * .58,
                height: size * .58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: TudloColors.green,
                  size: size * .32,
                ),
              ),
            ),
            if (showFinger)
              Positioned(
                right: 0,
                bottom: -size * .04,
                child: AnimatedBuilder(
                  animation: tapScale,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: tapOffset.value,
                      child: Transform.scale(
                        scale: tapScale.value,
                        alignment: Alignment.topLeft,
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedPointFinger(
                    asset: '$_assetBase/point-finger.png',
                    size: size * .56,
                    angle: -.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresentationSyllablePractice extends StatefulWidget {
  final List<String> syllables;
  final String fullWord;

  const _PresentationSyllablePractice({
    required this.syllables,
    required this.fullWord,
  });

  @override
  State<_PresentationSyllablePractice> createState() =>
      _PresentationSyllablePracticeState();
}

class _PresentationSyllablePracticeState
    extends State<_PresentationSyllablePractice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleController;
  int _nextIndex = 0;
  int? _wrongIndex;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  Future<void> _tapSyllable(int index) async {
    if (index != _nextIndex) {
      setState(() => _wrongIndex = index);
      _wiggleController.forward(from: 0);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Pindoton ang ${widget.syllables[_nextIndex]} anay.',
        hiligaynon: true,
      );
      return;
    }

    final syllable = widget.syllables[index];
    unawaited(AppAudioService.instance.playSyllableTap());
    setState(() {
      _wrongIndex = null;
      _nextIndex = (_nextIndex + 1).clamp(0, widget.syllables.length);
    });
    await TudloVoiceButton.speak(
      context,
      _titleCase(syllable),
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_nextIndex >= widget.syllables.length) {
      await TudloVoiceButton.speak(context, widget.fullWord, hiligaynon: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < widget.syllables.length; index++) ...[
          Expanded(child: _buildSyllable(index)),
          if (index < widget.syllables.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildSyllable(int index) {
    final selected = index < _nextIndex;
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _tapSyllable(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? TudloColors.green
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .40),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            widget.syllables[index],
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: selected ? Colors.white : TudloColors.ink,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );

    if (_wrongIndex != index) return card;
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        final dx = math.sin(_wiggleController.value * math.pi * 4) * 5;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: card,
    );
  }
}

class _PresentationAssetArt extends StatelessWidget {
  final _AlphabetPresentationTarget target;
  final double size;
  final double? maxWidth;

  const _PresentationAssetArt({
    required this.target,
    required this.size,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (target.imageAssets.length > 1) {
      final pairWidth = math.min(size * 1.18, maxWidth ?? size * 1.18);
      final imageWidth = pairWidth * .55;
      final sideInset = pairWidth * .035;
      return SizedBox(
        width: pairWidth,
        height: size * 1.08,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.bottomCenter,
          children: [
            for (var index = 0; index < target.imageAssets.length; index++)
              Positioned(
                left: index == 0 ? sideInset : null,
                right: index == 0 ? null : sideInset,
                bottom: 0,
                child: Image.asset(
                  target.imageAssets[index],
                  width: imageWidth,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(target.icon, color: Colors.white, size: size * .55),
                ),
              ),
          ],
        ),
      );
    }
    if (target.imageAssets.isEmpty) {
      return Icon(target.icon, color: Colors.white, size: size * .72);
    }
    return Image.asset(
      target.imageAssets.first,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          Icon(target.icon, color: Colors.white, size: size * .72),
    );
  }
}

class _QuizTimeSplash extends StatefulWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final double progress;
  final VoidCallback onDone;

  const _QuizTimeSplash({this.progress = 0, required this.onDone});

  @override
  State<_QuizTimeSplash> createState() => _QuizTimeSplashState();
}

class _QuizTimeSplashState extends State<_QuizTimeSplash> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final safeTop = MediaQuery.paddingOf(context).top;
        final topButtonSize = math
            .min(width * .14, height * .075)
            .clamp(48.0, 66.0)
            .toDouble();
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                '${_QuizTimeSplash._assetBase}/levelgame-bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                left: width * .06,
                top: safeTop + height * .025,
                child: _PresentationImageButton(
                  asset: '${_QuizTimeSplash._assetBase}/exit-page.png',
                  size: topButtonSize,
                  onTap: () => unawaited(_exitLessonFromContext(context)),
                  tooltip: 'Balik',
                ),
              ),
              Positioned(
                left: width * .28,
                right: width * .27,
                top: safeTop + height * .045,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.progress.clamp(0, 1).toDouble(),
                    minHeight: (height * .023).clamp(16.0, 24.0),
                    backgroundColor: Colors.white,
                    color: TudloColors.green,
                  ),
                ),
              ),
              Positioned(
                right: width * .055,
                top: safeTop + height * .026,
                child: Transform.scale(
                  scale: .78,
                  alignment: Alignment.topRight,
                  child: const EnergyIndicator(),
                ),
              ),
              Positioned(
                left: width * .10,
                right: width * .10,
                top: height * .31,
                child: Text(
                  'Oras na sang Pagtilaw!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: (width * .082).clamp(30.0, 46.0),
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF459B27),
                        blurRadius: 0,
                        offset: Offset(2, 2),
                      ),
                      Shadow(color: Colors.white, blurRadius: 1),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: height * .39,
                child: Center(
                  child: _LessonKokaMascot(
                    size: (width * .62).clamp(230.0, 330.0),
                    mood: KokaMood.idle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlphabetLetterIntroCard extends StatefulWidget {
  final String letter;
  final _AlphabetAnchor anchor;
  final VoidCallback onDone;

  const _AlphabetLetterIntroCard({
    required this.letter,
    required this.anchor,
    required this.onDone,
  });

  @override
  State<_AlphabetLetterIntroCard> createState() =>
      _AlphabetLetterIntroCardState();
}

class _AlphabetLetterIntroCardState extends State<_AlphabetLetterIntroCard> {
  bool _revealed = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Pamatii ang tingog sang ${widget.letter.toUpperCase()}. Pindoton ang ${widget.letter.toUpperCase()}.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleTap() async {
    if (_done) return;
    setState(() => _revealed = true);
    await TudloVoiceButton.speak(
      context,
      '${_letterSoundText(widget.letter)}... ${widget.letter}! May ${widget.letter} sa ${widget.anchor.word}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    _done = true;
    Future<void>.delayed(const Duration(milliseconds: 1050), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter.toUpperCase();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final stageHeight = screenHeight.clamp(620.0, 760.0);
    final mainLetterTop = (stageHeight * .16).clamp(88.0, 126.0).toDouble();
    final bubbleTop = (stageHeight - 285).clamp(398.0, 490.0).toDouble();
    final revealedWordTop = (stageHeight * .22).clamp(146.0, 172.0).toDouble();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: SizedBox(
          height: stageHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: _revealed ? 18 : mainLetterTop,
                child: Center(
                  child: IgnorePointer(
                    ignoring: _revealed,
                    child: GestureDetector(
                      onTap: _handleTap,
                      child: _IntroLetterBounce(
                        active: !_revealed,
                        glow: true,
                        child: _IntroLetterArt(
                          letter: letter,
                          size: _revealed ? 132 : 282,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: revealedWordTop,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: _revealed
                      ? Column(
                          key: const ValueKey('word'),
                          children: [
                            _HighlightedAlphabetWord(
                              word: widget.anchor.word,
                              highlightLetter: letter,
                              letterSize: 104,
                            ),
                            const SizedBox(height: 18),
                            _AlphabetAnchorImage(
                              imageAsset: widget.anchor.imageAsset,
                              icon: widget.anchor.icon,
                              word: _titleCase(widget.anchor.word),
                              meaning: widget.anchor.meaning,
                              voiceMessage: widget.anchor.word,
                              compact: true,
                              height: 176,
                              showVoiceButton: false,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
              Positioned(
                right: -26,
                top: bubbleTop,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(
                    message: _revealed
                        ? 'Koka: May $letter sa ${widget.anchor.word}!'
                        : 'Koka: Pamatii ang tingog. Pindoton ang $letter.',
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

class _IntroLetterBounce extends StatelessWidget {
  final bool active;
  final bool glow;
  final Widget child;

  const _IntroLetterBounce({
    required this.active,
    required this.glow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final jump = active ? -math.sin(value * math.pi * 2) * 10 : 0.0;
        return Transform.translate(
          offset: Offset(0, jump),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD447).withValues(alpha: .42),
                        blurRadius: 42,
                        spreadRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _IntroLetterArt extends StatelessWidget {
  final String letter;
  final double size;

  const _IntroLetterArt({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = const {
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
    if (asset == null) {
      return Text(
        letter,
        style: TextStyle(
          color: TudloColors.blue,
          fontSize: size * .72,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _HighlightedAlphabetWord extends StatelessWidget {
  final String word;
  final String highlightLetter;
  final double letterSize;

  const _HighlightedAlphabetWord({
    required this.word,
    required this.highlightLetter,
    this.letterSize = 82,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final letter in letters) ...[
            SizedBox(
              width: letterSize * .64,
              height: letterSize,
              child: OverflowBox(
                minWidth: 0,
                maxWidth: letterSize,
                minHeight: 0,
                maxHeight: letterSize,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 360),
                  decoration: BoxDecoration(
                    boxShadow: letter.toUpperCase() == highlightLetter
                        ? [
                            BoxShadow(
                              color: TudloColors.green.withValues(alpha: .52),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: _IntroLetterArt(letter: letter, size: letterSize),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlphabetMascotBubble extends StatelessWidget {
  final String message;
  final double scale;

  const _AlphabetMascotBubble({required this.message, this.scale = 1});

  String get _cleanMessage =>
      message.replaceFirst(RegExp(r'^\s*Koka:\s*'), '').trim();

  @override
  Widget build(BuildContext context) {
    final width = 386.0 * scale;
    final height = 260.0 * scale;
    final bubbleWidth = 286.0 * scale;
    final bubbleHeight = 176.0 * scale;
    final mascotSize = 198.0 * scale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 90 * scale,
            top: 0,
            child: SizedBox(
              width: bubbleWidth,
              height: bubbleHeight,
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
                    padding: EdgeInsets.fromLTRB(
                      28 * scale,
                      22 * scale,
                      28 * scale,
                      40 * scale,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Text(
                              _cleanMessage,
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              style: TextStyle(
                                color: TudloColors.ink,
                                fontSize: 19 * scale,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _LessonKokaMascot(
              size: mascotSize,
              mood: _messageLooksLikeRetry ? KokaMood.annoyed : KokaMood.idle,
            ),
          ),
        ],
      ),
    );
  }

  bool get _messageLooksLikeRetry {
    final message = _cleanMessage.toLowerCase();
    return message.contains('sulayi liwat') ||
        message.contains('suliton liwat') ||
        message.contains('liwata') ||
        message.contains('indi husto');
  }
}

class _AlphabetAnchorImage extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;
  final String word;
  final String meaning;
  final String voiceMessage;
  final bool compact;
  final double? height;
  final bool showVoiceButton;

  const _AlphabetAnchorImage({
    required this.imageAsset,
    required this.icon,
    required this.word,
    required this.meaning,
    required this.voiceMessage,
    this.compact = false,
    this.height,
    this.showVoiceButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? (compact ? 236 : 352),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: imageAsset == null
                ? _AlphabetIconArt(icon: icon)
                : Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => _AlphabetIconArt(icon: icon),
                  ),
          ),
          if (showVoiceButton) ...[
            const SizedBox(height: 8),
            TudloVoiceButton(
              message: voiceMessage,
              tooltip: 'Pamatii ang tingog',
              size: compact ? 60 : 70,
              hiligaynon: true,
              backgroundColor: Colors.white,
              foregroundColor: TudloColors.green,
            ),
          ],
        ],
      ),
    );
  }
}

class _AlphabetIconArt extends StatelessWidget {
  final IconData icon;

  const _AlphabetIconArt({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: TudloColors.forest, size: 74));
  }
}

class _GradeOneFamilyLesson extends StatefulWidget {
  final LevelContent content;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneFamilyLesson({
    required this.content,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneFamilyLesson> createState() => _GradeOneFamilyLessonState();
}

class _GradeOneFamilyLessonState extends State<_GradeOneFamilyLesson> {
  int _stepIndex = 0;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _familyWordsFor(widget.content.lessonNumber);
    var maxIndex = 0;
    final quizTargets = words.take(math.min(3, words.length)).toList();
    final nanay = words.firstWhere(
      (word) => word.hil == 'nanay',
      orElse: () => quizTargets.first,
    );
    final reviewTargets = quizTargets.take(2).toList();
    final useVisitorQuiz = widget.content.lessonNumber == 2;
    final usePhotoQuiz = widget.content.lessonNumber == 3;
    final quizCards = [
      _UnitOneTapChoiceActivity(
        key: ValueKey('family-warm-n-${widget.content.id}'),
        prompt: 'Tap the letter of nanay!',
        progress: 1 / _lessonQuizCount,
        choices: _shuffledChoices(const ['N', 'A', 'T']),
        answer: 'N',
        isLetter: true,
        imageAsset: nanay.imageAsset,
        icon: nanay.icon,
        onAttempt: (correct) => widget.onQuizAttempt(0, correct),
        onDone: () {
          widget.onQuizCorrect(0);
          _advanceAfterCorrect(maxIndex);
        },
      ),
      if (usePhotoQuiz)
        _FamilyPhotoQuizActivity(
          key: ValueKey('family-photo-${widget.content.id}'),
          progress: 2 / _lessonQuizCount,
          members: _familyPhotoTargets(words),
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onCorrect: () {
            widget.onQuizCorrect(1);
            _advanceAfterCorrect(maxIndex);
          },
        )
      else if (useVisitorQuiz)
        _FamilyVisitorDoorQuizActivity(
          key: ValueKey('family-visitors-${widget.content.id}'),
          progress: 2 / _lessonQuizCount,
          visitors: _familyVisitorTargets(words),
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onCorrect: () {
            widget.onQuizCorrect(1);
            _advanceAfterCorrect(maxIndex);
          },
        )
      else
        _FamilyHouseWindowQuizActivity(
          key: ValueKey('family-house-${widget.content.id}'),
          progress: 2 / _lessonQuizCount,
          members: _familyHouseTargets(words),
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onCorrect: () {
            widget.onQuizCorrect(1);
            _advanceAfterCorrect(maxIndex);
          },
        ),
      for (var index = 0; index < reviewTargets.length; index++)
        _FamilyQuizCard(
          key: ValueKey(
            'family-quiz-${widget.content.id}-${reviewTargets[index].hil}',
          ),
          target: reviewTargets[index],
          choices: _familyChoicesFor(reviewTargets[index], words, 3),
          onAttempt: (correct) => widget.onQuizAttempt(index + 2, correct),
          onCorrect: () {
            widget.onQuizCorrect(index + 2);
            _advanceAfterCorrect(maxIndex);
          },
        ),
    ];

    final steps = [
      _AlphabetFadeStep(
        child: _FamilyExploreCard(
          key: ValueKey('family-explore-${widget.content.id}'),
          words: quizTargets,
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      for (var index = 0; index < words.length; index++)
        _AlphabetFadeStep(
          child: _FamilyWordLessonCard(
            key: ValueKey(
              'family-lesson-${widget.content.id}-${words[index].hil}',
            ),
            word: words[index],
            canGoBack: index > 0,
            onBack: () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizCards) _AlphabetFadeStep(child: card),
      _AlphabetFadeStep(
        child: _FamilyMatchingCard(
          key: ValueKey('family-match-${widget.content.id}'),
          words: quizTargets,
          onAttempt: (word, correct) {
            widget.onQuizAttempt(4, correct);
          },
          onCorrect: () {
            widget.onQuizCorrect(4);
          },
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
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
                  key: ValueKey('family-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FamilyWord {
  final String hil;
  final String eng;
  final String imageAsset;
  final IconData icon;

  const _FamilyWord({
    required this.hil,
    required this.eng,
    required this.imageAsset,
    required this.icon,
  });
}

class _FamilyExploreCard extends StatefulWidget {
  final List<_FamilyWord> words;
  final VoidCallback onDone;

  const _FamilyExploreCard({
    super.key,
    required this.words,
    required this.onDone,
  });

  @override
  State<_FamilyExploreCard> createState() => _FamilyExploreCardState();
}

class _FamilyExploreCardState extends State<_FamilyExploreCard> {
  final Set<String> _tapped = {};
  String _message = 'Koka: Tan-awa ang pamilya. Pindoton sila.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Tan-awa ang pamilya. Pindoton sila.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapWord(_FamilyWord word) async {
    if (_reported) return;
    setState(() {
      _tapped.add(word.hil);
      _message = 'Koka: ${_titleCase(word.hil)}... ${_titleCase(word.eng)}.';
    });
    await TudloVoiceButton.speak(
      context,
      '${word.hil}... ${word.eng}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_tapped.length >= widget.words.length && !_reported) {
      _reported = true;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _message,
      child: SizedBox(
        height: 520,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Opacity(
                opacity: .42,
                child: Image.asset(
                  'assets/images/level_game/house.png',
                  width: 330,
                  height: 240,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.home_rounded,
                    color: TudloColors.forest.withValues(alpha: .32),
                    size: 160,
                  ),
                ),
              ),
            ),
            for (var index = 0; index < widget.words.length; index++)
              Positioned(
                left: _familyExploreOffset(index, widget.words.length).dx,
                top: _familyExploreOffset(index, widget.words.length).dy,
                child: _FamilyExplorePerson(
                  word: widget.words[index],
                  tapped: _tapped.contains(widget.words[index].hil),
                  onTap: () => _tapWord(widget.words[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _familyExploreOffset(int index, int count) {
    if (count <= 2) {
      return index == 0 ? const Offset(42, 210) : const Offset(198, 210);
    }
    return switch (index) {
      0 => const Offset(6, 210),
      1 => const Offset(128, 190),
      _ => const Offset(250, 214),
    };
  }
}

class _FamilyExplorePerson extends StatelessWidget {
  final _FamilyWord word;
  final bool tapped;
  final VoidCallback onTap;

  const _FamilyExplorePerson({
    required this.word,
    required this.tapped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 126,
        height: 218,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: tapped
                  ? Container(
                      key: ValueKey('name-${word.hil}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: TudloColors.green, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: TudloColors.forest.withValues(alpha: .16),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        _titleCase(word.hil),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 19,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty-name'), height: 41),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: tapped ? 1.08 : 1,
              child: Container(
                width: 126,
                height: 169,
                decoration: BoxDecoration(
                  boxShadow: tapped
                      ? [
                          BoxShadow(
                            color: TudloColors.green.withValues(alpha: .36),
                            blurRadius: 28,
                            spreadRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Image.asset(
                  word.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(word.icon, color: TudloColors.forest, size: 96),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeOneHelperLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneHelperLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneHelperLesson> createState() => _GradeOneHelperLessonState();
}

class _GradeOneHelperLessonState extends State<_GradeOneHelperLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpers = _helpersForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final allHelpers = _helpersForLesson(4);
    final helperByHil = {for (final helper in allHelpers) helper.hil: helper};
    final quizCards = _helperQuizCardsForLesson(
      lessonNumber: widget.content.lessonNumber,
      helpers: helpers,
      helperByHil: helperByHil,
      onQuizDone: (index) {
        widget.onQuizCorrect(index);
        _advanceAfterCorrect(maxIndex);
      },
      onLessonDone: _markComplete,
    );
    final steps = [
      for (final helper in helpers) ...[
        _AlphabetFadeStep(
          child: _HelperTapCard(
            key: ValueKey('helper-tap-${widget.content.id}-${helper.hil}'),
            helper: helper,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _HelperWorkplaceDragCard(
            key: ValueKey('helper-work-${widget.content.id}-${helper.hil}'),
            helper: helper,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _HelperToolDragCard(
            key: ValueKey('helper-tool-${widget.content.id}-${helper.hil}'),
            helper: helper,
            choices: _toolChoicesFor(helper, helpers),
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizCards) _AlphabetFadeStep(child: card),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
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
                  key: ValueKey('helper-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HelperWord {
  final String hil;
  final String eng;
  final String tapSpeech;
  final String workplaceLabel;
  final String workplaceSpeech;
  final String imageAsset;
  final String? workplaceAsset;
  final _HelperTool tool;
  final IconData icon;
  final IconData workplaceIcon;
  final Color color;

  const _HelperWord({
    required this.hil,
    required this.eng,
    required this.tapSpeech,
    required this.workplaceLabel,
    required this.workplaceSpeech,
    required this.imageAsset,
    required this.tool,
    required this.icon,
    required this.workplaceIcon,
    required this.color,
    this.workplaceAsset,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get workplaceInstruction =>
      'Guyoda ang $hil pakadto sa $workplaceLabel.';
  String get retryWorkplace =>
      'Liwata. Guyoda ang $hil pakadto sa $workplaceLabel.';
  String get toolInstruction => 'Guyoda ang gamit pakadto sa $hil.';
  String get toolSuccess => 'Husto! Ang $hil nagagamit sang ${tool.hil}.';
}

class _HelperTool {
  final String hil;
  final IconData icon;
  final Color color;
  final String? imageAsset;

  const _HelperTool({
    required this.hil,
    required this.icon,
    required this.color,
    this.imageAsset,
  });
}

class _HelperTapCard extends StatefulWidget {
  final _HelperWord helper;
  final VoidCallback onDone;

  const _HelperTapCard({super.key, required this.helper, required this.onDone});

  @override
  State<_HelperTapCard> createState() => _HelperTapCardState();
}

class _HelperTapCardState extends State<_HelperTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.helper.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapHelper() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.helper.tool.hil}! ${widget.helper.tapSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? widget.helper.tapSpeech
          : 'Koka: ${widget.helper.tapInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 36 : 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _tapHelper,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (_tapped)
                    Positioned(
                      right: -16,
                      top: 16,
                      child: _ToolArt(tool: widget.helper.tool, size: 92),
                    ),
                  _HelperArt(helper: widget.helper, size: 330),
                  if (_tapped) const _AnimalSparkles(size: 370),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelperWorkplaceDragCard extends StatefulWidget {
  final _HelperWord helper;
  final VoidCallback onDone;

  const _HelperWorkplaceDragCard({
    super.key,
    required this.helper,
    required this.onDone,
  });

  @override
  State<_HelperWorkplaceDragCard> createState() =>
      _HelperWorkplaceDragCardState();
}

class _HelperWorkplaceDragCardState extends State<_HelperWorkplaceDragCard> {
  bool _placed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.helper.workplaceInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_placed) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        widget.helper.retryWorkplace,
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _accept() async {
    if (_placed) return;
    setState(() => _placed = true);
    await TudloVoiceButton.speak(
      context,
      widget.helper.workplaceSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _placed
          ? 'Koka: ${widget.helper.workplaceSpeech}'
          : _retrying
          ? 'Koka: ${widget.helper.retryWorkplace}'
          : 'Koka: ${widget.helper.workplaceInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 445,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -8,
                  top: 18,
                  child: _HelperWorkplaceTarget(
                    helper: widget.helper,
                    size: 260,
                    placed: _placed,
                    onAccept: _accept,
                    onWrongDrop: _retry,
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: 18,
                  child: _placed
                      ? const SizedBox(width: 238, height: 238)
                      : _HelperDraggable(
                          helper: widget.helper,
                          size: 238,
                          onMissed: _retry,
                        ),
                ),
                if (_placed)
                  Positioned(
                    right: 50,
                    top: 104,
                    child: _AnimalBounce(
                      active: true,
                      child: _HelperArt(helper: widget.helper, size: 144),
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

class _HelperToolDragCard extends StatefulWidget {
  final _HelperWord helper;
  final List<_HelperTool> choices;
  final VoidCallback onDone;

  const _HelperToolDragCard({
    super.key,
    required this.helper,
    required this.choices,
    required this.onDone,
  });

  @override
  State<_HelperToolDragCard> createState() => _HelperToolDragCardState();
}

class _HelperToolDragCardState extends State<_HelperToolDragCard> {
  bool _matched = false;
  bool _retrying = false;

  void _retry() {
    if (_matched) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Liwata. Guyoda ang sakto nga gamit pakadto sa ${widget.helper.hil}.',
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _acceptTool(_HelperTool tool) async {
    if (_matched) return;
    if (tool.hil != widget.helper.tool.hil) {
      _retry();
      return;
    }
    setState(() => _matched = true);
    await TudloVoiceButton.speak(
      context,
      widget.helper.toolSuccess,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _matched
          ? 'Koka: ${widget.helper.toolSuccess}'
          : _retrying
          ? 'Koka: Liwata. Pangitaa ang sakto nga gamit.'
          : 'Koka: ${widget.helper.toolInstruction}',
      child: Column(
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          DragTarget<_HelperTool>(
            onWillAcceptWithDetails: (_) => !_matched,
            onAcceptWithDetails: (details) => _acceptTool(details.data),
            builder: (context, candidates, rejected) {
              return SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _HelperArt(helper: widget.helper, size: 236),
                    if (candidates.isNotEmpty || _matched)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: TudloColors.green.withValues(alpha: .32),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_matched)
                      Positioned(
                        right: 6,
                        bottom: 0,
                        child: _ToolArt(tool: widget.helper.tool, size: 88),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final tool in widget.choices)
                _matched && tool.hil == widget.helper.tool.hil
                    ? const SizedBox(width: 102, height: 102)
                    : _ToolDraggable(tool: tool, size: 102, onMissed: _retry),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelperReviewCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final VoidCallback onDone;

  const _HelperReviewCard({required this.helpers, required this.onDone});

  @override
  State<_HelperReviewCard> createState() => _HelperReviewCardState();
}

class _HelperReviewCardState extends State<_HelperReviewCard> {
  final Set<String> _matched = {};
  String _message =
      'Koka: Guyoda ang kada community helper pakadto sa ila ginatrabahuan.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang kada community helper pakadto sa ila ginatrabahuan.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleDrop(_HelperWord target, _HelperWord dragged) async {
    if (_reported || _matched.contains(dragged.hil)) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;

    if (target.hil != dragged.hil) {
      setState(() {
        _message =
            'Koka: Liwata. Pangitaa ang ginatrabahuan sang ${dragged.hil}.';
      });
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pangitaa ang ginatrabahuan sang ${dragged.hil}.',
        hiligaynon: true,
      );
      return;
    }
    setState(() {
      _matched.add(dragged.hil);
      _message = 'Koka: Husto! ${_titleCase(dragged.hil)}.';
    });
    await TudloVoiceButton.speak(
      context,
      dragged.workplaceSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_matched.length == widget.helpers.length && !_reported) {
      _reported = true;
      setState(() {
        _message =
            'Koka: Maayo gid! Kabalo ka na sang mga community helpers kag ila ginahimo!';
      });
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Kabalo ka na sang mga community helpers kag ila ginahimo!',
        hiligaynon: true,
      );
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _message,
      child: Column(
        children: [
          Text(
            'Ipares ang Trabaho',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final itemCount = widget.helpers.length;
              final gap = itemCount > 2 ? 8.0 : 16.0;
              final itemSize = itemCount == 0
                  ? 0.0
                  : math
                        .min(
                          126.0,
                          (constraints.maxWidth - gap * (itemCount - 1)) /
                              itemCount,
                        )
                        .clamp(0.0, 126.0)
                        .toDouble();
              final dragSize = math.min(126.0, itemSize);

              return Column(
                children: [
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final helper in widget.helpers)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _HelperReviewWorkplace(
                            helper: helper,
                            size: itemSize,
                            matched: _matched.contains(helper.hil),
                            onDrop: (dragged) => _handleDrop(helper, dragged),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final helper in widget.helpers)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _matched.contains(helper.hil)
                              ? SizedBox.square(dimension: dragSize)
                              : _HelperDraggable(
                                  helper: helper,
                                  size: dragSize,
                                  onMissed: () {
                                    setState(() {
                                      _message =
                                          'Koka: Guyoda ang ${helper.hil} pakadto sa iya ginatrabahuan.';
                                    });
                                  },
                                ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoryTapItem {
  final String id;
  final String label;
  final String imageAsset;
  final IconData icon;
  final Color color;
  final String instruction;
  final String successSpeech;

  const _StoryTapItem({
    required this.id,
    required this.label,
    required this.imageAsset,
    required this.icon,
    required this.color,
    required this.instruction,
    required this.successSpeech,
  });
}

List<Widget> _helperQuizCardsForLesson({
  required int lessonNumber,
  required List<_HelperWord> helpers,
  required Map<String, _HelperWord> helperByHil,
  required ValueChanged<int> onQuizDone,
  required VoidCallback onLessonDone,
}) {
  final teacher = helperByHil['manunudlo']!;
  final doctor = helperByHil['doktor']!;
  final nurse = helperByHil['nars']!;
  final police = helperByHil['pulis']!;
  final firefighter = helperByHil['bumbero']!;
  final vendor = helperByHil['tindera']!;
  final farmer = helperByHil['mangunguma']!;
  final fisher = helperByHil['mangingisda']!;

  switch (lessonNumber) {
    case 1:
      return [
        _HelperStoryTapQuizCard(
          key: const ValueKey('helper-story-sick-younger-sibling'),
          title: 'Nagmasakit ang manghod ni Koka!',
          progress: 1 / _lessonQuizCount,
          items: [
            _familyStoryItem(
              id: 'manghod',
              label: 'Manghod',
              imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
              icon: Icons.child_friendly_rounded,
              instruction: 'Ipindot ang manghod ni Koka.',
              successSpeech: 'Husto. Ara ang manghod ni Koka.',
            ),
            _helperStoryItem(
              doctor,
              instruction: 'Ipindot ang doktor para usisaon siya.',
              successSpeech: 'Husto. Gin-usisa siya sang doktor.',
            ),
            _helperStoryItem(
              nurse,
              instruction: 'Ipindot ang nars para sa bulong.',
              successSpeech: 'Husto. Ang nars naghatag sang bulong.',
            ),
            _helperStoryItem(
              teacher,
              instruction:
                  'Balik sa eskwelahan. Ipindot ang manunudlo nga nag-abot sa iya.',
              successSpeech:
                  'Husto. Ginbaton siya liwat sang manunudlo sa eskwelahan.',
            ),
          ],
          onDone: () {
            onQuizDone(0);
            onLessonDone();
          },
        ),
      ];
    case 2:
      return [
        _HelperStoryTapQuizCard(
          key: const ValueKey('helper-story-market-fire'),
          title: 'May kalayo sa tinda!',
          progress: 1 / _lessonQuizCount,
          showGentleFire: true,
          items: [
            _helperStoryItem(
              firefighter,
              instruction: 'Ipindot ang bumbero para mapatay ang kalayo.',
              successSpeech: 'Husto. Ginpatay sang bumbero ang kalayo.',
            ),
            _helperStoryItem(
              police,
              instruction: 'Ipindot ang pulis para magiya sang mga tawo.',
              successSpeech: 'Husto. Ginbuligan sang pulis ang mga tawo.',
            ),
            _helperStoryItem(
              vendor,
              instruction: 'Ipindot ang tindera para buksan liwat ang tinda.',
              successSpeech: 'Husto. Bukas na liwat ang tinda.',
            ),
            _helperStoryItem(
              teacher,
              instruction:
                  'Ipindot ang manunudlo para magsiling sang salamat ang klase.',
              successSpeech:
                  'Husto. Nagsiling ang klase, salamat sa mga helpers!',
            ),
          ],
          onDone: () => onQuizDone(0),
        ),
        _HelperToolSequenceQuizCard(
          key: const ValueKey('helper-tool-emergency-review'),
          progress: 2 / _lessonQuizCount,
          targets: [firefighter, police, vendor],
          onDone: () {
            onQuizDone(1);
            onLessonDone();
          },
        ),
      ];
    case 3:
      return [
        _HelperStoryTapQuizCard(
          key: const ValueKey('helper-story-food-chain'),
          title: 'Diin naghalin ang pagkaon ni Koka?',
          progress: 1 / _lessonQuizCount,
          items: [
            _helperStoryItem(
              farmer,
              instruction: 'Ipindot ang mangunguma. Halin sa iya ang humay.',
              successSpeech: 'Husto. Ang mangunguma nagatanom sang humay.',
            ),
            _helperStoryItem(
              fisher,
              instruction: 'Ipindot ang mangingisda. Halin sa iya ang isda.',
              successSpeech: 'Husto. Ang mangingisda nagakuha sang isda.',
            ),
            _helperStoryItem(
              vendor,
              instruction: 'Ipindot ang tindera. Ginabaligya niya ini.',
              successSpeech: 'Husto. Ang tindera nagabaligya sang pagkaon.',
            ),
            _familyStoryItem(
              id: 'nanay',
              label: 'Nanay',
              imageAsset: 'assets/images/level_game/people/nanay.png',
              icon: Icons.face_3_rounded,
              instruction:
                  'Ipindot si nanay. Siya nagaluto kag nagakaon ang pamilya.',
              successSpeech: 'Husto. Nagluto si nanay para sa pamilya.',
            ),
          ],
          onDone: () {
            onQuizDone(0);
            onLessonDone();
          },
        ),
      ];
    default:
      return [
        _HelperFastReviewQuizCard(
          key: const ValueKey('helper-fast-review'),
          helpers: _shuffledChoices(helperByHil.values).take(8).toList(),
          progress: 1 / _lessonQuizCount,
          onDone: () => onQuizDone(0),
        ),
        _HelperParadeQuizCard(
          key: const ValueKey('helper-thank-you-parade'),
          helpers: _shuffledChoices(helperByHil.values).take(8).toList(),
          progress: 1,
          onDone: () {
            onQuizDone(1);
            onLessonDone();
          },
        ),
      ];
  }
}

_StoryTapItem _helperStoryItem(
  _HelperWord helper, {
  required String instruction,
  required String successSpeech,
}) {
  return _StoryTapItem(
    id: helper.hil,
    label: _titleCase(helper.hil),
    imageAsset: helper.imageAsset,
    icon: helper.icon,
    color: helper.color,
    instruction: instruction,
    successSpeech: successSpeech,
  );
}

_StoryTapItem _familyStoryItem({
  required String id,
  required String label,
  required String imageAsset,
  required IconData icon,
  required String instruction,
  required String successSpeech,
}) {
  return _StoryTapItem(
    id: id,
    label: label,
    imageAsset: imageAsset,
    icon: icon,
    color: TudloColors.green,
    instruction: instruction,
    successSpeech: successSpeech,
  );
}

class _HelperStoryTapQuizCard extends StatefulWidget {
  final String title;
  final double progress;
  final List<_StoryTapItem> items;
  final bool showGentleFire;
  final VoidCallback onDone;

  const _HelperStoryTapQuizCard({
    super.key,
    required this.title,
    required this.progress,
    required this.items,
    required this.onDone,
    this.showGentleFire = false,
  });

  @override
  State<_HelperStoryTapQuizCard> createState() =>
      _HelperStoryTapQuizCardState();
}

class _HelperStoryTapQuizCardState extends State<_HelperStoryTapQuizCard> {
  final Set<String> _doneIds = {};
  int _targetIndex = 0;
  String? _wrongId;
  bool _completed = false;
  int _feedbackKey = 0;

  _StoryTapItem get _target =>
      widget.items[_targetIndex.clamp(0, math.max(0, widget.items.length - 1))];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.items.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _target.instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _tapItem(_StoryTapItem item) async {
    if (_completed || _doneIds.contains(item.id)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }

    final correct = item.id == _target.id;
    setState(() {
      _feedbackKey++;
      _wrongId = correct ? null : item.id;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. ${_target.instruction}',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_completed) setState(() => _wrongId = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _doneIds.add(item.id);
      if (_doneIds.length >= widget.items.length) {
        _completed = true;
      } else {
        _targetIndex++;
      }
    });
    await TudloVoiceButton.speak(
      context,
      item.successSpeech,
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_completed) {
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Natapos ang estorya.',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (mounted) widget.onDone();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _target.instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _completed ? 'Maayo gid!' : _target.instruction,
      progress: widget.progress,
      mascotMessage: _completed
          ? 'Koka: Husto tanan!'
          : 'Koka: ${widget.title}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemSize = (width * .30).clamp(86.0, 118.0);
          return Column(
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: (width * .065).clamp(22.0, 31.0),
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFF459B27), offset: Offset(2, 2)),
                  ],
                ),
              ),
              if (widget.showGentleFire) ...[
                const SizedBox(height: 6),
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: TudloColors.orange,
                  size: 46,
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item in widget.items)
                        _StoryTapTarget(
                          item: item,
                          size: itemSize,
                          done: _doneIds.contains(item.id),
                          wrong: _wrongId == item.id,
                          feedbackKey: _feedbackKey,
                          onTap: () => _tapItem(item),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryTapTarget extends StatelessWidget {
  final _StoryTapItem item;
  final double size;
  final bool done;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback onTap;

  const _StoryTapTarget({
    required this.item,
    required this.size,
    required this.done,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('story-${item.id}-$feedbackKey-$wrong'),
      correct: done,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size + 30,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: done
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(22),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .24),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(item.icon, color: item.color, size: size * .58),
                ),
              ),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFF459B27), offset: Offset(1.5, 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelperToolSequenceQuizCard extends StatefulWidget {
  final double progress;
  final List<_HelperWord> targets;
  final VoidCallback onDone;

  const _HelperToolSequenceQuizCard({
    super.key,
    required this.progress,
    required this.targets,
    required this.onDone,
  });

  @override
  State<_HelperToolSequenceQuizCard> createState() =>
      _HelperToolSequenceQuizCardState();
}

class _HelperToolSequenceQuizCardState
    extends State<_HelperToolSequenceQuizCard> {
  final Set<String> _matched = {};
  int _targetIndex = 0;
  _HelperTool? _wrongTool;
  bool _completed = false;

  _HelperWord get _target =>
      widget.targets[_targetIndex.clamp(
        0,
        math.max(0, widget.targets.length - 1),
      )];

  String get _instruction {
    if (_target.hil == 'pulis') {
      return 'Police officer. Pulis. Guyoda ang badge pakadto sa pulis.';
    }
    return 'Guyoda ang ${_target.tool.hil} pakadto sa ${_target.hil}.';
  }

  List<_HelperTool> get _tools =>
      _shuffledChoices(widget.targets.map((helper) => helper.tool));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.targets.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _acceptTool(_HelperTool tool, _HelperWord helper) async {
    if (_completed || _matched.contains(helper.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = helper.hil == _target.hil && tool.hil == helper.tool.hil;
    if (!correct) {
      setState(() => _wrongTool = tool);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_completed) setState(() => _wrongTool = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _matched.add(helper.hil);
      if (_matched.length >= widget.targets.length) {
        _completed = true;
      } else {
        _targetIndex++;
      }
    });
    await TudloVoiceButton.speak(
      context,
      helper.toolSuccess,
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_completed) {
      widget.onDone();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _instruction,
      progress: widget.progress,
      mascotMessage: 'Koka: Pamatia kag guyoda ang gamit.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final helperSize = (width * .26).clamp(76.0, 104.0);
          return Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final helper in widget.targets)
                      DragTarget<_HelperTool>(
                        onWillAcceptWithDetails: (_) =>
                            !_matched.contains(helper.hil),
                        onAcceptWithDetails: (details) =>
                            _acceptTool(details.data, helper),
                        builder: (context, candidates, rejected) {
                          return AnimatedScale(
                            duration: const Duration(milliseconds: 140),
                            scale: candidates.isNotEmpty ? 1.07 : 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HelperArt(helper: helper, size: helperSize),
                                const SizedBox(height: 4),
                                if (_matched.contains(helper.hil))
                                  _ToolArt(tool: helper.tool, size: 42),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (final tool in _tools)
                    if (!_matched.any(
                      (hil) =>
                          widget.targets
                              .firstWhere((helper) => helper.hil == hil)
                              .tool
                              .hil ==
                          tool.hil,
                    ))
                      _FeedbackMotion(
                        key: ValueKey(
                          'tool-seq-${tool.hil}-${_wrongTool == tool}',
                        ),
                        correct: false,
                        wrong: _wrongTool == tool,
                        child: _ToolDraggable(
                          tool: tool,
                          size: 86,
                          onMissed: () => unawaited(
                            TudloVoiceButton.speak(
                              context,
                              _instruction,
                              hiligaynon: true,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelperFastReviewQuizCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final double progress;
  final VoidCallback onDone;

  const _HelperFastReviewQuizCard({
    super.key,
    required this.helpers,
    required this.progress,
    required this.onDone,
  });

  @override
  State<_HelperFastReviewQuizCard> createState() =>
      _HelperFastReviewQuizCardState();
}

class _HelperFastReviewQuizCardState extends State<_HelperFastReviewQuizCard> {
  late final List<_HelperWord> _trials = [
    ..._shuffledChoices(widget.helpers),
    ..._shuffledChoices(widget.helpers),
  ].take(10).toList();
  int _index = 0;
  String? _wrongHil;
  bool _completed = false;
  int _feedbackKey = 0;

  _HelperWord get _target =>
      _trials[_index.clamp(0, math.max(0, _trials.length - 1))];

  String get _instruction => _index.isEven
      ? 'Ipindot ang ${_target.hil}.'
      : 'Ipindot ang helper nga may ${_target.tool.hil}.';

  List<_HelperWord> get _choices {
    final choices = <_HelperWord>[_target];
    for (final helper in _shuffledChoices(widget.helpers)) {
      if (choices.length >= 3) break;
      if (!choices.any((choice) => choice.hil == helper.hil)) {
        choices.add(helper);
      }
    }
    return _shuffledChoices(choices);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _trials.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _tapChoice(_HelperWord helper) async {
    if (_completed) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = helper.hil == _target.hil;
    setState(() {
      _feedbackKey++;
      _wrongHil = correct ? null : helper.hil;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_completed) setState(() => _wrongHil = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    if (_index >= _trials.length - 1) {
      setState(() => _completed = true);
      widget.onDone();
      return;
    }
    setState(() => _index++);
    unawaited(TudloVoiceButton.speak(context, _instruction, hiligaynon: true));
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _instruction,
      progress: widget.progress,
      mascotMessage: 'Koka: Dali nga pagtilaw!',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final choices = _choices;
          return Column(
            children: [
              Text(
                '${_index + 1} / ${_trials.length}',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFF459B27), offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_index.isOdd)
                _ToolArt(tool: _target.tool, size: 96)
              else
                Text(
                  _titleCase(_target.hil),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0xFF459B27), offset: Offset(2, 2)),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final helper in choices)
                        _FeedbackMotion(
                          key: ValueKey(
                            'fast-${helper.hil}-$_feedbackKey-${_wrongHil == helper.hil}',
                          ),
                          correct: false,
                          wrong: _wrongHil == helper.hil,
                          child: GestureDetector(
                            onTap: () => _tapChoice(helper),
                            child: _HelperArt(
                              helper: helper,
                              size: (width * .27).clamp(86.0, 116.0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelperParadeQuizCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final double progress;
  final VoidCallback onDone;

  const _HelperParadeQuizCard({
    super.key,
    required this.helpers,
    required this.progress,
    required this.onDone,
  });

  @override
  State<_HelperParadeQuizCard> createState() => _HelperParadeQuizCardState();
}

class _HelperParadeQuizCardState extends State<_HelperParadeQuizCard> {
  final Set<String> _joined = {};
  int _targetIndex = 0;
  String? _wrongHil;
  bool _completed = false;
  int _feedbackKey = 0;

  _HelperWord get _target =>
      widget.helpers[_targetIndex.clamp(
        0,
        math.max(0, widget.helpers.length - 1),
      )];

  String get _instruction =>
      'Salamat parade! Ipindot ang ${_target.hil} para magsulod sa linya.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.helpers.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _tapHelper(_HelperWord helper) async {
    if (_completed || _joined.contains(helper.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = helper.hil == _target.hil;
    setState(() {
      _feedbackKey++;
      _wrongHil = correct ? null : helper.hil;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_completed) setState(() => _wrongHil = null);
      });
      return;
    }
    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _joined.add(helper.hil);
      if (_joined.length >= widget.helpers.length) {
        _completed = true;
      } else {
        _targetIndex++;
      }
    });
    if (_completed) {
      await TudloVoiceButton.speak(
        context,
        'Salamat sa tanan nga helpers!',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (mounted) widget.onDone();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _instruction,
      progress: widget.progress,
      mascotMessage: 'Koka: Tawga ang kada helper sa parade.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemSize = (width * .21).clamp(64.0, 86.0);
          return Column(
            children: [
              SizedBox(
                height: 98,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final helper in widget.helpers)
                      if (_joined.contains(helper.hil))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _HelperArt(helper: helper, size: 46),
                        ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final helper in widget.helpers)
                        if (!_joined.contains(helper.hil))
                          _FeedbackMotion(
                            key: ValueKey(
                              'parade-${helper.hil}-$_feedbackKey-${_wrongHil == helper.hil}',
                            ),
                            correct: false,
                            wrong: _wrongHil == helper.hil,
                            child: GestureDetector(
                              onTap: () => _tapHelper(helper),
                              child: _HelperArt(helper: helper, size: itemSize),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelperDraggable extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final VoidCallback onMissed;

  const _HelperDraggable({
    required this.helper,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_HelperWord>(
      data: helper,
      feedback: Material(
        color: Colors.transparent,
        child: _HelperArt(helper: helper, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _HelperArt(helper: helper, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _HelperArt(helper: helper, size: size),
    );
  }
}

class _ToolDraggable extends StatelessWidget {
  final _HelperTool tool;
  final double size;
  final VoidCallback onMissed;

  const _ToolDraggable({
    required this.tool,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_HelperTool>(
      data: tool,
      feedback: Material(
        color: Colors.transparent,
        child: _ToolArt(tool: tool, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _ToolArt(tool: tool, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _ToolArt(tool: tool, size: size),
    );
  }
}

class _HelperWorkplaceTarget extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool placed;
  final VoidCallback onAccept;
  final VoidCallback onWrongDrop;

  const _HelperWorkplaceTarget({
    required this.helper,
    required this.size,
    required this.placed,
    required this.onAccept,
    required this.onWrongDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_HelperWord>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) {
        if (details.data.hil == helper.hil) {
          onAccept();
        } else {
          onWrongDrop();
        }
      },
      builder: (context, candidates, rejected) {
        return _HelperWorkplaceArt(
          helper: helper,
          size: size,
          active: candidates.isNotEmpty,
          matched: placed,
        );
      },
    );
  }
}

class _HelperReviewWorkplace extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool matched;
  final ValueChanged<_HelperWord> onDrop;

  const _HelperReviewWorkplace({
    required this.helper,
    required this.size,
    required this.matched,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_HelperWord>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) {
        return _HelperWorkplaceArt(
          helper: helper,
          size: size,
          active: candidates.isNotEmpty,
          matched: matched,
        );
      },
    );
  }
}

class _HelperArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperArt({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      helper.imageAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _HelperIconArt(helper: helper, size: size),
    );
  }
}

class _HelperIconArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperIconArt({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: helper.color.withValues(alpha: .16),
      ),
      child: Icon(helper.icon, color: helper.color, size: size * .58),
    );
  }
}

class _HelperWorkplaceArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool active;
  final bool matched;

  const _HelperWorkplaceArt({
    required this.helper,
    required this.size,
    required this.active,
    required this.matched,
  });

  @override
  Widget build(BuildContext context) {
    final workplace = helper.workplaceAsset == null
        ? _HelperWorkplaceIcon(helper: helper, size: size)
        : Image.asset(
            helper.workplaceAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _HelperWorkplaceIcon(helper: helper, size: size),
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        boxShadow: active || matched
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .24),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Center(child: workplace),
    );
  }
}

class _HelperWorkplaceIcon extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperWorkplaceIcon({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * .88,
      height: size * .88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TudloColors.softGreen.withValues(alpha: .82),
      ),
      child: Icon(
        helper.workplaceIcon,
        color: TudloColors.forest,
        size: size * .48,
      ),
    );
  }
}

class _ToolArt extends StatelessWidget {
  final _HelperTool tool;
  final double size;

  const _ToolArt({required this.tool, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tool.color.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: tool.color.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: tool.imageAsset == null
          ? Icon(tool.icon, color: tool.color, size: size * .54)
          : Padding(
              padding: EdgeInsets.all(size * .1),
              child: Image.asset(
                tool.imageAsset!,
                width: size * .8,
                height: size * .8,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    Icon(tool.icon, color: tool.color, size: size * .54),
              ),
            ),
    );
  }
}

List<_HelperTool> _toolChoicesFor(
  _HelperWord target,
  List<_HelperWord> helpers,
) {
  final tools = <_HelperTool>[target.tool];
  for (final helper in helpers) {
    if (helper.tool.hil != target.tool.hil) tools.add(helper.tool);
    if (tools.length == 3) break;
  }
  if (tools.length < 3) {
    for (final helper in _helpersForLesson(4)) {
      if (tools.any((tool) => tool.hil == helper.tool.hil)) continue;
      tools.add(helper.tool);
      if (tools.length == 3) break;
    }
  }
  return tools;
}

List<_HelperWord> _helpersForLesson(int lessonNumber) {
  const teacherTool = _HelperTool(
    hil: 'libro',
    icon: Icons.menu_book_rounded,
    color: TudloColors.blue,
    imageAsset: 'assets/images/level_game/book.png',
  );
  const doctorTool = _HelperTool(
    hil: 'stethoscope',
    icon: Icons.health_and_safety_rounded,
    color: TudloColors.coral,
    imageAsset: 'assets/images/level_game/stetoscope.png',
  );
  const nurseTool = _HelperTool(
    hil: 'thermometer',
    icon: Icons.thermostat_rounded,
    color: TudloColors.orange,
    imageAsset: 'assets/images/level_game/thermometer.png',
  );
  const policeTool = _HelperTool(
    hil: 'whistle',
    icon: Icons.campaign_rounded,
    color: TudloColors.blue,
  );
  const firefighterTool = _HelperTool(
    hil: 'hos',
    icon: Icons.water_drop_rounded,
    color: TudloColors.coral,
  );
  const vendorTool = _HelperTool(
    hil: 'basket sang prutas',
    icon: Icons.shopping_basket_rounded,
    color: TudloColors.gold,
    imageAsset: 'assets/images/level_game/fruits.png',
  );
  const farmerTool = _HelperTool(
    hil: 'gamit pang-uma',
    icon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fisherTool = _HelperTool(
    hil: 'pukot',
    icon: Icons.phishing_rounded,
    color: TudloColors.blue,
  );

  const teacher = _HelperWord(
    hil: 'manunudlo',
    eng: 'manunudlo',
    tapSpeech: 'Manunudlo. Ang manunudlo nagatudlo sa mga bata.',
    workplaceLabel: 'eskwelahan',
    workplaceSpeech: 'Husto! Ang manunudlo nagatrabaho sa eskwelahan.',
    imageAsset: 'assets/images/level_game/people/manunudlo.png',
    workplaceAsset: 'assets/images/level_game/eskwelahan.png',
    tool: teacherTool,
    icon: Icons.school_rounded,
    workplaceIcon: Icons.school_rounded,
    color: TudloColors.blue,
  );
  const doctor = _HelperWord(
    hil: 'doktor',
    eng: 'doktor',
    tapSpeech: 'Doktor. Ang doktor nagabulig sa mga masakiton.',
    workplaceLabel: 'ospital',
    workplaceSpeech: 'Husto! Ang doktor nagatrabaho sa ospital.',
    imageAsset: 'assets/images/level_game/people/doktor.png',
    workplaceAsset: 'assets/images/level_game/ospital.png',
    tool: doctorTool,
    icon: Icons.medical_services_rounded,
    workplaceIcon: Icons.local_hospital_rounded,
    color: TudloColors.coral,
  );
  const nurse = _HelperWord(
    hil: 'nars',
    eng: 'nars',
    tapSpeech: 'Nars. Ang nars nagaatipan sa mga masakiton.',
    workplaceLabel: 'ospital',
    workplaceSpeech: 'Husto! Ang nars nagatrabaho sa ospital.',
    imageAsset: 'assets/images/level_game/people/nars.png',
    workplaceAsset: 'assets/images/level_game/nursing-station.png',
    tool: nurseTool,
    icon: Icons.medical_information_rounded,
    workplaceIcon: Icons.local_hospital_rounded,
    color: TudloColors.orange,
  );
  const police = _HelperWord(
    hil: 'pulis',
    eng: 'pulis',
    tapSpeech: 'Pulis. Ang pulis nagabantay sang katawhayan.',
    workplaceLabel: 'estasyon sang pulis',
    workplaceSpeech: 'Husto! Ang pulis nagatrabaho sa estasyon sang pulis.',
    imageAsset: 'assets/images/level_game/people/pulis.png',
    workplaceAsset: 'assets/images/level_game/estasyon-sang-pulis.png',
    tool: policeTool,
    icon: Icons.local_police_rounded,
    workplaceIcon: Icons.local_police_rounded,
    color: TudloColors.blue,
  );
  const firefighter = _HelperWord(
    hil: 'bumbero',
    eng: 'bumbero',
    tapSpeech: 'Bumbero. Ang bumbero nagapatay sang kalayo.',
    workplaceLabel: 'estasyon sang bumbero',
    workplaceSpeech: 'Husto! Ang bumbero nagatrabaho sa estasyon sang bumbero.',
    imageAsset: 'assets/images/level_game/people/bumbero.png',
    workplaceAsset: 'assets/images/level_game/estasyon-sang-bumbero.png',
    tool: firefighterTool,
    icon: Icons.local_fire_department_rounded,
    workplaceIcon: Icons.local_fire_department_rounded,
    color: TudloColors.coral,
  );
  const vendor = _HelperWord(
    hil: 'tindera',
    eng: 'tindera',
    tapSpeech: 'Tindera. Ang tindera nagabaligya sang mga balaklon.',
    workplaceLabel: 'tinda',
    workplaceSpeech: 'Husto! Ang tindera nagatrabaho sa tinda.',
    imageAsset: 'assets/images/level_game/tindera.png',
    workplaceAsset: 'assets/images/level_game/tinda.png',
    tool: vendorTool,
    icon: Icons.storefront_rounded,
    workplaceIcon: Icons.storefront_rounded,
    color: TudloColors.gold,
  );
  const farmer = _HelperWord(
    hil: 'mangunguma',
    eng: 'mangunguma',
    tapSpeech: 'Mangunguma. Ang mangunguma nagatanom sang humay kag utan.',
    workplaceLabel: 'uma',
    workplaceSpeech: 'Husto! Ang mangunguma nagatrabaho sa uma.',
    imageAsset: 'assets/images/level_game/people/mangunguma.png',
    workplaceAsset: 'assets/images/level_game/uma.png',
    tool: farmerTool,
    icon: Icons.agriculture_rounded,
    workplaceIcon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fisher = _HelperWord(
    hil: 'mangingisda',
    eng: 'mangingisda',
    tapSpeech: 'Mangingisda. Ang mangingisda nagadakop sang isda.',
    workplaceLabel: 'baybay',
    workplaceSpeech: 'Husto! Ang mangingisda nagatrabaho sa baybay.',
    imageAsset: 'assets/images/level_game/people/mangingisda.png',
    workplaceAsset: 'assets/images/level_game/dagat.png',
    tool: fisherTool,
    icon: Icons.sailing_rounded,
    workplaceIcon: Icons.beach_access_rounded,
    color: TudloColors.blue,
  );

  return switch (lessonNumber) {
    1 => const [teacher, doctor, nurse],
    2 => const [police, firefighter, vendor],
    3 => const [farmer, fisher],
    _ => const [
      teacher,
      doctor,
      nurse,
      police,
      firefighter,
      vendor,
      farmer,
      fisher,
    ],
  };
}

class _GradeOnePlaceLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOnePlaceLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOnePlaceLesson> createState() => _GradeOnePlaceLessonState();
}

class _GradeOnePlaceLessonState extends State<_GradeOnePlaceLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _placesForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final reviewPlaces = _placeReviewTargetsFor(widget.content.lessonNumber);
    final steps = [
      _AlphabetFadeStep(
        child: _PlaceOpeningCard(onDone: () => _advanceAfterCorrect(maxIndex)),
      ),
      for (final place in places) ...[
        _AlphabetFadeStep(
          child: _PlaceTapCard(
            key: ValueKey('place-tap-${widget.content.id}-${place.hil}'),
            place: place,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _KokaTravelCard(
            key: ValueKey('place-travel-${widget.content.id}-${place.hil}'),
            place: place,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _PlaceMapGuideCard(
          key: ValueKey('place-guide-${widget.content.id}'),
          places: reviewPlaces,
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _PlaceSituationGameCard(
          key: ValueKey('place-situations-${widget.content.id}'),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
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
                  key: ValueKey('place-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceWord {
  final String hil;
  final String eng;
  final String asset;
  final IconData icon;
  final Color color;
  final String introSpeech;
  final String tapSpeech;
  final List<IconData> effects;

  const _PlaceWord({
    required this.hil,
    required this.eng,
    required this.asset,
    required this.icon,
    required this.color,
    required this.introSpeech,
    required this.tapSpeech,
    required this.effects,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get travelInstruction => 'Guyoda si Koka pakadto sa $hil.';
  String get arrivedSpeech => 'Husto! Ari na si Koka sa $hil.';
}

class _PlaceOpeningCard extends StatefulWidget {
  final VoidCallback onDone;

  const _PlaceOpeningCard({required this.onDone});

  @override
  State<_PlaceOpeningCard> createState() => _PlaceOpeningCardState();
}

class _PlaceOpeningCardState extends State<_PlaceOpeningCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Maglibot kita sa aton banwa!',
          hiligaynon: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: 'Koka: Maglibot kita sa aton banwa!',
      child: SizedBox(
        height: 510,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 38,
              child: Image.asset(
                'assets/images/level_game/road2.png',
                width: 350,
                height: 270,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned(top: 118, child: _LessonKokaMascot(size: 190)),
            Positioned(
              bottom: 46,
              child: SizedBox(
                width: 260,
                height: 70,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  child: const Text('Lakbay!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTapCard extends StatefulWidget {
  final _PlaceWord place;
  final VoidCallback onDone;

  const _PlaceTapCard({super.key, required this.place, required this.onDone});

  @override
  State<_PlaceTapCard> createState() => _PlaceTapCardState();
}

class _PlaceTapCardState extends State<_PlaceTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.place.introSpeech,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapPlace() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      widget.place.tapSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? 'Koka: ${widget.place.tapSpeech}'
          : 'Koka: ${widget.place.tapInstruction}',
      child: Column(
        children: [
          Text(
            widget.place.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.place.upperName.length > 9 ? 36 : 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _tapPlace,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _PlaceArt(place: widget.place, size: 330),
                  if (_tapped) ...[
                    const _AnimalSparkles(size: 360),
                    for (
                      var index = 0;
                      index < widget.place.effects.length;
                      index++
                    )
                      Positioned(
                        right: 16.0 + index * 34,
                        top: index.isEven ? 18 : 72,
                        child: Icon(
                          widget.place.effects[index],
                          color: widget.place.color,
                          size: 42,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KokaTravelCard extends StatefulWidget {
  final _PlaceWord place;
  final VoidCallback onDone;

  const _KokaTravelCard({super.key, required this.place, required this.onDone});

  @override
  State<_KokaTravelCard> createState() => _KokaTravelCardState();
}

class _KokaTravelCardState extends State<_KokaTravelCard> {
  bool _arrived = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.place.travelInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_arrived) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Liwata. ${widget.place.travelInstruction}',
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _arrive() async {
    if (_arrived) return;
    setState(() => _arrived = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.place.arrivedSpeech} Welcome!',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _arrived
          ? 'Koka: ${widget.place.arrivedSpeech}'
          : _retrying
          ? 'Koka: Liwata. ${widget.place.travelInstruction}'
          : 'Koka: ${widget.place.travelInstruction}',
      child: SizedBox(
        height: 530,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              right: 6,
              bottom: 88,
              child: Image.asset(
                'assets/images/level_game/road2.png',
                height: 170,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              right: 12,
              top: 18,
              child: DragTarget<String>(
                onWillAcceptWithDetails: (_) => !_arrived,
                onAcceptWithDetails: (_) => _arrive(),
                builder: (context, candidates, rejected) {
                  return _PlaceArt(
                    place: widget.place,
                    size: candidates.isNotEmpty || _arrived ? 246 : 232,
                    glow: candidates.isNotEmpty || _arrived,
                  );
                },
              ),
            ),
            Positioned(
              left: 22,
              bottom: 116,
              child: _arrived
                  ? const SizedBox(width: 132, height: 132)
                  : Draggable<String>(
                      data: widget.place.hil,
                      feedback: const Material(
                        color: Colors.transparent,
                        child: _LessonKokaMascot(size: 142),
                      ),
                      childWhenDragging: const Opacity(
                        opacity: .24,
                        child: _LessonKokaMascot(size: 132),
                      ),
                      onDragEnd: (details) {
                        if (!details.wasAccepted) _retry();
                      },
                      child: const _LessonKokaMascot(size: 132),
                    ),
            ),
            if (_arrived)
              Positioned(
                right: 62,
                top: 110,
                child: Column(
                  children: [
                    const _LessonKokaMascot(size: 104),
                    Text(
                      'Welcome!',
                      style: GoogleFonts.nunito(
                        color: TudloColors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
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

class _PlaceMapGuideCard extends StatefulWidget {
  final List<_PlaceWord> places;
  final VoidCallback onDone;

  const _PlaceMapGuideCard({
    super.key,
    required this.places,
    required this.onDone,
  });

  @override
  State<_PlaceMapGuideCard> createState() => _PlaceMapGuideCardState();
}

class _PlaceMapGuideCardState extends State<_PlaceMapGuideCard> {
  int _targetIndex = 0;
  String? _arrivedHil;
  bool _reported = false;

  _PlaceWord get _target => widget.places[_targetIndex];
  String get _targetPrompt => 'Buligi ako. Pindoton ang ${_target.hil}.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(context, _targetPrompt, hiligaynon: true),
      );
    });
  }

  Future<void> _tapPlace(_PlaceWord place) async {
    if (_reported) return;
    if (place.hil != _target.hil) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Buligi ako magkadto sa ${_target.hil}.',
        hiligaynon: true,
      );
      return;
    }
    setState(() => _arrivedHil = place.hil);
    await TudloVoiceButton.speak(
      context,
      'Husto! Ari na kita sa ${place.hil}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_targetIndex >= widget.places.length - 1) {
        _reported = true;
        widget.onDone();
      } else {
        setState(() {
          _targetIndex++;
          _arrivedHil = null;
        });
        unawaited(
          TudloVoiceButton.speak(context, _targetPrompt, hiligaynon: true),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: 'Koka: $_targetPrompt',
      child: Column(
        children: [
          Text(
            'Mapa sang Banwa',
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
          SizedBox(
            height: 448,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 22,
                  right: 22,
                  top: 58,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/level_game/road2.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Positioned(
                  left: 142,
                  bottom: 16,
                  child: _LessonKokaMascot(size: 78),
                ),
                for (var index = 0; index < widget.places.length; index++)
                  Positioned(
                    left: _mapOffset(index, widget.places.length).dx,
                    top: _mapOffset(index, widget.places.length).dy,
                    child: GestureDetector(
                      onTap: () => _tapPlace(widget.places[index]),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _PlaceArt(
                            place: widget.places[index],
                            size: 124,
                            glow: _arrivedHil == widget.places[index].hil,
                          ),
                          if (_arrivedHil == widget.places[index].hil)
                            const Positioned(
                              right: -10,
                              bottom: -8,
                              child: _LessonKokaMascot(size: 54),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _mapOffset(int index, int count) {
    final offsets = const [
      Offset(16, 58),
      Offset(238, 58),
      Offset(118, 208),
      Offset(24, 286),
      Offset(232, 286),
    ];
    return offsets[index % offsets.length];
  }
}

class _PlaceSituationGameCard extends StatefulWidget {
  final VoidCallback onDone;

  const _PlaceSituationGameCard({super.key, required this.onDone});

  @override
  State<_PlaceSituationGameCard> createState() =>
      _PlaceSituationGameCardState();
}

class _PlaceSituationGameCardState extends State<_PlaceSituationGameCard> {
  int _index = 0;
  String? _arrivedHil;
  bool _reported = false;
  late final List<List<String>> _choiceOrders;

  final List<_PlaceSituation> _situations = [
    _PlaceSituation(
      prompt: 'May bata nga masakit.',
      answerHil: 'ospital',
      choices: ['ospital', 'eskwelahan', 'uma'],
      imageAsset: 'assets/images/level_game/sick-kid.png',
      icon: Icons.sick_rounded,
    ),
    _PlaceSituation(
      prompt: 'Gutom ang karbaw.',
      answerHil: 'uma',
      choices: ['uma', 'baybay', 'ospital'],
      imageAsset: 'assets/images/level_game/animals/carabao.png',
      icon: Icons.agriculture_rounded,
    ),
    _PlaceSituation(
      prompt: 'Oras na magtuon.',
      answerHil: 'eskwelahan',
      choices: ['eskwelahan', 'baybay', 'tinda'],
      imageAsset: 'assets/images/level_game/book.png',
      icon: Icons.menu_book_rounded,
    ),
  ];

  _PlaceSituation get _current => _situations[_index];

  @override
  void initState() {
    super.initState();
    _choiceOrders = [
      for (final situation in _situations) _shuffledChoices(situation.choices),
    ];
  }

  Future<void> _tapChoice(_PlaceWord place) async {
    if (_reported) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;

    if (place.hil != _current.answerHil) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Diin kita makadto?',
        hiligaynon: true,
      );
      return;
    }
    setState(() => _arrivedHil = place.hil);
    await TudloVoiceButton.speak(
      context,
      'Husto! Makadto kita sa ${place.hil}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_index >= _situations.length - 1) {
        _reported = true;
        widget.onDone();
      } else {
        setState(() {
          _index++;
          _arrivedHil = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choiceOrders[_index]
        .map(_placeByHil)
        .whereType<_PlaceWord>()
        .toList();
    return _AnimalStage(
      mascotMessage: 'Koka: Diin kita makadto?',
      child: Column(
        children: [
          _PlaceSituationArt(situation: _current, size: 96),
          const SizedBox(height: 8),
          Text(
            _current.prompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final place in choices)
                GestureDetector(
                  onTap: () => _tapChoice(place),
                  child: _PlaceArt(
                    place: place,
                    size: 112,
                    glow: _arrivedHil == place.hil,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          if (_arrivedHil != null) const _LessonKokaMascot(size: 118),
        ],
      ),
    );
  }
}

class _PlaceSituation {
  final String prompt;
  final String answerHil;
  final List<String> choices;
  final String? imageAsset;
  final IconData icon;

  const _PlaceSituation({
    required this.prompt,
    required this.answerHil,
    required this.choices,
    this.imageAsset,
    required this.icon,
  });
}

class _PlaceSituationArt extends StatelessWidget {
  final _PlaceSituation situation;
  final double size;

  const _PlaceSituationArt({required this.situation, required this.size});

  @override
  Widget build(BuildContext context) {
    if (situation.imageAsset == null) {
      return Icon(situation.icon, color: TudloColors.green, size: size * .82);
    }
    return Image.asset(
      situation.imageAsset!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          Icon(situation.icon, color: TudloColors.green, size: size * .82),
    );
  }
}

class _PlaceArt extends StatelessWidget {
  final _PlaceWord place;
  final double size;
  final bool glow;

  const _PlaceArt({required this.place, required this.size, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Positioned.fill(
              child: LessonAssetGlow(
                asset: place.asset,
                fallbackIcon: place.icon,
                fallbackSize: size * .58,
              ),
            ),
          Image.asset(
            place.asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                Icon(place.icon, color: place.color, size: size * .58),
          ),
        ],
      ),
    );
  }
}

List<_PlaceWord> _placesForLesson(int lessonNumber) {
  final all = _allPlaces();
  return switch (lessonNumber) {
    1 => [all['balay']!, all['eskwelahan']!, all['simbahan']!],
    2 => [all['tinda']!, all['plasa']!, all['ospital']!],
    3 => [all['uma']!, all['baybay']!],
    _ => [
      all['balay']!,
      all['eskwelahan']!,
      all['tinda']!,
      all['ospital']!,
      all['uma']!,
      all['baybay']!,
      all['plasa']!,
    ],
  };
}

List<_PlaceWord> _placeReviewTargetsFor(int lessonNumber) {
  final all = _allPlaces();
  return switch (lessonNumber) {
    1 => [all['balay']!, all['eskwelahan']!, all['simbahan']!],
    2 => [all['ospital']!, all['tinda']!, all['plasa']!],
    3 => [all['uma']!, all['baybay']!, all['eskwelahan']!],
    _ => [all['ospital']!, all['eskwelahan']!, all['uma']!, all['baybay']!],
  };
}

_PlaceWord? _placeByHil(String hil) => _allPlaces()[hil];

Map<String, _PlaceWord> _allPlaces() {
  const house = _PlaceWord(
    hil: 'balay',
    eng: 'balay',
    asset: 'assets/images/level_game/house.png',
    icon: Icons.home_rounded,
    color: TudloColors.green,
    introSpeech: 'Ini ang balay.',
    tapSpeech: 'Balay. Diri nagapuyo ang pamilya.',
    effects: [Icons.door_front_door_rounded, Icons.pets_rounded],
  );
  const school = _PlaceWord(
    hil: 'eskwelahan',
    eng: 'eskwelahan',
    asset: 'assets/images/level_game/eskwelahan.png',
    icon: Icons.school_rounded,
    color: TudloColors.blue,
    introSpeech: 'Ini ang eskwelahan.',
    tapSpeech: 'Eskwelahan. Diri kita nagatuon.',
    effects: [Icons.notifications_active_rounded, Icons.waving_hand_rounded],
  );
  const church = _PlaceWord(
    hil: 'simbahan',
    eng: 'simbahan',
    asset: 'assets/images/level_game/simbahan.png',
    icon: Icons.church_rounded,
    color: TudloColors.forest,
    introSpeech: 'Ini ang simbahan.',
    tapSpeech: 'Simbahan. Diri nagasimba ang mga tawo.',
    effects: [Icons.notifications_rounded, Icons.door_front_door_rounded],
  );
  const market = _PlaceWord(
    hil: 'tinda',
    eng: 'tinda',
    asset: 'assets/images/level_game/tinda.png',
    icon: Icons.storefront_rounded,
    color: TudloColors.gold,
    introSpeech: 'Ini ang tinda.',
    tapSpeech: 'Tinda. Diri kita nagabakal sang pagkaon.',
    effects: [Icons.shopping_basket_rounded, Icons.local_grocery_store_rounded],
  );
  const plaza = _PlaceWord(
    hil: 'plasa',
    eng: 'plasa',
    asset: 'assets/images/level_game/plaza.png',
    icon: Icons.park_rounded,
    color: TudloColors.green,
    introSpeech: 'Ini ang plasa.',
    tapSpeech: 'Plasa. Diri nagadula kag nagapahuway ang mga tawo.',
    effects: [Icons.celebration_rounded, Icons.air_rounded],
  );
  const hospital = _PlaceWord(
    hil: 'ospital',
    eng: 'ospital',
    asset: 'assets/images/level_game/ospital.png',
    icon: Icons.local_hospital_rounded,
    color: TudloColors.coral,
    introSpeech: 'Ini ang ospital.',
    tapSpeech: 'Ospital. Diri ginabuligan ang mga masakiton.',
    effects: [Icons.medical_services_rounded, Icons.local_hospital_rounded],
  );
  const farm = _PlaceWord(
    hil: 'uma',
    eng: 'uma',
    asset: 'assets/images/level_game/uma.png',
    icon: Icons.agriculture_rounded,
    color: TudloColors.forest,
    introSpeech: 'Ini ang uma.',
    tapSpeech: 'Uma. Diri nagatanom ang mangunguma.',
    effects: [Icons.agriculture_rounded, Icons.grass_rounded],
  );
  const beach = _PlaceWord(
    hil: 'baybay',
    eng: 'baybay',
    asset: 'assets/images/level_game/baybay.png',
    icon: Icons.beach_access_rounded,
    color: TudloColors.blue,
    introSpeech: 'Ini ang baybay.',
    tapSpeech: 'Baybay. Diri nagapangisda ang mangingisda.',
    effects: [Icons.waves_rounded, Icons.water_rounded],
  );
  return const {
    'balay': house,
    'eskwelahan': school,
    'simbahan': church,
    'tinda': market,
    'plasa': plaza,
    'ospital': hospital,
    'uma': farm,
    'baybay': beach,
  };
}

class _FamilyWordLessonCard extends StatelessWidget {
  final _FamilyWord word;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _FamilyWordLessonCard({
    super.key,
    required this.word,
    required this.canGoBack,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: 'Koka: ${_titleCase(word.hil)}.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 458,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  child: _FamilyImage(
                    word: word,
                    size: 350,
                    voiceMessage: word.hil,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 184,
                  child: _PictureArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: canGoBack,
                    onPressed: onBack,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 184,
                  child: _PictureArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: true,
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _titleCase(word.hil),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PictureArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .36,
      child: Material(
        color: enabled
            ? TudloColors.green.withValues(alpha: .14)
            : TudloColors.line.withValues(alpha: .26),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 66,
            height: 66,
            child: Icon(
              icon,
              color: enabled ? TudloColors.blue : TudloColors.muted,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyQuizCard extends StatefulWidget {
  final _FamilyWord target;
  final List<_FamilyWord> choices;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyQuizCard({
    super.key,
    required this.target,
    required this.choices,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyQuizCard> createState() => _FamilyQuizCardState();
}

class _FamilyQuizCardState extends State<_FamilyQuizCard> {
  String? _selected;
  bool _checked = false;
  bool _correct = false;
  int _feedbackKey = 0;
  late final List<_FamilyWord> _choices;

  @override
  void initState() {
    super.initState();
    _choices = _shuffledChoices(widget.choices);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        unawaited(
          TudloVoiceButton.speak(context, widget.target.hil, hiligaynon: true),
        );
      });
    });
  }

  Future<void> _choose(_FamilyWord choice) async {
    if (_checked && _correct) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;
    await TudloVoiceButton.speak(context, choice.hil, hiligaynon: true);
    final isCorrect = choice.hil == widget.target.hil;
    widget.onAttempt(isCorrect);
    setState(() {
      _selected = choice.hil;
      _checked = true;
      _correct = isCorrect;
      _feedbackKey++;
    });
    if (isCorrect) {
      widget.onCorrect();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || _correct) return;
      setState(() {
        _checked = false;
        _selected = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _checked
          ? (_correct ? 'Husto! Maayo gid.' : 'Suliton liwat.')
          : _cleanFamilyPrompt('Koka: Pili-a ang sakto nga sabat.'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final imageSize = compact ? 238.0 : 258.0;
          final imageGap = compact ? 8.0 : 12.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FamilyImage(
                word: widget.target,
                size: imageSize,
                voiceMessage: widget.target.hil,
                voiceButtonSize: compact ? 60 : 64,
              ),
              SizedBox(height: imageGap),
              _FamilyChoiceGrid(
                choices: _choices,
                selected: _selected,
                checked: _checked,
                answer: widget.target.hil,
                feedbackKey: _feedbackKey,
                onChoose: _choose,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyHouseWindowQuizActivity extends StatefulWidget {
  final double progress;
  final List<_FamilyWord> members;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyHouseWindowQuizActivity({
    super.key,
    required this.progress,
    required this.members,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyHouseWindowQuizActivity> createState() =>
      _FamilyHouseWindowQuizActivityState();
}

class _FamilyHouseWindowQuizActivityState
    extends State<_FamilyHouseWindowQuizActivity> {
  late final List<_FamilyWord> _windowOrder = _shuffledChoices(widget.members);
  final Set<String> _found = {};
  int _targetIndex = 0;
  int? _wrongWindow;
  bool _done = false;
  int _feedbackKey = 0;

  _FamilyWord get _target =>
      widget.members[_targetIndex.clamp(
        0,
        math.max(0, widget.members.length - 1),
      )];

  String get _question => 'Diin si ${_familyQuestionName(_target)}?';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    });
  }

  Future<void> _tapWindow(int index) async {
    if (_done || index < 0 || index >= _windowOrder.length) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final member = _windowOrder[index];
    if (_found.contains(member.hil)) return;
    final correct = member.hil == _target.hil;
    widget.onAttempt(correct);
    setState(() {
      _feedbackKey++;
      _wrongWindow = correct ? null : index;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_question',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 720), () {
        if (mounted && !_done) setState(() => _wrongWindow = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _found.add(member.hil);
      if (_found.length >= widget.members.length) {
        _done = true;
      } else {
        _targetIndex++;
      }
    });
    if (_done) {
      await TudloVoiceButton.speak(
        context,
        'Ara na sila tanan!',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (!mounted) return;
      widget.onCorrect();
    } else {
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: 'Buligi si Koka makita ang iya pamilya sa balay!',
      progress: widget.progress,
      mascotMessage: _done ? 'Koka: Ara na sila tanan!' : 'Koka: $_question',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            children: [
              _PresentationInstructionText(
                message: _question,
                fontSize: (width * .074).clamp(25.0, 36.0),
                textAlign: TextAlign.center,
                onReplay: () => unawaited(
                  TudloVoiceButton.speak(context, _question, hiligaynon: true),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: math.min(width, 360),
                    height: 350,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(child: _FamilyHouseShell()),
                        for (
                          var index = 0;
                          index < _windowOrder.length && index < 3;
                          index++
                        )
                          Positioned(
                            left: 31.0 + index * 105.0,
                            top: 114,
                            child: _FamilyWindowTarget(
                              member: _windowOrder[index],
                              found: _found.contains(_windowOrder[index].hil),
                              wrong: _wrongWindow == index,
                              feedbackKey: _feedbackKey,
                              onTap: () => _tapWindow(index),
                            ),
                          ),
                        if (_done)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: .4, end: 1),
                                duration: const Duration(milliseconds: 620),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0, 1),
                                    child: Transform.scale(
                                      scale: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/level_game/people/pamilya.png',
                                    width: 250,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.family_restroom_rounded,
                                      color: TudloColors.green,
                                      size: 150,
                                    ),
                                  ),
                                ),
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
        },
      ),
    );
  }
}

class _FamilyVisitorDoorQuizActivity extends StatefulWidget {
  final double progress;
  final List<_FamilyWord> visitors;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyVisitorDoorQuizActivity({
    super.key,
    required this.progress,
    required this.visitors,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyVisitorDoorQuizActivity> createState() =>
      _FamilyVisitorDoorQuizActivityState();
}

class _FamilyVisitorDoorQuizActivityState
    extends State<_FamilyVisitorDoorQuizActivity> {
  late final List<_FamilyWord> _visitorOrder = _shuffledChoices(
    widget.visitors,
  );
  final Set<String> _found = {};
  int _targetIndex = 0;
  String? _wrong;
  bool _done = false;
  int _feedbackKey = 0;

  _FamilyWord get _target =>
      widget.visitors[_targetIndex.clamp(
        0,
        math.max(0, widget.visitors.length - 1),
      )];

  String get _question =>
      'Kilala mo si ${_familyQuestionName(_target)}? Tap-tapa siya!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    });
  }

  Future<void> _tapVisitor(_FamilyWord visitor) async {
    if (_done || _found.contains(visitor.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = visitor.hil == _target.hil;
    widget.onAttempt(correct);
    setState(() {
      _feedbackKey++;
      _wrong = correct ? null : visitor.hil;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_question',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 720), () {
        if (mounted && !_done) setState(() => _wrong = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _found.add(visitor.hil);
      if (_found.length >= widget.visitors.length) {
        _done = true;
      } else {
        _targetIndex++;
      }
    });
    if (_done) {
      await TudloVoiceButton.speak(
        context,
        'Husto! Kilala mo sila tanan.',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (!mounted) return;
      widget.onCorrect();
    } else {
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: 'May bisita sa balay ni Koka!',
      progress: widget.progress,
      mascotMessage: _done ? 'Koka: Maayo gid!' : 'Koka: $_question',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            children: [
              _PresentationInstructionText(
                message: _question,
                fontSize: (width * .066).clamp(23.0, 32.0),
                textAlign: TextAlign.center,
                onReplay: () => unawaited(
                  TudloVoiceButton.speak(context, _question, hiligaynon: true),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      top: 8,
                      child: _FamilyDoorShape(
                        width: math.min(width * .56, 210),
                        height: 270,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final visitor in _visitorOrder)
                            _FamilyVisitorTarget(
                              visitor: visitor,
                              found: _found.contains(visitor.hil),
                              wrong: _wrong == visitor.hil,
                              feedbackKey: _feedbackKey,
                              onTap: () => _tapVisitor(visitor),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyPhotoPlacement {
  final _FamilyWord member;
  final String place;
  final Alignment alignment;

  const _FamilyPhotoPlacement({
    required this.member,
    required this.place,
    required this.alignment,
  });
}

class _FamilyPhotoQuizActivity extends StatefulWidget {
  final double progress;
  final List<_FamilyWord> members;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyPhotoQuizActivity({
    super.key,
    required this.progress,
    required this.members,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyPhotoQuizActivity> createState() =>
      _FamilyPhotoQuizActivityState();
}

class _FamilyPhotoQuizActivityState extends State<_FamilyPhotoQuizActivity> {
  late final List<_FamilyPhotoPlacement> _placements = _familyPhotoPlacements(
    widget.members,
  );
  late final List<_FamilyWord> _choices = _shuffledChoices(
    _placements.map((placement) => placement.member),
  );
  final Map<String, _FamilyWord> _placedByHil = {};
  int _targetIndex = 0;
  String? _wrongHil;
  bool _done = false;
  bool _flash = false;
  int _feedbackKey = 0;

  _FamilyPhotoPlacement get _target =>
      _placements[_targetIndex.clamp(0, math.max(0, _placements.length - 1))];

  String get _instruction =>
      'Ibutang si ${_familyQuestionName(_target.member)} sa ${_target.place}!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _placements.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _placeMember(
    _FamilyPhotoPlacement slot,
    _FamilyWord member,
  ) async {
    if (_done || _placedByHil.containsKey(slot.member.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }

    final correct =
        member.hil == _target.member.hil &&
        slot.member.hil == _target.member.hil;
    widget.onAttempt(correct);
    setState(() {
      _feedbackKey++;
      _wrongHil = correct ? null : member.hil;
    });

    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 720), () {
        if (mounted && !_done) setState(() => _wrongHil = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _placedByHil[slot.member.hil] = member;
      if (_placedByHil.length >= _placements.length) {
        _done = true;
        _flash = true;
      } else {
        _targetIndex++;
      }
    });

    if (_done) {
      unawaited(
        AppAudioService.instance.playSoundEffect(
          AppAudioService.tap,
          volume: .60,
          allowRapidRepeat: true,
        ),
      );
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _flash = false);
      });
      await TudloVoiceButton.speak(
        context,
        'Husto! Kumpleto na ang photo sang pamilya!',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (!mounted) return;
      widget.onCorrect();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: 'Photo sang pamilya!',
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Kumpleto na ang photo!'
          : 'Koka: $_instruction',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final frameWidth = math.min(width * .90, 342.0);
          final frameHeight = math.min(338.0, constraints.maxHeight * .58);
          final avatarSize = (frameWidth * .25).clamp(70.0, 92.0);
          return Column(
            children: [
              _PresentationInstructionText(
                message: _instruction,
                fontSize: (width * .064).clamp(22.0, 31.0),
                textAlign: TextAlign.center,
                onReplay: () => unawaited(
                  TudloVoiceButton.speak(
                    context,
                    _instruction,
                    hiligaynon: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _flash
                              ? Colors.white
                              : Colors.white.withValues(alpha: .86),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: TudloColors.forest,
                            width: 6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TudloColors.forest.withValues(alpha: .18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6DE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE9C77E),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (final placement in _placements)
                      Align(
                        alignment: placement.alignment,
                        child: _FamilyPhotoSlot(
                          placement: placement,
                          placed: _placedByHil[placement.member.hil],
                          avatarSize: avatarSize,
                          onAccept: (member) => _placeMember(placement, member),
                        ),
                      ),
                    if (_done)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: _flash ? .72 : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final member in _choices)
                        if (!_placedByHil.containsKey(member.hil))
                          _FamilyPhotoDraggable(
                            member: member,
                            size: (width * .19).clamp(64.0, 84.0),
                            wrong: _wrongHil == member.hil,
                            feedbackKey: _feedbackKey,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyPhotoSlot extends StatelessWidget {
  final _FamilyPhotoPlacement placement;
  final _FamilyWord? placed;
  final double avatarSize;
  final ValueChanged<_FamilyWord> onAccept;

  const _FamilyPhotoSlot({
    required this.placement,
    required this.placed,
    required this.avatarSize,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlaced = placed != null;
    return DragTarget<_FamilyWord>(
      onWillAcceptWithDetails: (_) => !hasPlaced,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: candidates.isNotEmpty ? 1.08 : 1,
          child: Container(
            width: avatarSize + 22,
            height: avatarSize + 28,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hasPlaced
                  ? TudloColors.softGreen
                  : Colors.white.withValues(alpha: .70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: candidates.isNotEmpty
                    ? TudloColors.blue
                    : hasPlaced
                    ? TudloColors.green
                    : const Color(0xFFE8D59B),
                width: 4,
              ),
            ),
            child: hasPlaced
                ? _FamilyPhotoPerson(member: placed!, size: avatarSize)
                : Icon(
                    Icons.person_add_alt_1_rounded,
                    color: TudloColors.forest.withValues(alpha: .45),
                    size: avatarSize * .55,
                  ),
          ),
        );
      },
    );
  }
}

class _FamilyPhotoDraggable extends StatelessWidget {
  final _FamilyWord member;
  final double size;
  final bool wrong;
  final int feedbackKey;

  const _FamilyPhotoDraggable({
    required this.member,
    required this.size,
    required this.wrong,
    required this.feedbackKey,
  });

  @override
  Widget build(BuildContext context) {
    final child = _FeedbackMotion(
      key: ValueKey('photo-choice-${member.hil}-$feedbackKey-$wrong'),
      correct: false,
      wrong: wrong,
      child: _FamilyPhotoPerson(member: member, size: size),
    );
    return Draggable<_FamilyWord>(
      data: member,
      feedback: Material(
        color: Colors.transparent,
        child: _FamilyPhotoPerson(member: member, size: size * 1.05),
      ),
      childWhenDragging: Opacity(opacity: .30, child: child),
      child: child,
    );
  }
}

class _FamilyPhotoPerson extends StatelessWidget {
  final _FamilyWord member;
  final double size;

  const _FamilyPhotoPerson({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        member.imageAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(member.icon, color: TudloColors.forest, size: size * .76),
      ),
    );
  }
}

class _FamilyHouseShell extends StatelessWidget {
  const _FamilyHouseShell();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FamilyHouseShellPainter());
  }
}

class _FamilyHouseShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final roof = Path()
      ..moveTo(size.width * .08, size.height * .34)
      ..lineTo(size.width * .50, size.height * .06)
      ..lineTo(size.width * .92, size.height * .34)
      ..close();
    paint.color = const Color(0xFFFFA94D);
    canvas.drawPath(roof, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = TudloColors.forest.withValues(alpha: .75);
    canvas.drawPath(roof, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF5D8);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .10,
        size.height * .28,
        size.width * .80,
        size.height * .58,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(body, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = TudloColors.forest;
    canvas.drawRRect(body, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFC68144);
    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .43,
        size.height * .57,
        size.width * .14,
        size.height * .29,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(door, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FamilyWindowTarget extends StatelessWidget {
  final _FamilyWord member;
  final bool found;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback onTap;

  const _FamilyWindowTarget({
    required this.member,
    required this.found,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('window-${member.hil}-$feedbackKey-$wrong'),
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 88,
          height: 106,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: found ? Colors.white : const Color(0xFFC7F2FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: found ? TudloColors.green : TudloColors.blue,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .20),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: found
              ? Image.asset(
                  member.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(member.icon, color: TudloColors.forest, size: 52),
                )
              : Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1DC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1DC),
                          borderRadius: BorderRadius.circular(10),
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

class _FamilyDoorShape extends StatelessWidget {
  final double width;
  final double height;

  const _FamilyDoorShape({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TudloColors.forest, width: 6),
      ),
      child: Center(
        child: Container(
          width: width * .58,
          height: height * .72,
          decoration: BoxDecoration(
            color: const Color(0xFFC68144),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF8F5D2D), width: 5),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.only(right: width * .08),
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: TudloColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyVisitorTarget extends StatelessWidget {
  final _FamilyWord visitor;
  final bool found;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback onTap;

  const _FamilyVisitorTarget({
    required this.visitor,
    required this.found,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('visitor-${visitor.hil}-$feedbackKey-$wrong'),
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 108,
          height: 178,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            color: found
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: found ? TudloColors.green : Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  visitor.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(visitor.icon, color: TudloColors.forest, size: 74),
                ),
              ),
              Text(
                found ? _titleCase(visitor.hil) : '?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyMatchingCard extends StatefulWidget {
  final List<_FamilyWord> words;
  final void Function(_FamilyWord word, bool correct) onAttempt;
  final VoidCallback onCorrect;

  const _FamilyMatchingCard({
    super.key,
    required this.words,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyMatchingCard> createState() => _FamilyMatchingCardState();
}

class _FamilyMatchingCardState extends State<_FamilyMatchingCard> {
  String? _selectedHil;
  String? _wrongHil;
  String? _wrongImageHil;
  final Set<String> _matched = {};
  bool _reported = false;
  int _feedbackKey = 0;
  late final List<_FamilyWord> _imageOrder;

  @override
  void initState() {
    super.initState();
    _imageOrder = _shuffledChoices(widget.words);
  }

  Future<void> _selectWord(_FamilyWord word) async {
    if (_matched.contains(word.hil) || _reported) return;
    await TudloVoiceButton.speak(context, word.hil, hiligaynon: true);
    if (!mounted) return;
    setState(() {
      _selectedHil = _selectedHil == word.hil ? null : word.hil;
      _wrongHil = null;
      _wrongImageHil = null;
    });
  }

  Future<void> _selectImage(_FamilyWord word) async {
    if (_selectedHil == null || _matched.contains(word.hil) || _reported) {
      return;
    }
    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;
    final selected = _selectedHil!;
    final correct = selected == word.hil;
    widget.onAttempt(word, correct);
    setState(() {
      _feedbackKey++;
      if (correct) {
        _matched.add(word.hil);
        _selectedHil = null;
        _wrongHil = null;
        _wrongImageHil = null;
      } else {
        _wrongHil = selected;
        _wrongImageHil = word.hil;
        _selectedHil = null;
      }
    });
    if (correct && _matched.length == widget.words.length && !_reported) {
      _reported = true;
      widget.onCorrect();
      return;
    }
    if (!correct) {
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (!mounted || _reported) return;
        setState(() {
          _wrongHil = null;
          _wrongImageHil = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _matched.length == widget.words.length
          ? 'Husto! Maayo gid.'
          : 'Koka: Ipares ang pareho.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final word in widget.words) ...[
                    _matchWordButton(word),
                    if (word != widget.words.last) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final word in _imageOrder) ...[
                    _matchImageButton(word),
                    if (word != _imageOrder.last) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchWordButton(_FamilyWord word) {
    final selected = _selectedHil == word.hil;
    final matched = _matched.contains(word.hil);
    final wrong = _wrongHil == word.hil;
    return _FeedbackMotion(
      key: ValueKey('word-${word.hil}-$_feedbackKey-$selected-$matched'),
      correct: matched,
      wrong: wrong,
      child: SizedBox(
        height: 122,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _selectWord(word),
          style: ElevatedButton.styleFrom(
            backgroundColor: matched
                ? TudloColors.green
                : selected
                ? TudloColors.blue
                : const Color(0xFF49CC55),
            foregroundColor: Colors.white,
            elevation: selected || matched ? 7 : 4,
            shadowColor: TudloColors.forest.withValues(alpha: .20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: FittedBox(child: Text(_titleCase(word.hil))),
        ),
      ),
    );
  }

  Widget _matchImageButton(_FamilyWord word) {
    final matched = _matched.contains(word.hil);
    final wrong = _wrongImageHil == word.hil;
    return _FeedbackMotion(
      key: ValueKey('image-${word.hil}-$_feedbackKey-$matched'),
      correct: matched,
      wrong: wrong,
      child: GestureDetector(
        onTap: () => _selectImage(word),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 122,
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: matched
                ? const Color(0xFFE8FFD8)
                : wrong
                ? const Color(0xFFFFEEEE)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: matched
                ? [
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .20),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Transform.scale(
              scale: 1.18,
              child: Image.asset(
                word.imageAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    Icon(word.icon, color: TudloColors.forest, size: 72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _FamilyStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 555,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: _StageContentScaler(child: child),
                ),
              ),
              Positioned(
                right: -18,
                top: 510,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(message: mascotMessage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageContentScaler extends StatelessWidget {
  final Widget child;

  const _StageContentScaler({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
        );
      },
    );
  }
}

class _FamilyImage extends StatelessWidget {
  final _FamilyWord word;
  final double size;
  final String voiceMessage;
  final double voiceButtonSize;

  const _FamilyImage({
    required this.word,
    required this.size,
    required this.voiceMessage,
    this.voiceButtonSize = 70,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Image.asset(
              word.imageAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Icon(word.icon, color: TudloColors.forest, size: size * .56),
            ),
          ),
          const SizedBox(height: 8),
          TudloVoiceButton(
            message: voiceMessage,
            tooltip: 'Pamatii',
            size: voiceButtonSize,
            hiligaynon: true,
          ),
        ],
      ),
    );
  }
}

class _FamilyChoiceGrid extends StatelessWidget {
  final List<_FamilyWord> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackKey;
  final ValueChanged<_FamilyWord> onChoose;

  const _FamilyChoiceGrid({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackKey,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChoices = choices.take(3).toList();
    final topChoices = visibleChoices.take(2).toList();
    final bottomChoice = visibleChoices.length > 2 ? visibleChoices[2] : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 10.0 : 14.0;
        final buttonHeight = constraints.maxWidth < 360 ? 64.0 : 68.0;
        final bottomWidth = math.min(188.0, constraints.maxWidth * .54);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (var index = 0; index < topChoices.length; index++) ...[
                  Expanded(
                    child: _button(topChoices[index], height: buttonHeight),
                  ),
                  if (index == 0) SizedBox(width: gap),
                ],
              ],
            ),
            if (bottomChoice != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: bottomWidth,
                child: _button(bottomChoice, height: buttonHeight),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _button(_FamilyWord choice, {required double height}) {
    final active = selected == choice.hil;
    final correct = checked && active && choice.hil == answer;
    final wrong = checked && active && choice.hil != answer;
    return _FeedbackMotion(
      key: ValueKey('${choice.hil}-$feedbackKey-$active'),
      correct: correct,
      wrong: wrong,
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: () => onChoose(choice),
          style: ElevatedButton.styleFrom(
            backgroundColor: wrong
                ? const Color(0xFFE53935)
                : correct
                ? TudloColors.green
                : const Color(0xFF49CC55),
            foregroundColor: Colors.white,
            elevation: active ? 8 : 3,
            shadowColor: TudloColors.forest.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: FittedBox(child: Text(_titleCase(choice.hil))),
        ),
      ),
    );
  }
}

List<_FamilyWord> _familyWordsFor(int lessonNumber) {
  const nanay = _FamilyWord(
    hil: 'nanay',
    eng: 'nanay',
    imageAsset: 'assets/images/level_game/people/nanay.svg',
    icon: Icons.woman_rounded,
  );
  const tatay = _FamilyWord(
    hil: 'tatay',
    eng: 'tatay',
    imageAsset: 'assets/images/level_game/people/tatay.svg',
    icon: Icons.man_rounded,
  );
  const bata = _FamilyWord(
    hil: 'bata',
    eng: 'bata',
    imageAsset: 'assets/images/level_game/people/bata.svg',
    icon: Icons.child_care_rounded,
  );
  const lola = _FamilyWord(
    hil: 'lola',
    eng: 'lola',
    imageAsset: 'assets/images/level_game/people/lola.png',
    icon: Icons.elderly_woman_rounded,
  );
  const lolo = _FamilyWord(
    hil: 'lolo',
    eng: 'lolo',
    imageAsset: 'assets/images/level_game/people/lolo.png',
    icon: Icons.elderly_rounded,
  );
  const magulang = _FamilyWord(
    hil: 'magulang',
    eng: 'magulang',
    imageAsset: 'assets/images/level_game/people/bata-nga-lalaki.png',
    icon: Icons.escalator_warning_rounded,
  );
  const manghod = _FamilyWord(
    hil: 'manghod',
    eng: 'manghod',
    imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
    icon: Icons.child_friendly_rounded,
  );

  return switch (lessonNumber) {
    1 => const [nanay, tatay, bata],
    2 => const [lola, lolo, nanay],
    3 => const [magulang, manghod, lola, tatay],
    _ => const [nanay, tatay, bata, lola, lolo, magulang, manghod],
  };
}

List<_FamilyWord> _familyChoicesFor(
  _FamilyWord target,
  List<_FamilyWord> words,
  int count,
) {
  final pool = words.isEmpty ? [target] : words;
  final selected = <_FamilyWord>[];
  if (count == 2) {
    final distractor = pool.firstWhere(
      (word) => word.hil != target.hil,
      orElse: () => target,
    );
    selected.addAll([distractor, target]);
  } else {
    selected.addAll(pool.take(count));
    if (!selected.any((word) => word.hil == target.hil)) {
      selected[selected.length - 1] = target;
    }
  }
  return selected;
}

List<_FamilyWord> _familyHouseTargets(List<_FamilyWord> words) {
  final targets = ['nanay', 'tatay', 'bata']
      .map((name) => _familyWordByHil(words, name))
      .whereType<_FamilyWord>()
      .toList();
  if (targets.length >= 3) return targets.take(3).toList();
  return words.take(math.min(3, words.length)).toList();
}

List<_FamilyWord> _familyVisitorTargets(List<_FamilyWord> words) {
  final targets = ['lola', 'lolo', 'nanay']
      .map((name) => _familyWordByHil(words, name))
      .whereType<_FamilyWord>()
      .toList();
  if (targets.length >= 3) return targets.take(3).toList();
  return words.take(math.min(3, words.length)).toList();
}

List<_FamilyWord> _familyPhotoTargets(List<_FamilyWord> words) {
  final targets = ['magulang', 'manghod', 'lola', 'tatay']
      .map((name) => _familyWordByHil(words, name))
      .whereType<_FamilyWord>()
      .toList();
  if (targets.length >= 4) return targets.take(4).toList();
  final fallback = [...targets];
  for (final word in words) {
    if (fallback.length >= 4) break;
    if (!fallback.any((item) => item.hil == word.hil)) fallback.add(word);
  }
  return fallback;
}

List<_FamilyPhotoPlacement> _familyPhotoPlacements(List<_FamilyWord> words) {
  const defaults = [
    ('magulang', 'wala', Alignment(-.58, -.40)),
    ('manghod', 'tuo', Alignment(.58, -.40)),
    ('lola', 'ubos nga wala', Alignment(-.58, .44)),
    ('tatay', 'ubos nga tuo', Alignment(.58, .44)),
  ];
  final placements = <_FamilyPhotoPlacement>[];
  for (final item in defaults) {
    final word = _familyWordByHil(words, item.$1);
    if (word == null) continue;
    placements.add(
      _FamilyPhotoPlacement(member: word, place: item.$2, alignment: item.$3),
    );
  }
  if (placements.isNotEmpty) return placements;

  const fallbackAlignments = [
    Alignment(-.58, -.40),
    Alignment(.58, -.40),
    Alignment(-.58, .44),
    Alignment(.58, .44),
  ];
  const fallbackPlaces = ['wala', 'tuo', 'ubos nga wala', 'ubos nga tuo'];
  return [
    for (var index = 0; index < words.length && index < 4; index++)
      _FamilyPhotoPlacement(
        member: words[index],
        place: fallbackPlaces[index],
        alignment: fallbackAlignments[index],
      ),
  ];
}

_FamilyWord? _familyWordByHil(List<_FamilyWord> words, String hil) {
  for (final word in words) {
    if (word.hil == hil) return word;
  }
  return null;
}

String _familyQuestionName(_FamilyWord word) {
  return switch (word.hil) {
    'nanay' => 'mother',
    'tatay' => 'father',
    'bata' => 'child',
    'lola' => 'grandmother',
    'lolo' => 'grandfather',
    'magulang' => 'older sibling',
    'manghod' => 'younger sibling',
    _ => word.hil,
  };
}

String _cleanFamilyPrompt(String prompt) {
  return prompt
      .replaceAll('â€¦', '...')
      .replaceAll('…', '...')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _GradeOneAnimalLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAnimalLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneAnimalLesson> createState() => _GradeOneAnimalLessonState();
}

class _GradeOneAnimalLessonState extends State<_GradeOneAnimalLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animals = _animalsForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final steps = [
      for (final animal in animals) ...[
        _AlphabetFadeStep(
          child: _AnimalTapCard(
            key: ValueKey('animal-tap-${widget.content.id}-${animal.hil}'),
            animal: animal,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _AnimalHomeDragCard(
            key: ValueKey('animal-drag-${widget.content.id}-${animal.hil}'),
            animal: animal,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _AnimalReviewCard(
          key: ValueKey('animal-review-${widget.content.id}'),
          animals: animals.take(3).toList(),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
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
                  key: ValueKey('animal-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimalWord {
  final String hil;
  final String eng;
  final String soundText;
  final String tapSpeech;
  final String dragHomeLabel;
  final String? imageAsset;
  final String? homeAsset;
  final IconData icon;
  final IconData homeIcon;
  final Color color;

  const _AnimalWord({
    required this.hil,
    required this.eng,
    required this.soundText,
    required this.tapSpeech,
    required this.dragHomeLabel,
    required this.icon,
    required this.homeIcon,
    required this.color,
    this.imageAsset,
    this.homeAsset,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get dragInstruction => 'Guyoda ang $hil pakadto sa $dragHomeLabel.';
  String get retryInstruction =>
      'Liwata. Guyoda ang $hil pakadto sa $dragHomeLabel.';
  String get successSpeech => 'Husto! Ara na ang $hil sa $dragHomeLabel.';
}

class _SpacedLessonWord extends StatelessWidget {
  final String word;
  final Color color;
  final double fontSize;
  final double spacing;

  const _SpacedLessonWord({
    required this.word,
    required this.color,
    required this.fontSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < letters.length; index++) ...[
            Text(
              letters[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: color,
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            if (index != letters.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

class _AnimalTapCard extends StatefulWidget {
  final _AnimalWord animal;
  final VoidCallback onDone;

  const _AnimalTapCard({super.key, required this.animal, required this.onDone});

  @override
  State<_AnimalTapCard> createState() => _AnimalTapCardState();
}

class _AnimalTapCardState extends State<_AnimalTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.animal.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapAnimal() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.animal.soundText}! ${widget.animal.tapSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? widget.animal.tapSpeech
          : 'Koka: ${widget.animal.tapInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SpacedLessonWord(
            word: widget.animal.upperName,
            color: TudloColors.forest,
            fontSize: 48,
            spacing: 10,
          ),
          const SizedBox(height: 42),
          GestureDetector(
            onTap: _tapAnimal,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 374,
                    height: 374,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tapped
                          ? widget.animal.color.withValues(alpha: .18)
                          : Colors.transparent,
                      boxShadow: _tapped
                          ? [
                              BoxShadow(
                                color: widget.animal.color.withValues(
                                  alpha: .34,
                                ),
                                blurRadius: 34,
                                spreadRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  _AnimalArt(animal: widget.animal, size: 352),
                  if (_tapped) const _AnimalSparkles(size: 390),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHomeDragCard extends StatefulWidget {
  final _AnimalWord animal;
  final VoidCallback onDone;

  const _AnimalHomeDragCard({
    super.key,
    required this.animal,
    required this.onDone,
  });

  @override
  State<_AnimalHomeDragCard> createState() => _AnimalHomeDragCardState();
}

class _AnimalHomeDragCardState extends State<_AnimalHomeDragCard> {
  bool _placed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.animal.dragInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_placed) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        widget.animal.retryInstruction,
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _accept() async {
    if (_placed) return;
    setState(() => _placed = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.animal.soundText}! ${widget.animal.successSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _placed
          ? 'Koka: ${widget.animal.successSpeech}'
          : _retrying
          ? 'Koka: ${widget.animal.retryInstruction}'
          : 'Koka: ${widget.animal.dragInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.animal.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final targetSize = math.min(236.0, width * .62);
              final animalSize = math.min(214.0, width * .56);
              final placedAnimalSize = math.min(142.0, targetSize * .58);

              return SizedBox(
                height: 390,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: 0,
                      top: 8,
                      child: _AnimalHomeTarget(
                        animal: widget.animal,
                        size: targetSize,
                        placed: _placed,
                        onAccept: _accept,
                        onWrongDrop: _retry,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 10,
                      child: _placed
                          ? SizedBox(width: animalSize, height: animalSize)
                          : _AnimalDraggable(
                              animal: widget.animal,
                              size: animalSize,
                              onMissed: _retry,
                            ),
                    ),
                    if (_placed)
                      Positioned(
                        right: (targetSize - placedAnimalSize) / 2,
                        top: 76,
                        child: _AnimalBounce(
                          active: true,
                          child: _AnimalArt(
                            animal: widget.animal,
                            size: placedAnimalSize,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimalReviewRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const _AnimalReviewRow({required this.children, required this.gap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _AnimalReviewSizedSlot extends StatelessWidget {
  final double size;
  final Widget child;

  const _AnimalReviewSizedSlot({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

class _AnimalReviewCard extends StatefulWidget {
  final List<_AnimalWord> animals;
  final VoidCallback onDone;

  const _AnimalReviewCard({
    super.key,
    required this.animals,
    required this.onDone,
  });

  @override
  State<_AnimalReviewCard> createState() => _AnimalReviewCardState();
}

class _AnimalReviewCardState extends State<_AnimalReviewCard> {
  final Set<String> _matched = {};
  String _message = 'Koka: Guyoda ang kada sapat pakadto sa iya puluy-an.';
  late final List<_AnimalWord> _homeOrder;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _homeOrder = _shuffledHomeOrder(widget.animals);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang kada sapat pakadto sa iya puluy-an.',
          hiligaynon: true,
        ),
      );
    });
  }

  List<_AnimalWord> _shuffledHomeOrder(List<_AnimalWord> animals) {
    final shuffled = [...animals];
    if (shuffled.length < 2) return shuffled;

    shuffled.shuffle(math.Random());
    final sameOrder = List.generate(
      shuffled.length,
      (index) => shuffled[index].hil == animals[index].hil,
    ).every((same) => same);
    if (sameOrder) {
      final first = shuffled.removeAt(0);
      shuffled.add(first);
    }
    return shuffled;
  }

  Future<void> _handleDrop(_AnimalWord target, _AnimalWord dragged) async {
    if (_reported || _matched.contains(dragged.hil)) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;

    if (target.hil != dragged.hil) {
      setState(() {
        _message = 'Koka: Liwata. Pangitaa ang puluy-an sang ${dragged.hil}.';
      });
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pangitaa ang puluy-an sang ${dragged.hil}.',
        hiligaynon: true,
      );
      return;
    }

    setState(() {
      _matched.add(dragged.hil);
      _message = 'Koka: Husto! ${_titleCase(dragged.hil)}.';
    });
    await TudloVoiceButton.speak(
      context,
      '${dragged.soundText}! Husto! Ara na ang ${dragged.hil} sa ${dragged.dragHomeLabel}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_matched.length == widget.animals.length && !_reported) {
      _reported = true;
      setState(() {
        _message = 'Koka: Maayo gid! Kabalo ka na sang mga sapat sa palibot!';
      });
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Kabalo ka na sang mga sapat sa palibot!',
        hiligaynon: true,
      );
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _message,
      maxWidth: 430,
      mascotScale: 1.13,
      mascotTop: 430,
      mascotRight: -30,
      child: Column(
        children: [
          Text(
            'Ipares ang Puluy-an',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 76),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemCount = widget.animals.length;
              final gap = itemCount > 2 ? 8.0 : 16.0;
              final itemSize = itemCount == 0
                  ? 0.0
                  : math
                        .min(
                          136.0,
                          (constraints.maxWidth - gap * (itemCount - 1)) /
                              itemCount,
                        )
                        .clamp(0.0, 136.0)
                        .toDouble();
              final dragSize = math.min(132.0, itemSize);

              return Column(
                children: [
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final animal in _homeOrder)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _ReviewHomeTarget(
                            animal: animal,
                            matched: _matched.contains(animal.hil),
                            size: itemSize,
                            onDrop: (dragged) => _handleDrop(animal, dragged),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final animal in widget.animals)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _matched.contains(animal.hil)
                              ? SizedBox.square(dimension: dragSize)
                              : _AnimalDraggable(
                                  animal: animal,
                                  size: dragSize,
                                  onMissed: () {
                                    setState(() {
                                      _message =
                                          'Koka: Guyoda ang ${animal.hil} pakadto sa iya puluy-an.';
                                    });
                                  },
                                ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimalStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;
  final double maxWidth;
  final double mascotScale;
  final double mascotTop;
  final double mascotRight;

  const _AnimalStage({
    required this.child,
    required this.mascotMessage,
    this.maxWidth = 390,
    this.mascotScale = 1,
    this.mascotTop = 500,
    this.mascotRight = -18,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 550,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: _StageContentScaler(child: child),
                ),
              ),
              Positioned(
                right: mascotRight,
                top: mascotTop,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(
                    message: mascotMessage,
                    scale: mascotScale,
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

class _AnimalDraggable extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final VoidCallback onMissed;

  const _AnimalDraggable({
    required this.animal,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_AnimalWord>(
      data: animal,
      feedback: Material(
        color: Colors.transparent,
        child: _AnimalArt(animal: animal, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _AnimalArt(animal: animal, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _AnimalArt(animal: animal, size: size),
    );
  }
}

class _AnimalHomeTarget extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final bool placed;
  final VoidCallback onAccept;
  final VoidCallback onWrongDrop;

  const _AnimalHomeTarget({
    required this.animal,
    required this.size,
    required this.placed,
    required this.onAccept,
    required this.onWrongDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AnimalWord>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) {
        if (details.data.hil == animal.hil) {
          onAccept();
        } else {
          onWrongDrop();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return _AnimalHomeArt(
          animal: animal,
          size: size,
          active: candidateData.isNotEmpty,
          matched: placed,
          showLabel: false,
        );
      },
    );
  }
}

class _ReviewHomeTarget extends StatelessWidget {
  final _AnimalWord animal;
  final bool matched;
  final double size;
  final ValueChanged<_AnimalWord> onDrop;

  const _ReviewHomeTarget({
    required this.animal,
    required this.matched,
    required this.size,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AnimalWord>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        return _AnimalHomeArt(
          animal: animal,
          size: size,
          active: candidateData.isNotEmpty,
          matched: matched,
          showLabel: false,
        );
      },
    );
  }
}

class _AnimalArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalArt({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    if (animal.imageAsset != null) {
      return Image.asset(
        animal.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            _AnimalIconArt(animal: animal, size: size),
      );
    }
    return _AnimalIconArt(animal: animal, size: size);
  }
}

class _AnimalIconArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalIconArt({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: animal.color.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: animal.color.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(animal.icon, color: animal.color, size: size * .58),
    );
  }
}

class _AnimalHomeArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final bool active;
  final bool matched;
  final bool showLabel;

  const _AnimalHomeArt({
    required this.animal,
    required this.size,
    required this.active,
    required this.matched,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final home = animal.homeAsset == null
        ? _AnimalHomeIcon(animal: animal, size: size)
        : Image.asset(
            animal.homeAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _AnimalHomeIcon(animal: animal, size: size),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: showLabel ? size + 42 : size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        boxShadow: active || matched
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .24),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Center(child: home),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              _titleCase(animal.dragHomeLabel),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimalHomeIcon extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalHomeIcon({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * .88,
      height: size * .88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TudloColors.softGreen.withValues(alpha: .82),
      ),
      child: Icon(animal.homeIcon, color: TudloColors.forest, size: size * .48),
    );
  }
}

class _AnimalBounce extends StatelessWidget {
  final bool active;
  final Widget child;

  const _AnimalBounce({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final jump = -math.sin(value * math.pi) * 34;
        return Transform.translate(
          offset: Offset(0, jump),
          child: Transform.scale(scale: 1 + value * .04, child: child),
        );
      },
      child: child,
    );
  }
}

class _AnimalSparkles extends StatelessWidget {
  final double size;

  const _AnimalSparkles({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: const [
          Positioned(
            top: 18,
            right: 42,
            child: _Sparkle(color: TudloColors.gold, size: 18),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: _Sparkle(color: TudloColors.green, size: 13),
          ),
          Positioned(
            bottom: 48,
            right: 24,
            child: _Sparkle(color: TudloColors.gold, size: 15),
          ),
          Positioned(
            bottom: 30,
            left: 56,
            child: _Sparkle(color: TudloColors.green, size: 11),
          ),
        ],
      ),
    );
  }
}

List<_AnimalWord> _animalsForLesson(int lessonNumber) {
  const dog = _AnimalWord(
    hil: 'ido',
    eng: 'ido',
    soundText: 'aw aw',
    tapSpeech: 'Ido. Ang ido nagatahol.',
    dragHomeLabel: 'iya balay',
    imageAsset: 'assets/images/level_game/animals/dog.png',
    homeAsset: 'assets/images/level_game/dog-house.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_rounded,
    color: TudloColors.orange,
  );
  const cat = _AnimalWord(
    hil: 'kuring',
    eng: 'kuring',
    soundText: 'ngiyaw',
    tapSpeech: 'Kuring. Ang kuring nagingiyaw.',
    dragHomeLabel: 'iya balay',
    imageAsset: 'assets/images/level_game/animals/cat.png',
    homeAsset: 'assets/images/level_game/cat-house.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_rounded,
    color: TudloColors.coral,
  );
  const chicken = _AnimalWord(
    hil: 'manok',
    eng: 'manok',
    soundText: 'tok tok',
    tapSpeech: 'Manok. Ang manok nagapotok.',
    dragHomeLabel: 'tangkal',
    imageAsset: 'assets/images/level_game/animals/chicken.png',
    homeAsset: 'assets/images/level_game/chicken-house.png',
    icon: Icons.egg_alt_rounded,
    homeIcon: Icons.home_work_rounded,
    color: TudloColors.gold,
  );
  const pig = _AnimalWord(
    hil: 'baboy',
    eng: 'baboy',
    soundText: 'oynk oynk',
    tapSpeech: 'Baboy. Ang baboy naga-ukoy.',
    dragHomeLabel: 'iya kulungan',
    imageAsset: 'assets/images/level_game/animals/pig.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_work_rounded,
    color: TudloColors.coral,
  );
  const cow = _AnimalWord(
    hil: 'baka',
    eng: 'baka',
    soundText: 'moo',
    tapSpeech: 'Baka. Ang baka nagangaaw.',
    dragHomeLabel: 'hilamunan',
    imageAsset: 'assets/images/level_game/animals/cow.png',
    icon: Icons.agriculture_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.blue,
  );
  const carabao = _AnimalWord(
    hil: 'karbaw',
    eng: 'karbaw',
    soundText: 'ngaa',
    tapSpeech: 'Karbaw. Ang karbaw nagahuni.',
    dragHomeLabel: 'palayan',
    imageAsset: 'assets/images/level_game/animals/carabao.png',
    icon: Icons.agriculture_rounded,
    homeIcon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fish = _AnimalWord(
    hil: 'isda',
    eng: 'isda',
    soundText: 'bulubula',
    tapSpeech: 'Isda. Ang isda nagalangoy.',
    dragHomeLabel: 'tubig',
    imageAsset: 'assets/images/level_game/animals/fish.png',
    icon: Icons.water_rounded,
    homeIcon: Icons.water_rounded,
    color: TudloColors.blue,
  );
  const bird = _AnimalWord(
    hil: 'pispis',
    eng: 'pispis',
    soundText: 'tsirit tsirit',
    tapSpeech: 'Pispis. Ang pispis nagahuni.',
    dragHomeLabel: 'iya pugad',
    imageAsset: 'assets/images/level_game/animals/bird.png',
    icon: Icons.flutter_dash_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.green,
  );
  const goat = _AnimalWord(
    hil: 'kanding',
    eng: 'kanding',
    soundText: 'mee mee',
    tapSpeech: 'Kanding. Ang kanding nagame.',
    dragHomeLabel: 'hilamunan',
    imageAsset: 'assets/images/level_game/animals/goat.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.meadow,
  );

  return switch (lessonNumber) {
    1 => const [dog, cat, chicken],
    2 => const [pig, cow, carabao],
    3 => const [fish, bird, goat],
    _ => const [dog, cat, chicken, pig, cow, carabao, fish, bird, goat],
  };
}

String _titleCase(String value) {
  if (value.trim().isEmpty) return value;
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        final letters = word.characters.toList();
        if (letters.isEmpty) return '';
        return '${letters.first.toUpperCase()}${letters.skip(1).join().toLowerCase()}';
      })
      .join(' ');
}
