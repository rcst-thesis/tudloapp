import 'package:flutter/material.dart';
import 'package:tudloapp/core/constants/app_strings.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/features/profile/screens/profile_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.initialize();
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
        home: FutureBuilder<void>(
          future: _loadProfiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const ProfileSelectionScreen();
          },
        ),
      ),
    );
  }
}
