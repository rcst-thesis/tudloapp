import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

Future<void> showHomeLessonPreviewDialog({
  required BuildContext context,
  required HomeLessonPreview lesson,
  required Rect originRect,
  required VoidCallback onRetry,
  required VoidCallback onStart,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close lesson preview',
    barrierColor: const Color(0xCC000000),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, _, __) => SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: _HomeLessonPreviewDialog(
                lesson: lesson,
                originRect: originRect,
                onRetry: onRetry,
                onStart: onStart,
              ),
            ),
          ),
        ],
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: _HomeLessonPreviewDialogState._settleCurve,
      );
      return FadeTransition(opacity: curve, child: child);
    },
  );
}

class _HomeLessonPreviewDialog extends StatefulWidget {
  const _HomeLessonPreviewDialog({
    required this.lesson,
    required this.originRect,
    required this.onRetry,
    required this.onStart,
  });

  final HomeLessonPreview lesson;
  final Rect originRect;
  final VoidCallback onRetry;
  final VoidCallback onStart;

  @override
  State<_HomeLessonPreviewDialog> createState() =>
      _HomeLessonPreviewDialogState();
}

class _HomeLessonPreviewDialogState extends State<_HomeLessonPreviewDialog> {
  static const _settleCurve = Cubic(0.22, 0.82, 0.28, 1);
  static const _cardExpansionDuration = Duration(milliseconds: 380);
  static const _actionRevealDelay = Duration(milliseconds: 160);
  static const _actionRevealDuration = Duration(milliseconds: 180);
  static const _retryNoticeDuration = Duration(milliseconds: 1800);

  final _cardKey = GlobalKey();
  bool _cardIsOpen = false;
  bool _actionsAreVisible = false;
  bool _showRetryNotice = false;
  Timer? _retryNoticeTimer;
  Offset _launchTravel = Offset.zero;
  double _launchScaleX = .9;
  double _launchScaleY = .55;

  /// Retry only makes sense for a lesson you've already finished once --
  /// otherwise there's nothing to retry yet, same reasoning "suguran ta"
  /// (start) exists for.
  bool get _retryAvailable =>
      widget.lesson.status == HomeLessonStatus.completed;

  void _handleRetryTap() {
    if (_retryAvailable) {
      widget.onRetry();
      return;
    }
    _retryNoticeTimer?.cancel();
    setState(() => _showRetryNotice = true);
    _retryNoticeTimer = Timer(_retryNoticeDuration, () {
      if (mounted) setState(() => _showRetryNotice = false);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cardBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
      if (!mounted || cardBox == null) return;
      final cardRect = cardBox.localToGlobal(Offset.zero) & cardBox.size;
      setState(() {
        _launchTravel = widget.originRect.center - cardRect.center;
        // Start as the actual tapped card: nearly its full width, but much
        // shorter. The card then grows vertically while it travels to the
        // preview position, instead of looking like a separate modal popping
        // into view.
        _launchScaleX = (widget.originRect.width / cardRect.width)
            .clamp(.72, 1.18)
            .toDouble();
        _launchScaleY = (widget.originRect.height / cardRect.height)
            .clamp(.38, .78)
            .toDouble();
        _cardIsOpen = true;
      });
      await Future<void>.delayed(_actionRevealDelay);
      if (mounted) setState(() => _actionsAreVisible = true);
    });
  }

  @override
  void dispose() {
    _retryNoticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = (screenWidth - 80).clamp(260.0, 320.0).toDouble();
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: _cardExpansionDuration,
                  curve: _settleCurve,
                  tween: Tween<double>(begin: 0, end: _cardIsOpen ? 1 : 0),
                  child: DecoratedBox(
                    key: _cardKey,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 9),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 124,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 8, 12, 9),
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '10',
                                    style: TextStyle(
                                      color: Color(0xFF6C7176),
                                      fontFamily: 'ComicRelief',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFFF6B917),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/home_lesson_category.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.lesson.unitTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF151515),
                                        fontFamily: 'ComicRelief',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'lesson mo subong nga adlaw',
                                      style: TextStyle(
                                        color: Color(0xFF55575A),
                                        fontFamily: 'ComicRelief',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  builder: (context, progress, child) {
                    final scaleX =
                        _launchScaleX + ((1 - _launchScaleX) * progress);
                    final scaleY =
                        _launchScaleY + ((1 - _launchScaleY) * progress);
                    return Transform.translate(
                      offset: _launchTravel * (1 - progress),
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: child,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AnimatedSlide(
                  duration: _actionRevealDuration,
                  curve: _settleCurve,
                  offset: _actionsAreVisible
                      ? Offset.zero
                      : const Offset(0, .12),
                  child: AnimatedOpacity(
                    duration: _actionRevealDuration,
                    opacity: _actionsAreVisible ? 1 : 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LessonPreviewAction(
                          buttonKey: const Key('lesson-preview-retry-button'),
                          icon: Icons.refresh_rounded,
                          label: 'retry',
                          color: const Color(0xFF55A7D0),
                          size: 44,
                          emoji: '🔄',
                          emojiScale: .64,
                          emojiOffset: const Offset(0, 1),
                          showSurface: false,
                          verticalOffset: 8,
                          enabled: _retryAvailable,
                          onTap: _handleRetryTap,
                        ),
                        _LessonPreviewAction(
                          buttonKey: const Key('lesson-preview-start-button'),
                          icon: Icons.play_arrow_rounded,
                          label: 'suguran ta',
                          color: const Color(0xFF68B84D),
                          size: 56,
                          width: 66,
                          emoji: '▶',
                          emojiScale: .48,
                          showSurface: true,
                          verticalOffset: 0,
                          onTap: widget.onStart,
                        ),
                        _LessonPreviewAction(
                          icon: Icons.schedule_rounded,
                          label: 'do it later',
                          color: const Color(0xFF8B5D2B),
                          size: 44,
                          emoji: '⏰',
                          emojiScale: .64,
                          emojiOffset: const Offset(0, 1),
                          showSurface: false,
                          verticalOffset: 8,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -46,
              child: IgnorePointer(
                ignoring: !_showRetryNotice,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: _settleCurve,
                  offset: _showRetryNotice ? Offset.zero : const Offset(0, .3),
                  child: AnimatedOpacity(
                    key: const Key('lesson-preview-retry-notice'),
                    duration: const Duration(milliseconds: 180),
                    opacity: _showRetryNotice ? 1 : 0,
                    child: const _RetryUnavailableNotice(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryUnavailableNotice extends StatelessWidget {
  const _RetryUnavailableNotice();

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
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Text(
          'wala pa natapos ang lesson',
          style: TextStyle(
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

class _LessonPreviewAction extends StatelessWidget {
  const _LessonPreviewAction({
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
