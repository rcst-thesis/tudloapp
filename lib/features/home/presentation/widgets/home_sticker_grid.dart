import 'package:flutter/material.dart';
import 'package:tudloapp/shared/widgets/tilt_thumbnail_tile.dart';

/// A bounded Home preview of the learner's sticker collection.
///
/// The Home container always shows at most ten thumbnails. The full sticker
/// screen can later receive the same [HomeStickerThumbnail] data without
/// coupling its layout or loading behavior to the Home scene.
class HomeStickerGrid extends StatelessWidget {
  const HomeStickerGrid({this.stickers = _defaultStickers, super.key});

  static const int maxVisibleStickers = 10;
  static const int columns = 5;
  static const int rows = 2;
  static const double tileWidth = 62;
  static const double tileHeight = 118;
  static const double horizontalGap = 8.5;
  static const double verticalGap = 14;
  static const double designWidth =
      (columns * tileWidth) + ((columns - 1) * horizontalGap);
  static const double designHeight =
      (rows * tileHeight) + ((rows - 1) * verticalGap);
  static const Color _unearnedOverlayColor = Color(0xCCB88956);

  static const List<HomeStickerThumbnail> _defaultStickers = [
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_dog.png',
      label: 'Dog sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_house.png',
      label: 'House sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_mother.png',
      label: 'Mother sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_cat.png',
      label: 'Cat sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_school.png',
      label: 'School sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_church.png',
      label: 'Church sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_market.png',
      label: 'Market sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_park.png',
      label: 'Park sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_farm.png',
      label: 'Farm sticker',
    ),
    HomeStickerThumbnail(
      assetPath: 'assets/images/home_sticker_beach.png',
      label: 'Beach sticker',
    ),
  ];

  final List<HomeStickerThumbnail> stickers;

  @override
  Widget build(BuildContext context) {
    final itemCount = stickers.length > maxVisibleStickers
        ? maxVisibleStickers
        : stickers.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / designWidth;
        final cacheHeight =
            (tileHeight * scale * MediaQuery.devicePixelRatioOf(context))
                .round();
        return RepaintBoundary(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: tileHeight * scale,
              crossAxisSpacing: horizontalGap * scale,
              mainAxisSpacing: verticalGap * scale,
            ),
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return TiltThumbnailTile(
                child: Semantics(
                  image: true,
                  label: sticker.isEarned
                      ? sticker.label
                      : '${sticker.label}, not earned yet',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8 * scale),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          sticker.assetPath,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          cacheHeight: cacheHeight,
                          excludeFromSemantics: true,
                        ),
                        if (!sticker.isEarned)
                          const ColoredBox(color: _unearnedOverlayColor),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// A presentation-level sticker record. Replace the default list with real
/// learner collection data later without changing the Home layout.
class HomeStickerThumbnail {
  const HomeStickerThumbnail({
    required this.assetPath,
    required this.label,
    this.isEarned = false,
  });

  final String assetPath;
  final String label;
  final bool isEarned;
}
