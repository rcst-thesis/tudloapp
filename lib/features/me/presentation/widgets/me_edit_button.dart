import 'package:flutter/material.dart';
import 'package:tudloapp/shared/widgets/rive_edit_button.dart';

class MeEditButton extends StatelessWidget {
  const MeEditButton({required this.onPressed, this.enabled = true, super.key});

  static const width = RiveEditButton.width;
  static const height = RiveEditButton.height;

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RiveEditButton(
      key: const Key('me-edit-button'),
      onPressed: onPressed,
      enabled: enabled,
    );
  }
}
