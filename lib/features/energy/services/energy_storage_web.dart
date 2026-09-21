import 'package:web/web.dart' as web;

/// Browser-backed energy storage.
///
/// localStorage survives tab closes, which lets recharge calculations compare
/// the saved timestamp against the real current time when the app opens again.
class EnergyStorage {
  static const _prefix = 'tudlo.energy.';

  static Future<Map<String, String>> read() async {
    final storage = web.window.localStorage;
    return {
      'currentEnergy': storage.getItem('${_prefix}currentEnergy') ?? '',
      'lastEnergyAt': storage.getItem('${_prefix}lastEnergyAt') ?? '',
    };
  }

  static Future<void> write(Map<String, String> values) async {
    final storage = web.window.localStorage;
    for (final entry in values.entries) {
      storage.setItem('$_prefix${entry.key}', entry.value);
    }
  }
}
