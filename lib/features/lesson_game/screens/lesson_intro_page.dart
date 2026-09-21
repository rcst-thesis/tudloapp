import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';

class LessonIntroPage extends StatefulWidget {
  final int level;

  const LessonIntroPage({super.key, required this.level});

  @override
  State<LessonIntroPage> createState() => _LessonIntroPageState();
}

class _LessonIntroPageState extends State<LessonIntroPage> {
  late final Future<LevelContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = () async {
      final content = await LessonBank.loadLevelContentForLevel(widget.level);
      await AppAudioService.instance.preloadLessonAudio(content.audioAssets);
      return content;
    }();
    unawaited(DictionaryData.initialize());
  }

  int get _localLessonNumber => AppData.lessonNumberForLevel(widget.level);

  void _openLessonGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LevelGamePage(level: widget.level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final screenWidth = screen.width;
    final horizontalPadding = screenWidth < 380 ? 22.0 : 30.0;
    final topContentGap = (screen.height * .035).clamp(14.0, 36.0).toDouble();

    return Scaffold(
      backgroundColor: TudloColors.paper,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            22,
          ),
          child: Column(
            children: [
              _IntroHeader(
                lessonNumber: _localLessonNumber,
                onBack: () => Navigator.pop(context),
              ),
              SizedBox(height: topContentGap),
              Expanded(
                child: FutureBuilder<LevelContent>(
                  future: _contentFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    final content = snapshot.data;
                    if (content == null) {
                      return const Center(
                        child: Text(
                          'Wala nakita ang leksiyon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }

                    return _AnimatedLessonIntroContent(
                      key: ValueKey(content.id),
                      lessonNumber: _localLessonNumber,
                      content: content,
                      onStart: _openLessonGame,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroHeader extends StatelessWidget {
  final int lessonNumber;
  final VoidCallback onBack;

  const _IntroHeader({required this.lessonNumber, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final backButtonSize = screenWidth < 380 ? 48.0 : 56.0;

    return Row(
      children: [
        SizedBox(
          width: backButtonSize,
          height: backButtonSize,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: TudloColors.blue,
              size: screenWidth < 380 ? 34 : 42,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Leksiyon $lessonNumber',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.forest,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        SizedBox(width: backButtonSize),
      ],
    );
  }
}

class _AnimatedLessonIntroContent extends StatefulWidget {
  final int lessonNumber;
  final LevelContent content;
  final VoidCallback onStart;

  const _AnimatedLessonIntroContent({
    super.key,
    required this.lessonNumber,
    required this.content,
    required this.onStart,
  });

  @override
  State<_AnimatedLessonIntroContent> createState() =>
      _AnimatedLessonIntroContentState();
}

class _AnimatedLessonIntroContentState
    extends State<_AnimatedLessonIntroContent> {
  int _visibleLetters = 0;
  bool _showStart = false;
  bool _introVoicePlaying = false;
  late final List<_IntroLetterItem> _letters;
  late final String _introVoiceText;
  int _voiceRun = 0;

  @override
  void initState() {
    super.initState();
    _letters = _introLettersFor(widget.content);
    _introVoiceText = _introVoiceFor(widget.content, _letters);
    unawaited(_playLetterAnimation());
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) unawaited(_playIntroVoice());
    });
  }

  Future<void> _playLetterAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (_letters.isEmpty) {
      if (mounted) {
        setState(() {
          _showStart = true;
        });
      }
      return;
    }

    for (var index = 0; index < _letters.length; index++) {
      if (!mounted) return;
      setState(() => _visibleLetters = index + 1);
      await Future<void>.delayed(const Duration(milliseconds: 170));
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _showStart = true);
  }

  Future<void> _playIntroVoice() async {
    final run = ++_voiceRun;
    setState(() {
      _introVoicePlaying = true;
      _showStart = true;
    });
    await TudloVoiceButton.speak(
      context,
      _introVoiceText,
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted || run != _voiceRun) return;
    setState(() => _introVoicePlaying = false);
  }

  String _introVoiceFor(LevelContent content, List<_IntroLetterItem> items) {
    final labels = items
        .map((item) => item.label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    final spokenLabels = labels.map(_introVoiceLabelFor).toList();
    final allNumbers =
        labels.isNotEmpty &&
        labels.every((label) => RegExp(r'^\d+$').hasMatch(label));
    if (allNumbers) {
      return 'Tuon ta ang mga numero ${_joinHiligaynonList(spokenLabels)}.';
    }

    final contentText = spokenLabels.isNotEmpty
        ? _joinHiligaynonList(spokenLabels)
        : _cleanLessonTitle(content.title);
    final needsArticle = spokenLabels.isEmpty
        ? true
        : spokenLabels.any((label) => !RegExp(r'^[A-Z]$').hasMatch(label));
    return needsArticle
        ? 'Tuon ta ang ${contentText.toLowerCase()}.'
        : 'Tuon ta $contentText.';
  }

  String _introVoiceLabelFor(String label) {
    return _hiligaynonNumberWord(label) ?? label;
  }

  String? _hiligaynonNumberWord(String label) {
    return const {
      '0': 'sero',
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
    }[label.trim()];
  }

  String _joinHiligaynonList(List<String> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} kag ${values.last}';
    return '${values.take(values.length - 1).join(', ')}, kag ${values.last}';
  }

  String _cleanLessonTitle(String title) {
    return title
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'^\s*Letters\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*Numbers\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 690;
        final buttonHeight = compactHeight ? 62.0 : 72.0;
        final buttonGap = compactHeight ? 10.0 : 18.0;
        final headingHeight = (constraints.maxHeight * .24)
            .clamp(118.0, 184.0)
            .toDouble();
        final headingWidth = headingHeight * 260 / 184;

        return Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TuonTaHeading(width: headingWidth, height: headingHeight),
                  SizedBox(height: compactHeight ? 6 : 12),
                  Expanded(
                    child: _IntroLetterGrid(
                      children: [
                        for (var index = 0; index < _letters.length; index++)
                          _AnimatedIntroLetterCard(
                            item: _letters[index],
                            index: index,
                            visible: index < _visibleLetters,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: buttonGap),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _showStart
                  ? _IntroStartButton(
                      height: buttonHeight,
                      onPressed: _introVoicePlaying ? null : widget.onStart,
                    )
                  : SizedBox(height: buttonHeight),
            ),
          ],
        );
      },
    );
  }

  List<_IntroLetterItem> _introLettersFor(LevelContent content) {
    if (content.gradeLevel == 1 &&
        content.unitNumber == 2 &&
        content.lessonNumber == 1) {
      return const [
        _IntroLetterItem(
          label: 'pamilya',
          asset: 'assets/images/level_game/people/pamilya.png',
          large: true,
        ),
      ];
    }

    if (content.gradeLevel == 1 && content.unitNumber == 4) {
      return _animalIntroItemsFor(content.lessonNumber);
    }

    if (content.gradeLevel == 1 && content.unitNumber == 3) {
      return _helperIntroItemsFor(content.lessonNumber);
    }

    if (content.gradeLevel == 1 && content.unitNumber == 5) {
      return _placeIntroItemsFor(content.lessonNumber);
    }

    if (content.gradeLevel == 2) {
      return _gradeTwoIntroItemsFor(content.unitNumber, content.lessonNumber);
    }

    if (content.gradeLevel == 1 &&
        content.unitNumber == 1 &&
        content.lessonNumber >= 7) {
      final numberItems = switch (content.lessonNumber) {
        7 => const ['1', '2', '3', '4', '5'],
        8 => const ['6', '7', '8', '9', '0'],
        _ => const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
      };
      return numberItems.map(_letterItem).toList();
    }

    final titleLetters = RegExp(
      r'\b[A-Z]\b',
    ).allMatches(content.title).map((match) => match.group(0)!).toList();
    if (titleLetters.isNotEmpty) return titleLetters.map(_letterItem).toList();

    if (content.gradeLevel == 1 && content.unitNumber == 1) {
      final fallbackLetters = switch (content.lessonNumber) {
        1 => const ['A', 'N', 'T', 'Y'],
        2 => const ['I', 'D', 'O'],
        3 => const ['M', 'K', 'U'],
        4 => const ['B', 'L', 'S'],
        5 => const ['E', 'G', 'P'],
        _ => const ['R', 'H', 'W', 'C'],
      };
      return fallbackLetters.map(_letterItem).toList();
    }

    return _plainIntroLabelsFor(
      content.title,
    ).map((label) => _IntroLetterItem(label: label)).toList();
  }

  _IntroLetterItem _letterItem(String letter) {
    return _IntroLetterItem(
      label: letter,
      asset: const {
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
      }[letter.toUpperCase()],
      pictureOnly: true,
    );
  }

  List<_IntroLetterItem> _animalIntroItemsFor(int lessonNumber) {
    const dog = _IntroLetterItem(
      label: 'ido',
      asset: 'assets/images/level_game/animals/dog.png',
      pictureOnly: true,
    );
    const cat = _IntroLetterItem(
      label: 'kuring',
      asset: 'assets/images/level_game/animals/cat.png',
      pictureOnly: true,
    );
    const chicken = _IntroLetterItem(
      label: 'manok',
      asset: 'assets/images/level_game/animals/chicken.png',
      pictureOnly: true,
    );
    const pig = _IntroLetterItem(
      label: 'baboy',
      asset: 'assets/images/level_game/animals/pig.png',
      icon: Icons.pets_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const cow = _IntroLetterItem(
      label: 'baka',
      asset: 'assets/images/level_game/animals/cow.png',
      pictureOnly: true,
    );
    const carabao = _IntroLetterItem(
      label: 'karbaw',
      asset: 'assets/images/level_game/animals/carabao.png',
      icon: Icons.agriculture_rounded,
      color: TudloColors.forest,
      pictureOnly: true,
    );
    const fish = _IntroLetterItem(
      label: 'isda',
      asset: 'assets/images/level_game/animals/fish.png',
      icon: Icons.water_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const bird = _IntroLetterItem(
      label: 'pispis',
      asset: 'assets/images/level_game/animals/bird.png',
      icon: Icons.flutter_dash_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const goat = _IntroLetterItem(
      label: 'kanding',
      asset: 'assets/images/level_game/animals/goat.png',
      icon: Icons.pets_rounded,
      color: TudloColors.meadow,
      pictureOnly: true,
    );

    return switch (lessonNumber) {
      1 => const [dog, cat, chicken],
      2 => const [pig, cow, carabao],
      3 => const [fish, bird, goat],
      _ => const [dog, cat, chicken],
    };
  }

  List<_IntroLetterItem> _helperIntroItemsFor(int lessonNumber) {
    const teacher = _IntroLetterItem(
      label: 'manunudlo',
      asset: 'assets/images/level_game/people/manunudlo.png',
      icon: Icons.school_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const doctor = _IntroLetterItem(
      label: 'doktor',
      asset: 'assets/images/level_game/people/doktor.png',
      icon: Icons.medical_services_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const nurse = _IntroLetterItem(
      label: 'nars',
      asset: 'assets/images/level_game/people/nars.png',
      icon: Icons.medical_information_rounded,
      color: TudloColors.orange,
      pictureOnly: true,
    );
    const police = _IntroLetterItem(
      label: 'pulis',
      asset: 'assets/images/level_game/people/pulis.png',
      icon: Icons.local_police_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const firefighter = _IntroLetterItem(
      label: 'bumbero',
      asset: 'assets/images/level_game/people/bumbero.png',
      icon: Icons.local_fire_department_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const vendor = _IntroLetterItem(
      label: 'tindera',
      asset: 'assets/images/level_game/tindera.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.gold,
      pictureOnly: true,
    );
    const farmer = _IntroLetterItem(
      label: 'mangunguma',
      asset: 'assets/images/level_game/people/mangunguma.png',
      icon: Icons.agriculture_rounded,
      color: TudloColors.forest,
      pictureOnly: true,
    );
    const fisher = _IntroLetterItem(
      label: 'mangingisda',
      asset: 'assets/images/level_game/people/mangingisda.png',
      icon: Icons.sailing_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );

    return switch (lessonNumber) {
      1 => const [teacher, doctor, nurse],
      2 => const [police, firefighter, vendor],
      3 => const [farmer, fisher],
      _ => const [teacher, doctor, nurse],
    };
  }

  List<_IntroLetterItem> _placeIntroItemsFor(int lessonNumber) {
    const house = _IntroLetterItem(
      label: 'balay',
      asset: 'assets/images/level_game/house.png',
      icon: Icons.home_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const school = _IntroLetterItem(
      label: 'eskwelahan',
      asset: 'assets/images/level_game/eskwelahan.png',
      icon: Icons.school_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const church = _IntroLetterItem(
      label: 'simbahan',
      asset: 'assets/images/level_game/simbahan.png',
      icon: Icons.church_rounded,
      color: TudloColors.forest,
      pictureOnly: true,
    );
    const market = _IntroLetterItem(
      label: 'tinda',
      asset: 'assets/images/level_game/tinda.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.gold,
      pictureOnly: true,
    );
    const plaza = _IntroLetterItem(
      label: 'plasa',
      asset: 'assets/images/level_game/plaza.png',
      icon: Icons.park_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const hospital = _IntroLetterItem(
      label: 'ospital',
      asset: 'assets/images/level_game/ospital.png',
      icon: Icons.local_hospital_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const farm = _IntroLetterItem(
      label: 'uma',
      asset: 'assets/images/level_game/uma.png',
      icon: Icons.agriculture_rounded,
      color: TudloColors.forest,
      pictureOnly: true,
    );
    const beach = _IntroLetterItem(
      label: 'baybay',
      asset: 'assets/images/level_game/baybay.png',
      icon: Icons.beach_access_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );

    return switch (lessonNumber) {
      1 => const [house, school, church],
      2 => const [market, plaza, hospital],
      3 => const [farm, beach],
      _ => const [house, school, market, hospital],
    };
  }

  List<_IntroLetterItem> _gradeTwoIntroItemsFor(
    int unitNumber,
    int lessonNumber,
  ) {
    const grade2 = 'assets/images/level_game';
    const school = _IntroLetterItem(
      label: 'school',
      asset: '$grade2/school-entrance.png',
      icon: Icons.school_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const juan = _IntroLetterItem(
      label: 'Juan',
      asset: 'assets/images/level_game/people/boy-juan.png',
      icon: Icons.face_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const ana = _IntroLetterItem(
      label: 'Ana',
      asset: 'assets/images/level_game/people/girl-ana.png',
      icon: Icons.face_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const cake = _IntroLetterItem(
      label: 'keyk',
      asset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const balloons = _IntroLetterItem(
      label: 'lobo',
      asset: '$grade2/ballons.png',
      icon: Icons.celebration_rounded,
      color: TudloColors.gold,
      pictureOnly: true,
    );
    const birthdayParty = _IntroLetterItem(
      label: 'kaadlawan',
      asset: '$grade2/birthday-party.png',
      icon: Icons.celebration_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const family = _IntroLetterItem(
      label: 'pamilya',
      asset: 'assets/images/level_game/people/pamilya.png',
      icon: Icons.family_restroom_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const mango = _IntroLetterItem(
      label: 'mangga',
      asset: '$grade2/mango.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
      pictureOnly: true,
    );
    const book = _IntroLetterItem(
      label: 'libro',
      asset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const pencil = _IntroLetterItem(
      label: 'lapis',
      asset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
      pictureOnly: true,
    );
    const bag = _IntroLetterItem(
      label: 'bag',
      asset: '$grade2/bag.png',
      icon: Icons.backpack_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const chair = _IntroLetterItem(
      label: 'pulungkuan',
      asset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const table = _IntroLetterItem(
      label: 'lamesa',
      asset: '$grade2/table.png',
      icon: Icons.table_restaurant_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const plate = _IntroLetterItem(
      label: 'plato',
      asset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const glass = _IntroLetterItem(
      label: 'baso',
      asset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const spoon = _IntroLetterItem(
      label: 'kutsara',
      asset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
      pictureOnly: true,
    );
    const microphone = _IntroLetterItem(
      label: 'kanta',
      asset: '$grade2/microphone.png',
      icon: Icons.mic_rounded,
      color: TudloColors.coral,
      pictureOnly: true,
    );
    const stage = _IntroLetterItem(
      label: 'entablado',
      asset: '$grade2/school-stage.png',
      icon: Icons.theater_comedy_rounded,
      color: TudloColors.green,
      pictureOnly: true,
    );
    const dog = _IntroLetterItem(
      label: 'ido',
      asset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.pets_rounded,
      color: TudloColors.orange,
      pictureOnly: true,
    );
    const cat = _IntroLetterItem(
      label: 'kuring',
      asset: 'assets/images/level_game/animals/cat.png',
      icon: Icons.pets_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );
    const jeepney = _IntroLetterItem(
      label: 'paalam',
      asset: '$grade2/jeepney.png',
      icon: Icons.directions_bus_rounded,
      color: TudloColors.blue,
      pictureOnly: true,
    );

    return switch ((unitNumber, lessonNumber)) {
      (1, 1) => const [school, juan, ana],
      (1, 2) => const [birthdayParty, cake, balloons],
      (1, 3) => const [family],
      (2, 1) => const [
        _IntroLetterItem(
          label: 'aga',
          asset: 'assets/images/level_game/sunrise.png',
          icon: Icons.wb_sunny_rounded,
          color: TudloColors.gold,
          pictureOnly: true,
        ),
        _IntroLetterItem(
          label: 'hapon',
          icon: Icons.light_mode_rounded,
          color: TudloColors.orange,
          pictureOnly: true,
        ),
        _IntroLetterItem(
          label: 'gab-i',
          asset: 'assets/images/level_game/moon.png',
          icon: Icons.dark_mode_rounded,
          color: TudloColors.blue,
          pictureOnly: true,
        ),
      ],
      (2, 2) => const [
        _IntroLetterItem(
          label: 'malipayon',
          icon: Icons.mood_rounded,
          color: TudloColors.green,
          pictureOnly: true,
        ),
        _IntroLetterItem(
          label: 'masubo',
          icon: Icons.sentiment_dissatisfied_rounded,
          color: TudloColors.coral,
          pictureOnly: true,
        ),
        jeepney,
      ],
      (2, 3) => const [mango],
      (3, 1) => const [book, pencil, bag, chair],
      (3, 2) => const [table, plate, glass, spoon],
      (3, 3) => const [
        _IntroLetterItem(
          label: 'kahoy',
          asset: 'assets/images/level_game/forest.png',
          icon: Icons.park_rounded,
          color: TudloColors.forest,
          pictureOnly: true,
        ),
        _IntroLetterItem(
          label: 'saging',
          asset: 'assets/images/level_game/banana.png',
          icon: Icons.eco_rounded,
          color: TudloColors.gold,
          pictureOnly: true,
        ),
        _IntroLetterItem(
          label: 'suba',
          asset: 'assets/images/level_game/river.png',
          icon: Icons.water_rounded,
          color: TudloColors.blue,
          pictureOnly: true,
        ),
      ],
      (4, 1) => const [microphone],
      (4, 2) => const [dog, cat],
      (4, 3) => const [stage, microphone],
      (5, 1) => const [cat, dog],
      (5, 2) => const [
        _IntroLetterItem(
          label: 'lumpat',
          icon: Icons.keyboard_arrow_up_rounded,
          color: TudloColors.green,
          pictureOnly: true,
        ),
        _IntroLetterItem(
          label: 'paypay',
          icon: Icons.waving_hand_rounded,
          color: TudloColors.gold,
          pictureOnly: true,
        ),
      ],
      _ => const [dog, cat, microphone],
    };
  }

  List<String> _plainIntroLabelsFor(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll('"', '')
        .split(RegExp(r'[,/-]'))
        .map((part) => part.trim())
        .where(
          (part) => part.isNotEmpty && !part.toUpperCase().contains('UNIT'),
        )
        .take(4)
        .toList();
    return cleaned.isEmpty ? const ['Leksiyon'] : cleaned;
  }
}

class _TuonTaHeading extends StatelessWidget {
  final double width;
  final double height;

  const _TuonTaHeading({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          TudloDialogueAssets.tuonTa,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _IntroLetterItem {
  final String label;
  final String? asset;
  final IconData? icon;
  final Color color;
  final bool large;
  final bool pictureOnly;

  const _IntroLetterItem({
    required this.label,
    this.asset,
    this.icon,
    this.color = TudloColors.green,
    this.large = false,
    this.pictureOnly = false,
  });
}

class _IntroLetterGrid extends StatelessWidget {
  final List<Widget> children;

  const _IntroLetterGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final gridWidth = math
            .max(
              0.0,
              math.min(380.0, math.min(screenWidth - 44, constraints.maxWidth)),
            )
            .toDouble();
        final columnGap = screenWidth < 380 ? 12.0 : 18.0;
        final rowGap = screenWidth < 380 ? 8.0 : 14.0;

        if (children.length == 1) {
          final itemSize = math.min(
            330.0,
            math.min(gridWidth, constraints.maxHeight),
          );
          return SizedBox(
            width: gridWidth,
            height: constraints.maxHeight,
            child: Center(
              child: _ScaledIntroChild(size: itemSize, child: children.single),
            ),
          );
        }

        final rows = <List<Widget>>[];
        for (var index = 0; index < children.length; index += 2) {
          rows.add(
            children.sublist(index, math.min(index + 2, children.length)),
          );
        }

        final maxItemWidth = (gridWidth - columnGap) / 2;
        final maxItemHeight =
            math.max(0.0, constraints.maxHeight - (rows.length - 1) * rowGap) /
            rows.length;
        final itemSize = math
            .min(184.0, math.min(maxItemWidth, maxItemHeight))
            .clamp(0.0, 184.0)
            .toDouble();

        return SizedBox(
          width: gridWidth,
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      var childIndex = 0;
                      childIndex < rows[rowIndex].length;
                      childIndex++
                    ) ...[
                      _ScaledIntroChild(
                        size: itemSize,
                        child: rows[rowIndex][childIndex],
                      ),
                      if (childIndex != rows[rowIndex].length - 1)
                        SizedBox(width: columnGap),
                    ],
                  ],
                ),
                if (rowIndex != rows.length - 1) SizedBox(height: rowGap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ScaledIntroChild extends StatelessWidget {
  final double size;
  final Widget child;

  const _ScaledIntroChild({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

class _AnimatedIntroLetterCard extends StatelessWidget {
  final _IntroLetterItem item;
  final int index;
  final bool visible;

  const _AnimatedIntroLetterCard({
    required this.item,
    required this.index,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final colors = const [
      Color(0xFFFFF16A),
      Color(0xFFA6F4E0),
      Color(0xFFFFC857),
      Color(0xFFBDEFFF),
      Color(0xFFFFD6E8),
    ];
    final color = colors[index % colors.length];
    final cardSize = item.large
        ? 330.0
        : item.pictureOnly
        ? 184.0
        : 172.0;
    final imageSize = item.large
        ? 330.0
        : item.pictureOnly
        ? 184.0
        : 166.0;

    return SizedBox(
      width: cardSize,
      height: cardSize,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${item.label}-$visible'),
          tween: Tween<double>(begin: .42, end: visible ? 1 : .42),
          duration: const Duration(milliseconds: 420),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Center(
            child: item.pictureOnly
                ? _IntroPictureArt(item: item, size: imageSize)
                : item.asset == null
                ? Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: TudloColors.forest.withValues(alpha: .14),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.ink,
                          fontSize: item.label.length == 1 ? 56 : 24,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Image.asset(
                    item.asset!,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Text(
                      item.label,
                      style: GoogleFonts.nunito(
                        color: TudloColors.ink,
                        fontSize: 42,
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

class _IntroPictureArt extends StatelessWidget {
  final _IntroLetterItem item;
  final double size;

  const _IntroPictureArt({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    if (item.asset != null) {
      return Image.asset(
        item.asset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _IntroIconArt(item: item, size: size),
      );
    }
    return _IntroIconArt(item: item, size: size);
  }
}

class _IntroIconArt extends StatelessWidget {
  final _IntroLetterItem item;
  final double size;

  const _IntroIconArt({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.color.withValues(alpha: .14),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        item.icon ?? Icons.pets_rounded,
        color: item.color,
        size: size * .58,
      ),
    );
  }
}

class _IntroStartButton extends StatelessWidget {
  final double height;
  final VoidCallback? onPressed;

  const _IntroStartButton({required this.height, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: TudloColors.green,
          foregroundColor: Colors.white,
          elevation: 7,
          shadowColor: TudloColors.forest.withValues(alpha: .32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: const Text('Sugudi'),
      ),
    );
  }
}
