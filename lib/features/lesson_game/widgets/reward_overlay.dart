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
    final stickerSize = (view.height * .42).clamp(150.0, 215.0).toDouble();
    final glowSize = stickerSize * 1.45;
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
                    width: stickerSize,
                    height: stickerSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
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
                      child: SvgPicture.asset(
                        stickerAsset,
                        fit: BoxFit.contain,
                      ),
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
