import 'package:flutter/material.dart';

import 'package:tudloapp/shared/widgets/content_footer_wave.dart';

/// Decorative closing edge for the bottom of the Lessons screen's
/// scrollable content: a single wave, matching the same shape every other
/// screen's content footer uses (Home/Dictionary/Me), filled with this
/// screen's #00B4D8.
class LessonContentFooter extends StatelessWidget {
  const LessonContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentFooterWave(
      color: Color(0xFF00B4D8),
      paintKey: Key('lesson-content-footer'),
    );
  }
}
