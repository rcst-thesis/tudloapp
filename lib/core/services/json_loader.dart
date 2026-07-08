import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'dart:typed_data';

/// Type definition for standard JSON factory constructors.
typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

/// A generic utility class for loading JSON files from the Flutter assets folder.
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

      return await Isolate.run(() {
        final uint8List = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        final String jsonString = utf8.decode(uint8List);
        return jsonDecode(jsonString);
      });
    } catch (e) {
      throw Exception('Failed to load or parse asset at $path. Error: $e');
    }
  }
}
