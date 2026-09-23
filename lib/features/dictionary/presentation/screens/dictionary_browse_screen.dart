import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_search.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_words.dart';
import 'package:tudloapp/features/dictionary/domain/featured_words.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_layout.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_bento_grid.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_category_chips.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_content_footer.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_header.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_lookup_page.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_search_bar.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_stroked_text.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_word_grid_card.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';

/// The real, functional dictionary browser: a "featured" bento tray
/// banner, a category filter, and a category-grouped catalog of every
/// word. Opened from [DictionaryScreen]'s decoy search bar. Selecting any
/// word shows its full flip card inline here, without leaving this screen.
///
/// Deliberately mirrors [DictionaryScreen]'s header/search-bar layout
/// (same header widget, same scale math, same [dictionaryTopOffset]) so
/// tapping the decoy bar doesn't look like a navigation at all -- the
/// search bar just appears to split into a "back" pill and a shorter,
/// now-real search bar.
class DictionaryBrowseScreen extends StatefulWidget {
  const DictionaryBrowseScreen({
    this.entries = DictionaryWords.all,
    this.initialEntry,
    super.key,
  });

  /// Override for tests; defaults to the real placeholder dataset.
  final List<DictionaryEntry> entries;

  /// When set, the screen opens straight to this entry's definition page
  /// (e.g. tapping a word in [DictionaryFavoritesCarousel]) instead of the
  /// tray/catalog list.
  final DictionaryEntry? initialEntry;

  static const _backgroundColor = Color(0xFFF9C4CE);
  static const _designWidth = 412.0;

  @override
  State<DictionaryBrowseScreen> createState() => _DictionaryBrowseScreenState();
}

class _DictionaryBrowseScreenState extends State<DictionaryBrowseScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _query = '';
  String? _selectedCategory;
  DictionaryEntry? _selectedEntry;

  /// Categories already bumped for the current (non-empty) search
  /// session -- avoids re-incrementing on every keystroke while the set of
  /// matched categories stays the same.
  var _trackedQueryCategories = <String>{};

  List<String> _featuredIds = const [];
  var _resolvedFeatured = false;

  // _filtered/_groupedByCategory/_suggestions/_ghostSuggestion used to be
  // plain getters re-scanning the whole ~940-entry pool on every build --
  // including builds triggered by things that don't change their inputs at
  // all (focus changes, category taps, selecting a word). Caching them and
  // only recomputing when the actual input (query/category/focus/cursor)
  // changes turns a keystroke from ~4 full-pool scans into 1-2.
  var _filtered = const <DictionaryEntry>[];
  var _groupedByCategory = const <String, List<DictionaryEntry>>{};
  var _suggestions = const <DictionaryEntry>[];
  String? _ghostSuggestion;

  @override
  void initState() {
    super.initState();
    _selectedEntry = widget.initialEntry;
    _recomputeFilter();
    _recomputeGhostSuggestion();
    _searchController.addListener(_handleQueryChanged);
    // Ghost-text autocomplete only makes sense while the field is actually
    // focused -- rebuild so it disappears the moment focus leaves.
    _searchFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only resolve once per mount -- didChangeDependencies can fire again
    // for unrelated inherited-widget changes.
    if (_resolvedFeatured) return;
    _resolvedFeatured = true;

    final controller = LearnerScope.of(context);
    final profile = controller.profile;
    final eligiblePool = widget.entries
        .where((e) => e.frontCardImage != null)
        .toList();
    if (eligiblePool.isEmpty) return;

    final selection = resolveFeatured(
      pool: eligiblePool,
      categoryCounts: profile?.categorySearchCounts ?? const {},
      storedIds: profile?.featuredIds,
      storedDate: profile?.featuredDate,
      history: profile?.featuredHistory ?? const {},
    );
    _featuredIds = selection.ids;
    if (selection.isNew) {
      // A fresh (not same-day-cached) pick -- also decay categorySearchCounts
      // here, once per day, so old interest fades instead of accumulating
      // forever and permanently locking in whichever category got an early
      // lead.
      final decayedCounts = decayCategorySearchCounts(
        profile?.categorySearchCounts ?? const {},
      );
      // Defer the actual persistence (which calls notifyListeners) past
      // this build/dependency-resolution phase to avoid a reentrant-build
      // assertion.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          controller.recordFeatured(
            ids: selection.ids,
            date: DateTime.now(),
            history: selection.history,
            decayedCategoryCounts: decayedCounts,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_handleFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(_recomputeGhostSuggestion);

  void _handleQueryChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _query = query;
      _recomputeFilter();
      _recomputeGhostSuggestion();
    });
    if (query.isEmpty) {
      _trackedQueryCategories = {};
      return;
    }
    final matchedCategories = {
      for (final entry in widget.entries)
        if (matchesSearch(entry.word, query) ||
            matchesSearch(entry.definition, query))
          entry.category,
    };
    final newlyMatched = matchedCategories.difference(_trackedQueryCategories);
    if (newlyMatched.isEmpty) return;
    _trackedQueryCategories = {..._trackedQueryCategories, ...newlyMatched};
    final controller = LearnerScope.of(context);
    for (final category in newlyMatched) {
      unawaited(controller.incrementCategorySearchCount(category));
    }
  }

  void _handleBack() {
    if (_selectedEntry != null) {
      setState(() => _selectedEntry = null);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _selectEntry(DictionaryEntry entry) {
    unawaited(
      LearnerScope.of(context).incrementCategorySearchCount(entry.category),
    );
    setState(() => _selectedEntry = entry);
  }

  void _selectCategory(String? category) {
    if (category != null) {
      unawaited(
        LearnerScope.of(context).incrementCategorySearchCount(category),
      );
    }
    setState(() {
      _selectedCategory = category;
      _recomputeFilter();
    });
  }

  List<DictionaryEntry> get _featured {
    final byId = {for (final e in widget.entries) e.id: e};
    return [
      for (final id in _featuredIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<String> get _categories =>
      {for (final e in widget.entries) e.category}.toList()..sort();

  /// Recomputes [_filtered]/[_groupedByCategory]/[_suggestions] together --
  /// call whenever [_query] or [_selectedCategory] actually changes (never
  /// from `build()`; see the class doc comment above the cache fields).
  void _recomputeFilter() {
    final category = _selectedCategory;
    _filtered = widget.entries.where((entry) {
      final matchesCategory = category == null || entry.category == category;
      final matchesQuery =
          matchesSearch(entry.word, _query) ||
          matchesSearch(entry.definition, _query);
      return matchesCategory && matchesQuery;
    }).toList();

    final grouped = <String, List<DictionaryEntry>>{};
    for (final entry in _filtered) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }
    _groupedByCategory = grouped;

    // "Did you mean...?" picks for a typo'd search -- only computed when
    // the query actually came up empty, so a normal successful search
    // never pays for the extra edit-distance scan.
    _suggestions = _query.isEmpty || _filtered.isNotEmpty
        ? const []
        : closestWordMatches(_query, widget.entries);
  }

  /// Recomputes [_ghostSuggestion] -- call whenever the typed text or focus
  /// state actually changes (never from `build()`).
  ///
  /// Inline "ghost text" autocomplete suffix for whatever's currently typed
  /// -- a pure spelling aid, not tappable/acceptable (see
  /// `DictionarySearchBar.ghostSuggestion`). Deliberately uses the raw,
  /// un-trimmed/un-lowercased `_searchController.text` (not [_query]) since
  /// the invisible "typed" span it's laid over must pixel-match exactly
  /// what's rendered in the real field, including case and a trailing
  /// space mid-typing. Suppressed unless the field is focused with the
  /// cursor collapsed at the very end -- showing a suffix anywhere else
  /// would be visually wrong.
  void _recomputeGhostSuggestion() {
    if (!_searchFocusNode.hasFocus) {
      _ghostSuggestion = null;
      return;
    }
    final text = _searchController.text;
    final selection = _searchController.selection;
    if (text.isEmpty || selection.baseOffset != text.length) {
      _ghostSuggestion = null;
      return;
    }
    _ghostSuggestion = autocompleteSuggestion(text, widget.entries);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntry;
    return Scaffold(
      key: const Key('dictionary-browse-screen'),
      backgroundColor: DictionaryBrowseScreen._backgroundColor,
      bottomNavigationBar: const AppBottomTabNavigation(currentIndex: 4),
      // Full-bleed, matching DictionaryScreen -- see dictionaryTopOffset.
      body: LayoutBuilder(
        builder: (context, viewport) {
          final canvasWidth = math.min(viewport.maxWidth, 720.0);
          final scale = canvasWidth / DictionaryBrowseScreen._designWidth;
          final footerHeight = 48 * scale;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: canvasWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fixed, never scrolls away: the search bar and category
                  // chips are how a learner actually gets anywhere on this
                  // screen, so they stay reachable no matter how far down
                  // the catalog they've scrolled -- no more scrolling back
                  // up just to change what you're looking for.
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20 * scale,
                      right: 20 * scale,
                      top: dictionaryTopOffset(context, scale),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (selected != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _CompactBackButton(
                              key: const Key('dictionary-browse-back-pill'),
                              onTap: _handleBack,
                            ),
                          )
                        else ...[
                          Center(child: DictionaryHeader(width: 220 * scale)),
                          SizedBox(height: 20 * scale),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BackPill(
                                  key: const Key('dictionary-browse-back-pill'),
                                  onTap: _handleBack,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DictionarySearchBar(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    ghostSuggestion: _ghostSuggestion,
                                    fieldKey: const Key(
                                      'dictionary-browse-search-field',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          DictionaryCategoryChips(
                            categories: _categories,
                            selected: _selectedCategory,
                            onSelected: _selectCategory,
                          ),
                        ],
                        SizedBox(height: 12 * scale),
                      ],
                    ),
                  ),
                  Expanded(
                    // A CustomScrollView/slivers, not a SingleChildScrollView
                    // over a Column, so the catalog grid below (potentially
                    // hundreds of cards, unfiltered) only builds the cards
                    // actually near the viewport instead of all of them up
                    // front -- see _CategoryCardGrid.
                    child: CustomScrollView(
                      key: const Key('dictionary-browse-scroll-view'),
                      slivers: [
                        if (selected != null)
                          _sliverBox(
                            scale: scale,
                            child: _SelectedWordView(entry: selected),
                          )
                        else
                          _BrowseListView(
                            scale: scale,
                            featured: _featured,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _selectCategory,
                            grouped: _groupedByCategory,
                            isSearching: _query.isNotEmpty,
                            suggestions: _suggestions,
                            onSelect: _selectEntry,
                          ),
                        // Standard sliver idiom for "glue to the bottom of a
                        // short page, otherwise sit right after long
                        // content": when everything above is shorter than
                        // the viewport, the leftover space plus Align pins
                        // the footer to the true bottom; when it's taller,
                        // there's ~no leftover space and the footer sits
                        // right after the content, same as scrolling to the
                        // end today. (In the rare case content's height
                        // lands within footerHeight of the viewport's
                        // height, the footer can render slightly short for
                        // that one layout -- a minor, rare edge case.)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: footerHeight,
                              child: const DictionaryContentFooter(),
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Wraps [child] as a `SliverToBoxAdapter` with the horizontal side inset
/// shared by every content sliver on this screen (scaled to match), so a
/// plain box widget can sit directly in a `CustomScrollView`'s sliver list.
/// [padding] overrides the default horizontal-only inset -- used once, for
/// the very first sliver, which also carries the screen's top inset.
Widget _sliverBox({
  required Widget child,
  required double scale,
  EdgeInsets? padding,
}) {
  return SliverPadding(
    padding: padding ?? EdgeInsets.symmetric(horizontal: 20 * scale),
    sliver: SliverToBoxAdapter(child: child),
  );
}

/// Styled identically to [DictionarySearchBar]'s own pill (same fill color,
/// fully-rounded corners) so sitting beside the now-shorter search bar
/// reads as if one full-width bar simply got "cut" into two pieces. Sized
/// to fill the row's height (via the parent `IntrinsicHeight` +
/// `CrossAxisAlignment.stretch`) so it matches the search bar exactly.
class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DictionaryColors.background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: Text(
              'back',
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: DictionaryColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small, standard-looking back control for the definition page -- no
/// search bar sits beside it here, so it doesn't need [_BackPill]'s
/// "cut bar" illusion sizing (full stadium shape, search-bar height). Just
/// a compact rounded icon button.
class _CompactBackButton extends StatelessWidget {
  const _CompactBackButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DictionaryColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: DictionaryColors.ink,
          ),
        ),
      ),
    );
  }
}

class _SelectedWordView extends StatelessWidget {
  const _SelectedWordView({required this.entry});

  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = LearnerScope.of(context);
    final favoritedWords = controller.profile?.favoritedWords ?? const {};
    return Align(
      alignment: Alignment.topLeft,
      child: DictionaryLookupPage(
        entry: entry,
        isFavorited: favoritedWords.contains(entry.id),
        onFavoriteChanged: (_) => controller.toggleFavoriteWord(entry.id),
      ),
    );
  }
}

class _BrowseListView extends StatelessWidget {
  const _BrowseListView({
    required this.scale,
    required this.featured,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.grouped,
    required this.isSearching,
    required this.suggestions,
    required this.onSelect,
  });

  final double scale;
  final List<DictionaryEntry> featured;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final Map<String, List<DictionaryEntry>> grouped;
  final bool isSearching;

  /// "Did you mean...?" picks for a typo'd search that came up empty --
  /// always empty when [grouped] isn't (see
  /// [_DictionaryBrowseScreenState._suggestions]).
  final List<DictionaryEntry> suggestions;
  final ValueChanged<DictionaryEntry> onSelect;

  /// How many cards to show per category before offering "see all" --
  /// only while browsing everything with no category picked and no active
  /// search (picking a category, or searching, already narrows things down
  /// enough that a cap would just add an extra tap for no reason). Cuts a
  /// scroll through hundreds of cards in every category down to a quick
  /// scan, with a deliberate tap to go deeper into any one category.
  static const _previewCap = 6;

  @override
  Widget build(BuildContext context) {
    final showPreviews = selectedCategory == null && !isSearching;
    // A group of slivers under one key, not a single box widget -- keeps
    // the existing find.byKey('dictionary-browse-list') presence/absence
    // checks working while letting the catalog grid below be a real,
    // lazily-built SliverGrid (see _CategoryCardGrid) instead of a Column
    // child that forces every card to build immediately.
    return SliverMainAxisGroup(
      key: const Key('dictionary-browse-list'),
      slivers: [
        if (!isSearching && featured.isNotEmpty)
          _sliverBox(
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DictionaryStrokedText(
                  'featured',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                DictionaryBentoGrid(entries: featured, onTap: onSelect),
                const SizedBox(height: 20),
              ],
            ),
          ),
        _sliverBox(
          scale: scale,
          child: const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: DictionaryStrokedText(
              'all words',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (grouped.isEmpty)
          _sliverBox(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'no words found',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      color: DictionaryColors.ink,
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'did you mean:',
                      style: TextStyle(
                        fontFamily: 'ComicRelief',
                        fontSize: 12,
                        color: DictionaryColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in suggestions)
                          _SuggestionChip(
                            entry: entry,
                            onTap: () => onSelect(entry),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          for (final category in grouped.keys) ...[
            _sliverBox(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: DictionaryColors.ink,
                        ),
                      ),
                    ),
                    if (showPreviews && grouped[category]!.length > _previewCap)
                      _SeeAllButton(
                        category: category,
                        count: grouped[category]!.length,
                        onTap: () => onCategorySelected(category),
                      ),
                  ],
                ),
              ),
            ),
            _CategoryCardGrid(
              scale: scale,
              entries: showPreviews
                  ? grouped[category]!.take(_previewCap).toList()
                  : grouped[category]!,
              onSelect: onSelect,
            ),
            _sliverBox(scale: scale, child: const SizedBox(height: 16)),
          ],
      ],
    );
  }
}

/// "see all 42" -- tapping it is exactly equivalent to tapping that
/// category's chip up in the fixed header (same [onTap] callback,
/// `onCategorySelected`), so browsing that category to completion reuses
/// the existing category-filter behavior instead of inventing a second,
/// parallel "expanded" state to keep in sync.
class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({
    required this.category,
    required this.count,
    required this.onTap,
  });

  final String category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('dictionary-see-all-$category'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'see all $count',
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: DictionaryColors.ink.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: DictionaryColors.ink.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable "did you mean: `word`" pill -- tapping one jumps straight to
/// that word's definition, same as tapping any other catalog/letter-index
/// entry, rather than just correcting the search box text.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.entry, required this.onTap});

  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DictionaryColors.cardBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: Key('dictionary-suggestion-${entry.id}'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            entry.word,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: DictionaryColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A real, lazily-built sliver grid -- only cards actually near the
/// viewport (plus Flutter's small default cache-extent buffer) get built,
/// unlike the `GridView.count(shrinkWrap: true, physics:
/// NeverScrollableScrollPhysics())` this replaced, which forced every card
/// in [entries] to build immediately regardless of what was visible (the
/// root cause of the browse screen's initial-load lag with the full,
/// unfiltered ~940-word catalog).
class _CategoryCardGrid extends StatelessWidget {
  const _CategoryCardGrid({
    required this.scale,
    required this.entries,
    required this.onSelect,
  });

  final double scale;
  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      sliver: SliverGrid(
        key: const Key('dictionary-catalog-grid'),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => DictionaryWordGridCard(
            entry: entries[i],
            onTap: () => onSelect(entries[i]),
          ),
          childCount: entries.length,
        ),
      ),
    );
  }
}
