import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
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
    _contentFuture = LessonBank.loadLevelContentForLevel(widget.level);
    unawaited(DictionaryData.initialize());
  }

  int get _localLessonNumber => ((widget.level - 1) % AppData.unitLevels) + 1;

  void _openLessonGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LevelGamePage(level: widget.level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 22.0 : 30.0;

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
              _IntroHeader(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 46),
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
  final VoidCallback onBack;

  const _IntroHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final backButtonSize = screenWidth < 380 ? 48.0 : 56.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
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
  late final List<_IntroLetterItem> _letters;

  @override
  void initState() {
    super.initState();
    _letters = _introLettersFor(widget.content);
    unawaited(_playLetterAnimation());
  }

  Future<void> _playLetterAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (_letters.isEmpty) {
      if (mounted) setState(() => _showStart = true);
      return;
    }

    for (var index = 0; index < _letters.length; index++) {
      if (!mounted) return;
      setState(() => _visibleLetters = index + 1);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) setState(() => _showStart = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Leksiyon ${widget.lessonNumber}',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: TudloColors.forest,
            fontSize: 38,
            height: 1.02,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 34),
        _IntroLetterGrid(
          children: [
            for (var index = 0; index < _letters.length; index++)
              _AnimatedIntroLetterCard(
                item: _letters[index],
                index: index,
                visible: index < _visibleLetters,
              ),
          ],
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _showStart
              ? _IntroStartButton(onPressed: widget.onStart)
              : const SizedBox(height: 72),
        ),
      ],
    );
  }

  List<_IntroLetterItem> _introLettersFor(LevelContent content) {
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
        'A': 'assets/images/level_game/Grade1/unit1/A.png',
        'N': 'assets/images/level_game/Grade1/unit1/N.png',
        'T': 'assets/images/level_game/Grade1/unit1/T.png',
        'Y': 'assets/images/level_game/Grade1/unit1/Y.png',
      }[letter.toUpperCase()],
    );
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

class _IntroLetterItem {
  final String label;
  final String? asset;

  const _IntroLetterItem({required this.label, this.asset});
}

class _IntroLetterGrid extends StatelessWidget {
  final List<Widget> children;

  const _IntroLetterGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final rowCount = ((children.length + 1) ~/ 2).clamp(1, 3);
    return SizedBox(
      width: 238,
      height: (rowCount * 120).toDouble(),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 1,
        children: children,
      ),
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

    return SizedBox(
      width: 110,
      height: 110,
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
            child: item.asset == null
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
                          fontSize: item.label.length == 1 ? 42 : 20,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Image.asset(
                    item.asset!,
                    width: 108,
                    height: 108,
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

class _IntroStartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _IntroStartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
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
