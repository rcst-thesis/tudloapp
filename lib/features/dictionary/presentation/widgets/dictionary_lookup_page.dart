import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_heart_icon.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_stroked_text.dart';

/// A word's meaning, shown as a plain dictionary entry page -- word,
/// phonetic, definition, example -- directly on the screen's own
/// background. No card/background box, no flip; this is what
/// [DictionaryBrowseScreen] shows when you look a word up (as opposed to
/// [DictionaryWordCard]'s flip card, which stays specific to the main
/// screen's "word of the day").
class DictionaryLookupPage extends StatefulWidget {
  const DictionaryLookupPage({
    required this.entry,
    required this.isFavorited,
    this.onFavoriteChanged,
    this.onPronunciationRequested = _placeholderPronunciation,
    super.key,
  });

  final DictionaryEntry entry;
  final bool isFavorited;
  final ValueChanged<bool>? onFavoriteChanged;
  final Future<void> Function() onPronunciationRequested;

  static Future<void> _placeholderPronunciation() async {}

  @override
  State<DictionaryLookupPage> createState() => _DictionaryLookupPageState();
}

class _DictionaryLookupPageState extends State<DictionaryLookupPage> {
  static const _feedbackDuration = Duration(milliseconds: 160);

  Timer? _speakerFeedbackTimer;
  var _speakerPressed = false;

  void _requestPronunciation() {
    setState(() => _speakerPressed = true);
    _speakerFeedbackTimer?.cancel();
    _speakerFeedbackTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _speakerPressed = false);
    });
    unawaited(widget.onPronunciationRequested());
  }

  @override
  void dispose() {
    _speakerFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Semantics(
      key: const Key('dictionary-lookup-page'),
      label: 'Definition of ${entry.word}: ${entry.definition}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // A bit lower than the back button above it.
          const SizedBox(height: 24),
          // Speaker centered above the word, not beside it.
          Center(
            child: Column(
              children: [
                _SpeakerButton(
                  pressed: _speakerPressed,
                  onTap: _requestPronunciation,
                  semanticLabel: 'Play pronunciation for ${entry.word}',
                ),
                const SizedBox(height: 8),
                DictionaryStrokedText(
                  entry.word,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.phonetic,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: DictionaryColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            entry.definition,
            style: const TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 15,
              color: DictionaryColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.example,
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: DictionaryColors.ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          // Bottom-right of the content block, not the page's own footer.
          Align(
            alignment: Alignment.centerRight,
            child: _FavoriteButton(
              favorited: widget.isFavorited,
              onTap: () => widget.onFavoriteChanged?.call(!widget.isFavorited),
              semanticLabel: widget.isFavorited
                  ? 'Remove ${entry.word} from favorites'
                  : 'Add ${entry.word} to favorites',
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({
    required this.pressed,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool pressed;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          key: const Key('dictionary-lookup-speaker-button'),
          onTap: onTap,
          radius: 24,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: AnimatedScale(
            scale: pressed ? .9 : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: DictionaryColors.heart,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.favorited,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool favorited;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      toggled: favorited,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          key: const Key('dictionary-lookup-favorite-button'),
          onTap: onTap,
          radius: 24,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: DictionaryHeartIcon(favorited: favorited),
        ),
      ),
    );
  }
}
