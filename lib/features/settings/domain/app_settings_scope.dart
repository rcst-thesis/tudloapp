import 'package:flutter/widgets.dart';

import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/features/settings/domain/app_settings_repository.dart';

/// The [AppSettings] actually in effect right now: the signed-in learner's
/// own copy if one is signed in, otherwise the device-wide "main menu"
/// copy. For app-wide consumers (e.g. background music) that always want
/// "whichever settings currently apply," not `SettingsScreen`'s own
/// per-panel choice -- see that screen's `_readSettings` for the distinct
/// "am I editing the device-wide copy or a specific learner's" case, which
/// this deliberately doesn't replace.
AppSettings effectiveAppSettings(BuildContext context) =>
    LearnerScope.of(context).profile?.settings ??
    AppSettingsScope.of(context).settings;

/// Whether ambient/decorative motion should currently animate: off if the
/// OS's own "reduce motion" is on, the learner's "Ambient Animations"
/// toggle is off, or their performance-quality preset is Battery Saver
/// (which always strips ambient motion, independent of the toggle -- that
/// override is the whole point of the preset).
///
/// Consumed by every widget that runs a purely decorative, non-essential
/// animation loop (glow borders, ambient parallax/tilt, idle hint cues) --
/// see each call site for what it gates.
bool effectiveAmbientMotionEnabled(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return false;
  final settings = effectiveAppSettings(context);
  if (settings.performanceQuality == PerformanceQuality.batterySaver) {
    return false;
  }
  return settings.ambientAnimationsEnabled;
}

/// A stricter gate for the heaviest ambient effect specifically: the
/// continuously-looping native Rive state machine behind
/// `RiveAvatarBackground`. Only High Quality keeps that engine loop
/// running; Balanced already swaps to its cheaper flat-color fallback to
/// save the loop while every other ambient effect
/// ([effectiveAmbientMotionEnabled]) stays on.
bool effectiveHeavyAmbientMotionEnabled(BuildContext context) {
  if (!effectiveAmbientMotionEnabled(context)) return false;
  return effectiveAppSettings(context).performanceQuality ==
      PerformanceQuality.high;
}

/// The app's one device-wide [AppSettings] -- in effect whenever nobody is
/// signed in (the main menu), and what a brand new learner's own settings
/// are seeded from at creation (see `LearnerController.createAndSave`'s
/// `initialSettings` param). Same shape/best-effort-persist convention as
/// `LearnerController` (`lib/features/learner/domain/learner_scope.dart`).
class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    AppSettingsRepository repository = const AppSettingsRepository(),
  }) : _repository = repository;

  final AppSettingsRepository _repository;
  AppSettings _settings = AppSettings.defaults;

  AppSettings get settings => _settings;

  /// Loads whatever was last saved, if any. Safe to call even if nothing
  /// has ever been saved, or storage isn't available at all -- [settings]
  /// is just left at [AppSettings.defaults], same as a fresh install.
  Future<void> loadSaved() async {
    try {
      final loaded = await _repository.load();
      if (loaded == null) return;
      _settings = loaded;
      notifyListeners();
    } catch (_) {
      // Storage unavailable/corrupt: proceed with defaults rather than
      // crashing startup over it.
    }
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    try {
      await _repository.save(settings);
    } catch (_) {
      // Best-effort: the app keeps using the in-memory value either way.
    }
  }
}

/// Makes the app's one [AppSettingsController] available to every screen,
/// without threading it through navigation call sites. Same pattern as
/// `LearnerScope` (`lib/features/learner/domain/learner_scope.dart`).
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Returns the shared controller if one is above [context], otherwise a
  /// fresh standalone one with just [AppSettings.defaults] -- e.g. a
  /// widget test that pumps `SettingsScreen` inside a bare `MaterialApp`
  /// rather than the full `TudloApp` shell.
  static AppSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    return scope?.notifier ?? AppSettingsController();
  }
}
