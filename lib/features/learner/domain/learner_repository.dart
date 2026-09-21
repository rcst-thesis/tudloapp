import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/learner/domain/learner_profile.dart';

/// Persists [LearnerProfile]s to on-device storage via `shared_preferences`
/// -- the whole profile is one small JSON blob, read/written as a unit,
/// never queried by field, which is exactly what `shared_preferences` is
/// for. No backend, no sync: this is local-only, per-device storage.
///
/// Only one learner is "current" at a time, but every profile is stored
/// keyed by its own [LearnerProfile.id] (see [listSavedProfiles]), so
/// switching, deleting, or reloading one doesn't touch the others.
class LearnerRepository {
  const LearnerRepository();

  static const _currentIdKey = 'learner.currentId';
  static const _lastUsedIdKey = 'learner.lastUsedId';
  static String _profileKey(String id) => 'learner.profile.$id';

  /// A reasonably unique id for a new learner -- fine for local,
  /// single-device uniqueness, which is all this needs today.
  static String generateId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }

  Future<LearnerProfile?> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentIdKey);
    if (id == null) return null;
    final raw = prefs.getString(_profileKey(id));
    if (raw == null) return null;
    return LearnerProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> save(LearnerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(profile.id),
      jsonEncode(profile.toJson()),
    );
  }

  Future<void> setCurrent(LearnerProfile profile) async {
    await save(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentIdKey, profile.id);
    // "Last used" is deliberately never cleared by `clearCurrent` (log
    // out) -- see `loadLastUsed`.
    await prefs.setString(_lastUsedIdKey, profile.id);
  }

  /// Logs out: forgets which learner is "current" (their saved profile
  /// itself is left on disk, untouched) so [loadCurrent] returns `null`
  /// again, same as a fresh install, until someone completes onboarding.
  Future<void> clearCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentIdKey);
  }

  /// The most recently active learner, even after [clearCurrent] (log out)
  /// -- unlike [loadCurrent], logging out does not clear this. Lets the
  /// main menu's "continue" keep naming whoever you'd resume, independent
  /// of whether anyone is actively signed in right now.
  Future<LearnerProfile?> loadLastUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastUsedIdKey);
    if (id == null) return null;
    final raw = prefs.getString(_profileKey(id));
    if (raw == null) return null;
    try {
      return LearnerProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  /// Every learner id currently saved on this device -- every profile is
  /// individually keyed (see class doc), so this is just a key scan, no
  /// separate index to keep in sync.
  Future<List<String>> listSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    const prefix = 'learner.profile.';
    return prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .toList();
  }

  /// Every learner currently saved on this device (the Load screen's real
  /// save list). Silently skips any entry that fails to parse rather than
  /// letting one corrupt save take down the whole list.
  Future<List<LearnerProfile>> listSavedProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await listSavedIds();
    final profiles = <LearnerProfile>[];
    for (final id in ids) {
      final raw = prefs.getString(_profileKey(id));
      if (raw == null) continue;
      try {
        profiles.add(
          LearnerProfile.fromJson(jsonDecode(raw) as Map<String, Object?>),
        );
      } catch (_) {
        // Corrupt entry -- skip it rather than fail the whole list.
      }
    }
    return profiles;
  }

  /// Removes [id]'s saved data outright (not just "current" -- see
  /// [clearCurrent] for that). Also clears the "current" pointer if it was
  /// pointing at [id], so a deleted profile can never still read back as
  /// current.
  Future<void> deleteProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey(id));
    if (prefs.getString(_currentIdKey) == id) {
      await prefs.remove(_currentIdKey);
    }
    if (prefs.getString(_lastUsedIdKey) == id) {
      await prefs.remove(_lastUsedIdKey);
    }
  }
}
