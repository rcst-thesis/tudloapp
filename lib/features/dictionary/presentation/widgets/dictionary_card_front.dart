import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_asset_image.dart';

/// Shared card-front composition used by both the big word-of-the-day flip
/// card and the small favorites-carousel tiles. When
/// [DictionaryEntry.favThumbImage] is set, that fully-designed thumbnail is
/// shown as-is (it already bakes in the word label). When it isn't, this
/// renders a blank card at the same size/shape with just the word label --
/// no illustration exists for this entry yet, so there's nothing to show
/// but the word.
class DictionaryCardFront extends StatelessWidget {
  const DictionaryCardFront({
    required this.entry,
    this.borderRadius = 24,
    this.wordFontSize = 20,
    super.key,
  });

  final DictionaryEntry entry;
  final double borderRadius;
  final double wordFontSize;

  static const _labelColor = Color(0xFF5C2233);

  @override
  Widget build(BuildContext context) {
    final favThumbImage = entry.favThumbImage;
    if (favThumbImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: DictionaryColors.background,
          child: DictionaryAssetImage(path: favThumbImage, fit: BoxFit.contain),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        // Deliberately DictionaryColors.cardBackground, not .background --
        // the carousel/tray container behind this card is .background, so
        // using that same color here would make the blank card invisible
        // (no contrast, just a floating label). cardBackground gives it a
        // visible card outline at the real thumb's scale.
        color: DictionaryColors.cardBackground,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                entry.word,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.bold,
                  fontSize: wordFontSize,
                  color: _labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
