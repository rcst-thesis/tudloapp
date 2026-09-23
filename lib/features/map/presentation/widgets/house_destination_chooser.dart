import 'package:flutter/material.dart';

/// Shows the two intentional House destinations without making the map screen
/// own the dialog's presentation details. Callbacks keep Flutter navigation
/// ownership in [MapScreen] while retaining stable test keys.
Future<void> showHouseDestinationChooser(
  BuildContext context, {
  required VoidCallback onGoHome,
  required VoidCallback onOpenLessons,
}) {
  return showDialog<void>(
    context: context,
    barrierLabel: 'Choose House destination',
    builder: (dialogContext) => AlertDialog(
      key: const Key('map-house-destination-dialog'),
      backgroundColor: const Color(0xFFFFF8E7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Ano ang gusto mo himuon?',
        textAlign: TextAlign.center,
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HouseDestinationButton(
            key: const Key('map-house-go-home'),
            icon: Icons.home_rounded,
            label: 'Balay',
            color: const Color(0xFF63A851),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onGoHome();
            },
          ),
          _HouseDestinationButton(
            key: const Key('map-house-open-lessons'),
            icon: Icons.menu_book_rounded,
            label: 'Leksiyon',
            color: const Color(0xFF5A9AD6),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOpenLessons();
            },
          ),
        ],
      ),
    ),
  );
}

class _HouseDestinationButton extends StatelessWidget {
  const _HouseDestinationButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
