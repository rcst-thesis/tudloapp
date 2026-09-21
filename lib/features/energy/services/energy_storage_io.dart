import 'package:shared_preferences/shared_preferences.dart';

class EnergyStorage {
  static const _prefix = 'tudlo.energy.';

  static Future<Map<String, String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'currentEnergy': prefs.getString('${_prefix}currentEnergy') ?? '',
      'lastEnergyAt': prefs.getString('${_prefix}lastEnergyAt') ?? '',
    };
  }

  static Future<void> write(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      await prefs.setString('$_prefix${entry.key}', entry.value);
    }
  }
}
