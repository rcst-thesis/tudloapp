import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';

/// Routes copied DevG lesson audio through Tudlo's one audio owner.
///
/// The compatibility methods intentionally keep the source flows readable,
/// but neither create a second player nor persist duplicate audio settings.
class AppAudioService {
  AppAudioService._();

  static final instance = AppAudioService._();
  static const tap = 'audio/effects/tap.mp3';
  static const correct = 'audio/effects/correct.mp3';
  static const wrong = 'audio/effects/wrong.mp3';
  static const syllableTap = 'audio/effects/syllable_tap.mp3';
  static const lessonUnlock = 'audio/effects/lesson_unlock.mp3';
  static const lessonComplete = 'audio/effects/lesson_complete.mp3';
  static const star = 'audio/effects/star.mp3';

  final soundEffectsEnabledNotifier = ValueNotifier<bool>(true);
  final musicEnabledNotifier = ValueNotifier<bool>(true);
  final voiceOverEnabledNotifier = ValueNotifier<bool>(true);
  final _activeVoiceAssets = <String>{};
  TudloAudioController? _audio;

  bool get soundEffectsEnabled => soundEffectsEnabledNotifier.value;
  bool get musicEnabled => musicEnabledNotifier.value;
  bool get voiceOverEnabled => voiceOverEnabledNotifier.value;

  /// Called by a lesson host after it obtains Tudlo's app-scoped controller.
  void attach(TudloAudioController? audio) => _audio = audio;

  Future<void> initialize() async {}

  Future<void> preloadLessonAudio(Iterable<String> assetPaths) async {
    for (final path in assetPaths.take(8)) {
      _audio?.preloadVoiceOver(_asset(path));
    }
  }

  Future<void> playSoundEffect(
    String assetPath, {
    double volume = .45,
    bool allowRapidRepeat = false,
  }) => _audio?.playSoundEffect(_asset(assetPath)) ?? Future.value();

  Future<void> playTap() => playSoundEffect(tap, volume: .30);
  Future<void> playCorrect() => playSoundEffect(correct, volume: .42);
  Future<void> playWrong() => playSoundEffect(wrong, volume: .34);
  Future<void> playSyllableTap() => playSoundEffect(syllableTap, volume: .36);
  Future<void> playLessonUnlock() => playSoundEffect(lessonUnlock, volume: .40);
  Future<void> playLessonComplete() =>
      playSoundEffect(lessonComplete, volume: .48);
  Future<void> playStar() => playSoundEffect(star, volume: .38);

  Future<void> playVoiceAssets(
    List<String> paths, {
    double volume = .95,
  }) async {
    await stopVoice();
    for (final path in paths) {
      final asset = _asset(path);
      _activeVoiceAssets.add(asset);
      final audio = _audio;
      if (audio != null) await audio.playVoiceOverAndWait(asset);
      _activeVoiceAssets.remove(asset);
    }
  }

  Future<void> stopVoice() async {
    final active = _activeVoiceAssets.toList();
    _activeVoiceAssets.clear();
    await Future.wait(
      active.map((asset) => _audio?.stopVoiceOver(asset) ?? Future.value()),
    );
  }

  /// TudloAudioController ducks its one music loop while narration is active.
  Future<void> lowerBackgroundVolume() async {}
  Future<void> restoreBackgroundVolume() async {}
  Future<void> playBackgroundMusic(String path, {double volume = .18}) async {}
  Future<void> setSoundEffectsEnabled(bool enabled) async {}
  Future<void> setMusicEnabled(bool enabled) async {}
  Future<void> setVoiceOverEnabled(bool enabled) async {}
  Future<void> dispose() => stopVoice();

  static String _asset(String value) =>
      value.startsWith('assets/') ? value : 'assets/$value';
}
