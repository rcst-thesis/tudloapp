import 'package:flutter/material.dart';

import 'package:tudloapp/shared/widgets/content_footer_wave.dart';

/// Decorative closing edge for the bottom of the Dictionary screens'
/// scrollable content: a single wave, matching the same shape every other
/// screen's content footer uses (Home/Me), filled with this screen's
/// #FF667D.
class DictionaryContentFooter extends StatelessWidget {
  const DictionaryContentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentFooterWave(
      color: Color(0xFFFF667D),
      paintKey: Key('dictionary-content-footer'),
    );
  }
}
