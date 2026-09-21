import 'package:flutter/material.dart';

/// The label that introduces the developer panel below the sticker section.
class HomeDevPanelLabel extends StatelessWidget {
  const HomeDevPanelLabel({super.key});

  // Wide enough for the icon + "the dev" at its reference font size; measured
  // content is ~119 logical pixels, so this leaves a small margin.
  static const double designWidth = 122;
  static const double designHeight = 22;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: designWidth,
        height: designHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(
                'assets/images/home_dev_panel_label_icon.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'the dev',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'ComicRelief',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
