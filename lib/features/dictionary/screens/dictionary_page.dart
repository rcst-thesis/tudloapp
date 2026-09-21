import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

enum _DictionaryMode { englishToHiligaynon, hiligaynonToEnglish }

String? activeDictionarySection(
  List<MapEntry<String, double>> positions, {
  double threshold = 210,
}) {
  String? active;
  for (final position in positions) {
    if (position.value > threshold) break;
    active = position.key;
  }
  return active ?? positions.firstOrNull?.key;
}

double dictionaryIndexScale(int index, int activeIndex) {
  if (activeIndex < 0) return 1;
  final distance = (index - activeIndex).toDouble();
  return 1 + .55 * math.exp(-(distance * distance) / 4.5);
}

double _dictionaryScale(BuildContext context) {
  return (MediaQuery.sizeOf(context).width / 430).clamp(1.0, 1.32).toDouble();
}

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
  static const _allPartsFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};
  _DictionaryMode _mode = _DictionaryMode.englishToHiligaynon;
  String _query = '';
  String _selectedPartOfSpeech = _allPartsFilter;
  String? _activeLetter;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _searchController.addListener(() {
      setState(() {
        _query = DictionaryData.normalizeForSearch(_searchController.text);
        _visibleCount = _pageSize;
        _activeLetter = null;
        _letterKeys.clear();
      });
    });
  }

  void _handleScroll() {
    _loadMore();
    _updateActiveLetter();
  }

  void _updateActiveLetter() {
    final positions = <MapEntry<String, double>>[];
    for (final entry in _letterKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      positions.add(MapEntry(entry.key, box.localToGlobal(Offset.zero).dy));
    }
    final active = activeDictionarySection(positions);
    if (active == _activeLetter) return;
    setState(() => _activeLetter = active);
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
      final partMatches =
          _selectedPartOfSpeech == _allPartsFilter ||
          entry.partOfSpeech?.trim() == _selectedPartOfSpeech;
      if (!partMatches) return false;
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

  List<String> get _partOfSpeechOptions {
    const preferredOrder = [
      _allPartsFilter,
      'Noun',
      'Verb',
      'Adjective',
      'Adverb',
      'Pronoun',
      'Preposition',
      'Conjunction/Connector',
      'Question Word',
      'Particle',
      'Expression',
      'Pseudo Verb',
    ];
    final available = {
      for (final entry in DictionaryData.entries)
        if ((entry.partOfSpeech?.trim().isNotEmpty ?? false) &&
            entry.partOfSpeech!.trim().length > 2)
          entry.partOfSpeech!.trim(),
    };
    return [
      for (final part in preferredOrder)
        if (part == _allPartsFilter || available.remove(part)) part,
      ...available.toList()..sort(),
    ];
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
      setState(() {
        _visibleCount = needed;
        _activeLetter = targetLetter;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToLetter(targetLetter),
      );
      return;
    }
    setState(() => _activeLetter = targetLetter);
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
    final scale = _dictionaryScale(context);
    final horizontalPad = 10.0 * scale;
    final indexWidth = 23.0 * scale;
    final indexRight = 3.0 * scale;
    final listRightPad = indexWidth + indexRight + 14 * scale;
    final headerTop = 186.0 * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: _DictionaryHeader(
                  controller: _searchController,
                  selectedPartOfSpeech: _selectedPartOfSpeech,
                  partOfSpeechOptions: _partOfSpeechOptions,
                  onPartOfSpeechChanged: (part) => setState(() {
                    _selectedPartOfSpeech = part;
                    _visibleCount = _pageSize;
                    _activeLetter = null;
                    _letterKeys.clear();
                  }),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  14 * scale,
                  horizontalPad,
                  12 * scale,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ModeSwitch(
                    mode: _mode,
                    onChanged: (mode) => setState(() {
                      _mode = mode;
                      _visibleCount = _pageSize;
                      _activeLetter = null;
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
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    0,
                    listRightPad,
                    128,
                  ),
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
            top: headerTop,
            right: indexRight,
            bottom: 118,
            child: _LetterIndex(
              activeLetter: _activeLetter ?? sections.firstOrNull?.letter,
              onTap: _jumpToLetter,
            ),
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
  final String selectedPartOfSpeech;
  final List<String> partOfSpeechOptions;
  final ValueChanged<String> onPartOfSpeechChanged;

  const _DictionaryHeader({
    required this.controller,
    required this.selectedPartOfSpeech,
    required this.partOfSpeechOptions,
    required this.onPartOfSpeechChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scale = _dictionaryScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8 * scale,
        MediaQuery.paddingOf(context).top + 14 * scale,
        8 * scale,
        12 * scale,
      ),
      decoration: const BoxDecoration(color: Color(0xFF79AD55)),
      child: Column(
        children: [
          Text(
            'Dictionary',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * scale),
          Row(
            children: [
              Expanded(child: _SearchField(controller: controller)),
              SizedBox(width: 8 * scale),
              _PartOfSpeechFilterButton(
                selected: selectedPartOfSpeech,
                options: partOfSpeechOptions,
                onChanged: onPartOfSpeechChanged,
              ),
            ],
          ),
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
    final scale = _dictionaryScale(context);
    return SizedBox(
      height: 52 * scale,
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF5EA832),
        style: TextStyle(
          color: TudloColors.ink,
          fontSize: 16 * scale,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: 'Search word...',
          hintStyle: TextStyle(
            color: const Color(0xFF8D9690),
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF5EA832),
            size: 29 * scale,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20 * scale),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20 * scale),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20 * scale),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _PartOfSpeechFilterButton extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PartOfSpeechFilterButton({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scale = _dictionaryScale(context);
    final active = selected != _DictionaryPageState._allPartsFilter;
    return PopupMenuButton<String>(
      tooltip: 'Filter part of speech',
      initialValue: selected,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) {
        return [
          for (final option in options)
            PopupMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option == selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: option == selected
                        ? const Color(0xFF5EA832)
                        : TudloColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
      child: Container(
        height: 52 * scale,
        constraints: BoxConstraints(
          minWidth: 54 * scale,
          maxWidth: 132 * scale,
        ),
        padding: EdgeInsets.symmetric(horizontal: 13 * scale),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5EA832) : Colors.white,
          borderRadius: BorderRadius.circular(18 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8 * scale,
              offset: Offset(0, 2 * scale),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: active ? Colors.white : const Color(0xFF5EA832),
              size: 28 * scale,
            ),
            if (active) ...[
              SizedBox(width: 6 * scale),
              Flexible(
                child: Text(
                  selected,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
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
    final scale = _dictionaryScale(context);
    return Container(
      height: 44 * scale,
      padding: EdgeInsets.all(3 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: const Color(0xFFE7E9E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
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
    final scale = _dictionaryScale(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        // Tapping the pill tells the parent Dictionary page to change modes.
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF61A934) : Colors.transparent,
            borderRadius: BorderRadius.circular(17 * scale),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF797F7A),
              fontSize: 15 * scale,
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
    final scale = _dictionaryScale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(2 * scale, 6 * scale, 0, 8 * scale),
          child: Container(
            width: 29 * scale,
            height: 25 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFF5EA832),
              borderRadius: BorderRadius.circular(6 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 4 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
            child: Center(
              child: Text(
                section.letter,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17 * scale,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        ...section.terms.map((term) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12 * scale),
            child: _DictionaryCard(term: term, englishMode: englishMode),
          );
        }),
      ],
    );
  }
}

class _DictionaryCard extends StatelessWidget {
  final DictionaryEntry term;
  final bool englishMode;

  const _DictionaryCard({required this.term, required this.englishMode});

  @override
  Widget build(BuildContext context) {
    final scale = _dictionaryScale(context);
    // The displayed order changes based on the selected dictionary mode.
    final mainWord = englishMode
        ? term.english
        : _capitalizeDictionaryWord(term.hiligaynon);
    final translatedWord = englishMode
        ? _capitalizeDictionaryWord(term.hiligaynon)
        : term.english;
    return Container(
      constraints: BoxConstraints(minHeight: 58 * scale),
      padding: EdgeInsets.fromLTRB(
        18 * scale,
        13 * scale,
        18 * scale,
        13 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 7 * scale,
            offset: Offset(0, 2 * scale),
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
                  text: TextSpan(
                    style: TextStyle(
                      color: TudloColors.ink,
                      fontSize: 22 * scale,
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
                  SizedBox(height: 4 * scale),
                  Text(
                    term.partOfSpeech!,
                    style: TextStyle(
                      color: const Color(0xFF9AA09B),
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
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

String _capitalizeDictionaryWord(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

// Fixed A-Z index on the right side of the Dictionary page.
// Tapping a letter asks the parent page to scroll to that letter section.
class _LetterIndex extends StatelessWidget {
  final String? activeLetter;
  final ValueChanged<String> onTap;

  const _LetterIndex({required this.activeLetter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scale = _dictionaryScale(context);
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final activeIndex = activeLetter == null
        ? -1
        : letters.indexOf(activeLetter!);
    return Container(
      width: 23 * scale,
      padding: EdgeInsets.symmetric(vertical: 5 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 5 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: letters.split('').indexed.map((entry) {
            final (index, letter) = entry;
            final active = index == activeIndex;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // The parent handles the scroll target because it owns the
              // ScrollController and the section GlobalKeys.
              onTap: () => onTap(letter),
              child: SizedBox(
                width: 22 * scale,
                height: 17 * scale,
                child: Center(
                  child: AnimatedScale(
                    key: ValueKey('dictionary-index-$letter'),
                    scale: dictionaryIndexScale(index, activeIndex),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutBack,
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: active
                            ? TudloColors.forest
                            : const Color(0xFF5EA832),
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w900,
                      ),
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
