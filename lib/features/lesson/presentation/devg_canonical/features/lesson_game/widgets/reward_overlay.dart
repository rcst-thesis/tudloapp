import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/features/lesson/presentation/devg_canonical/core/theme/app_theme.dart';

class GradeThreeStickerRewardOverlay extends StatelessWidget {
  final String stickerAsset;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const GradeThreeStickerRewardOverlay({
    super.key,
    required this.stickerAsset,
    required this.message,
    this.primaryLabel = 'OK',
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final stickerHeight = (view.height * .50).clamp(210.0, 292.0).toDouble();
    final stickerWidth = stickerHeight * .64;
    final glowSize = stickerHeight * 1.34;
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: .56)),
        ),
        Positioned(
          left: view.width * .08,
          right: view.width * .08,
          top: view.height * .11,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: (view.width * .036).clamp(24.0, 38.0),
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  color: TudloColors.ink,
                  offset: Offset(0, 3),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -.10),
          child: GestureDetector(
            onTap: onPrimary,
            child: SizedBox(
              width: glowSize,
              height: glowSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: RadialGradient(
                        radius: .84,
                        colors: [
                          const Color(0xFFFFF0A8).withValues(alpha: .48),
                          const Color(0xFFFFD33D).withValues(alpha: .25),
                          Colors.transparent,
                        ],
                        stops: const [0, .50, 1],
                      ),
                    ),
                    child: SizedBox(width: glowSize, height: glowSize),
                  ),
                  Container(
                    width: stickerWidth,
                    height: stickerHeight,
                    padding: EdgeInsets.all(stickerHeight * .035),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFF3A6),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFF3A6).withValues(alpha: .66),
                          blurRadius: 26,
                          spreadRadius: 7,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFB800).withValues(alpha: .35),
                          blurRadius: 48,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _RewardStickerImage(asset: stickerAsset),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: view.width * .04,
          right: view.width * .04,
          bottom: view.height * .05,
          child: Row(
            children: [
              if (hasSecondary) ...[
                Expanded(
                  child: _GradeThreeRewardButton(
                    label: secondaryLabel!,
                    onTap: onSecondary!,
                    filled: false,
                  ),
                ),
                SizedBox(width: view.width * .02),
              ],
              Expanded(
                child: _GradeThreeRewardButton(
                  label: primaryLabel,
                  onTap: onPrimary,
                  filled: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardStickerImage extends StatelessWidget {
  final String asset;

  const _RewardStickerImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EmbeddedStickerImage?>(
      future: _loadEmbeddedStickerImage(asset),
      builder: (context, snapshot) {
        final embedded = snapshot.data;
        if (embedded != null) {
          return Image.memory(
            embedded.bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const _RewardStickerPlaceholder(),
          );
        }
        return const _RewardStickerPlaceholder();
      },
    );
  }
}

class _EmbeddedStickerImage {
  final Uint8List bytes;

  const _EmbeddedStickerImage(this.bytes);
}

Future<_EmbeddedStickerImage?> _loadEmbeddedStickerImage(String asset) async {
  if (!asset.toLowerCase().endsWith('.svg')) return null;
  try {
    final svg = await rootBundle.loadString(asset);
    final match = RegExp(
      r'data:image/(?:png|jpeg|jpg);base64,([^"]+)',
    ).firstMatch(svg);
    if (match == null) return null;
    return _EmbeddedStickerImage(base64Decode(match.group(1)!));
  } catch (_) {
    return null;
  }
}

class _RewardStickerPlaceholder extends StatelessWidget {
  const _RewardStickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFFFC928),
        size: 96,
      ),
    );
  }
}

class _GradeThreeRewardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _GradeThreeRewardButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final green = TudloColors.green;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: (view.height * .16).clamp(58.0, 86.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? green : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: green, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            color: filled ? Colors.white : green,
            fontSize: (view.width * .027).clamp(22.0, 34.0),
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
