import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_asset_image.dart';

/// The "featured words" banner: one bento tray that sizes itself to however
/// many [entries] there actually are (1 to 5, caller's responsibility to
/// cap it there) -- 1 entry is just a single hero compartment, 2-5 entries
/// are a hero on top plus the rest split evenly in a row below, separated
/// by thin divider lines like a real bento box. No blank/placeholder
/// compartments -- the tray only ever shows real, tappable entries.
class DictionaryBentoGrid extends StatelessWidget {
  const DictionaryBentoGrid({
    required this.entries,
    required this.onTap,
    super.key,
  });

  final List<DictionaryEntry> entries;
  final ValueChanged<DictionaryEntry> onTap;

  static final _dividerColor = DictionaryColors.ink.withValues(alpha: 0.14);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final hero = entries.first;
    final rest = entries.length > 1 ? entries.sublist(1) : <DictionaryEntry>[];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        key: const Key('dictionary-bento-grid'),
        decoration: const BoxDecoration(color: DictionaryColors.background),
        child: Column(
          children: [
            _BentoCompartment(entry: hero, height: 150, onTap: onTap),
            if (rest.isNotEmpty) ...[
              Container(height: 1.5, color: _dividerColor),
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < rest.length; i++) ...[
                      if (i > 0) Container(width: 1.5, color: _dividerColor),
                      Expanded(
                        child: _BentoCompartment(
                          entry: rest[i],
                          height: 90,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BentoCompartment extends StatelessWidget {
  const _BentoCompartment({
    required this.entry,
    required this.height,
    required this.onTap,
  });

  final DictionaryEntry entry;
  final double height;
  final ValueChanged<DictionaryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    final frontCardImage = entry.frontCardImage;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('dictionary-bento-tile-${entry.id}'),
        onTap: () => onTap(entry),
        child: SizedBox(
          height: height,
          width: double.infinity,
          // The tray is already gated to art-eligible entries (see
          // resolveFeatured's caller), so frontCardImage is normally always
          // set here -- this text fallback only guards against that
          // invariant ever slipping.
          child: frontCardImage != null
              ? ClipRect(
                  child: DictionaryAssetImage(
                    path: frontCardImage,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    entry.word,
                    style: const TextStyle(
                      fontFamily: 'ComicRelief',
                      fontWeight: FontWeight.bold,
                      color: DictionaryColors.ink,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
