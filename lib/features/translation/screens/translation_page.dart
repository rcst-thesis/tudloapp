import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/translation/services/child_safety_filter.dart';
import 'package:tudloapp/features/translation/services/nmt_translation_service.dart';
import 'package:tudloapp/features/translation/services/translation_history.dart';

class _TranslateStyle {
  static const softBg = TudloColors.paper;
  static const card = Colors.white;
  static const sourceLabel = Color(0xFF6B86A8);
  static const targetLabel = TudloColors.forest;
  static const radius = 26.0;
  static const notFoundMessage = 'Translation not found yet.';

  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: TudloColors.ink.withValues(alpha: .12),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];
}

/// Offline English-to-Hiligaynon model translation.
class TranslationPage extends StatefulWidget {
  final Future<String> Function(String)? translateEnglish;

  const TranslationPage({super.key, this.translateEnglish});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController topController = TextEditingController();
  final TextEditingController bottomController = TextEditingController();

  bool _englishInput = true;
  bool _isUpdating = false;
  bool showHelpOverlay = !AppData.translateHelpDone;
  bool _isTranslating = false;
  bool _nmtRunning = false;
  bool _disposed = false;
  bool _safetyReady = false;
  bool _inputBlocked = false;
  bool _commitPending = false;
  int _requestId = 0;
  Timer? _translationDebounce;
  String? _translationError;
  ({String text, int requestId})? _pendingRequest;
  NmtTranslationService? _nmtService;
  late final Future<String> Function(String) _translateEnglish;

  bool get _filterReady => !AppData.profanityFilterEnabled || _safetyReady;

  @override
  void initState() {
    super.initState();
    _nmtService = widget.translateEnglish == null
        ? NmtTranslationService()
        : null;
    _translateEnglish = widget.translateEnglish ?? _nmtService!.translate;
    topController.addListener(_onInputChanged);
    _safetyReady = ChildSafetyFilter.isReady;
    if (!_safetyReady) {
      ChildSafetyFilter.initialize().then(
        (_) {
          if (mounted) setState(() => _safetyReady = true);
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _translationError =
                  'Child-safe translation is unavailable. Try again.';
            });
          }
        },
      );
    }
    unawaited(TranslationHistory.instance.load());
  }

  void _onInputChanged() {
    if (_isUpdating || !_filterReady) return;

    final input = topController.text;
    final requestId = ++_requestId;
    _translationDebounce?.cancel();
    _pendingRequest = null;
    _commitPending = false;
    final inputBlocked =
        AppData.profanityFilterEnabled && ChildSafetyFilter.isUnsafe(input);
    final dictionaryTranslation =
        _englishInput || inputBlocked || !AppData.dictionaryFallbackEnabled
        ? ''
        : DictionaryData.translateFallback(input, fromEnglish: false);
    if (inputBlocked) {
      bottomController.text = ChildSafetyFilter.blockedMessage;
    } else if (!_englishInput && !AppData.dictionaryFallbackEnabled) {
      bottomController.clear();
    } else {
      bottomController.text =
          dictionaryTranslation.isEmpty && input.trim().isNotEmpty
          ? _TranslateStyle.notFoundMessage
          : _filteredOutput(dictionaryTranslation);
    }

    setState(() {
      _inputBlocked = inputBlocked;
      _isTranslating = false;
      _translationError =
          !_englishInput &&
              input.trim().isNotEmpty &&
              !AppData.dictionaryFallbackEnabled
          ? 'Dictionary fallback is disabled in Settings.'
          : null;
      if (input.trim().isNotEmpty && !AppData.translateHelpDone) {
        showHelpOverlay = false;
        AppData.translateHelpDone = true;
      }
    });

    if (_englishInput && !inputBlocked && input.trim().isNotEmpty) {
      _translationDebounce = Timer(const Duration(milliseconds: 450), () {
        if (!_isCurrent(input, requestId)) return;
        _pendingRequest = (text: input, requestId: requestId);
        unawaited(_drainNmtRequests());
      });
    }
  }

  Future<void> _drainNmtRequests() async {
    if (_nmtRunning) return;
    _nmtRunning = true;
    try {
      while (_pendingRequest != null) {
        final request = _pendingRequest!;
        _pendingRequest = null;
        if (!_isCurrent(request.text, request.requestId)) continue;
        setState(() => _isTranslating = true);
        try {
          final translation = (await _translateEnglish(request.text)).trim();
          if (!_isCurrent(request.text, request.requestId)) continue;
          if (translation.isEmpty) {
            throw StateError('The model returned an empty translation.');
          }
          setState(() {
            bottomController.text = _filteredOutput(translation);
            _translationError = null;
          });
        } catch (_) {
          if (!_isCurrent(request.text, request.requestId)) continue;
          final fallback = AppData.dictionaryFallbackEnabled
              ? DictionaryData.translateFallback(
                  request.text,
                  fromEnglish: true,
                )
              : '';
          setState(() {
            bottomController.text = _filteredOutput(fallback);
            _translationError = fallback.isEmpty
                ? 'Offline translation unavailable. Try again.'
                : null;
          });
        } finally {
          if (_isCurrent(request.text, request.requestId)) {
            setState(() => _isTranslating = false);
            if (_commitPending) {
              _commitPending = false;
              _commitResult();
            }
          }
        }
      }
    } finally {
      _nmtRunning = false;
    }
  }

  String _filteredOutput(String value) {
    return AppData.profanityFilterEnabled &&
            value.isNotEmpty &&
            ChildSafetyFilter.isUnsafe(value)
        ? ChildSafetyFilter.blockedMessage
        : value;
  }

  bool _isCurrent(String text, int requestId) {
    return !_disposed &&
        mounted &&
        _englishInput &&
        requestId == _requestId &&
        topController.text == text;
  }

  bool get _hasUsableTranslation {
    final target = bottomController.text.trim();
    return target.isNotEmpty &&
        !_inputBlocked &&
        target != _TranslateStyle.notFoundMessage &&
        target != ChildSafetyFilter.blockedMessage;
  }

  /// Return key: move the live pair into the result card and recents.
  void _submit() {
    if (topController.text.trim().isEmpty || _inputBlocked) return;
    final awaitingModel =
        _englishInput &&
        (_isTranslating || (_translationDebounce?.isActive ?? false));
    if (awaitingModel) {
      _translationDebounce?.cancel();
      _commitPending = true;
      _pendingRequest ??= (text: topController.text, requestId: _requestId);
      unawaited(_drainNmtRequests());
      return;
    }
    _commitResult();
  }

  void _commitResult() {
    if (!_hasUsableTranslation) return;
    final entry = TranslationEntry(
      source: topController.text.trim(),
      target: bottomController.text.trim(),
      fromEnglish: _englishInput,
    );
    TranslationHistory.instance.addRecent(entry);
    _requestId++;
    setState(() {
      _isUpdating = true;
      topController.clear();
      bottomController.clear();
      _isUpdating = false;
      _isTranslating = false;
      _translationError = null;
    });
  }

  void _swapLanguages() {
    if (!_filterReady || _inputBlocked) return;
    _translationDebounce?.cancel();
    _pendingRequest = null;
    _commitPending = false;
    _requestId++;
    setState(() {
      _englishInput = !_englishInput;
      _isTranslating = false;
      _translationError = null;
      final input = topController.text;
      _isUpdating = true;
      topController.text = bottomController.text;
      bottomController.text = input;
      _isUpdating = false;
    });
  }

  Future<void> _openHistory() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    final picked = await showModalBottomSheet<TranslationEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HistorySheet(),
    );
    if (picked != null) TranslationHistory.instance.addRecent(picked);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _translationDebounce?.cancel();
    _pendingRequest = null;
    topController.removeListener(_onInputChanged);
    final service = _nmtService;
    if (service != null) unawaited(service.close());
    topController.dispose();
    bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceLanguage = _englishInput ? 'English' : 'Hiligaynon';
    final targetLanguage = _englishInput ? 'Hiligaynon' : 'English';

    return Scaffold(
      backgroundColor: _TranslateStyle.softBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _TranslateBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                final horizontalPadding = wide ? 44.0 : 20.0;
                final maxContentWidth = wide ? 720.0 : 560.0;
                final titleSize = wide ? 40.0 : 32.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      wide ? 24 : 14,
                      horizontalPadding,
                      154,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TranslateHeader(
                            titleSize: titleSize,
                            onHistory: _openHistory,
                          ),
                          SizedBox(height: wide ? 28 : 20),
                          _RecentsStack(gap: wide ? 22 : 16),
                          _InputCard(
                            sourceLanguage: sourceLanguage,
                            targetLanguage: targetLanguage,
                            controller: topController,
                            outputController: bottomController,
                            hint: _englishInput
                                ? 'Type English'
                                : 'Type Hiligaynon',
                            outputHint: _englishInput
                                ? 'Hiligaynon translation'
                                : 'English translation',
                            inputEnabled: _filterReady,
                            swapEnabled: _filterReady && !_inputBlocked,
                            busy: !_filterReady || _isTranslating,
                            onSwap: _swapLanguages,
                            onSubmit: _submit,
                            onClear: topController.clear,
                          ),
                          if (_translationError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _translationError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: TudloColors.coral,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (showHelpOverlay)
            Positioned.fill(
              child: _TranslateHelpOverlay(
                onTap: () => setState(() => showHelpOverlay = false),
              ),
            ),
        ],
      ),
    );
  }
}

/// Result cards for this session, newest first. Swipe left to remove, swipe
/// right to save it to favorites (the card stays).
class _RecentsStack extends StatelessWidget {
  final double gap;

  const _RecentsStack({required this.gap});

  @override
  Widget build(BuildContext context) {
    final history = TranslationHistory.instance;
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final recents = history.recents;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in recents)
                Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: _SwipeableResultCard(
                    key: ValueKey(entry),
                    entry: entry,
                    onDelete: () => history.removeRecent(entry),
                    onFavorite: () => history.promoteToFavorite(entry),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SwipeableResultCard extends StatelessWidget {
  final TranslationEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  const _SwipeableResultCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onFavorite,
  });

  Widget _background({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_TranslateStyle.radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('recent-${entry.source}-${entry.fromEnglish}'),
      dismissThresholds: const {
        DismissDirection.startToEnd: .35,
        DismissDirection.endToStart: .35,
      },
      background: _background(
        color: TudloColors.forest,
        icon: Icons.star_rounded,
        label: 'Save',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _background(
        color: TudloColors.coral,
        icon: Icons.delete_rounded,
        label: 'Remove',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        unawaited(AppAudioService.instance.playTap());
        if (direction == DismissDirection.startToEnd) {
          onFavorite();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: _ResultCard(entry: entry, showDictionary: true),
    );
  }
}

class _TranslateHeader extends StatelessWidget {
  final double titleSize;
  final VoidCallback onHistory;

  const _TranslateHeader({required this.titleSize, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          tooltip: 'Favorites and recents',
          icon: Icons.format_list_bulleted_rounded,
          onTap: onHistory,
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Translate',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.archivoBlack(
                color: TudloColors.forest,
                fontSize: titleSize,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 52),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _TranslateStyle.card,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: TudloColors.ink.withValues(alpha: .25),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 52,
            child: Icon(icon, color: TudloColors.forest, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Top card: the last committed pair with playback and quick actions.
class _ResultCard extends StatelessWidget {
  final TranslationEntry entry;
  final bool showDictionary;
  final VoidCallback? onTap;

  const _ResultCard({
    required this.entry,
    this.showDictionary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _TranslateStyle.card,
      borderRadius: BorderRadius.circular(_TranslateStyle.radius),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(_TranslateStyle.radius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_TranslateStyle.radius),
            boxShadow: _TranslateStyle.shadow,
          ),
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhraseRow(
                language: entry.sourceLanguage,
                text: entry.source,
                labelColor: _TranslateStyle.sourceLabel,
                textColor: TudloColors.ink,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: TudloColors.line),
              ),
              _PhraseRow(
                language: entry.targetLanguage,
                text: entry.target,
                labelColor: _TranslateStyle.targetLabel,
                textColor: TudloColors.forest,
              ),
              const SizedBox(height: 14),
              _ResultActions(entry: entry, showDictionary: showDictionary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  final String language;
  final String text;
  final Color labelColor;
  final Color textColor;

  const _PhraseRow({
    required this.language,
    required this.text,
    required this.labelColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language,
                style: GoogleFonts.nunito(
                  color: labelColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                softWrap: true,
                style: GoogleFonts.nunito(
                  color: textColor,
                  fontSize: 28,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  final TranslationEntry entry;
  final bool showDictionary;

  const _ResultActions({required this.entry, required this.showDictionary});

  Future<void> _copy(BuildContext context) async {
    await AppAudioService.instance.playTap();
    await Clipboard.setData(ClipboardData(text: entry.target));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied text'),
          duration: Duration(milliseconds: 900),
        ),
      );
  }

  Future<void> _expand(BuildContext context) async {
    await AppAudioService.instance.playTap();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => _ExpandedResult(entry: entry),
    );
  }

  Future<void> _dictionary(BuildContext context) async {
    await AppAudioService.instance.playTap();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DictionarySheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIcon(
          tooltip: 'Expand',
          icon: Icons.open_in_full_rounded,
          onTap: () => _expand(context),
        ),
        ListenableBuilder(
          listenable: TranslationHistory.instance,
          builder: (context, _) {
            final saved = TranslationHistory.instance.isFavorite(entry);
            return _ActionIcon(
              tooltip: saved ? 'Remove from favorites' : 'Add to favorites',
              icon: saved ? Icons.star_rounded : Icons.star_outline_rounded,
              onTap: () {
                TranslationHistory.instance.toggleFavorite(entry);
                unawaited(AppAudioService.instance.playTap());
              },
            );
          },
        ),
        if (showDictionary)
          _ActionIcon(
            tooltip: 'Dictionary',
            icon: Icons.menu_book_rounded,
            onTap: () => _dictionary(context),
          ),
        _ActionIcon(
          tooltip: 'Copy text',
          icon: Icons.copy_rounded,
          onTap: () => _copy(context),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: 26,
      color: TudloColors.forest,
      icon: Icon(icon),
    );
  }
}

/// Bottom card: source input on top, live translation below, swap in between.
class _InputCard extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final TextEditingController controller;
  final TextEditingController outputController;
  final String hint;
  final String outputHint;
  final bool inputEnabled;
  final bool swapEnabled;
  final bool busy;
  final VoidCallback onSwap;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _InputCard({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.controller,
    required this.outputController,
    required this.hint,
    required this.outputHint,
    required this.inputEnabled,
    required this.swapEnabled,
    required this.busy,
    required this.onSwap,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final sourceText = controller.text.trim();
    final outputText = outputController.text.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodySize = (constraints.maxWidth * .06).clamp(24.0, 32.0);
        final bodyStyle = GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: bodySize,
          height: 1.14,
          fontWeight: FontWeight.w900,
        );
        final hintStyle = bodyStyle.copyWith(
          color: TudloColors.muted.withValues(alpha: .38),
        );

        return Container(
          decoration: BoxDecoration(
            color: _TranslateStyle.card,
            borderRadius: BorderRadius.circular(_TranslateStyle.radius),
            boxShadow: _TranslateStyle.shadow,
          ),
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LanguageLabelRow(
                language: sourceLanguage,
                color: _TranslateStyle.sourceLabel,
                trailing: sourceText.isEmpty
                    ? const SizedBox(height: 48)
                    : IconButton(
                        tooltip: 'Clear text',
                        onPressed: () {
                          onClear();
                          unawaited(AppAudioService.instance.playTap());
                        },
                        color: TudloColors.muted,
                        icon: const Icon(Icons.cancel_rounded),
                      ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: TextField(
                  controller: controller,
                  enabled: inputEnabled,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                  style: bodyStyle,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: hintStyle,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(right: 8, top: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              _SwapDivider(enabled: swapEnabled, busy: busy, onSwap: onSwap),
              _LanguageLabelRow(
                language: targetLanguage,
                color: _TranslateStyle.targetLabel,
                trailing: const SizedBox(height: 48),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: Text(
                    outputText.isEmpty ? outputHint : outputController.text,
                    softWrap: true,
                    style: outputText.isEmpty
                        ? hintStyle.copyWith(
                            color: TudloColors.forest.withValues(alpha: .38),
                          )
                        : bodyStyle.copyWith(color: TudloColors.forest),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageLabelRow extends StatelessWidget {
  final String language;
  final Color color;
  final Widget trailing;

  const _LanguageLabelRow({
    required this.language,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            language,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _SwapDivider extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onSwap;

  const _SwapDivider({
    required this.enabled,
    required this.busy,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          busy
              ? const LinearProgressIndicator(
                  minHeight: 2,
                  color: TudloColors.forest,
                  backgroundColor: TudloColors.line,
                )
              : const Divider(height: 2, thickness: 2, color: TudloColors.line),
          IconButton.filled(
            tooltip: 'Swap languages',
            onPressed: enabled ? onSwap : null,
            icon: const Icon(Icons.swap_vert_rounded),
            style: IconButton.styleFrom(
              backgroundColor: TudloColors.forest,
              foregroundColor: Colors.white,
              disabledBackgroundColor: TudloColors.line,
              minimumSize: const Size.square(52),
              iconSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen, large-type view of a result.
/// Full-screen, large-type view of a result. The rest of the app is portrait
/// only; this view follows the phone's rotation while it is open.
class _ExpandedResult extends StatefulWidget {
  final TranslationEntry entry;

  const _ExpandedResult({required this.entry});

  @override
  State<_ExpandedResult> createState() => _ExpandedResultState();
}

class _ExpandedResultState extends State<_ExpandedResult> {
  static const _portrait = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(_portrait));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Dialog.fullscreen(
      backgroundColor: TudloColors.forest,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: landscape ? 80 : 28,
                  vertical: landscape ? 28 : 80,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.source,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: landscape ? 26 : 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      entry.target,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: landscape ? 64 : 52,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _SheetCloseButton(
                onTap: () => Navigator.of(context).pop(),
                onDark: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool onDark;

  const _SheetCloseButton({required this.onTap, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onDark
          ? Colors.white.withValues(alpha: .18)
          : TudloColors.line.withValues(alpha: .55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            Icons.close_rounded,
            color: onDark ? Colors.white : TudloColors.ink,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .92,
      minChildSize: .5,
      maxChildSize: .96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: TudloColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: TudloColors.muted.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.archivoBlack(
                          color: TudloColors.forest,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    _SheetCloseButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Expanded(
                child: PrimaryScrollController(
                  controller: scrollController,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Saved favorites; tapping a card puts it back on the page, swiping removes it.
class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    final history = TranslationHistory.instance;
    return _SheetFrame(
      title: 'Favorites',
      child: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          final favorites = history.favorites;
          return ListView(
            primary: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                child: Text(
                  'English - Hiligaynon',
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (favorites.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  child: Text(
                    'Swipe a translation right, or tap its star, to save it here.',
                    style: GoogleFonts.nunito(
                      color: TudloColors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              for (final entry in favorites)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Dismissible(
                    key: ValueKey(
                      'favorite-${entry.source}-${entry.fromEnglish}',
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => history.toggleFavorite(entry),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: TudloColors.coral,
                        borderRadius: BorderRadius.circular(
                          _TranslateStyle.radius,
                        ),
                      ),
                      child: const Icon(
                        Icons.star_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    child: _ResultCard(
                      entry: entry,
                      onTap: () => Navigator.of(context).pop(entry),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Dictionary entries that match words in the result pair.
class _DictionarySheet extends StatelessWidget {
  final TranslationEntry entry;

  const _DictionarySheet({required this.entry});

  List<DictionaryEntry> _matches() {
    final words = <String>{
      for (final part in '${entry.source} ${entry.target}'.split(
        RegExp(r'[^\p{L}\p{N}]+', unicode: true),
      ))
        if (part.isNotEmpty) DictionaryData.normalizeForSearch(part),
    }..removeWhere((w) => w.isEmpty);
    return [
      for (final item in DictionaryData.entries)
        if (words.contains(
              DictionaryData.normalizeForSearch(item.hiligaynon),
            ) ||
            item.english
                .split(RegExp(r'[;,/]'))
                .map((m) => DictionaryData.normalizeForSearch(m))
                .any(words.contains))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches();
    return _SheetFrame(
      title: 'Dictionary',
      child: ListView(
        primary: true,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'No dictionary entries for these words yet.',
                style: GoogleFonts.nunito(
                  color: TudloColors.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          for (final item in matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DictionaryCard(item: item),
            ),
        ],
      ),
    );
  }
}

class _DictionaryCard extends StatelessWidget {
  final DictionaryEntry item;

  const _DictionaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.pronunciation case final p? when p.trim().isNotEmpty) p,
      if (item.partOfSpeech case final p? when p.trim().isNotEmpty) p,
    ].join(' · ');
    return Container(
      decoration: BoxDecoration(
        color: _TranslateStyle.card,
        borderRadius: BorderRadius.circular(_TranslateStyle.radius),
        boxShadow: _TranslateStyle.shadow,
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.hiligaynon,
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty)
            Text(
              meta,
              style: GoogleFonts.nunito(
                color: TudloColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            item.english,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (item.exampleSentence case final example?
              when example.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '▸ $example',
              style: GoogleFonts.nunito(
                color: TudloColors.muted,
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranslateHelpOverlay extends StatelessWidget {
  final VoidCallback onTap;

  const _TranslateHelpOverlay({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mascotWidth = (size.width * .55).clamp(190.0, 270.0);
    final bubbleWidth = (size.width * .58).clamp(200.0, 280.0);
    final mascotBottom = (size.height * .14).clamp(104.0, 150.0);
    final mascotLeft = (size.width * .07).clamp(16.0, 34.0);
    final mascotTop = size.height - mascotBottom - mascotWidth;
    final mascotVisibleTop = mascotTop + mascotWidth * .158;
    final bubbleVisibleBottom = bubbleWidth * 1.234;
    final bubbleTop = (mascotVisibleTop - bubbleVisibleBottom - 12).clamp(
      MediaQuery.paddingOf(context).top + 86,
      size.height * .46,
    );
    final bubbleLeft = (mascotLeft + mascotWidth * .5 - bubbleWidth * .5).clamp(
      12.0,
      size.width - bubbleWidth - 12,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: Colors.black.withValues(alpha: .34),
        child: Stack(
          children: [
            Positioned(
              left: mascotLeft,
              bottom: mascotBottom,
              child: TudloMascot(size: mascotWidth),
            ),
            Positioned(
              left: bubbleLeft,
              top: bubbleTop,
              child: _TranslateDialogueBubble(
                width: bubbleWidth,
                message: 'Testingan ta mag type',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslateDialogueBubble extends StatelessWidget {
  final double width;
  final String message;

  const _TranslateDialogueBubble({required this.width, required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleHeight = width * 1920 / 1080;
    return SizedBox(
      width: width,
      height: bubbleHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.dialogueBox,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: width * .20,
            right: width * .20,
            top: width * .59,
            height: width * .46,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * .58),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: 22,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslateBackground extends StatelessWidget {
  const _TranslateBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FFFB), TudloColors.paper, TudloColors.softGreen],
        ),
      ),
      child: CustomPaint(painter: _TranslateBackgroundPainter()),
    );
  }
}

class _TranslateBackgroundPainter extends CustomPainter {
  const _TranslateBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = TudloColors.brightGreen.withValues(alpha: .055);
    canvas.drawCircle(Offset(size.width * .10, size.height * .10), 96, paint);
    canvas.drawCircle(Offset(size.width * .96, size.height * .30), 132, paint);

    paint.color = TudloColors.forest.withValues(alpha: .045);
    canvas.drawCircle(Offset(size.width * .04, size.height * .78), 150, paint);
    canvas.drawCircle(Offset(size.width * .82, size.height * .88), 92, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
