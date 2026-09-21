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
    final canonicalBridgeSegment =
        '${Platform.pathSeparator}devg_canonical${Platform.pathSeparator}';

    for (final featurePath in featurePaths) {
      for (final entity in Directory(featurePath).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // This is authorized source retained verbatim for visual/mechanical
        // fidelity during the DevG migration. It is audited and documented as
        // a temporary extraction target, not a precedent for new Tudlo code.
        if (entity.path.contains(canonicalBridgeSegment)) continue;
        final lineCount = entity.readAsLinesSync().length;
        if (lineCount > 500) oversized.add('${entity.path} ($lineCount lines)');
      }
    }

    // This protects the maintainable Tudlo integration. The documented
    // `devg_canonical` preservation bridge is intentionally excluded until
    // its original flows are extracted without altering their child-facing UI.
    expect(
      oversized,
      isEmpty,
      reason:
          'Split a source file by lifecycle, data, or visual responsibility.',
    );
  });
}
