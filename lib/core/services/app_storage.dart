import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _prefix = 'tudlo.app.';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<Map<String, dynamic>> readAppData() async {
    final p = await _prefs;
    return {
      'streakDays': p.getInt('${_prefix}streakDays') ?? 0,
      'unlockedLevel': p.getInt('${_prefix}unlockedLevel') ?? 1,
      'levelStars': p.getString('${_prefix}levelStars') ?? '',
      'bestTestScores': p.getString('${_prefix}bestTestScores') ?? '',
      'completedLevels': p.getString('${_prefix}completedLevels') ?? '',
    };
  }

  static Future<void> writeAppData({
    required int streakDays,
    required int unlockedLevel,
    required Map<int, int> levelStars,
    required Map<int, int> bestTestScores,
    required Set<int> completedLevels,
  }) async {
    final p = await _prefs;
    await Future.wait([
      p.setInt('${_prefix}streakDays', streakDays),
      p.setInt('${_prefix}unlockedLevel', unlockedLevel),
      p.setString(
        '${_prefix}levelStars',
        levelStars.entries.map((e) => '${e.key}:${e.value}').join(','),
      ),
      p.setString(
        '${_prefix}bestTestScores',
        bestTestScores.entries.map((e) => '${e.key}:${e.value}').join(','),
      ),
      p.setString('${_prefix}completedLevels', completedLevels.join(',')),
    ]);
  }

  static Future<Map<String, dynamic>> readAppState() async {
    final p = await _prefs;
    return {
      'username': p.getString('${_prefix}username') ?? '',
      'ageRange': p.getString('${_prefix}ageRange') ?? '',
      'knowledgeLabel': p.getString('${_prefix}knowledgeLabel') ?? '',
      'knowledgeLevel': p.getInt('${_prefix}knowledgeLevel') ?? 1,
      'homeMapDataset': p.getString('${_prefix}homeMapDataset') ?? 'easy',
      'onboardingComplete': p.getBool('${_prefix}onboardingComplete') ?? false,
    };
  }

  static Future<Map<String, dynamic>> readDeveloperSettings() async {
    final p = await _prefs;
    return {
      'developerMode': p.getBool('${_prefix}developerMode') ?? false,
      'dailyWordDemoOffset': p.getInt('${_prefix}dailyWordDemoOffset') ?? 0,
    };
  }

  static Future<void> writeDeveloperSettings({
    required bool developerMode,
    required int dailyWordDemoOffset,
  }) async {
    final p = await _prefs;
    await Future.wait([
      p.setBool('${_prefix}developerMode', developerMode),
      p.setInt('${_prefix}dailyWordDemoOffset', dailyWordDemoOffset),
    ]);
  }

  static Future<Map<String, bool>> readTranslationSettings() async {
    final p = await _prefs;
    return {
      'profanityFilterEnabled':
          p.getBool('${_prefix}profanityFilterEnabled') ?? true,
      'dictionaryFallbackEnabled':
          p.getBool('${_prefix}dictionaryFallbackEnabled') ?? true,
    };
  }

  static Future<void> writeTranslationSettings({
    required bool profanityFilterEnabled,
    required bool dictionaryFallbackEnabled,
  }) async {
    final p = await _prefs;
    await Future.wait([
      p.setBool('${_prefix}profanityFilterEnabled', profanityFilterEnabled),
      p.setBool(
        '${_prefix}dictionaryFallbackEnabled',
        dictionaryFallbackEnabled,
      ),
    ]);
  }

  static Future<void> writeAppState({
    required String username,
    required String ageRange,
    required String knowledgeLabel,
    required int knowledgeLevel,
    required String homeMapDataset,
    required bool onboardingComplete,
  }) async {
    final p = await _prefs;
    await Future.wait([
      p.setString('${_prefix}username', username),
      p.setString('${_prefix}ageRange', ageRange),
      p.setString('${_prefix}knowledgeLabel', knowledgeLabel),
      p.setInt('${_prefix}knowledgeLevel', knowledgeLevel),
      p.setString('${_prefix}homeMapDataset', homeMapDataset),
      p.setBool('${_prefix}onboardingComplete', onboardingComplete),
    ]);
  }

  static Map<int, int> parseIntPairMap(String raw) {
    if (raw.isEmpty) return {};
    return Map.fromEntries(
      raw.split(',').map((e) {
        final parts = e.split(':');
        return MapEntry(int.parse(parts[0]), int.parse(parts[1]));
      }),
    );
  }

  static Set<int> parseIntSet(String raw) {
    if (raw.isEmpty) return {};
    return raw.split(',').map(int.parse).toSet();
  }
}
