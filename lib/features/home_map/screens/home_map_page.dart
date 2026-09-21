import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/lesson_game/screens/lesson_intro_page.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

const double _mapHeaderHeight = 340;

/// Interactive Home Map screen.
///
/// This page draws the road, unit message cards, level buttons, and map
/// decorations. It also opens lessons and unit vocabulary previews.
class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

String _homeText(
  BuildContext context, {
  required String hil,
  required String en,
}) {
  return AppStateScope.of(context).isHiligaynon ? hil : en;
}

String _joinLessonPreview(List<String> items) {
  final cleaned = items
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return '';
  if (cleaned.length == 1) return cleaned.first;
  if (cleaned.length == 2) return '${cleaned.first} kag ${cleaned.last}';
  return '${cleaned.take(cleaned.length - 1).join(', ')}, kag ${cleaned.last}';
}

String _lessonPreviewForLevel(int level) {
  final unit = AppData.unitForLevel(level);
  final lesson = AppData.lessonNumberForLevel(level);

  final preview = switch ((AppData.selectedGradeLevel, unit.number, lesson)) {
    (GradeLevel.grade1, 1, 1) => _joinLessonPreview(['A', 'N', 'T', 'Y']),
    (GradeLevel.grade1, 1, 2) => _joinLessonPreview(['I', 'D', 'O']),
    (GradeLevel.grade1, 1, 3) => _joinLessonPreview(['M', 'K', 'U']),
    (GradeLevel.grade1, 1, 4) => _joinLessonPreview(['B', 'L', 'S']),
    (GradeLevel.grade1, 1, 5) => _joinLessonPreview(['E', 'G', 'P']),
    (GradeLevel.grade1, 1, 6) => _joinLessonPreview(['R', 'H', 'W', 'C']),
    (GradeLevel.grade1, 1, 7) => _joinLessonPreview([
      'Isa',
      'Duwa',
      'Tatlo',
      'Apat',
      'Lima',
    ]),
    (GradeLevel.grade1, 1, 8) => _joinLessonPreview([
      'Anum',
      'Pito',
      'Walo',
      'Siyam',
      'Napulo',
    ]),
    (GradeLevel.grade1, 1, _) => 'Numero',
    (GradeLevel.grade1, 2, 1) => 'Pamilya',
    (GradeLevel.grade1, 2, 2) => _joinLessonPreview(['Lola', 'Lolo', 'Nanay']),
    (GradeLevel.grade1, 2, _) => _joinLessonPreview([
      'Magulang',
      'Manghod',
      'Lola',
      'Tatay',
    ]),
    (GradeLevel.grade1, 3, 1) => _joinLessonPreview([
      'Manunudlo',
      'Doktor',
      'Nars',
    ]),
    (GradeLevel.grade1, 3, 2) => _joinLessonPreview([
      'Pulis',
      'Bumbero',
      'Tindera',
    ]),
    (GradeLevel.grade1, 3, _) => _joinLessonPreview([
      'Mangunguma',
      'Mangingisda',
    ]),
    (GradeLevel.grade1, 4, 1) => _joinLessonPreview(['Ido', 'Kuring', 'Manok']),
    (GradeLevel.grade1, 4, 2) => _joinLessonPreview([
      'Baboy',
      'Baka',
      'Karbaw',
    ]),
    (GradeLevel.grade1, 4, _) => _joinLessonPreview([
      'Isda',
      'Pispis',
      'Kanding',
    ]),
    (GradeLevel.grade1, 5, 1) => _joinLessonPreview([
      'Balay',
      'Eskwelahan',
      'Simbahan',
    ]),
    (GradeLevel.grade1, 5, 2) => _joinLessonPreview([
      'Tinda',
      'Plasa',
      'Ospital',
    ]),
    (GradeLevel.grade1, 5, _) => _joinLessonPreview(['Uma', 'Baybay']),
    (GradeLevel.grade2, 1, 1) => _joinLessonPreview(['School', 'Juan', 'Ana']),
    (GradeLevel.grade2, 1, 2) => _joinLessonPreview(['Keyk', 'Lobo']),
    (GradeLevel.grade2, 1, _) => 'Pamilya',
    (GradeLevel.grade2, 2, 1) => _joinLessonPreview(['Aga', 'Hapon', 'Gab-i']),
    (GradeLevel.grade2, 2, 2) => _joinLessonPreview([
      'Malipayon',
      'Masubo',
      'Paalam',
    ]),
    (GradeLevel.grade2, 2, _) => 'Mangga',
    (GradeLevel.grade2, 3, 1) => _joinLessonPreview([
      'Libro',
      'Lapis',
      'Bag',
      'Pulungkuan',
    ]),
    (GradeLevel.grade2, 3, 2) => _joinLessonPreview([
      'Lamesa',
      'Plato',
      'Baso',
      'Kutsara',
    ]),
    (GradeLevel.grade2, 3, _) => _joinLessonPreview([
      'Kahoy',
      'Bulak',
      'Adlaw',
    ]),
    (GradeLevel.grade2, 4, 1) => 'Kanta',
    (GradeLevel.grade2, 4, 2) => _joinLessonPreview(['Ido', 'Kuring']),
    (GradeLevel.grade2, 4, _) => _joinLessonPreview(['Entablado', 'Kanta']),
    (GradeLevel.grade2, 5, 1) => _joinLessonPreview(['Kuring', 'Ido']),
    (GradeLevel.grade2, 5, _) => _joinLessonPreview(['Lumpat', 'Paypay']),
    _ => '',
  };

  return preview.isEmpty ? LessonBank.lessonTitleForLevel(level) : preview;
}

class _HomeMapPageState extends State<HomeMapPage> {
  /// Vertical spacing used by both the road painter and the level nodes.
  ///
  /// Keeping these constants shared prevents the buttons from drifting away
  /// from the path when the map height changes.
  static const double _levelGap = 148;
  static const double _unitMessageGap = 230;
  static const double _topPad = 250;
  static const double _bottomPad = 330;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopButton = false;
  int _mapHelpStep = 0;
  int? _activeLevel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 360;
    if (shouldShow == _showScrollTopButton) return;
    setState(() => _showScrollTopButton = shouldShow);
  }

  void _dismissMapHelp() {
    // The first tap advances the helper message. After that, the overlay lets
    // only the highlighted lesson button start the lesson.
    setState(() {
      if (_mapHelpStep == 0) _mapHelpStep = 1;
    });
  }

  void _openMapHelpTarget(int level, Offset nodeCenter) {
    setState(() => AppData.mapHelpDone = true);
    unawaited(AppStateScope.of(context).markMapHelpSeen());
    _openLevel(level, nodeCenter);
  }

  void _scrollToTop() {
    // Floating up-arrow button uses this to return the map to the top.
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  void _openLevel(int level, Offset nodeCenter) {
    if (!AppData.mapHelpDone) {
      setState(() => AppData.mapHelpDone = true);
      unawaited(AppStateScope.of(context).markMapHelpSeen());
    }
    setState(() => _activeLevel = level);
  }

  void _closeLevelPopup() {
    if (_activeLevel == null) return;
    setState(() => _activeLevel = null);
  }

  Future<void> _startLevel(int level) async {
    // Start button in the level popup:
    // Refresh real-time energy before gating access. If the learner has less
    // than the fixed lesson cost, the unit does not start.
    await AppData.refreshEnergy(save: true);
    if (!mounted) return;
    final spent = await AppData.spendLessonEnergy();
    if (!mounted) return;
    if (!spent) {
      _closeLevelPopup();
      await showLowEnergyDialog(context);
      return;
    }
    await AppStateScope.of(context).saveActiveProfileProgress();
    if (!mounted) return;
    // Enough energy: close the popup, then open the animated lesson intro
    // before the game screen.
    _closeLevelPopup();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonIntroPage(level: level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showMapHelp = !AppData.developerMode && !AppData.mapHelpDone;
    final currentLevel = AppData.firstUnlockedIncompleteLevel;
    // The scrollable map needs a fixed content height so decorations, road,
    // stars, and level nodes can all be positioned in the same coordinate space.
    final mapHeight =
        _topPad +
        (AppData.maxLevel - 1) * _levelGap +
        (AppData.units.length - 1) * _unitMessageGap +
        40 +
        _bottomPad;
    final username = AppStateScope.of(context).displayUsername;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final helpRoad = _RoadGeometry(
      width: screenWidth,
      topPad: _topPad,
      levelGap: _levelGap,
      unitMessageGap: _unitMessageGap,
    );
    final helpTarget = helpRoad.pointForLevel(currentLevel);
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final helpTargetInViewport = Offset(
      helpTarget.dx,
      _mapHeaderHeight + helpTarget.dy - scrollOffset,
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: TudloColors.meadow,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                children: [
                  _MapHeader(
                    currentLevel: currentLevel,
                    username: username,
                    dailyWord: showMapHelp ? null : _dailyWord(),
                  ),
                  SizedBox(
                    height: mapHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final road = _RoadGeometry(
                          width: constraints.maxWidth,
                          topPad: _topPad,
                          levelGap: _levelGap,
                          unitMessageGap: _unitMessageGap,
                        );

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ScrollableMapPainter(road: road),
                              ),
                            ),
                            _MapDecorationLayer(
                              width: constraints.maxWidth,
                              height: mapHeight,
                              road: road,
                            ),
                            for (final unit in AppData.units)
                              _UnitMessageCard(
                                unit: unit,
                                point: road.pointForUnitStart(unit.startLevel),
                              ),
                            for (
                              var level = 1;
                              level <= AppData.maxLevel;
                              level++
                            )
                              if (!(showMapHelp &&
                                  _mapHelpStep == 1 &&
                                  level == currentLevel))
                                // Each button uses the same road coordinates as
                                // the painter, which keeps nodes centered on the
                                // trail instead of manually guessing positions.
                                _LevelPositionedButton(
                                  level: level,
                                  point: road.pointForLevel(level),
                                  unitColor: _MapUnitStyle.colorForLevel(level),
                                  unlocked: AppData.isLevelUnlocked(level),
                                  current: level == currentLevel,
                                  completed: AppData.completedLevels.contains(
                                    level,
                                  ),
                                  // Level button opens the level-start popup.
                                  // Locked buttons pass null and cannot be
                                  // tapped.
                                  onTap: AppData.isLevelUnlocked(level)
                                      ? (nodeCenter) =>
                                            _openLevel(level, nodeCenter)
                                      : null,
                                ),
                            if (_activeLevel != null)
                              _LevelStartOverlay(
                                level: _activeLevel!,
                                title: _lessonPreviewForLevel(_activeLevel!),
                                nodeCenter: road.pointForLevel(_activeLevel!),
                                onStart: () => _startLevel(_activeLevel!),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 212,
            child: AnimatedScale(
              scale: _showScrollTopButton ? 1 : .72,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _showScrollTopButton ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showScrollTopButton,
                  child: _ScrollTopButton(onTap: _scrollToTop),
                ),
              ),
            ),
          ),
          if (!showMapHelp)
            const Positioned(left: 4, bottom: 104, child: _HomeKokaGuide()),
          if (showMapHelp)
            Positioned.fill(
              child: _MapDialogueOverlay(
                step: _mapHelpStep,
                username: username,
                levelButtonTarget: helpTargetInViewport,
                targetLevel: currentLevel,
                onTap: _dismissMapHelp,
                onTargetTap: (nodeCenter) =>
                    _openMapHelpTarget(currentLevel, nodeCenter),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  final int currentLevel;
  final String username;
  final LessonTerm? dailyWord;

  const _MapHeader({
    required this.currentLevel,
    required this.username,
    required this.dailyWord,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _HomeTimePalette.current();
    // Header uses a real image asset instead of painted shapes so it can be
    // easily swapped by replacing the game_map header asset.
    return Container(
      height: _mapHeaderHeight,
      width: double.infinity,
      decoration: BoxDecoration(color: TudloColors.meadow),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_map/mapheader.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 18, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: EnergyIndicator(light: true),
                  ),
                  if (dailyWord != null) ...[
                    const SizedBox(height: 22),
                    _HomeDailyWordCard(word: dailyWord!, palette: palette),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  Text(
                    _homeText(
                      context,
                      hil: 'Kumusta, $username!',
                      en: 'Hello, $username!',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _homeText(
                      context,
                      hil: 'Magtuon kita subong',
                      en: "Let's learn something today",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeKokaGuide extends StatefulWidget {
  const _HomeKokaGuide();

  @override
  State<_HomeKokaGuide> createState() => _HomeKokaGuideState();
}

class _HomeKokaGuideState extends State<_HomeKokaGuide> {
  int _tapCount = 0;
  KokaMood _mood = KokaMood.idle;

  KokaMood _moodForTapCount(int taps) {
    if (taps >= 5) return KokaMood.annoyed;
    if (taps >= 3) return KokaMood.curious;
    return KokaMood.hi;
  }

  void _handleTap() {
    setState(() {
      _tapCount += 1;
      _mood = _moodForTapCount(_tapCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mascotSize = (width * .48).clamp(196.0, 236.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: TudloMascot(size: mascotSize, mood: _mood),
    );
  }
}

class _HomeTimePalette {
  final Color card;
  final Color accent;
  final Color button;
  final Color buttonIcon;
  final Color shadow;
  final bool dark;

  const _HomeTimePalette({
    required this.card,
    required this.accent,
    required this.button,
    required this.buttonIcon,
    required this.shadow,
    required this.dark,
  });

  static _HomeTimePalette current([DateTime? dateTime]) {
    final hour = (dateTime ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 7) return dawn;
    if (hour >= 7 && hour < 11) return morning;
    if (hour >= 11 && hour < 14) return noon;
    if (hour >= 14 && hour < 17) return afternoon;
    if (hour >= 17 && hour < 20) return evening;
    return night;
  }

  static const dawn = _HomeTimePalette(
    card: Color(0xFFE96F50),
    accent: Color(0xFFFFE7B0),
    button: Color(0xFFFFE8DE),
    buttonIcon: Color(0xFFE8503A),
    shadow: Color(0x663C1D24),
    dark: false,
  );

  static const morning = _HomeTimePalette(
    card: Color(0xFFF5B85A),
    accent: Color(0xFFFFF2B2),
    button: Color(0xFFFFF6D9),
    buttonIcon: Color(0xFFD9781B),
    shadow: Color(0x553C2E12),
    dark: false,
  );

  static const noon = _HomeTimePalette(
    card: Color(0xFFF8C91A),
    accent: Color(0xFFFFFFFF),
    button: Color(0xFFFFF9C2),
    buttonIcon: Color(0xFFB68700),
    shadow: Color(0x55382700),
    dark: false,
  );

  static const afternoon = _HomeTimePalette(
    card: Color(0xFFE86600),
    accent: Color(0xFFFFF0A8),
    button: Color(0xFFFFE2C3),
    buttonIcon: Color(0xFFE05A00),
    shadow: Color(0x66351200),
    dark: false,
  );

  static const evening = _HomeTimePalette(
    card: Color(0xFF5734A4),
    accent: Color(0xFFBDEFFF),
    button: Color(0xFFE9DCFF),
    buttonIcon: Color(0xFF5734A4),
    shadow: Color(0x77190F33),
    dark: true,
  );

  static const night = _HomeTimePalette(
    card: Color(0xFF102F4C),
    accent: Color(0xFFD8F35B),
    button: Color(0xFFE5F3FF),
    buttonIcon: Color(0xFF102F4C),
    shadow: Color(0x88101E30),
    dark: true,
  );
}

class _MapDialogueOverlay extends StatefulWidget {
  final int step;
  final String username;
  final Offset levelButtonTarget;
  final int targetLevel;
  final VoidCallback onTap;
  final ValueChanged<Offset> onTargetTap;

  const _MapDialogueOverlay({
    required this.step,
    required this.username,
    required this.levelButtonTarget,
    required this.targetLevel,
    required this.onTap,
    required this.onTargetTap,
  });

  @override
  State<_MapDialogueOverlay> createState() => _MapDialogueOverlayState();
}

class _MapDialogueOverlayState extends State<_MapDialogueOverlay> {
  static const _lessonAssetBase = 'assets/images/level_game/lesson-game-assets';
  Timer? _speechTimer;

  @override
  void initState() {
    super.initState();
    _scheduleCurrentMessageSpeech();
  }

  @override
  void didUpdateWidget(covariant _MapDialogueOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _scheduleCurrentMessageSpeech();
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _scheduleCurrentMessageSpeech() {
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) unawaited(_speakCurrentMessage());
    });
  }

  Future<void> _speakCurrentMessage() async {
    await TudloVoiceButton.stop();
    if (!mounted) return;
    unawaited(
      TudloVoiceButton.speak(
        context,
        _message.replaceAll('\n', ' '),
        hiligaynon: AppStateScope.of(context).isHiligaynon,
      ),
    );
  }

  String get _tapHint =>
      _homeText(context, hil: 'ipindot para magpadayon', en: 'tap to continue');

  String get _message => widget.step == 0
      ? _homeText(
          context,
          hil: 'Maayong pag-abot,\nabyan!',
          en: 'Welcome,\nfriend!',
        )
      : _homeText(
          context,
          hil: 'Tum-oka ini para\nmakaumpisa kita!',
          en: 'Press so\nwe can start',
        );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mascotWidth = (size.width * .48).clamp(168.0, 236.0);
    final bubbleWidth = (size.width * .58).clamp(198.0, 280.0);
    final mascotBottom = (size.height * .16).clamp(92.0, 150.0);
    final mascotLeft = (size.width * .02).clamp(4.0, 16.0);
    final mascotTop = size.height - mascotBottom - mascotWidth;
    final mascotVisibleTop = mascotTop + mascotWidth * .158;
    final bubbleVisibleBottom = bubbleWidth * 1.234;
    final bubbleTop = (mascotVisibleTop - bubbleVisibleBottom - 10).clamp(
      MediaQuery.paddingOf(context).top + 96,
      size.height * .48,
    );
    final bubbleLeft = (mascotLeft + mascotWidth * .5 - bubbleWidth * .5).clamp(
      12.0,
      size.width - bubbleWidth - 12,
    );
    const targetSize = 104.0;
    final message = _message;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _MapTutorialDimPainter(
              spotlightCenter: widget.step == 1
                  ? widget.levelButtonTarget
                  : null,
              spotlightRadius: targetSize * .86,
            ),
          ),
        ),
        Positioned.fill(
          child: widget.step == 1
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: const SizedBox.expand(),
                )
              : const SizedBox.expand(),
        ),
        Positioned(
          left: mascotLeft,
          bottom: mascotBottom,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_speakCurrentMessage()),
            child: TudloMascot(
              size: mascotWidth,
              mood: widget.step == 0 ? KokaMood.hi : KokaMood.curious,
            ),
          ),
        ),
        Positioned(
          left: bubbleLeft,
          top: bubbleTop,
          child: IgnorePointer(
            child: _DialogueBubbleImage(
              width: bubbleWidth,
              message: message,
              hint: widget.step == 0 ? _tapHint : null,
            ),
          ),
        ),
        if (widget.step == 1)
          Positioned(
            left: widget.levelButtonTarget.dx - targetSize / 2,
            top: widget.levelButtonTarget.dy - targetSize / 2,
            child: _TutorialTargetLevelButton(
              level: widget.targetLevel,
              size: targetSize,
              onTap: () => widget.onTargetTap(widget.levelButtonTarget),
            ),
          ),
        if (widget.step == 1)
          Positioned(
            left: widget.levelButtonTarget.dx + targetSize * .16,
            top: widget.levelButtonTarget.dy - targetSize * .62,
            child: IgnorePointer(
              child: _AnimatedPointFinger(
                asset: '$_lessonAssetBase/point-finger.png',
                size: (size.width * .18).clamp(62.0, 88.0),
              ),
            ),
          )
        else
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
            ),
          ),
      ],
    );
  }
}

class _AnimatedPointFinger extends StatefulWidget {
  final String asset;
  final double size;

  const _AnimatedPointFinger({required this.asset, required this.size});

  @override
  State<_AnimatedPointFinger> createState() => _AnimatedPointFingerState();
}

class _AnimatedPointFingerState extends State<_AnimatedPointFinger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1, end: .86).animate(curve);
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
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
      builder: (context, child) {
        return Transform.translate(
          offset: _offset.value,
          child: Transform.scale(
            scale: _scale.value,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: Transform.rotate(
        angle: -.55,
        child: Image.asset(
          widget.asset,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _MapTutorialDimPainter extends CustomPainter {
  final Offset? spotlightCenter;
  final double spotlightRadius;

  const _MapTutorialDimPainter({
    required this.spotlightCenter,
    required this.spotlightRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);

    final center = spotlightCenter;
    if (center != null) {
      overlayPath.addOval(
        Rect.fromCircle(center: center, radius: spotlightRadius),
      );
    }

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(covariant _MapTutorialDimPainter oldDelegate) {
    return oldDelegate.spotlightCenter != spotlightCenter ||
        oldDelegate.spotlightRadius != spotlightRadius;
  }
}

class _TutorialTargetLevelButton extends StatefulWidget {
  final int level;
  final double size;
  final VoidCallback onTap;

  const _TutorialTargetLevelButton({
    required this.level,
    required this.size,
    required this.onTap,
  });

  @override
  State<_TutorialTargetLevelButton> createState() =>
      _TutorialTargetLevelButtonState();
}

class _TutorialTargetLevelButtonState extends State<_TutorialTargetLevelButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final glow = _pulse.value;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  OverflowBox(
                    maxWidth: widget.size + 96,
                    maxHeight: widget.size + 96,
                    child: Container(
                      width: widget.size + 72 + glow * 20,
                      height: widget.size + 72 + glow * 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: .58),
                            TudloColors.softGreen.withValues(alpha: .34),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: _CircularLevelNode(
              size: widget.size,
              nodeColor: TudloColors.brightGreen,
              borderColor: TudloColors.forest,
              lockedIconColor: const Color(0xFF9A7B50),
              unlocked: true,
              current: true,
              unitColor: TudloColors.green,
              glow: 0,
              label: '${_localLevelNumber(widget.level)}',
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogueBubbleImage extends StatelessWidget {
  final double width;
  final String message;
  final String? hint;

  const _DialogueBubbleImage({
    required this.width,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            TudloDialogueAssets.dialogueBox,
            width: width,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              width * .14,
              width * .13,
              width * .14,
              width * .20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: (width * .09).clamp(15.0, 20.0),
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (hint != null) ...[
                  SizedBox(height: width * .035),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: TudloColors.muted,
                      fontSize: (width * .052).clamp(11.0, 14.0),
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelStartOverlay extends StatefulWidget {
  final int level;
  final String title;
  final Offset nodeCenter;
  final FutureOr<void> Function() onStart;

  const _LevelStartOverlay({
    required this.level,
    required this.title,
    required this.nodeCenter,
    required this.onStart,
  });

  @override
  State<_LevelStartOverlay> createState() => _LevelStartOverlayState();
}

class _LevelStartOverlayState extends State<_LevelStartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<Offset> _slideAnimation;

  static const _cardGreen = TudloColors.green;
  static const _cardDark = TudloColors.forest;
  static const _nodeSize = 98.0;
  static const _cardHeight = 134.0;

  @override
  void initState() {
    super.initState();
    // The dialog animates from the tapped level node so the user understands
    // which level they are about to start.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    _cardScaleAnimation = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = math.min(screen.width * .68, 320.0);
    const cardTopGap = 18.0;
    final cardLeft = (widget.nodeCenter.dx - cardWidth / 2)
        .clamp(16.0, screen.width - cardWidth - 16)
        .toDouble();
    final cardTop = widget.nodeCenter.dy + _nodeSize / 2 + cardTopGap;
    final pointerLeft = (widget.nodeCenter.dx - cardLeft - 17)
        .clamp(18.0, cardWidth - 52)
        .toDouble();

    return Positioned(
      left: cardLeft,
      top: cardTop,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _cardScaleAnimation,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: pointerLeft,
                    top: -16,
                    child: CustomPaint(
                      size: const Size(34, 18),
                      painter: _LevelCardPointerPainter(color: _cardGreen),
                    ),
                  ),
                  _LevelStartCard(
                    width: cardWidth,
                    level: widget.level,
                    title: widget.title,
                    onStart: widget.onStart,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollTopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollTopButton({required this.onTap});

  // Floating button that returns the map to the greeting/header area.
  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(15));

    return Material(
      color: TudloColors.green,
      borderRadius: borderRadius,
      elevation: 8,
      shadowColor: TudloColors.forest.withValues(alpha: .18),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: .36),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }
}

class _LevelStartCard extends StatelessWidget {
  final double width;
  final int level;
  final String title;
  final FutureOr<void> Function() onStart;

  const _LevelStartCard({
    required this.width,
    required this.level,
    required this.title,
    required this.onStart,
  });

  static const _cardGreen = _LevelStartOverlayState._cardGreen;
  static const _cardDark = _LevelStartOverlayState._cardDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _LevelStartOverlayState._cardHeight,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: _cardGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: _cardDark, blurRadius: 0, offset: Offset(0, 7)),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(left: 42, top: 40, child: _SparkleDot(size: 8)),
          const Positioned(right: 34, top: 32, child: _SparkleDot(size: 7)),
          const Positioned(right: 4, bottom: 0, child: _SparkleDot(size: 10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Leksiyon ${_localLevelNumber(level)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _StartLevelButton(onStart: onStart),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartLevelButton extends StatefulWidget {
  final FutureOr<void> Function() onStart;

  const _StartLevelButton({required this.onStart});

  @override
  State<_StartLevelButton> createState() => _StartLevelButtonState();
}

class _StartLevelButtonState extends State<_StartLevelButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: SizedBox(
        height: 46,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: ElevatedButton(
            onPressed: () async {
              await AppAudioService.instance.playTap();
              widget.onStart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _LevelStartOverlayState._cardDark,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: .80),
                  width: 3,
                ),
              ),
              textStyle: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: const Text('Sugudi'),
          ),
        ),
      ),
    );
  }
}

class _LevelCardPointerPainter extends CustomPainter {
  final Color color;

  const _LevelCardPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LevelCardPointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SparkleDot extends StatelessWidget {
  final double size;

  const _SparkleDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MapAsset extends StatelessWidget {
  final String asset;
  final double left;
  final double top;
  final double width;
  final double? height;
  final double rotation;
  final bool flip;

  const _MapAsset({
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
    this.height,
    this.rotation = 0,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    // Unit cards mark the beginning of each unit. The book button
    // opens a preview of the vocabulary used in that unit.
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scaleX: flip ? -1 : 1,
            child: Image.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapDecorationLayer extends StatelessWidget {
  final double width;
  final double height;
  final _RoadGeometry road;

  const _MapDecorationLayer({
    required this.width,
    required this.height,
    required this.road,
  });

  static const _assets = [
    'assets/images/game_map/tree1.png',
    'assets/images/game_map/tree2.png',
    'assets/images/game_map/tree1 (2).png',
    'assets/images/game_map/grass.png',
    'assets/images/game_map/rock.png',
  ];

  @override
  Widget build(BuildContext context) {
    // Decorations are generated along the map height and placed on alternating
    // sides of the road. Large trees may crop offscreen so they do not block
    // level buttons.
    final decorations = <Widget>[];
    var index = 0;

    for (var y = 72.0; y < height - 120; y += 185) {
      decorations.add(_decoration(index, y, leftSide: index.isEven));
      if (index % 2 == 0) {
        decorations.add(
          _decoration(index + 7, y + 92, leftSide: false, compact: true),
        );
      } else {
        decorations.add(
          _decoration(index + 9, y + 96, leftSide: true, compact: true),
        );
      }
      index++;
    }

    return Positioned.fill(
      child: Stack(clipBehavior: Clip.none, children: decorations),
    );
  }

  Widget _decoration(
    int index,
    double y, {
    required bool leftSide,
    bool compact = false,
  }) {
    final asset = compact
        ? _assets[(index + 2) % _assets.length]
        : _assets[index % _assets.length];
    final isTree = asset.contains('tree');
    final baseWidth = switch (asset) {
      'assets/images/game_map/tree1.png' => compact ? 154.0 : 211.0,
      'assets/images/game_map/tree2.png' => compact ? 154.0 : 211.0,
      'assets/images/game_map/tree1 (2).png' => compact ? 154.0 : 211.0,
      'assets/images/game_map/grass.png' => compact ? 74.0 : 116.0,
      'assets/images/game_map/rock.png' => compact ? 62.0 : 92.0,
      _ => compact ? 32.0 : 44.0,
    };
    final assetHeight = isTree ? (compact ? 170.0 : 230.0) : null;
    final variation = math.sin(index * 1.73) * 20;
    final roadLevel = ((y - road.topPad) / road.levelGap) + 1;
    final roadX = road.xForLevel(roadLevel);
    final x = _xForSide(
      leftSide: leftSide,
      assetWidth: baseWidth,
      asset: asset,
      roadX: roadX,
      variation: variation,
    );
    final rotation = _rotationForAsset(asset, index);

    return _MapAsset(
      asset: asset,
      left: x,
      top: y,
      width: baseWidth,
      height: assetHeight,
      rotation: rotation,
      flip: !leftSide && (asset.contains('tree') || asset.contains('grass')),
    );
  }

  double _rotationForAsset(String asset, int index) {
    if (asset.contains('tree')) return 0;

    final wave = math.sin(index * .91);
    final maxDegrees = asset.contains('rock')
        ? 3.0
        : asset.contains('grass')
        ? 2.0
        : 5.0;
    return wave * maxDegrees * math.pi / 180;
  }

  double _xForSide({
    required bool leftSide,
    required double assetWidth,
    required String asset,
    required double roadX,
    required double variation,
  }) {
    // Keep decorations clear of the road. Trees are allowed to extend beyond
    // the screen edge because they are decorative, not tappable.
    final isTree = asset.contains('tree');
    final roadClearance = isTree
        ? 150.0
        : asset.contains('grass')
        ? 110.0
        : 98.0;
    if (leftSide) {
      final target = 14.0 + variation.abs();
      final maxSafe = roadX - roadClearance - assetWidth;
      if (isTree) {
        return math.min(target, maxSafe);
      }
      return target.clamp(0.0, math.max(0.0, maxSafe)).toDouble();
    }

    final target = width - assetWidth - 14.0 - variation.abs();
    final maxSafe = math.max(0.0, width - assetWidth);
    final minSafe = math.min(maxSafe, roadX + roadClearance);
    if (isTree) {
      return math.max(target, roadX + roadClearance);
    }
    return target.clamp(minSafe, maxSafe).toDouble();
  }
}

class _CenterMascotShowcase extends StatefulWidget {
  const _CenterMascotShowcase();

  @override
  State<_CenterMascotShowcase> createState() => _CenterMascotShowcaseState();
}

class _CenterMascotShowcaseState extends State<_CenterMascotShowcase>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _idleController;
  late final AnimationController _tapController;
  late final Animation<double> _entrance;
  late final Animation<double> _idle;
  late final Animation<double> _tapBounce;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _idle = CurvedAnimation(parent: _idleController, curve: Curves.easeInOut);
    _tapBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.12), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.12, end: 1), weight: 55),
    ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _react() {
    _tapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceController,
      child: ScaleTransition(
        scale: Tween<double>(begin: .7, end: 1).animate(_entrance),
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _tapBounce]),
          builder: (context, child) {
            final lift = -5 * _idle.value;
            final breathing = 1 + (_idle.value * .026);
            return Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(
                scale: breathing * _tapBounce.value,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: _react,
            child: SizedBox(
              width: 238,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (context, child) {
                      return Container(
                        width: 178 + (_idle.value * 14),
                        height: 178 + (_idle.value * 14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: .62),
                              Colors.white.withValues(alpha: .22),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: .42),
                              blurRadius: 42,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const _CenterSparkle(left: 24, top: 48, size: 18, delay: .1),
                  const _CenterSparkle(left: 58, top: 28, size: 8, delay: .5),
                  const _CenterSparkle(left: 190, top: 50, size: 15, delay: .8),
                  const _CenterSparkle(left: 34, top: 150, size: 10, delay: .3),
                  const _CenterSparkle(
                    left: 184,
                    top: 156,
                    size: 11,
                    delay: .6,
                  ),
                  const _CenterSparkle(left: 150, top: 24, size: 7, delay: .2),
                  const TudloMascot(size: 150),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterSparkle extends StatefulWidget {
  final double left;
  final double top;
  final double size;
  final double delay;

  const _CenterSparkle({
    required this.left,
    required this.top,
    required this.size,
    required this.delay,
  });

  @override
  State<_CenterSparkle> createState() => _CenterSparkleState();
}

class _CenterSparkleState extends State<_CenterSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + (widget.delay * 800).round()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = (_controller.value + widget.delay) % 1;
          final opacity = .28 + (math.sin(phase * math.pi) * .52);
          final drift = math.sin(phase * math.pi * 2) * 2;
          return Transform.translate(
            offset: Offset(0, drift),
            child: Transform.rotate(
              angle: phase * math.pi * .18,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: widget.size,
                color: Colors.white.withValues(alpha: opacity.clamp(.18, .80)),
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: .70),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapUnitStyle {
  static const _unitColors = [
    TudloColors.brightGreen,
    Color(0xFF3D91E8),
    Color(0xFF8B5CF6),
    Color(0xFFE85D9E),
    Color(0xFFE05A47),
    Color(0xFFF59E0B),
  ];

  static Color colorForLevel(int level) {
    final unitIndex = AppData.units.indexWhere(
      (unit) => level >= unit.startLevel && level <= unit.endLevel,
    );
    return _unitColors[unitIndex];
  }
}

class _UnitMessageCard extends StatelessWidget {
  final AppUnit unit;
  final Offset point;

  const _UnitMessageCard({required this.unit, required this.point});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 72,
      right: 72,
      top: point.dy,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: TudloColors.forest, width: 2),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Yunit ${unit.number}',
                      style: const TextStyle(
                        color: TudloColors.muted,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _HomeDailyWordCard extends StatelessWidget {
  final LessonTerm word;
  final _HomeTimePalette palette;

  const _HomeDailyWordCard({required this.word, required this.palette});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            borderRadius: radius,
            onTap: () => _showDailyWordPopup(context, word, palette),
            child: Container(
              constraints: const BoxConstraints(minHeight: 92),
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _homeText(
                            context,
                            hil: 'Tinaga subong nga adlaw',
                            en: 'Word of the Day',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                color: TudloColors.ink,
                                offset: Offset(1.4, 1.8),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          word.hil,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: palette.accent,
                            fontSize: 34,
                            height: .95,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                color: TudloColors.ink,
                                offset: Offset(1, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: _homeText(
                      context,
                      hil: 'Buksi ang Tinaga subong nga adlaw',
                      en: 'Open Word of the Day',
                    ),
                    onPressed: () =>
                        _showDailyWordPopup(context, word, palette),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.button,
                      foregroundColor: palette.buttonIcon,
                      minimumSize: const Size(58, 58),
                    ),
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 50,
                      weight: 900,
                    ),
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

Future<void> _showDailyWordPopup(
  BuildContext context,
  LessonTerm word, [
  _HomeTimePalette? palette,
]) {
  final appState = AppStateScope.of(context);
  final exampleHil =
      word.exampleSentenceHiligaynon ??
      word.missingSentence?.replaceAll('___', word.missingAnswer ?? '') ??
      'Nagakaon ako sang mansanas.';
  final exampleEng = word.exampleSentenceEnglish ?? 'I am eating an apple.';
  final pronunciation = word.pronunciation ?? _pronunciationFor(word.hil);
  var kokaTapCount = 0;
  var kokaMood = KokaMood.idle;

  KokaMood moodForTapCount(int taps) {
    if (taps >= 5) return KokaMood.annoyed;
    if (taps >= 3) return KokaMood.curious;
    return KokaMood.hi;
  }

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .38),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final saved = appState.isFavoriteWord(word.hil);
            const bedroomGreen = Color(0xFFC9EFC7);
            const wordInk = Color(0xFF101522);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 430,
                maxHeight: MediaQuery.sizeOf(context).height * .86,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Material(
                  color: bedroomGreen,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            AspectRatio(
                              aspectRatio: 1.42,
                              child: Image.asset(
                                'assets/images/word-of-the-day/bedroom-koka.jpg',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return const ColoredBox(
                                    color: bedroomGreen,
                                    child: Center(
                                      child: TudloMascot(
                                        size: 172,
                                        mood: KokaMood.idle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              left: 10,
                              top: 10,
                              child: IconButton(
                                tooltip: saved
                                    ? _homeText(
                                        context,
                                        hil: 'Kuhaa sa paborito',
                                        en: 'Remove favorite',
                                      )
                                    : _homeText(
                                        context,
                                        hil: 'Tipigi sa paborito',
                                        en: 'Save favorite',
                                      ),
                                onPressed: () async {
                                  await appState.toggleFavoriteWord(word.hil);
                                  setDialogState(() {});
                                },
                                icon: Icon(
                                  saved
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 34,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: IconButton(
                                tooltip: _homeText(
                                  context,
                                  hil: 'Sirad-i',
                                  en: 'Close',
                                ),
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 36,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setDialogState(() {
                                    kokaTapCount += 1;
                                    kokaMood = moodForTapCount(kokaTapCount);
                                  });
                                },
                                child: TudloMascot(size: 150, mood: kokaMood),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          decoration: BoxDecoration(
                            color: bedroomGreen,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .10),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _homeText(
                                  context,
                                  hil: 'Tinaga subong nga adlaw',
                                  en: 'Word of the day',
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: wordInk,
                                  fontSize: 28,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                word.hil.toLowerCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: Colors.black,
                                  fontSize: 54,
                                  height: .95,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                pronunciation,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: wordInk,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _meaningSentenceFor(context, word),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: wordInk,
                                  fontSize: 18,
                                  height: 1.18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _homeText(
                                  context,
                                  hil: 'Halimbawa:',
                                  en: 'Example:',
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: wordInk.withValues(alpha: .58),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                exampleHil,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: wordInk,
                                  fontSize: 18,
                                  height: 1.18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (!appState.isHiligaynon)
                                Text(
                                  exampleEng,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    color: wordInk.withValues(alpha: .78),
                                    fontSize: 17,
                                    height: 1.18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

LessonTerm _dailyWord() {
  final terms = _dailyWordTerms;
  final day = AppData.dailyWordNow().difference(DateTime(2026, 1, 1)).inDays;
  return terms[day.abs() % terms.length];
}

const _dailyWordTerms = [
  LessonTerm(
    unitNumber: 5,
    unitTitle: 'Daily Life',
    gradeLevel: 3,
    type: LessonContentType.word,
    hil: 'Kaon',
    eng: 'Eat',
    pronunciation: 'Ka-on',
    exampleSentenceHiligaynon: 'Nagakaon ako sang mansanas.',
    exampleSentenceEnglish: 'I am eating an apple.',
  ),
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Everyday Conversation',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'Balay',
    eng: 'House',
    pronunciation: 'Ba-lay',
    exampleSentenceHiligaynon: 'Ang balay daku.',
    exampleSentenceEnglish: 'The house is big.',
  ),
  LessonTerm(
    unitNumber: 5,
    unitTitle: 'Daily Life',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'Tubig',
    eng: 'Water',
    pronunciation: 'Tu-big',
    exampleSentenceHiligaynon: 'Nag-inom ako sang tubig.',
    exampleSentenceEnglish: 'I drank water.',
  ),
  LessonTerm(
    unitNumber: 5,
    unitTitle: 'Daily Life',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'Libro',
    eng: 'Book',
    pronunciation: 'Lib-ro',
    exampleSentenceHiligaynon: 'May libro ako.',
    exampleSentenceEnglish: 'I have a book.',
  ),
  LessonTerm(
    unitNumber: 5,
    unitTitle: 'Daily Life',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'Ido',
    eng: 'Dog',
    pronunciation: 'I-do',
    exampleSentenceHiligaynon: 'Ang ido nagadalagan.',
    exampleSentenceEnglish: 'The dog is running.',
  ),
];

String _pronunciationFor(String word) {
  if (word.length <= 3) return word;
  final midpoint = (word.length / 2).round();
  return '${word.substring(0, midpoint)}-${word.substring(midpoint)}';
}

String _meaningSentenceFor(BuildContext context, LessonTerm word) {
  if (word.hil == 'Kaon') {
    return _homeText(
      context,
      hil:
          'Ang kaon nagakahulugan sang pagbutang sang pagkaon sa baba, pag-usap, kag pagtulon sini.',
      en: 'Kaon means to eat.',
    );
  }
  return _homeText(
    context,
    hil: 'Ang ${word.hil} isa ka tinaga sa Hiligaynon.',
    en: '${word.hil} means "${word.eng}".',
  );
}

class _LevelPositionedButton extends StatefulWidget {
  final int level;
  final Offset point;
  final Color unitColor;
  final bool unlocked;
  final bool current;
  final bool completed;
  final ValueChanged<Offset>? onTap;

  const _LevelPositionedButton({
    required this.level,
    required this.point,
    required this.unitColor,
    required this.unlocked,
    required this.current,
    required this.completed,
    required this.onTap,
  });

  @override
  State<_LevelPositionedButton> createState() => _LevelPositionedButtonState();
}

class _LevelPositionedButtonState extends State<_LevelPositionedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Global level IDs are used for progress, but the visible number resets to
    // 1-5 inside every unit through _localLevelNumber().
    final size = widget.current ? 104.0 : 92.0;
    final nodeColor = widget.unlocked
        ? widget.unitColor
        : const Color(0xFFD6BA8C);
    final borderColor = widget.unlocked
        ? TudloColors.forest
        : const Color(0xFF7B5F37);
    final lockedIconColor = const Color(0xFF9A7B50);

    return Positioned(
      left: widget.point.dx - size / 2,
      top: widget.point.dy - size / 2,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
        child: Builder(
          builder: (buttonContext) {
            return InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: widget.onTap == null
                  ? null
                  : () {
                      final box = buttonContext.findRenderObject() as RenderBox;
                      final center = box.localToGlobal(
                        box.size.center(Offset.zero),
                      );
                      widget.onTap!(center);
                    },
              onTapDown: widget.onTap == null
                  ? null
                  : (_) => setState(() => _pressed = true),
              onTapCancel: widget.onTap == null
                  ? null
                  : () => setState(() => _pressed = false),
              onTapUp: widget.onTap == null
                  ? null
                  : (_) => setState(() => _pressed = false),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final glow = widget.current ? _pulse.value : 0.0;
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    scale: _pressed ? .94 : 1,
                    child: widget.completed
                        ? _CompletedLevelStar(
                            size: size,
                            glow: glow,
                            current: widget.current,
                          )
                        : _CircularLevelNode(
                            size: size,
                            nodeColor: nodeColor,
                            borderColor: borderColor,
                            lockedIconColor: lockedIconColor,
                            unlocked: widget.unlocked,
                            current: widget.current,
                            unitColor: widget.unitColor,
                            glow: glow,
                            label: '${_localLevelNumber(widget.level)}',
                          ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

int _localLevelNumber(int globalLevel) {
  return AppData.lessonNumberForLevel(globalLevel);
}

class _CircularLevelNode extends StatelessWidget {
  final double size;
  final Color nodeColor;
  final Color borderColor;
  final Color lockedIconColor;
  final bool unlocked;
  final bool current;
  final Color unitColor;
  final double glow;
  final String label;

  const _CircularLevelNode({
    required this.size,
    required this.nodeColor,
    required this.borderColor,
    required this.lockedIconColor,
    required this.unlocked,
    required this.current,
    required this.unitColor,
    required this.glow,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (unlocked)
          Container(
            width: size + 24 + glow * 8,
            height: size + 24 + glow * 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .36),
              shape: BoxShape.circle,
              boxShadow: [
                if (current)
                  BoxShadow(
                    color: unitColor.withValues(alpha: .22 + glow * .12),
                    blurRadius: 24 + glow * 18,
                    spreadRadius: 4 + glow * 6,
                  ),
              ],
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: nodeColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 5),
            boxShadow: [
              if (current)
                BoxShadow(
                  color: Colors.white.withValues(alpha: .70),
                  blurRadius: 22,
                  spreadRadius: 7,
                ),
              BoxShadow(
                color: TudloColors.forest.withValues(
                  alpha: unlocked ? .24 : .18,
                ),
                blurRadius: unlocked ? 16 : 10,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (unlocked)
                Positioned(
                  right: 13,
                  top: 10,
                  child: Container(
                    width: 24,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              Center(
                child: unlocked
                    ? Text(
                        label,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: current ? 36 : 31,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Icon(
                        Icons.lock_rounded,
                        color: lockedIconColor,
                        size: current ? 42 : 37,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletedLevelStar extends StatelessWidget {
  final double size;
  final double glow;
  final bool current;

  const _CompletedLevelStar({
    required this.size,
    required this.glow,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    const starColor = Color(0xFFFFD84D);
    final starSize = size * 1.24;
    return SizedBox.square(
      dimension: starSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.black.withValues(alpha: .24),
            size: starSize + 9,
          ),
          Icon(
            Icons.star_rounded,
            color: starColor,
            size: starSize,
            shadows: [
              Shadow(
                color: starColor.withValues(alpha: current ? .90 : .62),
                blurRadius: current ? 34 + glow * 8 : 20,
              ),
              if (current)
                Shadow(
                  color: Colors.white.withValues(alpha: .78),
                  blurRadius: 18 + glow * 8,
                ),
              Shadow(color: starColor.withValues(alpha: .50), blurRadius: 14),
              Shadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoadGeometry {
  final double width;
  final double topPad;
  final double levelGap;
  final double unitMessageGap;

  const _RoadGeometry({
    required this.width,
    required this.topPad,
    required this.levelGap,
    required this.unitMessageGap,
  });

  Offset pointForLevel(int level) {
    // This is the single source of truth for level node positions. The painter
    // and buttons both use it so they stay aligned.
    final y =
        topPad +
        (level - 1) * levelGap +
        AppData.units.where((unit) => unit.startLevel <= level).length *
            unitMessageGap -
        unitMessageGap;
    final unit = AppData.unitForLevel(level);
    final localLevel = (level - unit.startLevel + 1).toDouble();
    return Offset(xForUnitLocal(unit, localLevel), y);
  }

  Offset pointForUnitStart(int level) {
    final levelPoint = pointForLevel(level);
    final offset = level == 1 ? 176.0 : 224.0;
    return Offset(levelPoint.dx, levelPoint.dy - offset);
  }

  Offset pointForUnitPathStart(AppUnit unit) {
    final firstPoint = pointForLevel(unit.startLevel);
    return Offset(xForUnitLocal(unit, .38), firstPoint.dy - 82);
  }

  Offset pointForUnitPathEnd(AppUnit unit) {
    final lastPoint = pointForLevel(unit.endLevel);
    return Offset(
      xForUnitLocal(unit, unit.lessonCount + .62),
      lastPoint.dy + 96,
    );
  }

  double xForLevel(double level) {
    final approximateLevel = level.round().clamp(1, AppData.maxLevel);
    final unit = AppData.unitForLevel(approximateLevel);
    final localLevel = level - unit.startLevel + 1;
    return xForUnitLocal(unit, localLevel);
  }

  double xForUnitLocal(AppUnit unit, double localLevel) {
    final center = width / 2;
    final amplitude = math.max(76.0, width * .22);
    final phase = unit.number * .72;
    final broad = math.sin((localLevel - 1) * .90 + .40 + phase) * amplitude;
    final drift =
        math.sin((localLevel - 1) * .32 + 1.4 + phase) * amplitude * .12;
    final x = center + broad + drift;
    return x.clamp(104.0, width - 104.0);
  }

  List<Offset> anchorsForUnit(AppUnit unit) {
    return [
      pointForUnitPathStart(unit),
      for (var level = unit.startLevel; level <= unit.endLevel; level++)
        pointForLevel(level),
      pointForUnitPathEnd(unit),
    ];
  }

  List<List<Offset>> unitAnchors() {
    return [for (final unit in AppData.units) anchorsForUnit(unit)];
  }
}

class _ScrollableMapPainter extends CustomPainter {
  final _RoadGeometry road;

  const _ScrollableMapPainter({required this.road});

  @override
  void paint(Canvas canvas, Size size) {
    // The road is painted in wide layered strokes to create a soft trail
    // effect under the level buttons.
    _paintBackground(canvas, size);

    for (final anchors in road.unitAnchors()) {
      final path = _smoothPath(anchors);

      canvas.drawPath(
        path.shift(const Offset(0, 10)),
        Paint()
          ..color = TudloColors.forest.withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 110
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF9F1D1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 96
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFF8DE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 76
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final previous = i == 0 ? points[i] : points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      final afterNext = i + 2 < points.length ? points[i + 2] : next;

      final control1 = current + (next - previous) / 6;
      final control2 = next - (afterNext - current) / 6;
      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );
    }
    return path;
  }

  void _paintBackground(Canvas canvas, Size size) {
    final meadow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC9EA91), Color(0xFFAFD06E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, meadow);

    final hillPaint = Paint()..color = const Color(0xFFD6F2A4);
    for (var y = -28.0; y < size.height; y += 640) {
      final hill = Path()
        ..moveTo(0, y + 120)
        ..quadraticBezierTo(size.width * .30, y + 18, size.width * .58, y + 120)
        ..quadraticBezierTo(size.width * .78, y + 195, size.width, y + 90)
        ..lineTo(size.width, y + 260)
        ..lineTo(0, y + 260)
        ..close();
      canvas.drawPath(hill, hillPaint);
    }

    final flowerPaint = Paint()..color = Colors.white;
    final flowerCenter = Paint()..color = const Color(0xFFFFDE5B);
    for (final seed in [70.0, 185.0, 355.0, 540.0, 720.0, 980.0, 1190.0]) {
      final x = (math.sin(seed) * .5 + .5) * (size.width - 70) + 35;
      final y = seed % size.height;
      for (var i = 0; i < 5; i++) {
        final angle = math.pi * 2 * i / 5;
        canvas.drawCircle(
          Offset(x + math.cos(angle) * 7, y + math.sin(angle) * 7),
          5,
          flowerPaint,
        );
      }
      canvas.drawCircle(Offset(x, y), 4, flowerCenter);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrollableMapPainter oldDelegate) {
    return oldDelegate.road.width != road.width;
  }
}
