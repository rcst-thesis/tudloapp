import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/lesson/presentation/widgets/lesson_content_footer.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

const double _mapHeaderHeight = 340;
const Size _barangayMapViewBox = Size(2400, 1400);
const String _barangayMapAsset =
    'assets/images/level_game/backgrounds/tudlomap.svg';

enum MapLocation {
  house,
  school,
  classroom,
  market,
  farm,
  park,
  hospital,
  church,
  beach,
}

class MapAnchor {
  final Offset normalizedPosition;
  final double focusScale;
  final String label;
  final Size hitArea;

  const MapAnchor({
    required this.normalizedPosition,
    required this.focusScale,
    required this.label,
    this.hitArea = const Size(150, 150),
  });
}

const mapAnchors = <MapLocation, MapAnchor>{
  MapLocation.house: MapAnchor(
    normalizedPosition: Offset(.30, .44),
    focusScale: 2.35,
    label: 'Balay',
  ),
  MapLocation.school: MapAnchor(
    normalizedPosition: Offset(.54, .88),
    focusScale: 2.15,
    label: 'Eskwelahan',
    hitArea: Size(220, 170),
  ),
  MapLocation.classroom: MapAnchor(
    normalizedPosition: Offset(.54, .88),
    focusScale: 2.15,
    label: 'Eskwelahan',
    hitArea: Size(220, 170),
  ),
  MapLocation.market: MapAnchor(
    normalizedPosition: Offset(.83, .33),
    focusScale: 2.25,
    label: 'Tinda',
  ),
  MapLocation.farm: MapAnchor(
    normalizedPosition: Offset(.90, .72),
    focusScale: 2.05,
    label: 'Uma',
    hitArea: Size(240, 180),
  ),
  MapLocation.park: MapAnchor(
    normalizedPosition: Offset(.63, .43),
    focusScale: 2.45,
    label: 'Plasa',
    hitArea: Size(240, 210),
  ),
  MapLocation.hospital: MapAnchor(
    normalizedPosition: Offset(.56, .70),
    focusScale: 2.25,
    label: 'Ospital',
    hitArea: Size(230, 160),
  ),
  MapLocation.church: MapAnchor(
    normalizedPosition: Offset(.16, .17),
    focusScale: 2.25,
    label: 'Simbahan',
  ),
  MapLocation.beach: MapAnchor(
    normalizedPosition: Offset(.14, .84),
    focusScale: 2.05,
    label: 'Baybay',
    hitArea: Size(260, 180),
  ),
};

/// Interactive Home Map screen.
///
/// This page draws the road, unit message cards, level buttons, and map
/// decorations. It also opens lessons and unit vocabulary previews.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({this.initialSourceLevel, super.key});

  final int? initialSourceLevel;

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
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
    (GradeLevel.grade1, 1, 1) => _joinLessonPreview(['A', 'N', 'T']),
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

class _LessonsScreenState extends State<LessonsScreen> {
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
  int _selectedUnitNumber = 1;
  bool _launchingLevel = false;

  @override
  void initState() {
    super.initState();
    final initialLevel = _initialDashboardLevel();
    final initialUnit = AppData.unitForLevel(initialLevel);
    _selectedUnitNumber = initialUnit.number;
    _scrollController.addListener(_handleScroll);
    final requestedLevel = widget.initialSourceLevel;
    if (requestedLevel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_presentLessonStartPopup(requestedLevel));
      });
    }
  }

  int _initialDashboardLevel() {
    final focused =
        widget.initialSourceLevel ?? AppData.lessonDashboardFocusLevel;
    if (focused != null &&
        focused >= 1 &&
        focused <= AppData.maxLevel &&
        AppData.isCatalogLevel(focused) &&
        AppData.isLevelUnlocked(focused)) {
      return focused;
    }
    return AppData.firstCatalogLevel;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    unawaited(AppAudioService.instance.stopVoice());
    super.dispose();
  }

  void _stopLessonCardVoice() {
    unawaited(AppAudioService.instance.stopVoice());
  }

  String? _lessonCardVoiceAssetForLevel(int level) {
    if (!AppData.isProductionLessonAvailable(level)) return null;
    final unit = AppData.unitForLevel(level);
    final lesson = AppData.lessonNumberForLevel(level);
    return switch ((AppData.selectedGradeLevel, unit.number, lesson)) {
      (GradeLevel.grade1, 1, 1) => 'audio/VO-final/grade1/Gr_1_Les_1_1_1.wav',
      (GradeLevel.grade1, 1, 7) => 'audio/VO-final/grade1/Gr_1_Les_1_7_1.wav',
      (GradeLevel.grade1, 2, 1) => 'audio/VO-final/grade1/Gr_1_Les_2_1_1.wav',
      (GradeLevel.grade1, 2, 4) => 'audio/VO-final/grade1/Gr_1_Les_2_4_1.wav',
      (GradeLevel.grade2, 1, 1) => 'audio/VO-final/grade2/Gr_2_Les_1_1_1.wav',
      (GradeLevel.grade2, 1, 2) => 'audio/VO-final/grade2/Gr_2_Les_1_2_1.wav',
      (GradeLevel.grade2, 2, 1) => 'audio/VO-final/grade2/Gr_2_Les_2_1_1.wav',
      (GradeLevel.grade2, 2, 2) => 'audio/VO-final/grade2/Gr_2_Les_2_2_1.wav',
      (GradeLevel.grade3, 1, 1) => 'audio/VO-final/grade3/Gr_3_Les_1_1_1.wav',
      (GradeLevel.grade3, 1, 3) => 'audio/VO-final/grade3/Gr_3_Les_1_3_1.wav',
      (GradeLevel.grade3, 2, 1) => 'audio/VO-final/grade3/Gr_3_Les_2_1_1.wav',
      (GradeLevel.grade3, 2, 2) => 'audio/VO-final/grade3/Gr_3_Les_2_2_1.wav',
      _ => null,
    };
  }

  /// Plays a single lesson's VO on demand -- only used inside the "start
  /// lesson" popup below, not while just browsing the grid. With several
  /// lesson cards visible on screen at once, there's no single "selected"
  /// card left to narrate automatically; narrating whichever one the
  /// learner actually chose to start makes more sense than guessing.
  Future<void> _playLessonVoiceForLevel(int level) async {
    final asset = _lessonCardVoiceAssetForLevel(level);
    if (asset == null) return;
    try {
      await AppAudioService.instance.lowerBackgroundVolume();
      await AppAudioService.instance.playVoiceAssets([asset]);
    } catch (_) {
      // Missing or unsupported card VO should not block starting the lesson.
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
    }
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
    if (!AppData.isProductionLessonAvailable(level)) return;
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
    if (!AppData.isProductionLessonAvailable(level)) return;
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
    if (_launchingLevel) return;
    if (!AppData.isProductionLessonAvailable(level)) return;
    AppData.lessonDashboardFocusLevel = level;
    _stopLessonCardVoice();
    _launchingLevel = true;
    // Tudlo's 10–100 energy is an availability display, not a lesson cost.
    // The host keeps DevG's original card interaction but owns the route.
    _closeLevelPopup();
    DevGLessonHostScope.of(context).startSourceLevel(level);
    if (mounted) {
      setState(() => _launchingLevel = false);
    } else {
      _launchingLevel = false;
    }
  }

  // Applies a unit picked from the "yunits" dropdown in
  // _GradeOneUnitSelector (which owns showing/positioning that dropdown
  // itself -- this is just the resulting state mutation, replacing what
  // the old showModalBottomSheet-based picker used to do inline).
  void _applySelectedUnit(int selected) {
    if (selected == _selectedUnitNumber) return;
    final unit = AppData.unitForNumber(selected);
    final levels = AppData.catalogLevelsForUnit(unit);
    if (levels.isEmpty) return;
    _stopLessonCardVoice();
    AppData.lessonDashboardFocusLevel = levels.first;
    setState(() => _selectedUnitNumber = selected);
  }

  // Tapping a card's Play button no longer jumps straight into the lesson.
  // It pops up a dimmed confirmation card for that one lesson and narrates
  // it there instead -- narrating on the grid itself doesn't make sense
  // once several lesson cards can be on screen together.
  Future<void> _presentLessonStartPopup(int level) async {
    if (_launchingLevel) return;
    if (!AppData.isProductionLessonAvailable(level)) return;
    final title = _lessonTitleForDashboard(level);
    unawaited(_playLessonVoiceForLevel(level));
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close lesson popup',
      barrierColor: const Color(0xCC000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) => _LessonStartPopup(
        title: title,
        onStart: () {
          Navigator.of(dialogContext).pop();
          unawaited(_startLevel(level));
        },
      ),
    );
    _stopLessonCardVoice();
  }

  Widget _buildGradeOneDashboard(BuildContext context) {
    return _buildGradeOneDashboardOld(context);
  }

  // Used by the reusable lesson-map stage when it is inserted into lessons.
  // ignore: unused_element
  MapLocation _mapLocationForLevel(int level) {
    final unit = AppData.unitForLevel(level);
    final lesson = AppData.lessonNumberForLevel(level);
    return switch ((unit.number, lesson)) {
      (1, _) => MapLocation.classroom,
      (2, _) => MapLocation.house,
      (3, 1) => MapLocation.classroom,
      (3, 2) => MapLocation.market,
      (3, _) => MapLocation.farm,
      (4, 1) => MapLocation.farm,
      (4, 2) => MapLocation.farm,
      (4, _) => MapLocation.beach,
      (5, 1) => MapLocation.house,
      (5, 2) => MapLocation.market,
      (5, _) => MapLocation.farm,
      _ => MapLocation.park,
    };
  }

  Widget _buildGradeOneDashboardOld(BuildContext context) {
    final unit =
        AppData.catalogUnits.any((unit) => unit.number == _selectedUnitNumber)
        ? AppData.unitForNumber(_selectedUnitNumber)
        : AppData.unitForLevel(AppData.firstCatalogLevel);
    final levels = AppData.catalogLevelsForUnit(unit);
    final completedInUnit = [
      for (final level in levels)
        if (AppData.completedLevels.contains(level)) level,
    ].length;
    final badges = AppData.levelStars.values.where((stars) => stars > 0).length;
    final completedLessons = AppData.completedLevelCount;

    return Scaffold(
      backgroundColor: const Color(0xFF90E0EF),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final compact = h < 790;
            final horizontal = constraints.maxWidth.clamp(360.0, 520.0);
            final sidePadding = (constraints.maxWidth - horizontal) / 2 + 22;
            final topPadding = compact ? 8.0 : 14.0;
            final gap = compact ? 8.0 : 12.0;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    topPadding,
                    sidePadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GradeOneHeader(
                          gradeLabel: AppData.selectedGradeLevel.label,
                          isGradeOne:
                              AppData.selectedGradeLevel == GradeLevel.grade1,
                          compact: compact,
                        ),
                        SizedBox(height: gap),
                        _GradeOneUnitSelector(
                          unit: unit,
                          completed: completedInUnit,
                          lessonCount: levels.length,
                          compact: compact,
                          onUnitSelected: _applySelectedUnit,
                        ),
                        SizedBox(height: gap),
                        Row(
                          children: [
                            Expanded(
                              child: _GradeOneStatCard(
                                iconAsset: 'assets/images/stat_unit_symbol.svg',
                                value: '${unit.number}',
                                label: 'yunit',
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GradeOneStatCard(
                                iconAsset:
                                    'assets/images/stat_badge_symbol.svg',
                                value: '$badges',
                                label: 'badges',
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GradeOneStatCard(
                                iconAsset:
                                    'assets/images/stat_lesson_symbol.svg',
                                value:
                                    '$completedLessons/${AppData.catalogLevelCount}',
                                label: 'lessons',
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sidePadding),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              _GradeOneLessonCard._cardAspectRatio,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final level = levels[index];
                      return _GradeOneLessonCard(
                        key: ValueKey(level),
                        level: level,
                        unit: unit,
                        active: true,
                        launching: _launchingLevel,
                        available: AppData.isProductionLessonAvailable(level),
                        onTapCard: () {},
                        onPlay: () => _presentLessonStartPopup(level),
                      );
                    }, childCount: levels.length),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: gap)),
                // Sits at the bottom of the scroll content instead of a
                // fixed bottomNavigationBar so it scrolls with everything
                // else -- same single-wave shape as Home/Dictionary/Me's
                // own content footers, just filled with this screen's
                // #00B4D8. The outer LessonCatalogScreen Scaffold still
                // reserves AppBottomTabNavigation's own height separately.
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32, child: LessonContentFooter()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppData.selectedGradeLevel == GradeLevel.grade1 ||
        AppData.selectedGradeLevel == GradeLevel.grade2 ||
        AppData.selectedGradeLevel == GradeLevel.grade3) {
      return _buildGradeOneDashboard(context);
    }

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
                  _MapHeader(username: username),
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
                                _AvailableLevelPositionedButton(
                                  level: level,
                                  point: road.pointForLevel(level),
                                  unitColor: _MapUnitStyle.colorForLevel(level),
                                  current: level == currentLevel,
                                  completed: AppData.completedLevels.contains(
                                    level,
                                  ),
                                  onTap: (nodeCenter) =>
                                      _openLevel(level, nodeCenter),
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

class _LessonMapScreen extends StatefulWidget {
  final String lessonId;
  final int level;
  final MapLocation targetLocation;
  final VoidCallback onDestinationTap;
  final VoidCallback onBack;

  const _LessonMapScreen({
    required this.lessonId,
    required this.level,
    required this.targetLocation,
    required this.onDestinationTap,
    required this.onBack,
  });

  @override
  State<_LessonMapScreen> createState() => _LessonMapScreenState();
}

class _LessonMapScreenState extends State<_LessonMapScreen>
    with TickerProviderStateMixin {
  static final Map<String, Matrix4> _savedTransforms = {};
  static final Set<String> _focusedLessons = {};

  late final TransformationController _transformationController;
  late final AnimationController _cameraController;
  late final AnimationController _pulseController;
  Animation<Matrix4>? _cameraAnimation;
  Size _viewportSize = Size.zero;
  Size _sceneSize = Size.zero;
  bool _pinVisible = false;
  bool _destinationSelected = false;

  MapAnchor get _anchor => mapAnchors[widget.targetLocation]!;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController(
      _savedTransforms[widget.lessonId] ?? Matrix4.identity(),
    )..addListener(_saveTransform);
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 960),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LessonMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId) {
      _pinVisible = false;
      _destinationSelected = false;
      _transformationController.value =
          _savedTransforms[widget.lessonId] ?? Matrix4.identity();
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusTarget());
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_saveTransform);
    _saveTransform();
    _cameraController.dispose();
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _saveTransform() {
    _savedTransforms[widget.lessonId] = Matrix4.copy(
      _transformationController.value,
    );
  }

  void _maybeFocusTarget() {
    if (_viewportSize == Size.zero || _sceneSize == Size.zero) return;
    if (_focusedLessons.contains(widget.lessonId)) {
      if (!_pinVisible) setState(() => _pinVisible = true);
      return;
    }
    _focusedLessons.add(widget.lessonId);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _focusTarget();
    });
  }

  void _focusTarget({double? scale}) {
    if (_viewportSize == Size.zero || _sceneSize == Size.zero) return;
    final targetScale = scale ?? _anchor.focusScale;
    final target = Offset(
      _anchor.normalizedPosition.dx * _sceneSize.width,
      _anchor.normalizedPosition.dy * _sceneSize.height,
    );
    final usableCenter = Offset(
      _viewportSize.width / 2,
      (_viewportSize.height - 118) / 2,
    );
    final dx = usableCenter.dx - target.dx * targetScale;
    final dy = usableCenter.dy - target.dy * targetScale;
    final targetMatrix = Matrix4.identity();
    targetMatrix.storage[0] = targetScale;
    targetMatrix.storage[5] = targetScale;
    targetMatrix.storage[12] = dx;
    targetMatrix.storage[13] = dy;

    _cameraController
      ..stop()
      ..reset();
    _cameraAnimation =
        Matrix4Tween(
            begin: _transformationController.value,
            end: targetMatrix,
          ).animate(
            CurvedAnimation(
              parent: _cameraController,
              curve: Curves.easeInOutCubic,
            ),
          )
          ..addListener(() {
            _transformationController.value = _cameraAnimation!.value;
          });
    _cameraController.forward().whenComplete(() {
      if (mounted) setState(() => _pinVisible = true);
    });
  }

  void _zoomBy(double delta) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final next = (current + delta).clamp(.8, 4.5);
    _focusTarget(scale: next.toDouble());
  }

  Future<void> _handleDestinationTap() async {
    if (_destinationSelected) return;
    setState(() => _destinationSelected = true);
    await AppAudioService.instance.playCorrect();
    if (!mounted) return;
    widget.onDestinationTap();
  }

  Future<void> _handleWrongTap() async {
    await TudloVoiceButton.stop();
    if (!mounted) return;
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Pangitaa ang ${_anchor.label.toLowerCase()}.',
        hiligaynon: true,
      ),
    );
    _pulseController
      ..reset()
      ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final unit = AppData.unitForLevel(level);
    final lesson = AppData.lessonNumberForLevel(level);
    final progress = AppData.maxLevel == 0 ? 0.0 : level / AppData.maxLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFBDE8A7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          final sceneWidth = math.max(
            _viewportSize.width * 3.1,
            _barangayMapViewBox.width * .62,
          );
          _sceneSize = Size(
            sceneWidth,
            sceneWidth * _barangayMapViewBox.height / _barangayMapViewBox.width,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeFocusTarget();
          });

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleWrongTap,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: .8,
                    maxScale: 4.5,
                    panEnabled: true,
                    scaleEnabled: true,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(180),
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _sceneSize.width,
                      height: _sceneSize.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SvgPicture.asset(
                              _barangayMapAsset,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                          _DestinationMarker(
                            anchor: _anchor,
                            sceneSize: _sceneSize,
                            visible: _pinVisible,
                            selected: _destinationSelected,
                            pulse: _pulseController,
                            onTap: _handleDestinationTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      _MapCircleButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Balik',
                        onTap: widget.onBack,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 14,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              TudloColors.brightGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      TudloVoiceButton(
                        message: 'Pangitaa ang ${_anchor.label.toLowerCase()}.',
                        tooltip: 'Pamatii liwat',
                        hiligaynon: true,
                        size: 60,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: MediaQuery.paddingOf(context).top + 82,
                child: IgnorePointer(
                  child: _MapInstructionCard(
                    text:
                        'Yunit ${unit.number} • Leksyon ${unit.number}.$lesson',
                    instruction: 'Pangitaa ang ${_anchor.label}.',
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 124,
                child: Column(
                  children: [
                    _MapCircleButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Padakuon',
                      onTap: () => _zoomBy(.45),
                    ),
                    const SizedBox(height: 10),
                    _MapCircleButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Pagamayon',
                      onTap: () => _zoomBy(-.45),
                    ),
                    const SizedBox(height: 10),
                    _MapCircleButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Balik sa lugar',
                      onTap: () => _focusTarget(),
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

class _DestinationMarker extends StatelessWidget {
  final MapAnchor anchor;
  final Size sceneSize;
  final bool visible;
  final bool selected;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _DestinationMarker({
    required this.anchor,
    required this.sceneSize,
    required this.visible,
    required this.selected,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final center = Offset(
      anchor.normalizedPosition.dx * sceneSize.width,
      anchor.normalizedPosition.dy * sceneSize.height,
    );
    return Positioned(
      left: center.dx - anchor.hitArea.width / 2,
      top: center.dy - anchor.hitArea.height / 2,
      width: anchor.hitArea.width,
      height: anchor.hitArea.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 280),
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final glow = selected ? 1.28 : 1 + pulse.value * .18;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: glow,
                    child: Container(
                      width: anchor.hitArea.width * .74,
                      height: anchor.hitArea.height * .58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TudloColors.gold.withValues(alpha: .28),
                        boxShadow: [
                          BoxShadow(
                            color: TudloColors.brightGreen.withValues(
                              alpha: selected ? .72 : .42,
                            ),
                            blurRadius: selected ? 48 : 34,
                            spreadRadius: selected ? 13 : 7,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -42),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 78,
                      color: selected
                          ? TudloColors.brightGreen
                          : const Color(0xFFE94343),
                      shadows: [
                        Shadow(
                          color: TudloColors.ink.withValues(alpha: .22),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        anchor.label,
                        style: GoogleFonts.nunito(
                          color: TudloColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MapInstructionCard extends StatelessWidget {
  final String text;
  final String instruction;

  const _MapInstructionCard({required this.text, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TudloColors.ink.withValues(alpha: .14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: TudloColors.blue,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            instruction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .92),
        foregroundColor: TudloColors.blue,
        minimumSize: const Size(58, 58),
        elevation: 6,
        shadowColor: TudloColors.ink.withValues(alpha: .18),
      ),
      icon: Icon(icon, size: 34),
    );
  }
}

class _GradeOneHeader extends StatelessWidget {
  final String gradeLabel;
  final bool isGradeOne;
  final bool compact;

  const _GradeOneHeader({
    required this.gradeLabel,
    required this.isGradeOne,
    required this.compact,
  });

  // The supplied Figma wordmark's own viewBox (208x73) -- used to keep the
  // artwork's aspect ratio while it's sized to the same em-height the
  // replaced text used, so it occupies the same scale/position as before.
  static const _artworkAspectRatio = 208 / 73;

  @override
  Widget build(BuildContext context) {
    final labelHeight = compact ? 58.0 : 68.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: isGradeOne
                ? Transform.translate(
                    // Visual-only nudge (doesn't affect the Row's layout/
                    // height, unlike Padding) -- bump this to move the
                    // artwork lower/higher independent of the battery icon.
                    offset: const Offset(0, 11),
                    child: SizedBox(
                      height: labelHeight,
                      width: labelHeight * _artworkAspectRatio,
                      child: SvgPicture.asset(
                        'assets/images/grade1_dashboard_label.svg',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        semanticsLabel: gradeLabel,
                      ),
                    ),
                  )
                : Text(
                    gradeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: labelHeight,
                      height: .95,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: TudloColors.ink.withValues(alpha: .42),
                          offset: const Offset(2, 5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        const _GradeOneEnergyIndicator(),
      ],
    );
  }
}

/// Dashboard battery-style energy gauge, replacing the DevG-source
/// [EnergyIndicator] pill for this header only. Same real data source
/// (`AppData.currentEnergy`/`maxEnergy`, already Tudlo's 10-100 learner
/// energy -- see `AppData.configure`) and the same live-update/tap-to-open
/// behavior as [EnergyIndicator]; only the presentation changes to match
/// the supplied battery artwork.
///
/// The fill bars and the "n%" label are Flutter-drawn on top of the SVG
/// shell, the same technique `HomeEnergyIndicator` uses -- the source
/// Figma export baked its own 6 permanently-"full" bars and a static "60%"
/// label as vector text, so a real value never showed. The shipped asset
/// (`assets/images/lesson_energy_indicator.svg`) has both stripped out,
/// keeping only the shell/nub/badge-pill/window artwork.
class _GradeOneEnergyIndicator extends StatefulWidget {
  const _GradeOneEnergyIndicator();

  @override
  State<_GradeOneEnergyIndicator> createState() =>
      _GradeOneEnergyIndicatorState();
}

class _GradeOneEnergyIndicatorState extends State<_GradeOneEnergyIndicator> {
  // Scales the whole battery (SVG + Flutter-drawn bars + label) uniformly
  // -- adjust this alone to resize; all the geometry below is fixed to the
  // SVG's own 86x60 coordinate space, so scaling the box directly instead
  // would require recomputing every bar/label position by hand.
  static const _scale = 0.8;

  // 10 bars = 10% per bar, same intuitive mapping HomeEnergyIndicator uses.
  static const _barCount = 10;
  // The battery window's fill bars, in the SVG's own 86x60 coordinate space
  // (matches this widget's fixed SizedBox size 1:1). Derived from the
  // source artwork's own (now-removed) 6-bar spacing, extended to fill the
  // window edge to edge for 10 bars instead of leaving roughly 40% empty.
  static const _barLeftStart = 19.0;
  static const _barLeftStep = 6.0204;
  static const _barTop = 26.0;
  static const _barWidth = 4.81633;
  static const _barHeight = 24.0;
  static const _barRadius = 2.40816;
  static const _filledColor = Color(0xFF00D7FF);
  static const _labelColor = Color(0xFF0C2F4F);

  // The source artwork's badge-pill bounding box (also in the SVG's own
  // coordinate space) -- the "n%" label sits centered inside it.
  static const _labelLeft = 31.0;
  static const _labelTop = 2.06641;
  static const _labelWidth = 37.0;
  static const _labelHeight = 14.9333;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppData.refreshEnergy(save: true);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await AppData.refreshEnergy(save: true);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppData.energyRevision,
      builder: (context, _, __) {
        final displayedEnergy = AppData.developerMode
            ? AppData.maxEnergy
            : AppData.currentEnergy.clamp(0, AppData.maxEnergy);
        final filledBars = (displayedEnergy / AppData.maxEnergy * _barCount)
            .round();
        return Semantics(
          key: const Key('grade-one-energy-indicator'),
          label: 'Energy $displayedEnergy percent',
          child: GestureDetector(
            onTap: () => showEnergyDetails(context),
            behavior: HitTestBehavior.opaque,
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 86,
                height: 60,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(
                        'assets/images/lesson_energy_indicator.svg',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    for (var index = 0; index < filledBars; index++)
                      Positioned(
                        left: _barLeftStart + index * _barLeftStep,
                        top: _barTop,
                        width: _barWidth,
                        height: _barHeight,
                        child: DecoratedBox(
                          key: Key('grade-one-energy-bar-$index'),
                          decoration: BoxDecoration(
                            color: _filledColor,
                            borderRadius: BorderRadius.circular(_barRadius),
                          ),
                        ),
                      ),
                    Positioned(
                      left: _labelLeft,
                      top: _labelTop,
                      width: _labelWidth,
                      height: _labelHeight,
                      child: Center(
                        child: Text(
                          AppData.developerMode ? '∞' : '$displayedEnergy%',
                          key: const Key('grade-one-energy-label'),
                          maxLines: 1,
                          style: const TextStyle(
                            color: _labelColor,
                            fontFamily: 'ComicRelief',
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradeOneUnitSelector extends StatelessWidget {
  final AppUnit unit;
  final int completed;
  final int lessonCount;
  final bool compact;
  final ValueChanged<int> onUnitSelected;

  const _GradeOneUnitSelector({
    required this.unit,
    required this.completed,
    required this.lessonCount,
    required this.compact,
    required this.onUnitSelected,
  });

  // Supplied Figma card ("yunit card.svg"): two flat, unblurred rects --
  // a back one offset straight down, a front one at the origin -- instead
  // of a soft BoxShadow, giving the card a solid/boxy drop-shadow edge.
  // Keep the *ratio* of that offset to the card's height (source: 1.79834
  // / 123.201 tall), not the literal Figma pixel offset, so it scales with
  // this card's actual responsive height instead of a fixed export size.
  static const _shadowOffsetRatio = 1.79834 / 123.201;
  static const _shadowColor = Color(0xFF58858E);
  static const _cardColor = Color(0xFFCAF0F8);

  // Progress tracker label + fill -- deliberately 0xFF57858E, not this
  // card's own 0xFF58858E _shadowColor above (one digit apart, but a
  // separately supplied value, not a typo/duplicate of it).
  static const _progressColor = Color(0xFF57858E);

  @override
  Widget build(BuildContext context) {
    final progress = lessonCount <= 0 ? 0.0 : completed / lessonCount;
    final cardHeight = compact ? 90.0 : 100.0;
    final shadowOffset = cardHeight * _shadowOffsetRatio;
    return SizedBox(
      height: cardHeight + shadowOffset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Splits the card horizontally so the centered "yunit N" label
          // and the unit-title label never overlap: the title's column
          // starts partway across the card instead of spanning the full
          // width like "yunit N" does.
          final titleStart = constraints.maxWidth * 0.54;
          const titleGap = 40.0;
          final titleFontSize = (MediaQuery.sizeOf(context).width * 0.03).clamp(
            12.0,
            16.0,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: shadowOffset,
                height: cardHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _shadowColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: cardHeight,
                // The whole card is no longer itself tappable -- switching
                // units is now the dedicated "yunits" dropdown button's job
                // (below), not the whole card's, so this is a plain
                // decorated container instead of a Material/InkWell.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              Positioned(
                left: 3,
                top: 0,
                height: cardHeight,
                // Supplied "3 dots.svg" decoration, vertically centered at the
                // card's own left edge. Sized as a ratio of cardHeight (source
                // viewBox 16x36, aspect ratio kept) rather than the Figma export's
                // literal pixel size, same reasoning as the card's shadow offset.
                child: Center(
                  child: SizedBox(
                    height: cardHeight * 0.35,
                    width: cardHeight * 0.35 * (16 / 36),
                    child: SvgPicture.asset(
                      'assets/images/unit_card_dots.svg',
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              // Supplied "unit1 thumbnail.png", pinned to the card's own
              // top-left corner (unlike the dots above, which stay vertically
              // centered) -- this is what the old A/B/C tile is replaced by;
              // that Row slot above is now just an empty width-preserving
              // spacer. Sized as a ratio of cardHeight, square, same reasoning
              // as the other card decorations.
              Positioned(
                left: 26,
                top: 4,
                child: SizedBox(
                  // Shrunk from the old 0.85 so there's genuine room left
                  // in the card, below both this and the labels, for the
                  // progress tracker underneath -- growing the card's own
                  // height instead of shrinking this was tried and
                  // reverted.
                  height: cardHeight * 0.70,
                  width: cardHeight * 0.70,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: _unitThumbnailScaleForDashboard(unit.number),
                      heightFactor: _unitThumbnailScaleForDashboard(
                        unit.number,
                      ),
                      child: Image.asset(
                        _unitThumbnailForDashboard(unit.number),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // Progress tracker (label + bar) -- bottom-anchored, full
              // card width, so it always sits below the thumbnail *and*
              // below "yunit N"/the title (both vertically centered
              // higher up), inside the card's existing bounds.
              Positioned(
                left: 18,
                right: 16,
                bottom: compact ? 8 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CardStrokeLabel(
                      text: '$completed of $lessonCount done',
                      fontSize: compact ? 11 : 12,
                      color: _progressColor,
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Container(
                      height: compact ? 9 : 12,
                      decoration: BoxDecoration(
                        // Empty-state track is a plain white pill
                        // floating above the card, not a flat gray inset
                        // like a normal progress bar -- the drop shadow
                        // is what sells "floating".
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      // Small gap between the white container and the fill
                      // -- the fill floats inside the track instead of
                      // touching its edges.
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _progressColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Center(
                  child: _CardStrokeLabel(
                    text: 'padayuna (keep going)',
                    // Edit this label's size independently of "Yunit N" below.
                    fontSize: (MediaQuery.sizeOf(context).width * 0.03).clamp(
                      10.0,
                      13.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: cardHeight,
                child: Center(
                  child: _CardStrokeLabel(
                    text: 'yunit ${unit.number}',
                    // Edit this label's size independently of "padayuna" above.
                    fontSize: (MediaQuery.sizeOf(context).width * 0.03).clamp(
                      28.0,
                      41.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: titleStart,
                right: 16,
                top: 0,
                height: cardHeight,
                // Stays in this same center-right column always -- no
                // FittedBox shrink and never moved elsewhere on the card.
                // If it's too long for one line it wraps in place (up to
                // 2 lines); if it's still too long even then, the second
                // line ellipsizes instead of a 3rd line ever appearing.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    // Gap between "yunit N" and this title -- edit to
                    // widen/narrow the breathing room between them.
                    padding: const EdgeInsets.only(left: titleGap),
                    child: _CardStrokeLabel(
                      text: unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // Edit this label's size independently of the others.
                      fontSize: titleFontSize,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: compact ? 6 : 8,
                right: 10,
                child: _UnitDropdownButton(
                  compact: compact,
                  selectedUnit: unit.number,
                  onUnitSelected: onUnitSelected,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The "yunits [chevron]" pill above the unit title -- replaces the old
/// showModalBottomSheet unit picker with a dropdown anchored to this
/// button. Front/depth colors and the white front-only stroke are the
/// supplied spec; the label reuses [_CardStrokeLabel]'s stroke/shadow
/// style but with this button's own fill color (0xFF58858E, distinct from
/// the other labels' 0xFF57858E).
class _UnitDropdownButton extends StatelessWidget {
  const _UnitDropdownButton({
    required this.compact,
    required this.selectedUnit,
    required this.onUnitSelected,
  });

  final bool compact;
  final int selectedUnit;
  final ValueChanged<int> onUnitSelected;

  static const _frontColor = Color(0xFFCAF0F8);
  static const _depthColor = Color(0xFF57858E);
  static const _labelColor = Color(0xFF58858E);

  Future<void> _openMenu(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          Offset(0, button.size.height + 4),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<int>(
      context: context,
      position: position,
      color: _frontColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // Just the yunit number per unit, not the full title/progress the
      // old bottom sheet showed -- this is a quick switcher, not a browser.
      items: [
        for (final (index, catalogUnit) in AppData.catalogUnits.indexed) ...[
          if (index > 0)
            const PopupMenuItem<Never>(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              // White, and inset just barely from each edge -- not the
              // default PopupMenuDivider's theme-gray full-bleed line.
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white),
                  child: SizedBox(height: 1, width: double.infinity),
                ),
              ),
            ),
          PopupMenuItem<int>(
            value: catalogUnit.number,
            child: _CardStrokeLabel(
              text: 'yunit ${catalogUnit.number}',
              fontSize: 15,
              color: _labelColor,
            ),
          ),
        ],
      ],
    );
    if (selected != null) onUnitSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => SizedBox(
        width: compact ? 83 : 97,
        height: compact ? 23 : 27,
        child: StickerPressButton(
          restLift: 2,
          borderRadius: 999,
          frontColor: _frontColor,
          depthColor: _depthColor,
          frontBorder: Border.all(color: Colors.white, width: 1.6),
          playButtonSound: true,
          onPressed: () => _openMenu(buttonContext),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // Safety net against overflow at the smallest supported
            // viewport widths -- this chrome control isn't one of the
            // no-shrink card labels, so scaling it down slightly here is
            // fine.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardStrokeLabel(
                    text: 'yunits',
                    fontSize: compact ? 12 : 13,
                    color: _labelColor,
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _labelColor,
                    size: 16,
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

/// Reusable card caption *style* -- white stroke behind a filled fill color
/// with a soft drop shadow, since Flutter's TextStyle has no native stroke:
/// two stacked Text widgets sharing the same string, the back one painted
/// stroke-only (Paint.style = PaintingStyle.stroke) as the white outline,
/// the front one normally filled on top. The top "padayuna" label, the
/// center "yunit N" label, and the left-aligned unit-title label all use
/// this, but each caller passes its own [fontSize] -- they are not tied
/// together. Positioning is the caller's job too; it never wraps text or
/// shrinks its own font size -- optional [maxLines]/[overflow] only let a
/// caller opt into single-line ellipsis truncation.
class _CardStrokeLabel extends StatelessWidget {
  const _CardStrokeLabel({
    required this.text,
    required this.fontSize,
    this.maxLines,
    this.overflow,
    this.color = _defaultColor,
    this.textAlign,
  });

  final String text;

  // Each caller computes/passes its own size -- "padayuna" and "Yunit N"
  // look the same but are independently sized, not a shared computed value.
  final double fontSize;

  // Optional: callers that need to cap this at one line (with ellipsis if
  // it still doesn't fit) pass these -- this widget still never wraps or
  // shrinks its font size on its own otherwise.
  final int? maxLines;
  final TextOverflow? overflow;

  // Most labels share this fill color; the "yunits" dropdown button's
  // label uses a slightly different one (0xFF58858E vs this 0xFF57858E)
  // per its own supplied spec, hence this being overridable per instance.
  final Color color;

  // Only needed by callers whose label can wrap to 2+ lines inside a
  // fixed-width box (e.g. a right-aligned title next to a badge) -- a
  // single-line label ignores this since there's nothing to align.
  final TextAlign? textAlign;
  static const _defaultColor = Color(0xFF57858E);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'ComicRelief',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.22
              ..color = Colors.white,
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: style.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: .25),
                offset: const Offset(0, 1),
                blurRadius: 1.5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradeOneStatCard extends StatelessWidget {
  final String iconAsset;
  final String value;
  final String label;
  final bool compact;

  const _GradeOneStatCard({
    required this.iconAsset,
    required this.value,
    required this.label,
    required this.compact,
  });

  // Same boxy solid-shadow technique and colors as the yunit card
  // (_GradeOneUnitSelector): a flat, unblurred back rect offset straight
  // down instead of a soft BoxShadow, and the same front/shadow color
  // pair, kept in ratio to this card's own height rather than the yunit
  // card's literal pixel offset.
  static const _shadowOffsetRatio = 3.79834 / 123.201;
  static const _shadowColor = Color(0xFF58858E);
  static const _cardColor = Color(0xFFCAF0F8);
  // Value/label text color, same as the yunit card's labels.
  static const _labelColor = Color(0xFF58858E);

  @override
  Widget build(BuildContext context) {
    final cardHeight = compact ? 74.0 : 86.0;
    final shadowOffset = cardHeight * _shadowOffsetRatio;
    return SizedBox(
      height: cardHeight + shadowOffset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: shadowOffset,
            height: cardHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _shadowColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: cardHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: compact ? 8 : 10,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: compact ? 18 : 24,
                        height: compact ? 18 : 24,
                        // Supplied symbol SVGs are already colored
                        // 0xFF57858E, matching this card set's palette --
                        // no colorFilter override needed.
                        child: SvgPicture.asset(iconAsset, fit: BoxFit.contain),
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      _CardStrokeLabel(
                        text: value,
                        fontSize: compact ? 28 : 34,
                        color: _labelColor,
                      ),
                      _CardStrokeLabel(
                        text: label,
                        fontSize: compact ? 14 : 17,
                        color: _labelColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeOneLessonCard extends StatelessWidget {
  // Supplied "grade 1 lesson 1 card.svg"'s own card canvas -- 213 wide x
  // 371 tall -- kept as both an aspect ratio (so the card's actual
  // on-screen size still matches the source proportions instead of
  // stretching to whatever width the grid cell happens to give it)
  // and a literal design-space size every child below is positioned in,
  // 1:1 with that SVG's own pixel coordinates.
  static const _designWidth = 233.0;
  static const _designHeight = 391.0;
  static const _cardAspectRatio = _designWidth / _designHeight;

  // The supplied PNG already has its own rounded corners baked in via
  // alpha transparency (measured from the source file: opaque starts at
  // ~112px into an 852px-wide image, i.e. 112 * (213/852) here) -- the
  // outer ClipRRect below must use 0 for this specific card (PNG's own
  // rounding wins) or it double-rounds with a mismatched curve, notching
  // the corners. The dynamically-built fallback card (any lesson besides
  // Grade 1 Unit 1 Lesson 1, which has no hand-drawn art yet) is flat
  // rects with no baked-in rounding, so it uses _dynamicCardRadius for
  // both its own background and the shared ClipRRect instead.
  static const _cardRadius = 10.0;
  static const _dynamicCardRadius = 10.0;
  static const _cardFill = Color(0xFFACE6B0);

  // Only the fallback (non-lesson-1) card uses these -- the supplied PNG
  // has its own colors baked in.
  static const _frameTeal = Color(0xFF76C4AE);
  static const _labelTeal = Color(0xFF4A7B6D);

  // Play button colors, per explicit instruction: front 0x4A7B6D, back/
  // depth 0x004A35. Unit 2 uses its own front/back pair (0x884830 /
  // 0x482518) and play-triangle asset/tint to match that unit's own
  // orange card color instead of Unit 1's green.
  static const _playFront = Color(0xFF4A7B6D);
  static const _playDepth = Color(0xFF004A35);
  static const _unit2PlayFront = Color(0xFF884830);
  static const _unit2PlayDepth = Color(0xFF482518);
  static const _unit2IconTint = Color(0xFFF9A488);
  static const _playDiameter = 64.0;

  final int level;
  final AppUnit unit;
  final bool active;
  final bool launching;
  final bool available;
  final VoidCallback onTapCard;
  final VoidCallback onPlay;

  const _GradeOneLessonCard({
    required this.level,
    required this.unit,
    required this.active,
    required this.launching,
    required this.available,
    required this.onTapCard,
    required this.onPlay,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = AppData.isLevelUnlocked(level);
    final playable = available && unlocked;
    final completed = AppData.completedLevels.contains(level);
    final lessonNumber = AppData.lessonNumberForLevel(level);
    final title = _lessonTitleForDashboard(level);

    // Hand-drawn art exists for a handful of specific lessons -- every
    // other lesson falls back to a dynamically-built card (same color
    // language, generated content) since there's no equivalent art for
    // them yet.
    final cardArt = _lessonCardArtForDashboard(unit.number, lessonNumber);
    final cardRadius = cardArt != null ? _cardRadius : _dynamicCardRadius;

    final isUnit2 = unit.number == 2;
    final playFront = isUnit2 ? _unit2PlayFront : _playFront;
    final playDepth = isUnit2 ? _unit2PlayDepth : _playDepth;
    final playIconTint = isUnit2 ? _unit2IconTint : _cardFill;
    final playIconAsset = isUnit2
        ? 'assets/images/lesson_play_icon_unit2.svg'
        : 'assets/images/lesson_play_icon.svg';

    // Icon shown on the play button per state -- the supplied play.svg
    // triangle only makes sense when the lesson is actually playable;
    // completed/locked/unavailable states keep using plain Material icons
    // like the previous button did, just recolored to match the new
    // button's light-on-dark look.
    final Widget buttonIcon = completed
        ? Icon(Icons.check_rounded, size: 30, color: playIconTint)
        : !available
        ? Icon(Icons.block_rounded, size: 30, color: playIconTint)
        : !unlocked
        ? Icon(Icons.lock_rounded, size: 30, color: playIconTint)
        : SvgPicture.asset(playIconAsset, width: 26, height: 26);

    return Center(
      child: AspectRatio(
        aspectRatio: _cardAspectRatio,
        child: GestureDetector(
          onTap: active ? null : onTapCard,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardRadius),
              // A single FittedBox scales this whole design-space Stack
              // (art, button, and the locked/unavailable scrim together)
              // as one unit -- keeping the scrim sized to this Stack
              // instead of to the outer post-margin box means it can never
              // read taller than the card it's covering.
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _designWidth,
                  height: _designHeight,
                  child: Stack(
                    children: [
                      ColorFiltered(
                        colorFilter: playable
                            ? const ColorFilter.matrix(<double>[
                                1,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ])
                            : const ColorFilter.matrix(<double>[
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                .62,
                                0,
                              ]),
                        // The card itself -- background, badge, "yunit N",
                        // unit title, thumbnail, caption, title bar -- is
                        // the raw supplied PNG rendered as-is, not rebuilt
                        // out of Flutter widgets.
                        child: cardArt != null
                            // An invisible native Container sized to the
                            // card's design dimensions -- it, not the PNG,
                            // is what the FittedBox above scales for each
                            // viewport, and the PNG just fits inside it. A
                            // raw Image at a fixed pixel size wouldn't
                            // rescale cleanly across viewports on its own.
                            ? Container(
                                width: _designWidth,
                                height: _designHeight,
                                color: Colors.transparent,
                                child: Image.asset(
                                  cardArt,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : _DynamicLessonCardArt(
                                unit: unit,
                                lessonNumber: lessonNumber,
                                title: title,
                                cardRadius: _dynamicCardRadius,
                                cardFill: _cardFill,
                                frameTeal: _frameTeal,
                                labelTeal: _labelTeal,
                                designWidth: _designWidth,
                                designHeight: _designHeight,
                              ),
                      ),
                      // The play button (not present in the art) is
                      // overlaid on top, since the card still needs to be
                      // interactive.
                      Positioned(
                        left: (_designWidth - _playDiameter) / 2,
                        // Biased toward the bottom of the footer zone
                        // (below the title bar at y=257) instead of
                        // centered in it.
                        top: 257 + (_designHeight - 257 - _playDiameter) * 0.7,
                        width: _playDiameter,
                        height: _playDiameter,
                        child: Semantics(
                          button: true,
                          enabled: active && playable && !launching,
                          label: available
                              ? playable
                                    ? 'Open $title'
                                    : '$title locked'
                              : '$title unavailable',
                          child: StickerPressButton(
                            onPressed: onPlay,
                            enabled: active && playable && !launching,
                            frontColor: playFront,
                            depthColor: playDepth,
                            height: _playDiameter,
                            borderRadius: _playDiameter / 2,
                            playButtonSound: false,
                            child: buttonIcon,
                          ),
                        ),
                      ),
                      if (!playable)
                        Positioned.fill(
                          child: Container(
                            // A strong dark scrim (not a light wash) so the
                            // card visibly reads as inactive rather than
                            // just slightly faded.
                            color: const Color(
                              0xFF14211D,
                            ).withValues(alpha: .68),
                            alignment: Alignment.center,
                            child: _LockedCardBadge(
                              icon: available
                                  ? Icons.lock_rounded
                                  : Icons.hourglass_bottom_rounded,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A locked/unavailable card's badge -- a chunky sticker circle (flat fill,
// hard offset "depth" shadow, no blur) in the same visual language as the
// status indicators on Home and the card's own play button.
class _LockedCardBadge extends StatelessWidget {
  const _LockedCardBadge({required this.icon});

  final IconData icon;

  static const _fill = Color(0xFFDADAD8);
  static const _depth = Color(0xFF908C8A);
  static const _iconColor = Color(0xFF6B6663);
  static const _diameter = 68.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: const BoxDecoration(
        color: _fill,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _depth, offset: Offset(0, 5))],
      ),
      child: Icon(icon, size: 32, color: _iconColor),
    );
  }
}

// Dynamically-built card art for every lesson besides Grade 1 Unit 1
// Lesson 1 (which has its own hand-drawn PNG) -- same color language and
// pixel positions as that PNG's own layout, just generated from the
// actual unit/lesson/title data instead of being baked into an image.
class _DynamicLessonCardArt extends StatelessWidget {
  const _DynamicLessonCardArt({
    required this.unit,
    required this.lessonNumber,
    required this.title,
    required this.cardRadius,
    required this.cardFill,
    required this.frameTeal,
    required this.labelTeal,
    required this.designWidth,
    required this.designHeight,
  });

  final AppUnit unit;
  final int lessonNumber;
  final String title;
  final double cardRadius;
  final Color cardFill;
  final Color frameTeal;
  final Color labelTeal;
  final double designWidth;
  final double designHeight;

  @override
  Widget build(BuildContext context) {
    final thumbnail = _lessonThumbnailForDashboard(unit.number, lessonNumber);
    return Stack(
      children: [
        Container(
          width: designWidth,
          height: designHeight,
          decoration: BoxDecoration(
            color: cardFill,
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
        Positioned(
          left: 19,
          top: 14,
          width: 26,
          height: 26,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: _unitThumbnailScaleForDashboard(unit.number),
              heightFactor: _unitThumbnailScaleForDashboard(unit.number),
              child: Image.asset(
                _unitThumbnailForDashboard(unit.number),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          left: 49,
          top: 14,
          width: 59,
          height: 29,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _CardStrokeLabel(
              text: 'yunit ${unit.number}',
              fontSize: 15,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: labelTeal,
            ),
          ),
        ),
        Positioned(
          left: 108,
          top: 14,
          width: 90,
          height: 29,
          child: Align(
            alignment: Alignment.centerRight,
            child: _CardStrokeLabel(
              text: unit.title.toUpperCase(),
              fontSize: 11,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              color: labelTeal,
            ),
          ),
        ),
        Positioned(
          left: 13,
          top: 60,
          width: 188,
          height: 142,
          child: Container(
            decoration: BoxDecoration(
              color: frameTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _DashboardSvgImage(asset: thumbnail),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 207,
          width: designWidth,
          height: 13,
          child: Center(
            child: _CardStrokeLabel(
              text: 'lesson ${unit.number}.$lessonNumber',
              fontSize: 11,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: labelTeal,
            ),
          ),
        ),
        Positioned(
          left: 3,
          top: 228,
          width: 207,
          height: 29,
          child: Container(
            color: frameTeal,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _CardStrokeLabel(
              text: title,
              fontSize: 14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: labelTeal,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardSvgImage extends StatelessWidget {
  final String asset;

  const _DashboardSvgImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      placeholderBuilder: (_) => Container(
        color: const Color(0xFFE7FCFF),
        child: const Center(child: TudloMascot(size: 120, mood: KokaMood.hi)),
      ),
    );
  }
}

/// Small badge icon for a unit -- shown on the "yunits" selector card and
/// on each lesson card's top-left corner.
String _unitThumbnailForDashboard(int unitNumber) {
  return switch ((AppData.selectedGradeLevel, unitNumber)) {
    (GradeLevel.grade1, 2) => 'assets/images/unit2_thumbnail.png',
    _ => 'assets/images/unit1_thumbnail.png',
  };
}

/// Each unit thumbnail's source PNG has its own amount of built-in padding
/// around the art, so the same display box doesn't render every unit's
/// icon at the same visual size -- this is the per-unit correction factor
/// (1.0 = no change) applied on top of that shared box.
double _unitThumbnailScaleForDashboard(int unitNumber) {
  return switch ((AppData.selectedGradeLevel, unitNumber)) {
    (GradeLevel.grade1, 2) => 0.8,
    _ => 1.0,
  };
}

String _lessonThumbnailForDashboard(int unitNumber, int lessonNumber) {
  return switch ((AppData.selectedGradeLevel, unitNumber, lessonNumber)) {
    (GradeLevel.grade1, 1, 1) =>
      'assets/images/level_game/backgrounds/classroom.svg',
    (GradeLevel.grade1, 1, 7) =>
      'assets/images/level_game/backgrounds/beach.svg',
    (GradeLevel.grade1, 2, _) =>
      'assets/images/level_game/backgrounds/house.svg',
    (GradeLevel.grade1, 3, _) =>
      'assets/images/level_game/backgrounds/lesson3-popup.svg',
    (GradeLevel.grade1, 4, _) =>
      'assets/images/level_game/backgrounds/lesson4-popup.svg',
    (GradeLevel.grade2, 1, 1) =>
      'assets/images/level_game/grade2/backgrounds/Tudlo_Classroom_Background_With_Ana.svg',
    (GradeLevel.grade2, 1, 2) =>
      'assets/images/level_game/grade2/backgrounds/Tudlo_Birthday_Background_Ana_Holding_Cake.svg',
    (GradeLevel.grade2, 2, _) =>
      'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Intro_Background.svg',
    (GradeLevel.grade3, 1, 1) =>
      'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets/background/MarketLandscape.svg',
    (GradeLevel.grade3, 1, 3) =>
      'assets/images/level_game/grade3/G3_U1_L1.3_Pagbakal_ni_Koka_sa_Merkado_SVG_Assets/background/MarketLandscape.svg',
    (GradeLevel.grade3, 2, 1) =>
      'assets/images/level_game/backgrounds/grade3_landscape/FarmLandscape 1.svg',
    (GradeLevel.grade3, 2, 2) =>
      'assets/images/level_game/backgrounds/grade3_landscape/ClassroomLandscape 1.svg',
    (GradeLevel.grade3, 1, _) =>
      'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets/background/MarketLandscape.svg',
    (GradeLevel.grade3, 2, _) =>
      'assets/images/level_game/backgrounds/grade3_landscape/FarmLandscape 1.svg',
    (GradeLevel.grade3, 3, _) =>
      'assets/images/level_game/backgrounds/garden.svg',
    (GradeLevel.grade3, 4, _) =>
      'assets/images/level_game/backgrounds/lesson3-popup.svg',
    (GradeLevel.grade3, 5, _) =>
      'assets/images/level_game/backgrounds/lesson4-popup.svg',
    _ => 'assets/images/level_game/backgrounds/classroom.svg',
  };
}

String _lessonTitleForDashboard(int level) {
  final unit = AppData.unitForLevel(level);
  final lesson = AppData.lessonNumberForLevel(level);
  return switch ((AppData.selectedGradeLevel, unit.number, lesson)) {
    (GradeLevel.grade1, 1, 1) => 'Ang Nadula nga mga Letra ni Koka',
    (GradeLevel.grade1, 1, 7) => 'Ang Lima ka Tikang Pakadto sa Payong',
    (GradeLevel.grade1, 2, 1) => 'Ang Litrato sang Pamilya',
    (GradeLevel.grade1, 2, 4) => 'Pamilya Picnic',
    _ => LessonBank.lessonTitleForLevel(level),
  };
}

// A dimmed pop-up shown when a lesson card's Play button is tapped, before
// actually launching the lesson -- this is where the lesson's VO narrates,
// rather than on the grid itself where several cards can be visible at
// once and there's no single card left to narrate automatically.
class _LessonStartPopup extends StatelessWidget {
  const _LessonStartPopup({required this.title, required this.onStart});

  final String title;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .78, 320.0);
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: TudloColors.ink,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: StickerPressButton(
                    key: const Key('lesson-start-popup-play-button'),
                    onPressed: onStart,
                    frontColor: const Color(0xFF4A7B6D),
                    depthColor: const Color(0xFF004A35),
                    height: 54,
                    borderRadius: 27,
                    child: Text(
                      'sugodan ta',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hand-drawn card art asset for lessons that have one, or null to fall
/// back to the dynamically-built card.
String? _lessonCardArtForDashboard(int unitNumber, int lessonNumber) {
  return switch ((AppData.selectedGradeLevel, unitNumber, lessonNumber)) {
    (GradeLevel.grade1, 1, 1) => 'assets/images/grade1_lesson1_card.png',
    (GradeLevel.grade1, 1, 7) => 'assets/images/grade1_unit1_lesson7_card.png',
    (GradeLevel.grade1, 2, 1) => 'assets/images/grade1_unit2_lesson1_card.png',
    (GradeLevel.grade1, 2, 4) => 'assets/images/grade1_unit2_lesson4_card.png',
    _ => null,
  };
}

class _MapHeader extends StatelessWidget {
  final String username;

  const _MapHeader({required this.username});

  @override
  Widget build(BuildContext context) {
    // Header uses a real image asset instead of painted shapes so it can be
    // easily swapped by replacing the game_map header asset.
    return Container(
      height: _mapHeaderHeight,
      width: double.infinity,
      decoration: const BoxDecoration(color: TudloColors.meadow),
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
                    child: const CustomPaint(
                      size: Size(34, 18),
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

class _AvailableLevelPositionedButton extends StatelessWidget {
  final int level;
  final Offset point;
  final Color unitColor;
  final bool current;
  final bool completed;
  final ValueChanged<Offset> onTap;

  const _AvailableLevelPositionedButton({
    required this.level,
    required this.point,
    required this.unitColor,
    required this.current,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = AppData.isProductionLessonAvailable(level);
    final unlocked = AppData.isLevelUnlocked(level);
    return _LevelPositionedButton(
      level: level,
      point: point,
      unitColor: available ? unitColor : Colors.grey.shade500,
      unlocked: available && unlocked,
      current: current && available,
      completed: completed,
      onTap: available && unlocked ? onTap : null,
    );
  }
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
