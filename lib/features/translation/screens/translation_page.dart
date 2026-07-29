import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/translation/services/child_safety_filter.dart';
import 'package:tudloapp/features/translation/services/nmt_translation_service.dart';

class _TranslateStyle {
  static const softBg = TudloColors.paper;
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
  int _requestId = 0;
  Timer? _translationDebounce;
  String? _translationError;
  ({String text, int requestId})? _pendingRequest;
  NmtTranslationService? _nmtService;
  late final Future<String> Function(String) _translateEnglish;

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
  }

  void _onInputChanged() {
    if (_isUpdating || !_safetyReady) return;

    final input = topController.text;
    final requestId = ++_requestId;
    _translationDebounce?.cancel();
    _pendingRequest = null;
    final inputBlocked = ChildSafetyFilter.isUnsafe(input);
    final dictionaryTranslation = _englishInput || inputBlocked
        ? ''
        : DictionaryData.meaningFor(input);
    bottomController.text = inputBlocked
        ? ChildSafetyFilter.blockedMessage
        : dictionaryTranslation.isEmpty && input.trim().isNotEmpty
        ? 'Translation not found yet.'
        : dictionaryTranslation;

    setState(() {
      _inputBlocked = inputBlocked;
      _isTranslating = false;
      _translationError = null;
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
            bottomController.text = ChildSafetyFilter.isUnsafe(translation)
                ? ChildSafetyFilter.blockedMessage
                : translation;
            _translationError = null;
          });
        } catch (_) {
          if (!_isCurrent(request.text, request.requestId)) continue;
          setState(() {
            bottomController.clear();
            _translationError = 'Offline translation unavailable. Try again.';
          });
        } finally {
          if (_isCurrent(request.text, request.requestId)) {
            setState(() => _isTranslating = false);
          }
        }
      }
    } finally {
      _nmtRunning = false;
    }
  }

  bool _isCurrent(String text, int requestId) {
    return !_disposed &&
        mounted &&
        _englishInput &&
        requestId == _requestId &&
        topController.text == text;
  }

  void _swapLanguages() {
    if (!_safetyReady || _inputBlocked) return;
    _translationDebounce?.cancel();
    _pendingRequest = null;
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
    return Scaffold(
      backgroundColor: _TranslateStyle.softBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _TranslateBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final horizontalPadding = availableWidth >= 700 ? 44.0 : 24.0;
                final contentWidth = (availableWidth - horizontalPadding * 2)
                    .clamp(0.0, availableWidth);
                final maxContentWidth = availableWidth >= 700 ? 720.0 : 520.0;
                final titleSize = availableWidth >= 700 ? 64.0 : 52.0;
                final topPadding = availableWidth >= 700 ? 48.0 : 34.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      154,
                    ),
                    child: SizedBox(
                      width: contentWidth.clamp(0.0, maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FittedBox(
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
                          SizedBox(height: availableWidth >= 700 ? 46 : 38),
                          _TranslationLanguageCard(
                            language: _englishInput ? 'English' : 'Hiligaynon',
                            controller: topController,
                            hint: _englishInput
                                ? 'Type English'
                                : 'Type Hiligaynon',
                            readOnly: false,
                            inputEnabled: _safetyReady,
                            safeActions: !_inputBlocked,
                            onClear: topController.clear,
                          ),
                          SizedBox(height: availableWidth >= 700 ? 18 : 14),
                          Center(
                            child: IconButton.filled(
                              tooltip: 'Swap languages',
                              onPressed: _safetyReady && !_inputBlocked
                                  ? _swapLanguages
                                  : null,
                              icon: const Icon(Icons.swap_vert_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: TudloColors.forest,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: TudloColors.line,
                                minimumSize: const Size.square(56),
                                iconSize: 38,
                              ),
                            ),
                          ),
                          SizedBox(height: availableWidth >= 700 ? 18 : 14),
                          _TranslationLanguageCard(
                            language: _englishInput ? 'Hiligaynon' : 'English',
                            controller: bottomController,
                            hint: _englishInput
                                ? 'Hiligaynon translation'
                                : 'English translation',
                            readOnly: true,
                            inputEnabled: true,
                            safeActions: true,
                            onClear: () {
                              setState(() => bottomController.clear());
                            },
                          ),
                          if (!_safetyReady || _isTranslating)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(),
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

class _TranslationLanguageCard extends StatelessWidget {
  final String language;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final bool inputEnabled;
  final bool safeActions;
  final VoidCallback onClear;

  const _TranslationLanguageCard({
    required this.language,
    required this.controller,
    required this.hint,
    required this.readOnly,
    required this.inputEnabled,
    required this.safeActions,
    required this.onClear,
  });

  Future<void> _copyText(BuildContext context, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await AppAudioService.instance.playTap();
    await Clipboard.setData(ClipboardData(text: value));
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

  Future<void> _clearText() async {
    if (controller.text.trim().isEmpty) return;
    await AppAudioService.instance.playTap();
    onClear();
  }

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 520).clamp(1.0, 1.18);
        final labelSize = 26.0 * scale;
        final bodySize = (constraints.maxWidth * .055).clamp(23.0, 30.0);

        return Container(
          constraints: BoxConstraints(minHeight: 176 * scale),
          padding: EdgeInsets.fromLTRB(
            20 * scale,
            18 * scale,
            16 * scale,
            22 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .13),
                blurRadius: 18 * scale,
                offset: Offset(0, 8 * scale),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _flagFor(language),
                    style: TextStyle(fontSize: 30 * scale),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      language,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF6B86A8),
                        fontSize: labelSize,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Listen',
                    iconSize: 30 * scale,
                    onPressed: text.isEmpty || !safeActions
                        ? null
                        : () => TudloVoiceButton.speak(context, text),
                    icon: Opacity(
                      opacity: text.isEmpty || !safeActions ? .35 : 1,
                      child: TudloSpeakerIcon(size: 24 * scale),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22 * scale),
              readOnly
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        20 * scale,
                        0,
                        12 * scale,
                        8 * scale,
                      ),
                      child: Text(
                        text.isEmpty ? hint : controller.text,
                        softWrap: true,
                        style: GoogleFonts.nunito(
                          color: text.isEmpty
                              ? TudloColors.muted.withValues(alpha: .60)
                              : Colors.black,
                          fontSize: bodySize,
                          height: 1.14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      enabled: inputEnabled,
                      maxLines: null,
                      minLines: 1,
                      style: GoogleFonts.nunito(
                        color: Colors.black,
                        fontSize: bodySize,
                        height: 1.14,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: GoogleFonts.nunito(
                          color: TudloColors.muted.withValues(alpha: .58),
                          fontWeight: FontWeight.w900,
                        ),
                        contentPadding: EdgeInsets.fromLTRB(
                          20 * scale,
                          0,
                          12 * scale,
                          8 * scale,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
              SizedBox(height: 10 * scale),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TranslationActionButton(
                      tooltip: 'Copy text',
                      icon: Icons.copy_rounded,
                      color: TudloColors.forest,
                      enabled: text.isNotEmpty && safeActions,
                      scale: scale,
                      onTap: () => _copyText(context, controller.text),
                    ),
                    SizedBox(width: 8 * scale),
                    _TranslationActionButton(
                      tooltip: 'Clear text',
                      icon: Icons.delete_rounded,
                      color: TudloColors.coral,
                      enabled: text.isNotEmpty,
                      scale: scale,
                      onTap: _clearText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _flagFor(String language) {
    return language == 'English' ? '🇺🇸' : '🇵🇭';
  }
}

class _TranslationActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final bool enabled;
  final double scale;
  final VoidCallback onTap;

  const _TranslationActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = 38 * scale;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? color.withValues(alpha: .11)
            : TudloColors.line.withValues(alpha: .70),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              color: enabled ? color : TudloColors.muted.withValues(alpha: .45),
              size: 21 * scale,
            ),
          ),
        ),
      ),
    );
  }
}
