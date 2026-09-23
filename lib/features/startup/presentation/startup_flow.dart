import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/features/main_menu/presentation/main_menu_screen.dart';
import 'package:tudloapp/features/me/presentation/screens/daily_checkin_screen.dart';
import 'package:tudloapp/features/me/presentation/screens/daily_streak_screen.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

class StartupFlow extends StatefulWidget {
  const StartupFlow({
    this.splashDuration = const Duration(seconds: 5),
    this.splashWarmup,
    this.assetWarmup,
    this.logoAudioDelay = Duration.zero,
    this.logoAudioPlayer,
    this.backgroundMusicPlayer,
    this.debugShowDailyStreakFirst = false,
    super.key,
  });

  final Duration splashDuration;
  final Future<void> Function()? splashWarmup;
  final Future<void> Function()? assetWarmup;

  /// TEMP DEBUG: when true, shows the new day-streak flow (check-in screen,
  /// then the sun-rays celebration) right after boot, before Main Menu --
  /// quick to check on an emulator without wiring a real trigger yet.
  /// Defaults to false (existing behavior) so this never affects the app
  /// unless a call site opts in; `main.dart` is the only place that
  /// currently does, and only for this debugging pass.
  final bool debugShowDailyStreakFirst;

  /// How long after the rendered Maral logo the sting plays. It defaults to
  /// zero so the Stage 0 visual and audio arrive together.
  final Duration logoAudioDelay;

  /// Overridable for tests, same convention as [splashWarmup]/
  /// [assetWarmup] -- defaults to the app-owned audio controller's Maral
  /// splash-sting channel.
  final Future<void> Function()? logoAudioPlayer;

  /// Overridable for tests, same convention as [logoAudioPlayer] -- defaults
  /// to starting the audio controller's background loop when the Maral splash
  /// ends (see [_StartupFlowState._runStartup]'s stage 0 -> 1 transition).
  final Future<void> Function()? backgroundMusicPlayer;

  @override
  State<StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<StartupFlow> {
  int _stage = 0;
  bool _running = false;
  Object? _startupError;
  bool _debugCheckInDismissed = false;
  bool _debugStreakDismissed = false;

  Timer? _logoAudioTimer;
  TudloAudioController? _audio;
  var _logoAudioScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_runStartup());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    // Both startup tracks now belong to the app-level controller; this screen
    // preserves only their timing, not native audio resources.
    audio.preloadStartupAudio();
  }

  Future<void> _playLogoAudio() async {
    if (!mounted || _stage != 0) return;
    try {
      await (widget.logoAudioPlayer ?? _playDefaultLogoAudio)();
    } catch (_) {
      // Best-effort: a missing/unsupported audio backend (e.g. no native
      // SoLoud library registered in a widget test) shouldn't block or
      // crash the splash sequence over a sound effect.
    }
  }

  /// Starts the sting clock only after Flutter has painted the Maral logo.
  ///
  /// Starting it from [initState] races image decoding on a cold launch: the
  /// audio cue can finish before the user ever sees the logo. The guard
  /// also prevents later image frames/rebuilds from creating duplicate cues.
  void _scheduleLogoAudioAfterMaralLogoPaints() {
    if (!mounted || _stage != 0 || _logoAudioScheduled) return;
    _logoAudioScheduled = true;
    _logoAudioTimer = Timer(widget.logoAudioDelay, _playLogoAudio);
  }

  Future<void> _playDefaultLogoAudio() async {
    await (_audio?.playSplashSting() ?? Future<void>.value());
  }

  /// Fires once, right after the Maral splash ends (see [_runStartup]'s
  /// stage 0 -> 1 transition) -- "starts right after the Maral logo
  /// splash" per the feature request. The scoped controller owns the native
  /// loop, settings reconciliation, and later route-driven restarts.
  Future<void> _startBackgroundMusic() async {
    if (!mounted) return;
    try {
      await (widget.backgroundMusicPlayer ??
          () => _audio?.startBackgroundMusic() ?? Future<void>.value())();
    } catch (_) {
      // Best-effort: a missing/unsupported audio backend shouldn't block
      // or crash startup over background music.
    }
  }

  Future<void> _runStartup() async {
    if (_running) return;
    _running = true;
    try {
      // Maral remains visible for the full minimum duration while the next
      // splash is decoded into Flutter's image cache.
      await Future.wait<void>([
        Future<void>.delayed(widget.splashDuration),
        widget.splashWarmup?.call() ??
            precacheImage(
              const AssetImage('assets/images/loading_logo.png'),
              context,
            ),
      ]);
      if (!mounted) return;
      _logoAudioTimer?.cancel();
      setState(() => _stage = 1);
      unawaited(_startBackgroundMusic());

      // Tudlo remains visible for at least five seconds. It stays on screen
      // longer when the Main Menu's immediate artwork is not ready yet.
      final minimumDisplay = Future<void>.delayed(widget.splashDuration);
      final assetWarmup = widget.assetWarmup?.call() ?? _precacheMenuAssets();
      await Future.wait<void>([minimumDisplay, assetWarmup]);
      if (!mounted) return;
      setState(() => _stage = 2);
    } catch (error) {
      if (!mounted) return;
      setState(() => _startupError = error);
    } finally {
      _running = false;
    }
  }

  Future<void> _precacheMenuAssets() async {
    // Later screens own their load boundaries; do not retain onboarding art
    // at app launch when the Main Menu is the only immediate destination.
    const assets = <String>[
      'assets/images/onboarding_footer.png',
      'assets/images/onboarding_logo.png',
    ];
    await Future.wait<void>(
      assets.map((asset) => precacheImage(AssetImage(asset), context)),
    );
  }

  @override
  void dispose() {
    _logoAudioTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return ColoredBox(
        color: AppColors.mint,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('wala natapos ang paghanda'),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                height: 44,
                child: StickerPressButton(
                  label: 'try liwat',
                  onPressed: () {
                    setState(() {
                      _stage = 0;
                      _startupError = null;
                    });
                    unawaited(_runStartup());
                  },
                  frontColor: AppColors.green,
                  depthColor: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: switch (_stage) {
        0 => SplashImage(
          key: const ValueKey('maral'),
          asset: 'assets/images/maral_loading_logo.png',
          backgroundColor: AppColors.charcoal,
          semanticLabel: 'Maral MT splash screen',
          designWidth: 224,
          maximumWidth: 280,
          onFirstImageFrame: _scheduleLogoAudioAfterMaralLogoPaints,
        ),
        1 => const SplashImage(
          key: ValueKey('tudlo'),
          asset: 'assets/images/loading_logo.png',
          backgroundColor: AppColors.mint,
          semanticLabel: 'Tudlo splash screen',
          designWidth: 116,
        ),
        _ when widget.debugShowDailyStreakFirst && !_debugCheckInDismissed =>
          DailyCheckInScreen(
            key: const ValueKey('daily-checkin-debug'),
            // No real learner profile exists yet this early in boot -- a
            // week-old placeholder date just previews "day 7" here; the
            // real trigger will pass the actual profile's createdAt.
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
            onStart: () => setState(() => _debugCheckInDismissed = true),
          ),
        _ when widget.debugShowDailyStreakFirst && !_debugStreakDismissed =>
          DailyStreakScreen(
            key: const ValueKey('daily-streak-debug'),
            streakCount: 1,
            onContinue: () => setState(() => _debugStreakDismissed = true),
          ),
        _ => const MainMenuScreen(key: ValueKey('menu')),
      },
    );
  }
}

class SplashImage extends StatelessWidget {
  const SplashImage({
    required this.asset,
    required this.backgroundColor,
    required this.semanticLabel,
    this.designWidth,
    this.maximumWidth = 160,
    this.onFirstImageFrame,
    super.key,
  });

  final String asset;
  final Color backgroundColor;
  final String semanticLabel;
  final double? designWidth;
  final double maximumWidth;
  final VoidCallback? onFirstImageFrame;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = designWidth == null
              ? constraints.maxWidth
              : (constraints.maxWidth * designWidth! / 412).clamp(
                  92.0,
                  maximumWidth,
                );
          return Center(
            child: SizedBox(
              width: targetWidth,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: semanticLabel,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => onFirstImageFrame?.call(),
                    );
                  }
                  return child;
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
