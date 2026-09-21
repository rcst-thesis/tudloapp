import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/features/home/presentation/screens/home_screen.dart';
import 'package:tudloapp/features/placeholder/presentation/placeholder_screen.dart';
import 'package:tudloapp/features/welcome/presentation/widgets/farm_depth_background.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/onboarding_bottom_actions.dart';

class WelcomeAboardScreen extends StatefulWidget {
  const WelcomeAboardScreen({
    this.learnerName = '',
    this.onNext,
    this.onSkip,
    this.voiceOverPlayer,
    super.key,
  });

  final String learnerName;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final Future<void> Function()? voiceOverPlayer;

  @override
  State<WelcomeAboardScreen> createState() => _WelcomeAboardScreenState();
}

class _WelcomeAboardScreenState extends State<WelcomeAboardScreen> {
  Offset _farmTilt = Offset.zero;
  Timer? _recenterTimer;
  bool _openingTutorial = false;
  bool _openingHome = false;
  TudloAudioController? _audio;
  var _initialVoiceOverScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    audio.preloadVoiceOver(TudloAudioAssets.welcomeAboardVoiceOver);
    if (_initialVoiceOverScheduled) return;
    _initialVoiceOverScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_playVoiceOver());
    });
  }

  Future<void> _playVoiceOver() {
    return widget.voiceOverPlayer?.call() ??
        _audio?.playVoiceOver(TudloAudioAssets.welcomeAboardVoiceOver) ??
        Future<void>.value();
  }

  Future<void> _stopVoiceOver() {
    return _audio?.stopVoiceOver(TudloAudioAssets.welcomeAboardVoiceOver) ??
        Future<void>.value();
  }

  Future<void> _openTutorialPlaceholder() async {
    if (_openingTutorial) return;
    _openingTutorial = true;
    unawaited(_stopVoiceOver());
    await Navigator.of(context).push(
      FadePageRoute<void>(
        page: const PlaceholderScreen(
          title: 'Tutorial',
          description: 'New learner tutorial will be built here.',
          icon: Icons.school_rounded,
        ),
      ),
    );
    _openingTutorial = false;
  }

  Future<void> _openHome() async {
    if (_openingHome) return;
    _openingHome = true;
    unawaited(_stopVoiceOver());
    unawaited(
      Navigator.of(context).pushReplacement(
        FadePageRoute<void>(page: HomeScreen(learnerName: widget.learnerName)),
      ),
    );
  }

  void _handleNext() {
    if (widget.onNext case final callback?) {
      unawaited(_stopVoiceOver());
      callback();
      return;
    }
    unawaited(_openTutorialPlaceholder());
  }

  void _handleSkip() {
    if (widget.onSkip case final callback?) {
      unawaited(_stopVoiceOver());
      callback();
      return;
    }
    unawaited(_openHome());
  }

  void _tiltFarm(PointerEvent event, Size size) {
    _recenterTimer?.cancel();
    setState(() {
      _farmTilt = Offset(
        ((event.localPosition.dx / size.width) - 0.5).clamp(-0.5, 0.5) * 2,
        ((event.localPosition.dy / size.height) - 0.5).clamp(-0.5, 0.5) * 2,
      );
    });
  }

  void _recenterFarm() {
    _recenterTimer?.cancel();
    _recenterTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() => _farmTilt = Offset.zero);
    });
  }

  @override
  void dispose() {
    _recenterTimer?.cancel();
    unawaited(_stopVoiceOver());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8D8E7),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
            final compact = constraints.maxHeight < 720;
            final uiScale = math
                .min(constraints.maxWidth / 412, constraints.maxHeight / 917)
                .clamp(0.78, 1.08);
            final verticalScale = (constraints.maxHeight / 917).clamp(
              0.62,
              1.08,
            );
            final useWideFarm =
                compact || constraints.maxWidth / constraints.maxHeight > 0.52;
            final farmAspectRatio = useWideFarm ? 535 / 552 : 412 / 552;
            final farmWidth = math.min(
              constraints.maxWidth,
              constraints.maxHeight * farmAspectRatio,
            );
            final farmHeight = farmWidth / farmAspectRatio;
            final farmGroundHeight = farmHeight * (552 - 348.469) / 552;
            return Listener(
              key: const Key('welcome-depth-interaction-surface'),
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _tiltFarm(event, constraints.biggest),
              onPointerMove: (event) => _tiltFarm(event, constraints.biggest),
              onPointerUp: (_) => _recenterFarm(),
              onPointerCancel: (_) => _recenterFarm(),
              child: Stack(
                key: const Key('welcome-aboard-screen'),
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: farmGroundHeight,
                    child: const ColoredBox(color: Color(0xFFABD962)),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        key: const Key('welcome-farm-frame'),
                        width: farmWidth,
                        height: farmHeight,
                        child: FarmDepthBackground(
                          assetName: useWideFarm
                              ? 'assets/images/welcome_farm_background_wide.svg'
                              : 'assets/images/welcome_farm_background.svg',
                          enableHardwareTilt: false,
                          enableTouchTilt: false,
                          tiltTarget: _farmTilt,
                          layerAssets: useWideFarm
                              ? const [
                                  'assets/images/welcome_farm_far_wide_v3.svg',
                                  'assets/images/welcome_farm_mountains_wide_v3.svg',
                                  'assets/images/welcome_farm_fields_wide_v3.svg',
                                  'assets/images/welcome_farm_subject_wide_v3.svg',
                                ]
                              : const [
                                  'assets/images/welcome_farm_far_v3.svg',
                                  'assets/images/welcome_farm_mountains_v3.svg',
                                  'assets/images/welcome_farm_fields_v3.svg',
                                  'assets/images/welcome_farm_subject_v3.svg',
                                ],
                          skyIdleAssets: useWideFarm
                              ? const [
                                  'assets/images/welcome_sky_base_wide_v1.svg',
                                  'assets/images/welcome_sky_sun_responsive.svg',
                                  'assets/images/welcome_sky_cloud_right_responsive.svg',
                                  'assets/images/welcome_sky_cloud_middle_wide_v1.svg',
                                  'assets/images/welcome_sky_cloud_left_wide_v1.svg',
                                ]
                              : const [
                                  'assets/images/welcome_sky_base_v1.svg',
                                  'assets/images/welcome_sky_sun_responsive.svg',
                                  'assets/images/welcome_sky_cloud_right_responsive.svg',
                                  'assets/images/welcome_sky_cloud_middle_v1.svg',
                                  'assets/images/welcome_sky_cloud_left_v1.svg',
                                ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 96 * verticalScale,
                    left: 24 * uiScale,
                    right: 24 * uiScale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'welcome aboard!',
                        key: const Key('welcome-aboard-heading'),
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'ComicRelief',
                          fontSize: 32 * uiScale,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 157 * verticalScale,
                    left: 24 * uiScale,
                    right: 24 * uiScale,
                    child: Text(
                      'sa tagsa mo ka tikang, may\n'
                      'bag-o nga hibalo nga\n'
                      'nagahulat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF717171),
                        fontFamily: 'ComicRelief',
                        fontSize: 20 * uiScale,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 279 * verticalScale,
                    left: 24 * uiScale,
                    right: 24 * uiScale,
                    child: Text(
                      'first time mo diri sa tudlo app?\n'
                      'umpisahan ta kung pano gamiton ini nga\n'
                      'app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF4F5355),
                        fontFamily: 'ComicRelief',
                        fontSize: 14 * uiScale,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12 * uiScale + bottomInset,
                    child: Center(
                      child: SizedBox(
                        width: OnboardingBottomActions.width * uiScale,
                        height: OnboardingBottomActions.height * uiScale,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: OnboardingBottomActions(
                            primaryKey: const Key('welcome-aboard-next-button'),
                            secondaryKey: const Key(
                              'welcome-aboard-skip-button',
                            ),
                            primaryLabel: 'next',
                            secondaryLabel: 'skip',
                            primaryStyle: OnboardingPrimaryButtonStyle.white,
                            onPrimaryPressed: _handleNext,
                            onSecondaryPressed: _handleSkip,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
