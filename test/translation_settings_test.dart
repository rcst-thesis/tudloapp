import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/services/app_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('translation settings default on and persist changes', () async {
    expect(await AppStorage.readTranslationSettings(), {
      'profanityFilterEnabled': true,
      'dictionaryFallbackEnabled': true,
    });

    await AppStorage.writeTranslationSettings(
      profanityFilterEnabled: false,
      dictionaryFallbackEnabled: false,
    );

    expect(await AppStorage.readTranslationSettings(), {
      'profanityFilterEnabled': false,
      'dictionaryFallbackEnabled': false,
    });
  });
}
