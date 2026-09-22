import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/vendor/devg/core/services/app_audio_service.dart';
import 'package:tudloapp/vendor/devg/core/services/lesson_number_voice_service.dart';
import 'package:tudloapp/vendor/devg/core/theme/app_theme.dart';
import 'package:tudloapp/vendor/devg/core/widgets/animated_point_finger.dart';
import 'package:tudloapp/vendor/devg/core/widgets/mascot_widget.dart';
import 'package:tudloapp/vendor/devg/features/lesson_game/widgets/reward_overlay.dart';

const String _marketRoot =
    'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets';
const String _marketBg = '$_marketRoot/background/MarketLandscape.svg';
const String _fruitStall = '$_marketRoot/stalls/Stall_Fruit_Empty.svg';
const String _vendor = '$_marketRoot/people/Vendor_Female.svg';
const String _pointFinger =
    'assets/images/level_game/lesson-game-assets/point-finger.png';
const String _apple = 'assets/images/level_game/apple.png';
const String _crate = '$_marketRoot/inventory/Produce_Crate_Empty.svg';
const String _displayTray = '$_marketRoot/inventory/Display_Tray_Empty.svg';
const Duration _marketCompletionHold = Duration(seconds: 3);
const double _g3DialogueX = 96;
const double _g3DialogueY = 56;
const double _g3DialogueWidth = 768;
const double _g3DialogueHeight = 64;

enum _MarketState {
  intro,
  map,
  stall,
  numberTeach,
  numberExplore,
  appleModel,
  guidedCount,
  question,
  setupOrder,
  arrangeOrder,
  reward,
}

class GradeThreeMarketNumbersFlow extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onLessonComplete;
  final String rewardStickerAsset;

  const GradeThreeMarketNumbersFlow({
    super.key,
    required this.onExit,
    required this.onLessonComplete,
    required this.rewardStickerAsset,
  });

  @override
  State<GradeThreeMarketNumbersFlow> createState() =>
      _GradeThreeMarketNumbersFlowState();
}

class _GradeThreeMarketNumbersFlowState
    extends State<GradeThreeMarketNumbersFlow>
    with WidgetsBindingObserver {
  static const _answer = 5;
  static const _targetOrder = [6, 7, 8, 9, 10];

  var _initialized = false;
  _MarketState _state = _MarketState.intro;
  final Set<int> _heardNumbers = {};
  final Set<int> _placedApples = {};
  final Set<int> _lockedSlots = {};
  final List<int?> _orderSlots = List<int?>.filled(5, null);
  final List<int> _orderTray = [8, 6, 10, 7, 9];
  int? _wrongChoice;
  int? _correctChoice;
  int? _selectedTile;
  int _wrongPulse = 0;
  bool _busy = true;
  bool _rewardCollected = false;
  bool _completedCallbackSent = false;
  late final String _rewardStickerAsset = widget.rewardStickerAsset;

  double get _progress =>
      (_MarketState.values.indexOf(_state) + 1) / _MarketState.values.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      unawaited(_restore());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(AppAudioService.instance.stopVoice());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(AppAudioService.instance.stopVoice());
    super.dispose();
  }

  Future<void> _restore() async {
    if (!mounted) return;
    setState(() => _busy = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playStateVoice());
    });
  }

  /// Tudlo persists the final reward claim only; this activity always starts
  /// fresh after an exit or app restart.
  Future<void> _save() async {}

  Future<void> _playClip(int clip) async {
    if (!AppAudioService.instance.voiceOverEnabled) return;
    await AppAudioService.instance.lowerBackgroundVolume();
    try {
      await AppAudioService.instance.playVoiceAssets([
        'audio/VO-final/grade3/Gr_3_Les_1_1_$clip.wav',
      ]);
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  int _clipForState() {
    return switch (_state) {
      _MarketState.intro => 1,
      _MarketState.map => 3,
      _MarketState.stall => 4,
      _MarketState.numberTeach => 6,
      _MarketState.numberExplore => 7,
      _MarketState.appleModel => 8,
      _MarketState.guidedCount => 8,
      _MarketState.question => 10,
      _MarketState.setupOrder => 16,
      _MarketState.arrangeOrder => 21,
      _MarketState.reward => 25,
    };
  }

  Future<void> _playStateVoice() {
    if (_state == _MarketState.numberTeach) return _playNumberIntroSequence();
    return _playClip(_clipForState());
  }

  Future<void> _playNumberIntroSequence() async {
    if (mounted) setState(() => _busy = true);
    await _playClip(5);
    await _playClip(6);
    await _playClip(7);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _go(_MarketState next, {bool voice = true}) async {
    if (_busy) return;
    setState(() {
      _state = next;
      _wrongChoice = null;
      _correctChoice = null;
      _selectedTile = null;
      _busy = voice;
    });
    await _save();
    if (voice) {
      await _playStateVoice();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wrong({int? choice}) async {
    setState(() {
      _wrongChoice = choice;
      _wrongPulse++;
      _busy = true;
    });
    unawaited(AppAudioService.instance.playWrong());
    await _playClip(12);
    if (!mounted) return;
    setState(() {
      _wrongChoice = null;
      _busy = false;
    });
  }

  Future<void> _activateMarket() async {
    await _go(_MarketState.map);
  }

  Future<void> _tapMarket() async {
    await _go(_MarketState.stall);
  }

  Future<void> _tapStall() async {
    if (_busy) return;
    setState(() {
      _state = _MarketState.numberTeach;
      _wrongChoice = null;
      _correctChoice = null;
      _selectedTile = null;
      _busy = true;
    });
    await _save();
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    await _playNumberIntroSequence();
  }

  Future<void> _tapNumber(int number) async {
    if (_busy) return;
    setState(() {
      _heardNumbers.add(number);
      _busy = true;
    });
    await AppAudioService.instance.playTap();
    await playLessonNumberVoice(number);
    await _save();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _placeApple(int appleId) async {
    if (_busy || _placedApples.contains(appleId)) return;
    setState(() {
      _busy = true;
      _placedApples.add(appleId);
    });
    await AppAudioService.instance.playTap();
    await playLessonNumberVoice(_placedApples.length);
    await _save();
    if (!mounted) return;
    setState(() => _busy = false);
    if (_placedApples.length == 5) {
      setState(() => _busy = true);
      await _playClip(11);
      if (!mounted) return;
      setState(() => _busy = false);
      await _go(_MarketState.question);
    }
  }

  Future<void> _chooseAnswer(int choice) async {
    if (_busy || _correctChoice != null) return;
    if (choice != _answer) {
      await _wrong(choice: choice);
      return;
    }
    setState(() {
      _correctChoice = choice;
      _busy = true;
    });
    await AppAudioService.instance.playCorrect();
    await _playClip(11);
    await _save();
    if (!mounted) return;
    setState(() => _busy = false);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) await _go(_MarketState.setupOrder);
  }

  Future<void> _placeNumber(int number, int slot) async {
    if (_busy || _lockedSlots.length == _targetOrder.length) return;
    final expected = _targetOrder[slot];
    if (number != expected) {
      await _wrongOrderNumber(number);
      return;
    }
    setState(() {
      final previous = _orderSlots.indexOf(number);
      if (previous != -1) _orderSlots[previous] = null;
      _orderSlots[slot] = number;
      if (_orderSlots.indexed.every(
        (entry) => entry.$2 == _targetOrder[entry.$1],
      )) {
        _lockedSlots.addAll(List<int>.generate(_targetOrder.length, (i) => i));
      }
      _selectedTile = null;
    });
    await AppAudioService.instance.playCorrect();
    await playLessonNumberVoice(number);
    await _save();
    if (_lockedSlots.length == 5) {
      await _playClip(22);
      if (mounted) await _openStall();
    }
  }

  Future<void> _wrongOrderNumber(int number) async {
    setState(() {
      _wrongChoice = number;
      _wrongPulse++;
      _busy = true;
    });
    unawaited(AppAudioService.instance.playWrong());
    await _playClip(23);
    await _playClip(24);
    if (!mounted) return;
    setState(() {
      _wrongChoice = null;
      _busy = false;
    });
  }

  Future<void> _openStall() async {
    if (_busy || _lockedSlots.length != 5) return;
    setState(() => _busy = true);
    await AppAudioService.instance.playCorrect();
    await _playClip(25);
    await _save();
    if (!mounted) return;
    setState(() => _busy = false);
    await Future<void>.delayed(_marketCompletionHold);
    if (!mounted) return;
    await _go(_MarketState.reward, voice: false);
  }

  Future<void> _collectReward() async {
    if (_busy || _rewardCollected) return;
    setState(() {
      _busy = true;
      _rewardCollected = true;
    });
    await _save();
    await AppAudioService.instance.playStar();
    if (!_completedCallbackSent) {
      _completedCallbackSent = true;
      widget.onLessonComplete();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF92DCF9),
      child: Stack(
        children: [
          Positioned.fill(child: _asset(_marketBg, fit: BoxFit.cover)),
          _topChrome(),
          ..._scene(),
        ],
      ),
    );
  }

  Widget _topChrome() {
    return Stack(
      children: [
        _at(24, 22, 52, 52, _roundIcon(Icons.arrow_back, widget.onExit)),
        _at(
          330,
          24,
          300,
          22,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress,
              color: TudloColors.green,
              backgroundColor: Colors.white.withValues(alpha: .85),
            ),
          ),
        ),
        _at(884, 22, 52, 52, _roundIcon(Icons.volume_up, _playStateVoice)),
      ],
    );
  }

  List<Widget> _scene() {
    return switch (_state) {
      _MarketState.intro => _introScene(
        speech: 'Madamo nga prutas sa merkado. Buligan ta ang tindera!',
      ),
      _MarketState.map => _mapScene(),
      _MarketState.stall => _stallScene(),
      _MarketState.numberTeach => _numberTeachScene(),
      _MarketState.numberExplore => _numberExploreScene(),
      _MarketState.appleModel => _appleModelScene(),
      _MarketState.guidedCount => _guidedCountScene(),
      _MarketState.question => _questionScene(),
      _MarketState.setupOrder => _setupOrderScene(),
      _MarketState.arrangeOrder => _arrangeScene(),
      _MarketState.reward => _rewardScene(),
    };
  }

  List<Widget> _introScene({required String speech}) {
    return [
      _dialogue(speech),
      _at(86, 200, 260, 300, const TudloMascot(size: 300, mood: KokaMood.idle)),
      _at(560, 160, 360, 330, _vendorAsset()),
      _bottomActionButton('SIGE', () => unawaited(_activateMarket())),
    ];
  }

  List<Widget> _mapScene() {
    const names = ['MARKET', 'PARK', 'SCHOOL', 'BAHAY'];
    return [
      _dialogue('I-tap ang Market.'),
      for (final item in names.indexed)
        _at(
          50 + item.$1 * 220,
          210,
          190,
          210,
          _locationCard(
            item.$2,
            active: item.$2 == 'MARKET',
            onTap: item.$2 == 'MARKET' ? () => unawaited(_tapMarket()) : null,
          ),
        ),
    ];
  }

  List<Widget> _stallScene() {
    return [
      _dialogue('Pangitaa kag i-tap ang fruit stall.'),
      _at(38, 252, 205, 230, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(555, 155, 330, 255, _vendorAsset()),
      _at(
        238,
        146,
        300,
        172,
        GestureDetector(
          onTap: () => unawaited(_tapStall()),
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
      _at(
        445,
        198,
        84,
        84,
        GestureDetector(
          onTap: () => unawaited(_tapStall()),
          child: const AnimatedPointFinger(
            asset: _pointFinger,
            size: 84,
            angle: -.55,
            tapOffset: Offset(-8, -8),
          ),
        ),
      ),
    ];
  }

  List<Widget> _numberTeachScene() {
    return [
      _dialogue('Paminawa ug ihinumdom ang mga numero 1 hangtod 10.'),
      _at(16, 218, 250, 285, const TudloMascot(size: 285, mood: KokaMood.idle)),
      _at(185, 158, 725, 245, _numberBoard(interactive: !_busy)),
      _bottomActionButton(
        'SUNOD',
        _busy ? null : () => unawaited(_go(_MarketState.appleModel)),
      ),
    ];
  }

  List<Widget> _numberExploreScene() {
    return [
      _dialogue('I-tap ang number strip para mabatian ang 1 tubtob 10.'),
      _at(28, 250, 205, 230, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(200, 235, 650, 200, _numberBoard(interactive: true)),
      if (_heardNumbers.length >= 10)
        _bottomActionButton(
          'SUNOD',
          () => unawaited(_go(_MarketState.appleModel)),
        ),
    ];
  }

  List<Widget> _appleModelScene() {
    return [
      _dialogue('Ibutang ang mansanas sa basket.'),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(662, 112, 250, 335, _vendorAsset()),
      _at(380, 270, 470, 330, _basketDropTarget()),
      _at(235, 428, 300, 78, _remainingApples()),
      _at(
        565,
        178,
        100,
        125,
        _counterCard(_placedApples.length, '${_placedApples.length}/5'),
      ),
    ];
  }

  List<Widget> _guidedCountScene() {
    final count = _placedApples.length;
    return [
      _dialogue('Ibutang ang sunod nga mansanas sa basket.'),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(662, 112, 250, 335, _vendorAsset()),
      _at(380, 270, 470, 330, _basketDropTarget()),
      _at(235, 428, 300, 78, _remainingApples()),
      _at(565, 178, 100, 125, _counterCard(count, '$count/5')),
    ];
  }

  List<Widget> _questionScene() {
    return [
      _dialogue('How many apples?'),
      _at(270, 165, 420, 245, _displayTrayWithApples(5)),
      for (final entry in [4, 5, 6].indexed)
        _at(315 + entry.$1 * 135, 372, 118, 118, _answerCard(entry.$2)),
      if (_correctChoice == 5)
        _bottomActionButton(
          'SUNOD',
          () => unawaited(_go(_MarketState.setupOrder)),
        ),
    ];
  }

  List<Widget> _setupOrderScene() {
    return [
      _dialogue('Ihan-ay ang six pakadto ten.'),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(265, 205, 570, 125, _numberStrip(_orderTray)),
      _bottomActionButton(
        'SUNOD',
        () => unawaited(_go(_MarketState.arrangeOrder)),
      ),
    ];
  }

  List<Widget> _arrangeScene() {
    final placed = _orderSlots.whereType<int>().toSet();
    return [
      _dialogue('Ihan-ay ang 6, 7, 8, 9, kag 10.'),
      for (var i = 0; i < 5; i++)
        _at(145 + i * 137, 175, 118, 92, _dropSlot(i)),
      for (final entry in _orderTray.indexed)
        if (!placed.contains(entry.$2))
          _at(
            150 + entry.$1 * 137,
            340,
            112,
            88,
            _numberTile(entry.$2, draggable: true),
          ),
    ];
  }

  List<Widget> _rewardScene() {
    return [
      Positioned.fill(
        child: GradeThreeStickerRewardOverlay(
          stickerAsset: _rewardStickerAsset,
          message: 'Maayo gid!\nNatapos mo ang Numero sa Merkado.',
          primaryLabel: 'OK',
          onPrimary: () => unawaited(_collectReward()),
        ),
      ),
    ];
  }

  Widget _remainingApples() {
    final remaining = [
      1,
      2,
      3,
      4,
      5,
    ].where((id) => !_placedApples.contains(id));
    return Stack(
      children: [
        for (final entry in remaining.indexed)
          Positioned(
            left: entry.$1 * 54,
            top: 0,
            width: 68,
            height: 68,
            child: Draggable<int>(
              data: entry.$2,
              maxSimultaneousDrags: _busy ? 0 : 1,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: 76, height: 76, child: _asset(_apple)),
              ),
              childWhenDragging: Opacity(opacity: .25, child: _asset(_apple)),
              child: _pulse(active: !_busy, child: _asset(_apple)),
            ),
          ),
      ],
    );
  }

  Widget _numberBoard({required bool interactive}) {
    return _creamBoard(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bigLabel('Mga Numero 1-10', size: 30),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var number = 1; number <= 10; number++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: interactive
                        ? () => unawaited(_tapNumber(number))
                        : null,
                    child: _FeedbackMotionLite(
                      active: _heardNumbers.contains(number),
                      child: _smallNumberTile(number),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberStrip(List<int> numbers) {
    return _creamBoard(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final number in numbers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _smallNumberTile(number),
            ),
        ],
      ),
    );
  }

  Widget _dropSlot(int index) {
    final value = _orderSlots[index];
    final allCorrect = _lockedSlots.length == _targetOrder.length;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => !_busy && !allCorrect,
      onAcceptWithDetails: (details) =>
          unawaited(_placeNumber(details.data, index)),
      builder: (context, candidates, rejected) {
        return GestureDetector(
          onTap: () {
            final selected = _selectedTile;
            if (selected != null) unawaited(_placeNumber(selected, index));
          },
          child: _pulse(
            active: candidates.isNotEmpty || allCorrect,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value == null ? Colors.white : _numberTileColor(value),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: allCorrect && value != null
                      ? TudloColors.green
                      : const Color(0xFF82BFEF),
                  width: 3,
                ),
              ),
              child: value == null ? const SizedBox() : _bigLabel('$value'),
            ),
          ),
        );
      },
    );
  }

  Widget _numberTile(int number, {required bool draggable}) {
    final tile = GestureDetector(
      onTap: () => setState(() => _selectedTile = number),
      child: _FeedbackMotionLite(
        active: _selectedTile == number,
        wrong: _wrongChoice == number,
        pulse: _wrongPulse,
        child: _smallNumberTile(number, large: true),
      ),
    );
    if (!draggable) return tile;
    return Draggable<int>(
      data: number,
      feedback: Material(
        color: Colors.transparent,
        child: _smallNumberTile(number, large: true),
      ),
      childWhenDragging: Opacity(opacity: .35, child: tile),
      child: tile,
    );
  }

  Widget _answerCard(int value) {
    final labels = {4: 'Four', 5: 'Five', 6: 'Six'};
    return GestureDetector(
      onTap: () => unawaited(_chooseAnswer(value)),
      child: _FeedbackMotionLite(
        active: _correctChoice == value,
        wrong: _wrongChoice == value,
        pulse: _wrongPulse,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _correctChoice == value
                ? const Color(0xFFDFFFD5)
                : const Color(0xFFF8FCFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _correctChoice == value
                  ? TudloColors.green
                  : (_wrongChoice == value
                        ? TudloColors.coral
                        : TudloColors.blue),
              width: 3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bigLabel('$value', size: 44),
              _bigLabel(labels[value]!, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appleRow(int count, {required bool numbered, int startNumber = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          SizedBox(
            width: numbered ? 68 : 54,
            height: numbered ? 78 : 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _asset(_apple),
                if (numbered)
                  Positioned(
                    bottom: 9,
                    child: Text(
                      '${startNumber + i}',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: 1,
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
      ],
    );
  }

  Widget _basketWithApples(int count, {required bool numbered}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: _asset(_crate)),
        Positioned(
          left: numbered ? 32 : 62,
          right: numbered ? 32 : 62,
          bottom: numbered ? 126 : 136,
          height: numbered ? 128 : 112,
          child: _basketAppleRows(count, numbered: numbered),
        ),
      ],
    );
  }

  Widget _displayTrayWithApples(int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: _asset(_displayTray)),
        Positioned(
          left: 50,
          right: 50,
          top: 58,
          height: 116,
          child: _trayAppleRows(count),
        ),
      ],
    );
  }

  Widget _trayAppleRows(int count) {
    if (count <= 3) return _appleRow(count, numbered: false);
    final topCount = count - 3;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 54, child: _appleRow(topCount, numbered: false)),
        Transform.translate(
          offset: const Offset(0, -8),
          child: SizedBox(height: 62, child: _appleRow(3, numbered: false)),
        ),
      ],
    );
  }

  Widget _basketAppleRows(int count, {required bool numbered}) {
    if (count <= 3) return _appleRow(count, numbered: numbered);
    final topCount = count - 3;
    final bottomCount = math.min(3, count);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: numbered ? 58 : 48,
          child: _appleRow(topCount, numbered: numbered),
        ),
        Transform.translate(
          offset: const Offset(0, -12),
          child: SizedBox(
            height: numbered ? 72 : 62,
            child: _appleRow(
              bottomCount,
              numbered: numbered,
              startNumber: topCount + 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _basketDropTarget() {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) =>
          !_busy && !_placedApples.contains(details.data),
      onAcceptWithDetails: (details) => unawaited(_placeApple(details.data)),
      builder: (context, candidates, rejected) {
        final count = _placedApples.length;
        return _pulse(
          active: candidates.isNotEmpty,
          child: _basketWithApples(count, numbered: false),
        );
      },
    );
  }

  Widget _locationCard(
    String label, {
    required bool active,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _pulse(
        active: active,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFE6FFD9)
                : Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? TudloColors.green : Colors.grey.shade500,
              width: 4,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: active
                    ? _asset(_fruitStall)
                    : Icon(Icons.lock, size: 72, color: Colors.grey.shade600),
              ),
              _bigLabel(
                label,
                size: 22,
                color: active ? Colors.white : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counterCard(int number, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCC8A24), width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bigLabel('$number', size: 52),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD941),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _bigLabel(label, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _smallNumberTile(int number, {bool large = false}) {
    return Container(
      width: large ? 92 : 58,
      height: large ? 72 : 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _numberTileColor(number),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TudloColors.blue, width: 2),
      ),
      child: _bigLabel('$number', size: large ? 34 : 32),
    );
  }

  Color _numberTileColor(int number) {
    const colors = [
      Color(0xFFFFB2B2),
      Color(0xFFFFC986),
      Color(0xFFFFF27D),
      Color(0xFF9BFF9C),
      Color(0xFF86EFA0),
      Color(0xFFAEEAFF),
      Color(0xFF9EC5FF),
      Color(0xFFC9A8FF),
      Color(0xFFE7A8FF),
      Color(0xFFFFA4CE),
    ];
    return colors[(number - 1).clamp(0, 9)];
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return IconButton.filled(
      onPressed: _busy && icon != Icons.arrow_back ? null : onTap,
      icon: Icon(icon, size: 30),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: TudloColors.blue,
        disabledBackgroundColor: Colors.white.withValues(alpha: .55),
      ),
    );
  }

  Widget _bottomActionButton(String label, VoidCallback? onTap) {
    return _at(40, 430, 880, 66, _blueButton(label, onTap));
  }

  Widget _blueButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .55 : 1,
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
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
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

  Widget _topPrompt(String text) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E7).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
      ),
      child: _bigLabel(text, size: 26),
    );
  }

  Widget _dialogue(String text) {
    return _at(
      _g3DialogueX,
      _g3DialogueY,
      _g3DialogueWidth,
      _g3DialogueHeight,
      _topPrompt(text),
    );
  }

  Widget _vendorAsset() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: _asset(_vendor),
    );
  }

  Widget _creamBoard(Widget child) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8CF).withValues(alpha: .98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFCA31), width: 3),
      ),
      child: child,
    );
  }

  Widget _bigLabel(
    String text, {
    double size = 28,
    Color color = TudloColors.ink,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.nunito(
        color: color,
        fontSize: size,
        height: 1.02,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _asset(String asset, {BoxFit fit = BoxFit.contain}) {
    final lower = asset.toLowerCase();
    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(asset, fit: fit);
    }
    return Image.asset(asset, fit: fit, filterQuality: FilterQuality.high);
  }

  Widget _at(double x, double y, double w, double h, Widget child) {
    return Positioned(left: x, top: y, width: w, height: h, child: child);
  }

  Widget _pulse({required bool active, required Widget child}) {
    return _MarketPulse(active: active, child: child);
  }
}

class _MarketPulse extends StatefulWidget {
  final bool active;
  final Widget child;

  const _MarketPulse({required this.active, required this.child});

  @override
  State<_MarketPulse> createState() => _MarketPulseState();
}

class _MarketPulseState extends State<_MarketPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MarketPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
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
      child: widget.child,
      builder: (context, child) {
        final scale = widget.active ? 1 + _controller.value * .035 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

class _FeedbackMotionLite extends StatelessWidget {
  final bool active;
  final bool wrong;
  final int pulse;
  final Widget child;

  const _FeedbackMotionLite({
    required this.active,
    required this.child,
    this.wrong = false,
    this.pulse = 0,
  });

  @override
  Widget build(BuildContext context) {
    final shake = wrong ? math.sin(pulse * math.pi / 2) * 6 : 0.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      transform: Matrix4.translationValues(shake, 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .45),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
