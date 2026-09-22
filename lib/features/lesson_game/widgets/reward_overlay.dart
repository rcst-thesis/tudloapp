import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/theme/app_theme.dart';

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
    final hasSecondary = secondaryLabel != null && onSecondary != null;
    final buttonHeight = (view.height * .075).clamp(36.0, 46.0).toDouble();
    final buttonBottom = (view.height * .045).clamp(14.0, 26.0).toDouble();
    final middleTop = (view.height * .075).clamp(22.0, 40.0).toDouble();
    final middleBottom = buttonBottom + buttonHeight + 10;
    final middleHeight = (view.height - middleTop - middleBottom)
        .clamp(150.0, 380.0)
        .toDouble();
    final messageHeight = (view.height * .14).clamp(48.0, 72.0).toDouble();
    final stickerHeight = (middleHeight - messageHeight - 4)
        .clamp(170.0, 340.0)
        .toDouble();
    final stickerWidth = (view.width * .48)
        .clamp(330.0, 470.0)
        .toDouble()
        .clamp(0.0, view.width * .72)
        .toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: .50)),
        ),
        Positioned(
          top: middleTop,
          bottom: middleBottom,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: messageHeight,
                  child: Center(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: (view.width * .024).clamp(17.0, 25.0),
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        shadows: const [
                          Shadow(
                            color: TudloColors.ink,
                            offset: Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onPrimary,
                  child: SizedBox(
                    width: stickerWidth,
                    height: stickerHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: stickerWidth * .17,
                              vertical: stickerHeight * .05,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: const Color(
                                  0xFFFFD94A,
                                ).withValues(alpha: .12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD33D,
                                    ).withValues(alpha: .74),
                                    blurRadius: 42,
                                    spreadRadius: 12,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: .32),
                                    blurRadius: 22,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: stickerWidth,
                          height: stickerHeight,
                          child: _GradeThreeRewardSticker(asset: stickerAsset),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: view.width * .08,
          right: view.width * .08,
          bottom: buttonBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasSecondary) ...[
                Flexible(
                  child: _GradeThreeRewardButton(
                    label: secondaryLabel!,
                    onTap: onSecondary!,
                    filled: false,
                  ),
                ),
                SizedBox(width: view.width * .02),
              ],
              Flexible(
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

class _GradeThreeRewardSticker extends StatelessWidget {
  final String asset;

  const _GradeThreeRewardSticker({required this.asset});

  String? get _pngFallback {
    final name = asset.split('/').last;
    final match = RegExp(r'^(.+)-home-sticker\.svg$').firstMatch(name);
    if (match == null) return null;
    return 'assets/images/home_sticker_${match.group(1)}.png';
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _pngFallback;
    if (fallback != null) {
      return Image.asset(
        fallback,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            SvgPicture.asset(asset, fit: BoxFit.contain),
      );
    }
    return SvgPicture.asset(asset, fit: BoxFit.contain);
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: (view.width * .18).clamp(135.0, 190.0),
          maxWidth: (view.width * .28).clamp(185.0, 270.0),
        ),
        child: Container(
          height: (view.height * .075).clamp(36.0, 46.0),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: filled ? green : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: green, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
              fontSize: (view.width * .014).clamp(13.0, 18.0),
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
