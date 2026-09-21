import 'package:tudloapp/core/services/tudlo_tts_platform_interface.dart';
import 'package:tudloapp/core/services/tudlo_tts_platform_io.dart'
    if (dart.library.js_interop) 'package:tudloapp/core/services/tudlo_tts_platform_web.dart'
    as implementation;

TudloTtsPlatform createTudloTtsPlatform() =>
    implementation.createTudloTtsPlatform();
