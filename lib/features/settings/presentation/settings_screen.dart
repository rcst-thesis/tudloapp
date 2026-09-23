import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/motion/app_animation_controller.dart';
import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/placeholder/presentation/placeholder_screen.dart';
import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

/// Reads the *effective* [AppSettings] for a panel -- the current
/// learner's own copy while `insideLearnerProfile` is true and a learner
/// is actually signed in, otherwise the device-wide "main menu" copy. See
/// [SettingsScreen.insideLearnerProfile].
AppSettings _readSettings(BuildContext context, bool insideLearnerProfile) {
  if (insideLearnerProfile) {
    final profile = LearnerScope.of(context).profile;
    if (profile != null) return profile.settings;
  }
  return AppSettingsScope.of(context).settings;
}

/// Writes to whichever store [_readSettings] would currently read from.
Future<void> _writeSettings(
  BuildContext context,
  bool insideLearnerProfile,
  AppSettings settings,
) async {
  if (insideLearnerProfile) {
    final controller = LearnerScope.of(context);
    if (controller.profile != null) {
      await controller.updateSettings(settings);
      return;
    }
  }
  await AppSettingsScope.of(context).update(settings);
}

/// Same duration every accordion panel's own `AnimatedSize` uses -- kept
/// here too so [_scrollExpandedPanelIntoView] waits for that animation to
/// actually finish before measuring where to scroll to.
const _panelExpandDuration = Duration(milliseconds: 200);

/// Scrolls a just-expanded panel into view once its `AnimatedSize` finishes
/// growing, aligned so the *bottom* of the panel (not just its header)
/// ends up visible -- without this, expanding a panel near the bottom of
/// the list (Display & Performance, About) reveals content that's still
/// off-screen below the viewport, which reads as broken rather than as an
/// accordion opening.
Future<void> _scrollExpandedPanelIntoView(GlobalKey panelKey) async {
  await Future<void>.delayed(_panelExpandDuration);
  final panelContext = panelKey.currentContext;
  if (panelContext == null) return;
  // Freshly re-fetched from the key right above, not a stale context
  // carried across the gap -- the lint can't tell the two apart.
  await Scrollable.ensureVisible(
    // ignore: use_build_context_synchronously
    panelContext,
    alignment: 1,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );
  // The panel's RenderBox can still be mid-layout the instant
  // AnimatedSize's own animation reports "done" (this fires off a real
  // Future.delayed, not a frame callback), so the pass above can slightly
  // undershoot. A second, instant pass re-measures the now-settled size
  // and snaps the rest of the way if needed -- a no-op if the first pass
  // already nailed it.
  final settledContext = panelKey.currentContext;
  if (settledContext == null) return;
  await Scrollable.ensureVisible(
    // ignore: use_build_context_synchronously
    settledContext,
    alignment: 1,
  );
}

/// Settings' category picker -- Finch's calm minimalism (soft shadow, no
/// borders, generous white space, no icons/chevrons cluttering the row)
/// blended with Duolingo's playful per-category color personality (each
/// row's own title/subtitle hue, not one flat neutral palette). Just a
/// centered title and subtitle per row, nothing else. Every category --
/// General, Sound & Voice, Learning & Energy, Display & Performance, and
/// About -- expands in place (an accordion, not navigation); About's own
/// sub-items (Help/Privacy/Credits) still push their own
/// [PlaceholderScreen] since there's no real content for them yet.
class SettingsScreen extends StatelessWidget {
  /// [insideLearnerProfile] is set by the *caller* (true from Home/Me,
  /// left false from the main menu) rather than inferred from whether a
  /// learner profile happens to be loaded -- a profile can already be
  /// loaded in memory (e.g. restored on app startup so the main menu can
  /// offer "continue") while the learner hasn't actually entered their
  /// profile yet, so `LearnerScope.of(context).profile != null` alone
  /// can't tell the two situations apart.
  const SettingsScreen({this.insideLearnerProfile = false, super.key});

  final bool insideLearnerProfile;

  static const _backgroundColor = Color(0xFFABE6AF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        // Align(topCenter), not Center -- Center also centers *vertically*,
        // and SingleChildScrollView shrink-wraps to its content's height
        // when given loose constraints. With every panel collapsed (the
        // shortest the content ever gets), that combination floated the
        // whole column -- back button included -- toward the vertical
        // middle of the screen instead of sitting at the top where it
        // belongs. Horizontal centering (for wide windows) is all that was
        // ever intended here.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            // A plain scrolling column, not IntrinsicHeight+Spacer --
            // that combination doesn't cope with General's
            // expand/collapse changing the content's height at
            // runtime (Expanded/Spacer sizing conflicts with
            // intrinsic-height measurement, which caused a real
            // overflow once General was expandable). "About" just
            // follows after a larger, fixed gap instead of being
            // flex-pinned to the bottom of the viewport.
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scrolls away with the rest of the content (like Me
                  // screen's own settings button -- me_screen.dart), not a
                  // fixed Stack overlay. The *width* half of the scale has
                  // to come from *this* LayoutBuilder's own constrained
                  // width, not raw MediaQuery -- this widget already lives
                  // inside the ConstrainedBox(maxWidth: 420) above, so on
                  // any window wider than 420 a MediaQuery-based width
                  // scale would drift away from where the actual centered
                  // content starts (exactly the "not glued" bug). Height
                  // *is* unbounded inside a scroll view though, so that half
                  // comes from MediaQuery's safe-area-adjusted height
                  // instead, matching the min(widthScale, heightScale) that
                  // AdaptiveBackButtonPlacement uses on the onboarding Name
                  // screen -- keeping this button the same scale as that one.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final mediaPadding = MediaQuery.paddingOf(context);
                      final availableHeight =
                          MediaQuery.sizeOf(context).height -
                          mediaPadding.top -
                          mediaPadding.bottom;
                      final widthScale = constraints.maxWidth / 412;
                      final heightScale = availableHeight / 917;
                      final scale = widthScale < heightScale
                          ? widthScale
                          : heightScale;
                      final left = (27 * scale).clamp(16.0, 32.0);
                      final top = (51 * scale).clamp(16.0, 32.0);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(left, top, 0, 40),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: 93 * scale,
                            height: 44 * scale,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: LoadBackButton(
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Choose a category to make Koka feel just '
                          'right.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF638E6B),
                            fontFamily: 'ComicRelief',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _GeneralSettingsPanel(
                          key: const Key('settings-category-general'),
                          insideLearnerProfile: insideLearnerProfile,
                        ),
                        const SizedBox(height: 10),
                        _SoundVoicePanel(
                          key: const Key('settings-category-sound-voice'),
                          insideLearnerProfile: insideLearnerProfile,
                        ),
                        const SizedBox(height: 10),
                        _LearningEnergyPanel(
                          key: const Key('settings-category-learning-energy'),
                          enabled: insideLearnerProfile,
                        ),
                        const SizedBox(height: 10),
                        _DisplayPerformancePanel(
                          key: const Key(
                            'settings-category-display-performance',
                          ),
                          insideLearnerProfile: insideLearnerProfile,
                        ),
                        const SizedBox(height: 200),
                        const _AboutPanel(key: Key('settings-category-about')),
                      ],
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

/// General expands in place (an accordion, not a navigation push) to
/// reveal the language picker -- every category is now an in-place
/// accordion (see [_AboutPanel] for the last one to convert). The language
/// itself reads/writes
/// [_readSettings]/[_writeSettings] (device-wide from the main menu,
/// per-learner once signed in) rather than local state, so it actually
/// persists.
class _GeneralSettingsPanel extends StatefulWidget {
  const _GeneralSettingsPanel({required this.insideLearnerProfile, super.key});

  final bool insideLearnerProfile;

  @override
  State<_GeneralSettingsPanel> createState() => _GeneralSettingsPanelState();
}

class _GeneralSettingsPanelState extends State<_GeneralSettingsPanel> {
  static const _depthColor = Color(0xFF9DBE93);
  static const _restLift = 4.0;
  static const _radius = 13.0;

  final _panelKey = GlobalKey();
  var _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) unawaited(_scrollExpandedPanelIntoView(_panelKey));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _readSettings(context, widget.insideLearnerProfile);

    return DecoratedBox(
      key: _panelKey,
      decoration: const BoxDecoration(
        color: _depthColor,
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: _restLift),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                splashFactory: NoSplash.splashFactory,
                highlightColor: const Color(0xFF448759).withValues(alpha: 0.06),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'General',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF448759),
                          fontFamily: 'ComicRelief',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Language preferences',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B9B6D),
                          fontFamily: 'ComicRelief',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Language',
                              style: TextStyle(
                                color: Color(0xFF448759),
                                fontFamily: 'ComicRelief',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDEFD3),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _LanguageSegment(
                                        key: const Key(
                                          'settings-language-hiligaynon',
                                        ),
                                        label: 'Hiligaynon',
                                        selected:
                                            settings.language ==
                                            AppLanguage.hiligaynon,
                                        onTap: () => _writeSettings(
                                          context,
                                          widget.insideLearnerProfile,
                                          settings.copyWith(
                                            language: AppLanguage.hiligaynon,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: _LanguageSegment(
                                        key: const Key(
                                          'settings-language-english',
                                        ),
                                        label: 'English',
                                        selected:
                                            settings.language ==
                                            AppLanguage.english,
                                        onTap: () => _writeSettings(
                                          context,
                                          widget.insideLearnerProfile,
                                          settings.copyWith(
                                            language: AppLanguage.english,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF68AA59) : Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFFFFCF4)
                    : const Color(0xFF518454),
                fontFamily: 'ComicRelief',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sound & Voice expands in place to reveal a master volume slider plus a
/// mute toggle + volume slider per audio channel. The shared audio controller
/// applies music and narration values, gates native button clicks, and the
/// values persist through [_readSettings]/[_writeSettings].
class _SoundVoicePanel extends StatefulWidget {
  const _SoundVoicePanel({required this.insideLearnerProfile, super.key});

  final bool insideLearnerProfile;

  @override
  State<_SoundVoicePanel> createState() => _SoundVoicePanelState();
}

class _SoundVoicePanelState extends State<_SoundVoicePanel> {
  static const _depthColor = Color(0xFF9DBE93);
  static const _restLift = 4.0;
  static const _radius = 13.0;

  final _panelKey = GlobalKey();
  var _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) unawaited(_scrollExpandedPanelIntoView(_panelKey));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: _panelKey,
      decoration: const BoxDecoration(
        color: _depthColor,
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: _restLift),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                splashFactory: NoSplash.splashFactory,
                highlightColor: const Color(0xFFAD6B30).withValues(alpha: 0.06),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Sound & Voice',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFAD6B30),
                          fontFamily: 'ComicRelief',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Music, effects, and spoken guidance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9E7F4F),
                          fontFamily: 'ComicRelief',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded
                    ? _buildExpandedContent()
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final settings = _readSettings(context, widget.insideLearnerProfile);
    void write(AppSettings updated) =>
        _writeSettings(context, widget.insideLearnerProfile, updated);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Master Volume',
                  style: TextStyle(
                    color: Color(0xFF846033),
                    fontFamily: 'ComicRelief',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${settings.masterVolume.round()}%',
                style: const TextStyle(
                  color: Color(0xFF568E4F),
                  fontFamily: 'ComicRelief',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _VolumeSlider(
            key: const Key('settings-master-volume-slider'),
            value: settings.masterVolume,
            onChanged: (value) => write(settings.copyWith(masterVolume: value)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Controls all Koka audio',
            style: TextStyle(
              color: Color(0xFF8E774F),
              fontFamily: 'ComicRelief',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _AudioChannelRow(
            key: const Key('settings-channel-music'),
            toggleKey: const Key('settings-channel-music-toggle'),
            label: 'Background Music',
            enabled: settings.musicEnabled,
            volume: settings.musicVolume,
            onEnabledChanged: (value) =>
                write(settings.copyWith(musicEnabled: value)),
            onVolumeChanged: (value) =>
                write(settings.copyWith(musicVolume: value)),
          ),
          const SizedBox(height: 16),
          _AudioChannelRow(
            key: const Key('settings-channel-sfx'),
            toggleKey: const Key('settings-channel-sfx-toggle'),
            label: 'Sound Effects',
            enabled: settings.sfxEnabled,
            volume: settings.sfxVolume,
            onEnabledChanged: (value) =>
                write(settings.copyWith(sfxEnabled: value)),
            onVolumeChanged: (value) =>
                write(settings.copyWith(sfxVolume: value)),
            hint: 'Button clicks use the app sound-effect level.',
          ),
          const SizedBox(height: 16),
          _AudioChannelRow(
            key: const Key('settings-channel-voice'),
            toggleKey: const Key('settings-channel-voice-toggle'),
            label: 'Voice-over',
            enabled: settings.voiceEnabled,
            volume: settings.voiceVolume,
            onEnabledChanged: (value) =>
                write(settings.copyWith(voiceEnabled: value)),
            onVolumeChanged: (value) =>
                write(settings.copyWith(voiceVolume: value)),
          ),
        ],
      ),
    );
  }
}

class _AudioChannelRow extends StatelessWidget {
  const _AudioChannelRow({
    required this.label,
    required this.enabled,
    required this.volume,
    required this.onEnabledChanged,
    required this.onVolumeChanged,
    this.hint,
    this.toggleKey,
    super.key,
  });

  final String label;
  final bool enabled;
  final double volume;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<double> onVolumeChanged;
  final String? hint;

  /// Key on the actual mute toggle, not this whole row -- the row's own
  /// bounds also cover the label and the volume slider below it.
  final Key? toggleKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF846033),
                  fontFamily: 'ComicRelief',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              enabled ? 'On' : 'Muted',
              style: TextStyle(
                color: enabled
                    ? const Color(0xFF568E4F)
                    : const Color(0xFF63704F),
                fontFamily: 'ComicRelief',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            _MuteToggle(
              key: toggleKey,
              value: enabled,
              onChanged: onEnabledChanged,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _VolumeSlider(value: volume, onChanged: onVolumeChanged),
        if (hint case final text?) ...[
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8E774F),
              fontFamily: 'ComicRelief',
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

/// A pill switch matching the app's Duolingo-ish flat style, not Material's
/// default oval [Switch] -- used app-wide wherever a mute/enable toggle
/// needs to look related to the custom [_VolumeSlider]s. [onColor]
/// defaults to the standard green but can be overridden -- e.g. Display &
/// Performance's "Halt Animations" uses a terracotta "on" color instead,
/// since it reads as a caution/stop action rather than a normal enable
/// switch.
class _MuteToggle extends StatelessWidget {
  const _MuteToggle({
    required this.value,
    required this.onChanged,
    this.onColor = _defaultOnColor,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color onColor;

  static const _defaultOnColor = Color(0xFF4F893A);
  static const _offColor = Color(0xFFD8D3C4);
  static const _thumbColor = Color(0xFFFCFCF4);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: value ? onColor : _offColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (value ? onColor : _offColor).withValues(alpha: 0.3),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: _thumbColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x2D1E3816),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: SizedBox(width: 24, height: 24),
          ),
        ),
      ),
    );
  }
}

/// The pill-shaped volume slider from the reference design -- built on
/// Flutter's own [Slider] (real drag/tap/keyboard handling for free)
/// rather than a hand-rolled gesture detector, just re-skinned via
/// [SliderTheme] and a custom thumb shape to match.
class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F9E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBCDBAD)),
      ),
      child: SliderTheme(
        data: const SliderThemeData(
          trackHeight: 16,
          activeTrackColor: Color(0xFF66AA56),
          inactiveTrackColor: Color(0xFFC9E5BA),
          thumbShape: _VolumeThumbShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
        ),
        child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
      ),
    );
  }
}

class _VolumeThumbShape extends SliderComponentShape {
  const _VolumeThumbShape();

  static const _radius = 15.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Same flat offset-shadow convention as the rest of the app -- a
    // solid circle behind, not a blurred Material shadow.
    canvas.drawCircle(
      center + const Offset(0, 3),
      _radius,
      Paint()..color = const Color(0x6B518444),
    );
    canvas.drawCircle(
      center,
      _radius,
      Paint()..color = const Color(0xFFFFFCF4),
    );
    canvas.drawCircle(
      center,
      _radius - 1,
      Paint()
        ..color = const Color(0xFF569949)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// Learning & Energy expands in place to reveal the energy summary, a
/// lesson-reminders toggle, and a reset action. Same "real UI, not-yet-real
/// backend" honesty as General/Sound & Voice -- there's no lesson-progress
/// store to wire the toggle or the reset into yet, so both are local widget
/// state; reset still confirms first, matching the app's other destructive
/// actions (e.g. the learner reset dialog, the Me screen's logout dialog).
class _LearningEnergyPanel extends StatefulWidget {
  const _LearningEnergyPanel({required this.enabled, super.key});

  /// Whether the caller is inside the learner's own profile (Home/Me) as
  /// opposed to the main menu -- see [SettingsScreen.insideLearnerProfile].
  final bool enabled;

  @override
  State<_LearningEnergyPanel> createState() => _LearningEnergyPanelState();
}

class _LearningEnergyPanelState extends State<_LearningEnergyPanel> {
  static const _depthColor = Color(0xFF9DBE93);
  static const _restLift = 4.0;
  static const _radius = 13.0;

  final _panelKey = GlobalKey();
  var _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) unawaited(_scrollExpandedPanelIntoView(_panelKey));
  }

  Future<void> _confirmReset() async {
    // Wiping progress is just as much a parent decision as changing the
    // energy level -- same gate, same reasoning, before the reset
    // confirmation ever shows up.
    final passedGate = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGateDialog(),
    );
    if (!mounted || !(passedGate ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ResetLessonProgressDialog(),
    );
    if (confirmed ?? false) {
      // No lesson-progress store exists yet to actually clear -- this is
      // the same placeholder honesty as the rest of this panel.
    }
  }

  /// Changing how much a child can learn in a day is a parent decision,
  /// not a tap a curious kid should be able to make by themselves -- the
  /// math challenge (same idea as the "parental gate" pattern other kids'
  /// apps use before purchases/external links) has to be answered first,
  /// every time, before the actual energy editor ever shows up.
  Future<void> _changeEnergy() async {
    final passedGate = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGateDialog(),
    );
    if (!mounted || !(passedGate ?? false)) return;

    final controller = LearnerScope.of(context);
    final newEnergy = await showDialog<int>(
      context: context,
      builder: (_) =>
          _EnergyEditorDialog(initialEnergy: controller.profile?.energy ?? 60),
    );
    if (newEnergy == null) return;
    await controller.setEnergy(newEnergy);
  }

  @override
  Widget build(BuildContext context) {
    // Energy/reminders/progress only mean anything once the learner has
    // actually entered their profile (Home/Me) -- from the main menu this
    // panel is visible but inert, dimmed the same way Home's "retry" dims
    // an unavailable action (home_lesson_preview_dialog.dart), and its
    // subtitle says why instead of just refusing the tap silently.
    final hasProfile = widget.enabled;
    final expanded = _expanded && hasProfile;

    return Opacity(
      opacity: hasProfile ? 1 : 0.45,
      child: DecoratedBox(
        key: _panelKey,
        decoration: const BoxDecoration(
          color: _depthColor,
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: _restLift),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: hasProfile ? _toggleExpanded : null,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: const Color(
                    0xFF609347,
                  ).withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Learning & Energy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF609347),
                            fontFamily: 'ComicRelief',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasProfile
                              ? 'Energy, reminders, and progress'
                              : 'Log in to a profile to unlock this',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF779B5B),
                            fontFamily: 'ComicRelief',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: expanded
                      ? _buildExpandedContent()
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final learnerController = LearnerScope.of(context);
    final profile = learnerController.profile;
    final energy = profile?.effectiveEnergy() ?? 60;
    // Same formula home_lesson_panel.dart's `_availableLessons` uses --
    // this text is a preview of the exact cap Home enforces, not an
    // independent number.
    final lessons = (energy.clamp(0, 60) ~/ 10).clamp(0, 6);
    final remindersEnabled =
        profile?.settings.lessonRemindersEnabled ??
        AppSettings.defaults.lessonRemindersEnabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Koka Energy · $energy% · Up to $lessons lessons',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5B9144),
              fontFamily: 'ComicRelief',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Parent controlled',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A9E60),
              fontFamily: 'ComicRelief',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // The app's standard StickerPressButton, not a flat pill -- same
          // width/height as the Lesson Reminders row below (52 = its 10px
          // vertical padding either side of the 32px mute toggle), and
          // its own fill/border colors reused as the button's front/depth
          // so the two rows read as one matching pair.
          SizedBox(
            width: double.infinity,
            child: StickerPressButton(
              key: const Key('settings-change-energy'),
              label: 'Change Energy Level',
              height: 52,
              fontSize: 15,
              borderRadius: 14,
              frontColor: const Color(0xFFEFF9E8),
              depthColor: const Color(0xFFD6EDCC),
              labelColor: const Color(0xFF335428),
              onPressed: _changeEnergy,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF9E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6EDCC)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lesson Reminders',
                    style: TextStyle(
                      color: Color(0xFF335428),
                      fontFamily: 'ComicRelief',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _MuteToggle(
                    key: const Key('settings-lesson-reminders-toggle'),
                    value: remindersEnabled,
                    onChanged: (value) => learnerController.updateSettings(
                      (profile?.settings ?? AppSettings.defaults).copyWith(
                        lessonRemindersEnabled: value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('settings-reset-lesson-progress'),
                onTap: _confirmReset,
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    'Reset Lesson Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFAD6B3D),
                      fontFamily: 'ComicRelief',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog for the destructive "Reset Lesson Progress" action,
/// styled identically to the Me screen's `_LogoutConfirmationDialog` --
/// this app's established pattern for a pearl-white/tint-green confirm
/// dialog, muted-red only on the label of the destructive action.
class _ResetLessonProgressDialog extends StatelessWidget {
  const _ResetLessonProgressDialog();

  static const _pearlWhite = Color(0xFFF4F9EE);
  static const _pearlShadow = Color(0xFFCFE0C2);
  static const _tintGreen = Color(0xFFA9D98E);
  static const _tintGreenDepth = Color(0xFF7CAD5F);
  static const _tintGreenLabel = Color(0xFF3E6B2C);
  static const _softRed = Color(0xFFC9615F);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('settings-reset-lesson-progress-dialog'),
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
                'reset lesson progress?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'mawala ang tanan nga nahuman nga leksyon kag indi na '
                'ma-undo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('settings-reset-lesson-cancel-button'),
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
                      key: const Key('settings-reset-lesson-confirm-button'),
                      label: 'reset',
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

/// A simple math challenge gating "Change Energy Level" -- the same
/// "parental gate" idea other kids' apps use before a purchase or an
/// external link: nothing a young child can brute-force by tapping, but
/// no real barrier to an adult. Answering wrong just says so and lets you
/// try again, no lockout -- the goal is to require a moment of adult
/// arithmetic, not to punish a wrong tap.
class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  static const _pearlWhite = Color(0xFFF4F9EE);
  static const _pearlShadow = Color(0xFFCFE0C2);
  static const _tintGreen = Color(0xFFA9D98E);
  static const _tintGreenDepth = Color(0xFF7CAD5F);
  static const _tintGreenLabel = Color(0xFF3E6B2C);
  static const _softRed = Color(0xFFC9615F);

  final _answerController = TextEditingController();
  late final int _a;
  late final int _b;
  var _wrong = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    // 6-9 x 6-9 -- two-digit products a grade-school reader can't usually
    // do at a glance, but any adult can in a second or two.
    _a = 6 + random.nextInt(4);
    _b = 6 + random.nextInt(4);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = int.tryParse(_answerController.text);
    if (answer == _a * _b) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _wrong = true);
    _answerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('settings-parent-gate-dialog'),
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
                'parents only',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'answer this to change the energy level',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 16),
              Text(
                'What is $_a × $_b?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('settings-parent-gate-input'),
                controller: _answerController,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: _pearlWhite,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _pearlShadow,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _tintGreenDepth,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_wrong) ...[
                const SizedBox(height: 8),
                const Text(
                  'not quite -- try again',
                  style: TextStyle(
                    color: _softRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('settings-parent-gate-cancel-button'),
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
                      key: const Key('settings-parent-gate-continue-button'),
                      label: 'continue',
                      height: 44,
                      fontSize: 14,
                      frontColor: _tintGreen,
                      depthColor: _tintGreenDepth,
                      labelColor: _tintGreenLabel,
                      onPressed: _submit,
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

/// The actual energy editor -- only ever reached after [_ParentGateDialog]
/// passes. Same 10-100, 10%-step range as onboarding's energy setter
/// (`energy_setter_screen.dart`), so a value picked here means the same
/// thing everywhere else in the app that reads it.
class _EnergyEditorDialog extends StatefulWidget {
  const _EnergyEditorDialog({required this.initialEnergy});

  final int initialEnergy;

  @override
  State<_EnergyEditorDialog> createState() => _EnergyEditorDialogState();
}

class _EnergyEditorDialogState extends State<_EnergyEditorDialog> {
  static const _pearlWhite = Color(0xFFF4F9EE);
  static const _pearlShadow = Color(0xFFCFE0C2);
  static const _tintGreen = Color(0xFFA9D98E);
  static const _tintGreenDepth = Color(0xFF7CAD5F);
  static const _tintGreenLabel = Color(0xFF3E6B2C);

  late var _energy = (widget.initialEnergy / 10).round() * 10;

  void _adjust(int delta) {
    setState(() => _energy = (_energy + delta).clamp(10, 100));
  }

  @override
  Widget build(BuildContext context) {
    final lessons = (_energy.clamp(0, 60) ~/ 10).clamp(0, 6);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('settings-energy-editor-dialog'),
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
                'change energy level',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'how many lessons can Koka unlock in a day?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepButton(
                    key: const Key('settings-energy-minus-button'),
                    label: '−',
                    enabled: _energy > 10,
                    onTap: () => _adjust(-10),
                  ),
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        Text(
                          '$_energy%',
                          key: const Key('settings-energy-value'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _tintGreenLabel,
                          ),
                        ),
                        Text(
                          'Up to $lessons lessons',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _StepButton(
                    key: const Key('settings-energy-plus-button'),
                    label: '+',
                    enabled: _energy < 100,
                    onTap: () => _adjust(10),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('settings-energy-cancel-button'),
                      label: 'cancel',
                      height: 44,
                      fontSize: 14,
                      frontColor: _tintGreen,
                      depthColor: _tintGreenDepth,
                      labelColor: _tintGreenLabel,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StickerPressButton(
                      key: const Key('settings-energy-save-button'),
                      label: 'save',
                      height: 44,
                      fontSize: 14,
                      frontColor: _tintGreen,
                      depthColor: _tintGreenDepth,
                      labelColor: _tintGreenLabel,
                      onPressed: () => Navigator.pop(context, _energy),
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

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: StickerPressButton(
        label: label,
        fontSize: 22,
        frontColor: const Color(0xFFA9D98E),
        depthColor: const Color(0xFF7CAD5F),
        labelColor: const Color(0xFF3E6B2C),
        enabled: enabled,
        onPressed: onTap,
      ),
    );
  }
}

/// Display & Performance expands in place like the other panels. "Halt
/// Animations" is wired to the app's one real animation flag
/// (`AppAnimationScope` -- previously this screen's whole reason for
/// existing), inverted since halting is the opposite of enabling --
/// deliberately untouched by the [_readSettings]/[_writeSettings] split
/// below, since it's already a real, long-lived, device-wide control with
/// no per-learner concept. "Ambient Animations" and the quality tier
/// picker go through [_readSettings]/[_writeSettings] to persist, *and*
/// are real: every purely-decorative animation loop in the app (glow
/// borders, ambient parallax/tilt, idle hint cues, the learner card's
/// holofoil/rotating-rays, and the Rive avatar background) reads them
/// back via `effectiveAmbientMotionEnabled`/
/// `effectiveHeavyAmbientMotionEnabled` (`app_settings_scope.dart`) --
/// Battery Saver always turns them off, Balanced additionally swaps the
/// Rive avatar background (the one continuously-looping native engine
/// state machine among them) to its flat-color fallback, and the toggle
/// is a manual master switch independent of tier.
class _DisplayPerformancePanel extends StatefulWidget {
  const _DisplayPerformancePanel({
    required this.insideLearnerProfile,
    super.key,
  });

  final bool insideLearnerProfile;

  @override
  State<_DisplayPerformancePanel> createState() =>
      _DisplayPerformancePanelState();
}

class _DisplayPerformancePanelState extends State<_DisplayPerformancePanel> {
  static const _depthColor = Color(0xFF9DBE93);
  static const _restLift = 4.0;
  static const _radius = 13.0;

  final _panelKey = GlobalKey();
  var _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) unawaited(_scrollExpandedPanelIntoView(_panelKey));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: _panelKey,
      decoration: const BoxDecoration(
        color: _depthColor,
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: _restLift),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                splashFactory: NoSplash.splashFactory,
                highlightColor: const Color(0xFF548E9E).withValues(alpha: 0.06),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Display & Performance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF548E9E),
                          fontFamily: 'ComicRelief',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Motion and device-friendly visuals',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6DA0AA),
                          fontFamily: 'ComicRelief',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded
                    ? _buildExpandedContent()
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final animationController = AppAnimationScope.of(context);
    final settings = _readSettings(context, widget.insideLearnerProfile);
    void write(AppSettings updated) =>
        _writeSettings(context, widget.insideLearnerProfile, updated);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TogglePillRow(
            label: 'Ambient Animations',
            value: settings.ambientAnimationsEnabled,
            toggleKey: const Key('settings-ambient-animations-toggle'),
            onChanged: (value) =>
                write(settings.copyWith(ambientAnimationsEnabled: value)),
          ),
          const SizedBox(height: 10),
          _TogglePillRow(
            label: 'Halt Animations',
            value: !animationController.isEnabled,
            toggleKey: const Key('settings-animation-switch'),
            onColor: const Color(0xFFC67059),
            onChanged: (halt) => animationController.setEnabled(!halt),
          ),
          const SizedBox(height: 14),
          _QualityOption(
            key: const Key('settings-quality-high'),
            title: 'High Quality',
            subtitle: 'Best visuals · uses more battery',
            selected: settings.performanceQuality == PerformanceQuality.high,
            onTap: () => write(
              settings.copyWith(performanceQuality: PerformanceQuality.high),
            ),
          ),
          const SizedBox(height: 8),
          _QualityOption(
            key: const Key('settings-quality-balanced'),
            title: 'Balanced',
            subtitle: 'Smooth play for most devices',
            selected:
                settings.performanceQuality == PerformanceQuality.balanced,
            onTap: () => write(
              settings.copyWith(
                performanceQuality: PerformanceQuality.balanced,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _QualityOption(
            key: const Key('settings-quality-battery-saver'),
            title: 'Battery Saver',
            subtitle: 'Less effects · saves battery',
            selected:
                settings.performanceQuality == PerformanceQuality.batterySaver,
            onTap: () => write(
              settings.copyWith(
                performanceQuality: PerformanceQuality.batterySaver,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Ambient Animations"/"Halt Animations" pill row -- same
/// bg/border/pill shape the Lesson Reminders row established, reused here
/// since both are just "label + [_MuteToggle]" rows.
class _TogglePillRow extends StatelessWidget {
  const _TogglePillRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.toggleKey,
    this.onColor,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key toggleKey;
  final Color? onColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6EDCC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF335428),
                  fontFamily: 'ComicRelief',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _MuteToggle(
              key: toggleKey,
              value: value,
              onColor: onColor ?? const Color(0xFF4F893A),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the quality-tier picker -- a 3-way radio choice, not
/// independent toggles, so selecting one deselects the others.
class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFF68AA59);
  static const _selectedBorder = Color(0xFF519147);
  static const _unselectedColor = Color(0xFFEFF7E8);
  static const _unselectedBorder = Color(0xFFC4DDB7);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? _selectedColor : _unselectedColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _selectedBorder : _unselectedBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(color: Color(0x66518947), offset: Offset(0, 3)),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFFFFCF4)
                          : const Color(0xFF4F7FA8),
                      fontFamily: 'ComicRelief',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFEFF9E8)
                          : const Color(0xFF6D99AF),
                      fontFamily: 'ComicRelief',
                      fontSize: 12,
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

/// About expands in place like the other panels. Its own sub-items (About
/// Toadlu/Help/Privacy/Credits) have no real content yet, so each still
/// pushes a [PlaceholderScreen] -- the last of the app-vs-navigation
/// distinction this file's class doc mentions. "Version 3 Alpha" is a
/// plain version stamp, not a link, so it's the one row here without an
/// [InkWell].
class _AboutPanel extends StatefulWidget {
  const _AboutPanel({super.key});

  @override
  State<_AboutPanel> createState() => _AboutPanelState();
}

class _AboutPanelState extends State<_AboutPanel> {
  static const _depthColor = Color(0xFF9DBE93);
  static const _restLift = 4.0;
  static const _radius = 13.0;
  static const _titleColor = Color(0xFF966344);

  final _panelKey = GlobalKey();
  var _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) unawaited(_scrollExpandedPanelIntoView(_panelKey));
  }

  void _openPlaceholder(String title) {
    Navigator.of(context).push(
      FadePageRoute<void>(
        page: PlaceholderScreen(
          title: title,
          description: 'Help, privacy, and credits',
          icon: Icons.info_outline_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: _panelKey,
      decoration: const BoxDecoration(
        color: _depthColor,
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: _restLift),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                splashFactory: NoSplash.splashFactory,
                highlightColor: _titleColor.withValues(alpha: 0.06),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'About',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _titleColor,
                          fontFamily: 'ComicRelief',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Help, privacy, and credits',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFA87C5E),
                          fontFamily: 'ComicRelief',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded
                    ? _buildExpandedContent()
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          _AboutLink(
            key: const Key('settings-about-toadlu'),
            label: 'About Toadlu',
            onTap: () => _openPlaceholder('About Toadlu'),
          ),
          const SizedBox(height: 9),
          _AboutLink(
            key: const Key('settings-about-help'),
            label: 'Help',
            onTap: () => _openPlaceholder('Help'),
          ),
          const SizedBox(height: 9),
          _AboutLink(
            key: const Key('settings-about-privacy'),
            label: 'Privacy',
            onTap: () => _openPlaceholder('Privacy'),
          ),
          const SizedBox(height: 9),
          _AboutLink(
            key: const Key('settings-about-credits'),
            label: 'Credits',
            onTap: () => _openPlaceholder('Credits'),
          ),
          const SizedBox(height: 9),
          const Text(
            'Version 3 Alpha',
            key: Key('settings-about-version'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleColor,
              fontFamily: 'ComicRelief',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLink extends StatelessWidget {
  const _AboutLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  static const _color = Color(0xFF966344);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: _color.withValues(alpha: 0.06),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _color,
                fontFamily: 'ComicRelief',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
