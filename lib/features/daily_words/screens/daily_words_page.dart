import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:vector_graphics/vector_graphics.dart';

class DailyWordsPage extends StatelessWidget {
  final VoidCallback? onOpenLessons;

  const DailyWordsPage({super.key, this.onOpenLessons});

  @override
  Widget build(BuildContext context) {
    final word = _dailyWord();
    final palette = _DailyWordPalette.current();
    final appState = AppStateScope.of(context);
    final saved = appState.isFavoriteWord(word.hil);

    return Scaffold(
      backgroundColor: palette.bottom,
      body: Stack(
        children: [
          Positioned.fill(child: _DailyWordBackground(palette: palette)),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 740;
                final wide = constraints.maxWidth >= 700;
                final horizontalPadding = wide ? 42.0 : 20.0;
                final maxWidth = wide ? 620.0 : 460.0;
                final contentHeight = (constraints.maxHeight - 92).clamp(
                  650.0,
                  850.0,
                );
                final mascotSize = compact ? 104.0 : 132.0;
                final mascotTop = (contentHeight * .16).clamp(100.0, 136.0);
                final bannerHeight = compact ? 172.0 : 190.0;
                final availableLowerTop =
                    contentHeight - (compact ? 386.0 : 408.0);
                final naturalBannerTop =
                    mascotTop + mascotSize + (compact ? 28 : 38);
                final bannerTop = math.max(naturalBannerTop, availableLowerTop);
                final statsTop = bannerTop + bannerHeight + 10;
                final unitTop = statsTop + (compact ? 62 : 66);

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 8 : 12,
                      horizontalPadding,
                      104,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: SizedBox(
                        height: contentHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: _HomeStatusRow(),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: mascotTop,
                              child: Center(
                                child: TudloMascot(
                                  size: mascotSize,
                                  mood: KokaMood.hi,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: bannerTop,
                              child: SizedBox(
                                height: bannerHeight,
                                child: _DailyWordBanner(
                                  word: word,
                                  saved: saved,
                                  compact: compact,
                                  palette: palette,
                                  onFavorite: () =>
                                      appState.toggleFavoriteWord(word.hil),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: statsTop,
                              child: _HomeStatsStrip(palette: palette),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: unitTop,
                              child: _CurrentUnitCard(
                                palette: palette,
                                onOpenLessons: onOpenLessons,
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
          ),
        ],
      ),
    );
  }
}

class _HomeStatusRow extends StatelessWidget {
  const _HomeStatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: _pillDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.park_rounded, color: TudloColors.forest),
              const SizedBox(width: 8),
              Text(
                'Grado ${AppData.selectedGradeLevel.number}',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF0E5D3D),
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const EnergyIndicator(),
      ],
    );
  }
}

class _DailyWordBanner extends StatelessWidget {
  final LessonTerm word;
  final bool saved;
  final bool compact;
  final _DailyWordPalette palette;
  final VoidCallback onFavorite;

  const _DailyWordBanner({
    required this.word,
    required this.saved,
    required this.compact,
    required this.palette,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 12 : 14,
        20,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD75F), Color(0xFFFFB947)],
        ),
        border: Border.all(color: const Color(0xFFFFA928), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C5A17).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tinaga subong nga adlaw',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.black,
                  fontSize: compact ? 20 : 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              TudloVoiceButton(
                message: '${word.hil}. ${word.eng}',
                tooltip: 'Pamatii ang tinaga',
                size: compact ? 40 : 46,
              ),
              SizedBox(height: compact ? 5 : 7),
              Row(
                children: [
                  const SizedBox(width: 54),
                  Expanded(
                    child: Text(
                      word.hil.toLowerCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: Colors.black,
                        fontSize: compact ? 44 : 54,
                        height: .9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 54,
                    height: 52,
                    child: IconButton(
                      tooltip: saved ? 'Remove favorite' : 'Save favorite',
                      onPressed: onFavorite,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        saved ? Icons.favorite : Icons.favorite_rounded,
                        color: TudloColors.coral,
                        size: 46,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 0 : 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  _exampleFor(word),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: Colors.black,
                    fontSize: compact ? 13 : 14,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            bottom: -4,
            child: Opacity(
              opacity: .72,
              child: Icon(
                Icons.auto_stories_rounded,
                color: Colors.black.withValues(alpha: .50),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _exampleFor(LessonTerm word) {
    return switch (word.hil.toLowerCase()) {
      'balay' => 'naga istar ako sa akon balay',
      'kaon' => 'nagakaon ako sang mansanas',
      'tubig' => 'nag-inom ako sang tubig',
      'libro' => 'may libro ako',
      'ido' => 'ang ido nagadalagan',
      _ => word.eng,
    };
  }
}

class _HomeStatsStrip extends StatelessWidget {
  final _DailyWordPalette palette;

  const _HomeStatsStrip({required this.palette});

  @override
  Widget build(BuildContext context) {
    final currentUnit = AppData.unitForLevel(
      AppData.firstUnlockedIncompleteLevel,
    );
    final badges = AppData.levelStars.values.where((stars) => stars > 0).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _pillDecoration(radius: 30),
      child: Row(
        children: [
          Expanded(
            child: _HomeStat(
              icon: Icons.square_rounded,
              value: '${currentUnit.number}',
              label: 'yunit',
              color: TudloColors.forest,
            ),
          ),
          _HomeDivider(palette: palette),
          Expanded(
            child: _HomeStat(
              icon: Icons.star_rounded,
              value: '$badges',
              label: 'badges',
              color: TudloColors.gold,
            ),
          ),
          _HomeDivider(palette: palette),
          Expanded(
            child: _HomeStat(
              icon: Icons.bar_chart_rounded,
              value: '${AppData.completedLevelCount}/${AppData.maxLevel}',
              label: 'leksyon',
              color: palette.bannerWord,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDivider extends StatelessWidget {
  final _DailyWordPalette palette;

  const _HomeDivider({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 38,
      color: palette.bannerWord.withValues(alpha: .16),
    );
  }
}

class _HomeStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HomeStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 27),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 23,
                height: .9,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: TudloColors.ink.withValues(alpha: .74),
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentUnitCard extends StatelessWidget {
  final _DailyWordPalette palette;
  final VoidCallback? onOpenLessons;

  const _CurrentUnitCard({required this.palette, required this.onOpenLessons});

  @override
  Widget build(BuildContext context) {
    final unit = AppData.unitForLevel(AppData.firstUnlockedIncompleteLevel);
    final lessonNumber = AppData.lessonNumberForLevel(
      AppData.firstUnlockedIncompleteLevel,
    );
    final completed = AppData.completedLessonsByUnit[unit.number]?.length ?? 0;
    const color = Color(0xFF62B944);

    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: TudloColors.ink.withValues(alpha: .13),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenLessons,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            child: Row(
              children: [
                Text(
                  'ABC',
                  style: GoogleFonts.nunito(
                    color: TudloColors.blue,
                    fontSize: 24,
                    height: .9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'yunit ${unit.number}',
                            style: GoogleFonts.nunito(
                              color: Colors.black,
                              fontSize: 25,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              unit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF10163A),
                                fontSize: 13,
                                height: 1.02,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'leksyon ${unit.number}.$lessonNumber - $completed/${unit.lessonCount}',
                        style: GoogleFonts.nunito(
                          color: TudloColors.ink.withValues(alpha: .62),
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: 'Buksan ang leksyon',
                  onPressed: onOpenLessons,
                  style: IconButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(46, 46),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyWordBackground extends StatelessWidget {
  final _DailyWordPalette palette;

  const _DailyWordBackground({required this.palette});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: Stack(
        key: ValueKey(palette.asset),
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.bottom,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.top, palette.middle, palette.bottom],
              ),
            ),
          ),
          VectorGraphic(
            loader: AssetBytesLoader('${palette.asset}.vec'),
            fit: BoxFit.fill,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}

class _DailyWordPalette {
  final String asset;
  final Color top;
  final Color middle;
  final Color bottom;
  final Color bannerWord;
  final Color shadow;

  const _DailyWordPalette({
    required this.asset,
    required this.top,
    required this.middle,
    required this.bottom,
    required this.bannerWord,
    required this.shadow,
  });

  static _DailyWordPalette current([DateTime? dateTime]) {
    final hour = (dateTime ?? AppData.dailyWordNow()).hour;
    if (hour >= 5 && hour < 7) return dawn;
    if (hour >= 7 && hour < 11) return morning;
    if (hour >= 11 && hour < 14) return noon;
    if (hour >= 14 && hour < 17) return afternoon;
    if (hour >= 17 && hour < 20) return evening;
    if (hour >= 20 && hour < 23) return night;
    return midnight;
  }

  static const dawn = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-dawn.svg',
    top: Color(0xFFFFB38D),
    middle: Color(0xFFFFD36E),
    bottom: Color(0xFF9EE673),
    bannerWord: Color(0xFF4B189B),
    shadow: Color(0x663C1D24),
  );

  static const morning = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-morning.svg',
    top: Color(0xFFBDEEFF),
    middle: Color(0xFFDDF6B4),
    bottom: Color(0xFFBFF37F),
    bannerWord: Color(0xFF4B189B),
    shadow: Color(0x553C2E12),
  );

  static const noon = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-noon.svg',
    top: Color(0xFFFFF184),
    middle: Color(0xFFFFDE3A),
    bottom: Color(0xFFBBEF54),
    bannerWord: Color(0xFF4B189B),
    shadow: Color(0x55382700),
  );

  static const afternoon = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-afternoon.svg',
    top: Color(0xFFFF8B1A),
    middle: Color(0xFFFFB032),
    bottom: Color(0xFFD8EF65),
    bannerWord: Color(0xFF4B189B),
    shadow: Color(0x66351200),
  );

  static const evening = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-evening.svg',
    top: Color(0xFF7D58C8),
    middle: Color(0xFF533497),
    bottom: Color(0xFF243B67),
    bannerWord: Color(0xFF4B189B),
    shadow: Color(0x77190F33),
  );

  static const night = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-night.svg',
    top: Color(0xFF0F3150),
    middle: Color(0xFF10233A),
    bottom: Color(0xFF132B2E),
    bannerWord: Color(0xFF17324D),
    shadow: Color(0x88101E30),
  );

  static const midnight = _DailyWordPalette(
    asset: 'assets/images/word-of-the-day/wotd-midnight.svg',
    top: Color(0xFF0B223A),
    middle: Color(0xFF101E2E),
    bottom: Color(0xFF10272A),
    bannerWord: Color(0xFF17324D),
    shadow: Color(0x88101E30),
  );
}

LessonTerm _dailyWord() {
  const terms = [
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      type: LessonContentType.word,
      hil: 'Balay',
      eng: 'House',
      pronunciation: 'Ba-lay',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 1,
      type: LessonContentType.word,
      hil: 'Kaon',
      eng: 'Eat',
      pronunciation: 'Ka-on',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 1,
      type: LessonContentType.word,
      hil: 'Tubig',
      eng: 'Water',
      pronunciation: 'Tu-big',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 1,
      type: LessonContentType.word,
      hil: 'Libro',
      eng: 'Book',
      pronunciation: 'Lib-ro',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Animals',
      gradeLevel: 1,
      type: LessonContentType.word,
      hil: 'Ido',
      eng: 'Dog',
      pronunciation: 'I-do',
    ),
  ];
  final day = AppData.dailyWordNow().difference(DateTime(2026, 1, 1)).inDays;
  return terms[day.abs() % terms.length];
}

BoxDecoration _pillDecoration({double radius = 28}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: .88),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: TudloColors.ink.withValues(alpha: .10),
        blurRadius: 14,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
