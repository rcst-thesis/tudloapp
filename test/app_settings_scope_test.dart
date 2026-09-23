import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/features/settings/domain/app_settings_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a never-saved controller reads AppSettings.defaults', () {
    final controller = AppSettingsController();
    expect(controller.settings.language, AppSettings.defaults.language);
    expect(controller.settings.masterVolume, AppSettings.defaults.masterVolume);
  });

  test('update persists across a fresh controller\'s loadSaved', () async {
    final controller = AppSettingsController();
    await controller.update(
      AppSettings.defaults.copyWith(language: AppLanguage.english),
    );
    expect(controller.settings.language, AppLanguage.english);

    final fresh = AppSettingsController();
    await fresh.loadSaved();
    expect(fresh.settings.language, AppLanguage.english);
  });

  test(
    'loadSaved leaves defaults in place when nothing was ever saved',
    () async {
      final controller = AppSettingsController();
      await controller.loadSaved();
      expect(controller.settings.language, AppSettings.defaults.language);
    },
  );
}
