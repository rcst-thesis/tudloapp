import 'package:flutter/material.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';

enum _DictionaryMode { englishToHiligaynon, hiligaynonToEnglish }

/// Dictionary screen built from word-based DictionaryData entries.
///
/// It supports language direction switching, search, voice playback, and
/// the fixed A-Z index on the right side.
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  static const _pageSize = 80;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};
  _DictionaryMode _mode = _DictionaryMode.englishToHiligaynon;
  String _query = '';
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
    _searchController.addListener(() {
      setState(() {
        _query = DictionaryData.normalizeForSearch(_searchController.text);
        _visibleCount = _pageSize;
        _letterKeys.clear();
      });
    });
  }

  void _loadMore() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 600) {
      return;
    }
    final total = _filteredTerms.length;
    if (_visibleCount >= total) return;
    setState(() => _visibleCount = (_visibleCount + _pageSize).clamp(0, total));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _englishMode => _mode == _DictionaryMode.englishToHiligaynon;

  List<DictionaryEntry> get _filteredTerms {
    // Search checks both languages and is case-insensitive, so "house" and
    // "balay" can find the same vocabulary pair.
    final terms = DictionaryData.entries.where((entry) {
      if (_query.isEmpty) return true;
      return DictionaryData.normalizeForSearch(
            entry.english,
          ).contains(_query) ||
          DictionaryData.normalizeForSearch(entry.hiligaynon).contains(_query);
    }).toList();

    terms.sort((a, b) {
      final first = _englishMode ? a.english : a.hiligaynon;
      final second = _englishMode ? b.english : b.hiligaynon;
      return first.toLowerCase().compareTo(second.toLowerCase());
    });
    return terms;
  }

  List<_DictionarySection> get _sections {
    return _sectionsFor(_filteredTerms.take(_visibleCount));
  }

  List<_DictionarySection> _sectionsFor(Iterable<DictionaryEntry> terms) {
    // Group the filtered results by first letter based on the selected
    // language mode. English mode groups by English; Hiligaynon mode groups by
    // Hiligaynon.
    final grouped = <String, List<DictionaryEntry>>{};
    for (final entry in terms) {
      final word = _englishMode ? entry.english : entry.hiligaynon;
      final normalizedWord = DictionaryData.normalizeForSearch(word);
      final letter = normalizedWord.isEmpty
          ? '#'
          : normalizedWord[0].toUpperCase();
      grouped
          .putIfAbsent(RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#', () {
            return [];
          })
          .add(entry);
    }

    final letters = grouped.keys.toList()..sort();
    return letters
        .map((letter) => _DictionarySection(letter, grouped[letter]!))
        .toList();
  }

  void _jumpToLetter(String letter) {
    // The A-Z index scrolls to the requested section. If that letter is not in
    // the current filtered results, it jumps to the nearest next available
    // section, or the last section as a fallback.
    final allSections = _sectionsFor(_filteredTerms);
    final sectionLetters = allSections
        .map((section) => section.letter)
        .toList();
    if (sectionLetters.isEmpty) return;

    final targetLetter = sectionLetters.contains(letter)
        ? letter
        : sectionLetters.firstWhere(
            (sectionLetter) => sectionLetter.compareTo(letter) > 0,
            orElse: () => sectionLetters.last,
          );
    final needed = allSections
        .takeWhile((section) => section.letter.compareTo(targetLetter) <= 0)
        .fold<int>(0, (count, section) => count + section.terms.length);
    if (needed > _visibleCount) {
      setState(() => _visibleCount = needed);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToLetter(targetLetter),
      );
      return;
    }
    _scrollToLetter(targetLetter);
  }

  void _scrollToLetter(String letter) {
    final key = _letterKeys[letter];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: .05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: _DictionaryHeader(controller: _searchController),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 14, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _ModeSwitch(
                    mode: _mode,
                    onChanged: (mode) => setState(() {
                      _mode = mode;
                      _visibleCount = _pageSize;
                      _letterKeys.clear();
                    }),
                  ),
                ),
              ),
              if (sections.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No words found',
                      style: TextStyle(
                        color: TudloColors.muted,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 34, 128),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: sections.map((section) {
                        // All current sections are mounted so ensureVisible
                        // can reliably scroll to any A-Z letter.
                        final key = _letterKeys.putIfAbsent(
                          section.letter,
                          GlobalKey.new,
                        );
                        return _DictionarySectionView(
                          key: key,
                          section: section,
                          englishMode: _englishMode,
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            top: 186,
            right: 3,
            bottom: 118,
            child: _LetterIndex(onTap: _jumpToLetter),
          ),
        ],
      ),
    );
  }
}

class _DictionarySection {
  final String letter;
  final List<DictionaryEntry> terms;

  const _DictionarySection(this.letter, this.terms);
}

class _DictionaryHeader extends StatelessWidget {
  final TextEditingController controller;

  const _DictionaryHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 14,
        8,
        10,
      ),
      decoration: const BoxDecoration(color: Color(0xFF79AD55)),
      child: Column(
        children: [
          const Text(
            'Dictionary',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SearchField(controller: controller),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: const Color(0xFF5EA832),
      style: const TextStyle(
        color: TudloColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: 'Search word...',
        hintStyle: const TextStyle(
          color: Color(0xFF8D9690),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF5EA832),
          size: 29,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// This switch controls the dictionary direction:
// English words first, or Hiligaynon words first.
// The selected mode also decides how words are sorted and grouped by letter.
class _ModeSwitch extends StatelessWidget {
  final _DictionaryMode mode;
  final ValueChanged<_DictionaryMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E9E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Shows English as the main word and Hiligaynon as the translation.
          _ModePill(
            label: 'English',
            selected: mode == _DictionaryMode.englishToHiligaynon,
            onTap: () => onChanged(_DictionaryMode.englishToHiligaynon),
          ),
          // Shows Hiligaynon as the main word and English as the translation.
          _ModePill(
            label: 'Hiligaynon',
            selected: mode == _DictionaryMode.hiligaynonToEnglish,
            onTap: () => onChanged(_DictionaryMode.hiligaynonToEnglish),
          ),
        ],
      ),
    );
  }
}

// A single selectable option inside the dictionary mode switch.
// It uses a soft selected style instead of a full green fill so the toggle
// stays readable and matches the app's dictionary design.
class _ModePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        // Tapping the pill tells the parent Dictionary page to change modes.
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF61A934) : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF797F7A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// Displays one alphabet section in the dictionary, such as A, B, or C.
// Each section contains all visible words that start with that letter.
class _DictionarySectionView extends StatelessWidget {
  final _DictionarySection section;
  final bool englishMode;

  const _DictionarySectionView({
    super.key,
    required this.section,
    required this.englishMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 0, 8),
          child: Container(
            width: 29,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFF5EA832),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                section.letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        ...section.terms.map((term) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DictionaryCard(term: term, englishMode: englishMode),
          );
        }),
      ],
    );
  }
}

// A single dictionary word card.
// It shows the main word, its translation, and a speaker button for audio.
class _DictionaryCard extends StatelessWidget {
  final DictionaryEntry term;
  final bool englishMode;

  const _DictionaryCard({required this.term, required this.englishMode});

  @override
  Widget build(BuildContext context) {
    // The displayed order changes based on the selected dictionary mode.
    final mainWord = englishMode ? term.english : term.hiligaynon;
    final translatedWord = englishMode ? term.hiligaynon : term.english;

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                    children: [
                      TextSpan(text: mainWord),
                      const TextSpan(
                        text: ' = ',
                        style: TextStyle(color: TudloColors.muted),
                      ),
                      TextSpan(
                        text: translatedWord,
                        style: const TextStyle(color: Color(0xFF5EA832)),
                      ),
                    ],
                  ),
                ),
                if (term.partOfSpeech?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 3),
                  Text(
                    term.partOfSpeech!,
                    style: const TextStyle(
                      color: Color(0xFF9AA09B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _DictionarySpeakButton(message: mainWord, hiligaynon: !englishMode),
        ],
      ),
    );
  }
}

class _DictionarySpeakButton extends StatelessWidget {
  final String message;
  final bool hiligaynon;

  const _DictionarySpeakButton({
    required this.message,
    required this.hiligaynon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: 'Play pronunciation',
      onPressed: () =>
          TudloVoiceButton.speak(context, message, hiligaynon: hiligaynon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFEFF8E8),
        foregroundColor: const Color(0xFF5EA832),
        minimumSize: const Size(40, 40),
        iconSize: 26,
      ),
      icon: const Icon(Icons.volume_up_rounded),
    );
  }
}

// Fixed A-Z index on the right side of the Dictionary page.
// Tapping a letter asks the parent page to scroll to that letter section.
class _LetterIndex extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _LetterIndex({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return Container(
      width: 23,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: letters.split('').map((letter) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // The parent handles the scroll target because it owns the
              // ScrollController and the section GlobalKeys.
              onTap: () => onTap(letter),
              child: SizedBox(
                width: 22,
                height: 17,
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Color(0xFF5EA832),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
