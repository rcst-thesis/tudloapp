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
  priceDemo,
  priceChoice,
  ageContrast,
  ageChoice,
  sentenceModel,
  sentenceArrange,
  reward,
}

enum _G3ShopPhase { quantity, price }

class _GradeThreeShoppingFlow extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onLessonComplete;

  const _GradeThreeShoppingFlow({
    required this.onExit,
    required this.onLessonComplete,
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

  double get _progress =>
      (_G3ShopStep.values.indexOf(_step) + 1) / _G3ShopStep.values.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playStepVoice();
    });
  }

  void _next() {
    final index = _G3ShopStep.values.indexOf(_step);
    if (index >= _G3ShopStep.values.length - 1) return;
    setState(() {
      _step = _G3ShopStep.values[index + 1];
      _wrongId = null;
      _correctId = null;
      _selectedTile = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playStepVoice();
    });
  }

  int _clipForStep() {
    return switch (_step) {
      _G3ShopStep.listIntro => _listOpen ? 2 : 1,
      _G3ShopStep.map => 3,
      _G3ShopStep.stallHotspot => 4,
      _G3ShopStep.priceDemo => 5,
      _G3ShopStep.priceChoice => 6,
      _G3ShopStep.ageContrast => 7,
      _G3ShopStep.ageChoice => 8,
      _G3ShopStep.sentenceModel => 9,
      _G3ShopStep.sentenceArrange => 10,
      _G3ShopStep.reward => 11,
    };
  }

  Future<void> _playClip(int clip) async {
    await TudloVoiceButton.stop();
    await AppAudioService.instance.lowerBackgroundVolume();
    try {
      await AppAudioService.instance.playVoiceAssets([
        'audio/VO-final/grade3/Gr_3_Les_1_3_$clip.wav',
      ]);
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
  }

  Future<void> _playStepVoice() => _playClip(_clipForStep());

  Future<void> _choose(String id, String answer) async {
    if (_correctId != null) return;
    if (id != answer) {
      setState(() {
        _wrongId = id;
        _wrongPulse++;
      });
      await AppAudioService.instance.playWrong();
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
      await _playClip(7);
    } else if (_step == _G3ShopStep.ageChoice) {
      await _playClip(9);
    }
  }

  Future<void> _placeSentence(String tile, int slot) async {
    const answer = ['It costs', 'ten pesos.'];
    if (tile != answer[slot]) {
      setState(() => _wrongPulse++);
      await AppAudioService.instance.playWrong();
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        'Hmmm, hindi amo na.',
        hiligaynon: true,
      );
      return;
    }
    setState(() {
      _sentenceSlots[slot] = tile;
      _selectedTile = null;
    });
    if (_sentenceSlots.indexed.every((entry) => entry.$2 == answer[entry.$1])) {
      await AppAudioService.instance.playCorrect();
    }
  }

  Future<void> _openList() async {
    if (_listOpen) return;
    setState(() => _listOpen = true);
    await AppAudioService.instance.playCorrect();
    await _playClip(2);
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
          onOpen: () => unawaited(_openList()),
          onNext: _listOpen ? _next : null,
        ),
        _G3ShopStep.map => _G3ShopMapPage(
          onTapMarket: () => unawaited(_hotspotNext(clip: 4)),
        ),
        _G3ShopStep.stallHotspot => _G3ShopBananaStallPage(
          prompt: 'Pangitaa ang banana stall.',
          onTapStall: () => unawaited(_hotspotNext()),
        ),
        _G3ShopStep.priceDemo => _G3ShopBananaPriceDemo(onNext: _next),
        _G3ShopStep.priceChoice => _G3ShopPriceChoicePage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          onChoose: (id) => unawaited(_choose(id, '10')),
          onNext: _correctId == null ? null : _next,
        ),
        _G3ShopStep.ageContrast => _G3ShopAgeContrastPage(onNext: _next),
        _G3ShopStep.ageChoice => _G3ShopAgeChoicePage(
          wrongId: _wrongId,
          correctId: _correctId,
          wrongPulse: _wrongPulse,
          onChoose: (id) => unawaited(_choose(id, 'I am nine years old.')),
          onNext: _correctId == null ? null : _next,
        ),
        _G3ShopStep.sentenceModel => _G3ShopSentenceModelPage(onNext: _next),
        _G3ShopStep.sentenceArrange => _G3ShopSentencePage(
          slots: _sentenceSlots,
          selectedTile: _selectedTile,
          wrongPulse: _wrongPulse,
          onSelectTile: (tile) => setState(() => _selectedTile = tile),
          onPlace: (tile, slot) => unawaited(_placeSentence(tile, slot)),
          onTapSlot: (slot) {
            final tile = _selectedTile;
            if (tile != null) unawaited(_placeSentence(tile, slot));
          },
          onNext: _sentenceSlots.every((value) => value != null) ? _next : null,
        ),
        _G3ShopStep.reward => _G3ShopRewardPage(
          onComplete: widget.onLessonComplete,
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
    onChoose: (selectedChoice, selectedAnswer) async {},
    onNext: () {},
  ),
  _G3AgeQuestionPage(
    wrongId: null,
    correctId: null,
    wrongPulse: 0,
    onChoose: (selectedChoice, selectedAnswer) async {},
    onNext: () {},
  ),
  _G3PriceOnlyPage(
    wrongId: null,
    correctId: null,
    wrongPulse: 0,
    onChoose: (selectedChoice, selectedAnswer) async {},
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
    onAnswer: (selectedQuestion, selectedAnswer) {},
    onNext: null,
  ),
);

class _G3ShopListIntroPage extends StatelessWidget {
  final bool opened;
  final VoidCallback onOpen;
  final VoidCallback? onNext;

  const _G3ShopListIntroPage({
    required this.opened,
    required this.onOpen,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: opened
          ? 'Bukas ang shopping list. Saging ang unahon ta.'
          : 'May listahan ako sang baklon. Buligi ako gamit ang numero.',
      showContentPanel: false,
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: SizedBox(
        height: view.height * .54,
        child: Stack(
          children: [
            Positioned(
              left: -view.width * .02,
              bottom: 0,
              child: _LessonKokaMascot(
                size: (view.width * .34).clamp(130.0, 190.0),
                mood: KokaMood.hi,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: 170,
              height: 238,
              child: _LessonPictureAsset(
                asset: opened ? _g3ShopNanayBasket : _g3ShopNanayList,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: view.width * .30,
              right: view.width * .02,
              top: 0,
              bottom: 4,
              child: GestureDetector(
                onTap: onOpen,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const _LessonPictureAsset(
                      asset: _g3ShopList,
                      fit: BoxFit.contain,
                    ),
                    if (opened)
                      Positioned(
                        top: view.height * .105,
                        left: view.width * .055,
                        right: view.width * .055,
                        child: Text(
                          'saging\nP10',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: TudloColors.ink,
                            fontSize: 24,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: view.height * .10,
                        child: SizedBox(
                          width: (view.width * .12).clamp(54.0, 86.0),
                          child: const _LessonPictureAsset(
                            asset: _g3ShopPointFinger,
                            fit: BoxFit.contain,
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

class _G3ShopMapPage extends StatelessWidget {
  final VoidCallback onTapMarket;

  const _G3ShopMapPage({required this.onTapMarket});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Kadtu kita sa Market. I-tap ang banana stall.',
      footer: const SizedBox(height: 64),
      child: GestureDetector(
        onTap: onTapMarket,
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
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
      ),
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
        height: view.height * .54,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 2,
              child: _LessonKokaMascot(
                size: (view.width * .34).clamp(130.0, 190.0),
                mood: KokaMood.hi,
              ),
            ),
            Positioned(
              left: view.width * .02,
              top: 0,
              width: (view.width * .18).clamp(76.0, 118.0),
              height: (view.height * .24).clamp(118.0, 168.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _LessonPictureAsset(
                    asset: _g3ShopList,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    top: 42,
                    left: 10,
                    right: 10,
                    child: Text(
                      'SAGING\nPresyo: --',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: TudloColors.ink,
                        fontSize: 14,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: view.width * .02,
              bottom: 0,
              width: (view.width * .52).clamp(260.0, 430.0),
              height: (view.height * .42).clamp(220.0, 330.0),
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

class _G3ShopBananaPriceDemo extends StatelessWidget {
  final VoidCallback onNext;

  const _G3ShopBananaPriceDemo({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'Ang saging nagabalor ten pesos.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .54,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 4,
              child: _LessonKokaMascot(
                size: (view.width * .34).clamp(130.0, 190.0),
                mood: KokaMood.hi,
              ),
            ),
            Positioned(
              right: -view.width * .015,
              bottom: 0,
              width: (view.width * .56).clamp(280.0, 450.0),
              height: (view.height * .44).clamp(235.0, 350.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: (view.height * .25).clamp(132.0, 206.0),
                    child: const _LessonPictureAsset(
                      asset: _g3ShopCounter,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: view.width * .03,
                    right: view.width * .02,
                    height: (view.height * .22).clamp(120.0, 176.0),
                    child: const _LessonPictureAsset(
                      asset: _g3ShopBananasBunch,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: (view.height * .035).clamp(18.0, 32.0),
                    child: const _G3PriceTag(price: 10),
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

class _G3ShopPriceChoicePage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final ValueChanged<String> onChoose;
  final VoidCallback? onNext;

  const _G3ShopPriceChoicePage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'Tan-awa ang tatlo ka price tag kag pilia ang ten pesos.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              width: (view.width * .76).clamp(420.0, 650.0),
              height: (view.height * .47).clamp(250.0, 370.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: (view.height * .27).clamp(145.0, 215.0),
                    child: const _LessonPictureAsset(
                      asset: _g3ShopCounter,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: view.width * .10,
                    right: view.width * .10,
                    height: (view.height * .23).clamp(126.0, 184.0),
                    child: const _LessonPictureAsset(
                      asset: _g3ShopBananasBunch,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: view.width * .02,
                    right: view.width * .02,
                    bottom: (view.height * .03).clamp(16.0, 28.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final price in const [8, 12, 10])
                          _FeedbackMotion(
                            key: ValueKey(
                              'g3-shop-price-$price-$wrongPulse-$correctId',
                            ),
                            correct: correctId == '$price',
                            wrong: wrongId == '$price',
                            child: GestureDetector(
                              onTap: correctId == null
                                  ? () => onChoose('$price')
                                  : null,
                              child: _G3PriceChoiceTag(
                                price: price,
                                correct: correctId == '$price',
                                wrong: wrongId == '$price',
                              ),
                            ),
                          ),
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

class _G3ShopAgeContrastPage extends StatelessWidget {
  final VoidCallback onNext;

  const _G3ShopAgeContrastPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'How old are you? Nine years old ang bata.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: Row(
        children: [
          const Expanded(
            child: SizedBox(
              height: 190,
              child: _LessonPictureAsset(asset: _g3ShopBoy),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: _g3SoftPanelDecoration(),
              child: Text(
                'How old?\n\nI am nine years old.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 25,
                  height: 1.1,
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

class _G3ShopAgeChoicePage extends StatelessWidget {
  final String? wrongId;
  final String? correctId;
  final int wrongPulse;
  final ValueChanged<String> onChoose;
  final VoidCallback? onNext;

  const _G3ShopAgeChoicePage({
    required this.wrongId,
    required this.correctId,
    required this.wrongPulse,
    required this.onChoose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    return _G3MarketContentFrame(
      prompt: 'Pilia ang sabat nga I am nine years old.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .54,
        child: Stack(
          children: [
            Positioned(
              left: -view.width * .015,
              bottom: 0,
              child: _LessonKokaMascot(
                size: (view.width * .24).clamp(104.0, 150.0),
                mood: KokaMood.hi,
              ),
            ),
            Positioned(
              left: view.width * .08,
              bottom: 0,
              width: (view.width * .22).clamp(118.0, 180.0),
              height: (view.height * .43).clamp(230.0, 340.0),
              child: const _LessonPictureAsset(
                asset: _g3ShopAgeBoy,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: view.width * .31,
              right: 0,
              top: view.height * .08,
              bottom: view.height * .05,
              child: Row(
                children: [
                  for (final choice in const [
                    'I am eight years old.',
                    'I am ten years old.',
                    'I am nine years old.',
                  ]) ...[
                    Expanded(
                      child: _FeedbackMotion(
                        key: ValueKey(
                          'shop-age-choice-$choice-$wrongPulse-$correctId',
                        ),
                        correct: correctId == choice,
                        wrong: wrongId == choice,
                        child: GestureDetector(
                          onTap: correctId == null
                              ? () => onChoose(choice)
                              : null,
                          child: _G3AgeChoiceCard(
                            label: choice,
                            correct: correctId == choice,
                            wrong: wrongId == choice,
                          ),
                        ),
                      ),
                    ),
                    if (choice != 'I am nine years old.')
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

class _G3ShopSentenceModelPage extends StatelessWidget {
  final VoidCallback onNext;

  const _G3ShopSentenceModelPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Ihan-ay: It costs - ten pesos.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      child: const Column(
        children: [
          _G3PriceTag(price: 10),
          SizedBox(height: 16),
          _G3ResultText(text: 'It costs ten pesos.'),
        ],
      ),
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
                mood: KokaMood.hi,
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
            child: GestureDetector(
              onTap: correctId == null ? () => onChoose(choice) : null,
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
    final glowColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : null;
    return SizedBox(
      width: (view.width * .20).clamp(104.0, 154.0),
      height: (view.height * .12).clamp(66.0, 92.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glowColor != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 1.04,
                child: LessonAssetGlow(
                  asset: _g3ShopTag,
                  fallbackIcon: Icons.local_offer_rounded,
                  fallbackSize: (view.width * .13).clamp(68.0, 100.0),
                  color: glowColor,
                ),
              ),
            ),
          const Positioned.fill(
            child: _LessonPictureAsset(asset: _g3ShopTag, fit: BoxFit.fill),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(
              '$price\nPESOS',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: (view.width * .032).clamp(18.0, 28.0),
                height: .86,
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

class _G3ShopSentencePage extends StatelessWidget {
  final List<String?> slots;
  final String? selectedTile;
  final int wrongPulse;
  final ValueChanged<String> onSelectTile;
  final void Function(String tile, int slot) onPlace;
  final ValueChanged<int> onTapSlot;
  final VoidCallback? onNext;

  const _G3ShopSentencePage({
    required this.slots,
    required this.selectedTile,
    required this.wrongPulse,
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
      prompt: 'Ihan-ay ang It costs kag ten pesos.',
      footer: _LessonOneBlueButton(label: 'Sunod', onTap: onNext),
      showContentPanel: false,
      child: SizedBox(
        height: view.height * .54,
        child: Stack(
          children: [
            Positioned(
              left: -view.width * .02,
              bottom: 0,
              child: _LessonKokaMascot(
                size: (view.width * .34).clamp(136.0, 206.0),
                mood: KokaMood.hi,
              ),
            ),
            Positioned(
              left: view.width * .28,
              right: view.width * .02,
              top: view.height * .075,
              child: Row(
                children: [
                  for (var index = 0; index < slots.length; index++) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTapSlot(index),
                        child: _G3SentenceSlot(
                          index: index + 1,
                          value: slots[index],
                          onAccept: (tile) => onPlace(tile, index),
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
              left: view.width * .31,
              right: view.width * .03,
              top: view.height * .255,
              child: Row(
                children: [
                  for (final tile in tiles)
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: placed.contains(tile) ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: placed.contains(tile),
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
  final VoidCallback onComplete;

  const _G3ShopRewardPage({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return _G3MarketContentFrame(
      prompt: 'Maayo gid! Maalam ka na mamakal.',
      footer: Row(
        children: [
          Expanded(
            child: _LessonOneBlueButton(
              label: 'Balik sa Mapa',
              onTap: onComplete,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LessonOneBlueButton(label: 'Padayon', onTap: onComplete),
          ),
        ],
      ),
      child: const Column(
        children: [
          _LessonKokaMascot(size: 132, mood: KokaMood.hi),
          SizedBox(height: 8),
          Icon(
            Icons.workspace_premium_rounded,
            color: TudloColors.gold,
            size: 112,
          ),
          SizedBox(height: 8),
          _G3ResultText(text: 'NUMERO UNIT'),
        ],
      ),
    );
  }
}
