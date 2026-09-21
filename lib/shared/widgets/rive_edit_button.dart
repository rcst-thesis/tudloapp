import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

/// Reusable runtime bridge for Tudlo's animated Rive edit button.
///
/// Rive owns the pressed/released visual via the `down` boolean on its
/// `Button` View Model. There is no trigger in this asset, so Flutter's
/// recognized tap fully owns invoking [onPressed], same as the back button.
class RiveEditButton extends StatefulWidget {
  const RiveEditButton({
    required this.onPressed,
    this.assetPath = _defaultAssetPath,
    this.enabled = true,
    super.key,
  });

  static const width = 47.0;
  static const height = 49.0;
  static const _defaultAssetPath = 'assets/images/edit_button_me.riv';

  final VoidCallback onPressed;
  final String assetPath;
  final bool enabled;

  @override
  State<RiveEditButton> createState() => _RiveEditButtonState();
}

class _RiveEditButtonState extends State<RiveEditButton> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.ViewModelInstanceBoolean? _downProperty;

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
      final downProperty = viewModel.boolean('down');
      if (downProperty == null) {
        throw StateError('${widget.assetPath} is missing down.');
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
        _downProperty = downProperty;
      });
    } catch (_) {
      controller.dispose();
      file.dispose();
    }
  }

  void _setDown(bool value) {
    if (!widget.enabled) return;
    _downProperty?.value = value;
  }

  void _handleTap() {
    if (!widget.enabled) return;
    TudloAudioScope.maybeOf(context)?.playButtonTapSound();
    widget.onPressed();
  }

  @override
  void dispose() {
    _downProperty?.value = false;
    _controller?.dispose();
    _viewModel?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SizedBox(
      width: RiveEditButton.width,
      height: RiveEditButton.height,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: 'Edit',
        onTap: widget.enabled ? _handleTap : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setDown(true),
          onTapUp: (_) => _setDown(false),
          onTapCancel: () => _setDown(false),
          onTap: widget.enabled ? _handleTap : null,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: controller == null
                ? const _EditButtonFallback()
                : rive.RiveWidget(
                    controller: controller,
                    fit: rive.Fit.contain,
                    alignment: Alignment.center,
                  ),
          ),
        ),
      ),
    );
  }
}

class _EditButtonFallback extends StatelessWidget {
  const _EditButtonFallback();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/me_edit_button.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
