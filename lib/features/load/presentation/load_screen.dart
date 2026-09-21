import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/features/home/presentation/screens/fourth_loading_screen.dart';
import 'package:tudloapp/features/home/presentation/screens/home_screen.dart';
import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/load/domain/save_preview.dart';
import 'package:tudloapp/features/load/presentation/widgets/load_confirmation_dialog.dart';
import 'package:tudloapp/features/load/presentation/widgets/save_card.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';
import 'package:tudloapp/shared/widgets/rive_load_nav_button.dart';

class LoadScreen extends StatefulWidget {
  const LoadScreen({this.introVoiceOverPlayer, super.key});

  /// Overridable for tests, same convention as `StartupFlow`'s
  /// `logoAudioPlayer`/`backgroundMusicPlayer` -- defaults to actually
  /// playing `assets/audio/vo_load_screen.wav` via `flutter_soloud` once,
  /// when this screen opens.
  final Future<void> Function()? introVoiceOverPlayer;

  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  static const _pageSize = 4;

  /// The one fixed, non-persisted sample save -- always present, never
  /// deletable, and loading it never touches [LearnerScope].
  static const _demoSave = SavePreview(
    name: 'demo koka',
    grade: GradeLevel.grade1,
    avatarId: LearnerProfile.defaultAvatarId,
  );

  var saves = const <SavePreview>[_demoSave];
  var _profiles = const <LearnerProfile>[];
  var _resolvedSaves = false;
  int _currentPage = 0;

  var _playedIntroVo = false;
  TudloAudioController? _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    _audio = audio;
    audio.preloadSoundEffect(TudloAudioAssets.mapUnlockedSoundEffect);
    // Only resolve once per mount -- didChangeDependencies can fire again
    // for unrelated inherited-widget changes.
    if (_resolvedSaves) return;
    _resolvedSaves = true;
    _refreshSaves();
    audio.preloadVoiceOver(TudloAudioAssets.loadScreenVoiceOver);

    if (!_playedIntroVo) {
      _playedIntroVo = true;
      unawaited(
        (widget.introVoiceOverPlayer ??
            () => audio.playVoiceOver(TudloAudioAssets.loadScreenVoiceOver))(),
      );
    }
  }

  Future<void> _stopIntroVoiceOver() {
    return _audio?.stopVoiceOver(TudloAudioAssets.loadScreenVoiceOver) ??
        Future<void>.value();
  }

  void _leaveLoadScreen() {
    unawaited(_stopIntroVoiceOver());
    Navigator.of(context).pop();
  }

  Future<void> _refreshSaves() async {
    final profiles = await LearnerScope.of(context).listSavedProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      saves = [_demoSave, ...profiles.map(SavePreview.fromProfile)];
      if (_currentPage >= _pageCount) {
        _currentPage = (_pageCount - 1).clamp(0, _pageCount - 1);
      }
    });
  }

  int get _pageCount => (saves.length / _pageSize).ceil();

  void _goToPage(int page) {
    if (page < 0 || page >= _pageCount || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  Future<void> _confirm(int index, bool deleting) async {
    final save = saves[index];
    final confirmationVoiceOver = deleting
        ? TudloAudioAssets.deleteConfirmationVoiceOver
        : TudloAudioAssets.loadConfirmationVoiceOver;
    final audio = TudloAudioScope.of(context);

    // A confirmation prompt owns the spoken focus. Do not let the initial
    // Load-screen introduction overlap it.
    unawaited(_stopIntroVoiceOver());
    audio.preloadVoiceOver(confirmationVoiceOver);

    final confirmation = showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: deleting ? 'Delete confirmation' : 'Load confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.51),
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, animation, secondaryAnimation) =>
          LoadConfirmationDialog(
            name: save.name,
            previewColor: save.previewColor,
            grade: save.grade.number,
            avatarId: save.avatarId,
            deleting: deleting,
          ),
    );
    // The dialog route is pushed synchronously, but its first visible frame
    // arrives next. Starting here guarantees the matching VO belongs to the
    // pop-up the learner can actually see.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(audio.playVoiceOver(confirmationVoiceOver));
      }
    });

    final accepted = await confirmation;
    // The confirmation's words must never continue underneath Load or the
    // following loading/home route after the dialog is dismissed.
    unawaited(audio.stopVoiceOver(confirmationVoiceOver));
    if (!mounted || accepted != true) return;

    if (deleting) {
      await LearnerScope.of(context).deleteProfile(save.profileId!);
      if (!mounted) return;
      await _refreshSaves();
      return;
    }

    if (save.isDemo) {
      // pushAndRemoveUntil, not pushReplacement -- this can be reached with
      // the main menu still underneath in the stack (opened via a plain
      // `push`), and Home is meant to be the navigator's first route (see
      // AppBottomTabNavigation's `popUntil((route) => route.isFirst)`).
      // A mere pushReplacement would leave the main menu route stranded
      // beneath Home, so tapping the bottom nav's Home tab would pop past
      // Home and land back on the main menu instead of staying on Home.
      //
      // Goes silent through the loading transition; HomeScreen starts it
      // fresh again once it actually appears.
      unawaited(_stopIntroVoiceOver());
      unawaited(TudloAudioScope.of(context).stopBackgroundMusic());
      Navigator.of(context).pushAndRemoveUntil(
        FadePageRoute<void>(
          page: FourthLoadingScreen(
            homeBuilder: (context) =>
                const HomeScreen(learnerName: 'demo koka', energy: 60),
          ),
        ),
        (route) => false,
      );
      return;
    }

    final profile = _profiles
        .where((profile) => profile.id == save.profileId)
        .firstOrNull;
    if (profile == null) return;
    await LearnerScope.of(context).switchTo(profile);
    if (!mounted) return;
    // Same reasoning as the demo branch above.
    unawaited(_stopIntroVoiceOver());
    unawaited(TudloAudioScope.of(context).stopBackgroundMusic());
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(page: const FourthLoadingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageStart = _currentPage * _pageSize;
    final visibleSaves = saves.skip(pageStart).take(_pageSize).toList();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: const Key('load-page-canvas'),
                    width: 412,
                    height: 917,
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 412,
                          height: 917,
                          child: MediaQuery.withNoTextScaling(
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 47,
                                  top: 108,
                                  child: SizedBox(
                                    key: const Key('load-header-image'),
                                    width: 318,
                                    height: 186.5,
                                    child: Image.asset(
                                      'assets/images/load_logo.png',
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      semanticLabel:
                                          'maayong pag balik! Load saved progress',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 26,
                                  top: 323,
                                  width: 360,
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    runAlignment: WrapAlignment.start,
                                    spacing: 24,
                                    runSpacing: 18,
                                    children: [
                                      for (
                                        var index = 0;
                                        index < visibleSaves.length;
                                        index++
                                      )
                                        SizedBox(
                                          width: 168,
                                          height: 193,
                                          child: SaveCard(
                                            name: visibleSaves[index].name,
                                            previewShadowColor:
                                                visibleSaves[index]
                                                    .previewShadowColor,
                                            grade: visibleSaves[index]
                                                .grade
                                                .number,
                                            avatarId:
                                                visibleSaves[index].avatarId,
                                            onLoad: () => _confirm(
                                              pageStart + index,
                                              false,
                                            ),
                                            onDelete: visibleSaves[index].isDemo
                                                ? null
                                                : () => _confirm(
                                                    pageStart + index,
                                                    true,
                                                  ),
                                          ),
                                        ),
                                    ],
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
            ),
          ),
          SafeArea(
            child: AdaptiveBackButtonPlacement(onPressed: _leaveLoadScreen),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = _largeScreenScale(constraints);
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    26 * scale,
                    0,
                    26 * scale,
                    30 * scale,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 255 * scale,
                      child: Row(
                        key: const Key('load-pagination'),
                        children: [
                          _ScaledDesignControl(
                            scale: scale,
                            child: RiveLoadNavButton(
                              key: const Key('load-previous-button'),
                              assetPath: 'assets/images/load_prev_button.riv',
                              fallbackLabel: 'previous',
                              enabled: _currentPage > 0,
                              onPressed: () => _goToPage(_currentPage - 1),
                            ),
                          ),
                          SizedBox(width: 20 * scale),
                          SizedBox(
                            width: 29 * scale,
                            height: 19 * scale,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Container(
                                key: const Key('load-page-number'),
                                width: 29,
                                height: 19,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_currentPage + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20 * scale),
                          _ScaledDesignControl(
                            scale: scale,
                            child: RiveLoadNavButton(
                              key: const Key('load-next-button'),
                              assetPath: 'assets/images/load_next_button.riv',
                              fallbackLabel: 'next',
                              enabled: _currentPage < _pageCount - 1,
                              onPressed: () => _goToPage(_currentPage + 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Covers system back and external route removal in addition to the
    // explicit navigation paths above.
    unawaited(_stopIntroVoiceOver());
    super.dispose();
  }
}

double _largeScreenScale(BoxConstraints constraints) {
  final widthScale = constraints.maxWidth / 412;
  final heightScale = constraints.maxHeight / 917;
  return widthScale < heightScale ? widthScale : heightScale;
}

class _ScaledDesignControl extends StatelessWidget {
  const _ScaledDesignControl({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 93 * scale,
      height: 44 * scale,
      child: FittedBox(fit: BoxFit.fill, child: child),
    );
  }
}
