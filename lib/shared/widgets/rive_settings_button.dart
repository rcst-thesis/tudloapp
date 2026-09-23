import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart' as rive;

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

/// Reusable runtime bridge for Tudlo's animated Rive Settings button.
///
/// Rive owns the raised/down motion and the rotating gear. Flutter owns the
/// action after activation, such as opening the Settings screen.
class RiveSettingsButton extends StatefulWidget {
  const RiveSettingsButton({
    required this.onPressed,
    this.assetPath = _defaultAssetPath,
    this.enabled = true,
    super.key,
  });

  static const width = 47.0;
  static const height = 49.0;
  static const _defaultAssetPath = 'assets/images/settings_button.riv';

  final VoidCallback onPressed;
  final String assetPath;
  final bool enabled;

  @override
  State<RiveSettingsButton> createState() => _RiveSettingsButtonState();
}

class _RiveSettingsButtonState extends State<RiveSettingsButton> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.BooleanInput? _pressInput;

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
      if (viewModel.trigger('activated') == null) {
        throw StateError('settings_button.riv is missing activated.');
      }
      // Flutter drives this public input to keep press/release and navigation
      // deterministic, including a cancelled touch.
      // ignore: deprecated_member_use
      final pressInput = controller.stateMachine.boolean('isPressed');
      if (pressInput == null) {
        throw StateError('settings_button.riv is missing isPressed.');
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
        _pressInput = pressInput;
      });
    } catch (_) {
      controller.dispose();
      file.dispose();
    }
  }

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    // ignore: deprecated_member_use
    _pressInput?.value = value;
  }

  void _handleTap() {
    if (!widget.enabled) return;
    TudloAudioScope.maybeOf(context)?.playButtonTapSound();
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
    return SizedBox(
      width: RiveSettingsButton.width,
      height: RiveSettingsButton.height,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: 'Settings',
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
                ? const _SettingsButtonFallback()
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

class _SettingsButtonFallback extends StatelessWidget {
  const _SettingsButtonFallback();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/home_settings_button.svg',
      fit: BoxFit.contain,
      semanticsLabel: 'Settings',
    );
  }
}
