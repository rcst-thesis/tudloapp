/// The production audio assets currently bundled with Tudlo.
abstract final class TudloAudioAssets {
  static const maralSplashSting = 'assets/audio/maral_splash.wav';
  static const backgroundMusic = 'assets/audio/background_music.wav';
  static const loadScreenVoiceOver = 'assets/audio/vo_load_screen.wav';
  static const loadConfirmationVoiceOver =
      'assets/audio/vo_load_confirmation.wav';
  static const deleteConfirmationVoiceOver =
      'assets/audio/vo_delete_confirmation.wav';
  static const nameScreenVoiceOver = 'assets/audio/vo_name_screen.wav';
  static const gradeLevelIntroVoiceOver =
      'assets/audio/vo_grade_level_intro.wav';
  static const grade1CardVoiceOver = 'assets/audio/vo_grade_1_card.wav';
  static const grade2CardVoiceOver = 'assets/audio/vo_grade_2_card.wav';
  static const grade3CardVoiceOver = 'assets/audio/vo_grade_3_card.wav';
  static const energySetterVoiceOver = 'assets/audio/vo_energy_setter.wav';
  static const learnerCardVoiceOver = 'assets/audio/vo_learner_card.wav';
  static const welcomeAboardVoiceOver = 'assets/audio/vo_welcome_aboard.wav';

  /// Loops for as long as the day-streak flow (`DailyCheckInScreen` ->
  /// `DailyStreakScreen`) is on screen -- background music is silent there
  /// and resumes once the flow hands off to Home.
  static const dailyStreakVoiceOver = 'assets/audio/vo_daily_streak.wav';

  /// Shared tap feedback for StickerPressButton and Rive buttons.
  static const buttonTapSoundEffect = 'assets/audio/sfx_button_press.wav';

  /// The Me avatar tiles intentionally retain their original tap sound.
  static const meAvatarTileSoundEffect = 'assets/audio/sfx_me_avatar_tile.wav';
  static const mapLockedSoundEffect = 'assets/audio/sfx_map_locked.wav';
  static const mapUnlockedSoundEffect = 'assets/audio/sfx_map_unlocked.wav';
  static const homeLampSwitchSoundEffect =
      'assets/audio/sfx_home_lamp_switch.wav';
  static const homeDoorSoundEffect = 'assets/audio/sfx_home_door.wav';

  /// Native playback-complete events are not delivered consistently on every
  /// Android device. These measured clip lengths make voice-over completion
  /// deterministic without cutting a clip short when the native event works.
  static Duration voiceOverDuration(String assetPath) => switch (assetPath) {
    loadScreenVoiceOver => const Duration(milliseconds: 12646),
    loadConfirmationVoiceOver => const Duration(milliseconds: 1566),
    deleteConfirmationVoiceOver => const Duration(milliseconds: 2374),
    nameScreenVoiceOver => const Duration(milliseconds: 5715),
    gradeLevelIntroVoiceOver => const Duration(milliseconds: 3251),
    grade1CardVoiceOver => const Duration(milliseconds: 1554),
    grade2CardVoiceOver => const Duration(milliseconds: 1463),
    grade3CardVoiceOver => const Duration(milliseconds: 1509),
    energySetterVoiceOver => const Duration(milliseconds: 7273),
    learnerCardVoiceOver => const Duration(milliseconds: 4249),
    welcomeAboardVoiceOver => const Duration(milliseconds: 7668),
    dailyStreakVoiceOver => const Duration(milliseconds: 117190),
    _ => const Duration(seconds: 15),
  };
}
