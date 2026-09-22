import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_badge_collection.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_collections_header.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_content_footer.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_daily_streak_card.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_edit_button.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_edit_dialog.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_learner_card.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_section_wave_divider.dart';
import 'package:tudloapp/features/main_menu/presentation/main_menu_screen.dart';
import 'package:tudloapp/features/me/presentation/widgets/me_settings_button.dart';
import 'package:tudloapp/features/settings/presentation/settings_screen.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/rive_settings_button.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

/// Incremental Me screen. Currently hosts the top Settings/Edit buttons,
/// the learner card with its about/details/progress tabs, and the daily
/// streak card; badge collection follows later.
///
/// [learnerName], [grade], [userCode], [createdAt], [lessonsFinished],
/// [stickersEarned], [badgesEarned], and [currentStreak] are explicit
/// overrides -- mainly for tests. Real app code shouldn't need these: when
/// omitted, they fall back to the current learner from [LearnerScope], then
/// to the original hardcoded placeholders if no learner is loaded either
/// (`createdAt` falls back to now, so the "details" tab's age reads
/// "today"; the progress counts and streak default honestly, 0 and 1,
/// rather than fabricated numbers).
class MeScreen extends StatefulWidget {
  const MeScreen({
    this.learnerName,
    this.grade,
    this.userCode,
    this.lessonsFinished,
    this.stickersEarned,
    this.badgesEarned,
    this.currentStreak,
    this.createdAt,
    super.key,
  });

  final String? learnerName;
  final int? grade;
  final String? userCode;
  final DateTime? createdAt;
  final int? lessonsFinished;
  final int? stickersEarned;
  final int? badgesEarned;
  final int? currentStreak;

  static const _topBackgroundColor = Color(0xFFE5D5A9);
  static const _bottomBackgroundColor = Color(0xFFDCCB8C);
  static const _designWidth = 412.0;

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  var _selectedTab = MeCardTab.about;
  TudloAudioController? _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.of(context);
    if (identical(_audio, audio)) return;
    _audio = audio;
    audio.preloadSoundEffect(TudloAudioAssets.meAvatarTileSoundEffect);
  }

  String get _learnerName =>
      widget.learnerName ?? LearnerScope.of(context).profile?.name ?? 'Koka';
  int get _grade =>
      widget.grade ?? LearnerScope.of(context).profile?.grade ?? 1;
  String get _userCode =>
      widget.userCode ?? LearnerScope.of(context).profile?.id ?? '0000001';
  String get _avatarId =>
      LearnerScope.of(context).profile?.avatarId ??
      LearnerProfile.defaultAvatarId;
  DateTime get _createdAt =>
      widget.createdAt ??
      LearnerScope.of(context).profile?.createdAt ??
      DateTime.now();
  int get _lessonsFinished =>
      widget.lessonsFinished ??
      LearnerScope.of(context).profile?.lessonsFinished ??
      0;
  int get _stickersEarned =>
      widget.stickersEarned ??
      LearnerScope.of(context).profile?.stickersEarned ??
      0;
  int get _badgesEarned =>
      widget.badgesEarned ??
      LearnerScope.of(context).profile?.badgesEarned ??
      0;
  int get _currentStreak =>
      widget.currentStreak ??
      LearnerScope.of(context).profile?.effectiveStreak() ??
      1;

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: const SettingsScreen(insideLearnerProfile: true),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final audio = _audio;
    final result = await showGeneralDialog<MeEditResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit profile',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => MeEditDialog(
        learnerName: _learnerName,
        grade: _grade,
        userCode: _userCode,
        avatarId: _avatarId,
        onAvatarSelected: (_) => unawaited(
          audio?.playSoundEffect(TudloAudioAssets.meAvatarTileSoundEffect) ??
              Future<void>.value(),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );
    if (result == null || !context.mounted) return;
    // Uses *this* screen's own context, not the dialog's -- see
    // MeEditResult's doc for why the dialog can't safely do this itself.
    final scope = LearnerScope.of(context);
    if (result.name != _learnerName) await scope.updateName(result.name);
    if (result.avatarId != _avatarId) await scope.updateAvatar(result.avatarId);
  }

  Future<void> _logOut(BuildContext context) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Log out confirmation',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _LogoutConfirmationDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );
    if (confirmed != true || !context.mounted) return;
    await LearnerScope.of(context).logOut();
    if (!context.mounted) return;
    // Signed-in learner's own settings no longer apply once logged out --
    // start fresh against the device-wide copy (nothing else restarts
    // playback on this particular path, unlike MainMenuScreen->Home, which
    // stops it on the way in and HomeScreen starts it fresh on the way
    // back).
    unawaited(TudloAudioScope.of(context).startBackgroundMusic());
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(page: const MainMenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('me-screen'),
      backgroundColor: MeScreen._topBackgroundColor,
      bottomNavigationBar: const AppBottomTabNavigation(currentIndex: 5),
      // Full-bleed behind the status bar, same as Home: the top buttons'
      // own `51 * topControlScale` offset alone clears it, so wrapping in
      // SafeArea here would double that clearance.
      body: LayoutBuilder(
        builder: (context, viewport) {
          final canvasWidth = math.min(viewport.maxWidth, 720.0);
          final topControlScale = (canvasWidth / 460).clamp(.82, 1.12);
          final sceneScale = canvasWidth / MeScreen._designWidth;
          return SingleChildScrollView(
            key: const Key('me-content-scroll-view'),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: canvasWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColoredBox(
                      color: MeScreen._topBackgroundColor,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  19 * sceneScale,
                                  140 * sceneScale,
                                  19 * sceneScale,
                                  24 * sceneScale,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    MeLearnerCard(
                                      learnerName: _learnerName,
                                      grade: _grade,
                                      userCode: _userCode,
                                      avatarId: _avatarId,
                                      selectedTab: _selectedTab,
                                      onTabSelected: (tab) =>
                                          setState(() => _selectedTab = tab),
                                      createdAt: _createdAt,
                                      lessonsFinished: _lessonsFinished,
                                      stickersEarned: _stickersEarned,
                                      badgesEarned: _badgesEarned,
                                    ),
                                    SizedBox(height: 16 * sceneScale),
                                    MeDailyStreakCard(
                                      currentStreak: _currentStreak,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 48 * sceneScale,
                                child: const MeSectionWaveDivider(
                                  color: MeScreen._bottomBackgroundColor,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 51 * topControlScale,
                            left: 30 * topControlScale,
                            width: RiveSettingsButton.width * topControlScale,
                            height: RiveSettingsButton.height * topControlScale,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: MeSettingsButton(
                                onTap: () => _openSettings(context),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 51 * topControlScale,
                            right: 30 * topControlScale,
                            width: MeEditButton.width * topControlScale,
                            height: MeEditButton.height * topControlScale,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: MeEditButton(
                                onPressed: () => unawaited(_openEdit(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ColoredBox(
                      color: MeScreen._bottomBackgroundColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              19 * sceneScale,
                              10 * sceneScale,
                              19 * sceneScale,
                              0,
                            ),
                            child: const MeCollectionsHeader(),
                          ),
                          SizedBox(height: 12 * sceneScale),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 19 * sceneScale,
                            ),
                            child: const MeBadgeCollection(),
                          ),
                          SizedBox(height: 100 * sceneScale),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 19 * sceneScale,
                            ),
                            child: StickerPressButton(
                              key: const Key('me-logout-button'),
                              label: 'log out',
                              frontColor: const Color(0xFFFF5260),
                              depthColor: const Color(0xFFB23347),
                              onPressed: () => _logOut(context),
                            ),
                          ),
                          SizedBox(height: 12 * sceneScale),
                          SizedBox(
                            height: 48 * sceneScale,
                            child: const MeContentFooter(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Confirmation dialog, styled identically to
/// `learner_card_screen.dart`'s `_ResetLearnerDialog` -- the app's
/// established sticker-card pattern for a "this leaves your current
/// session" confirmation.
class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  // Pearl white with a faint green tint, not the same bright green fill as
  // the onboarding reset dialog -- log out reads as a calmer, lighter
  // moment than a destructive reset. The shadow/border and the buttons all
  // share this one softer, tinted-green family instead of the app's usual
  // vivid green, so the whole card reads as one coherent palette -- a
  // deeper shade of the card's own pearl white, the same "flat shadow is a
  // darker tint of the card's own fill" convention used elsewhere (e.g.
  // SaveCard).
  static const _pearlWhite = Color(0xFFF4F9EE);
  static const _pearlShadow = Color(0xFFCFE0C2);
  static const _tintGreen = Color(0xFFA9D98E);
  static const _tintGreenDepth = Color(0xFF7CAD5F);
  // Labels softened to match: plain white reads too harsh on a pastel
  // button, and the app's usual vivid red is jarring against this calmer
  // palette -- a deep, muted version of each button's own hue instead.
  static const _tintGreenLabel = Color(0xFF3E6B2C);
  static const _softRed = Color(0xFFC9615F);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('me-logout-dialog'),
          width: 304,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          decoration: const BoxDecoration(
            color: _pearlWhite,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.fromBorderSide(
              BorderSide(color: _pearlShadow, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _pearlShadow,
                offset: Offset(0, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'log out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'balik ka sa main menu kag mag-log in liwat',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('me-logout-cancel-button'),
                      label: 'cancel',
                      height: 44,
                      fontSize: 14,
                      frontColor: _tintGreen,
                      depthColor: _tintGreenDepth,
                      labelColor: _tintGreenLabel,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('me-logout-confirm-button'),
                      label: 'log out',
                      height: 44,
                      fontSize: 14,
                      frontColor: _tintGreen,
                      depthColor: _tintGreenDepth,
                      labelColor: _softRed,
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
