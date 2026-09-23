import 'package:flutter/material.dart';

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/rive_long_button.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

enum OnboardingPrimaryButtonStyle { green, white }

class OnboardingBottomActions extends StatelessWidget {
  const OnboardingBottomActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    required this.primaryKey,
    required this.secondaryKey,
    this.primaryStyle = OnboardingPrimaryButtonStyle.green,
    this.primaryEnabled = true,
    super.key,
  });

  static const width = 352.295;
  static const height = 94.0;

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final Key primaryKey;
  final Key secondaryKey;
  final OnboardingPrimaryButtonStyle primaryStyle;

  /// When false the primary action is shown dimmed and ignores taps -- for a
  /// destination that is not built yet.
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    final white = primaryStyle == OnboardingPrimaryButtonStyle.white;
    final frontColor = Colors.white;
    final depthColor = const Color(0xFFB8C3AF);
    final foregroundColor = Colors.black;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          SizedBox(
            key: primaryKey,
            width: width,
            height: RiveLongButton.height,
            child: IgnorePointer(
              ignoring: !primaryEnabled,
              child: Opacity(
                opacity: primaryEnabled ? 1 : .45,
                child: white
                    ? StickerPressButton(
                        label: primaryLabel,
                        onPressed: onPrimaryPressed,
                        frontColor: frontColor,
                        depthColor: depthColor,
                        labelColor: foregroundColor,
                        height: 44,
                        fontSize: 15,
                      )
                    : RiveLongButton(
                        label: primaryLabel,
                        onPressed: onPrimaryPressed,
                      ),
              ),
            ),
          ),
          Positioned(
            left: (width - 120) / 2,
            top: 50,
            width: 120,
            height: 44,
            child: TextButton(
              key: secondaryKey,
              onPressed: () {
                TudloAudioScope.maybeOf(context)?.playButtonTapSound();
                onSecondaryPressed();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xB3000000),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.2,
                ),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
