import 'package:flutter/widgets.dart';

import 'package:tudloapp/shared/audio/tudlo_audio_controller.dart';

/// Makes Tudlo's single app-owned audio controller available to screens.
class TudloAudioScope extends InheritedNotifier<TudloAudioController> {
  const TudloAudioScope({
    required TudloAudioController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  // Bare widget tests can still exercise screen timing/callback seams without
  // having to install the native audio plugin.
  static final _fallback = TudloAudioController();

  static TudloAudioController of(BuildContext context) {
    final scope = _scopeFor(context);
    return scope?.notifier ?? _fallback;
  }

  /// Returns the app-owned controller when this widget is mounted below the
  /// app shell. Shared controls use this so isolated widget tests do not try
  /// to initialize a native audio backend.
  static TudloAudioController? maybeOf(BuildContext context) =>
      _scopeFor(context)?.notifier;

  static TudloAudioScope? _scopeFor(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TudloAudioScope>();
}
