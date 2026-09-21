import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/shared/widgets/rive_avatar.dart';
import 'package:tudloapp/shared/widgets/rive_avatar_background.dart';
import 'package:tudloapp/shared/widgets/svg_text_overlay.dart';

/// The learner card's three sections, each backed by its own exported
/// Figma artwork (`assets/images/me_card_*.svg`): the card is genuinely
/// taller for [details] and [progress] than for [about].
enum MeCardTab { about, details, progress }

/// The Me screen's learner card. Header artwork (avatar placeholder,
/// name/grade/user code, postal-stamp mark) is identical across all three
/// exported SVGs; only the tab band position and the content below it
/// differ, so [selectedTab] swaps both the background asset and the card's
/// height.
///
/// All three SVGs bake their copy into vector paths, so name/grade/user
/// code, the tab band's pill/labels, and each tab's row content are masked
/// and redrawn as real Flutter text for accessibility, dynamic data, and a
/// selection pill that can actually move.
class MeLearnerCard extends StatelessWidget {
  const MeLearnerCard({
    required this.learnerName,
    required this.grade,
    required this.userCode,
    required this.avatarId,
    required this.selectedTab,
    required this.onTabSelected,
    required this.createdAt,
    this.lessonsFinished = 0,
    this.stickersEarned = 0,
    this.badgesEarned = 0,
    super.key,
  });

  final String learnerName;
  final int grade;
  final String userCode;
  final String avatarId;
  final MeCardTab selectedTab;
  final ValueChanged<MeCardTab> onTabSelected;
  final DateTime createdAt;

  /// Constructor-carried placeholders (same pattern as Home's `energy`)
  /// until real lesson/sticker/badge tracking exists; default to 0 rather
  /// than fabricating numbers.
  final int lessonsFinished;
  final int stickersEarned;
  final int badgesEarned;

  static const double _cardWidth = 374;
  static const Color _cardWhite = Colors.white;
  static const Color _bandTan = Color(0xFFFFE49A);
  static const Color _pillTan = Color(0xFFD9BF77);
  static const Color _labelMuted = Color(0xFFD5B488);
  static const Color _textSelected = Color(0xFF2A2A2A);
  static const Color _textUnselected = Color(0xFF806138);

  static const _pillWidth = 99.0;
  static const _pillHeight = 36.0;
  static const _pillGapAboveBand = 6.0;

  // Column left edges are a fixed, slightly-uneven grid from the exported
  // artwork (99-wide pills with ~14-15px gaps), not perfect thirds.
  static const _columnLeft = {
    MeCardTab.about: 22.0,
    MeCardTab.details: 135.0,
    MeCardTab.progress: 249.0,
  };

  static const _assetFor = {
    MeCardTab.about: 'assets/images/me_learner_card.svg',
    MeCardTab.details: 'assets/images/me_card_details.svg',
    MeCardTab.progress: 'assets/images/me_card_progress.svg',
  };

  static const _heightFor = {
    MeCardTab.about: 233.0,
    MeCardTab.details: 313.0,
    MeCardTab.progress: 313.0,
  };

  double get _cardHeight => _heightFor[selectedTab]!;
  double get _bandTop => _cardHeight - 48;

  /// How long this profile has existed, from [createdAt] to [now].
  ///
  /// Pure so it can be unit-tested without waiting on the clock; production
  /// callers omit [now] to use the current time.
  static String formatAge(DateTime createdAt, {DateTime? now}) {
    final days = (now ?? DateTime.now()).difference(createdAt).inDays;
    final clamped = days < 0 ? 0 : days;
    if (clamped == 1) return '1 day';
    return '$clamped days';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('me-learner-card'),
      label: '$learnerName, grade $grade, user code $userCode',
      child: AspectRatio(
        aspectRatio: _cardWidth / _cardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / _cardWidth;
            return Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    _assetFor[selectedTab]!,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                ..._headerOverlays(scale),
                ..._tabBand(scale),
                if (selectedTab == MeCardTab.details) ..._detailsContent(scale),
                if (selectedTab == MeCardTab.progress)
                  ..._progressContent(scale),
              ],
            );
          },
        ),
      ),
    );
  }

  // Identical across all three exported SVGs.
  List<Widget> _headerOverlays(double scale) {
    return [
      // The baked SVG art already reserves this exact rounded rectangle
      // (x:16, y:24, w:115, h:152 in the SVG's own 374-wide coordinate
      // space -- see assets/images/me_learner_card.svg) as the avatar's own
      // background/placeholder, so the live Rive avatar just draws directly
      // on top of it -- no separate mask needed, unlike the baked-text
      // overlays below.
      Positioned(
        key: const Key('me-learner-card-avatar'),
        left: 16 * scale,
        top: 24 * scale,
        width: 115 * scale,
        height: 152 * scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12 * scale),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RiveAvatarBackground(grade: grade),
              // `RiveAvatar` itself always fits its artboard with
              // `Fit.contain` (shared with the Edit popup's
              // preview/tiles, so not changed globally) -- scaled up here
              // so it reads bigger in this box too; the ClipRRect above
              // crops whatever spills past the rounded corners.
              Transform.scale(
                scale: 1.25,
                child: RiveAvatar(artboardId: avatarId),
              ),
            ],
          ),
        ),
      ),
      SvgTextMask(
        left: 146,
        top: 51,
        width: 90,
        height: 26,
        scale: scale,
        color: _cardWhite,
      ),
      SvgTextMask(
        left: 146,
        top: 80,
        width: 70,
        height: 18,
        scale: scale,
        color: _cardWhite,
      ),
      SvgTextMask(
        left: 146,
        top: 122,
        width: 70,
        height: 14,
        scale: scale,
        color: _cardWhite,
      ),
      SvgTextMask(
        left: 146,
        top: 136,
        width: 80,
        height: 16,
        scale: scale,
        color: _cardWhite,
      ),
      SvgCardText(
        key: const Key('me-learner-card-name'),
        text: learnerName,
        left: 147,
        top: 51,
        width: 90,
        height: 26,
        scale: scale,
        fontSize: 22,
        color: _textSelected,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-learner-card-grade'),
        text: 'grade $grade',
        left: 146,
        top: 80,
        width: 70,
        height: 18,
        scale: scale,
        fontSize: 14,
        color: _labelMuted,
        fontWeight: FontWeight.w400,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-learner-card-user-code-label'),
        text: 'user code',
        left: 146,
        top: 122,
        width: 70,
        height: 14,
        scale: scale,
        fontSize: 11,
        color: const Color(0xFFAD9E8B),
        fontWeight: FontWeight.w400,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-learner-card-user-code'),
        text: userCode,
        left: 146,
        top: 136,
        width: 80,
        height: 16,
        scale: scale,
        fontSize: 13,
        color: const Color(0xFFA07B57),
        alignment: Alignment.centerLeft,
      ),
    ];
  }

  // The SVGs bake a pill and black-vs-#806138 label color only under
  // whichever tab that export represents. Flutter redraws the pill under
  // whichever tab is actually selected and all three labels with the
  // correct selected/unselected color, so switching tabs (which also swaps
  // the background asset) never shows a stale pill or wrong label color.
  List<Widget> _tabBand(double scale) {
    final pillTop = _bandTop + _pillGapAboveBand;
    return [
      for (final tab in MeCardTab.values)
        SvgTextMask(
          left: _columnLeft[tab]!,
          top: pillTop,
          width: _pillWidth,
          height: _pillHeight,
          scale: scale,
          color: _bandTan,
        ),
      Positioned(
        left: _columnLeft[selectedTab]! * scale,
        top: pillTop * scale,
        width: _pillWidth * scale,
        height: _pillHeight * scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _pillTan,
            borderRadius: BorderRadius.circular(9 * scale),
          ),
        ),
      ),
      for (final tab in MeCardTab.values)
        Positioned(
          left: _columnLeft[tab]! * scale,
          top: pillTop * scale,
          width: _pillWidth * scale,
          height: _pillHeight * scale,
          child: Center(
            child: Text(
              tab.name,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
                color: tab == selectedTab ? _textSelected : _textUnselected,
              ),
            ),
          ),
        ),
      for (final tab in MeCardTab.values)
        Positioned(
          left: _columnLeft[tab]! * scale,
          top: _bandTop * scale,
          width: _pillWidth * scale,
          height: 48 * scale,
          child: Semantics(
            button: true,
            selected: tab == selectedTab,
            label: '${tab.name} tab',
            child: GestureDetector(
              key: Key('me-tab-${tab.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onTabSelected(tab),
            ),
          ),
        ),
    ];
  }

  // "age" (time since this profile was created), "friendship" (matches the
  // exported details.svg's own baked value, "Abyan" — this app's existing
  // Hiligaynon word for friend, already used in NameScreen's dialogue), and
  // "human" (the exported "<username>" placeholder — the learner's name).
  List<Widget> _detailsContent(double scale) {
    const labelColor = _labelMuted;
    const valueColor = _textSelected;
    return [
      SvgTextMask(
        left: 14,
        top: 183,
        width: 340,
        height: 22,
        scale: scale,
        color: _cardWhite,
      ),
      SvgTextMask(
        left: 14,
        top: 210,
        width: 340,
        height: 22,
        scale: scale,
        color: _cardWhite,
      ),
      SvgTextMask(
        left: 14,
        top: 238,
        width: 340,
        height: 22,
        scale: scale,
        color: _cardWhite,
      ),
      SvgCardText(
        key: const Key('me-details-age-label'),
        text: 'age',
        left: 16,
        top: 188,
        width: 60,
        height: 16,
        scale: scale,
        fontSize: 13,
        color: labelColor,
        fontWeight: FontWeight.w400,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-details-age-value'),
        text: formatAge(createdAt),
        left: 148,
        top: 185,
        width: 130,
        height: 20,
        scale: scale,
        fontSize: 17,
        color: valueColor,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-details-friendship-label'),
        text: 'friendship',
        left: 16,
        top: 213,
        width: 100,
        height: 18,
        scale: scale,
        fontSize: 13,
        color: labelColor,
        fontWeight: FontWeight.w400,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-details-friendship-value'),
        text: 'Abyan',
        left: 148,
        top: 212,
        width: 100,
        height: 20,
        scale: scale,
        fontSize: 17,
        color: valueColor,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-details-human-label'),
        text: 'human',
        left: 16,
        top: 242,
        width: 60,
        height: 16,
        scale: scale,
        fontSize: 13,
        color: labelColor,
        fontWeight: FontWeight.w400,
        alignment: Alignment.centerLeft,
      ),
      SvgCardText(
        key: const Key('me-details-human-value'),
        text: learnerName,
        left: 148,
        top: 240,
        width: 200,
        height: 18,
        scale: scale,
        fontSize: 14,
        color: valueColor,
        alignment: Alignment.centerLeft,
      ),
    ];
  }

  // The exported progress.svg has three category labels ("lesson
  // finished", "sticker earned", "badges earned") but no baked counts —
  // Flutter draws a real number above each, honestly starting at 0.
  static const _progressColumns = [
    (left: 6.0, width: 115.0, label: 'lesson finished'),
    (left: 130.0, width: 115.0, label: 'sticker earned'),
    (left: 247.0, width: 115.0, label: 'badges earned'),
  ];

  List<Widget> _progressContent(double scale) {
    final counts = [lessonsFinished, stickersEarned, badgesEarned];
    return [
      SvgTextMask(
        left: 4,
        top: 178,
        width: 366,
        height: 72,
        scale: scale,
        color: _cardWhite,
      ),
      for (var i = 0; i < _progressColumns.length; i++) ...[
        SvgCardText(
          key: Key('me-progress-label-$i'),
          text: _progressColumns[i].label,
          left: _progressColumns[i].left,
          top: 192,
          width: _progressColumns[i].width,
          height: 20,
          scale: scale,
          fontSize: 12,
          color: _labelMuted,
          fontWeight: FontWeight.w400,
          alignment: Alignment.center,
          autoFit: true,
        ),
        SvgCardText(
          key: Key('me-progress-count-$i'),
          text: '${counts[i]}',
          left: _progressColumns[i].left,
          top: 212,
          width: _progressColumns[i].width,
          height: 40,
          scale: scale,
          fontSize: 33,
          color: _textSelected,
          alignment: Alignment.center,
        ),
      ],
    ];
  }
}
