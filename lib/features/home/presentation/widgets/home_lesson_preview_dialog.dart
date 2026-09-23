import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/features/home/presentation/widgets/home_lesson_card.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_preview_actions.dart';

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
  static const _unavailableNoticeDuration = Duration(milliseconds: 1800);
  static const _retryUnavailableMessage = 'wala pa natapos ang lesson';
  static const _startUnavailableMessage = 'tapusa anay ang una nga lesson';

  final _cardKey = GlobalKey();
  bool _cardIsOpen = false;
  bool _actionsAreVisible = false;
  bool _showUnavailableNotice = false;
  String _unavailableNoticeMessage = _retryUnavailableMessage;
  Timer? _unavailableNoticeTimer;
  Offset _launchTravel = Offset.zero;
  double _launchScaleX = .9;
  double _launchScaleY = .55;

  /// Retry only makes sense for a lesson you've already finished once --
  /// otherwise there's nothing to retry yet, same reasoning "suguran ta"
  /// (start) exists for.
  bool get _retryAvailable =>
      widget.lesson.status == HomeLessonStatus.completed;

  /// A locked lesson (its predecessor isn't finished/claimed yet) can't be
  /// started -- same as [_retryAvailable]'s reasoning, just for the other
  /// direction: nothing to retry vs. nothing to start yet.
  bool get _startAvailable => widget.lesson.status != HomeLessonStatus.locked;

  void _handleRetryTap() {
    if (_retryAvailable) {
      widget.onRetry();
      return;
    }
    _notifyUnavailable(_retryUnavailableMessage);
  }

  void _handleStartTap() {
    if (_startAvailable) {
      widget.onStart();
      return;
    }
    _notifyUnavailable(_startUnavailableMessage);
  }

  void _notifyUnavailable(String message) {
    _unavailableNoticeTimer?.cancel();
    setState(() {
      _unavailableNoticeMessage = message;
      _showUnavailableNotice = true;
    });
    _unavailableNoticeTimer = Timer(_unavailableNoticeDuration, () {
      if (mounted) setState(() => _showUnavailableNotice = false);
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
    _unavailableNoticeTimer?.cancel();
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
                                      categoryIconForUnit(
                                        widget.lesson.unitNumber,
                                      ),
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
                        LessonPreviewAction(
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
                        LessonPreviewAction(
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
                          enabled: _startAvailable,
                          onTap: _handleStartTap,
                        ),
                        LessonPreviewAction(
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
                ignoring: !_showUnavailableNotice,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: _settleCurve,
                  offset: _showUnavailableNotice
                      ? Offset.zero
                      : const Offset(0, .3),
                  child: AnimatedOpacity(
                    key: const Key('lesson-preview-action-unavailable-notice'),
                    duration: const Duration(milliseconds: 180),
                    opacity: _showUnavailableNotice ? 1 : 0,
                    child: ActionUnavailableNotice(
                      message: _unavailableNoticeMessage,
                    ),
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
