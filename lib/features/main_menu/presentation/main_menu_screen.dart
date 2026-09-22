import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/theme/app_colors.dart';
import 'package:tudloapp/features/home/presentation/screens/fourth_loading_screen.dart';
import 'package:tudloapp/features/home/presentation/screens/home_screen.dart';
import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/load/presentation/load_screen.dart';
import 'package:tudloapp/features/me/presentation/screens/daily_streak_flow.dart';
import 'package:tudloapp/features/onboarding/presentation/screens/name_screen.dart';
import 'package:tudloapp/features/settings/presentation/settings_screen.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/rive_long_button.dart';
import 'package:tudloapp/shared/widgets/rive_settings_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  /// How many characters of the learner's name the "continue" button will
  /// show before cutting it off with "..." -- the button is a fixed-size
  /// Rive graphic, not a text field that can wrap or shrink to fit.
  static const _maxContinueNameLength = 10;
  static const _menuButtonHeight = 70.0;

  LearnerProfile? _lastUsedProfile;
  var _resolvedLastUsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    TudloAudioScope.of(
      context,
    ).preloadSoundEffect(TudloAudioAssets.mapUnlockedSoundEffect);
    // Only resolve once per mount -- didChangeDependencies can fire again
    // for unrelated inherited-widget changes. No need to fetch anything if
    // someone's already actively signed in.
    if (_resolvedLastUsed) return;
    _resolvedLastUsed = true;
    if (LearnerScope.of(context).profile != null) return;
    unawaited(_loadLastUsedProfile());
  }

  /// Resolves whoever's currently last-used on disk and sets [_lastUsedProfile]
  /// to match exactly -- including back to `null` if storage now reports
  /// nobody (e.g. that learner was deleted from the Load screen since this
  /// was last resolved). Reused by both the initial mount resolve and
  /// [_openLoad]'s post-return refresh below.
  Future<void> _loadLastUsedProfile() async {
    final profile = await LearnerScope.of(context).loadLastUsedProfile();
    if (!mounted) return;
    setState(() => _lastUsedProfile = profile);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(FadePageRoute<void>(page: screen));
  }

  /// Same as [_open] for the Load screen specifically, except it awaits the
  /// pushed route's own `Future` (which a plain `push` would otherwise just
  /// discard) so it knows exactly when the user has come back -- the one
  /// moment [_lastUsedProfile] might have gone stale, since Load is the only
  /// screen reachable from here that can delete the learner "continue" names.
  Future<void> _openLoad(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(FadePageRoute<void>(page: const LoadScreen()));
    if (!mounted) return;
    await _loadLastUsedProfile();
  }

  void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(FadePageRoute<void>(page: screen));
  }

  /// "continue" alone if nobody's ever used this device, otherwise
  /// "continue as `name`" -- naming whoever's actively signed in, or
  /// failing that, whoever was last signed in (see [LearnerController.
  /// loadLastUsedProfile], which survives logging out). Cuts the name off
  /// with "..." once it'd make the label too long for the button.
  String _continueLabel(BuildContext context) {
    final name =
        (LearnerScope.of(context).profile?.name ?? _lastUsedProfile?.name)
            ?.trim();
    if (name == null || name.isEmpty) return 'continue';
    final shown = name.length > _maxContinueNameLength
        ? '${name.substring(0, _maxContinueNameLength - 3)}...'
        : name;
    return 'continue as $shown';
  }

  /// Whether "continue" has anyone to actually resume -- either an active
  /// profile or a last-used one still on disk. Kept in lockstep with
  /// [_continueLabel] since both read the same two sources, so the button's
  /// enabled-state and its label can never disagree.
  bool _canContinue(BuildContext context) =>
      LearnerScope.of(context).profile != null || _lastUsedProfile != null;

  /// Resuming with nobody actively signed in (e.g. right after logging
  /// out) silently signs back into whoever "continue" named, so Home
  /// actually shows that learner instead of empty defaults.
  ///
  /// Always re-reads [LearnerController.loadLastUsedProfile] here rather
  /// than trusting the cached [_lastUsedProfile] -- that cache is only
  /// ever populated once per mount, so it goes stale (and would silently
  /// resurrect a deleted profile via [LearnerController.switchTo]) if the
  /// learner it names got deleted from the Load screen after this screen
  /// was first built but before "continue" is tapped.
  Future<void> _continue(BuildContext context) async {
    final scope = LearnerScope.of(context);
    if (scope.profile == null) {
      final resume = await scope.loadLastUsedProfile();
      if (resume != null) await scope.switchTo(resume);
    }
    if (!context.mounted) return;
    // Goes silent through the loading transition; HomeScreen starts it
    // fresh again once it actually appears.
    unawaited(TudloAudioScope.of(context).stopBackgroundMusic());
    final profile = scope.profile;
    final needsStreakCheckIn =
        profile != null && profile.needsStreakCheckInToday();
    if (needsStreakCheckIn) unawaited(scope.recordStreakCheckIn());
    // The check-in/streak screens show after the loading screen, not
    // before it -- same spot HomeScreen itself would otherwise appear.
    _replaceWith(
      context,
      FourthLoadingScreen(
        homeBuilder: needsStreakCheckIn ? _buildStreakThenHome : null,
      ),
    );
  }

  Widget _buildStreakThenHome(BuildContext context) {
    return DailyStreakFlow(
      onFinished: (flowContext) => Navigator.of(
        flowContext,
      ).pushReplacement(FadePageRoute<void>(page: const HomeScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.mint,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 412,
              height: 917,
              child: Stack(
                children: [
                  Positioned(
                    key: const Key('main-menu-logo'),
                    left: 82,
                    top: 252,
                    width: 248,
                    height: 279,
                    child: Image.asset(
                      'assets/images/onboarding_logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Tudlo logo and description',
                    ),
                  ),
                  Positioned(
                    key: const Key('main-menu-footer'),
                    left: 30,
                    top: 824,
                    width: 352,
                    height: 42,
                    child: Image.asset(
                      'assets/images/onboarding_footer.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Tudlo project footer',
                    ),
                  ),
                  Positioned(
                    left: 335,
                    top: 51,
                    width: 47,
                    height: 49,
                    child: RiveSettingsButton(
                      key: const Key('main-settings-button'),
                      onPressed: () => _open(context, const SettingsScreen()),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 594,
                    width: 352.295,
                    height: _menuButtonHeight,
                    child: RiveLongButton(
                      label: 'start new koka',
                      buttonHeight: _menuButtonHeight,
                      onPressed: () => _open(context, const NameScreen()),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 670,
                    width: 352,
                    height: _menuButtonHeight,
                    child: RiveLongButton(
                      label: _continueLabel(context),
                      enabled: _canContinue(context),
                      buttonHeight: _menuButtonHeight,
                      soundEffectAsset: TudloAudioAssets.mapUnlockedSoundEffect,
                      onPressed: () => unawaited(_continue(context)),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 746,
                    width: 352,
                    height: _menuButtonHeight,
                    child: RiveLongButton(
                      label: 'load',
                      buttonHeight: _menuButtonHeight,
                      onPressed: () => unawaited(_openLoad(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
