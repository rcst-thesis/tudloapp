import 'package:flutter_soloud/flutter_soloud.dart';

/// The one memoized `SoLoud.instance.init()` call for the app's whole
/// lifetime, shared only by the app-owned audio backend.
///
/// This has to be a single shared holder, not a private field on whichever
/// widget happens to call it first: `SoLoud.init()` "deinits + re-inits"
/// when called on an already-initialized instance (needed for the hot
/// restart case -- see `StartupFlow`'s own historical comment on this), so
/// two independent callers each memoizing their own `init()` future could
/// race, with the second silently tearing down whatever the first had
/// already set up -- e.g. a voice-over clip playing on a later screen
/// re-initializing the engine and killing already-playing background music.
class SoloudEngine {
  const SoloudEngine._();

  static Future<void>? _init;

  static Future<void> ensureReady() {
    return _init ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await SoLoud.instance.init();
    } catch (_) {
      // Do not cache a transient native initialization failure forever.
      _init = null;
      rethrow;
    }
  }

  /// Releases the process-wide native engine from TudloApp's disposal path.
  static Future<void> shutdown() async {
    final initialization = _init;
    if (initialization != null) {
      try {
        await initialization;
      } catch (_) {
        // The engine is already unavailable; there is nothing left to release.
      }
    }
    try {
      final soloud = SoLoud.instance;
      if (soloud.isInitialized) soloud.deinit();
    } catch (_) {
      // Best-effort app shutdown.
    } finally {
      _init = null;
    }
  }
}
