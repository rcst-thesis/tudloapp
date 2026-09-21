import 'package:flutter/material.dart';

import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/shared/widgets/rive_back_button.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

class AdaptiveBackButtonPlacement extends StatelessWidget {
  const AdaptiveBackButtonPlacement({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = constraints.maxWidth / 412;
        final heightScale = constraints.maxHeight / 917;
        final scale = widthScale < heightScale ? widthScale : heightScale;
        final left = (constraints.maxWidth * 27 / 412).clamp(16.0, 32.0);
        final top = (constraints.maxHeight * 51 / 917).clamp(16.0, 32.0);

        return Padding(
          padding: EdgeInsets.only(left: left, top: top),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 93 * scale,
              height: 44 * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: LoadBackButton(onPressed: onPressed),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadBackButton extends StatelessWidget {
  const LoadBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RiveBackButton(
      key: const Key('load-back-button'),
      onPressed: onPressed,
    );
  }
}

class DesignNavigationButton extends StatelessWidget {
  const DesignNavigationButton({
    this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 93,
      height: 44,
      child: StickerPressButton(
        onPressed: onPressed ?? () {},
        enabled: enabled && onPressed != null,
        frontColor: AppColors.green,
        depthColor: AppColors.darkGreen,
        restLift: 4.3732,
        fontSize: 15,
        child: icon != null
            ? const SizedBox(
                width: 93,
                height: 39.6269,
                child: CustomPaint(painter: _BackArrowPainter()),
              )
            : Text(
                label!,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFBFB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(43.125, 12.625)
      ..lineTo(37.5, 18.25)
      ..lineTo(43.125, 23.875)
      ..moveTo(37.5, 18.25)
      ..lineTo(49.5, 18.25)
      ..cubicTo(52.814, 18.25, 55.5, 20.936, 55.5, 24.25)
      ..lineTo(55.5, 27.25);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackArrowPainter oldDelegate) => false;
}
