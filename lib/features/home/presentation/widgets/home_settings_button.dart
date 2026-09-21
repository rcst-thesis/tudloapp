import 'package:flutter/material.dart';
import 'package:tudloapp/shared/widgets/rive_settings_button.dart';

class HomeSettingsButton extends StatelessWidget {
  const HomeSettingsButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RiveSettingsButton(
      key: const Key('home-settings-button'),
      assetPath: 'assets/images/settings_button_home.riv',
      onPressed: onTap,
    );
  }
}
