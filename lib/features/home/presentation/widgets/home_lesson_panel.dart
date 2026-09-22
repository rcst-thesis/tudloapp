import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/home/presentation/widgets/home_lesson_card.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel_layout.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_preview.dart';

export 'home_lesson_preview.dart';

/// Responsive Home lesson panel. It renders visual availability only: learner
/// progress decides each preview's status and energy remains a display cap.
class HomeLessonPanel extends StatefulWidget {
  const HomeLessonPanel({
    required this.energy,
    this.lesson = const HomeLessonPreview(
      unitTitle: 'yunit 1',
      category: 'ALPHABETO KAG NUMERO',
      status: HomeLessonStatus.completed,
    ),
    this.additionalLessons = const [],
    this.onLessonTap,
    this.onCollapsedChanged,
    super.key,
  });

  final int energy;
  final HomeLessonPreview lesson;
  final List<HomeLessonPreview> additionalLessons;
  final HomeLessonTapCallback? onLessonTap;
  final ValueChanged<bool>? onCollapsedChanged;

  /// HomeScene uses this before layout so its scroll extent matches the
  /// currently rendered cards. It must stay in step with [_LessonDeck].
  ///
  /// [configuredLessonCount] is the actual number of real lessons on offer
  /// (e.g. the grade's lesson catalog size) -- energy is a display cap, not
  /// an invitation to invent extra locked slots past what's really there.
  static double designHeightForEnergy(
    int energy, {
    required bool isCollapsed,
    required int configuredLessonCount,
  }) {
    final lessonCount = (energy.clamp(0, 60) ~/ 10)
        .clamp(0, 6)
        .clamp(0, configuredLessonCount);
    if (isCollapsed && lessonCount > 1) {
      final stackDepth = lessonCount.clamp(1, 3);
      return HomeLessonPanelLayout.headingIconSize +
          HomeLessonPanelLayout.headingToSectionGap +
          HomeLessonPanelLayout.cardHeight +
          (stackDepth - 1) * HomeLessonPanelLayout.deckVerticalOffset;
    }
    final sectionHeight = lessonCount > 1
        ? HomeLessonPanelLayout.headingToSectionGap +
              HomeLessonPanelLayout.sectionChevronSize +
              HomeLessonPanelLayout.sectionToCardGap
        : HomeLessonPanelLayout.headingToSectionGap;
    final cardsHeight = lessonCount * HomeLessonPanelLayout.cardHeight;
    final gapsHeight = lessonCount > 1
        ? (lessonCount - 1) * HomeLessonPanelLayout.lessonCardGap
        : 0.0;
    return HomeLessonPanelLayout.headingIconSize +
        sectionHeight +
        cardsHeight +
        gapsHeight;
  }

  @override
  State<HomeLessonPanel> createState() => _HomeLessonPanelState();
}

class _HomeLessonPanelState extends State<HomeLessonPanel> {
  bool _isExpanded = true;

  List<HomeLessonPreview> get _configuredLessons => [
    widget.lesson,
    ...widget.additionalLessons,
  ];

  // Energy is a display cap, not an invitation to invent curriculum: never
  // show more slots than there are real lessons, even at max energy.
  int get _availableLessons => ((widget.energy.clamp(0, 60) ~/ 10).clamp(
    0,
    6,
  )).clamp(0, _configuredLessons.length);

  List<HomeLessonPreview> get _visibleLessons =>
      _configuredLessons.take(_availableLessons).toList();

  bool get _canCollapse => _visibleLessons.length > 1;
  String get _summaryCategories =>
      _visibleLessons.map((lesson) => lesson.category).toSet().join(', ');

  void _setExpanded(bool expanded) {
    if (_isExpanded == expanded) return;
    setState(() => _isExpanded = expanded);
    widget.onCollapsedChanged?.call(!expanded);
  }

  @override
  Widget build(BuildContext context) {
    final lessonLabel = _availableLessons == 1 ? 'lesson' : 'lessons';
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / HomeLessonPanelLayout.designWidth;
        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvailabilityHeading(
                availableLessons: _availableLessons,
                lessonLabel: lessonLabel,
                scale: scale,
              ),
              _SectionHeading(
                isExpanded: _isExpanded,
                canCollapse: _canCollapse,
                scale: scale,
                onCollapse: () => _setExpanded(false),
              ),
              if (_visibleLessons.isEmpty)
                const SizedBox.shrink()
              else if (_isExpanded)
                _LessonList(
                  lessons: _visibleLessons,
                  scale: scale,
                  onLessonTap: widget.onLessonTap,
                )
              else
                _LessonDeck(
                  lesson: _visibleLessons.first,
                  summaryCategories: _summaryCategories,
                  stackDepth: _canCollapse
                      ? _visibleLessons.length.clamp(1, 3)
                      : 1,
                  scale: scale,
                  onTap: !_canCollapse ? null : () => _setExpanded(true),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AvailabilityHeading extends StatelessWidget {
  const _AvailabilityHeading({
    required this.availableLessons,
    required this.lessonLabel,
    required this.scale,
  });

  final int availableLessons;
  final String lessonLabel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: HomeLessonPanelLayout.headingLeftInset * scale,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/home_bookshelf_outline_white.png',
            width: HomeLessonPanelLayout.headingIconSize * scale,
            height: HomeLessonPanelLayout.headingIconSize * scale,
            fit: BoxFit.contain,
            semanticLabel: 'Available lessons',
          ),
          SizedBox(width: HomeLessonPanelLayout.headingGap * scale),
          Flexible(
            child: Text(
              '$availableLessons $lessonLabel subong nga adlaw!',
              key: const Key('home-lesson-availability'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'ComicRelief',
                fontSize: HomeLessonPanelLayout.headingFontSize * scale,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.isExpanded,
    required this.canCollapse,
    required this.scale,
    required this.onCollapse,
  });

  final bool isExpanded;
  final bool canCollapse;
  final double scale;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    if (!isExpanded || !canCollapse) {
      return SizedBox(
        height: HomeLessonPanelLayout.headingToSectionGap * scale,
      );
    }
    return Column(
      children: [
        SizedBox(height: HomeLessonPanelLayout.headingToSectionGap * scale),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Collapse lessons',
              child: InkResponse(
                key: const Key('home-lesson-collapse-toggle'),
                onTap: onCollapse,
                radius: 14 * scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'umpisahan ta subong adlaw',
                      key: const Key('home-lesson-section-label'),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'ComicRelief',
                        fontSize:
                            HomeLessonPanelLayout.sectionLabelFontSize * scale,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                    SizedBox(
                      width: HomeLessonPanelLayout.sectionChevronSize * scale,
                      height: HomeLessonPanelLayout.sectionChevronSize * scale,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: HomeLessonPanelLayout.sectionChevronSize * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: HomeLessonPanelLayout.sectionLabelToLineGap * scale,
            ),
            Expanded(
              child: SvgPicture.asset(
                'assets/images/home_lesson_divider.svg',
                height: HomeLessonPanelLayout.dividerHeight * scale,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
        SizedBox(height: HomeLessonPanelLayout.sectionToCardGap * scale),
      ],
    );
  }
}

class _LessonList extends StatefulWidget {
  const _LessonList({
    required this.lessons,
    required this.scale,
    required this.onLessonTap,
  });

  final List<HomeLessonPreview> lessons;
  final double scale;
  final HomeLessonTapCallback? onLessonTap;

  @override
  State<_LessonList> createState() => _LessonListState();
}

class _LessonListState extends State<_LessonList> {
  int? _openingLessonIndex;

  Future<void> _openLesson(int index, BuildContext cardContext) async {
    final callback = widget.onLessonTap;
    if (callback == null || _openingLessonIndex != null) return;
    final box = cardContext.findRenderObject()! as RenderBox;
    setState(() => _openingLessonIndex = index);
    await callback(
      widget.lessons[index],
      box.localToGlobal(Offset.zero) & box.size,
    );
    if (mounted) setState(() => _openingLessonIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < widget.lessons.length; index++) ...[
          SizedBox(
            height: HomeLessonPanelLayout.cardHeight * widget.scale,
            width: double.infinity,
            child: Builder(
              builder: (cardContext) => Opacity(
                opacity: _openingLessonIndex == index ? 0 : 1,
                child: GestureDetector(
                  key: Key('home-lesson-card-$index'),
                  onTap: widget.onLessonTap == null
                      ? null
                      : () => _openLesson(index, cardContext),
                  behavior: HitTestBehavior.opaque,
                  child: HomeLessonCard(lesson: widget.lessons[index]),
                ),
              ),
            ),
          ),
          if (index < widget.lessons.length - 1)
            SizedBox(
              height: HomeLessonPanelLayout.lessonCardGap * widget.scale,
            ),
        ],
      ],
    );
  }
}

class _LessonDeck extends StatelessWidget {
  const _LessonDeck({
    required this.lesson,
    required this.summaryCategories,
    required this.stackDepth,
    required this.scale,
    required this.onTap,
  });

  final HomeLessonPreview lesson;
  final String summaryCategories;
  final int stackDepth;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardHeight = HomeLessonPanelLayout.cardHeight * scale;
    final peekOffset = HomeLessonPanelLayout.deckVerticalOffset * scale;
    return Semantics(
      button: onTap != null,
      label: onTap == null ? null : 'Expand lessons',
      child: GestureDetector(
        key: onTap == null
            ? null
            : const Key('home-lesson-collapsed-deck-toggle'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: cardHeight + ((stackDepth - 1) * peekOffset),
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var layer = stackDepth - 1; layer >= 1; layer--)
                Positioned(
                  top: layer * peekOffset,
                  left:
                      (layer * HomeLessonPanelLayout.deckSideInset +
                          HomeLessonPanelLayout.deckHorizontalOffset) *
                      scale,
                  right:
                      (layer * HomeLessonPanelLayout.deckSideInset -
                          HomeLessonPanelLayout.deckHorizontalOffset) *
                      scale,
                  height: HomeLessonPanelLayout.deckCardHeight * scale,
                  child: DecoratedBox(
                    key: Key('home-lesson-deck-layer-$layer'),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(
                        HomeLessonPanelLayout.cardRadius * scale,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x22000000),
                          offset: Offset(0, scale),
                          blurRadius: scale,
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: cardHeight,
                child: HomeLessonCard(
                  key: const Key('home-lesson-card'),
                  lesson: lesson,
                  isElevated: stackDepth > 1,
                  isSummary: onTap != null,
                  summaryCategories: summaryCategories,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
