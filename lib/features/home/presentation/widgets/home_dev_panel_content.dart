import 'package:flutter/material.dart';

/// Supplied developer credits artwork positioned within the 378 x 63 panel.
class HomeDevPanelContent extends StatelessWidget {
  const HomeDevPanelContent({super.key});

  static const double designWidth = 378;
  static const double designHeight = 63;

  static const double _logoLeft = 20;
  static const double _logoTop = 7;
  // Change only this value to resize the supplied logo proportionally.
  static const double logoScale = 0.9;
  static const double _logoWidth = 113 * logoScale;
  static const double _logoHeight = 55 * logoScale;

  static const double _labelLeft = 142;
  static const double _labelTop = 9;
  static const double _labelWidth = 221;
  static const double _labelHeight = 45;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / designWidth;
        return Stack(
          children: [
            Positioned(
              left: _logoLeft * scale,
              top: _logoTop * scale,
              width: _logoWidth * scale,
              height: _logoHeight * scale,
              child: Image.asset(
                'assets/images/home_dev_panel_maralxtoadlu_logo.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              left: _labelLeft * scale,
              top: _labelTop * scale,
              width: _labelWidth * scale,
              height: _labelHeight * scale,
              child: Image.asset(
                'assets/images/home_dev_panel_label.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
