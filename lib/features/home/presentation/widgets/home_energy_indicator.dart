import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A battery-style energy gauge: the shell/nub/lightning-bolt/percent-badge
/// art comes from the SVG, but the 10 fill bars inside the battery window
/// are drawn here in Flutter, colored per [energy] (one bar per 10%) -- the
/// SVG used to bake 6 bars in as permanently-filled decoration, so the icon
/// always looked "full" no matter the actual value. Only the "n%" text
/// label was ever real.
class HomeEnergyIndicator extends StatelessWidget {
  const HomeEnergyIndicator({this.energy = 60, super.key});

  final int energy;

  // 10 bars = 10% per bar, an intuitive 1:1 mapping to the displayed
  // percentage. The original SVG only drew 6 bars at this same spacing,
  // which left roughly the right 40% of the battery window empty --
  // continuing that exact spacing for 10 bars fills the window edge to
  // edge instead.
  static const _barCount = 10;
  // The battery window's fill bars, in the SVG's own 78x52 coordinate
  // space (matches this widget's fixed SizedBox size 1:1, so no unit
  // conversion is needed) -- same per-bar geometry the SVG used to
  // hardcode as permanently-filled rects.
  static const _barLeftStart = 7.20801;
  static const _barLeftStep = 5.42383;
  static const _barTop = 23.1664;
  static const _barWidth = 4.33974;
  static const _barHeight = 21.6252;
  static const _barRadius = 2.16987;
  static const _filledColor = Color(0xFFAD6E47);

  @override
  Widget build(BuildContext context) {
    final displayedEnergy = energy.clamp(0, 100);
    final filledBars = (displayedEnergy / 100 * _barCount).round();
    return Semantics(
      key: const Key('home-energy-indicator'),
      label: 'Energy $displayedEnergy percent',
      child: SizedBox(
        width: 78,
        height: 52,
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/home_energy_indicator.svg',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            for (var index = 0; index < filledBars; index++)
              Positioned(
                left: _barLeftStart + index * _barLeftStep,
                top: _barTop,
                width: _barWidth,
                height: _barHeight,
                child: DecoratedBox(
                  key: Key('home-energy-bar-$index'),
                  decoration: BoxDecoration(
                    color: _filledColor,
                    borderRadius: BorderRadius.circular(_barRadius),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              top: 1,
              width: 34,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _filledColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$displayedEnergy%',
                    key: const Key('home-energy-label'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ComicRelief',
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
