import 'package:flutter/material.dart';
import 'package:tudloapp/shared/widgets/rive_settings_button.dart';

class MeSettingsButton extends StatelessWidget {
  const MeSettingsButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RiveSettingsButton(
      key: const Key('me-settings-button'),
      assetPath: 'assets/images/settings_button_me.riv',
      onPressed: onTap,
    );
  }
}
