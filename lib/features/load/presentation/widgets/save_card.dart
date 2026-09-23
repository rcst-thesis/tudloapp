import 'package:flutter/material.dart';

import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/shared/widgets/rive_avatar.dart';
import 'package:tudloapp/shared/widgets/rive_avatar_background.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

class SaveCard extends StatelessWidget {
  const SaveCard({
    required this.name,
    required this.previewShadowColor,
    required this.grade,
    required this.avatarId,
    required this.onLoad,
    this.onDelete,
    super.key,
  });

  final String name;
  final Color previewShadowColor;
  final int grade;
  final String avatarId;
  final VoidCallback onLoad;

  /// `null` hides the delete button entirely -- used for the fixed demo
  /// card, which has nothing on disk to delete.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(10));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A solid offset layer matches the reference better than a blur.
        const Positioned(
          left: 2,
          top: 5,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF75D548),
              borderRadius: radius,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 2,
          bottom: 5,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF98EF6F),
              borderRadius: radius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          top: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: previewShadowColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          bottom: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                RiveAvatarBackground(grade: grade),
                                // Same scale-up treatment as the Me
                                // screen's avatar boxes -- `RiveAvatar`'s
                                // own `Fit.contain` otherwise reads small
                                // in a box this size.
                                Transform.scale(
                                  scale: 1.5,
                                  child: RiveAvatar(artboardId: avatarId),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SaveCardButton(label: 'load', onPressed: onLoad),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SaveCardButton(
                            label: 'delete',
                            onPressed: onDelete!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SaveCardButton extends StatelessWidget {
  const SaveCardButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StickerPressButton(
      label: label,
      onPressed: onPressed,
      frontColor: AppColors.green,
      depthColor: AppColors.darkGreen,
      height: 38,
      borderRadius: 7,
      fontSize: 12,
    );
  }
}
