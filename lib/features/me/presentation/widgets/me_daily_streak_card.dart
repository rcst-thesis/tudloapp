import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/shared/widgets/svg_text_overlay.dart';

/// 1:1 copy of the exported daily-streak card
/// (`assets/images/me_daily_streak_card.svg`): checkmark badge, "day
/// streak" label, and "longest learning streak ever!" caption are all part
/// of the SVG. Only the streak count itself is baked into a vector path in
/// the export, so it is masked and redrawn as real Flutter text — the one
/// genuinely dynamic number on the card.
class MeDailyStreakCard extends StatelessWidget {
  const MeDailyStreakCard({this.currentStreak = 1, super.key});

  /// Constructor-carried placeholder (same pattern as the learner card's
  /// progress counts) until real streak tracking exists.
  final int currentStreak;

  static const double _cardWidth = 372;
  static const double _cardHeight = 74;
  static const Color _cardWhite = Colors.white;
  static const Color _numberColor = Color(0xFF9D7C21);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('me-daily-streak-card'),
      label: '$currentStreak day streak, longest learning streak ever',
      child: AspectRatio(
        aspectRatio: _cardWidth / _cardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / _cardWidth;
            return Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/me_daily_streak_card.svg',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                SvgTextMask(
                  left: 94,
                  top: 15,
                  width: 14,
                  height: 25,
                  scale: scale,
                  color: _cardWhite,
                ),
                SvgCardText(
                  key: const Key('me-daily-streak-count'),
                  text: '$currentStreak',
                  left: 94,
                  top: 15,
                  width: 16,
                  height: 25,
                  scale: scale,
                  fontSize: 24,
                  color: _numberColor,
                  alignment: Alignment.centerLeft,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
