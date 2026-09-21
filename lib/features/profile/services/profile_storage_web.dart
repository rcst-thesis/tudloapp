import 'package:web/web.dart' as web;

class ProfileStorage {
  static const _key = 'tudlo.profiles.state';

  static Future<String> read() async {
    return web.window.localStorage.getItem(_key) ?? '';
  }

  static Future<void> write(String value) async {
    web.window.localStorage.setItem(_key, value);
  }
}
