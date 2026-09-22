import 'dart:convert';

import 'package:flutter/services.dart';

/// Read-only JSON cache used by the copied DevG lesson data.
///
/// This deliberately replaces DevG's app-wide loader. Lesson content remains
/// bundled in Tudlo, while learner state continues to live in Tudlo's learner
/// feature.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;
  final _maps = <String, Future<Map<String, dynamic>>>{};
  final _lists = <String, Future<List<dynamic>>>{};

  Future<Map<String, dynamic>> loadMap(String path) =>
      _maps.putIfAbsent(path, () => _loadMap(path));

  Future<List<dynamic>> loadList(String path) =>
      _lists.putIfAbsent(path, () => _loadList(path));

  void clear() {
    _maps.clear();
    _lists.clear();
  }

  Future<Map<String, dynamic>> _loadMap(String path) async {
    final raw = await (_bundle ?? rootBundle).loadString(path);
    final value = jsonDecode(raw);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object.');
  }

  Future<List<dynamic>> _loadList(String path) async {
    final raw = await (_bundle ?? rootBundle).loadString(path);
    final value = jsonDecode(raw);
    if (value is List<dynamic>) return value;
    throw const FormatException('Expected a JSON list.');
  }
}
