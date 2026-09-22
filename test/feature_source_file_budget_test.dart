import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tudlo-authored Home, Lesson, and Map files stay reviewable', () {
    const featurePaths = [
      'lib/features/home',
      'lib/features/lesson',
      'lib/features/map',
    ];
    final oversized = <String>[];

    for (final featurePath in featurePaths) {
      for (final entity in Directory(featurePath).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lineCount = entity.readAsLinesSync().length;
        if (lineCount > 500) oversized.add('${entity.path} ($lineCount lines)');
      }
    }

    // This protects the maintainable Tudlo integration. The preserved DevG
    // source now lives under lib/vendor/devg/, outside these feature paths,
    // so it no longer needs an exclusion here.
    expect(
      oversized,
      isEmpty,
      reason:
          'Split a source file by lifecycle, data, or visual responsibility.',
    );
  });
}
