import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAudioService {
  AppAudioService();

  static final AppAudioService instance = AppAudioService();

  // Effects are short .wav clips: uncompressed so they decode instantly and
  // can run through the platform's low-latency (SoundPool-style) player.
  static const tap = 'audio/effects/tap.wav';
  static const correct = 'audio/effects/correct.wav';
  static const wrong = 'audio/effects/wrong.wav';
  static const syllableTap = 'audio/effects/syllable_tap.wav';
  static const lessonUnlock = 'audio/effects/lesson_unlock.wav';
  static const lessonComplete = 'audio/effects/lesson_complete.wav';
  static const star = 'audio/effects/star.wav';
  static const _initialAssets = [
    tap,
    correct,
    wrong,
    syllableTap,
    lessonUnlock,
    lessonComplete,
    star,
  ];

  static const _soundEffectsKey = 'audio.soundEffectsEnabled';
  static const _musicKey = 'audio.musicEnabled';
  static const _voiceOverKey = 'audio.voiceOverEnabled';

  /// One preloaded low-latency player per effect, keyed by [idOf], so
  /// play() is instant and at most one clip is audible at a time.
  final Map<String, AudioPlayer> _effectPlayers = {};

  /// Effects never take audio focus: requesting it on every tap costs a
  /// system round-trip and can duck the background music player.
  static final _effectContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );
  final Map<String, StreamSubscription<void>> _effectSubs = {};
  String? _currentId;
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final ValueNotifier<bool> soundEffectsEnabledNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> musicEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> voiceOverEnabledNotifier = ValueNotifier<bool>(
    true,
  );
  DateTime _lastEffectAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _currentBackgroundTrack;
  double _backgroundVolume = .18;
  bool _initialized = false;
  int _voiceToken = 0;

  bool get soundEffectsEnabled => soundEffectsEnabledNotifier.value;
  bool get musicEnabled => musicEnabledNotifier.value;
  bool get voiceOverEnabled => voiceOverEnabledNotifier.value;

  /// All loaded effect controllers, keyed by id.
  Map<String, AudioPlayer> get controllers => Map.unmodifiable(_effectPlayers);

  /// Id of the effect currently playing, or null.
  String? get currentId => _currentId;

  /// id = file name without extension, lower-cased.
  /// "assets/audio/effects/Tap.WAV" -> "tap"
  static String idOf(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return (dot == -1 ? name : name.substring(0, dot)).toLowerCase();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    soundEffectsEnabledNotifier.value = prefs.getBool(_soundEffectsKey) ?? true;
    musicEnabledNotifier.value = prefs.getBool(_musicKey) ?? true;
    voiceOverEnabledNotifier.value = prefs.getBool(_voiceOverKey) ?? true;
    try {
      await loadAudio(_initialAssets);
    } catch (_) {
      // Missing optional audio must not block app startup.
    }
  }

  /// Loads (and fully buffers) the given asset paths. Accepts .wav (played
  /// through the low-latency player) and .mp3 (regular media player).
  /// Returns {id: controller} for everything that is loaded.
  Future<Map<String, AudioPlayer>> loadAudio(List<String> files) async {
    for (final path in files) {
      final ext = path.split('.').last.toLowerCase();
      if (ext != 'wav' && ext != 'mp3') {
        throw ArgumentError('Unsupported audio format: $path');
      }
    }
    await Future.wait(files.map(_loadEffect));
    return controllers;
  }

  Future<AudioPlayer?> _loadEffect(String path) async {
    final id = idOf(path);
    final existing = _effectPlayers[id];
    if (existing != null) return existing;

    final assetPath = path.startsWith('assets/') ? path.substring(7) : path;
    final isWav = path.toLowerCase().endsWith('.wav');
    final player = AudioPlayer(playerId: 'fx:$id');
    try {
      await player.setPlayerMode(
        isWav ? PlayerMode.lowLatency : PlayerMode.mediaPlayer,
      );
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setAudioContext(_effectContext);
      await player.setSource(AssetSource(assetPath)); // decode + buffer now
    } catch (_) {
      await player.dispose();
      return null;
    }
    _effectPlayers[id] = player;
    // Clear the "currently playing" slot when a clip ends on its own.
    _effectSubs[id] = player.onPlayerComplete.listen((_) {
      if (_currentId == id) _currentId = null;
    });
    return player;
  }

  /// Stops whatever effect is playing and starts [id] from the beginning.
  /// [id] may also be an asset path; it is normalised with [idOf].
  Future<void> play(String id, {double volume = 1}) async {
    final key = idOf(id);
    final player = _effectPlayers[key];
    if (player == null) throw ArgumentError('Audio not loaded: $id');

    final previous = _currentId;
    if (previous != null && previous != key) await stop(previous);

    _currentId = key;
    // Low-latency mode has no seek: stop() rewinds without releasing the
    // buffered source, so resume() restarts from the top immediately.
    await player.stop();
    await player.setVolume(volume.clamp(0, 1).toDouble());
    await player.resume();
  }

  /// Stops [id] as soon as possible, ready for the next play.
  Future<void> stop(String id) async {
    final key = idOf(id);
    final player = _effectPlayers[key];
    if (player == null) return;
    await player.stop();
    if (_currentId == key) _currentId = null;
  }

  /// Stops every loaded effect.
  Future<void> stopAll() async {
    for (final id in _effectPlayers.keys.toList()) {
      await stop(id);
    }
  }

  Future<void> preloadLessonAudio(Iterable<String> assetPaths) async {
    final paths = assetPaths
        .map((path) => path.startsWith('assets/') ? path.substring(7) : path)
        .where((path) => path.isNotEmpty)
        .toSet()
        .take(5)
        .toList();
    try {
      await AudioCache.instance.loadAll(paths);
    } catch (_) {
      // Lessons can fall back to text-to-speech when recordings are absent.
    }
  }

  Future<void> playSoundEffect(
    String assetPath, {
    double volume = .45,
    bool allowRapidRepeat = false,
  }) async {
    if (!soundEffectsEnabled) return;
    final now = DateTime.now();
    if (!allowRapidRepeat &&
        now.difference(_lastEffectAt) < const Duration(milliseconds: 70)) {
      return;
    }
    _lastEffectAt = now;

    try {
      if (!_effectPlayers.containsKey(idOf(assetPath))) {
        if (await _loadEffect(assetPath) == null) return;
      }
      await play(assetPath, volume: volume);
    } catch (_) {
      // Placeholder or missing audio must never interrupt learning.
    }
  }

  Future<void> playTap() => playSoundEffect(tap, volume: .30);
  Future<void> playCorrect() => playSoundEffect(correct, volume: .42);
  Future<void> playWrong() => playSoundEffect(wrong, volume: .34);
  Future<void> playSyllableTap() => playSoundEffect(syllableTap, volume: .36);
  Future<void> playLessonUnlock() => playSoundEffect(lessonUnlock, volume: .40);
  Future<void> playLessonComplete() =>
      playSoundEffect(lessonComplete, volume: .48);
  Future<void> playStar() => playSoundEffect(star, volume: .38);

  Future<void> playVoiceAssets(
    List<String> assetPaths, {
    double volume = .95,
  }) async {
    if (!voiceOverEnabled || assetPaths.isEmpty) return;
    final token = ++_voiceToken;
    try {
      await _voicePlayer.stop();
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setVolume(volume.clamp(0, 1).toDouble());
      for (final assetPath in assetPaths) {
        if (token != _voiceToken) return;
        final completed = Completer<void>();
        late final StreamSubscription<void> sub;
        sub = _voicePlayer.onPlayerComplete.listen((_) {
          if (!completed.isCompleted) completed.complete();
        });
        await _voicePlayer.play(AssetSource(assetPath));
        await completed.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {},
        );
        await sub.cancel();
      }
    } catch (_) {
      // Browsers can reject autoplay before a user gesture; audio should never
      // blank or block the lesson UI.
    }
  }

  Future<void> stopVoice() async {
    _voiceToken++;
    try {
      await _voicePlayer.stop();
    } catch (_) {}
  }

  Future<void> playBackgroundMusic(
    String assetPath, {
    double volume = .18,
  }) async {
    if (!musicEnabled || _currentBackgroundTrack == assetPath) return;
    _currentBackgroundTrack = assetPath;
    _backgroundVolume = volume.clamp(0, 1).toDouble();
    try {
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(_backgroundVolume);
      await _backgroundPlayer.play(AssetSource(assetPath));
    } catch (_) {
      _currentBackgroundTrack = null;
    }
  }

  Future<void> lowerBackgroundVolume() async {
    try {
      await _backgroundPlayer.setVolume(.05);
    } catch (_) {}
  }

  Future<void> restoreBackgroundVolume() async {
    if (!musicEnabled) return;
    try {
      await _backgroundPlayer.setVolume(_backgroundVolume);
    } catch (_) {}
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    soundEffectsEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, enabled);
    if (!enabled) await stopAll();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, enabled);
    try {
      if (!enabled) {
        await _backgroundPlayer.pause();
      } else if (_currentBackgroundTrack != null) {
        await _backgroundPlayer.resume();
      }
    } catch (_) {}
  }

  Future<void> setVoiceOverEnabled(bool enabled) async {
    voiceOverEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceOverKey, enabled);
  }

  Future<void> dispose() async {
    for (final sub in _effectSubs.values) {
      await sub.cancel();
    }
    for (final player in _effectPlayers.values) {
      await player.dispose();
    }
    _effectSubs.clear();
    _effectPlayers.clear();
    _currentId = null;
    await _backgroundPlayer.dispose();
    await _voicePlayer.dispose();
  }
}
