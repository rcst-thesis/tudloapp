import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/features/onboarding/presentation/widgets/onboarding_koka_greeting.dart';
import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

/// Full-screen daily-streak celebration: waving Koka over a slowly
/// rotating two-tone sun-ray backdrop (same technique as the onboarding
/// learner card's rays), centered on Koka rather than the screen, the
/// current streak count, and a CTA to continue.
///
/// Standalone for now -- not yet wired to a real trigger (e.g. "shown after
/// a lesson completion that extends the streak"). [streakCount] is the only
/// thing callers need to supply; everything else has sensible defaults.
class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({
    required this.streakCount,
    this.message =
        'wow good job abyan! buksi ang app adlaw-adlaw para imo ma '
        'maintain ang imo streak',
    this.onContinue,
    super.key,
  });

  final int streakCount;
  final String message;

  /// Defaults to just popping the screen when no caller-specific action is
  /// supplied.
  final VoidCallback? onContinue;

  static const _rayColorA = Color(0xFF0E9BE2);
  static const _rayColorB = Color(0xFF1A9FE2);
  static const _mascotSize = 120.0;

  @override
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen> {
  final _stackKey = GlobalKey();
  final _mascotKey = GlobalKey();
  Offset? _raysCenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureRaysCenter());
  }

  // The rays' vertex/pivot needs Koka's actual on-screen center, not the
  // Stack's geometric center -- Koka isn't vertically centered in the
  // layout (the streak count/message/button sit below it), so those two
  // points differ. Measured once after first layout rather than computed
  // from the Spacer flex math, so it stays correct even if the surrounding
  // layout changes later.
  void _measureRaysCenter() {
    final mascotBox = _mascotKey.currentContext?.findRenderObject();
    final stackBox = _stackKey.currentContext?.findRenderObject();
    if (mascotBox is! RenderBox ||
        stackBox is! RenderBox ||
        !mascotBox.attached ||
        !stackBox.attached) {
      return;
    }
    final centerInStack = stackBox.globalToLocal(
      mascotBox.localToGlobal(mascotBox.size.center(Offset.zero)),
    );
    if (!mounted || centerInStack == _raysCenter) return;
    setState(() => _raysCenter = centerInStack);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyStreakScreen._rayColorB,
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          children: [
            Positioned.fill(child: _StreakRays(center: _raysCenter)),
            Column(
              children: [
                const Spacer(flex: 6),
                SizedBox(
                  key: _mascotKey,
                  width: DailyStreakScreen._mascotSize,
                  height: DailyStreakScreen._mascotSize,
                  // Loops the "Hi" wave continuously (same widget the Name
                  // screen uses) instead of a single one-shot wave.
                  child: const OnboardingKokaGreeting(),
                ),
                const SizedBox(height: 18),
                Text(
                  '${widget.streakCount}',
                  key: const Key('daily-streak-count'),
                  style: const TextStyle(
                    fontFamily: 'ComicRelief',
                    fontWeight: FontWeight.w800,
                    fontSize: 56,
                    color: Colors.white,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'day streak',
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _WeekStreakIndicator(
                    key: const Key('daily-streak-week-indicator'),
                    streakCount: widget.streakCount,
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.message,
                    key: const Key('daily-streak-message'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ComicRelief',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      // Same footprint as the welcome-aboard screen's long
                      // button (OnboardingBottomActions/RiveLongButton).
                      constraints: const BoxConstraints(maxWidth: 352.295),
                      child: SizedBox(
                        width: double.infinity,
                        child: StickerPressButton(
                          key: const Key('daily-streak-continue-button'),
                          label: 'Lets goooooooo!',
                          onPressed:
                              widget.onContinue ??
                              () => Navigator.of(context).maybePop(),
                          frontColor: Colors.white,
                          depthColor: const Color(0xFFCFCFCF),
                          labelColor: const Color(0xFF1A1A1A),
                          height: 40,
                          borderRadius: 12,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The week-at-a-glance pill: one circle per weekday (Mon first). The
/// trailing [streakCount] of them (ending today, an unbroken run) merge
/// into a single connected white capsule -- not separate circles each with
/// their own check -- with just one checkmark, on today. Everything else
/// stays a plain dark circle.
class _WeekStreakIndicator extends StatelessWidget {
  const _WeekStreakIndicator({required this.streakCount, super.key});

  final int streakCount;

  static const _labels = ['m', 't', 'w', 't', 'f', 's', 's'];
  static const _pillColor = Color(0xFF1591D3);
  static const _dayColor = Color(0xFF0D5A8C);
  static const _circleSize = 26.0;

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1; // 0 (Mon) .. 6 (Sun)
    final doneCount = streakCount.clamp(0, _labels.length);
    final doneIndices = {
      for (var i = 0; i < doneCount; i++) (todayIndex - i) % 7,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                for (final label in _labels)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'ComicRelief',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                for (var i = 0; i < _labels.length; i++)
                  Expanded(
                    child: _DayCell(
                      isDone: doneIndices.contains(i),
                      // Row order only -- a run that wraps past Sunday back
                      // to Monday isn't visually adjacent in this layout,
                      // so it isn't treated as connected here either.
                      connectsToPrev: i > 0 && doneIndices.contains(i - 1),
                      connectsToNext:
                          i < _labels.length - 1 && doneIndices.contains(i + 1),
                      isToday: i == todayIndex,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.isDone,
    required this.connectsToPrev,
    required this.connectsToNext,
    required this.isToday,
  });

  final bool isDone;
  final bool connectsToPrev;
  final bool connectsToNext;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    const circleSize = _WeekStreakIndicator._circleSize;
    // A custom-painted mark instead of Icons.check_rounded -- that glyph's
    // own visual weight sits off-center within its bounding box, which read
    // as an offset checkmark no matter how it was aligned/padded.
    final check = isToday
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(
              painter: _CheckMarkPainter(
                color: _WeekStreakIndicator._pillColor,
              ),
            ),
          )
        : null;

    if (!isDone) {
      return Center(
        child: Container(
          width: circleSize,
          height: circleSize,
          decoration: const BoxDecoration(
            color: _WeekStreakIndicator._dayColor,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // A done day with no connected neighbor either side is just its own
    // circle, same footprint as a plain day.
    if (!connectsToPrev && !connectsToNext) {
      return Center(
        child: Container(
          width: circleSize,
          height: circleSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: check,
        ),
      );
    }

    // Part of an unbroken run -- stretch across the whole slot and only
    // round the outer edge, so it visually joins with its connected
    // neighbor(s) into one continuous capsule.
    const gap = 3.0;
    return Padding(
      padding: EdgeInsets.only(
        left: connectsToPrev ? 0 : gap,
        right: connectsToNext ? 0 : gap,
      ),
      child: Container(
        height: circleSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(
            left: connectsToPrev
                ? Radius.zero
                : const Radius.circular(circleSize / 2),
            right: connectsToNext
                ? Radius.zero
                : const Radius.circular(circleSize / 2),
          ),
        ),
        child: check,
      ),
    );
  }
}

/// A checkmark drawn to exactly fill and center within [size] -- two
/// strokes meeting at a low-left vertex, sized/positioned as fractions of
/// the canvas rather than a font glyph with its own baked-in offset.
class _CheckMarkPainter extends CustomPainter {
  const _CheckMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.86, size.height * 0.26);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StreakRaysPainter extends CustomPainter {
  const _StreakRaysPainter({required this.center, required this.angle});

  /// Null until the first post-frame measurement lands, in which case this
  /// falls back to the canvas's own geometric center for that one frame.
  final Offset? center;
  final double angle;

  static const _colorA = DailyStreakScreen._rayColorA;
  static const _colorB = DailyStreakScreen._rayColorB;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = center ?? size.center(Offset.zero);
    // Long enough that a full rotation never exposes bare background at the
    // corners, on any phone/tablet size, from any origin within the canvas.
    final radius = size.longestSide * 2;
    const rays = 24;
    const twoPi = 6.283185307179586;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    for (var index = 0; index < rays; index++) {
      final start = index * twoPi / rays;
      final end = (index + 1) * twoPi / rays;
      final paint = Paint()..color = index.isEven ? _colorA : _colorB;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(radius * math.cos(start), radius * math.sin(start))
          ..lineTo(radius * math.cos(end), radius * math.sin(end))
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StreakRaysPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.angle != angle;
}

class _StreakRays extends StatefulWidget {
  const _StreakRays({required this.center});

  final Offset? center;

  @override
  State<_StreakRays> createState() => _StreakRaysState();
}

class _StreakRaysState extends State<_StreakRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = !effectiveAmbientMotionEnabled(context);
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('daily-streak-rotating-rays'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _StreakRaysPainter(
            center: widget.center,
            angle: _controller.value * math.pi * 2,
          ),
        ),
      ),
    );
  }
}
