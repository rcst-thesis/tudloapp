import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

/// Tudlo's reusable Rive long-button runtime bridge.
///
/// The Rive component owns the press motion and visible label. Flutter owns
/// the action that follows activation, including navigation and validation.
class RiveLongButton extends StatefulWidget {
  const RiveLongButton({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.enabled = true,
    this.soundEffectAsset,
    this.buttonHeight = RiveLongButton.height,
    this.fillBounds = false,
    super.key,
  });

  static const width = 352.295;
  static const height = 52.0;
  static const _assetPath = 'assets/images/longbtn.riv';
  // Matches RiveLoadNavButton's own disabled-opacity contract
  // (rive_load_nav_button.dart), so every disabled Rive button in the app
  // dims the same amount.
  static const _disabledOpacity = 0.35;

  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final bool enabled;
  final double buttonHeight;
  final bool fillBounds;

  /// Overrides the shared tap cue for a specific action.
  final String? soundEffectAsset;

  @override
  State<RiveLongButton> createState() => _RiveLongButtonState();
}

class _RiveLongButtonState extends State<RiveLongButton> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.ViewModelInstanceString? _labelProperty;
  rive.BooleanInput? _pressInput;

  bool get _usesFlutterSurface =>
      widget.buttonHeight > RiveLongButton.height && !widget.fillBounds;

  @override
  void initState() {
    super.initState();
    if (!_usesFlutterSurface) unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant RiveLongButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) {
      _labelProperty?.value = widget.label;
    }
    if (!_usesFlutterSurface && _controller == null) unawaited(_load());
  }

  Future<void> _load() async {
    final file = await rive.File.asset(
      RiveLongButton._assetPath,
      riveFactory: rive.Factory.flutter,
    );
    if (!mounted || file == null) {
      file?.dispose();
      return;
    }

    final controller = rive.RiveWidgetController(file);
    try {
      final viewModel = controller.dataBind(rive.DataBind.auto());
      final labelProperty = viewModel.string('buttonLabel');
      if (labelProperty == null || viewModel.trigger('activated') == null) {
        throw StateError(
          'longbtn.riv is missing its exported button contract.',
        );
      }
      labelProperty.value = widget.label;
      // The component's public press input is deliberately driven by Flutter.
      // Its exported `activated` trigger remains available to other runtimes,
      // but Flutter keeps the navigation callback deterministic on pointer-up.
      // ignore: deprecated_member_use
      final pressInput = controller.stateMachine.boolean('isPressed');

      if (!mounted) {
        viewModel.dispose();
        controller.dispose();
        file.dispose();
        return;
      }
      setState(() {
        _file = file;
        _controller = controller;
        _viewModel = viewModel;
        _labelProperty = labelProperty;
        _pressInput = pressInput;
      });
    } catch (_) {
      controller.dispose();
      file.dispose();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    // ignore: deprecated_member_use
    _pressInput?.value = true;
  }

  void _handleTapUp(TapUpDetails details) {
    // ignore: deprecated_member_use
    _pressInput?.value = false;
  }

  void _handleTapCancel() {
    // ignore: deprecated_member_use
    _pressInput?.value = false;
  }

  void _handleTap() {
    if (!widget.enabled) return;
    TudloAudioScope.maybeOf(
      context,
    )?.playButtonTapSound(soundEffectAsset: widget.soundEffectAsset);
    widget.onPressed();
  }

  @override
  void dispose() {
    // ignore: deprecated_member_use
    _pressInput?.value = false;
    _controller?.dispose();
    _viewModel?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final semanticsLabel = widget.semanticLabel ?? widget.label;
    return Opacity(
      opacity: widget.enabled ? 1 : RiveLongButton._disabledOpacity,
      child: SizedBox(
        width: RiveLongButton.width,
        height: widget.buttonHeight,
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          label: semanticsLabel,
          onTap: widget.enabled ? _handleTap : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.enabled ? _handleTap : null,
            child: IgnorePointer(
              ignoring: !widget.enabled,
              child: _usesFlutterSurface || controller == null
                  ? _LongButtonFallback(label: widget.label)
                  : rive.RiveWidget(
                      controller: controller,
                      fit: widget.fillBounds ? rive.Fit.fill : rive.Fit.contain,
                      alignment: Alignment.center,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LongButtonFallback extends StatelessWidget {
  const _LongButtonFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Stack(
        children: [
          Positioned.fill(
            top: 4.373,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2C6121),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 4.373,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF4E9F3E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'ComicRelief',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
