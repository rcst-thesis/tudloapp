import 'dart:async';
import 'dart:js_interop';

import 'package:tudloapp/core/services/tudlo_tts_platform_interface.dart';
import 'package:web/web.dart' as web;

TudloTtsPlatform createTudloTtsPlatform() => _WebTudloTtsPlatform();

class _WebTudloTtsPlatform implements TudloTtsPlatform {
  Completer<void>? _completion;

  @override
  Future<void> speak(
    String text, {
    required bool hiligaynon,
    required bool waitForCompletion,
  }) async {
    await stop();
    final completion = Completer<void>();
    _completion = completion;

    final utterance = web.SpeechSynthesisUtterance(text)
      ..lang = hiligaynon ? 'tl-PH' : 'en-US'
      ..rate = .62
      ..pitch = 1.04
      ..volume = 1;

    void complete() {
      if (!completion.isCompleted) completion.complete();
      if (identical(_completion, completion)) _completion = null;
    }

    utterance.onend = ((web.Event _) => complete()).toJS;
    utterance.onerror = ((web.Event _) => complete()).toJS;

    web.window.speechSynthesis.speak(utterance);

    if (waitForCompletion) {
      await completion.future.timeout(
        Duration(milliseconds: (text.length * 170).clamp(1900, 22000)),
        onTimeout: () {},
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      web.window.speechSynthesis.cancel();
    } catch (_) {
      // Browser speech cancellation should never block UI flow.
    }
    final completion = _completion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _completion = null;
  }
}
