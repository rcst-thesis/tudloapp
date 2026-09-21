import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';

/// Reusable runtime bridge for the Load screen's Rive previous/next
/// pagination buttons.
///
/// Both exported assets bind `isPressed` (boolean) on their own View Model;
/// Flutter drives that for the press visual and owns [onPressed] via its
/// own recognized tap, same as the other Rive button bridges. When
/// [enabled] is false the button dims to 35% opacity and stops accepting
/// input, matching [DesignNavigationButton]'s existing disabled contract.
class RiveLoadNavButton extends StatefulWidget {
  const RiveLoadNavButton({
    required this.assetPath,
    required this.fallbackLabel,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  static const width = 93.0;
  static const height = 44.0;
  static const _disabledOpacity = 0.35;

  final String assetPath;
  final String fallbackLabel;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<RiveLoadNavButton> createState() => _RiveLoadNavButtonState();
}

class _RiveLoadNavButtonState extends State<RiveLoadNavButton> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.ViewModelInstanceBoolean? _pressedProperty;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final file = await rive.File.asset(
      widget.assetPath,
      riveFactory: rive.Factory.flutter,
    );
    if (!mounted || file == null) {
      file?.dispose();
      return;
    }

    final controller = rive.RiveWidgetController(file);
    try {
      final viewModel = controller.dataBind(rive.DataBind.auto());
      final pressedProperty = viewModel.boolean('isPressed');
      if (pressedProperty == null) {
        throw StateError('${widget.assetPath} is missing isPressed.');
      }

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
        _pressedProperty = pressedProperty;
      });
    } catch (_) {
      controller.dispose();
      file.dispose();
    }
  }

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    _pressedProperty?.value = value;
  }

  void _handleTap() {
    if (!widget.enabled) return;
    TudloAudioScope.maybeOf(context)?.playButtonTapSound();
    widget.onPressed();
  }

  @override
  void dispose() {
    _pressedProperty?.value = false;
    _controller?.dispose();
    _viewModel?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Opacity(
      opacity: widget.enabled ? 1 : RiveLoadNavButton._disabledOpacity,
      child: SizedBox(
        width: RiveLoadNavButton.width,
        height: RiveLoadNavButton.height,
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.fallbackLabel,
          onTap: widget.enabled ? _handleTap : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.enabled ? widget.onPressed : null,
            child: IgnorePointer(
              ignoring: !widget.enabled,
              child: controller == null
                  ? DesignNavigationButton(label: widget.fallbackLabel)
                  : rive.RiveWidget(
                      controller: controller,
                      fit: rive.Fit.contain,
                      alignment: Alignment.center,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
