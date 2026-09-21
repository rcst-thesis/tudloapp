import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _pageIndex = 0;
  String? _lastNarrationKey;

  static const _pages = [
    _TudloOnboardingPageData(
      hiligaynonTitle: 'Tuon sang Hiligaynon',
      englishTitle: 'Learn Hiligaynon',
      hiligaynonDescription:
          'Magtuon sang Hiligaynon paagi sa leksiyon, estorya, ehemplo, kag lingaw nga buluhaton.',
      englishDescription:
          'Learn Hiligaynon through fun lessons, stories, examples, and interactive activities.',
      hiligaynonVoice:
          'Maayong pag-abot, abyan! Diri makatuon kita sang Hiligaynon paagi sa sari-sari nga leksiyon, istorya, mga ehemplo, kag kaliliagaw nga mga buluhaton!',
      englishVoice:
          'Welcome to Tudlo! Here, you can learn Hiligaynon through lessons, stories, examples, and fun activities. Let us start learning!',
      color: TudloColors.green,
      accent: TudloColors.gold,
    ),
    _TudloOnboardingPageData(
      hiligaynonTitle: 'Tinaga',
      englishTitle: 'Dictionary',
      hiligaynonDescription:
          'Mangita sang Hiligaynon kag English nga tinaga kag pamatii ang ila paglitok.',
      englishDescription:
          'Search Hiligaynon and English words anytime. Listen to pronunciation and discover new words.',
      hiligaynonVoice:
          'Diri, puwede ka man makapangita sang mga tinaga nga gusto mo mahibaluan kag kon ano ang ila kahulugan.',
      englishVoice:
          'You can search for words in Hiligaynon and English. Listen to their correct pronunciation and discover new words every day.',
      color: TudloColors.blue,
      accent: TudloColors.softGreen,
    ),
    _TudloOnboardingPageData(
      hiligaynonTitle: 'Hubad',
      englishTitle: 'Translate',
      hiligaynonDescription:
          'Ihubad ang tinaga kag simple nga pangungusap sa Hiligaynon kag English.',
      englishDescription:
          'Translate words and simple sentences between Hiligaynon and English.',
      hiligaynonVoice:
          'Puwede mo man diri mahubad ang imo mga tinaga halin sa Hiligaynon pakadto sa English, ukon halin sa English pakadto sa Hiligaynon.',
      englishVoice:
          'You can translate words and simple sentences from Hiligaynon to English, and from English to Hiligaynon anytime.',
      color: TudloColors.coral,
      accent: TudloColors.sky,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNarrationIfNeeded();
  }

  Future<void> _finish() async {
    final appState = AppStateScope.of(context);
    await TudloVoiceButton.stop();
    await appState.markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
      (_) => false,
    );
  }

  Future<void> _next() async {
    if (_pageIndex >= _pages.length - 1) {
      await _finish();
      return;
    }
    await TudloVoiceButton.stop();
    if (!mounted) return;
    await _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleNarrationIfNeeded() {
    final appState = AppStateScope.of(context);
    final key = '$_pageIndex-${appState.appLanguage}';
    if (_lastNarrationKey == key) return;
    final pageIndex = _pageIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageIndex != pageIndex) return;
      unawaited(_playNarrationForPage(pageIndex));
    });
  }

  Future<void> _playNarrationForPage(int index, {bool force = false}) {
    if (index < 0 || index >= _pages.length) return Future.value();
    final appState = AppStateScope.of(context);
    final key = '$index-${appState.appLanguage}';
    if (!force && _lastNarrationKey == key) return Future.value();
    _lastNarrationKey = key;
    final activePage = _pages[index];
    final useHiligaynon = appState.isHiligaynon;
    return TudloVoiceButton.speak(
      context,
      activePage.voiceText(useHiligaynon),
      hiligaynon: useHiligaynon,
    );
  }

  Future<void> _handlePageChanged(int value) async {
    setState(() => _pageIndex = value);
    await TudloVoiceButton.stop();
    if (!mounted) return;
    unawaited(_playNarrationForPage(value, force: true));
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isHiligaynon = appState.isHiligaynon;
    final activePage = _pages[_pageIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 820 || constraints.maxWidth < 390;
            return Padding(
              padding: EdgeInsets.fromLTRB(22, compact ? 12 : 18, 22, 18),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: TudloLanguageToggle(),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _controller,
                                itemCount: _pages.length,
                                onPageChanged: (value) {
                                  unawaited(_handlePageChanged(value));
                                },
                                itemBuilder: (context, index) {
                                  return _TudloOnboardingPage(
                                    data: _pages[index],
                                    compact: compact,
                                    hiligaynon: isHiligaynon,
                                  );
                                },
                              ),
                            ),
                            _OnboardingBottomNav(
                              count: _pages.length,
                              activeIndex: _pageIndex,
                              color: activePage.color,
                              hiligaynon: isHiligaynon,
                              onSkip: () => unawaited(_finish()),
                              onNext: () => unawaited(_next()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TudloOnboardingPage extends StatelessWidget {
  final _TudloOnboardingPageData data;
  final bool compact;
  final bool hiligaynon;

  const _TudloOnboardingPage({
    required this.data,
    required this.compact,
    required this.hiligaynon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28, compact ? 18 : 32, 28, 0),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Center(
              child: TudloMascot(
                size: compact ? 230 : 290,
                mood: KokaMood.idle,
              ),
            ),
          ),
          const Spacer(flex: 1),
          Text(
            data.titleText(hiligaynon),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: compact ? 34 : 40,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.descriptionText(hiligaynon),
            textAlign: TextAlign.center,
            maxLines: compact ? 4 : 5,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: TudloColors.muted,
              fontSize: compact ? 18 : 21,
              height: 1.18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: compact ? 18 : 26),
        ],
      ),
    );
  }
}

class _OnboardingBottomNav extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color color;
  final bool hiligaynon;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _OnboardingBottomNav({
    required this.count,
    required this.activeIndex,
    required this.color,
    required this.hiligaynon,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = activeIndex == count - 1;
    return SizedBox(
      height: 68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonFont = constraints.maxWidth < 350 ? 14.0 : 16.0;
          return Row(
            children: [
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        hiligaynon ? 'Laktawan' : 'Skip',
                        style: GoogleFonts.nunito(
                          color: TudloColors.muted.withValues(alpha: .58),
                          fontSize: buttonFont,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: _OnboardingDots(
                    count: count,
                    activeIndex: activeIndex,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: isLast
                        ? ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              minimumSize: const Size(104, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: GoogleFonts.nunito(
                                fontSize: buttonFont,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                            child: Text(
                              hiligaynon ? 'SUGDAN' : 'START',
                              maxLines: 1,
                              softWrap: false,
                            ),
                          )
                        : TextButton(
                            onPressed: onNext,
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: const Size(0, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              hiligaynon ? 'PADAYON' : 'NEXT',
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.nunito(
                                color: color,
                                fontSize: buttonFont,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _OnboardingDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: index == activeIndex ? 11 : 7,
            height: index == activeIndex ? 11 : 7,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? TudloColors.green
                  : TudloColors.line,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _TudloOnboardingPageData {
  final String hiligaynonTitle;
  final String englishTitle;
  final String hiligaynonDescription;
  final String englishDescription;
  final String hiligaynonVoice;
  final String englishVoice;
  final Color color;
  final Color accent;

  const _TudloOnboardingPageData({
    required this.hiligaynonTitle,
    required this.englishTitle,
    required this.hiligaynonDescription,
    required this.englishDescription,
    required this.hiligaynonVoice,
    required this.englishVoice,
    required this.color,
    required this.accent,
  });

  String titleText(bool hiligaynon) =>
      hiligaynon ? hiligaynonTitle : englishTitle;

  String descriptionText(bool hiligaynon) =>
      hiligaynon ? hiligaynonDescription : englishDescription;

  String voiceText(bool hiligaynon) =>
      hiligaynon ? hiligaynonVoice : englishVoice;
}
