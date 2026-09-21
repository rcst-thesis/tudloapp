import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_asset_image.dart';

/// One catalog card: an image box (the word's [DictionaryEntry.frontCardImage]
/// when it has one, cropped to fill via `BoxFit.cover` rather than
/// letterboxed -- alignment matters more than showing 100% of the art here;
/// a plain semi-transparent placeholder box otherwise), the word, and a
/// one-line definition snippet. Used in the browse screen's
/// category-grouped catalog grid, in place of a bare text row.
class DictionaryWordGridCard extends StatelessWidget {
  const DictionaryWordGridCard({
    required this.entry,
    required this.onTap,
    super.key,
  });

  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DictionaryColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('dictionary-catalog-card-${entry.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: entry.frontCardImage != null
                    ? SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: DictionaryAssetImage(
                          path: entry.frontCardImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: DictionaryColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.definition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontSize: 11,
                  color: DictionaryColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
