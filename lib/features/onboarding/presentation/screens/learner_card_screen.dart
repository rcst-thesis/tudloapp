import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/features/home/presentation/screens/home_loading_screen.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/onboarding/presentation/screens/name_screen.dart';
import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/onboarding_bottom_actions.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

class LearnerCardScreen extends StatefulWidget {
  const LearnerCardScreen({
    required this.learnerName,
    required this.grade,
    required this.energy,
    this.earnedBadgeCount = 0,
    this.onContinue,
    this.precacheWelcomeVectors,
    this.voiceOverPlayer,
    super.key,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final int earnedBadgeCount;
  final VoidCallback? onContinue;
  final Future<void> Function(BuildContext context)? precacheWelcomeVectors;
  final Future<void> Function()? voiceOverPlayer;

  @override
  State<LearnerCardScreen> createState() => _LearnerCardScreenState();
}

class _LearnerCardScreenState extends State<LearnerCardScreen> {
  TudloAudioController? _audio;
  var _initialVoiceOverScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    audio.preloadVoiceOver(TudloAudioAssets.learnerCardVoiceOver);
    if (_initialVoiceOverScheduled) return;
    _initialVoiceOverScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playVoiceOver());
    });
  }

  Future<void> _playVoiceOver() {
    return widget.voiceOverPlayer?.call() ??
        _audio?.playVoiceOver(TudloAudioAssets.learnerCardVoiceOver) ??
        Future<void>.value();
  }

  Future<void> _stopVoiceOver() {
    return _audio?.stopVoiceOver(TudloAudioAssets.learnerCardVoiceOver) ??
        Future<void>.value();
  }

  Color get _gradeColor => switch (widget.grade) {
    2 => const Color(0xFF3E75A6),
    3 => const Color(0xFFB04444),
    _ => AppColors.green,
  };

  String get _kokaAsset => switch (widget.grade) {
    2 => 'assets/images/koka_blue.png',
    3 => 'assets/images/koka_red.png',
    _ => 'assets/images/koka_green.png',
  };

  void _finish(BuildContext context) {
    unawaited(_stopVoiceOver());
    if (widget.onContinue case final callback?) {
      callback();
      return;
    }
    // Fire-and-forget: LearnerController updates its in-memory profile
    // synchronously before its own (best-effort) disk write, so screens
    // reading LearnerScope after this navigation already see it -- no need
    // to block leaving this screen on the save completing.
    unawaited(
      LearnerScope.of(context).createAndSave(
        name: widget.learnerName,
        grade: widget.grade,
        energy: widget.energy,
        initialSettings: AppSettingsScope.of(context).settings,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(
        page: HomeLoadingScreen(
          learnerName: widget.learnerName,
          grade: widget.grade,
          energy: widget.energy,
          precacheWelcomeVectors: widget.precacheWelcomeVectors,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reset learner confirmation',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _ResetLearnerDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );
    if (confirmed != true || !context.mounted) return;
    unawaited(_stopVoiceOver());
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(page: const NameScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    unawaited(_stopVoiceOver());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: const Color(0xFFD9FF79),
        child: SafeArea(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: const Key('learner-card-canvas'),
                width: 412,
                height: 917,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _RotatingRays()),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 102,
                      height: 86,
                      child: FractionallySizedBox(
                        widthFactor: 0.50,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/learner_card_earned.png',
                          key: const Key('learner-card-earned-heading'),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 219,
                      child: _InteractiveFloatingCard(
                        child: _LearnerCard(
                          learnerName: widget.learnerName,
                          grade: widget.grade,
                          energy: widget.energy,
                          earnedBadgeCount: widget.earnedBadgeCount,
                          gradeColor: _gradeColor,
                          kokaAsset: _kokaAsset,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 807,
                      child: OnboardingBottomActions(
                        primaryKey: const Key('learner-card-continue-button'),
                        secondaryKey: const Key('learner-card-reset-button'),
                        primaryLabel: 'hop. hop. hop. lets gooo',
                        secondaryLabel: 'reset',
                        onPrimaryPressed: () => _finish(context),
                        onSecondaryPressed: () => _reset(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveFloatingCard extends StatefulWidget {
  const _InteractiveFloatingCard({required this.child});

  final Widget child;

  @override
  State<_InteractiveFloatingCard> createState() =>
      _InteractiveFloatingCardState();
}

class _InteractiveFloatingCardState extends State<_InteractiveFloatingCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _tiltController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  double _targetTiltX = 0;
  double _targetTiltY = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = !effectiveAmbientMotionEnabled(context);
    if (_reduceMotion) {
      _floatController
        ..stop()
        ..value = 0;
      _tiltController
        ..stop()
        ..value = 0;
    } else if (!_floatController.isAnimating) {
      _floatController.repeat();
    }
  }

  void _tilt(Offset localPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final normalizedX = (localPosition.dx / box.size.width - 0.5).clamp(
      -0.5,
      0.5,
    );
    final normalizedY = (localPosition.dy / box.size.height - 0.5).clamp(
      -0.5,
      0.5,
    );
    // Rotate the touched edge away from the viewer so it feels pressed down.
    _targetTiltX = normalizedY * 0.12;
    _targetTiltY = -normalizedX * 0.16;
    _tiltController.forward(from: 0);
  }

  double get _tiltStrength {
    final value = _tiltController.value;
    if (value <= 0.24) {
      return Curves.easeOutCubic.transform(value / 0.24);
    }
    return 1 - Curves.elasticOut.transform((value - 0.24) / 0.76);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        key: const Key('learner-card-tilt-target'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _tilt(event.localPosition),
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _tiltController]),
          child: widget.child,
          builder: (context, child) {
            final bob = math.sin(_floatController.value * math.pi * 2) * 4;
            final strength = _tiltStrength;
            final tiltTransform = Matrix4.identity();
            if (strength.abs() > 0.0001) {
              tiltTransform
                ..setEntry(3, 2, 0.0012)
                ..rotateX(_targetTiltX * strength)
                ..rotateY(_targetTiltY * strength);
            }
            return Transform.translate(
              offset: Offset(0, bob),
              child: Transform(
                key: const Key('learner-card-tilt-transform'),
                alignment: Alignment.center,
                transform: tiltTransform,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResetLearnerDialog extends StatelessWidget {
  const _ResetLearnerDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('learner-reset-dialog'),
          width: 304,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF98EF6F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkGreen, width: 1.5),
            // Flat, hard-edged shadow only -- matching the app's sticker-card
            // convention (e.g. HomeLessonPreviewDialog's `blurRadius: 0`
            // shadows) instead of mixing in a second, soft/blurred shadow.
            boxShadow: const [
              BoxShadow(
                color: AppColors.darkGreen,
                offset: Offset(0, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'reset learner?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'balik kita sa name screen kag magsugod liwat?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('learner-reset-cancel-button'),
                      label: 'cancel',
                      height: 44,
                      fontSize: 14,
                      frontColor: AppColors.green,
                      depthColor: AppColors.darkGreen,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('learner-reset-confirm-button'),
                      label: 'reset',
                      height: 44,
                      fontSize: 14,
                      frontColor: AppColors.green,
                      depthColor: AppColors.darkGreen,
                      labelColor: const Color(0xFFFF5260),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnerCardPalette {
  const _LearnerCardPalette({
    required this.card,
    required this.panel,
    required this.badges,
    required this.surface,
    required this.inactive,
  });

  final Color card;
  final Color panel;
  final Color badges;
  final Color surface;
  final Color inactive;

  static _LearnerCardPalette forGrade(int grade) => switch (grade) {
    2 => const _LearnerCardPalette(
      card: Color(0xFFEAF3FA),
      panel: Color(0xFFB5CCE0),
      badges: Color(0xFFA7BED3),
      surface: Color(0xFFEDF4FA),
      inactive: Color(0xFF8EA7BB),
    ),
    3 => const _LearnerCardPalette(
      card: Color(0xFFFAEDEB),
      panel: Color(0xFFDDB8B4),
      badges: Color(0xFFD0A6A3),
      surface: Color(0xFFF9EEEC),
      inactive: Color(0xFFB68F8C),
    ),
    _ => const _LearnerCardPalette(
      card: Color(0xFFF3F7E8),
      panel: Color(0xFFB8CDB0),
      badges: Color(0xFFAFC3A7),
      surface: Color(0xFFF0F5E7),
      inactive: Color(0xFF91A68C),
    ),
  };
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({
    required this.learnerName,
    required this.grade,
    required this.energy,
    required this.earnedBadgeCount,
    required this.gradeColor,
    required this.kokaAsset,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final int earnedBadgeCount;
  final Color gradeColor;
  final String kokaAsset;

  @override
  Widget build(BuildContext context) {
    final palette = _LearnerCardPalette.forGrade(grade);
    return Container(
      key: const Key('learner-card'),
      width: 352,
      height: 561,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: const Color(0xFF24361F), width: 1.2),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          // The golden aura is a deliberate "magic reveal" glow for this
          // one-time card moment, not a card-lift shadow -- left as soft/
          // blurred on purpose, unlike the flat sticker-shadow convention
          // used everywhere else in the app.
          BoxShadow(color: Color(0xAAFFF176), spreadRadius: 4, blurRadius: 20),
          BoxShadow(color: Color(0x66FFD54F), spreadRadius: 9, blurRadius: 30),
          // The actual card-lift shadow, though, now matches the app's flat
          // hard-edged convention (see e.g. the reset dialog above) instead
          // of a soft blurred drop shadow -- using the card's own border
          // color for a cohesive bevel.
          BoxShadow(
            color: Color(0xFF24361F),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            left: 16,
            top: 14,
            width: 320,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'LEARNER CARD',
                  key: Key('learner-card-header-text'),
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 64,
            width: 320,
            height: 217,
            child: DecoratedBox(
              key: const Key('learner-card-portrait-panel'),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 24, 13, 23),
                child: Image.asset(
                  kokaAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 292,
            width: 320,
            height: 169,
            child: _DetailsPanel(
              key: const Key('learner-card-details-panel'),
              learnerName: learnerName,
              grade: grade,
              energy: energy,
              gradeColor: gradeColor,
              palette: palette,
            ),
          ),
          Positioned(
            left: 1,
            top: 475,
            width: 350,
            height: 65,
            child: _BadgesPanel(
              earnedBadgeCount: earnedBadgeCount,
              earnedColor: gradeColor,
              backgroundColor: palette.badges,
            ),
          ),
          Positioned.fill(child: _HolofoilOverlay(accent: gradeColor)),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.learnerName,
    required this.grade,
    required this.energy,
    required this.gradeColor,
    required this.palette,
    super.key,
  });

  final String learnerName;
  final int grade;
  final int energy;
  final Color gradeColor;
  final _LearnerCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 13,
            width: 205,
            height: 25,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                learnerName,
                key: const Key('learner-card-name'),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 17,
            top: 20,
            child: Text(
              'grade $grade',
              key: const Key('learner-card-grade'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Positioned(
            left: 13,
            top: 38,
            width: 294,
            child: Divider(height: 1, thickness: 1, color: Colors.black),
          ),
          // Just one label, not two -- there's only ever one bar below,
          // and it shows `energy` (the level the learner picked for
          // themselves during onboarding, static thereafter -- nothing
          // in the app ever changes it again). Previously this said "hil
          // progress" / "eng progress" side by side, implying two
          // separate Hiligaynon/English progress metrics that don't
          // exist; the percentage on the right is the same number the
          // bar visualizes, for a quick read without counting segments.
          const Positioned(
            left: 23,
            top: 47,
            child: Text('energy', style: TextStyle(fontSize: 12)),
          ),
          Positioned(
            right: 20,
            top: 47,
            child: Text(
              '$energy%',
              key: const Key('learner-card-energy-value'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Positioned(
            left: 23,
            top: 66,
            width: 282,
            height: 15,
            child: _SegmentedProgress(
              value: energy,
              color: gradeColor,
              trackColor: palette.surface,
              inactiveColor: palette.inactive,
            ),
          ),
          Positioned(
            left: 23,
            top: 89,
            child: _CounterTile(
              label: 'words saved',
              backgroundColor: palette.surface,
            ),
          ),
          Positioned(
            left: 122,
            top: 89,
            child: _CounterTile(
              label: 'stickers',
              backgroundColor: palette.surface,
            ),
          ),
          Positioned(
            left: 221,
            top: 89,
            child: _CounterTile(
              label: 'lessons finished',
              backgroundColor: palette.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.inactiveColor,
  });

  final int value;
  final Color color;
  final Color trackColor;
  final Color inactiveColor;

  static const _segmentCount = 20;

  @override
  Widget build(BuildContext context) {
    // Same 0-100 clamp convention as HomeEnergyIndicator, so this bar and
    // the home screen's energy indicator always agree on what a given
    // energy value looks like.
    final filledCount = (value.clamp(0, 100) / 100 * _segmentCount).round();
    return Semantics(
      label: '$value percent learning energy',
      child: Container(
        key: const Key('learner-card-energy'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var index = 0; index < _segmentCount; index++) ...[
              Expanded(
                child: SizedBox.expand(
                  child: DecoratedBox(
                    key: Key('learner-card-progress-segment-$index'),
                    decoration: BoxDecoration(
                      color: index < filledCount ? color : inactiveColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
              if (index != _segmentCount - 1) const SizedBox(width: 1.25),
            ],
          ],
        ),
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 70,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                '0',
                style: TextStyle(
                  fontSize: 43,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesPanel extends StatelessWidget {
  const _BadgesPanel({
    required this.earnedBadgeCount,
    required this.earnedColor,
    required this.backgroundColor,
  });

  static const _assets = <String>[
    'assets/images/badge_1.png',
    'assets/images/badge_2.png',
    'assets/images/badge_3.png',
    'assets/images/badge_4.png',
    'assets/images/badge_5.png',
    'assets/images/badge_6.png',
    'assets/images/badge_7.png',
    'assets/images/badge_8.png',
  ];

  final int earnedBadgeCount;
  final Color earnedColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Stack(
        children: [
          const Positioned(
            left: 17,
            top: 5,
            child: Text(
              "learner's badges",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Positioned(
            left: 17,
            top: 27,
            right: 17,
            height: 33,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var index = 0; index < _assets.length; index++)
                  SizedBox(
                    width: 33,
                    height: 33,
                    child: Semantics(
                      label:
                          'badge ${index + 1}, ${index < earnedBadgeCount ? 'earned' : 'locked'}',
                      image: true,
                      child: index < earnedBadgeCount
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                earnedColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                _assets[index],
                                key: Key('learner-badge-${index + 1}'),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            )
                          : Image.asset(
                              _assets[index],
                              key: Key('learner-badge-${index + 1}'),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HolofoilOverlay extends StatefulWidget {
  const _HolofoilOverlay({required this.accent});

  final Color accent;

  @override
  State<_HolofoilOverlay> createState() => _HolofoilOverlayState();
}

class _HolofoilOverlayState extends State<_HolofoilOverlay>
    with SingleTickerProviderStateMixin {
  static const _targetFramesPerSecond = 30;
  static const _animationSeconds = 14;
  static const _frameCount = _targetFramesPerSecond * _animationSeconds;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _animationSeconds),
  );
  final ValueNotifier<double> _paintProgress = ValueNotifier<double>(0);
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scheduleFoilFrame);
  }

  void _scheduleFoilFrame() {
    final quantized = (_controller.value * _frameCount).floor() / _frameCount;
    if (quantized != _paintProgress.value) {
      _paintProgress.value = quantized;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = !effectiveAmbientMotionEnabled(context);
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0.42;
      _paintProgress.value = 0.42;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_scheduleFoilFrame);
    _controller.dispose();
    _paintProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(
              child: CustomPaint(painter: _FoilGrainPainter()),
            ),
            AnimatedBuilder(
              animation: _paintProgress,
              builder: (context, child) => CustomPaint(
                key: const Key('learner-card-holofoil'),
                isComplex: true,
                willChange: true,
                painter: _HolofoilPainter(
                  progress: _paintProgress.value,
                  accent: widget.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _foilColors = <Color>[
  Color(0xFF00D9FF),
  Color(0xFF596CFF),
  Color(0xFFB64DFF),
  Color(0xFFFF4FA3),
  Color(0xFFFF8A3D),
  Color(0xFFFFE94A),
  Color(0xFF55F27C),
];

double _foilNoise(int seed) {
  final value = math.sin(seed * 12.9898) * 43758.5453;
  return value - value.floorToDouble();
}

double _foilSmoothstep(double value) {
  final clamped = value.clamp(0.0, 1.0);
  return clamped * clamped * (3 - 2 * clamped);
}

class _FoilGrainPainter extends CustomPainter {
  const _FoilGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var index = 0; index < 70; index++) {
      final center = Offset(
        _foilNoise(index * 47 + 5) * size.width,
        _foilNoise(index * 61 + 19) * size.height,
      );
      paint.color = _foilColors[(index * 3) % _foilColors.length].withValues(
        alpha: 0.34,
      );
      canvas.drawCircle(center, 0.55 + _foilNoise(index * 23 + 2) * 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FoilGrainPainter oldDelegate) => false;
}

class _HolofoilPainter extends CustomPainter {
  const _HolofoilPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final time = progress * math.pi * 2;

    // Each patch fades out completely before receiving a new deterministic
    // random position. This creates soft spawning across the whole card with
    // no visible teleporting and a perfectly seamless loop.
    const patchSlots = 8;
    const patchCyclesPerLoop = 2;
    for (var index = 0; index < patchSlots; index++) {
      final cycle = progress * patchCyclesPerLoop + index / patchSlots;
      final generation = cycle.floor();
      final phase = cycle - generation;
      final opacity = switch (phase) {
        < 0.18 => _foilSmoothstep(phase / 0.18),
        < 0.48 => 1.0,
        < 0.78 => 1 - _foilSmoothstep((phase - 0.48) / 0.30),
        _ => 0.0,
      };
      if (opacity <= 0.001) continue;

      final spawn = index * 101 + (generation % patchCyclesPerLoop) * 977;
      final center = Offset(
        (0.02 + _foilNoise(spawn + 11) * 0.96) * size.width,
        (0.02 + _foilNoise(spawn + 23) * 0.96) * size.height,
      );
      final radiusX = 68.0 + _foilNoise(spawn + 37) * 82;
      final radiusY = radiusX * (0.72 + _foilNoise(spawn + 41) * 0.55);
      final patchRect = Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      );
      final color =
          _foilColors[(_foilNoise(spawn + 53) * _foilColors.length).floor() %
              _foilColors.length];
      final patchPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.28 * opacity),
            color.withValues(alpha: 0.15 * opacity),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(patchRect);
      final angle = (_foilNoise(spawn + 67) - 0.5) * math.pi;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawOval(patchRect, patchPaint);
      canvas.restore();
    }

    // Bright four-point stars twinkle independently at deterministic random
    // positions, avoiding visual jumps between animation frames.
    for (var index = 0; index < 38; index++) {
      final phaseA = _foilNoise(index * 59 + 7) * math.pi * 2;
      final phaseB = _foilNoise(index * 67 + 23) * math.pi * 2;
      final frequencyA = 1.0 + (_foilNoise(index * 71 + 29) * 3).floor();
      final frequencyB = frequencyA + 1.0 + index % 2;
      final wave =
          math.sin(time * frequencyA + phaseA) * 0.68 +
          math.sin(time * frequencyB + phaseB) * 0.32;
      final twinkle = math.pow(math.max(0.0, wave), 3).toDouble();
      if (twinkle < 0.025) continue;
      final baseCenter = Offset(
        _foilNoise(index * 73 + 13) * size.width,
        _foilNoise(index * 89 + 31) * size.height,
      );
      final center =
          baseCenter +
          Offset(
            math.sin(time * (1 + index % 2) + phaseB) * 3.2,
            math.cos(time * (1 + (index + 1) % 2) + phaseA) * 2.6,
          );
      final radius = (1.4 + _foilNoise(index * 37 + 17) * 3.8) * twinkle;
      final sparkleColor = Color.lerp(
        Colors.white,
        _foilColors[(index + 2) % _foilColors.length],
        0.24,
      )!;
      canvas.drawCircle(
        center,
        radius * 2.2,
        Paint()..color = sparkleColor.withValues(alpha: 0.12 * twinkle),
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - radius * 1.9)
          ..lineTo(center.dx + radius * 0.34, center.dy - radius * 0.34)
          ..lineTo(center.dx + radius * 1.9, center.dy)
          ..lineTo(center.dx + radius * 0.34, center.dy + radius * 0.34)
          ..lineTo(center.dx, center.dy + radius * 1.9)
          ..lineTo(center.dx - radius * 0.34, center.dy + radius * 0.34)
          ..lineTo(center.dx - radius * 1.9, center.dy)
          ..lineTo(center.dx - radius * 0.34, center.dy - radius * 0.34)
          ..close(),
        Paint()..color = sparkleColor.withValues(alpha: 0.82 * twinkle),
      );
    }

    final borderRect = bounds.deflate(1.4);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        transform: GradientRotation(progress * math.pi * 2),
        colors: [
          accent.withValues(alpha: 0.70),
          const Color(0xB36DEBFF),
          const Color(0xB3D983FF),
          const Color(0xB3FFE36D),
          const Color(0xB3FF7AA8),
          accent.withValues(alpha: 0.70),
        ],
      ).createShader(bounds);
    canvas.drawRRect(
      RRect.fromRectAndRadius(borderRect, const Radius.circular(15.6)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HolofoilPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = const Color(0x558EBF59);
    const rays = 16;
    for (var index = 0; index < rays; index += 2) {
      final start = index * 6.283185307179586 / rays;
      final end = (index + 1) * 6.283185307179586 / rays;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + 720 * math.cos(start),
            center.dy + 720 * math.sin(start),
          )
          ..lineTo(
            center.dx + 720 * math.cos(end),
            center.dy + 720 * math.sin(end),
          )
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) => false;
}

class _RotatingRays extends StatefulWidget {
  const _RotatingRays();

  @override
  State<_RotatingRays> createState() => _RotatingRaysState();
}

class _RotatingRaysState extends State<_RotatingRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.rotate(
          key: const Key('learner-card-rotating-rays'),
          angle: _controller.value * math.pi * 2,
          child: child,
        ),
        child: const CustomPaint(painter: _RaysPainter()),
      ),
    );
  }
}
