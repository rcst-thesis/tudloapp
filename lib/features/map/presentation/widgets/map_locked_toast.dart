import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a themed, self-dismissing toast near the bottom of the screen --
/// the Map's "still locked" tap feedback. Replaces a bare default
/// `SnackBar` (black bar, system font, square corners) with a card that
/// actually looks like it belongs in this app: white rounded card, flat
/// offset shadow (no blur), ComicRelief font -- the same "sticker" card
/// language used by `HomeLessonPreviewDialog` and the load-screen dialogs,
/// just simple enough for a one-line, no-buttons notice. Auto-dismisses on
/// its own; tapping it dismisses early.
void showMapLockedToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) =>
        _MapLockedToast(message: message, onDismissed: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _MapLockedToast extends StatefulWidget {
  const _MapLockedToast({required this.message, required this.onDismissed});

  final String message;
  final VoidCallback onDismissed;

  @override
  State<_MapLockedToast> createState() => _MapLockedToastState();
}

class _MapLockedToastState extends State<_MapLockedToast>
    with SingleTickerProviderStateMixin {
  static const _visibleDuration = Duration(milliseconds: 2200);
  static const _fadeDuration = Duration(milliseconds: 220);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _fadeDuration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  Timer? _dismissTimer;
  var _dismissing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward());
    _dismissTimer = Timer(_visibleDuration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomInset + 32,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: GestureDetector(
            onTap: _dismiss,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6B917),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              '🔒',
                              style: TextStyle(fontSize: 18, height: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              fontFamily: 'ComicRelief',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF151515),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
