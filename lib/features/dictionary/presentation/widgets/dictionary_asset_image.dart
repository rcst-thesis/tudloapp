import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders [path] as an SVG (via `flutter_svg`) or a raster image
/// (`Image.asset`), chosen by file extension -- dictionary entries mix
/// designed SVG card art with raster sticker-art stand-ins.
class DictionaryAssetImage extends StatelessWidget {
  const DictionaryAssetImage({
    required this.path,
    required this.fit,
    super.key,
  });

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, fit: fit);
    }
    return Image.asset(path, fit: fit);
  }
}
