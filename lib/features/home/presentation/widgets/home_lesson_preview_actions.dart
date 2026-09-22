/// The action row of the Home lesson preview: one button per lesson action,
/// and the notice shown in place of them when an action is unavailable.
library;

import 'package:flutter/material.dart';

import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

class ActionUnavailableNotice extends StatelessWidget {
  const ActionUnavailableNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Color(0xFF151515),
          ),
        ),
      ),
    );
  }
}

class LessonPreviewAction extends StatelessWidget {
  const LessonPreviewAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    this.width,
    this.emoji,
    this.emojiScale = .72,
    this.emojiOffset = Offset.zero,
    required this.showSurface,
    required this.verticalOffset,
    required this.onTap,
    this.enabled = true,
    this.buttonKey,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final double? width;
  final String? emoji;
  final double emojiScale;
  final Offset emojiOffset;
  final bool showSurface;
  final double verticalOffset;
  final VoidCallback onTap;

  /// Key on the actual tappable surface, not this wrapper -- the wrapper's
  /// own bounds also cover the label text below it, which isn't hittable.
  final Key? buttonKey;

  /// Purely visual (dims the icon/label) -- [onTap] still fires regardless,
  /// since a disabled action here (e.g. "retry" before a lesson's ever been
  /// finished) needs the tap to land in order to explain why it's
  /// unavailable, not swallow it silently.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: width ?? size,
      height: size,
      child: emoji == null
          ? Icon(icon, color: color, size: size * .53)
          : Center(
              child: Transform.translate(
                offset: emojiOffset,
                child: Text(
                  emoji!,
                  style: TextStyle(
                    color: showSurface ? color : null,
                    fontSize: size * emojiScale,
                    height: 1,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
              ),
            ),
    );

    return SizedBox(
      width: 66,
      child: Transform.translate(
        offset: Offset(0, verticalOffset),
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: Column(
            children: [
              SizedBox(
                width: width ?? size,
                height: size,
                // "suguran ta" (start) is the one real call-to-action here
                // -- gets the app's standard physical press-down effect.
                // Retry/do-it-later are lighter emoji taps, not CTAs.
                child: showSurface
                    ? StickerPressButton(
                        key: buttonKey,
                        onPressed: onTap,
                        frontColor: Colors.white,
                        depthColor: const Color(0xFFB7B7B7),
                        borderRadius: 15,
                        restLift: 4,
                        child: content,
                      )
                    : Material(
                        key: buttonKey,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        child: InkResponse(
                          onTap: onTap,
                          radius: size / 2,
                          child: content,
                        ),
                      ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ComicRelief',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
