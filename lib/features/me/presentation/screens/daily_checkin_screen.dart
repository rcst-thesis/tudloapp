import 'package:flutter/material.dart';

import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

/// The "day streak" flow's first screen: a solid-blue welcome-back card
/// with today's day-of-week illustration, shown before
/// [DailyStreakScreen] (the sun-rays celebration).
///
/// Standalone for now -- not yet wired to a real trigger, same as
/// [DailyStreakScreen].
class DailyCheckInScreen extends StatelessWidget {
  const DailyCheckInScreen({required this.createdAt, this.onStart, super.key});

  /// When this learner's profile was created -- "day N" counts up from
  /// there (day 1 on the creation day itself), e.g. a profile created a
  /// week ago reads "day 7" today. Independent of the "happy {weekday}!"
  /// heading below it, which is just today's real calendar day name.
  final DateTime createdAt;

  /// Defaults to just popping the screen when no caller-specific action is
  /// supplied.
  final VoidCallback? onStart;

  static const _backgroundColor = Color(0xFF1A9FE2);
  static const _boltColor = Color(0xFFFDB44E);

  static const _dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 (Mon) .. 7 (Sun)
    final dayName = _dayNames[weekday - 1];

    // Age in days since the profile was created, 1-based (day 1 = creation
    // day). Compared by calendar date only, not elapsed hours, so it ticks
    // over at midnight rather than 24-hour boundaries from signup time.
    final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final dayNumber = today.difference(created).inDays + 1;
    // Only 7 character illustrations exist, so they cycle through in step
    // with the day count rather than repeating "Day 1" forever past a week.
    final artDay = ((dayNumber - 1) % 7) + 1;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 26),
            Text(
              'day $dayNumber',
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'happy $dayName!',
              key: const Key('daily-checkin-heading'),
              style: const TextStyle(
                fontFamily: 'ComicRelief',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 58),
              // Capped so a wide (tablet-portrait) screen can't blow the
              // square card past the available vertical space.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/daily_checkin_day$artDay.png',
                          key: const Key('daily-checkin-day-image'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 3),
            const Icon(Icons.bolt_rounded, color: _boltColor, size: 42),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'koka fully recovered umpisahan ang bag o nga adlaw '
                'kaupod si koka',
                key: Key('daily-checkin-message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(flex: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  // Same footprint/style as the sun-rays daily-streak
                  // screen's own CTA -- both belong to the same flow.
                  constraints: const BoxConstraints(maxWidth: 352.295),
                  child: SizedBox(
                    width: double.infinity,
                    child: StickerPressButton(
                      key: const Key('daily-checkin-start-button'),
                      label: 'sugudan ta',
                      onPressed:
                          onStart ?? () => Navigator.of(context).maybePop(),
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
      ),
    );
  }
}
