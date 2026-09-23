/// The shared language options General's picker offers.
enum AppLanguage { hiligaynon, english }

/// The three tiers Display & Performance's quality picker offers.
enum PerformanceQuality { high, balanced, batterySaver }

/// Every Settings value that needs the app's two-tier persistence: a
/// device-wide "main menu" copy (`AppSettingsRepository`/
/// `AppSettingsController`) for when nobody is signed in, and a per-learner
/// copy (`LearnerProfile.settings`) that overrides it once someone logs
/// in. Deliberately excludes `LearnerProfile.energy` (already
/// learner-only, gated behind the parent gate) and the app-wide animation
/// on/off flag (`AppAnimationController`, already a real, long-lived
/// controller with no per-learner concept).
///
/// [ambientAnimationsEnabled] and [performanceQuality] are consumed via
/// `effectiveAmbientMotionEnabled`/`effectiveHeavyAmbientMotionEnabled`
/// (`app_settings_scope.dart`), not read directly -- see those for the
/// actual on/off rules each ambient effect follows.
class AppSettings {
  const AppSettings({
    required this.language,
    required this.masterVolume,
    required this.musicEnabled,
    required this.musicVolume,
    required this.sfxEnabled,
    required this.sfxVolume,
    required this.voiceEnabled,
    required this.voiceVolume,
    required this.ambientAnimationsEnabled,
    required this.performanceQuality,
    required this.lessonRemindersEnabled,
  });

  /// The values every Settings panel showed before this feature existed --
  /// what a brand new install (or a save from before this field existed)
  /// falls back to.
  static const defaults = AppSettings(
    language: AppLanguage.hiligaynon,
    masterVolume: 80,
    musicEnabled: true,
    musicVolume: 80,
    sfxEnabled: true,
    sfxVolume: 80,
    voiceEnabled: true,
    voiceVolume: 80,
    ambientAnimationsEnabled: true,
    performanceQuality: PerformanceQuality.balanced,
    lessonRemindersEnabled: true,
  );

  final AppLanguage language;
  final double masterVolume;
  final bool musicEnabled;
  final double musicVolume;
  final bool sfxEnabled;
  final double sfxVolume;
  final bool voiceEnabled;
  final double voiceVolume;
  final bool ambientAnimationsEnabled;
  final PerformanceQuality performanceQuality;
  final bool lessonRemindersEnabled;

  AppSettings copyWith({
    AppLanguage? language,
    double? masterVolume,
    bool? musicEnabled,
    double? musicVolume,
    bool? sfxEnabled,
    double? sfxVolume,
    bool? voiceEnabled,
    double? voiceVolume,
    bool? ambientAnimationsEnabled,
    PerformanceQuality? performanceQuality,
    bool? lessonRemindersEnabled,
  }) {
    return AppSettings(
      language: language ?? this.language,
      masterVolume: masterVolume ?? this.masterVolume,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      ambientAnimationsEnabled:
          ambientAnimationsEnabled ?? this.ambientAnimationsEnabled,
      performanceQuality: performanceQuality ?? this.performanceQuality,
      lessonRemindersEnabled:
          lessonRemindersEnabled ?? this.lessonRemindersEnabled,
    );
  }

  Map<String, Object?> toJson() => {
    'language': language.name,
    'masterVolume': masterVolume,
    'musicEnabled': musicEnabled,
    'musicVolume': musicVolume,
    'sfxEnabled': sfxEnabled,
    'sfxVolume': sfxVolume,
    'voiceEnabled': voiceEnabled,
    'voiceVolume': voiceVolume,
    'ambientAnimationsEnabled': ambientAnimationsEnabled,
    'performanceQuality': performanceQuality.name,
    'lessonRemindersEnabled': lessonRemindersEnabled,
  };

  /// Tolerant of a missing or corrupt field -- falls back to [defaults]'
  /// own value for that field rather than failing the whole parse, same
  /// style as `LearnerProfile.fromJson`'s optional fields.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    AppLanguage language;
    try {
      language = AppLanguage.values.byName(json['language']! as String);
    } catch (_) {
      language = defaults.language;
    }
    PerformanceQuality performanceQuality;
    try {
      performanceQuality = PerformanceQuality.values.byName(
        json['performanceQuality']! as String,
      );
    } catch (_) {
      performanceQuality = defaults.performanceQuality;
    }
    return AppSettings(
      language: language,
      masterVolume:
          (json['masterVolume'] as num?)?.toDouble() ?? defaults.masterVolume,
      musicEnabled: json['musicEnabled'] as bool? ?? defaults.musicEnabled,
      musicVolume:
          (json['musicVolume'] as num?)?.toDouble() ?? defaults.musicVolume,
      sfxEnabled: json['sfxEnabled'] as bool? ?? defaults.sfxEnabled,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? defaults.sfxVolume,
      voiceEnabled: json['voiceEnabled'] as bool? ?? defaults.voiceEnabled,
      voiceVolume:
          (json['voiceVolume'] as num?)?.toDouble() ?? defaults.voiceVolume,
      ambientAnimationsEnabled:
          json['ambientAnimationsEnabled'] as bool? ??
          defaults.ambientAnimationsEnabled,
      performanceQuality: performanceQuality,
      lessonRemindersEnabled:
          json['lessonRemindersEnabled'] as bool? ??
          defaults.lessonRemindersEnabled,
    );
  }
}
