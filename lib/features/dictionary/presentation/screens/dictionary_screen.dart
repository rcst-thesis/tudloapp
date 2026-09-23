import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_words.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_layout.dart';
import 'package:tudloapp/features/dictionary/presentation/screens/dictionary_browse_screen.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_content_footer.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_favorites_carousel.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_header.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_search_bar.dart';
import 'package:tudloapp/features/dictionary/domain/word_of_the_day.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_word_card.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';

/// The Dictionary tab: a flippable "word of the day" card and a favorites
/// carousel, backed by a small placeholder word dataset
/// ([DictionaryWords.all]). The search bar here is a decoy -- tapping it
/// opens [DictionaryBrowseScreen], which has the real, functional search.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({this.entries = DictionaryWords.all, super.key});

  /// Override for tests; defaults to the real placeholder dataset.
  final List<DictionaryEntry> entries;

  static const _backgroundColor = Color(0xFFF9C4CE);
  static const _designWidth = 412.0;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  DictionaryEntry? _wordOfTheDay;
  var _resolvedWordOfTheDay = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only resolve once per mount -- didChangeDependencies can fire again
    // for unrelated inherited-widget changes.
    if (_resolvedWordOfTheDay) return;
    _resolvedWordOfTheDay = true;

    final controller = LearnerScope.of(context);
    final profile = controller.profile;
    final eligiblePool = widget.entries
        .where((e) => e.frontCardImage != null)
        .toList();
    final selection = resolveWordOfTheDay(
      pool: eligiblePool.isNotEmpty ? eligiblePool : widget.entries,
      storedId: profile?.wordOfTheDayId,
      storedDate: profile?.wordOfTheDayDate,
      history: profile?.wordOfTheDayHistory ?? const {},
    );
    _wordOfTheDay = selection.entry;
    if (selection.isNew) {
      // Defer the actual persistence (which calls notifyListeners) past
      // this build/dependency-resolution phase to avoid a reentrant-build
      // assertion.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          controller.recordWordOfTheDay(
            id: selection.entry.id,
            date: DateTime.now(),
            history: selection.history,
          ),
        );
      });
    }
  }

  void _openBrowse(BuildContext context, {DictionaryEntry? initialEntry}) {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: DictionaryBrowseScreen(
          entries: widget.entries,
          initialEntry: initialEntry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = LearnerScope.of(context);
    final favoritedWords = controller.profile?.favoritedWords ?? const {};
    final wordOfTheDay = _wordOfTheDay ?? widget.entries.first;
    final favorites = widget.entries
        .where((e) => favoritedWords.contains(e.id))
        .toList();

    return Scaffold(
      key: const Key('dictionary-screen'),
      backgroundColor: DictionaryScreen._backgroundColor,
      bottomNavigationBar: const AppBottomTabNavigation(currentIndex: 4),
      // Full-bleed: no SafeArea (that plus this padding stacked into a
      // visible top gap). dictionaryTopOffset clears the status bar
      // precisely instead, and must match DictionaryBrowseScreen's exactly
      // so the header doesn't shift when the decoy bar opens it.
      body: LayoutBuilder(
        builder: (context, viewport) {
          final canvasWidth = math.min(viewport.maxWidth, 720.0);
          final scale = canvasWidth / DictionaryScreen._designWidth;
          final footerHeight = 48 * scale;
          return SingleChildScrollView(
            key: const Key('dictionary-content-scroll-view'),
            // ConstrainedBox(minHeight) + Stack/Positioned pins the footer
            // to the actual bottom of the screen even when content is
            // short, while still scrolling normally when content is taller
            // than the viewport. (Deliberately not IntrinsicHeight here --
            // that combo crashes when the subtree contains scrollables like
            // GridView/horizontal ListViews.)
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: canvasWidth),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20 * scale,
                          right: 20 * scale,
                          top: dictionaryTopOffset(context, scale),
                          bottom: 24 * scale + footerHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: DictionaryHeader(width: 220 * scale)),
                            SizedBox(height: 20 * scale),
                            DictionarySearchBar(
                              readOnly: true,
                              onTap: () => _openBrowse(context),
                            ),
                            SizedBox(height: 20 * scale),
                            const Text(
                              'word of the day',
                              style: TextStyle(
                                fontFamily: 'ComicRelief',
                                fontWeight: FontWeight.bold,
                                color: DictionaryColors.ink,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            DictionaryWordCard(
                              entry: wordOfTheDay,
                              isFavorited: favoritedWords.contains(
                                wordOfTheDay.id,
                              ),
                              onFavoriteChanged: (_) => controller
                                  .toggleFavoriteWord(wordOfTheDay.id),
                            ),
                            SizedBox(height: 20 * scale),
                            const Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: DictionaryColors.heart,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'my favorites',
                                  style: TextStyle(
                                    fontFamily: 'ComicRelief',
                                    fontWeight: FontWeight.bold,
                                    color: DictionaryColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8 * scale),
                            DictionaryFavoritesCarousel(
                              entries: favorites,
                              onSelect: (entry) =>
                                  _openBrowse(context, initialEntry: entry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Edge-to-edge, matching Home/Me's content footer (never
                  // inset), but still width-capped on very wide screens.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: canvasWidth),
                        child: SizedBox(
                          height: footerHeight,
                          child: const DictionaryContentFooter(),
                        ),
                      ),
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
