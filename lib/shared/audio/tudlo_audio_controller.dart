import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/audio_backend.dart';

/// Owns every native-audio resource for Tudlo's process lifetime.
///
/// Screens request an intent (start/stop the music or play a named one-shot);
/// they never hold SoLoud sources or handles. The app composition root updates
/// this controller whenever the effective learner/device settings change.
class TudloAudioController extends ChangeNotifier {
  TudloAudioController({TudloAudioBackend? backend})
    : _backend = backend ?? const SoloudAudioBackend() {
    _music = _LoopingAudio(_backend, TudloAudioAssets.backgroundMusic);
    _splashSting = _OneShotAudio(_backend, TudloAudioAssets.maralSplashSting);
  }

  final TudloAudioBackend _backend;
  final Map<String, _OneShotAudio> _voiceOvers = {};
  final Map<String, _OneShotAudio> _soundEffects = {};
  final Map<String, _VoiceOverSession> _voiceOverSessions = {};
  late final _LoopingAudio _music;
  late final _OneShotAudio _splashSting;

  AppSettings _settings = AppSettings.defaults;
  var _activeVoiceOvers = 0;
  var _disposed = false;

  /// Prepares startup audio and the shared button-tap effect. Playback still
  /// waits for the owning screen's existing timing and settings gates.
  void preloadStartupAudio() {
    if (_disposed) return;
    _splashSting.preload();
    _music.preload();
    preloadSoundEffect(TudloAudioAssets.buttonTapSoundEffect);
  }

  /// Prepares a short voice-over while its screen is building.
  void preloadVoiceOver(String assetPath) {
    if (_disposed) return;
    _voiceOverFor(assetPath).preload();
  }

  /// Prepares a short, app-supplied sound effect for its owning feature.
  void preloadSoundEffect(String assetPath) {
    if (_disposed) return;
    _soundEffectFor(assetPath).preload();
  }

  /// Reconciles the active music loop with the latest effective settings.
  Future<void> applySettings(AppSettings settings) {
    _settings = settings;
    if (_disposed) return Future<void>.value();
    return _music.updateSettings(settings);
  }

  Future<void> playSplashSting() async {
    if (_disposed) return;
    await _splashSting.play(_settings, _AudioChannel.soundEffects);
  }

  /// Plays Tudlo's shared button-tap effect without changing music ducking.
  ///
  /// This keeps every StickerPressButton and shared Rive button on the same
  /// Sound Effects and Master-volume controls.
  void playButtonTapSound({String? soundEffectAsset}) {
    if (_disposed) return;
    unawaited(
      playSoundEffect(
        soundEffectAsset ?? TudloAudioAssets.buttonTapSoundEffect,
      ),
    );
  }

  /// Plays a feature-specific sound effect without changing music ducking.
  ///
  /// This is reserved for meaningful interaction feedback that has its own
  /// supplied audio cue; ordinary buttons use [playButtonTapSound] instead.
  Future<void> playSoundEffect(String assetPath) async {
    if (_disposed) return;
    await _soundEffectFor(
      assetPath,
    ).play(_settings, _AudioChannel.soundEffects);
  }

  Future<void> playVoiceOver(String assetPath) async {
    final session = await _startVoiceOver(assetPath);
    if (session != null) unawaited(session.completion);
  }

  /// Starts a voice-over and completes only after it naturally ends or is
  /// stopped. Use this for a screen's initial narration when the next spoken
  /// cue must not overlap it.
  Future<void> playVoiceOverAndWait(String assetPath) async {
    final session = await _startVoiceOver(assetPath);
    if (session != null) await session.completion;
  }

  Future<_VoiceOverSession?> _startVoiceOver(String assetPath) async {
    if (_disposed) return null;

    // Replaying a clip replaces only that clip. Its cancellation immediately
    // releases the prior session's ducking ownership.
    _voiceOverSessions.remove(assetPath)?.cancel();
    final playback = await _voiceOverFor(
      assetPath,
    ).play(_settings, _AudioChannel.voiceOver);
    if (playback == null || _disposed) return null;

    final session = _VoiceOverSession();
    _voiceOverSessions[assetPath] = session;
    _activeVoiceOvers++;
    unawaited(_music.setVoiceOverActive(true));
    unawaited(_completeVoiceOverWhenFinished(assetPath, playback, session));
    return session;
  }

  /// Cancels a voice-over when the screen that owns it is no longer visible.
  ///
  /// This also invalidates an in-flight asset load, so a voice-over cannot
  /// begin after its screen has already navigated away.
  Future<void> stopVoiceOver(String assetPath) async {
    if (_disposed) return;
    _voiceOverSessions.remove(assetPath)?.cancel();
    await (_voiceOvers[assetPath]?.stop() ?? Future<void>.value());
  }

  Future<void> startBackgroundMusic() {
    if (_disposed) return Future<void>.value();
    return _music.start(_settings);
  }

  Future<void> stopBackgroundMusic() {
    if (_disposed) return Future<void>.value();
    return _music.stop();
  }

  /// Forces every cached playback handle to be dropped and, if music is
  /// still requested, replayed from scratch.
  ///
  /// A device-level stall (OS audio-session teardown during an emulator
  /// hang, a long GC/frame-lag spike, or the app being backgrounded and
  /// resumed) can silently invalidate SoLoud's native handles while they
  /// still look valid to Dart: `fadeVolume`/`play` return normally, so
  /// [_LoopingAudio._reconcile] never falls into its reload path and the
  /// app is left believing music is playing when the native engine has
  /// gone dead. Call this after such an interruption is detected (e.g.
  /// `AppLifecycleState.resumed`) to recover without needing a restart.
  Future<void> recoverAfterInterruption() {
    if (_disposed) return Future<void>.value();
    return _music.forceRestart(_settings);
  }

  _OneShotAudio _voiceOverFor(String assetPath) => _voiceOvers.putIfAbsent(
    assetPath,
    () => _OneShotAudio(_backend, assetPath),
  );

  _OneShotAudio _soundEffectFor(String assetPath) => _soundEffects.putIfAbsent(
    assetPath,
    () => _OneShotAudio(_backend, assetPath),
  );

  Future<void> _completeVoiceOverWhenFinished(
    String assetPath,
    _OneShotPlayback playback,
    _VoiceOverSession session,
  ) async {
    final clipDuration = TudloAudioAssets.voiceOverDuration(assetPath);
    final fallbackCompleted = Completer<void>();
    final fallbackTimer = Timer(clipDuration, fallbackCompleted.complete);
    try {
      await Future.any<void>([
        _waitForNativeVoiceOverEnd(playback, fallbackCompleted.future),
        fallbackCompleted.future,
        session.cancelled,
      ]);
    } finally {
      fallbackTimer.cancel();
      if (!fallbackCompleted.isCompleted) fallbackCompleted.complete();
      if (identical(_voiceOverSessions[assetPath], session)) {
        _voiceOverSessions.remove(assetPath);
      }
      if (_activeVoiceOvers > 0) _activeVoiceOvers--;
      session.complete();
      if (!_disposed) {
        unawaited(_music.setVoiceOverActive(_activeVoiceOvers > 0));
      }
    }
  }

  /// Wait for SoLoud when possible, but never make screen flow or music
  /// ducking depend on a platform event that can be missed.
  Future<void> _waitForNativeVoiceOverEnd(
    _OneShotPlayback playback,
    Future<void> fallback,
  ) async {
    try {
      await _backend.waitForPlaybackEnd(playback.source, playback.handle);
    } catch (_) {
      await fallback;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final session in _voiceOverSessions.values) {
      session.cancel();
    }
    _voiceOverSessions.clear();
    // SoLoud's documented cleanup point is the uppermost widget. Stopping the
    // loop first preserves the same no-overlap rule used during route changes.
    unawaited(_music.dispose().whenComplete(_backend.dispose));
    super.dispose();
  }
}

enum _AudioChannel { voiceOver, soundEffects }

// SoLoud mixes float-based gain above unity. Tudlo's supplied audio is quiet
// at unity on device, so retain the production-calibrated gain while the
// Settings sliders still determine each channel's relative level.
const _basePlaybackVolume = 15.0;
const _voiceOverMusicMultiplier = 0.35;
const _musicDuckingDuration = Duration(milliseconds: 160);

bool _isEnabled(AppSettings settings, _AudioChannel channel) {
  return switch (channel) {
    _AudioChannel.voiceOver => settings.voiceEnabled,
    _AudioChannel.soundEffects => settings.sfxEnabled,
  };
}

double _volumeFor(AppSettings settings, _AudioChannel channel) {
  final channelVolume = switch (channel) {
    _AudioChannel.voiceOver => settings.voiceVolume,
    _AudioChannel.soundEffects => settings.sfxVolume,
  };
  return _basePlaybackVolume *
      (settings.masterVolume / 100) *
      (channelVolume / 100);
}

/// A cached short clip. The backend owns native handles; this object only
/// owns its reusable source and retries a failed load on the next request.
class _OneShotAudio {
  _OneShotAudio(this._backend, this._assetPath);

  final TudloAudioBackend _backend;
  final String _assetPath;
  Future<Object?>? _load;
  TudloAudioHandle? _handle;
  var _playRequest = 0;

  void preload() {
    unawaited(_ensureLoaded());
  }

  Future<_OneShotPlayback?> play(
    AppSettings settings,
    _AudioChannel channel,
  ) async {
    final request = ++_playRequest;
    await _stopCurrent();
    if (request != _playRequest || !_isEnabled(settings, channel)) {
      return null;
    }

    final source = await _ensureLoaded();
    if (source == null ||
        request != _playRequest ||
        !_isEnabled(settings, channel)) {
      return null;
    }
    try {
      final handle = await _backend.play(
        source,
        volume: _volumeFor(settings, channel),
        looping: false,
      );
      if (request != _playRequest) {
        await _stop(handle);
        return null;
      }
      _handle = handle;
      return _OneShotPlayback(source, handle);
    } catch (_) {
      // Audio must never block the visual/navigation flow.
      return null;
    }
  }

  Future<void> stop() async {
    _playRequest++;
    await _stopCurrent();
  }

  Future<Object?> _ensureLoaded() {
    return _load ??= _loadFromBackend();
  }

  Future<Object?> _loadFromBackend() async {
    try {
      await _backend.initialize();
      return await _backend.loadAsset(_assetPath, mode: LoadMode.memory);
    } catch (_) {
      _load = null;
      return null;
    }
  }

  Future<void> _stopCurrent() async {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    await _stop(handle);
  }

  Future<void> _stop(TudloAudioHandle handle) async {
    try {
      await _backend.stop(handle);
    } catch (_) {
      // A completed one-shot may already have an invalid native handle.
    }
  }
}

class _OneShotPlayback {
  const _OneShotPlayback(this.source, this.handle);

  final Object source;
  final TudloAudioHandle handle;
}

class _VoiceOverSession {
  final _cancelled = Completer<void>();
  final _completion = Completer<void>();

  Future<void> get cancelled => _cancelled.future;
  Future<void> get completion => _completion.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  void complete() {
    if (!_completion.isCompleted) _completion.complete();
  }
}

/// The one long-lived looping track. Every start, stop, and settings update is
/// serialized because flutter_soloud completes a stop asynchronously.
class _LoopingAudio {
  _LoopingAudio(this._backend, this._assetPath);

  final TudloAudioBackend _backend;
  final String _assetPath;
  final _source = _OneShotSourceLoader();
  Future<void> _operation = Future<void>.value();
  AppSettings _settings = AppSettings.defaults;
  TudloAudioHandle? _handle;
  var _requested = false;
  var _voiceOverActive = false;

  void preload() {
    _source.preload(_backend, _assetPath);
  }

  Future<void> start(AppSettings settings) {
    _requested = true;
    _settings = settings;
    return _enqueue(_reconcile);
  }

  Future<void> stop() {
    _requested = false;
    return _enqueue(_stopCurrent);
  }

  Future<void> updateSettings(AppSettings settings) {
    _settings = settings;
    return _enqueue(_reconcile);
  }

  Future<void> setVoiceOverActive(bool active) {
    _voiceOverActive = active;
    return _enqueue(_reconcile);
  }

  /// Drops the current handle unconditionally, then reconciles -- unlike
  /// [_reconcile] alone, this never trusts a cached handle that still looks
  /// valid, so it also recovers a native session that died silently.
  Future<void> forceRestart(AppSettings settings) {
    _settings = settings;
    return _enqueue(() async {
      await _stopCurrent();
      await _reconcile();
    });
  }

  Future<void> dispose() => stop();

  bool get _shouldPlay => _requested && _settings.musicEnabled;

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operation.catchError((Object _) {}).then((_) => operation());
    _operation = next;
    return next;
  }

  Future<void> _reconcile() async {
    if (!_shouldPlay) {
      await _stopCurrent();
      return;
    }

    final handle = _handle;
    if (handle != null) {
      try {
        _backend.fadeVolume(
          handle,
          _targetVolume,
          duration: _musicDuckingDuration,
        );
        return;
      } catch (_) {
        _handle = null;
      }
    }

    final source = await _source.load(_backend, _assetPath);
    if (source == null || !_shouldPlay) return;
    try {
      _handle = await _backend.play(
        source,
        volume: _targetVolume,
        looping: true,
      );
    } catch (_) {
      // A future start/settings update gets another chance to recover.
    }
  }

  Future<void> _stopCurrent() async {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    try {
      await _backend.stop(handle);
    } catch (_) {
      // A stale native handle is already unusable, which is the desired end
      // state for this branch.
    }
  }

  double get _targetVolume =>
      _musicVolume(_settings) *
      (_voiceOverActive ? _voiceOverMusicMultiplier : 1);
}

double _musicVolume(AppSettings settings) =>
    _basePlaybackVolume *
    (settings.masterVolume / 100) *
    (settings.musicVolume / 100);

class _OneShotSourceLoader {
  Future<Object?>? _load;

  void preload(TudloAudioBackend backend, String assetPath) {
    unawaited(load(backend, assetPath));
  }

  Future<Object?> load(TudloAudioBackend backend, String assetPath) {
    return _load ??= _loadFromBackend(backend, assetPath);
  }

  Future<Object?> _loadFromBackend(
    TudloAudioBackend backend,
    String assetPath,
  ) async {
    try {
      await backend.initialize();
      return await backend.loadAsset(assetPath, mode: LoadMode.memory);
    } catch (_) {
      _load = null;
      return null;
    }
  }
}
