import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/lesson/domain/lesson_progress.dart';
import 'package:tudloapp/features/settings/domain/app_settings.dart';

LessonCompletion _completion(String lessonId, DateTime completedAt) =>
    LessonCompletion(
      lessonId: lessonId,
      score: 10,
      accuracy: 1,
      mistakes: 0,
      duration: const Duration(minutes: 1),
      completedAt: completedAt,
      rewardAsset: 'reward.svg',
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('listSavedProfiles returns every persisted profile', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    await controller.createAndSave(name: 'Beto', grade: 2, energy: 60);

    final saved = await controller.listSavedProfiles();
    expect(saved.map((p) => p.name).toSet(), {'Anna', 'Beto'});
  });

  test('switchTo makes the profile current in memory and on disk', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    final anna = controller.profile!;
    await controller.createAndSave(name: 'Beto', grade: 2, energy: 60);
    expect(controller.profile!.name, 'Beto');

    await controller.switchTo(anna);
    expect(controller.profile!.name, 'Anna');

    // Persisted too, not just in memory.
    final fresh = LearnerController();
    await fresh.loadSaved();
    expect(fresh.profile!.name, 'Anna');
  });

  test('deleteProfile on the current profile clears it from memory', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    final id = controller.profile!.id;

    await controller.deleteProfile(id);

    expect(controller.profile, isNull);
    expect(await controller.listSavedProfiles(), isEmpty);
  });

  test(
    'deleteProfile on a non-current profile leaves the current one alone',
    () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
      final current = controller.profile!;
      await controller.createAndSave(name: 'Beto', grade: 2, energy: 60);
      // createAndSave always makes the newest one current -- switch back so
      // "Anna" is current while we delete "Beto".
      await controller.switchTo(current);

      final beto = (await controller.listSavedProfiles()).firstWhere(
        (p) => p.name == 'Beto',
      );
      await controller.deleteProfile(beto.id);

      expect(controller.profile?.name, 'Anna');
      expect((await controller.listSavedProfiles()).map((p) => p.name), [
        'Anna',
      ]);
    },
  );

  test('loadLastUsedProfile survives logOut', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);

    await controller.logOut();

    expect(controller.profile, isNull);
    expect((await controller.loadLastUsedProfile())?.name, 'Anna');
  });

  test(
    'createAndSave seeds settings from initialSettings when given',
    () async {
      const seeded = AppSettings(
        language: AppLanguage.english,
        masterVolume: 30,
        musicEnabled: false,
        musicVolume: 30,
        sfxEnabled: false,
        sfxVolume: 30,
        voiceEnabled: false,
        voiceVolume: 30,
        ambientAnimationsEnabled: false,
        performanceQuality: PerformanceQuality.batterySaver,
        lessonRemindersEnabled: false,
      );
      final controller = LearnerController();

      await controller.createAndSave(
        name: 'Anna',
        grade: 1,
        energy: 60,
        initialSettings: seeded,
      );

      expect(controller.profile!.settings.language, AppLanguage.english);
      expect(controller.profile!.settings.masterVolume, 30);
      expect(
        controller.profile!.settings.performanceQuality,
        PerformanceQuality.batterySaver,
      );
    },
  );

  test(
    'createAndSave without initialSettings falls back to AppSettings.defaults',
    () async {
      final controller = LearnerController();

      await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);

      expect(
        controller.profile!.settings.language,
        AppSettings.defaults.language,
      );
    },
  );

  test(
    'updateSettings replaces the current learner\'s settings and persists',
    () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);

      await controller.updateSettings(
        controller.profile!.settings.copyWith(language: AppLanguage.english),
      );

      expect(controller.profile!.settings.language, AppLanguage.english);

      final fresh = LearnerController();
      await fresh.loadSaved();
      expect(fresh.profile!.settings.language, AppLanguage.english);
    },
  );

  test('the day streak extends on consecutive days and resets after a '
      'skipped day', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    final day1 = DateTime(2026, 1, 1);
    final day2 = day1.add(const Duration(days: 1));
    final day4 = day1.add(const Duration(days: 3)); // day 3 skipped

    await controller.recordLessonCompletion(
      completion: _completion('l1', day1),
      nextLessonId: 'l2',
      unlockedLocationIds: const {},
    );
    expect(controller.profile!.currentStreak, 1);

    await controller.recordLessonCompletion(
      completion: _completion('l2', day2),
      nextLessonId: 'l3',
      unlockedLocationIds: const {},
    );
    expect(controller.profile!.currentStreak, 2);

    await controller.recordLessonCompletion(
      completion: _completion('l3', day4),
      nextLessonId: null,
      unlockedLocationIds: const {},
    );
    expect(controller.profile!.currentStreak, 1);
  });

  test(
    'effectiveStreak reads as broken once a day has passed with no new '
    'completion, without waiting for the next completion to notice',
    () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
      final day1 = DateTime(2026, 1, 1);
      await controller.recordLessonCompletion(
        completion: _completion('l1', day1),
        nextLessonId: 'l2',
        unlockedLocationIds: const {},
      );

      // Still today or the very next day -- today's completion may just not
      // have happened yet, so the streak should still read as intact.
      expect(controller.profile!.effectiveStreak(day1), 1);
      expect(
        controller.profile!.effectiveStreak(day1.add(const Duration(days: 1))),
        1,
      );
      // A full day skipped with nothing recorded -- reads as broken even
      // though the stored currentStreak field hasn't been touched.
      expect(
        controller.profile!.effectiveStreak(day1.add(const Duration(days: 2))),
        0,
      );
    },
  );

  test('energy drains 10 per completed lesson, replays included', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 100);
    final day1 = DateTime(2026, 1, 1);

    await controller.recordLessonCompletion(
      completion: _completion('l1', day1),
      nextLessonId: 'l2',
      unlockedLocationIds: const {},
    );
    expect(controller.profile!.effectiveEnergy(day1), 90);

    // A replay of the same lesson still costs energy.
    await controller.recordLessonCompletion(
      completion: _completion('l1', day1),
      nextLessonId: 'l2',
      unlockedLocationIds: const {},
    );
    expect(controller.profile!.effectiveEnergy(day1), 80);
  });

  test('energy regenerates 10 every 4 hours after a drain, capped at the '
      "profile's set energy level", () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 100);
    final day1 = DateTime(2026, 1, 1);

    await controller.recordLessonCompletion(
      completion: _completion('l1', day1),
      nextLessonId: 'l2',
      unlockedLocationIds: const {},
    );
    await controller.recordLessonCompletion(
      completion: _completion('l2', day1),
      nextLessonId: 'l3',
      unlockedLocationIds: const {},
    );
    expect(controller.profile!.effectiveEnergy(day1), 80);

    // Under 4 hours -- no regen tick yet.
    expect(
      controller.profile!.effectiveEnergy(day1.add(const Duration(hours: 3))),
      80,
    );
    // One whole 4-hour block passed.
    expect(
      controller.profile!.effectiveEnergy(day1.add(const Duration(hours: 4))),
      90,
    );
    // Two whole blocks.
    expect(
      controller.profile!.effectiveEnergy(day1.add(const Duration(hours: 8))),
      100,
    );
    // Never above the profile's set energy level (100 here), even with
    // more blocks than needed to reach it.
    expect(
      controller.profile!.effectiveEnergy(day1.add(const Duration(hours: 12))),
      100,
    );
  });
}
