import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/me/presentation/widgets/me_collection_container.dart';
import 'package:tudloapp/shared/widgets/tilt_thumbnail_tile.dart';

/// The "badges" section inside [MeCollectionContainer]: a 4x2 grid of the
/// 8 exported badge icons, plus the "badges" label.
///
/// All 8 exported badges (`assets/images/me_badge_1.svg` .. `me_badge_8.svg`)
/// are the gray "not earned" art only — there are no colored "earned"
/// variants yet, and no real per-learner badge-earning data. [earnedBadges]
/// is accepted now so this widget doesn't need to change shape once both
/// exist; until then every badge renders identically (honest, not
/// fabricated), regardless of what's passed in.
class MeBadgeCollection extends StatelessWidget {
  const MeBadgeCollection({this.earnedBadges = const [], super.key});

  final List<bool> earnedBadges;

  static const double _cardWidth = 372;
  static const double _cardHeight = 226;
  static const Color _labelColor = Color(0xFF9D7C21);

  static const _iconSize = 61.0;
  static const _columnLeft = [34.0, 115.0, 196.0, 277.0];
  static const _rowTop = [72.0, 147.0];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('me-badge-collection'),
      label: "Koka's badges",
      child: AspectRatio(
        aspectRatio: _cardWidth / _cardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / _cardWidth;
            return Stack(
              children: [
                const Positioned.fill(child: MeCollectionContainer()),
                Positioned(
                  left: 34 * scale,
                  top: 38 * scale,
                  child: Text(
                    'badges',
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                      color: _labelColor,
                    ),
                  ),
                ),
                for (var i = 0; i < 8; i++)
                  Positioned(
                    left: _columnLeft[i % 4] * scale,
                    top: _rowTop[i ~/ 4] * scale,
                    width: _iconSize * scale,
                    height: _iconSize * scale,
                    child: TiltThumbnailTile(
                      key: Key('me-badge-$i'),
                      child: SvgPicture.asset(
                        'assets/images/me_badge_${i + 1}.svg',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
