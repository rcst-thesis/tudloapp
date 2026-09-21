import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';

/// Records every platform call as `method:playerId[:arg]` and emits a
/// `prepared` event as soon as a source is set, like a real backend would.
class _FakePlatform extends AudioplayersPlatformInterface {
  final calls = <String>[];
  final _events = <String, StreamController<AudioEvent>>{};

  StreamController<AudioEvent> _ctrl(String id) =>
      _events.putIfAbsent(id, () => StreamController<AudioEvent>.broadcast());

  List<String> forPlayer(String id) =>
      calls.where((c) => c.contains(':$id')).toList();

  void complete(String playerId) =>
      _ctrl(playerId).add(const AudioEvent(eventType: AudioEventType.complete));

  @override
  Future<void> create(String playerId) async => calls.add('create:$playerId');
  @override
  Future<void> dispose(String playerId) async => calls.add('dispose:$playerId');
  @override
  Future<void> pause(String playerId) async => calls.add('pause:$playerId');
  @override
  Future<void> stop(String playerId) async => calls.add('stop:$playerId');
  @override
  Future<void> resume(String playerId) async => calls.add('resume:$playerId');
  @override
  Future<void> release(String playerId) async => calls.add('release:$playerId');
  @override
  Future<void> seek(String playerId, Duration position) async =>
      calls.add('seek:$playerId:${position.inMilliseconds}');
  @override
  Future<void> setBalance(String playerId, double balance) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async =>
      calls.add('setVolume:$playerId:$volume');
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async =>
      calls.add('setReleaseMode:$playerId:${releaseMode.name}');
  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}
  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    calls.add('setSourceUrl:$playerId:$url');
    _ctrl(playerId).add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
  }

  @override
  Future<void> setSourceBytes(
    String playerId,
    List<int> bytes, {
    String? mimeType,
  }) async {}
  @override
  Future<void> setAudioContext(String playerId, AudioContext ctx) async {}
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async =>
      calls.add('setPlayerMode:$playerId:${playerMode.name}');
  @override
  Future<int?> getDuration(String playerId) async => null;
  @override
  Future<int?> getCurrentPosition(String playerId) async => null;
  @override
  Future<void> emitLog(String playerId, String message) async {}
  @override
  Future<void> emitError(String playerId, String code, String message) async {}
  @override
  Stream<AudioEvent> getEventStream(String playerId) => _ctrl(playerId).stream;
}

class _FakeGlobalPlatform extends GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}
  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}
  @override
  Future<void> emitGlobalLog(String message) async {}
  @override
  Future<void> emitGlobalError(String code, String message) async {}
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

/// Skips rootBundle + temp files: hands back a fake local uri per asset.
class _FakeCache extends AudioCache {
  @override
  Future<Uri> load(String fileName) async =>
      Uri.parse('file:///fake/$fileName');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlatform platform;
  late AppAudioService audio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = _FakePlatform();
    AudioplayersPlatformInterface.instance = platform;
    GlobalAudioplayersPlatformInterface.instance = _FakeGlobalPlatform();
    AudioCache.instance = _FakeCache();
    audio = AppAudioService();
  });

  tearDown(() => audio.dispose());

  group('idOf', () {
    test('strips directories and extension, lower-cases', () {
      expect(AppAudioService.idOf('assets/audio/effects/Beep.WAV'), 'beep');
      expect(AppAudioService.idOf(r'Assets\theme.mp3'), 'theme');
      expect(AppAudioService.idOf('noext'), 'noext');
    });
  });

  group('loadAudio', () {
    test('rejects unsupported formats before loading anything', () async {
      await expectLater(
        audio.loadAudio(['assets/beep.wav', 'assets/clip.ogg']),
        throwsArgumentError,
      );
      expect(audio.controllers, isEmpty);
    });

    test('buffers each file into its own controller keyed by id', () async {
      final controllers = await audio.loadAudio([
        'assets/beep.wav',
        'assets/theme.mp3',
      ]);

      expect(controllers.keys, unorderedEquals(['beep', 'theme']));
      expect(
        platform.forPlayer('fx:beep'),
        containsAllInOrder([
          'setPlayerMode:fx:beep:lowLatency',
          'setReleaseMode:fx:beep:stop',
          'setSourceUrl:fx:beep:/fake/beep.wav',
        ]),
      );
      expect(
        platform.forPlayer('fx:theme'),
        contains('setPlayerMode:fx:theme:mediaPlayer'),
      );
      // The `assets/` prefix is stripped so AudioCache does not double it.
      expect(platform.calls, isNot(contains(matches(r'assets/assets'))));
    });

    test('is idempotent: reloading an id reuses the controller', () async {
      final first = await audio.loadAudio(['assets/beep.wav']);
      final second = await audio.loadAudio(['assets/beep.wav']);
      expect(identical(first['beep'], second['beep']), isTrue);
      expect(platform.calls.where((c) => c == 'create:fx:beep'), hasLength(1));
    });
  });

  group('play / stop', () {
    setUp(() => audio.loadAudio(['assets/beep.wav', 'assets/theme.mp3']));

    test('throws for an id that was never loaded', () {
      expect(() => audio.play('nope'), throwsArgumentError);
    });

    test('restarts from the top and tracks currentId', () async {
      platform.calls.clear();
      await audio.play('beep', volume: .5);

      expect(audio.currentId, 'beep');
      expect(platform.calls, [
        'stop:fx:beep',
        'setVolume:fx:beep:0.5',
        'resume:fx:beep',
      ]);
    });

    test('accepts a path and clamps volume', () async {
      platform.calls.clear();
      await audio.play('assets/beep.wav', volume: 3);
      expect(audio.currentId, 'beep');
      expect(platform.calls, contains('setVolume:fx:beep:1.0'));
    });

    test('stops the previous clip before starting the next', () async {
      await audio.play('theme');
      platform.calls.clear();

      await audio.play('beep');

      expect(audio.currentId, 'beep');
      expect(platform.calls.first, 'stop:fx:theme');
      expect(platform.calls, contains('resume:fx:beep'));
    });

    test('stop() halts the clip and clears currentId', () async {
      await audio.play('beep');
      platform.calls.clear();

      await audio.stop('beep');

      expect(platform.calls, ['stop:fx:beep']);
      expect(audio.currentId, isNull);
    });

    test('stop() on an unloaded or non-current id is a no-op', () async {
      await audio.play('beep');
      await audio.stop('nope');
      await audio.stop('theme');
      expect(audio.currentId, 'beep');
    });

    test('currentId clears when the clip finishes on its own', () async {
      await audio.play('beep');
      platform.complete('fx:beep');
      await Future<void>.delayed(Duration.zero);
      expect(audio.currentId, isNull);
    });

    test('stopAll() stops every loaded controller', () async {
      await audio.play('beep');
      platform.calls.clear();

      await audio.stopAll();

      expect(
        platform.calls,
        unorderedEquals(['stop:fx:beep', 'stop:fx:theme']),
      );
      expect(audio.currentId, isNull);
    });
  });

  group('playSoundEffect', () {
    test('lazily loads an unloaded wav and plays it', () async {
      await audio.playSoundEffect('audio/effects/tap.wav');
      expect(audio.controllers.keys, ['tap']);
      expect(audio.currentId, 'tap');
      expect(platform.calls, contains('resume:fx:tap'));
    });

    test('throttles rapid repeats unless allowed', () async {
      await audio.loadAudio(['audio/effects/tap.wav']);
      platform.calls.clear();

      await audio.playSoundEffect('audio/effects/tap.wav');
      await audio.playSoundEffect('audio/effects/tap.wav');
      expect(platform.calls.where((c) => c == 'resume:fx:tap'), hasLength(1));

      await audio.playSoundEffect(
        'audio/effects/tap.wav',
        allowRapidRepeat: true,
      );
      expect(platform.calls.where((c) => c == 'resume:fx:tap'), hasLength(2));
    });

    test('does nothing while sound effects are disabled', () async {
      await audio.loadAudio(['audio/effects/tap.wav']);
      await audio.setSoundEffectsEnabled(false);
      platform.calls.clear();

      await audio.playSoundEffect('audio/effects/tap.wav');

      expect(platform.calls, isEmpty);
      expect(audio.currentId, isNull);
    });
  });

  test('initialize() preloads every built-in effect', () async {
    await audio.initialize();
    expect(
      audio.controllers.keys,
      unorderedEquals([
        'tap',
        'correct',
        'wrong',
        'syllable_tap',
        'lesson_unlock',
        'lesson_complete',
        'star',
      ]),
    );
  });

  test('dispose() releases every controller', () async {
    await audio.loadAudio(['assets/beep.wav']);
    await audio.dispose();
    expect(platform.calls, contains('dispose:fx:beep'));
    expect(audio.controllers, isEmpty);
    expect(audio.currentId, isNull);
    audio = AppAudioService(); // so tearDown has something fresh to dispose
  });
}
