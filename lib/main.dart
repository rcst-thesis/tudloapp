import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive;
import 'package:tudloapp/core/constants/app_strings.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/features/splash/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole UI is laid out for portrait; ignore device rotation.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await rive.RiveNative.init();
  await AppData.initialize();
  await AppAudioService.instance.initialize();
  runApp(const TudloApp());
}

/// Root widget for the app.
///
/// `AppStateScope` wraps the whole app so onboarding choices and profile data
/// can be read from any screen without passing values through constructors.
class TudloApp extends StatefulWidget {
  const TudloApp({super.key});

  @override
  State<TudloApp> createState() => _TudloAppState();
}

class _TudloAppState extends State<TudloApp> {
  final AppState _appState = AppState();
  late final Future<void> _loadProfiles = _appState.loadProfiles();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: TudloTheme.theme,
        home: SplashScreen(loadFuture: _loadProfiles),
      ),
    );
  }
}
