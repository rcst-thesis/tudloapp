import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';

/// A favorite heart with a white outline. Flutter icons can't do a true
/// even-width stroke, so this layers a slightly larger white heart behind
/// the colored one -- a fake outline that reads correctly at these sizes.
class DictionaryHeartIcon extends StatelessWidget {
  const DictionaryHeartIcon({
    required this.favorited,
    this.size = 28,
    super.key,
  });

  final bool favorited;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = favorited
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size + 6, color: Colors.white),
          Icon(icon, size: size, color: DictionaryColors.heart),
        ],
      ),
    );
  }
}
