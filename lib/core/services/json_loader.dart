import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

dynamic _decodeJson(Uint8List bytes) => jsonDecode(utf8.decode(bytes));

/// Type definition for standard JSON factory constructors.
typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

/// A performant, generic utility for asynchronously loading and parsing JSON assets.
///
/// Decodes JSON with Flutter's platform-aware background compute helper.
class JsonLoader {
  // Prevent instantiation of this utility class.
  JsonLoader._();

  /// Loads a JSON file from the assets folder and returns it as a [Map<String, dynamic>].
  /// Parsing and UTF-8 decoding are offloaded to a background isolate to prevent UI frame drops,
  /// making it capable of easily handling large files (10MB+).
  ///
  /// [bundle] is optional and allows for dependency injection during unit testing.
  ///
  /// Example Usage:
  /// ```dart
  /// final map = await JsonLoader.loadMap('assets/data/user.json');
  /// final user = User.fromJson(map);
  /// ```
  static Future<Map<String, dynamic>> loadMap(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final dynamic decoded = await _loadAndDecode(assetPath, bundle);

    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'Expected a JSON object (Map) but got ${decoded.runtimeType} in $assetPath',
      );
    }

    return decoded;
  }

  /// Loads a JSON file from the assets folder and returns it as a [List<dynamic>].
  /// Parsing and UTF-8 decoding are offloaded to a background isolate.
  ///
  /// [bundle] is optional and allows for dependency injection during unit testing.
  static Future<List<dynamic>> loadList(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final dynamic decoded = await _loadAndDecode(assetPath, bundle);

    if (decoded is! List) {
      throw FormatException(
        'Expected a JSON array (List) but got ${decoded.runtimeType} in $assetPath',
      );
    }

    return decoded;
  }

  /// A high-level generic method that loads the JSON map and pipes it directly into your factory.
  ///
  /// Example Usage:
  /// ```dart
  /// final user = await JsonLoader.loadObject('assets/data/user.json', User.fromJson);
  /// ```
  static Future<T> loadObject<T>(
    String assetPath,
    JsonFactory<T> fromJson, {
    AssetBundle? bundle,
  }) async {
    final map = await loadMap(assetPath, bundle: bundle);
    return fromJson(map);
  }

  /// Helper to safely load raw bytes and offload BOTH UTF-8 decoding and JSON parsing
  /// to a background isolate. This is crucial for maintaining 60/120fps with huge JSON files.
  static Future<dynamic> _loadAndDecode(
    String path,
    AssetBundle? bundle,
  ) async {
    try {
      final activeBundle = bundle ?? rootBundle;
      final ByteData byteData = await activeBundle.load(path);

      return await compute(
        _decodeJson,
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        debugLabel: 'decode $path',
      );
    } catch (e) {
      throw Exception('Failed to load or parse asset at $path. Error: $e');
    }
  }
}
