part of '../../level_game_page.dart';

const String _g3ShopRoot =
    'assets/images/level_game/grade3/G3_U1_L1.3_Pagbakal_ni_Koka_sa_Merkado_SVG_Assets';
const String _g3ShopBg = '$_g3ShopRoot/background/MarketLandscape.svg';
const String _g3ShopNanayList = '$_g3ShopRoot/people/Nanay_Shopping_List.svg';
const String _g3ShopNanayBasket =
    '$_g3ShopRoot/people/Nanay_Shopping_Basket.svg';
const String _g3ShopBoy = '$_g3ShopRoot/people/Boy_Age_9.svg';
const String _g3ShopFishVendor = '$_g3ShopRoot/people/Vendor_Fish_Male.svg';
const String _g3ShopFruitVendor = '$_g3ShopRoot/people/Vendor_Fruit_Female.svg';
const String _g3ShopVendor = '$_g3ShopRoot/people/Vendor_General_Male.svg';
const String _g3ShopFruitStall = '$_g3ShopRoot/stalls/Stall_Fruit_Empty.svg';
const String _g3ShopFishStall = '$_g3ShopRoot/stalls/Stall_Fish_Empty.svg';
const String _g3ShopFlowerStall = '$_g3ShopRoot/stalls/Stall_Flower_Empty.svg';
const String _g3ShopBananaStall =
    '$_g3ShopRoot/stalls/Stall_Flower_With_Bananas.svg';
const String _g3ShopInventoryStall =
    '$_g3ShopRoot/stalls/Stall_Inventory_Empty.svg';
const String _g3ShopCounter = '$_g3ShopRoot/stalls/Market_Counter.svg';
const String _g3ShopMango = '$_g3ShopRoot/products/Mango.svg';
const String _g3ShopFish = '$_g3ShopRoot/products/Fish.svg';
const String _g3ShopFlower = '$_g3ShopRoot/products/Flower_Pink.svg';
const String _g3ShopSpoon = '$_g3ShopRoot/products/Spoon.svg';
const String _g3ShopChair = '$_g3ShopRoot/products/Chair.svg';
const String _g3ShopCandle = '$_g3ShopRoot/products/Birthday_Candle.svg';
const String _g3ShopBanana = '$_g3ShopRoot/products/Banana_Single.svg';
const String _g3ShopBananasBunch =
    'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets/inventory/Bananas_Bunch.svg';
const String _g3ShopEgg = '$_g3ShopRoot/products/Egg.svg';
const String _g3ShopCup = '$_g3ShopRoot/shopping_props/Cup_Blue.svg';
const String _g3ShopTray = '$_g3ShopRoot/shopping_props/Display_Tray_Empty.svg';
const String _g3ShopBasket =
    '$_g3ShopRoot/shopping_props/Shopping_Basket_Empty.svg';
const String _g3ShopList =
    '$_g3ShopRoot/shopping_props/Shopping_List_Blank.svg';
const String _g3ShopTag = '$_g3ShopRoot/shopping_props/Price_Tag_Blank.svg';
const String _g3ShopCoin = '$_g3ShopRoot/shopping_props/Peso_Coin.svg';
const String _g3ShopBill = '$_g3ShopRoot/shopping_props/Play_Money_Bill.svg';
const String _g3ShopPointFinger =
    'assets/images/level_game/lesson-game-assets/point-finger.png';
const String _g3ShopAgeBoy =
    'assets/images/level_game/grade3/G3_U2_L2.2_Ang_Bag-o_nga_Estudyante/ChatGPT Image Sep 19, 2026, 04_23_03 PM.png';

bool _isGrade3ShoppingLesson(LevelContent content) {
  return content.gradeLevel == 3 &&
      content.unitNumber == 1 &&
      content.lessonNumber == 3;
}

enum _G3ShopStep {
  listIntro,
  map,
  stallHotspot,
  priceChoice,
  ageChoice,
  sentenceArrange,
  reward,
}

enum _G3ShopPhase { quantity, price }

class _GradeThreeShoppingFlow extends StatefulWidget {
  final VoidCallback onExit;
  final String rewardStickerAsset;
  final VoidCallback onBackToMap;
  final VoidCallback onContinue;

  const _GradeThreeShoppingFlow({
    required this.onExit,
    required this.rewardStickerAsset,
    required this.onBackToMap,
    required this.onContinue,
  });

  @override
  State<_GradeThreeShoppingFlow> createState() =>
      _GradeThreeShoppingFlowState();
}

class _GradeThreeShoppingFlowState extends State<_GradeThreeShoppingFlow> {
  _G3ShopStep _step = _G3ShopStep.listIntro;
  bool _listOpen = false;
  String? _wrongId;
  String? _correctId;
  int _wrongPulse = 0;
  final List<String?> _sentenceSlots = List<String?>.filled(2, null);
  String? _selectedTile;
  bool _priceChoiceReady = false;
  bool _ageChoiceReady = false;
  bool _sentenceReady = false;
  bool _listIntroReady = false;
  int _voiceGeneration = 0;

  double get _progress =>
      (_G3ShopStep.values.indexOf(_step) + 1) / _G3ShopStep.values.length;

  @override
  void initState() {
    super.initState();
    unawaited(_playInitialStepVoice());
  }

  void _next() {
    final index = _G3ShopStep.values.indexOf(_step);
    if (index >= _G3ShopStep.values.length - 1) return;
    _voiceGeneration++;
    setState(() {
      _step = _G3ShopStep.values[index + 1];
      _wrongId = null;
      _correctId = null;
      _selectedTile = null;
      _listIntroReady = false;
      _priceChoiceReady = false;
      _ageChoiceReady = false;
      _sentenceReady = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playStepVoice();
    });
  }

  int _clipForStep() {
    return switch (_step) {
      _G3ShopStep.listIntro => 2,
      _G3ShopStep.map => 3,
      _G3ShopStep.stallHotspot => 4,
      _G3ShopStep.priceChoice => 5,
      _G3ShopStep.ageChoice => 14,
      _G3ShopStep.sentenceArrange => 23,
      _G3ShopStep.reward => 30,
    };
  }

  Future<void> _playClip(
    int clip, {
    bool waitForTextToSpeechStop = true,
    bool waitForVoiceStop = true,
  }) async {
    if (!AppAudioService.instance.voiceOverEnabled) return;
    if (waitForTextToSpeechStop) {
      await TudloVoiceButton.stop();
    } else {
      unawaited(TudloVoiceButton.stop());
    }
    if (waitForVoiceStop) {
      await AppAudioService.instance.stopVoice();
    }
    await AppAudioService.instance.lowerBackgroundVolume();
    try {
      await AppAudioService.instance.playVoiceAssets([
        'audio/VO-final/grade3/Gr_3_Les_1_3_$clip.wav',
      ]);
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  Future<void> _playInitialStepVoice() {
    final generation = ++_voiceGeneration;
    return _playClip(_clipForStep()).then((_) {
      if (!_isCurrentVoice(generation, _G3ShopStep.listIntro)) return;
      setState(() => _listIntroReady = true);
    });
  }

  Future<void> _playPriceChoiceSequence(int generation) async {
    setState(() {
      _priceChoiceReady = false;
    });
    await _playClip(5);
    if (!_isCurrentVoice(generation, _G3ShopStep.priceChoice)) return;
    await _playClip(6);
    if (!_isCurrentVoice(generation, _G3ShopStep.priceChoice)) return;
    await _playClip(7);
    if (!_isCurrentVoice(generation, _G3ShopStep.priceChoice)) return;
    await _playClip(8);
    if (!_isCurrentVoice(generation, _G3ShopStep.priceChoice)) return;
    await _playClip(9);
    if (_isCurrentVoice(generation, _G3ShopStep.priceChoice)) {
      setState(() => _priceChoiceReady = true);
    }
  }

  Future<void> _playAgeChoiceSequence(int generation) async {
    setState(() => _ageChoiceReady = false);
    for (final clip in const [14, 15, 16, 17, 18]) {
      await _playClip(clip);
      if (!_isCurrentVoice(generation, _G3ShopStep.ageChoice)) return;
    }
    if (_isCurrentVoice(generation, _G3ShopStep.ageChoice)) {
      setState(() => _ageChoiceReady = true);
    }
  }

  Future<void> _playSentenceArrangeSequence(int generation) async {
    setState(() => _sentenceReady = false);
    await _playClip(23);
    if (!_isCurrentVoice(generation, _G3ShopStep.sentenceArrange)) return;
    await _playClip(24);
    if (_isCurrentVoice(generation, _G3ShopStep.sentenceArrange)) {
      setState(() => _sentenceReady = true);
    }
  }

  bool _isCurrentVoice(int generation, _G3ShopStep step) =>
      mounted && _voiceGeneration == generation && _step == step;

  Future<void> _playStepVoice() {
    final generation = ++_voiceGeneration;
    if (_step == _G3ShopStep.listIntro) {
      setState(() => _listIntroReady = false);
      return _playClip(_clipForStep()).then((_) {
        if (_isCurrentVoice(generation, _G3ShopStep.listIntro)) {
          setState(() => _listIntroReady = true);
        }
      });
    }
    if (_step == _G3ShopStep.priceChoice) {
      return _playPriceChoiceSequence(generation);
    }
    if (_step == _G3ShopStep.ageChoice) {
      return _playAgeChoiceSequence(generation);
    }
    if (_step == _G3ShopStep.sentenceArrange) {
      return _playSentenceArrangeSequence(generation);
    }
    return _playClip(_clipForStep());
  }

  Future<void> _choose(String id, String answer) async {
    if (_correctId != null) return;
    if (id != answer) {
      setState(() {
        _wrongId = id;
        _wrongPulse++;
      });
      await AppAudioService.instance.playWrong();
      if (_step == _G3ShopStep.priceChoice) {
        await _playClip(11);
        if (mounted) setState(() => _wrongId = null);
        return;
      }
      if (_step == _G3ShopStep.ageChoice) {
        await _playClip(20);
        if (!mounted || _step != _G3ShopStep.ageChoice) return;
        await _playClip(21);
        if (!mounted || _step != _G3ShopStep.ageChoice) return;
        await _playClip(22);
        if (mounted) setState(() => _wrongId = null);
        return;
      }
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        'Hmmm, hindi amo na.',
        hiligaynon: true,
      );
      if (mounted) setState(() => _wrongId = null);
      return;
    }
    setState(() => _correctId = id);
    await AppAudioService.instance.playCorrect();
    if (_step == _G3ShopStep.priceChoice) {
      await _playClip(10);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted && _step == _G3ShopStep.priceChoice) _next();
    } else if (_step == _G3ShopStep.ageChoice) {
      await _playClip(19);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted && _step == _G3ShopStep.ageChoice) _next();
    }
  }

  Future<void> _placeSentence(String tile, int slot) async {
    if (!_sentenceReady) return;
    const answer = ['It costs', 'ten pesos.'];
    if (tile != answer[slot]) {
      setState(() => _wrongPulse++);
      await AppAudioService.instance.playWrong();
      await _playClip(27);
      if (!mounted || _step != _G3ShopStep.sentenceArrange) return;
      await _playClip(28);
      if (!mounted || _step != _G3ShopStep.sentenceArrange) return;
      await _playClip(25);
      return;
    }
    setState(() {
      _sentenceSlots[slot] = tile;
      _selectedTile = null;
    });
    if (_sentenceSlots.indexed.every((entry) => entry.$2 == answer[entry.$1])) {
      await AppAudioService.instance.playCorrect();
      await _playClip(26);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted && _step == _G3ShopStep.sentenceArrange) _next();
    }
  }

  Future<void> _openList() async {
    if (_listOpen || !_listIntroReady) return;
    setState(() => _listOpen = true);
    await AppAudioService.instance.playCorrect();
    if (mounted && _step == _G3ShopStep.listIntro) _next();
  }

  Future<void> _hotspotNext({int? clip}) async {
    await AppAudioService.instance.playCorrect();
    if (clip != null) await _playClip(clip);
    if (mounted) _next();
  }

  @override
  Widget build(BuildContext context) {
    assert(_g3ShoppingLegacyReferenceSink != null);
    return _G3ShoppingChrome(
      progress: _progress,
      onExit: widget.onExit,
      onReplay: _playStepVoice,
      child: switch (_step) {
        _G3ShopStep.listIntro => _G3ShopListIntroPage(
          opened: _listOpen,
          ready: _listIntroReady,
          onOpen: () => unawaited(_openList()),
        ),
        _G3ShopStep.map => _G3ShopMapPage(
          onTapMarket: () => unawaited(_hotspotNext()),
        ),
        _G3ShopStep.stallHotspot => _G3ShopBananaStallPage(
          prompt: 'Pangitaa ang banana stall.',
          onTapStall: () => unawaited(_hotspotNext()),
        ),
        _G3ShopStep.priceChoice => _G3ShopPriceChoicePage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          ready: _priceChoiceReady,
          onChoose: (id) => unawaited(_choose(id, '10')),
        ),
        _G3ShopStep.ageChoice => _G3ShopAgeChoicePage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          ready: _ageChoiceReady,
          onChoose: (id) => unawaited(_choose(id, 'I am 9 years old.')),
          onNext: _correctId == null ? null : _next,
        ),
        _G3ShopStep.sentenceArrange => _G3ShopSentencePage(
          slots: _sentenceSlots,
          selectedTile: _selectedTile,
          wrongPulse: _wrongPulse,
          ready: _sentenceReady,
          onSelectTile: (tile) {
            if (_sentenceReady) setState(() => _selectedTile = tile);
          },
          onPlace: (tile, slot) => unawaited(_placeSentence(tile, slot)),
          onTapSlot: (slot) {
            if (!_sentenceReady) return;
            final tile = _selectedTile;
            if (tile != null) unawaited(_placeSentence(tile, slot));
          },
          onNext: _sentenceSlots.every((value) => value != null) ? _next : null,
        ),
        _G3ShopStep.reward => _G3ShopRewardPage(
          stickerAsset: widget.rewardStickerAsset,
          onBackToMap: widget.onBackToMap,
          onContinue: widget.onContinue,
        ),
      },
    );
  }
}

class _G3ShoppingChrome extends StatelessWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final Widget child;

  const _G3ShoppingChrome({
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
      backgroundAsset: _g3ShopBg,
      child: child,
    );
  }
}

Object? get _g3ShoppingLegacyReferenceSink => (
  _g3ShopFishVendor,
  _g3ShopFruitVendor,
  _g3ShopFruitStall,
  _g3ShopFishStall,
  _g3ShopFlowerStall,
  _g3ShopInventoryStall,
  _g3ShopFlower,
  _g3ShopSpoon,
  _G3ShopIntroPage(onNext: () {}),
  _G3QuestionTypesPage(opened: const {}, onOpen: (_) {}, onNext: null),
  _G3ShopQuestionPage(
    prompt: '',
    stallAsset: _g3ShopFishStall,
    vendorAsset: _g3ShopFishVendor,
    productAsset: _g3ShopFish,
    count: 1,
    price: 1,
    choices: const [''],
    answer: '',
    wrongId: null,
    correctId: null,
    wrongPulse: 0,
    onChoose: (unusedId, unusedAnswer) async {},
    onNext: () {},
  ),
  _G3AgeQuestionPage(
    wrongId: null,
    correctId: null,
    wrongPulse: 0,
    onChoose: (unusedId, unusedAnswer) async {},
    onNext: () {},
  ),
  _G3PriceOnlyPage(
    wrongId: null,
    correctId: null,
    wrongPulse: 0,
    onChoose: (unusedId, unusedAnswer) async {},
    onNext: () {},
  ),
  _G3SpeakAtStallPage(done: false, onRecord: () {}, onNext: null),
  _g3ShoppingRounds,
  _G3ShoppingListPage(
    round: _g3ShoppingRounds.first,
    roundIndex: 0,
    phase: _G3ShopPhase.quantity,
    basketCount: 0,
    basketPulse: 0,
    wrongId: null,
    correctId: null,
    wrongPulse: 0,
    onAdd: () {},
    onRemove: () {},
    onCheckQuantity: () async {},
    onChoosePrice: (_) {},
  ),
  _G3ShopPhase.price,
  _G3ShopReviewPage(
    done: const {},
    wrongId: null,
    wrongPulse: 0,
    onAnswer: (unusedIndex, unusedId) {},
    onNext: null,
  ),
);

class _G3ShopListIntroPage extends StatelessWidget {
  final bool opened;
  final bool ready;
  final VoidCallback onOpen;

  const _G3ShopListIntroPage({
    required this.opened,
    required this.ready,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'May listahan ako sang baklon. Buligi ako gamit ang numero.',
      promptFontSize: 30,
      showContentPanel: false,
      footer: const SizedBox(height: 72),
      child: SizedBox(
        height: view.height * .62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: view.width * .245,
              bottom: -view.height * .31,
              child: _LessonKokaMascot(
                size: (view.width * .62).clamp(230.0, 355.0),
                mood: KokaMood.idle,
              ),
            ),
            Positioned(
              left: view.width * .295,
              right: -view.width * .01,
              top: view.height * .105,
              bottom: -view.height * .18,
              child: GestureDetector(
                onTap: ready ? onOpen : null,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const _LessonPictureAsset(
                      asset: _g3ShopList,
                      fit: BoxFit.contain,
                    ),
                    if (ready && !opened)
                      Positioned(
                        right: view.width * .09,
                        bottom: view.height * .075,
                        child: AnimatedPointFinger(
                          asset: _g3ShopPointFinger,
                          size: (view.width * .125).clamp(66.0, 102.0),
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

class _G3ShopMapPage extends StatefulWidget {
  final VoidCallback onTapMarket;

  const _G3ShopMapPage({required this.onTapMarket});

  @override
  State<_G3ShopMapPage> createState() => _G3ShopMapPageState();
}

class _G3ShopMapPageState extends State<_G3ShopMapPage> {
  final _overrides = tudlo_map.MapEventOverrides()
    ..setOverride(
      tudlo_map.MapLocation.market,
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
      message: 'I-tap ang Market sa mapa.',
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      FadePageRoute<void>(
        page: tudlo_map.MapScreen(
          eventOverrides: _overrides,
          temporaryUnlockedLocations: const {tudlo_map.MapLocation.market},
          initialFocusLocation: tudlo_map.MapLocation.market,
        ),
      ),
    );
    if (!mounted) return;
    await AppAudioService.instance.playCorrect();
    widget.onTapMarket();
  }

  @override
  Widget build(BuildContext context) {
    return const _G3MarketContentFrame(
      prompt: 'Ginapangita ang Market sa mapa...',
      footer: SizedBox(height: 64),
      child: SizedBox(height: 360),
    );
  }
}

class _G3ShopBananaStallPage extends StatelessWidget {
  final String prompt;
  final VoidCallback onTapStall;

  const _G3ShopBananaStallPage({
    required this.prompt,
    required this.onTapStall,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: prompt,
      showContentPanel: false,
      footer: const SizedBox(height: 64),
      child: SizedBox(
        height: view.height * .62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: view.width * .075,
              bottom: -view.height * .19,
              child: _LessonKokaMascot(
                size: (view.width * .62).clamp(230.0, 355.0),
                mood: KokaMood.idle,
              ),
            ),
            Positioned(
              right: -view.width * .155,
              bottom: -view.height * .32,
              width: (view.width * .78).clamp(430.0, 680.0),
              height: (view.height * .72).clamp(390.0, 580.0),
              child: GestureDetector(
                onTap: onTapStall,
                behavior: HitTestBehavior.opaque,
                child: const _LessonPictureAsset(
                  asset: _g3ShopBananaStall,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3ShopPriceChoicePage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final bool ready;
  final ValueChanged<String> onChoose;

  const _G3ShopPriceChoicePage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.ready,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final bananaWidth = (view.width * .48).clamp(275.0, 450.0);
    final bananaHeight = (view.height * .45).clamp(255.0, 390.0);
    final bananaClusterWidth = bananaWidth * 1.46;
    return _G3MarketContentFrame(
      prompt: 'Tan-awa ang tatlo ka price tag kag pilia ang ten pesos.',
      footer: const SizedBox.shrink(),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .82,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -view.width * .055,
              right: -view.width * .055,
              bottom: -view.height * .25,
              height: (view.height * .92).clamp(500.0, 700.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: (view.height * .72).clamp(390.0, 555.0),
                    child: const _LessonPictureAsset(
                      asset: _g3ShopCounter,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: (view.height * .34).clamp(184.0, 266.0),
                    height: bananaHeight,
                    child: Center(
                      child: SizedBox(
                        width: bananaClusterWidth,
                        height: bananaHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final index in const [0, 1, 2])
                              Positioned(
                                left: index * bananaWidth * .23,
                                bottom: 0,
                                width: bananaWidth,
                                height: bananaHeight,
                                child: const _LessonPictureAsset(
                                  asset: _g3ShopBananasBunch,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: view.width * .095,
                    right: view.width * .095,
                    bottom: (view.height * .19).clamp(104.0, 146.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final entry in const [8, 12, 10].indexed) ...[
                          if (entry.$1 > 0) const SizedBox(width: 0),
                          _FeedbackMotion(
                            key: ValueKey(
                              'g3-shop-price-${entry.$2}-$wrongPulse-$correctId',
                            ),
                            correct: correctId == '${entry.$2}',
                            wrong: wrongId == '${entry.$2}',
                            child: GestureDetector(
                              onTap: ready && correctId == null
                                  ? () => onChoose('${entry.$2}')
                                  : null,
                              child: _G3PriceChoiceTag(
                                price: entry.$2,
                                correct: correctId == '${entry.$2}',
                                wrong: wrongId == '${entry.$2}',
                              ),
                            ),
                          ),
                        ],
                      ],
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

class _G3ShopAgeChoicePage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final bool ready;
  final ValueChanged<String> onChoose;
  final VoidCallback? onNext;

  const _G3ShopAgeChoicePage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.ready,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'Pilia ang sabat nga I am nine years old.',
      footer: const SizedBox.shrink(),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .66,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: view.width * .015,
              bottom: -view.height * .18,
              child: _LessonKokaMascot(
                size: (view.width * .34).clamp(150.0, 225.0),
                mood: KokaMood.idle,
              ),
            ),
            Positioned(
              left: view.width * .10,
              bottom: -view.height * .145,
              width: (view.width * .31).clamp(170.0, 255.0),
              height: (view.height * .55).clamp(300.0, 430.0),
              child: const _LessonPictureAsset(
                asset: _g3ShopAgeBoy,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: view.width * .40,
              right: 0,
              top: view.height * .08,
              bottom: view.height * .05,
              child: Row(
                children: [
                  for (final choice in const [
                    'I am 8 years old.',
                    'I am 9 years old.',
                    'I am 10 years old.',
                  ]) ...[
                    Expanded(
                      child: _FeedbackMotion(
                        key: ValueKey(
                          'shop-age-choice-$choice-$wrongPulse-$correctId',
                        ),
                        correct: correctId == choice,
                        wrong: wrongId == choice,
                        child: GradeThreePressable(
                          onTap: ready && correctId == null
                              ? () => onChoose(choice)
                              : null,
                          borderRadius: 22,
                          child: _G3AgeChoiceCard(
                            label: choice,
                            correct: correctId == choice,
                            wrong: wrongId == choice,
                          ),
                        ),
                      ),
                    ),
                    if (choice != 'I am 10 years old.')
                      SizedBox(width: view.width * .015),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3AgeChoiceCard extends StatelessWidget {
  final String label;
  final bool correct;
  final bool wrong;

  const _G3AgeChoiceCard({
    required this.label,
    required this.correct,
    required this.wrong,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final glowColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (glowColor != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: .68),
                    blurRadius: 18,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: .34),
                    blurRadius: 34,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: (view.width * .012).clamp(8.0, 14.0),
            vertical: 10,
          ),
          decoration: _g3SoftPanelDecoration(
            fill: Colors.white,
            borderColor: correct
                ? TudloColors.green
                : wrong
                ? TudloColors.coral
                : TudloColors.blue,
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: (view.width * .027).clamp(17.0, 26.0),
              height: .98,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _G3ShopIntroPage extends StatelessWidget {
  final VoidCallback onNext;

  const _G3ShopIntroPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'Mabakal kita sa merkado!',
      footer: _LessonOneBlueButton(label: 'Sugdi', onTap: onNext),
      child: SizedBox(
        height: view.height * .54,
        child: Stack(
          children: [
            Positioned(
              left: -view.width * .02,
              bottom: 0,
              child: _LessonKokaMascot(
                size: (view.width * .38).clamp(140.0, 210.0),
                mood: KokaMood.idle,
              ),
            ),
            const Positioned(
              right: 6,
              bottom: 0,
              width: 180,
              height: 260,
              child: _LessonPictureAsset(
                asset: _g3ShopNanayList,
                fit: BoxFit.contain,
              ),
            ),
            const Positioned(
              left: 120,
              right: 0,
              top: 12,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  _Grade3MarketLearningChip(label: 'EDAD'),
                  _Grade3MarketLearningChip(label: 'KADAMUON'),
                  _Grade3MarketLearningChip(label: 'PRESYO'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3QuestionTypesPage extends StatelessWidget {
  final Set<String> opened;
  final ValueChanged<String> onOpen;
  final VoidCallback? onNext;

  const _G3QuestionTypesPage({
    required this.opened,
    required this.onOpen,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Tulo ka pangutana.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Row(
        children: [
          Expanded(
            child: _G3TypeCard(
              id: 'age',
              title: 'HOW OLD?',
              asset: _g3ShopBoy,
              text: 'I am 9.',
              active: opened.contains('age'),
              onTap: onOpen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _G3TypeCard(
              id: 'many',
              title: 'HOW MANY?',
              asset: _g3ShopChair,
              text: 'Twelve chairs.',
              copies: 12,
              active: opened.contains('many'),
              onTap: onOpen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _G3TypeCard(
              id: 'much',
              title: 'HOW MUCH?',
              asset: _g3ShopMango,
              text: 'Ten pesos.',
              price: 10,
              active: opened.contains('much'),
              onTap: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _G3TypeCard extends StatelessWidget {
  final String id;
  final String title;
  final String asset;
  final String text;
  final int copies;
  final int? price;
  final bool active;
  final ValueChanged<String> onTap;

  const _G3TypeCard({
    required this.id,
    required this.title,
    required this.asset,
    required this.text,
    required this.active,
    required this.onTap,
    this.copies = 1,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: _g3SoftPanelDecoration(
          fill: active ? const Color(0xFFE3FFD8) : Colors.white,
          borderColor: active ? TudloColors.green : TudloColors.blue,
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      for (var index = 0; index < copies; index++)
                        SizedBox(
                          width: copies > 1 ? 26 : 76,
                          height: copies > 1 ? 26 : 76,
                          child: _LessonPictureAsset(asset: asset),
                        ),
                    ],
                  ),
                  if (price != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _G3PriceTag(price: price!, small: true),
                    ),
                ],
              ),
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.blue,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3ShopQuestionPage extends StatelessWidget {
  final String prompt;
  final String? stallAsset;
  final String? vendorAsset;
  final String productAsset;
  final int count;
  final int? price;
  final List<String> choices;
  final String answer;
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final Future<void> Function(String id, String answer) onChoose;
  final VoidCallback onNext;

  const _G3ShopQuestionPage({
    required this.prompt,
    required this.productAsset,
    required this.count,
    required this.choices,
    required this.answer,
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
    required this.onNext,
    this.stallAsset,
    this.vendorAsset,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: prompt,
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: correctId == null ? null : onNext,
      ),
      child: Column(
        children: [
          if (stallAsset != null)
            _G3MarketSceneLayer(
              stallAsset: stallAsset!,
              vendorAsset: vendorAsset,
            ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              _G3ObjectTray(
                baseAsset: _g3ShopTray,
                objectAssets: [
                  for (var index = 0; index < count; index++) productAsset,
                ],
              ),
              if (price != null)
                Positioned(
                  right: 14,
                  top: 8,
                  child: _G3PriceTag(price: price!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _G3TextChoiceWrap(
            choices: choices,
            wrongId: wrongId,
            correctId: correctId,
            wrongPulse: wrongPulse,
            onChoose: (id) => unawaited(onChoose(id, answer)),
          ),
        ],
      ),
    );
  }
}

class _G3AgeQuestionPage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final Future<void> Function(String id, String answer) onChoose;
  final VoidCallback onNext;

  const _G3AgeQuestionPage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Juan has eight birthday candles. How old is Juan?',
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: correctId == null ? null : onNext,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              children: [
                const Expanded(child: _LessonPictureAsset(asset: _g3ShopBoy)),
                Expanded(
                  flex: 2,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < 8; i++)
                        const SizedBox(
                          width: 34,
                          height: 54,
                          child: _LessonPictureAsset(asset: _g3ShopCandle),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _G3TextChoiceWrap(
            choices: const ['Eight years old', 'Eight candles', 'Eight pesos'],
            wrongId: wrongId,
            correctId: correctId,
            wrongPulse: wrongPulse,
            onChoose: (id) => unawaited(onChoose(id, 'Eight years old')),
          ),
        ],
      ),
    );
  }
}

class _G3PriceOnlyPage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final Future<void> Function(String id, String answer) onChoose;
  final VoidCallback onNext;

  const _G3PriceOnlyPage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'How much is it?',
      footer: _LessonOneBlueButton(
        label: 'Sunod',
        onTap: correctId == null ? null : onNext,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: _LessonPictureAsset(asset: _g3ShopCoin),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 112,
                height: 84,
                child: _LessonPictureAsset(asset: _g3ShopBill),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _G3PriceTag(price: 20),
          const SizedBox(height: 12),
          _G3TextChoiceWrap(
            choices: const ['Twenty pesos', 'Twenty items', 'Twelve pesos'],
            wrongId: wrongId,
            correctId: correctId,
            wrongPulse: wrongPulse,
            onChoose: (id) => unawaited(onChoose(id, 'Twenty pesos')),
          ),
        ],
      ),
    );
  }
}

class _G3TextChoiceWrap extends StatelessWidget {
  final List<String> choices;
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final ValueChanged<String> onChoose;

  const _G3TextChoiceWrap({
    required this.choices,
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final choice in choices)
          _FeedbackMotion(
            key: ValueKey('shop-choice-$choice-$wrongPulse-$correctId'),
            correct: correctId == choice,
            wrong: wrongId == choice,
            child: GradeThreePressable(
              onTap: correctId == null ? () => onChoose(choice) : null,
              borderRadius: 20,
              child: Container(
                constraints: const BoxConstraints(minWidth: 132, minHeight: 58),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: _g3SoftPanelDecoration(
                  fill: correctId == choice
                      ? const Color(0xFFE3FFD8)
                      : Colors.white,
                  borderColor: correctId == choice
                      ? TudloColors.green
                      : TudloColors.blue,
                ),
                child: Text(
                  choice,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: 18,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _G3PriceTag extends StatelessWidget {
  final int price;
  final bool small;

  const _G3PriceTag({required this.price, this.small = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: small ? 74 : 110,
      height: small ? 48 : 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: _LessonPictureAsset(asset: _g3ShopTag)),
          Text(
            'P$price',
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: small ? 18 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _G3PriceChoiceTag extends StatelessWidget {
  final int price;
  final bool correct;
  final bool wrong;

  const _G3PriceChoiceTag({
    required this.price,
    this.correct = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final tagWidth = (view.width * .285).clamp(168.0, 270.0);
    final tagHeight = (view.height * .245).clamp(132.0, 190.0);
    return SizedBox(
      width: tagWidth,
      height: tagHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (correct)
            Positioned.fill(
              child: Transform.scale(
                scale: 1.08,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TudloColors.green.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .42),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFF69B).withValues(alpha: .46),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Positioned.fill(
            child: _LessonPictureAsset(asset: _g3ShopTag, fit: BoxFit.fill),
          ),
          Positioned(
            left: tagWidth * .24,
            right: tagWidth * .18,
            top: tagHeight * .48,
            height: tagHeight * .30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$price\nPESOS',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: (view.width * .031).clamp(19.0, 30.0),
                  height: .9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _G3ShopSentencePage extends StatelessWidget {
  final List<String?> slots;
  final String? selectedTile;
  final int wrongPulse;
  final bool ready;
  final ValueChanged<String> onSelectTile;
  final void Function(String tile, int slot) onPlace;
  final ValueChanged<int> onTapSlot;
  final VoidCallback? onNext;

  const _G3ShopSentencePage({
    required this.slots,
    required this.selectedTile,
    required this.wrongPulse,
    required this.ready,
    required this.onSelectTile,
    required this.onPlace,
    required this.onTapSlot,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    const tiles = ['ten pesos.', 'It costs'];
    final placed = slots.whereType<String>().toSet();
    return _G3MarketContentFrame(
      prompt: 'Ihay-an',
      footer: const SizedBox.shrink(),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .76,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: view.width * .055,
              bottom: -view.height * .24,
              child: _LessonKokaMascot(
                size: (view.width * .48).clamp(200.0, 315.0),
                mood: KokaMood.idle,
              ),
            ),
            Positioned(
              left: view.width * .34,
              right: view.width * .02,
              top: view.height * .21,
              child: Row(
                children: [
                  for (var index = 0; index < slots.length; index++) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTapSlot(index),
                        child: IgnorePointer(
                          ignoring: !ready,
                          child: _G3SentenceSlot(
                            index: index + 1,
                            value: slots[index],
                            onAccept: (tile) => onPlace(tile, index),
                          ),
                        ),
                      ),
                    ),
                    if (index < slots.length - 1)
                      SizedBox(width: view.width * .025),
                  ],
                ],
              ),
            ),
            Positioned(
              left: view.width * .37,
              right: view.width * .03,
              top: view.height * .42,
              child: Row(
                children: [
                  for (final tile in tiles)
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: placed.contains(tile) ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: !ready || placed.contains(tile),
                          child: GestureDetector(
                            onTap: () => onSelectTile(tile),
                            child: _G3SentenceTile(
                              label: tile,
                              selected: selectedTile == tile,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: view.width * .025),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _G3SpeakAtStallPage extends StatelessWidget {
  final bool done;
  final VoidCallback onRecord;
  final VoidCallback? onNext;

  const _G3SpeakAtStallPage({
    required this.done,
    required this.onRecord,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Ten pesos, please!',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        children: [
          const _G3MarketSceneLayer(
            stallAsset: _g3ShopCounter,
            vendorAsset: _g3ShopVendor,
          ),
          const SizedBox(height: 10),
          const _G3ResultText(text: 'Ten   pesos   please!'),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRecord,
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: TudloColors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 58,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _G3ShoppingRound {
  final String label;
  final String asset;
  final int quantity;
  final List<int> prices;

  const _G3ShoppingRound({
    required this.label,
    required this.asset,
    required this.quantity,
    required this.prices,
  });
}

const List<_G3ShoppingRound> _g3ShoppingRounds = [
  _G3ShoppingRound(
    label: 'bananas',
    asset: _g3ShopBanana,
    quantity: 4,
    prices: [15, 20, 25],
  ),
  _G3ShoppingRound(
    label: 'eggs',
    asset: _g3ShopEgg,
    quantity: 6,
    prices: [12, 18, 20],
  ),
  _G3ShoppingRound(
    label: 'cups',
    asset: _g3ShopCup,
    quantity: 2,
    prices: [8, 10, 12],
  ),
  _G3ShoppingRound(
    label: 'mangoes',
    asset: _g3ShopMango,
    quantity: 3,
    prices: [20, 30, 40],
  ),
  _G3ShoppingRound(
    label: 'fish',
    asset: _g3ShopFish,
    quantity: 1,
    prices: [10, 15, 25],
  ),
];

class _G3ShoppingListPage extends StatelessWidget {
  final _G3ShoppingRound round;
  final int roundIndex;
  final _G3ShopPhase phase;
  final int basketCount;
  final int basketPulse;
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Future<void> Function() onCheckQuantity;
  final ValueChanged<int> onChoosePrice;

  const _G3ShoppingListPage({
    required this.round,
    required this.roundIndex,
    required this.phase,
    required this.basketCount,
    required this.basketPulse,
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onAdd,
    required this.onRemove,
    required this.onCheckQuantity,
    required this.onChoosePrice,
  });

  @override
  Widget build(BuildContext context) {
    final quantityPhase = phase == _G3ShopPhase.quantity;
    return _G3MarketContentFrame(
      prompt: quantityPhase
          ? '${round.quantity} ${round.label}'
          : 'Tap ang presyo sang ${round.label}.',
      footer: _LessonOneBlueButton(
        label: quantityPhase ? 'Sabat' : 'Padayon',
        onTap: quantityPhase && basketCount > 0
            ? () => unawaited(onCheckQuantity())
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 82,
                height: 120,
                child: _LessonPictureAsset(asset: _g3ShopNanayBasket),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      height: 120,
                      child: _LessonPictureAsset(asset: _g3ShopList),
                    ),
                    Text(
                      '${roundIndex + 1}/5\n${round.quantity} ${round.label}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: TudloColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (quantityPhase) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < round.quantity + 3; i++)
                  Draggable<int>(
                    data: i,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: _LessonPictureAsset(asset: round.asset),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: onAdd,
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: _LessonPictureAsset(asset: round.asset),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DragTarget<int>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (_) => onAdd(),
              builder: (context, candidate, rejected) {
                return _FeedbackMotion(
                  key: ValueKey('basket-$basketPulse'),
                  correct: false,
                  wrong: basketPulse > 0,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      height: 118,
                      padding: const EdgeInsets.all(10),
                      decoration: _g3SoftPanelDecoration(
                        borderColor: candidate.isNotEmpty
                            ? TudloColors.green
                            : TudloColors.blue,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const _LessonPictureAsset(asset: _g3ShopBasket),
                          Text(
                            '$basketCount/${round.quantity}',
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
              },
            ),
          ] else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final price in round.prices)
                  _FeedbackMotion(
                    key: ValueKey('price-$price-$wrongPulse-$correctId'),
                    correct: correctId == '$price',
                    wrong: wrongId == '$price',
                    child: GestureDetector(
                      onTap: correctId == null
                          ? () => onChoosePrice(price)
                          : null,
                      child: _G3PriceTag(price: price),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _G3ShopReviewPage extends StatelessWidget {
  final Set<int> done;
  final String? wrongId;
  final int wrongPulse;
  final void Function(int index, String id) onAnswer;
  final VoidCallback? onNext;

  const _G3ShopReviewPage({
    required this.done,
    required this.wrongId,
    required this.wrongPulse,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const cards = [
      ('How old?', 'Age', 'age'),
      ('How many?', 'Quantity', 'quantity'),
      ('How much?', 'Price', 'price'),
    ];
    return _G3MarketContentFrame(
      prompt: 'Balikan ta ang tatlo ka pangutana.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Column(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Text(
              cards[index].$1,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            _G3TextChoiceWrap(
              choices: const ['Age', 'Quantity', 'Price'],
              wrongId: wrongId,
              correctId: done.contains(index) ? cards[index].$2 : null,
              wrongPulse: wrongPulse,
              onChoose: (label) => onAnswer(index, label.toLowerCase()),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _G3ShopRewardPage extends StatelessWidget {
  final String stickerAsset;
  final VoidCallback onBackToMap;
  final VoidCallback onContinue;

  const _G3ShopRewardPage({
    required this.stickerAsset,
    required this.onBackToMap,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return GradeThreeStickerRewardOverlay(
      stickerAsset: stickerAsset,
      message: 'Maayo gid!\nMaalam ka na mamakal.',
      primaryLabel: 'PADAYON KITA',
      onPrimary: onContinue,
      secondaryLabel: 'BALIK SA MAPA',
      onSecondary: onBackToMap,
    );
  }
}
