import 'package:flutter/material.dart';

/// The tiny state surface that imported screens read for copy and lifecycle.
/// Progress never passes through this facade; the Tudlo lesson host owns it.
class AppState extends ChangeNotifier {
  AppState({this.username = 'Abyan', this.activeProfileId});

  final String? activeProfileId;
  final String username;
  bool _isHiligaynon = true;

  String get displayUsername => username.trim().isEmpty ? 'Abyan' : username;
  bool get isHiligaynon => _isHiligaynon;
  void toggleAppLanguage() {
    _isHiligaynon = !_isHiligaynon;
    notifyListeners();
  }

  Future<void> markMapHelpSeen() async {}
  Future<void> saveActiveProfileProgress() async {}
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    required AppState super.notifier,
    required super.child,
    super.key,
  });

  static final _fallback = AppState();

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateScope>()?.notifier ??
      _fallback;
}
