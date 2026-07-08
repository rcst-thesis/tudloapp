import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tudloapp/core/services/json_loader.dart';

class ContentRepository {
  final AssetBundle? _bundle;
  final _mapCache = <String, Future<Map<String, dynamic>>>{};
  final _listCache = <String, Future<List<dynamic>>>{};

  ContentRepository({AssetBundle? bundle}) : _bundle = bundle;

  Future<Map<String, dynamic>> loadMap(String path) {
    return _mapCache.putIfAbsent(
      path,
      () => JsonLoader.loadMap(path, bundle: _bundle),
    );
  }

  Future<List<dynamic>> loadList(String path) {
    return _listCache.putIfAbsent(
      path,
      () => JsonLoader.loadList(path, bundle: _bundle),
    );
  }

  void clear() {
    _mapCache.clear();
    _listCache.clear();
  }
}
