import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/animated_point_finger.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/lesson_game/widgets/reward_overlay.dart';

const _newStudentRoot =
    'assets/images/level_game/grade3/G3_U2_L2.2_Ang_Bag-o_nga_Estudyante';
const _classroomLandscape =
    'assets/images/level_game/backgrounds/grade3_landscape/ClassroomLandscape 1.svg';
const _pointFinger =
    'assets/images/level_game/lesson-game-assets/point-finger.png';
const _anaShy = '$_newStudentRoot/character_ana_shy_transparent.png';
const _anaSad =
    '$_newStudentRoot/character_ana_sad_head_lowered_transparent.png';
const _anaSitting = '$_newStudentRoot/character_ana_sitting.png';
const _anaLookingAtJuan =
    '$_newStudentRoot/character_ana_looking_at_juan_transparent.png';
const _juan = '$_newStudentRoot/character_juan_neutral_transparent_final.png';

enum _NewStudentStage {
  intro,
  map,
  search,
  observe,
  emotion,
  problem,
  action,
  model,
  sequence,
  welcome,
  reward,
}

class GradeThreeNewStudentFlow extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onLessonComplete;
  final VoidCallback onBackToMap;
  final VoidCallback onContinue;
  final String rewardStickerAsset;

  const GradeThreeNewStudentFlow({
    super.key,
    required this.onExit,
    required this.onLessonComplete,
    required this.onBackToMap,
    required this.onContinue,
    required this.rewardStickerAsset,
  });

  @override
  State<GradeThreeNewStudentFlow> createState() =>
      _GradeThreeNewStudentFlowState();
}

class _GradeThreeNewStudentFlowState extends State<GradeThreeNewStudentFlow> {
  _NewStudentStage _stage = _NewStudentStage.intro;
  String? _wrongId;
  String? _correctId;
  int _wrongPulse = 0;
  int _voiceRun = 0;
  bool _emotionChoicesEnabled = false;
  bool _recallChoicesEnabled = false;
  final List<String?> _sequenceSlots = List<String?>.filled(3, null);
  bool _completedSent = false;
  SharedPreferences? _prefs;
  late String _saveKey;

  double get _progress =>
      (_NewStudentStage.values.indexOf(_stage) + 1) /
      _NewStudentStage.values.length;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefs != null) return;
    _saveKey =
        'newstudent.g3.u2.l2.2.${AppStateScope.of(context).activeProfileId ?? 'guest'}';
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _prefs = prefs;
    final rawStage = prefs.getString('$_saveKey.stage');
    if (rawStage != null) {
      _stage = _NewStudentStage.values.firstWhere(
        (stage) => stage.name == rawStage,
        orElse: () => _NewStudentStage.intro,
      );
      _correctId = prefs.getString('$_saveKey.correctId');
      final slots = prefs.getStringList('$_saveKey.sequenceSlots');
      if (slots != null && slots.length == 3) {
        for (var i = 0; i < 3; i++) {
          _sequenceSlots[i] = slots[i].isEmpty ? null : slots[i];
        }
      }
      _completedSent =
          prefs.getBool('$_saveKey.completedCallbackSent') ?? false;
    }
    setState(() {});
    unawaited(_playStageVoice());
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_saveKey, true);
    await prefs.setString('$_saveKey.stage', _stage.name);
    if (_correctId == null) {
      await prefs.remove('$_saveKey.correctId');
    } else {
      await prefs.setString('$_saveKey.correctId', _correctId!);
    }
    await prefs.setStringList('$_saveKey.sequenceSlots', [
      for (final value in _sequenceSlots) value ?? '',
    ]);
    await prefs.setBool('$_saveKey.completedCallbackSent', _completedSent);
  }

  Future<void> _playClip(int clip) => _playClips([clip]);

  Future<void> _playClips(List<int> clips) async {
    if (!AppAudioService.instance.voiceOverEnabled) return;
    final run = ++_voiceRun;
    await TudloVoiceButton.stop();
    if (run != _voiceRun) return;
    await AppAudioService.instance.lowerBackgroundVolume();
    if (run != _voiceRun) return;
    try {
      if (run != _voiceRun) return;
      await AppAudioService.instance.playVoiceAssets([
        for (final clip in clips)
          'audio/VO-final/grade3/Gr_3_Les_2_2_$clip.wav',
      ]);
    } finally {
      if (run == _voiceRun) {
        await AppAudioService.instance.restoreBackgroundVolume();
      }
    }
  }

  Future<void> _playStageVoice() {
    if (_stage == _NewStudentStage.emotion) {
      return _playEmotionPromptSequence();
    }
    if (_stage == _NewStudentStage.problem) {
      return _playRecallPromptSequence();
    }
    if (_stage == _NewStudentStage.model) {
      return _playClips(const [24, 25]);
    }
    if (_stage == _NewStudentStage.search) {
      return _playClips(const [4, 5]);
    }
    if (_stage == _NewStudentStage.welcome) {
      return _playClips(const [29, 30]);
    }
    final clip = switch (_stage) {
      _NewStudentStage.intro => 2,
      _NewStudentStage.map => 3,
      _NewStudentStage.search => 5,
      _NewStudentStage.observe => 5,
      _NewStudentStage.emotion => 10,
      _NewStudentStage.problem => 14,
      _NewStudentStage.action => 19,
      _NewStudentStage.model => 25,
      _NewStudentStage.sequence => 26,
      _NewStudentStage.welcome => 30,
      _NewStudentStage.reward => 31,
    };
    return _playClip(clip);
  }

  Future<void> _playEmotionPromptSequence() async {
    if (mounted) {
      setState(() => _emotionChoicesEnabled = false);
    }
    await _playClips(const [7, 8, 9, 10]);
    if (!mounted || _stage != _NewStudentStage.emotion) return;
    setState(() => _emotionChoicesEnabled = true);
  }

  Future<void> _playRecallPromptSequence() async {
    if (mounted) {
      setState(() => _recallChoicesEnabled = false);
    }
    await _playClips(const [13, 14]);
    if (!mounted || _stage != _NewStudentStage.problem) return;
    setState(() => _recallChoicesEnabled = true);
  }

  void _go(_NewStudentStage next, {bool voice = true}) {
    setState(() {
      _stage = next;
      _wrongId = null;
      _correctId = null;
      _emotionChoicesEnabled = next != _NewStudentStage.emotion;
      _recallChoicesEnabled = next != _NewStudentStage.problem;
    });
    unawaited(_save());
    if (voice) unawaited(_playStageVoice());
  }

  Future<void> _choose(String id, String answer, _NewStudentStage next) async {
    if (_stage == _NewStudentStage.emotion && !_emotionChoicesEnabled) return;
    if (_stage == _NewStudentStage.problem && !_recallChoicesEnabled) return;
    if (_correctId != null) return;
    if (id != answer) {
      setState(() {
        _wrongId = id;
        _wrongPulse++;
      });
      await AppAudioService.instance.playWrong();
      if (_stage == _NewStudentStage.problem) {
        await _playClips(const [17, 18]);
      } else {
        await _playClip(_stage == _NewStudentStage.emotion ? 12 : 10);
      }
      if (mounted) setState(() => _wrongId = null);
      return;
    }
    setState(() => _correctId = id);
    unawaited(_save());
    await AppAudioService.instance.playCorrect();
    await _playClip(
      _stage == _NewStudentStage.action
          ? 20
          : _stage == _NewStudentStage.problem
          ? 16
          : 11,
    );
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (mounted && _stage != next) _go(next);
  }

  Future<void> _placeEvent(String event, int slot) async {
    const answer = ['afraid', 'greeted', 'friends'];
    if (_sequenceSlots[slot] != null) return;
    setState(() {
      _sequenceSlots[slot] = event;
    });
    unawaited(_save());
    if (_sequenceSlots.any((value) => value == null)) return;
    final correct = _sequenceSlots.indexed.every((entry) {
      return entry.$2 == answer[entry.$1];
    });
    if (correct) {
      await AppAudioService.instance.playCorrect();
      await _playClip(27);
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (mounted) _go(_NewStudentStage.welcome);
      return;
    }
    await AppAudioService.instance.playWrong();
    setState(() {
      for (var i = 0; i < _sequenceSlots.length; i++) {
        if (_sequenceSlots[i] != answer[i]) _sequenceSlots[i] = null;
      }
      _wrongPulse++;
    });
    await _playClip(28);
  }

  void _collectRewardAndContinue() {
    if (!_completedSent) {
      _completedSent = true;
      widget.onLessonComplete();
      unawaited(_save());
    }
    widget.onContinue();
  }

  void _collectRewardAndMap() {
    if (!_completedSent) {
      _completedSent = true;
      widget.onLessonComplete();
      unawaited(_save());
    }
    widget.onBackToMap();
  }

  @override
  Widget build(BuildContext context) {
    return _NewStudentChrome(
      progress: _progress,
      onExit: widget.onExit,
      onReplay: _playStageVoice,
      child: switch (_stage) {
        _NewStudentStage.intro => _IntroPage(
          onStart: () => _go(_NewStudentStage.map),
        ),
        _NewStudentStage.map => _MapPage(
          onSchool: () => _go(_NewStudentStage.search),
          onLocked: () => setState(() => _wrongPulse++),
          wrongPulse: _wrongPulse,
        ),
        _NewStudentStage.search => _SearchPage(
          onFind: () => _go(_NewStudentStage.observe, voice: false),
        ),
        _NewStudentStage.observe => _ObservePage(
          onNext: () => _go(_NewStudentStage.emotion),
        ),
        _NewStudentStage.emotion => _EmotionPage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          choicesEnabled: _emotionChoicesEnabled,
          onChoose: (id) =>
              unawaited(_choose(id, 'sad', _NewStudentStage.problem)),
        ),
        _NewStudentStage.problem => _ProblemPage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          choicesEnabled: _recallChoicesEnabled,
          onChoose: (id) =>
              unawaited(_choose(id, 'new_alone', _NewStudentStage.action)),
        ),
        _NewStudentStage.action => _ActionPage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          onChoose: (id) =>
              unawaited(_choose(id, 'greet_include', _NewStudentStage.model)),
        ),
        _NewStudentStage.model => _ModelPage(
          onNext: () => _go(_NewStudentStage.sequence),
        ),
        _NewStudentStage.sequence => _SequencePage(
          slots: _sequenceSlots,
          wrongPulse: _wrongPulse,
          onDrop: (event, slot) => unawaited(_placeEvent(event, slot)),
        ),
        _NewStudentStage.welcome => _WelcomeAnaPage(
          onNext: () => _go(_NewStudentStage.reward),
        ),
        _NewStudentStage.reward => GradeThreeStickerRewardOverlay(
          stickerAsset: widget.rewardStickerAsset,
          message: 'Welcome, Ana!\nMaayo gid ang imo paghangop.',
          primaryLabel: 'PADAYON',
          onPrimary: _collectRewardAndContinue,
          secondaryLabel: 'BALIK SA MAPA',
          onSecondary: _collectRewardAndMap,
        ),
      },
    );
  }
}

class _NewStudentChrome extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;

  const _NewStudentChrome({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return ColoredBox(
      color: const Color(0xFFAEE8F8),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              left: 14,
              top: 10,
              child: _RoundControl(
                icon: Icons.arrow_back_rounded,
                color: const Color(0xFF1BA7F2),
                onTap: onExit,
              ),
            ),
            Positioned(
              left: view.width * .28,
              right: view.width * .28,
              top: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 16,
                  value: progress.clamp(0, 1),
                  backgroundColor: Colors.white.withValues(alpha: .92),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF67D600)),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 10,
              child: _RoundControl(
                icon: Icons.volume_up_rounded,
                color: Colors.white,
                iconColor: TudloColors.green,
                onTap: onReplay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoundControl({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 34),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final VoidCallback onStart;

  const _IntroPage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final kokaSize = (view.width * .42).clamp(315.0, 430.0);
    final anaWidth = (view.width * .36).clamp(285.0, 390.0);
    final anaHeight = (view.height * .72).clamp(385.0, 500.0);

    return Stack(
      children: [
        const Positioned.fill(child: _SoftClassroomBackground()),
        Positioned(
          left: view.width * .10,
          right: view.width * .10,
          top: (view.height * .12).clamp(76.0, 92.0),
          child: const _PromptBubble(
            text: 'Bag-o si Ana sa eskwelahan. Buligan ta siya.',
          ),
        ),
        Positioned(
          left: view.width * .16,
          bottom: -view.height * .04,
          child: _Koka(size: kokaSize),
        ),
        Positioned(
          right: view.width * .15,
          bottom: -view.height * .11,
          width: anaWidth,
          height: anaHeight,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: Image.asset(_anaSad, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          left: view.width * .18,
          right: view.width * .18,
          bottom: view.height * .04,
          child: _BlueGreenButton(label: 'SUGODAN TA', onTap: onStart),
        ),
      ],
    );
  }
}

class _MapPage extends StatelessWidget {
  final VoidCallback onSchool;
  final VoidCallback onLocked;
  final int wrongPulse;

  const _MapPage({
    required this.onSchool,
    required this.onLocked,
    required this.wrongPulse,
  });

  @override
  Widget build(BuildContext context) {
    return _SceneShell(
      prompt: 'I-tap ang School.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MapLocationCard(
            label: 'SCHOOL',
            icon: Icons.school_rounded,
            active: true,
            onTap: onSchool,
          ),
          for (final item in const [
            ('BALAY', Icons.home_rounded),
            ('MARKET', Icons.storefront_rounded),
            ('FARM', Icons.agriculture_rounded),
          ])
            _MapLocationCard(
              label: item.$1,
              icon: item.$2,
              active: false,
              onTap: onLocked,
            ),
        ],
      ),
    );
  }
}

class _SearchPage extends StatelessWidget {
  final VoidCallback onFind;

  const _SearchPage({required this.onFind});

  @override
  Widget build(BuildContext context) {
    return _ClassroomFrame(
      prompt: 'Pangitaa si Ana.',
      child: Stack(
        children: [
          const Positioned(left: 150, bottom: -8, child: _Koka(size: 285)),
          Positioned(
            right: 120,
            bottom: 10,
            width: 255,
            height: 360,
            child: Image.asset(_anaShy, fit: BoxFit.contain),
          ),
          Positioned(
            right: 122,
            bottom: 6,
            width: 265,
            height: 355,
            child: GestureDetector(
              onTap: onFind,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            right: 118,
            bottom: 226,
            child: GestureDetector(
              onTap: onFind,
              child: const AnimatedPointFinger(
                asset: _pointFinger,
                size: 78,
                angle: -.22,
                tapOffset: Offset(10, -4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservePage extends StatelessWidget {
  final VoidCallback onNext;

  const _ObservePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _ClassroomFrame(
      prompt: 'Nagaisahanon si Ana. Ano ang iya nabatyagan?',
      footer: _BlueGreenButton(label: 'SUNOD', onTap: onNext),
      child: Stack(
        children: [
          const Positioned(left: 150, bottom: -8, child: _Koka(size: 285)),
          Positioned(
            right: 120,
            bottom: 10,
            width: 255,
            height: 360,
            child: Image.asset(_anaSad, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _EmotionPage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final bool choicesEnabled;
  final ValueChanged<String> onChoose;

  const _EmotionPage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.choicesEnabled,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return _ClassroomFrame(
      prompt: 'Ano ang nabatyagan ni Ana?',
      child: Stack(
        children: [
          Positioned(
            left: 92,
            bottom: 14,
            width: 300,
            height: 420,
            child: Image.asset(_anaSad, fit: BoxFit.contain),
          ),
          Positioned(
            right: 48,
            top: 42,
            width: 335,
            child: Column(
              children: [
                _ChoiceCard(
                  id: 'happy',
                  label: 'Happy',
                  correct: correctId == 'happy',
                  wrong: wrongId == 'happy',
                  pulse: wrongPulse,
                  enabled: choicesEnabled,
                  onTap: onChoose,
                ),
                _ChoiceCard(
                  id: 'sad',
                  label: 'Sad',
                  correct: correctId == 'sad',
                  wrong: wrongId == 'sad',
                  pulse: wrongPulse,
                  enabled: choicesEnabled,
                  onTap: onChoose,
                ),
                _ChoiceCard(
                  id: 'angry',
                  label: 'Angry',
                  correct: correctId == 'angry',
                  wrong: wrongId == 'angry',
                  pulse: wrongPulse,
                  enabled: choicesEnabled,
                  onTap: onChoose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemPage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final bool choicesEnabled;
  final ValueChanged<String> onChoose;

  const _ProblemPage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.choicesEnabled,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return _ClassroomFrame(
      prompt: 'Dumdumon ta: Ngaa masubo si Ana?',
      child: Stack(
        children: [
          Positioned(
            left: 70,
            bottom: 74,
            width: 245,
            height: 255,
            child: Opacity(
              opacity: .42,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(_juan, height: 150, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  const _Koka(size: 130),
                ],
              ),
            ),
          ),
          Positioned(
            left: 64,
            bottom: 26,
            width: 250,
            height: 315,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFE477).withValues(alpha: .62),
                    blurRadius: 36,
                    spreadRadius: 16,
                  ),
                ],
              ),
              child: Image.asset(_anaSitting, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            right: 34,
            top: 12,
            width: 430,
            child: Column(
              children: [
                _ChoiceCard(
                  id: 'new_alone',
                  label: 'Bag-o si Ana sa eskwelahan kag wala pa siya upod.',
                  correct: correctId == 'new_alone',
                  wrong: wrongId == 'new_alone',
                  pulse: wrongPulse,
                  enabled: choicesEnabled,
                  fontSize: 18,
                  onTap: onChoose,
                ),
                _ChoiceCard(
                  id: 'lost_book',
                  label: 'Nalipat si Ana sang iya libro.',
                  correct: correctId == 'lost_book',
                  wrong: wrongId == 'lost_book',
                  pulse: wrongPulse,
                  enabled: choicesEnabled,
                  fontSize: 20,
                  onTap: onChoose,
                ),
                _ChoiceCard(
                  id: 'play_alone',
                  label: 'Gusto ni Ana magdula nga siya lang.',
                  correct: correctId == 'play_alone',
                  wrong: wrongId == 'play_alone',
                  pulse: wrongPulse,
                  enabled: choicesEnabled,
                  fontSize: 20,
                  onTap: onChoose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final ValueChanged<String> onChoose;

  const _ActionPage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return _ClassroomFrame(
      prompt: 'Pilia ang maayo kag mabuot nga himuon.',
      child: Stack(
        children: [
          Positioned(
            left: 92,
            bottom: 14,
            width: 300,
            height: 420,
            child: Image.asset(_anaShy, fit: BoxFit.contain),
          ),
          Positioned(
            right: 48,
            top: 42,
            width: 335,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChoiceCard(
                  id: 'greet_include',
                  label: 'Kumustahon kag updan',
                  correct: correctId == 'greet_include',
                  wrong: wrongId == 'greet_include',
                  pulse: wrongPulse,
                  onTap: onChoose,
                ),
                _ChoiceCard(
                  id: 'ignore',
                  label: 'Pasagdan',
                  correct: correctId == 'ignore',
                  wrong: wrongId == 'ignore',
                  pulse: wrongPulse,
                  onTap: onChoose,
                ),
                _ChoiceCard(
                  id: 'walk',
                  label: 'Laktan lang',
                  correct: correctId == 'walk',
                  wrong: wrongId == 'walk',
                  pulse: wrongPulse,
                  onTap: onChoose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelPage extends StatelessWidget {
  final VoidCallback onNext;

  const _ModelPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _SceneShell(
      prompt:
          'Una nahadlok siya. Sunod, ginkumusta siya. Katapusan, may mga abyan siya.',
      footer: _BlueGreenButton(label: 'SUNOD', onTap: onNext),
      child: Center(
        child: SizedBox(
          height: 300,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _EventPanel(event: 'afraid')),
              SizedBox(
                width: 50,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF1BA7F2),
                  size: 62,
                ),
              ),
              Expanded(child: _EventPanel(event: 'greeted')),
              SizedBox(
                width: 50,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF1BA7F2),
                  size: 62,
                ),
              ),
              Expanded(child: _EventPanel(event: 'friends')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SequencePage extends StatelessWidget {
  final List<String?> slots;
  final int wrongPulse;
  final void Function(String event, int slot) onDrop;

  const _SequencePage({
    required this.slots,
    required this.wrongPulse,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final placed = slots.whereType<String>().toSet();
    return _SceneShell(
      prompt: 'Ihan-ay ang una, sunod, kag katapusan nga hitabo.',
      child: Column(
        children: [
          SizedBox(
            height: 235,
            child: Row(
              children: [
                for (final entry in const ['UNA', 'SUNOD', 'KATAPUSAN'].indexed)
                  Expanded(
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (_) => slots[entry.$1] == null,
                      onAcceptWithDetails: (details) {
                        onDrop(details.data, entry.$1);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return _SequenceSlot(
                          title: entry.$2,
                          event: slots[entry.$1],
                          wrongPulse: wrongPulse,
                          highlighted: candidateData.isNotEmpty,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 116,
            child: Row(
              children: [
                for (final event in const ['greeted', 'friends', 'afraid'])
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: placed.contains(event) ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: placed.contains(event),
                        child: Draggable<String>(
                          data: event,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 210,
                              height: 110,
                              child: _EventTile(event: event),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: .35,
                            child: _EventTile(event: event),
                          ),
                          child: _EventTile(event: event),
                        ),
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
}

class _WelcomeAnaPage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeAnaPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _ClassroomFrame(
      prompt:
          'Welcome sa aton classroom, Ana! Salamat! Nalipat gid ako nga may bag-o na ako nga abyan.',
      footer: _BlueGreenButton(label: 'SUNOD', onTap: onNext),
      child: Stack(
        children: [
          Positioned(
            left: 230,
            bottom: 16,
            width: 250,
            height: 350,
            child: Image.asset(_anaLookingAtJuan, fit: BoxFit.contain),
          ),
          const Positioned(left: 430, bottom: 22, child: _Koka(size: 205)),
        ],
      ),
    );
  }
}

class _SceneShell extends StatelessWidget {
  final String prompt;
  final Widget child;
  final Widget? footer;

  const _SceneShell({required this.prompt, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned.fill(child: _SoftClassroomBackground()),
        Positioned(
          left: view.width * .10,
          right: view.width * .10,
          top: view.height * .09,
          child: _PromptBubble(text: prompt),
        ),
        Positioned(
          left: view.width * .06,
          right: view.width * .06,
          top: view.height * .23,
          bottom: footer == null ? view.height * .06 : view.height * .18,
          child: child,
        ),
        if (footer != null)
          Positioned(
            left: view.width * .18,
            right: view.width * .18,
            bottom: view.height * .055,
            child: footer!,
          ),
      ],
    );
  }
}

class _ClassroomFrame extends StatelessWidget {
  final String prompt;
  final Widget child;
  final Widget? footer;

  const _ClassroomFrame({
    required this.prompt,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return _SceneShell(prompt: prompt, footer: footer, child: child);
  }
}

class _SoftClassroomBackground extends StatelessWidget {
  const _SoftClassroomBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SvgPicture.asset(_classroomLandscape, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06)),
        ),
      ],
    );
  }
}

class _PromptBubble extends StatelessWidget {
  final String text;

  const _PromptBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAE7).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: (width * .03).clamp(23.0, 34.0),
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BlueGreenButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BlueGreenButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1BA7F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _Koka extends StatelessWidget {
  final double size;

  const _Koka({required this.size});

  @override
  Widget build(BuildContext context) {
    return TudloMascot(size: size, mood: KokaMood.idle);
  }
}

class _MapLocationCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _MapLocationCard({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFE5E8EF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active ? const Color(0xFF1BA7F2) : Colors.grey.shade500,
              width: 5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD33D).withValues(alpha: .62),
                      blurRadius: 26,
                      spreadRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? icon : Icons.lock_rounded,
                color: active ? const Color(0xFF1BA7F2) : Colors.grey.shade700,
                size: 76,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 24,
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

class _ChoiceCard extends StatelessWidget {
  final String id;
  final String label;
  final bool correct;
  final bool wrong;
  final int pulse;
  final bool enabled;
  final double fontSize;
  final ValueChanged<String> onTap;

  const _ChoiceCard({
    required this.id,
    required this.label,
    required this.correct,
    required this.wrong,
    required this.pulse,
    this.enabled = true,
    this.fontSize = 25,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      key: ValueKey('$id-$pulse-$wrong-$correct'),
      scale: correct ? 1.05 : 1,
      duration: const Duration(milliseconds: 160),
      child: _FeedbackMotion(
        correct: correct,
        wrong: wrong,
        child: IgnorePointer(
          ignoring: !enabled,
          child: GestureDetector(
            onTap: () => onTap(id),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: wrong ? const Color(0xFFFFF1EC) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: correct
                      ? TudloColors.green
                      : wrong
                      ? TudloColors.coral
                      : const Color(0xFF1BA7F2),
                  width: 5,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: fontSize,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackMotion extends StatelessWidget {
  final bool correct;
  final bool wrong;
  final Widget child;

  const _FeedbackMotion({
    required this.correct,
    required this.wrong,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (correct || wrong) ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      child: child,
      builder: (context, value, child) {
        final shakeOffset = wrong
            ? math.sin(value * math.pi * 6) * (1 - value) * 9
            : 0.0;
        final jumpOffset = correct
            ? -math.sin(value * math.pi) * (1 - value * .25) * 10
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, jumpOffset),
          child: child,
        );
      },
    );
  }
}

class _EventPanel extends StatelessWidget {
  final String event;

  const _EventPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC928), width: 4),
      ),
      child: Column(
        children: [
          Expanded(child: _EventImage(event: event)),
          Text(
            switch (event) {
              'afraid' => 'Hadlok',
              'greeted' => 'Ginkumusta',
              _ => 'May abyan',
            },
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final String event;

  const _EventImage({required this.event});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final characterHeight = constraints.maxHeight * .86;
        return Align(
          alignment: Alignment.bottomCenter,
          child: switch (event) {
            'afraid' => Image.asset(
              _anaSad,
              height: characterHeight,
              fit: BoxFit.contain,
            ),
            'greeted' => Image.asset(
              _anaShy,
              height: characterHeight,
              fit: BoxFit.contain,
            ),
            _ => SizedBox(
              width: constraints.maxWidth,
              height: characterHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: constraints.maxWidth * .08,
                    bottom: 0,
                    height: characterHeight,
                    child: Image.asset(_anaLookingAtJuan, fit: BoxFit.contain),
                  ),
                  Positioned(
                    left: constraints.maxWidth * .34,
                    bottom: -characterHeight * .08,
                    child: _Koka(size: characterHeight * .96),
                  ),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}

class _SequenceSlot extends StatelessWidget {
  final String title;
  final String? event;
  final int wrongPulse;
  final bool highlighted;

  const _SequenceSlot({
    required this.title,
    required this.event,
    required this.wrongPulse,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFE9F8FF)
            : Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1BA7F2), width: 5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1BA7F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: event == null
                ? Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .62),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1BA7F2).withValues(alpha: .45),
                        width: 2,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: _EventImage(event: event!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final String event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC928), width: 5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 76, child: _EventImage(event: event)),
          const SizedBox(width: 12),
          Text(
            _sequenceEventLabel(event),
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _sequenceEventLabel(String event) {
  return switch (event) {
    'afraid' => 'Afraid',
    'greeted' => 'Greeted',
    _ => 'Friends',
  };
}
