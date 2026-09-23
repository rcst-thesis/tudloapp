import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/presentation/dictionary_colors.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_asset_image.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_card_front.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_heart_icon.dart';
import 'package:tudloapp/features/dictionary/presentation/widgets/dictionary_stroked_text.dart';

/// The "word of the day" flip card: tapping rotates between [entry]'s
/// illustrated front face and a definition-bearing back face.
class DictionaryWordCard extends StatefulWidget {
  const DictionaryWordCard({
    required this.entry,
    required this.isFavorited,
    this.onFavoriteChanged,
    this.onPronunciationRequested = _placeholderPronunciation,
    super.key,
  });

  final DictionaryEntry entry;
  final bool isFavorited;
  final ValueChanged<bool>? onFavoriteChanged;

  /// Inject the real pronunciation player here when its VO is available.
  final Future<void> Function() onPronunciationRequested;

  static Future<void> _placeholderPronunciation() async {}

  @override
  State<DictionaryWordCard> createState() => _DictionaryWordCardState();
}

class _DictionaryWordCardState extends State<DictionaryWordCard>
    with SingleTickerProviderStateMixin {
  static const _feedbackDuration = Duration(milliseconds: 160);

  late final AnimationController _flipController;
  Timer? _heartFeedbackTimer;
  Timer? _speakerFeedbackTimer;
  var _heartPopped = false;
  var _speakerPressed = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _toggleFlip() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (_flipController.value < 0.5) {
      if (disableAnimations) {
        _flipController.value = 1;
      } else {
        _flipController.forward();
      }
    } else {
      if (disableAnimations) {
        _flipController.value = 0;
      } else {
        _flipController.reverse();
      }
    }
  }

  void _toggleFavorite() {
    setState(() => _heartPopped = true);
    widget.onFavoriteChanged?.call(!widget.isFavorited);
    _heartFeedbackTimer?.cancel();
    _heartFeedbackTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _heartPopped = false);
    });
  }

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
    _flipController.dispose();
    _heartFeedbackTimer?.cancel();
    _speakerFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Semantics(
      key: const Key('dictionary-word-card'),
      label: 'Word of the day: ${entry.word}. ${entry.definition}',
      child: GestureDetector(
        onTap: _toggleFlip,
        child: AspectRatio(
          // Fixed card shape for both faces. Taller than the original
          // 378/260 -- that ratio left too little vertical room for the
          // back face's text. Matches balay_dictionary.png's own shape
          // closely too, so the front face's art barely letterboxes.
          aspectRatio: 1449 / 1136,
          child: AnimatedBuilder(
            animation: _flipController,
            builder: (context, child) {
              final angle = _flipController.value * math.pi;
              final showBack = angle > math.pi / 2;
              final displayAngle = showBack ? angle - math.pi : angle;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(displayAngle),
                child: showBack ? _buildBack(entry) : _buildFront(entry),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront(DictionaryEntry entry) {
    final frontCardImage = entry.frontCardImage;
    return Column(
      children: [
        Expanded(
          child: frontCardImage != null
              ? DictionaryAssetImage(path: frontCardImage, fit: BoxFit.contain)
              : DictionaryCardFront(entry: entry, wordFontSize: 26),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'tap to flip',
            style: TextStyle(
              fontFamily: 'ComicRelief',
              color: DictionaryColors.ink.withValues(alpha: 0.56),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBack(DictionaryEntry entry) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DictionaryColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              // Stack defaults to top-left alignment for non-positioned
              // children -- without this, the FittedBox-scaled label block
              // (below) sits pinned to the top-left corner instead of
              // centered whenever it scales down to fit.
              alignment: Alignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    // FittedBox gives its child unbounded constraints, so
                    // without this the definition text (the long one) never
                    // wraps -- it lays out as one huge single line, forcing
                    // FittedBox to scale the whole block down drastically
                    // to fit the available width. That scale-down cancels
                    // out any font-size change, which is why bumping sizes
                    // earlier had no visible effect. Pinning a real width
                    // here lets text wrap normally first.
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _WordCardIconButton(
                          key: const Key('dictionary-word-speaker-button'),
                          semanticLabel: 'Play pronunciation for ${entry.word}',
                          onTap: _requestPronunciation,
                          child: AnimatedScale(
                            scale: _speakerPressed ? .9 : 1,
                            duration: _feedbackDuration,
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
                                  color: DictionaryColors.cardBackground,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: DictionaryStrokedText(
                            entry.word,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: DictionaryStrokedText(
                            entry.phonetic,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: DictionaryStrokedText(
                            entry.definition,
                            fontSize: 14,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            entry.example,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'ComicRelief',
                              color: DictionaryColors.ink.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: _WordCardIconButton(
                    key: const Key('dictionary-word-favorite-button'),
                    semanticLabel: widget.isFavorited
                        ? 'Remove ${entry.word} from favorites'
                        : 'Add ${entry.word} to favorites',
                    toggled: widget.isFavorited,
                    onTap: _toggleFavorite,
                    child: AnimatedScale(
                      scale: _heartPopped ? 1.12 : 1,
                      duration: _feedbackDuration,
                      curve: Curves.easeOutBack,
                      child: DictionaryHeartIcon(favorited: widget.isFavorited),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WordCardIconButton extends StatelessWidget {
  const _WordCardIconButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.toggled,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      toggled: toggled,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          containedInkWell: true,
          child: Center(child: child),
        ),
      ),
    );
  }
}
