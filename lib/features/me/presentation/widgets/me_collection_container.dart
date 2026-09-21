import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 1:1 copy of the exported collection-card shell
/// (`assets/images/me_collection_container.svg`): the white clothespin-hung
/// card that will hold the badges grid. No baked text — the badges label
/// and grid are a later step.
class MeCollectionContainer extends StatelessWidget {
  const MeCollectionContainer({super.key});

  static const double _cardWidth = 372;
  static const double _cardHeight = 226;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _cardWidth / _cardHeight,
      child: SvgPicture.asset(
        key: const Key('me-collection-container'),
        'assets/images/me_collection_container.svg',
        fit: BoxFit.contain,
        semanticsLabel: "Koka's badge collection",
      ),
    );
  }
}
