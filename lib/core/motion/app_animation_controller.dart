import 'package:flutter/widgets.dart';

/// App-wide on/off switch for Tudlo motion.
class AppAnimationController extends ChangeNotifier {
  bool _isEnabled;

  AppAnimationController({bool isEnabled = true}) : _isEnabled = isEnabled;

  bool get isEnabled => _isEnabled;

  void setEnabled(bool isEnabled) {
    if (_isEnabled == isEnabled) return;
    _isEnabled = isEnabled;
    notifyListeners();
  }
}

/// Makes the app-wide animation preference available to every screen.
class AppAnimationScope extends InheritedNotifier<AppAnimationController> {
  const AppAnimationScope({
    required AppAnimationController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppAnimationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppAnimationScope>();
    assert(scope != null, 'AppAnimationScope is missing above this context.');
    return scope!.notifier!;
  }
}
