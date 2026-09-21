import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/audio_backend.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';

void main() {
  test('music uses normalized settings and recovers after unmuting', () async {
    final backend = _FakeAudioBackend();
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    final quietMusic = AppSettings.defaults.copyWith(
      masterVolume: 50,
      musicVolume: 40,
    );
    await controller.applySettings(quietMusic);
    await controller.startBackgroundMusic();

    expect(
      backend.commands,
      containsAllInOrder([
        'initialize',
        'load:${TudloAudioAssets.backgroundMusic}',
        'play:${TudloAudioAssets.backgroundMusic}:3.0:true',
      ]),
    );

    await controller.applySettings(quietMusic.copyWith(musicEnabled: false));
    expect(backend.commands.last, 'stop:1');

    await controller.applySettings(quietMusic);
    expect(
      backend.commands.last,
      'play:${TudloAudioAssets.backgroundMusic}:3.0:true',
    );
  });

  test('a stop requested during a pending start prevents playback', () async {
    final backend = _FakeAudioBackend(loadCompleter: Completer<Object>());
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    final starting = controller.startBackgroundMusic();
    await Future<void>.delayed(Duration.zero);
    expect(
      backend.commands,
      contains('load:${TudloAudioAssets.backgroundMusic}'),
    );
    final stopping = controller.stopBackgroundMusic();
    backend.loadCompleter!.complete(TudloAudioAssets.backgroundMusic);
    await Future.wait([starting, stopping]);

    expect(
      backend.commands.where((command) => command.startsWith('play:')),
      isEmpty,
    );
  });

  test('shared button taps honor the Sound Effects settings', () async {
    final backend = _FakeAudioBackend();
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    controller.playButtonTapSound();
    await Future<void>.delayed(Duration.zero);
    expect(
      backend.commands,
      contains('play:${TudloAudioAssets.buttonTapSoundEffect}:15.0:false'),
    );
    final playCount = backend.commands
        .where((command) => command.startsWith('play:'))
        .length;

    await controller.applySettings(
      AppSettings.defaults.copyWith(sfxEnabled: false),
    );
    controller.playButtonTapSound();
    await Future<void>.delayed(Duration.zero);
    expect(
      backend.commands.where((command) => command.startsWith('play:')).length,
      playCount,
    );

    await controller.applySettings(AppSettings.defaults.copyWith(sfxVolume: 0));
    controller.playButtonTapSound();
    await Future<void>.delayed(Duration.zero);
    expect(
      backend.commands.where((command) => command.startsWith('play:')).length,
      playCount,
    );

    await controller.applySettings(
      AppSettings.defaults.copyWith(masterVolume: 0),
    );
    controller.playButtonTapSound();
    await Future<void>.delayed(Duration.zero);
    expect(
      backend.commands.where((command) => command.startsWith('play:')).length,
      playCount,
    );
  });

  test('feature-specific effects use the Sound Effects channel', () async {
    final backend = _FakeAudioBackend();
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    const effectAsset = 'assets/audio/example_effect.wav';
    await controller.applySettings(
      AppSettings.defaults.copyWith(masterVolume: 50, sfxVolume: 40),
    );
    await controller.playSoundEffect(effectAsset);

    expect(backend.commands.last, 'play:$effectAsset:3.0:false');

    await controller.applySettings(
      AppSettings.defaults.copyWith(sfxEnabled: false),
    );
    await controller.playSoundEffect(effectAsset);
    expect(
      backend.commands.where((command) => command.startsWith('play:')).length,
      1,
    );
  });

  test(
    'a button can override the shared effect for a meaningful action',
    () async {
      final backend = _FakeAudioBackend();
      final controller = TudloAudioController(backend: backend);
      addTearDown(controller.dispose);

      controller.playButtonTapSound(
        soundEffectAsset: TudloAudioAssets.mapUnlockedSoundEffect,
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        backend.commands,
        contains('play:${TudloAudioAssets.mapUnlockedSoundEffect}:15.0:false'),
      );
    },
  );

  test('voice-over honors only master and voice-over settings', () async {
    final backend = _FakeAudioBackend();
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    const voiceAsset = 'assets/audio/example_voice.wav';
    final enabled = AppSettings.defaults.copyWith(
      masterVolume: 50,
      voiceVolume: 40,
      sfxVolume: 0,
    );
    await controller.applySettings(enabled);
    await controller.playVoiceOver(voiceAsset);

    expect(backend.commands.last, 'play:$voiceAsset:3.0:false');

    await controller.applySettings(enabled.copyWith(voiceEnabled: false));
    await controller.playVoiceOver(voiceAsset);
    expect(
      backend.commands.where((command) => command.startsWith('play:')).length,
      1,
    );
  });

  test('stopping a voice-over cancels one still loading', () async {
    final backend = _FakeAudioBackend(loadCompleter: Completer<Object>());
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    const voiceAsset = 'assets/audio/example_voice.wav';
    final playing = controller.playVoiceOver(voiceAsset);
    await Future<void>.delayed(Duration.zero);
    final stopping = controller.stopVoiceOver(voiceAsset);

    backend.loadCompleter!.complete(voiceAsset);
    await Future.wait([playing, stopping]);

    expect(
      backend.commands.where((command) => command.startsWith('play:')),
      isEmpty,
    );
  });

  test('stopping an active voice-over stops its native playback', () async {
    final backend = _FakeAudioBackend();
    final controller = TudloAudioController(backend: backend);
    addTearDown(controller.dispose);

    const voiceAsset = 'assets/audio/example_voice.wav';
    await controller.playVoiceOver(voiceAsset);
    await controller.stopVoiceOver(voiceAsset);

    expect(backend.commands.last, 'stop:1');
  });

  test(
    'a stopped awaited voice-over always releases its screen flow',
    () async {
      final backend = _FakeAudioBackend();
      final controller = TudloAudioController(backend: backend);
      addTearDown(controller.dispose);

      const voiceAsset = 'assets/audio/example_voice.wav';
      final narration = controller.playVoiceOverAndWait(voiceAsset);
      await Future<void>.delayed(Duration.zero);

      await controller.stopVoiceOver(voiceAsset);
      await narration;

      expect(backend.commands.last, 'stop:1');
    },
  );

  test(
    'voice-over ducks music and restores its Settings volume afterward',
    () async {
      final backend = _FakeAudioBackend();
      final controller = TudloAudioController(backend: backend);
      addTearDown(controller.dispose);

      const voiceAsset = 'assets/audio/example_voice.wav';
      await controller.startBackgroundMusic();
      await controller.playVoiceOver(voiceAsset);
      await Future<void>.delayed(Duration.zero);

      double lastMusicFadeVolume() {
        final command = backend.commands
            .where((command) => command.startsWith('fade:1:'))
            .last;
        return double.parse(command.split(':')[2]);
      }

      expect(lastMusicFadeVolume(), closeTo(3.36, 0.001));
      expect(lastMusicFadeVolume(), greaterThan(0));

      await controller.stopVoiceOver(voiceAsset);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(lastMusicFadeVolume(), closeTo(9.6, 0.001));
    },
  );
}

class _FakeAudioBackend implements TudloAudioBackend {
  _FakeAudioBackend({this.loadCompleter});

  final Completer<Object>? loadCompleter;
  final commands = <String>[];
  final _playbackEnds = <TudloAudioHandle, Completer<void>>{};
  var _nextHandle = 0;

  @override
  Future<void> initialize() async {
    commands.add('initialize');
  }

  @override
  Future<Object> loadAsset(String assetPath, {required LoadMode mode}) async {
    commands.add('load:$assetPath');
    return loadCompleter?.future ?? assetPath;
  }

  @override
  Future<TudloAudioHandle> play(
    Object source, {
    required double volume,
    required bool looping,
  }) async {
    commands.add('play:$source:$volume:$looping');
    final handle = _FakeAudioHandle(++_nextHandle);
    _playbackEnds[handle] = Completer<void>();
    return handle;
  }

  @override
  Future<void> stop(TudloAudioHandle handle) async {
    commands.add('stop:$handle');
    _playbackEnds.remove(handle)?.complete();
  }

  @override
  Future<void> waitForPlaybackEnd(Object source, TudloAudioHandle handle) =>
      _playbackEnds[handle]?.future ?? Future<void>.value();

  @override
  void fadeVolume(
    TudloAudioHandle handle,
    double volume, {
    required Duration duration,
  }) {
    commands.add('fade:$handle:$volume:${duration.inMilliseconds}');
  }

  @override
  Future<void> dispose() async {
    for (final completion in _playbackEnds.values) {
      if (!completion.isCompleted) completion.complete();
    }
    _playbackEnds.clear();
    commands.add('dispose');
  }
}

class _FakeAudioHandle extends TudloAudioHandle {
  const _FakeAudioHandle(this.value);

  final int value;

  @override
  String toString() => '$value';
}
