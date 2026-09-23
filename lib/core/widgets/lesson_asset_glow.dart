import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LessonAssetGlow extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final double fallbackSize;
  final Color color;

  const LessonAssetGlow({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackSize,
    this.color = const Color(0xFFFFD447),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          _LessonAssetGlowLayer(
            asset: asset,
            fallbackIcon: fallbackIcon,
            fallbackSize: fallbackSize,
            color: color,
            scale: 1.08,
            blur: 4.5,
            opacity: .78,
          ),
          _LessonAssetGlowLayer(
            asset: asset,
            fallbackIcon: fallbackIcon,
            fallbackSize: fallbackSize,
            color: color,
            scale: 1.16,
            blur: 11,
            opacity: .44,
          ),
        ],
      ),
    );
  }
}

class _LessonAssetGlowLayer extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final double fallbackSize;
  final Color color;
  final double scale;
  final double blur;
  final double opacity;

  const _LessonAssetGlowLayer({
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackSize,
    required this.color,
    required this.scale,
    required this.blur,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: _assetWidget(context),
          ),
        ),
      ),
    );
  }

  Widget _assetWidget(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholderBuilder: (_) =>
            Icon(fallbackIcon, color: color, size: fallbackSize),
      );
    }

    return Image.asset(
      asset,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          Icon(fallbackIcon, color: color, size: fallbackSize),
    );
  }
}
