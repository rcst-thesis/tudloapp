import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/me/presentation/screens/daily_checkin_screen.dart';
import 'package:tudloapp/features/me/presentation/screens/daily_streak_screen.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

/// Chains [DailyCheckInScreen] into [DailyStreakScreen] for the currently
/// signed-in learner, then hands off to [onFinished].
///
/// Callers (Main Menu's "continue", Load's "load a save") are responsible
/// for only routing here when [LearnerProfile.needsStreakCheckInToday] is
/// true and for calling [LearnerController.recordStreakCheckIn] before
/// pushing this -- this widget just renders the two screens back to back,
/// it doesn't own the once-per-day gate itself.
///
/// [TudloAudioAssets.dailyStreakVoiceOver] loops for as long as this widget
/// is mounted (background music is already silent here -- see the
/// "continue"/"load" call sites -- and only resumes once Home mounts) and
/// stops the instant it's disposed, whichever screen that happens on.
class DailyStreakFlow extends StatefulWidget {
  const DailyStreakFlow({required this.onFinished, super.key});

  /// Called once the learner taps through both screens, with this widget's
  /// own (still-mounted) [BuildContext] -- not whatever context the caller
  /// pushed this from, which is long gone by the time a learner actually
  /// finishes clicking through. The caller decides how to navigate onward
  /// (a plain replace vs. clearing the whole stack differs between the
  /// "continue" and "load" call sites).
  final void Function(BuildContext context) onFinished;

  @override
  State<DailyStreakFlow> createState() => _DailyStreakFlowState();
}

class _DailyStreakFlowState extends State<DailyStreakFlow> {
  var _showingStreak = false;
  TudloAudioController? _audio;
  var _voiceOverLoopStarted = false;
  var _disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    audio.preloadVoiceOver(TudloAudioAssets.dailyStreakVoiceOver);
    if (!_voiceOverLoopStarted) {
      _voiceOverLoopStarted = true;
      unawaited(_loopVoiceOver(audio));
    }
  }

  // playVoiceOverAndWait only resolves once a clip naturally ends or is
  // cancelled (see TudloAudioController) -- looping is just re-starting it
  // each time that happens, until this widget goes away.
  //
  // Guarded with a minimum per-iteration wait: if playback can't actually
  // start (missing/failed asset, no audio backend available, a disposed
  // controller), playVoiceOverAndWait can resolve near-instantly, and
  // without this guard the loop would spin the event loop with no yield
  // point instead of just quietly doing nothing.
  static const _minLoopInterval = Duration(milliseconds: 250);

  Future<void> _loopVoiceOver(TudloAudioController audio) async {
    while (!_disposed) {
      await Future.wait([
        audio.playVoiceOverAndWait(TudloAudioAssets.dailyStreakVoiceOver),
        Future<void>.delayed(_minLoopInterval),
      ]);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_audio?.stopVoiceOver(TudloAudioAssets.dailyStreakVoiceOver));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = LearnerScope.of(context).profile;
    if (profile == null) {
      // Shouldn't happen -- both call sites switch to a profile before
      // pushing this -- but fail open onto the normal path rather than
      // show a broken screen if it ever does.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished(context);
      });
      return const SizedBox.shrink();
    }

    if (!_showingStreak) {
      return DailyCheckInScreen(
        createdAt: profile.createdAt,
        onStart: () => setState(() => _showingStreak = true),
      );
    }

    return DailyStreakScreen(
      streakCount: profile.effectiveStreak(),
      onContinue: () => widget.onFinished(context),
    );
  }
}
