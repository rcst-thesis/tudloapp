import 'package:flutter/widgets.dart';

/// The header's top offset for both Dictionary screens: real status-bar
/// clearance (via [MediaQuery], not [SafeArea]) plus deliberate breathing
/// room. Both `DictionaryScreen` and `DictionaryBrowseScreen` must use this
/// exact same formula -- full-bleed everywhere else, but the header has to
/// land in the identical on-screen spot on both, or tapping the decoy
/// search bar would visibly shift content and give away the "navigation".
double dictionaryTopOffset(BuildContext context, double scale) {
  return MediaQuery.of(context).padding.top + 16 * scale;
}
