import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfileStorage {
  // 1. Create a helper getter to fetch the safe file path asynchronously
  static Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/.tudlo_profiles_state');
  }

  static Future<String> read() async {
    // 2. Await the file instance before using it
    final file = await _file;

    if (!await file.exists()) return '';
    return file.readAsString();
  }

  static Future<void> write(String value) async {
    // 3. Await the file instance before writing to it
    final file = await _file;

    await file.writeAsString(value);
  }
}
