import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_card_front.dart';

/// "my favorites": one outer box holding the whole feature -- a
/// continuously, freely scrollable belt of tightly-spaced cards (no
/// page-snapping, no dots -- just drag through them). Card ratio
/// (366:584, height = width * 1.6) matches the user-supplied thumbnail
/// art's real proportions so `BoxFit.contain` (in [DictionaryCardFront])
/// never crops or letterboxes it. About 3 cards are visible at once.
class DictionaryFavoritesCarousel extends StatelessWidget {
  const DictionaryFavoritesCarousel({
    required this.entries,
    this.onSelect,
    super.key,
  });

  final List<DictionaryEntry> entries;

  /// Called with the tapped entry -- [DictionaryScreen] uses this to open
  /// that word's definition screen.
  final ValueChanged<DictionaryEntry>? onSelect;

  static const _cardGap = 8.0;
  static const _cardAspectRatio = 366 / 584;
  // ~3 cards visible at once, sized relative to the row's own width.
  static const _cardWidthFraction = 0.3;

  Widget _buildTile(DictionaryEntry entry, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('dictionary-favorite-tile-${entry.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onSelect == null ? null : () => onSelect!(entry),
          child: DictionaryCardFront(
            entry: entry,
            wordFontSize: 10,
            borderRadius: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      // Explicit width and height -- a landscape rectangle (wider than
      // tall) standing in for the carousel container when there's nothing
      // to show yet.
      return Container(
        key: const Key('dictionary-favorites-empty-card'),
        width: double.infinity,
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: DictionaryColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 28,
              color: DictionaryColors.ink.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'No favorites yet -- tap the heart on a word to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                color: DictionaryColors.ink,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('dictionary-favorites-container'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DictionaryColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth * _cardWidthFraction;
          final cardHeight = cardWidth / _cardAspectRatio;
          // A single favorite has nothing to scroll through -- center it
          // instead of leaving it stuck at the left edge.
          if (entries.length == 1) {
            return SizedBox(
              height: cardHeight,
              child: Center(
                key: const Key('dictionary-favorites-page-view'),
                child: _buildTile(entries.first, cardWidth, cardHeight),
              ),
            );
          }
          return SizedBox(
            height: cardHeight,
            child: ListView.builder(
              key: const Key('dictionary-favorites-page-view'),
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == entries.length - 1 ? 0 : _cardGap,
                  ),
                  child: _buildTile(entries[index], cardWidth, cardHeight),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
