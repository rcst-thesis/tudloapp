import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

class CsvReader {
  String filepath;
  File file;

  CsvReader({required this.filepath}) : file = File(filepath);

  /// print(rows.first); // e.g. ['Name', 'Age', 'City']
  Future<List<dynamic>> read() async {
    final List<List<dynamic>> rows = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(csv.decoder)
        .toList();

    return rows;
  }
}
