import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;

import 'app/tudlo_app.dart';
import 'features/map/domain/map_rive_asset.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  // Kick off decoding the map's .riv file now, in parallel with everything
  // else (startup flow, onboarding), so it's already cached by the time the
  // learner first opens the Map tab -- see MapRiveAsset.
  unawaited(MapRiveAsset.preload());
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TudloApp());
}
