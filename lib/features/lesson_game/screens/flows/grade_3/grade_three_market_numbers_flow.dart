import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/services/lesson_number_voice_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/lesson_asset_glow.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/lesson_game/widgets/reward_overlay.dart';

const String _marketRoot =
    'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets';
const String _marketBg = '$_marketRoot/background/MarketLandscape.svg';
const String _fruitStall = '$_marketRoot/stalls/Stall_Fruit_Empty.svg';
const String _vendor = '$_marketRoot/people/Vendor_Female.svg';
const String _apple = 'assets/images/level_game/apple.png';
const String _crate = '$_marketRoot/inventory/Produce_Crate_Empty.svg';
const Duration _marketCompletionHold = Duration(seconds: 3);

enum _MarketState {
  intro,
  start,
  map,
  stall,
  numberTeach,
  numberExplore,
  appleModel,
  guidedCount,
  countCheck,
  question,
  correctFive,
  setupOrder,
  arrangeOrder,
  openStall,
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

  SharedPreferences? _prefs;
  late String _saveKey;
  Future<void> _saveQueue = Future.value();
  _MarketState _state = _MarketState.intro;
  final Set<int> _heardNumbers = {};
  final Set<int> _placedApples = {};
  final Set<int> _lockedSlots = {};
  List<int?> _orderSlots = List<int?>.filled(5, null);
  List<int> _orderTray = [8, 6, 10, 7, 9];
  int? _wrongChoice;
  int? _correctChoice;
  int? _selectedTile;
  int _wrongPulse = 0;
  bool _busy = true;
  bool _stallOpened = false;
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
    if (_prefs == null) {
      _saveKey =
          'g3.u1.l1.1.market.${AppStateScope.of(context).activeProfileId ?? 'guest'}';
      unawaited(_restore());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_save());
      unawaited(AppAudioService.instance.stopVoice());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_save());
    unawaited(AppAudioService.instance.stopVoice());
    super.dispose();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _prefs = prefs;
    final raw = prefs.getString(_saveKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _state = _MarketState.values.firstWhere(
          (item) => item.name == data['state'],
          orElse: () => _MarketState.intro,
        );
        _heardNumbers.addAll(List<int>.from(data['heardNumbers'] ?? []));
        _placedApples.addAll(List<int>.from(data['placedAppleIds'] ?? []));
        _lockedSlots.addAll(List<int>.from(data['lockedSlots'] ?? []));
        final slots = List<int?>.from(data['orderSlots'] ?? const []);
        if (slots.length == 5) _orderSlots = slots;
        final tray = List<int>.from(data['orderTray'] ?? const []);
        if (tray.length == 5 && tray.toSet().containsAll(_targetOrder)) {
          _orderTray = tray;
        }
        _stallOpened = data['stallOpened'] == true;
        _rewardCollected = data['rewardCollected'] == true;
      } on FormatException {
        // Start fresh if a previous save is unreadable.
      }
    }
    setState(() => _busy = false);
    if (_rewardCollected && !_completedCallbackSent) {
      _completedCallbackSent = true;
      widget.onLessonComplete();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playStateVoice());
    });
  }

  Future<void> _save() {
    final prefs = _prefs;
    if (prefs == null) return Future.value();
    final snapshot = jsonEncode({
      'state': _state.name,
      'heardNumbers': _heardNumbers.toList()..sort(),
      'placedAppleIds': _placedApples.toList()..sort(),
      'orderSlots': _orderSlots,
      'orderTray': _orderTray,
      'lockedSlots': _lockedSlots.toList()..sort(),
      'stallOpened': _stallOpened,
      'rewardCollected': _rewardCollected,
    });
    _saveQueue = _saveQueue.then((_) => prefs.setString(_saveKey, snapshot));
    return _saveQueue;
  }

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
      _MarketState.start => 2,
      _MarketState.map => 3,
      _MarketState.stall => 4,
      _MarketState.numberTeach => 6,
      _MarketState.numberExplore => 7,
      _MarketState.appleModel => 8,
      _MarketState.guidedCount => 8,
      _MarketState.countCheck => 9,
      _MarketState.question => 10,
      _MarketState.correctFive => 11,
      _MarketState.setupOrder => 16,
      _MarketState.arrangeOrder => 21,
      _MarketState.openStall => 25,
      _MarketState.reward => 25,
    };
  }

  Future<void> _playStateVoice() => _playClip(_clipForState());

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
    setState(() => _busy = true);
    await AppAudioService.instance.playCorrect();
    await _playClip(5);
    if (!mounted) return;
    setState(() => _busy = false);
    await _go(_MarketState.numberTeach);
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
    await _save();
    if (!mounted) return;
    setState(() => _busy = false);
    if (_placedApples.length == 5) {
      await _go(_MarketState.countCheck);
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
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _placeNumber(int number, int slot) async {
    if (_busy || _lockedSlots.length == _targetOrder.length) return;
    final expected = _targetOrder[slot];
    if (number != expected) {
      await playLessonNumberVoice(number);
      await _wrong(choice: number);
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
    }
  }

  Future<void> _openStall() async {
    if (_busy || _lockedSlots.length != 5) return;
    setState(() {
      _stallOpened = true;
      _busy = true;
    });
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
        speech: 'Madamo nga prutas\nsa merkado. Buligan\nta ang tindera!',
        showButton: false,
      ),
      _MarketState.start => _introScene(
        speech: 'I-tap ang\nSIGE para\nbuksan ang merkado!',
        showButton: true,
      ),
      _MarketState.map => _mapScene(),
      _MarketState.stall => _stallScene(),
      _MarketState.numberTeach => _numberTeachScene(),
      _MarketState.numberExplore => _numberExploreScene(),
      _MarketState.appleModel => _appleModelScene(),
      _MarketState.guidedCount => _guidedCountScene(),
      _MarketState.countCheck => _countCheckScene(),
      _MarketState.question => _questionScene(),
      _MarketState.correctFive => _correctFiveScene(),
      _MarketState.setupOrder => _setupOrderScene(),
      _MarketState.arrangeOrder => _arrangeScene(),
      _MarketState.openStall => _openStallScene(),
      _MarketState.reward => _rewardScene(),
    };
  }

  List<Widget> _introScene({required String speech, required bool showButton}) {
    return [
      _at(105, 102, 300, 150, _speech(speech, size: 22)),
      _at(36, 228, 205, 245, const TudloMascot(size: 245, mood: KokaMood.idle)),
      _at(350, 130, 285, 285, _asset(_crate)),
      _at(540, 128, 380, 315, _asset(_vendor)),
      _at(224, 145, 340, 185, _asset(_fruitStall)),
      if (showButton)
        _at(
          420,
          385,
          250,
          72,
          _blueButton('SIGE', () => unawaited(_activateMarket())),
        )
      else
        _at(
          420,
          442,
          250,
          58,
          _blueButton('SIGE', () => unawaited(_go(_MarketState.start))),
        ),
    ];
  }

  List<Widget> _mapScene() {
    const names = ['MARKET', 'PARK', 'SCHOOL', 'BAHAY'];
    return [
      _at(235, 105, 490, 70, _woodSign('I-tap ang Market.')),
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
      _at(106, 112, 285, 92, _speech('Pangitaa kag i-tap\nang fruit stall.')),
      _at(38, 252, 205, 230, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(555, 155, 330, 255, _asset(_vendor)),
      _at(
        372,
        140,
        350,
        250,
        _pulse(
          active: !_busy,
          child: GestureDetector(
            onTap: () => unawaited(_tapStall()),
            child: _glowFrame(_fruitStall),
          ),
        ),
      ),
      _at(370, 350, 250, 125, _asset(_crate)),
    ];
  }

  List<Widget> _numberTeachScene() {
    return [
      _at(
        55,
        112,
        280,
        92,
        _speech('Paminawa ug ihinumdom\nang mga numero\n1 hangtod 10.'),
      ),
      _at(28, 255, 205, 225, const TudloMascot(size: 230, mood: KokaMood.idle)),
      _at(200, 160, 650, 240, _numberBoard(interactive: false)),
      _at(
        650,
        430,
        230,
        58,
        _blueButton('SUNOD', () => unawaited(_go(_MarketState.numberExplore))),
      ),
    ];
  }

  List<Widget> _numberExploreScene() {
    return [
      _at(
        72,
        112,
        310,
        105,
        _speech('I-tap ang number strip\npara mabatian ang\n1 tubtob 10.'),
      ),
      _at(28, 250, 205, 230, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(200, 235, 650, 200, _numberBoard(interactive: true)),
      if (_heardNumbers.length >= 10)
        _at(
          650,
          455,
          230,
          54,
          _blueButton('SUNOD', () => unawaited(_go(_MarketState.appleModel))),
        ),
    ];
  }

  List<Widget> _appleModelScene() {
    return [
      _at(120, 105, 280, 95, _speech('Isa ka mansanas\nuna.')),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(662, 112, 250, 335, _asset(_vendor)),
      _at(245, 305, 270, 125, _appleShelf(4)),
      _at(468, 268, 310, 205, _basketDropTarget()),
      _at(392, 198, 82, 82, _asset(_apple)),
      _at(585, 115, 100, 125, _counterCard(1, '1/5')),
      _at(
        650,
        455,
        230,
        54,
        _blueButton('SUNOD', () {
          _placedApples.add(0);
          unawaited(_save());
          unawaited(_go(_MarketState.guidedCount));
        }),
      ),
    ];
  }

  List<Widget> _guidedCountScene() {
    final count = math.max(1, _placedApples.length);
    return [
      _at(
        112,
        105,
        295,
        100,
        _speech('Ibutang ang\nsunod nga mansanas\nsa basket.'),
      ),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(662, 112, 250, 335, _asset(_vendor)),
      _at(425, 258, 330, 215, _basketDropTarget()),
      _at(250, 330, 210, 118, _remainingApples()),
      _at(585, 115, 100, 125, _counterCard(count, '$count/5')),
    ];
  }

  List<Widget> _countCheckScene() {
    return [
      _at(118, 108, 292, 88, _speech('Lima ka mansanas\nsa basket!')),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(662, 112, 250, 335, _asset(_vendor)),
      _at(350, 258, 380, 215, _basketWithApples(5, numbered: true)),
      _at(585, 115, 100, 125, _counterCard(5, '5/5')),
      _at(
        650,
        455,
        230,
        54,
        _blueButton('SUNOD', () => unawaited(_go(_MarketState.question))),
      ),
    ];
  }

  List<Widget> _questionScene() {
    return [
      _at(128, 118, 260, 82, _speech('How many apples?')),
      _at(
        40,
        250,
        200,
        230,
        const TudloMascot(size: 230, mood: KokaMood.curious),
      ),
      _at(690, 132, 210, 300, _asset(_vendor)),
      _at(230, 250, 350, 220, _basketWithApples(5, numbered: false)),
      for (final entry in [4, 5, 6].indexed)
        _at(420 + entry.$1 * 120, 365, 110, 118, _answerCard(entry.$2)),
      if (_correctChoice == 5)
        _at(
          700,
          455,
          180,
          54,
          _blueButton('SUNOD', () => unawaited(_go(_MarketState.correctFive))),
        ),
    ];
  }

  List<Widget> _correctFiveScene() {
    return [
      _at(
        118,
        108,
        292,
        88,
        _speech('Husto ang imo pag-isip!\nMaka-open na ang stall.'),
      ),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(662, 112, 250, 335, _asset(_vendor)),
      _at(285, 220, 480, 265, _basketWithApples(5, numbered: true)),
      _at(
        650,
        455,
        230,
        54,
        _blueButton('SUNOD', () => unawaited(_go(_MarketState.setupOrder))),
      ),
    ];
  }

  List<Widget> _setupOrderScene() {
    return [
      _at(110, 106, 310, 82, _speech('Ihan-ay ang six\npakadto ten.')),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(265, 205, 570, 125, _numberStrip(_orderTray)),
      _at(
        650,
        455,
        230,
        54,
        _blueButton('SUNOD', () => unawaited(_go(_MarketState.arrangeOrder))),
      ),
    ];
  }

  List<Widget> _arrangeScene() {
    final placed = _orderSlots.whereType<int>().toSet();
    return [
      _at(150, 90, 660, 65, _speech('Ihan-ay ang 6, 7, 8, 9, kag 10.')),
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
      if (_lockedSlots.length == 5)
        _at(
          650,
          455,
          230,
          54,
          _blueButton('SUNOD', () => unawaited(_go(_MarketState.openStall))),
        ),
    ];
  }

  List<Widget> _openStallScene() {
    return [
      _at(118, 105, 310, 88, _speech('Husto! Ablihan ta\nang stall.')),
      _at(35, 245, 200, 235, const TudloMascot(size: 235, mood: KokaMood.idle)),
      _at(555, 126, 295, 270, _asset(_vendor)),
      _at(310, 140, 390, 285, _glowFrame(_fruitStall)),
      _at(
        640,
        455,
        240,
        54,
        _blueButton('OPEN', () => unawaited(_openStall())),
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
    final remaining = [1, 2, 3, 4].where((id) => !_placedApples.contains(id));
    return Stack(
      children: [
        for (final entry in remaining.indexed)
          Positioned(
            left: entry.$1 * 42,
            top: entry.$1.isEven ? 0 : 24,
            width: 64,
            height: 64,
            child: Draggable<int>(
              data: entry.$2,
              maxSimultaneousDrags: _busy ? 0 : 1,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: 68, height: 68, child: _asset(_apple)),
              ),
              childWhenDragging: Opacity(opacity: .25, child: _asset(_apple)),
              child: _pulse(active: !_busy, child: _asset(_apple)),
            ),
          ),
      ],
    );
  }

  Widget _appleShelf(int count) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFBA7A38),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 26,
          height: 75,
          child: _appleRow(count, numbered: false),
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

  Widget _appleRow(int count, {required bool numbered}) {
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
                      '${i + 1}',
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
          left: numbered ? 18 : 38,
          right: numbered ? 18 : 38,
          bottom: numbered ? 44 : 42,
          height: numbered ? 92 : 72,
          child: _appleRow(count, numbered: numbered),
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
        final count = math.max(1, _placedApples.length);
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

  Widget _blueButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .55 : 1,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TudloColors.blue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7ED8FF), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 31,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _speech(String text, {double size = 25}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: TudloColors.blue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _bigLabel(text, size: size),
    );
  }

  Widget _woodSign(String text) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE7B36F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A5A2E), width: 4),
      ),
      child: _bigLabel(text, size: 28),
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

  Widget _glowFrame(String asset) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: LessonAssetGlow(
            asset: asset,
            fallbackIcon: Icons.storefront_rounded,
            fallbackSize: 170,
          ),
        ),
        Padding(padding: const EdgeInsets.all(8), child: _asset(asset)),
      ],
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
