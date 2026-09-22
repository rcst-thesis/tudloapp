import 'package:flutter/material.dart';

import 'package:tudloapp/shared/widgets/content_footer_wave.dart';

/// Decorative closing edge for the bottom of the Me screen's scrollable
/// content: a single wave, matching the lowest/front wave shape from
/// Home's content footer, filled with this screen's #9D7C21.
class MeContentFooter extends StatelessWidget {
  const MeContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentFooterWave(
      color: Color(0xFF9D7C21),
      paintKey: Key('me-content-footer'),
    );
  }
}
