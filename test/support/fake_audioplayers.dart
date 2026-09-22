/// Fake audioplayers platform, shared by the tests that would otherwise hit a
/// plugin that does not exist under `flutter test`.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';

/// Installs the fakes below as the active audioplayers platform.
FakeAudioplayersPlatform installFakeAudioplayers() {
  final platform = FakeAudioplayersPlatform();
  AudioplayersPlatformInterface.instance = platform;
  GlobalAudioplayersPlatformInterface.instance =
      FakeGlobalAudioplayersPlatform();
  AudioCache.instance = FakeAudioCache();
  return platform;
}

/// Records every platform call as `method:playerId[:arg]` and emits a
/// `prepared` event as soon as a source is set, like a real backend would.
class FakeAudioplayersPlatform extends AudioplayersPlatformInterface {
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

class FakeGlobalAudioplayersPlatform
    extends GlobalAudioplayersPlatformInterface {
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
class FakeAudioCache extends AudioCache {
  @override
  Future<Uri> load(String fileName) async =>
      Uri.parse('file:///fake/$fileName');
}
