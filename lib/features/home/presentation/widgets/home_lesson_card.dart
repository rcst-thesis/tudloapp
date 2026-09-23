import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel_layout.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_preview.dart';

/// Each unit's own category icon -- matches the badge used on the lesson
/// dashboard's unit selector and cards. Also used by the lesson preview
/// popup so it shows the right unit's icon too.
String categoryIconForUnit(int unitNumber) {
  return switch (unitNumber) {
    2 => 'assets/images/unit2_thumbnail.png',
    _ => 'assets/images/home_lesson_category.png',
  };
}

/// One card in Home's lesson list or its collapsed summary deck.
class HomeLessonCard extends StatelessWidget {
  const HomeLessonCard({
    required this.lesson,
    this.isElevated = false,
    this.isSummary = false,
    this.summaryCategories,
    super.key,
  });

  final HomeLessonPreview lesson;
  final bool isElevated;
  final bool isSummary;
  final String? summaryCategories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / HomeLessonPanelLayout.designWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              HomeLessonPanelLayout.cardRadius * scale,
            ),
            boxShadow: isElevated
                ? [
                    BoxShadow(
                      color: const Color(0x16000000),
                      offset: Offset(0, 2 * scale),
                      blurRadius: 7 * scale,
                    ),
                  ]
                : null,
          ),
          child: isSummary
              ? _CollapsedLessonSummaryContent(
                  categories: summaryCategories ?? lesson.category,
                  scale: scale,
                )
              : _LessonCardContent(lesson: lesson, scale: scale),
        );
      },
    );
  }
}

class _LessonCardContent extends StatelessWidget {
  const _LessonCardContent({required this.lesson, required this.scale});

  final HomeLessonPreview lesson;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: HomeLessonPanelLayout.cardHorizontalPadding * scale,
      ),
      child: Row(
        children: [
          SizedBox(
            width: HomeLessonPanelLayout.dotsWidth * scale,
            height: HomeLessonPanelLayout.dotsHeight * scale,
            child: Transform.translate(
              offset: Offset(
                HomeLessonPanelLayout.dotsOffsetX * scale,
                HomeLessonPanelLayout.dotsOffsetY * scale,
              ),
              child: SvgPicture.asset(
                'assets/images/home_lesson_more_dots.svg',
                fit: BoxFit.contain,
                semanticsLabel: 'Lesson options',
              ),
            ),
          ),
          SizedBox(width: HomeLessonPanelLayout.dotsToIconGap * scale),
          Image.asset(
            categoryIconForUnit(lesson.unitNumber),
            width: HomeLessonPanelLayout.categoryIconSize * scale,
            height: HomeLessonPanelLayout.categoryIconSize * scale,
            fit: BoxFit.contain,
            semanticLabel: lesson.category,
          ),
          SizedBox(width: HomeLessonPanelLayout.categoryToTextGap * scale),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: HomeLessonPanelLayout.unitTextWidth * scale,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      lesson.unitTitle,
                      maxLines: 1,
                      style: _cardText(
                        fontSize: HomeLessonPanelLayout.unitFontSize * scale,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: HomeLessonPanelLayout.textColumnsGap * scale),
                Expanded(
                  child: Text(
                    lesson.category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _cardText(
                      fontSize: HomeLessonPanelLayout.categoryFontSize * scale,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: HomeLessonPanelLayout.statusGap * scale),
          _LessonStatusIndicator(status: lesson.status, scale: scale),
        ],
      ),
    );
  }

  TextStyle _cardText({required double fontSize, double height = 1}) {
    return TextStyle(
      color: const Color(0xFF151515),
      fontFamily: 'ComicRelief',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: height,
    );
  }
}

/// The collapsed deck describes the day rather than repeating card actions.
class _CollapsedLessonSummaryContent extends StatelessWidget {
  const _CollapsedLessonSummaryContent({
    required this.categories,
    required this.scale,
  });

  final String categories;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: HomeLessonPanelLayout.cardHorizontalPadding * scale,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/home_lesson_category.png',
            width: HomeLessonPanelLayout.categoryIconSize * scale,
            height: HomeLessonPanelLayout.categoryIconSize * scale,
            fit: BoxFit.contain,
            semanticLabel: 'Lessons for today',
          ),
          SizedBox(width: HomeLessonPanelLayout.summaryIconToTextGap * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mga lesson ta subong nga adlaw',
                  key: const Key('home-lesson-summary-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontFamily: 'ComicRelief',
                    fontSize:
                        HomeLessonPanelLayout.summaryTitleFontSize * scale,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                SizedBox(height: HomeLessonPanelLayout.summaryTextGap * scale),
                Text(
                  categories,
                  key: const Key('home-lesson-summary-categories'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF515151),
                    fontFamily: 'ComicRelief',
                    fontSize:
                        HomeLessonPanelLayout.summaryCategoryFontSize * scale,
                    fontWeight: FontWeight.w400,
                    height: 1,
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

class _LessonStatusIndicator extends StatelessWidget {
  const _LessonStatusIndicator({required this.status, required this.scale});

  final HomeLessonStatus status;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final (background, icon, iconColor) = switch (status) {
      HomeLessonStatus.completed => (
        const Color(0xFFEBEAEA),
        Icons.check_rounded,
        const Color(0xFF56C84D),
      ),
      HomeLessonStatus.available => (
        const Color(0xFFFFE7A1),
        Icons.play_arrow_rounded,
        const Color(0xFFB87926),
      ),
      HomeLessonStatus.locked => (
        const Color(0xFFEBEAEA),
        Icons.lock_rounded,
        const Color(0xFFB7B4B4),
      ),
    };
    return Semantics(
      label: 'Lesson ${status.name}',
      child: Container(
        width: HomeLessonPanelLayout.statusWidth * scale,
        height: HomeLessonPanelLayout.statusHeight * scale,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            HomeLessonPanelLayout.statusRadius * scale,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB7B4B4),
              offset: Offset(0, HomeLessonPanelLayout.statusDepth * scale),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: HomeLessonPanelLayout.statusIconSize * scale,
        ),
      ),
    );
  }
}
