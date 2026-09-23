import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/domain/featured_words.dart';
import 'package:tudloapp/features/dictionary/domain/word_of_the_day.dart';
import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';

const _pool = [
  DictionaryEntry(
    id: 'a',
    word: 'a',
    phonetic: '/a/',
    definition: 'def a',
    example: 'ex a',
    category: 'test',
  ),
  DictionaryEntry(
    id: 'b',
    word: 'b',
    phonetic: '/b/',
    definition: 'def b',
    example: 'ex b',
    category: 'test',
  ),
  DictionaryEntry(
    id: 'c',
    word: 'c',
    phonetic: '/c/',
    definition: 'def c',
    example: 'ex c',
    category: 'test',
  ),
];

const _featuredPool = [
  DictionaryEntry(
    id: 'home1',
    word: 'home1',
    phonetic: '/h1/',
    definition: 'def home1',
    example: 'ex home1',
    category: 'home',
  ),
  DictionaryEntry(
    id: 'home2',
    word: 'home2',
    phonetic: '/h2/',
    definition: 'def home2',
    example: 'ex home2',
    category: 'home',
  ),
  DictionaryEntry(
    id: 'animal1',
    word: 'animal1',
    phonetic: '/a1/',
    definition: 'def animal1',
    example: 'ex animal1',
    category: 'animals',
  ),
  DictionaryEntry(
    id: 'animal2',
    word: 'animal2',
    phonetic: '/a2/',
    definition: 'def animal2',
    example: 'ex animal2',
    category: 'animals',
  ),
  DictionaryEntry(
    id: 'food1',
    word: 'food1',
    phonetic: '/f1/',
    definition: 'def food1',
    example: 'ex food1',
    category: 'food',
  ),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('resolveWordOfTheDay', () {
    test('same calendar date + valid stored id returns the cached entry', () {
      final now = DateTime(2026, 1, 15, 10);
      final selection = resolveWordOfTheDay(
        pool: _pool,
        storedId: 'b',
        storedDate: DateTime(2026, 1, 15, 3),
        history: const {'b'},
        now: now,
      );

      expect(selection.entry.id, 'b');
      expect(selection.isNew, isFalse);
      expect(selection.history, {'b'});
    });

    test('no stored date picks an unshown entry and marks it new', () {
      final selection = resolveWordOfTheDay(
        pool: _pool,
        storedId: null,
        storedDate: null,
        history: const {},
        now: DateTime(2026, 1, 15),
      );

      expect(selection.isNew, isTrue);
      expect(_pool.map((e) => e.id), contains(selection.entry.id));
      expect(selection.history, contains(selection.entry.id));
    });

    test(
      'a different calendar date picks again even with a valid stored id',
      () {
        final selection = resolveWordOfTheDay(
          pool: _pool,
          storedId: 'a',
          storedDate: DateTime(2026, 1, 14),
          history: const {'a'},
          now: DateTime(2026, 1, 15),
        );

        expect(selection.isNew, isTrue);
      },
    );

    test('never repeats an entry already in history until the pool resets', () {
      final selection = resolveWordOfTheDay(
        pool: _pool,
        storedId: null,
        storedDate: null,
        history: const {'a', 'b'},
        now: DateTime(2026, 1, 15),
      );

      expect(selection.entry.id, 'c');
      expect(selection.history, {'a', 'b', 'c'});
    });

    test('resets and reshuffles once the whole pool has been shown', () {
      final selection = resolveWordOfTheDay(
        pool: _pool,
        storedId: null,
        storedDate: null,
        history: {'a', 'b', 'c'},
        now: DateTime(2026, 1, 15),
      );

      expect(selection.isNew, isTrue);
      // History resets to just the freshly-picked entry, not the full old
      // set plus the pick.
      expect(selection.history, {selection.entry.id});
    });

    test('throws a clear error for an empty pool in every build mode '
        '(regression: this used to be a debug-only `assert`, which is '
        "stripped in release -- a caller that forgot to pre-check "
        'emptiness would crash release-only with `.first`\'s cryptic '
        '"Bad state: No element" instead)', () {
      expect(
        () => resolveWordOfTheDay(
          pool: const [],
          storedId: null,
          storedDate: null,
          history: const {},
          now: DateTime(2026, 1, 15),
        ),
        throwsArgumentError,
      );
    });
  });

  group('LearnerProfile word-of-the-day fields', () {
    test('round-trip through toJson/fromJson', () {
      final profile = LearnerProfile(
        id: '1',
        name: 'Josh',
        grade: 2,
        energy: 60,
        createdAt: DateTime(2026, 1, 1),
        wordOfTheDayId: 'balay',
        wordOfTheDayDate: DateTime(2026, 1, 15),
        wordOfTheDayHistory: const {'balay', 'ido'},
      );

      final restored = LearnerProfile.fromJson(profile.toJson());

      expect(restored.wordOfTheDayId, 'balay');
      expect(restored.wordOfTheDayDate, DateTime(2026, 1, 15));
      expect(restored.wordOfTheDayHistory, {'balay', 'ido'});
    });

    test('defaults are empty/null when absent from JSON', () {
      final profile = LearnerProfile(
        id: '1',
        name: 'Josh',
        grade: 2,
        energy: 60,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(profile.wordOfTheDayId, isNull);
      expect(profile.wordOfTheDayDate, isNull);
      expect(profile.wordOfTheDayHistory, isEmpty);
    });
  });

  group('LearnerController.recordWordOfTheDay', () {
    test('is a no-op with no current learner', () async {
      final controller = LearnerController();
      await controller.recordWordOfTheDay(
        id: 'balay',
        date: DateTime(2026, 1, 15),
        history: const {'balay'},
      );
      expect(controller.profile, isNull);
    });

    test('sets and persists the fields on the current learner', () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);

      await controller.recordWordOfTheDay(
        id: 'balay',
        date: DateTime(2026, 1, 15),
        history: const {'balay'},
      );

      expect(controller.profile!.wordOfTheDayId, 'balay');
      expect(controller.profile!.wordOfTheDayDate, DateTime(2026, 1, 15));
      expect(controller.profile!.wordOfTheDayHistory, {'balay'});
    });
  });

  group('resolveFeatured', () {
    test(
      'same calendar date + all stored ids still in pool returns cached',
      () {
        final now = DateTime(2026, 1, 15, 10);
        final selection = resolveFeatured(
          pool: _featuredPool,
          categoryCounts: const {},
          storedIds: const ['home1', 'animal1'],
          storedDate: DateTime(2026, 1, 15, 3),
          history: const {'home1', 'animal1'},
          now: now,
        );

        expect(selection.ids, ['home1', 'animal1']);
        expect(selection.isNew, isFalse);
      },
    );

    test('favors the highest-count category more often than not (weighted, '
        'not a guaranteed strict sort)', () {
      // The featured tray deliberately uses weighted-random category
      // ordering (see _weightedCategoryOrder in featured_words.dart) so a
      // category that got an early lead doesn't permanently dominate every
      // single day -- so this can't assert a single deterministic outcome.
      // Instead, run many independent picks and check the heavily-favored
      // category ("animals", weight 6 of 9 vs "home"'s 2 and "food"'s 1)
      // comes out on top far more often than a uniform 1-in-3 chance would
      // predict.
      const trials = 300;
      var animalFirst = 0;
      for (var i = 0; i < trials; i++) {
        final selection = resolveFeatured(
          pool: _featuredPool,
          categoryCounts: const {'animals': 5, 'home': 1, 'food': 0},
          storedIds: null,
          storedDate: null,
          history: const {},
          slotCount: 1,
          now: DateTime(2026, 1, 15),
        );
        if (selection.ids.single.startsWith('animal')) animalFirst++;
      }

      // Uniform-by-category would land near 100 (1/3 of 300); weighted
      // toward "animals" should land well above that.
      expect(animalFirst, greaterThan(150));
    });

    test('backfills across categories when the top category runs out', () {
      final selection = resolveFeatured(
        pool: _featuredPool,
        categoryCounts: const {'food': 10, 'animals': 5, 'home': 1},
        storedIds: null,
        storedDate: null,
        history: const {},
        slotCount: 3,
        now: DateTime(2026, 1, 15),
      );

      expect(selection.isNew, isTrue);
      expect(selection.ids, contains('food1'));
      expect(selection.ids.length, 3);
    });

    test('resets and reshuffles once the pool has been fully featured', () {
      final history = _featuredPool.map((e) => e.id).toSet();
      final selection = resolveFeatured(
        pool: _featuredPool,
        categoryCounts: const {},
        storedIds: null,
        storedDate: null,
        history: history,
        slotCount: 5,
        now: DateTime(2026, 1, 15),
      );

      expect(selection.isNew, isTrue);
      expect(selection.ids.toSet(), history);
      expect(selection.history, history);
    });

    test('works with an all-zero-count pool (no search history yet)', () {
      final selection = resolveFeatured(
        pool: _featuredPool,
        categoryCounts: const {},
        storedIds: null,
        storedDate: null,
        history: const {},
        slotCount: 5,
        now: DateTime(2026, 1, 15),
      );

      expect(selection.isNew, isTrue);
      expect(selection.ids.length, 5);
      expect(selection.ids.toSet(), _featuredPool.map((e) => e.id).toSet());
    });

    test('throws a clear error for an empty pool in every build mode '
        '(regression: this used to be a debug-only `assert`, which is '
        'stripped in release)', () {
      expect(
        () => resolveFeatured(
          pool: const [],
          categoryCounts: const {},
          storedIds: null,
          storedDate: null,
          history: const {},
          now: DateTime(2026, 1, 15),
        ),
        throwsArgumentError,
      );
    });
  });

  group('decayCategorySearchCounts', () {
    test('halves each count, flooring, and drops entries that hit zero', () {
      final decayed = decayCategorySearchCounts({
        'home': 10,
        'animals': 3,
        'food': 1,
      });

      expect(decayed, {'home': 5, 'animals': 1});
      expect(decayed.containsKey('food'), isFalse);
    });

    test('an empty map stays empty', () {
      expect(decayCategorySearchCounts({}), isEmpty);
    });
  });

  group('LearnerProfile featured/category fields', () {
    test('round-trip through toJson/fromJson', () {
      final profile = LearnerProfile(
        id: '1',
        name: 'Josh',
        grade: 2,
        energy: 60,
        createdAt: DateTime(2026, 1, 1),
        categorySearchCounts: const {'home': 3, 'animals': 1},
        featuredIds: const ['balay', 'ido'],
        featuredDate: DateTime(2026, 1, 15),
        featuredHistory: const {'balay', 'ido'},
      );

      final restored = LearnerProfile.fromJson(profile.toJson());

      expect(restored.categorySearchCounts, {'home': 3, 'animals': 1});
      expect(restored.featuredIds, ['balay', 'ido']);
      expect(restored.featuredDate, DateTime(2026, 1, 15));
      expect(restored.featuredHistory, {'balay', 'ido'});
    });

    test('defaults are empty/null when absent from JSON', () {
      final profile = LearnerProfile(
        id: '1',
        name: 'Josh',
        grade: 2,
        energy: 60,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(profile.categorySearchCounts, isEmpty);
      expect(profile.featuredIds, isEmpty);
      expect(profile.featuredDate, isNull);
      expect(profile.featuredHistory, isEmpty);
    });
  });

  group('LearnerController featured/category mutators', () {
    test(
      'incrementCategorySearchCount is a no-op with no current learner',
      () async {
        final controller = LearnerController();
        await controller.incrementCategorySearchCount('home');
        expect(controller.profile, isNull);
      },
    );

    test('incrementCategorySearchCount bumps and persists the count', () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);

      await controller.incrementCategorySearchCount('home');
      await controller.incrementCategorySearchCount('home');
      await controller.incrementCategorySearchCount('animals');

      expect(controller.profile!.categorySearchCounts, {
        'home': 2,
        'animals': 1,
      });
    });

    test('recordFeatured is a no-op with no current learner', () async {
      final controller = LearnerController();
      await controller.recordFeatured(
        ids: const ['balay'],
        date: DateTime(2026, 1, 15),
        history: const {'balay'},
      );
      expect(controller.profile, isNull);
    });

    test('recordFeatured sets and persists the fields', () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);

      await controller.recordFeatured(
        ids: const ['balay', 'ido'],
        date: DateTime(2026, 1, 15),
        history: const {'balay', 'ido'},
      );

      expect(controller.profile!.featuredIds, ['balay', 'ido']);
      expect(controller.profile!.featuredDate, DateTime(2026, 1, 15));
      expect(controller.profile!.featuredHistory, {'balay', 'ido'});
    });
  });

  group('LearnerController.logOut', () {
    test('is a no-op with no current learner', () async {
      final controller = LearnerController();
      await controller.logOut();
      expect(controller.profile, isNull);
    });

    test('clears the in-memory profile immediately', () async {
      final controller = LearnerController();
      await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);
      expect(controller.profile, isNotNull);

      await controller.logOut();

      expect(controller.profile, isNull);
    });

    test(
      'forgets the learner as "current" on disk, not just in memory',
      () async {
        final controller = LearnerController();
        await controller.createAndSave(name: 'Josh', grade: 2, energy: 60);

        await controller.logOut();

        // A fresh controller/repository read (simulating a relaunch) must not
        // resume the logged-out learner.
        final reloaded = LearnerController();
        await reloaded.loadSaved();
        expect(reloaded.profile, isNull);
      },
    );
  });
}
