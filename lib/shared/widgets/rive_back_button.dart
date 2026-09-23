import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';
import 'package:tudloapp/shared/widgets/design_navigation_button.dart';

/// Reusable runtime bridge for Tudlo's animated Rive back button.
///
/// Rive owns the pressed/released visual via the `pressed` boolean on its
/// `Button` View Model. There is no `activated` trigger in this asset, so
/// Flutter's recognized tap fully owns invoking [onPressed], same as the
/// other Rive button bridges.
class RiveBackButton extends StatefulWidget {
  const RiveBackButton({
    required this.onPressed,
    this.assetPath = _defaultAssetPath,
    this.enabled = true,
    super.key,
  });

  static const width = 93.0;
  static const height = 44.0;
  static const _defaultAssetPath = 'assets/images/green_back_button.riv';

  final VoidCallback onPressed;
  final String assetPath;
  final bool enabled;

  @override
  State<RiveBackButton> createState() => _RiveBackButtonState();
}

class _RiveBackButtonState extends State<RiveBackButton> {
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
      final pressedProperty = viewModel.boolean('pressed');
      if (pressedProperty == null) {
        throw StateError('${widget.assetPath} is missing pressed.');
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
    return SizedBox(
      width: RiveBackButton.width,
      height: RiveBackButton.height,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: 'Back',
        onTap: widget.enabled ? _handleTap : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.enabled ? _handleTap : null,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: controller == null
                ? const _BackButtonFallback()
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

class _BackButtonFallback extends StatelessWidget {
  const _BackButtonFallback();

  @override
  Widget build(BuildContext context) {
    return const DesignNavigationButton(icon: Icons.arrow_back_rounded);
  }
}
