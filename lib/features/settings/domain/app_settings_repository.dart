import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudloapp/features/settings/domain/app_settings.dart';

/// Persists the device-wide [AppSettings] to on-device storage via
/// `shared_preferences` -- one JSON blob under one fixed key, unlike
/// `LearnerRepository` (`lib/features/learner/domain/learner_repository.dart`)
/// which keys multiple profiles by id. This is the "main menu settings"
/// store: what's in effect when nobody is signed in.
class AppSettingsRepository {
  const AppSettingsRepository();

  static const _key = 'app.settings';

  /// `null` if nothing has ever been saved, or the saved value is corrupt.
  Future<AppSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
