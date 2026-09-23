import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/learner/domain/learner_profile.dart';
import 'package:tudloapp/features/learner/domain/learner_repository.dart';

LearnerProfile _profile(String id, String name) => LearnerProfile(
  id: id,
  name: name,
  grade: 1,
  energy: 60,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const repository = LearnerRepository();

  test(
    'listSavedIds and listSavedProfiles round-trip every saved profile',
    () async {
      await repository.save(_profile('a', 'Anna'));
      await repository.save(_profile('b', 'Beto'));

      final ids = await repository.listSavedIds();
      expect(ids.toSet(), {'a', 'b'});

      final profiles = await repository.listSavedProfiles();
      expect(profiles.map((p) => p.name).toSet(), {'Anna', 'Beto'});
    },
  );

  test(
    'deleteProfile removes it and leaves other saves and current intact',
    () async {
      await repository.setCurrent(_profile('a', 'Anna'));
      await repository.save(_profile('b', 'Beto'));

      await repository.deleteProfile('b');

      expect(await repository.listSavedIds(), ['a']);
      expect((await repository.loadCurrent())?.id, 'a');
    },
  );

  test('deleteProfile also clears the current pointer when deleting the '
      'current profile', () async {
    await repository.setCurrent(_profile('a', 'Anna'));

    await repository.deleteProfile('a');

    expect(await repository.listSavedIds(), isEmpty);
    expect(await repository.loadCurrent(), isNull);
  });

  test('loadLastUsed survives clearCurrent (log out)', () async {
    await repository.setCurrent(_profile('a', 'Anna'));

    await repository.clearCurrent();

    expect(await repository.loadCurrent(), isNull);
    expect((await repository.loadLastUsed())?.name, 'Anna');
  });

  test(
    'deleteProfile clears the last-used pointer too, when it matches',
    () async {
      await repository.setCurrent(_profile('a', 'Anna'));
      await repository.clearCurrent();

      await repository.deleteProfile('a');

      expect(await repository.loadLastUsed(), isNull);
    },
  );

  test('loadLastUsed is null when nothing has ever been used', () async {
    expect(await repository.loadLastUsed(), isNull);
  });
}
