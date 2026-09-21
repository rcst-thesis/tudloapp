import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';

/// The pill-shaped search field. Two modes:
/// - Functional (`readOnly: false`, the default): a normal search field,
///   [controller] drives live filtering. Used inside
///   `DictionaryBrowseScreen`. Optionally shows an inline "ghost text"
///   autocomplete suffix (see [ghostSuggestion]) right after the cursor.
/// - Decoy (`readOnly: true`): looks identical but can't be typed into
///   ([IgnorePointer]'d) -- tapping anywhere on the bar fires [onTap]
///   instead. [DictionaryScreen] uses this to open the browse screen while
///   looking like an inline search bar. Never shows ghost text.
class DictionarySearchBar extends StatelessWidget {
  const DictionarySearchBar({
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.ghostSuggestion,
    this.fieldKey = const Key('dictionary-search-field'),
    super.key,
  });

  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  /// The remaining characters of a plausible autocomplete for whatever's
  /// currently in [controller] (see
  /// `dictionary_search.dart#autocompleteSuggestion`) -- just the suffix,
  /// not the whole word. Rendered faded, immediately after the typed text,
  /// purely as a spelling aid; not tappable/acceptable. `null`/empty means
  /// no ghost text is shown (the common case: no controller text yet, no
  /// plausible completion, or the caller doesn't want one -- e.g. the decoy
  /// bar never passes this).
  final String? ghostSuggestion;

  /// Distinct per screen -- both the main screen's decoy bar and the
  /// browse screen's real one can be mounted at once (routes stay alive
  /// underneath), so they can't share one key.
  final Key fieldKey;

  static const _textStyle = TextStyle(
    color: DictionaryColors.ink,
    fontSize: 16,
  );

  // Icon moved out of TextField's `prefixIcon` into a plain Row sibling
  // (see build()) specifically so the ghost-text layer's alignment doesn't
  // have to replicate InputDecorator's internal icon-layout math -- both
  // the ghost text and the real field's own `contentPadding` line up
  // directly since there's no icon-width offset baked into either.
  static const _contentPadding = EdgeInsets.symmetric(vertical: 14);

  @override
  Widget build(BuildContext context) {
    final icon = Padding(
      padding: const EdgeInsets.all(10),
      // Explicit size -- the source SVG's own viewBox is 37x37, larger than
      // this pill comfortably fits now that the icon is a plain Row
      // sibling (previously it implicitly rendered smaller inside
      // TextField's `prefixIcon` slot). 24x24 matches the standard
      // Material icon size.
      child: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/images/dictionary_search_icon.svg',
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );

    final field = TextField(
      key: fieldKey,
      controller: controller,
      readOnly: readOnly,
      focusNode: focusNode,
      style: _textStyle,
      decoration: const InputDecoration(
        // Otherwise TextField reserves extra vertical space for a
        // helper/error line even though this bar never shows one -- that
        // made it visibly taller than the same-height back pill beside it
        // on the browse screen.
        isDense: true,
        hintText: 'search',
        hintStyle: TextStyle(color: DictionaryColors.ink),
        border: InputBorder.none,
        contentPadding: _contentPadding,
      ),
    );

    final ghost = ghostSuggestion;
    final showGhost = ghost != null && ghost.isNotEmpty;
    // `field` always sits inside this same Stack, whether or not a ghost
    // suggestion is showing right now -- only the ghost layer child comes
    // and goes. Previously this branched between a bare `field` and a
    // Stack-wrapped `field`, which meant the TextField's *parent type*
    // changed every time a suggestion appeared or disappeared (very
    // often, mid-keystroke, since most typed prefixes have no plausible
    // completion). Flutter tears down and recreates an Element whose
    // parent type changed, which destroys the TextField's live platform
    // keyboard connection -- dismissing the keyboard out from under the
    // learner while they were still typing (or right as they hit
    // enter, if the ghost suggestion happened to disappear at that
    // moment). Keeping `field`'s parent shape constant lets Flutter's
    // keyed reconciliation reuse the same element/connection across every
    // build.
    final fieldArea = Stack(
      children: [
        if (showGhost)
          // Ghost layer, painted behind: an invisible copy of the typed
          // text (so its width lines up exactly with the real field's
          // rendered text) followed by the faded suggestion suffix. Same
          // padding as the real field's `contentPadding` so both
          // baselines/left edges match.
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: _contentPadding,
                child: Text.rich(
                  key: const Key('dictionary-search-ghost-text'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: controller?.text ?? '',
                        style: _textStyle.copyWith(color: Colors.transparent),
                      ),
                      TextSpan(
                        text: ghost,
                        style: _textStyle.copyWith(
                          color: DictionaryColors.ink.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        field,
      ],
    );

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: DictionaryColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          icon,
          Expanded(
            child: readOnly ? IgnorePointer(child: fieldArea) : fieldArea,
          ),
        ],
      ),
    );
    if (!readOnly) return bar;
    return Semantics(
      button: true,
      label: 'Browse the dictionary',
      child: GestureDetector(
        key: const Key('dictionary-search-bar-tap'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: bar,
      ),
    );
  }
}
