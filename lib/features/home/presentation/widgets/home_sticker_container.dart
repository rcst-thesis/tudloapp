import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_sticker_grid.dart';

/// The Home sticker section shell. Sticker content is intentionally absent
/// until the next Home step; this widget currently owns only its label, frame,
/// and navigation button.
class HomeStickerContainer extends StatelessWidget {
  const HomeStickerContainer({required this.onOpenStickers, super.key});

  static const double designWidth = 378;
  // Wide enough for the icon + "imo mga stickers" at its reference font
  // size; measured content is ~238 logical pixels, so this leaves a small
  // margin.
  static const double labelWidth = 240;
  static const double labelHeight = 22;
  static const double labelToFrameGap = 8;
  static const double frameHeight = 309;
  static const double frameRadius = 28;
  // Sticker grid tuning. These move the whole 5 x 2 thumbnail area without
  // affecting the label, frame, or round sticker-screen button.
  static const double stickerGridLeft = 17;
  static const double stickerGridTopInset = 20;
  static const double stickerGridOffsetX = 0;
  static const double stickerGridOffsetY = 0;

  // Sticker-screen button tuning. Edit these values to change only this
  // button's visual size or placement inside the brown sticker frame.
  static const double stickerScreenButtonWidth = 24;
  static const double stickerScreenButtonHeight = 33;
  static const double stickerScreenButtonOffsetX = 0;
  static const double stickerScreenButtonBottomInset = 4;

  static const double designHeight =
      labelHeight + labelToFrameGap + frameHeight;

  final VoidCallback onOpenStickers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / designWidth;
        final buttonLeft =
            ((designWidth - stickerScreenButtonWidth) / 2) +
            stickerScreenButtonOffsetX;
        final frameTop = labelHeight + labelToFrameGap;
        final buttonTop =
            frameTop +
            frameHeight -
            stickerScreenButtonHeight -
            stickerScreenButtonBottomInset;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: labelWidth * scale,
              height: labelHeight * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: labelWidth,
                  height: labelHeight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Image.asset(
                          'assets/images/home_sticker_label_icon.png',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'imo mga stickers',
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
              ),
            ),
            Positioned(
              left: 0,
              top: frameTop * scale,
              width: designWidth * scale,
              height: frameHeight * scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5D2B),
                  borderRadius: BorderRadius.circular(frameRadius * scale),
                ),
              ),
            ),
            Positioned(
              left: (stickerGridLeft + stickerGridOffsetX) * scale,
              top:
                  (frameTop + stickerGridTopInset + stickerGridOffsetY) * scale,
              width: HomeStickerGrid.designWidth * scale,
              height: HomeStickerGrid.designHeight * scale,
              child: const HomeStickerGrid(),
            ),
            Positioned(
              left: buttonLeft * scale,
              top: buttonTop * scale,
              width: stickerScreenButtonWidth * scale,
              height: stickerScreenButtonHeight * scale,
              child: Semantics(
                button: true,
                label: 'Open stickers',
                child: GestureDetector(
                  key: const Key('home-sticker-screen-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenStickers,
                  child: SvgPicture.asset(
                    'assets/images/home_sticker_screen_button.svg',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
