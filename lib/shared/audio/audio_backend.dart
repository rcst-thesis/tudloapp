import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:tudloapp/shared/audio/soloud_engine.dart';

/// The small runtime boundary used by Tudlo's audio controller.
///
/// Handles remain opaque here so controller tests can use a deterministic fake
/// backend without loading the native SoLoud library.
abstract interface class TudloAudioBackend {
  Future<void> initialize();

  Future<Object> loadAsset(String assetPath, {required LoadMode mode});

  Future<TudloAudioHandle> play(
    Object source, {
    required double volume,
    required bool looping,
  });

  Future<void> stop(TudloAudioHandle handle);

  /// Completes when this individual playback instance ends or is stopped.
  Future<void> waitForPlaybackEnd(Object source, TudloAudioHandle handle);

  void fadeVolume(
    TudloAudioHandle handle,
    double volume, {
    required Duration duration,
  });

  Future<void> dispose();
}

/// The production [TudloAudioBackend] backed by flutter_soloud.
class SoloudAudioBackend implements TudloAudioBackend {
  const SoloudAudioBackend();

  @override
  Future<void> initialize() => SoloudEngine.ensureReady();

  @override
  Future<Object> loadAsset(String assetPath, {required LoadMode mode}) async {
    return await SoLoud.instance.loadAsset(assetPath, mode: mode);
  }

  @override
  Future<TudloAudioHandle> play(
    Object source, {
    required double volume,
    required bool looping,
  }) async {
    final handle = await SoLoud.instance.play(
      source as AudioSource,
      volume: volume,
      looping: looping,
    );
    return _SoloudAudioHandle(handle);
  }

  @override
  Future<void> stop(TudloAudioHandle handle) =>
      SoLoud.instance.stop((handle as _SoloudAudioHandle).value);

  @override
  Future<void> waitForPlaybackEnd(Object source, TudloAudioHandle handle) {
    final soundHandle = (handle as _SoloudAudioHandle).value;
    return (source as AudioSource).soundEvents
        .firstWhere(
          (event) =>
              event.event == SoundEventType.handleIsNoMoreValid &&
              event.handle == soundHandle,
        )
        .then((_) {});
  }

  @override
  void fadeVolume(
    TudloAudioHandle handle,
    double volume, {
    required Duration duration,
  }) {
    SoLoud.instance.fadeVolume(
      (handle as _SoloudAudioHandle).value,
      volume,
      duration,
    );
  }

  @override
  Future<void> dispose() => SoloudEngine.shutdown();
}

/// A playback instance owned by a [TudloAudioBackend].
///
/// This is deliberately not an [Object] alias: flutter_soloud's
/// `SoundHandle` is a Dart extension type and therefore cannot be assigned to
/// `Object`. The wrapper keeps that package detail inside this adapter.
abstract class TudloAudioHandle {
  const TudloAudioHandle();
}

class _SoloudAudioHandle extends TudloAudioHandle {
  const _SoloudAudioHandle(this.value);

  final SoundHandle value;
}
