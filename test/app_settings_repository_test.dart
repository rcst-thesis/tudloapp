import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/settings/domain/app_settings.dart';
import 'package:tudloapp/features/settings/domain/app_settings_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const repository = AppSettingsRepository();

  test('load returns null when nothing has ever been saved', () async {
    expect(await repository.load(), isNull);
  });

  test('save then load round-trips every field', () async {
    const settings = AppSettings(
      language: AppLanguage.english,
      masterVolume: 40,
      musicEnabled: false,
      musicVolume: 20,
      sfxEnabled: false,
      sfxVolume: 30,
      voiceEnabled: false,
      voiceVolume: 10,
      ambientAnimationsEnabled: false,
      performanceQuality: PerformanceQuality.batterySaver,
      lessonRemindersEnabled: false,
    );

    await repository.save(settings);
    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded!.language, AppLanguage.english);
    expect(loaded.masterVolume, 40);
    expect(loaded.musicEnabled, isFalse);
    expect(loaded.musicVolume, 20);
    expect(loaded.sfxEnabled, isFalse);
    expect(loaded.sfxVolume, 30);
    expect(loaded.voiceEnabled, isFalse);
    expect(loaded.voiceVolume, 10);
    expect(loaded.ambientAnimationsEnabled, isFalse);
    expect(loaded.performanceQuality, PerformanceQuality.batterySaver);
    expect(loaded.lessonRemindersEnabled, isFalse);
  });

  test('load falls back to null on corrupt stored JSON', () async {
    SharedPreferences.setMockInitialValues({'app.settings': 'not json'});
    expect(await repository.load(), isNull);
  });
}
