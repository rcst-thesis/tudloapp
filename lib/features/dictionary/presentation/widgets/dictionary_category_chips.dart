import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';

/// A horizontal row of category filter chips -- "all" plus one per
/// distinct category. [selected] is null for "all". Selecting a chip
/// narrows [DictionaryBrowseScreen]'s catalog to that category.
class DictionaryCategoryChips extends StatelessWidget {
  const DictionaryCategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('dictionary-category-chips'),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'all',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _Chip(
              label: category,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DictionaryColors.ink : DictionaryColors.background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: Key('dictionary-category-chip-$label'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected ? Colors.white : DictionaryColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
