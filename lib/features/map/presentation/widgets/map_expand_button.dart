import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Circular "fit to view" control shown bottom-right of the map, 1:1 copy
/// of the exported expand-arrows button. Tapping it resets the pannable
/// map back to its default framing.
class MapExpandButton extends StatelessWidget {
  const MapExpandButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  static const size = 41.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset('assets/images/map_expand_button.svg'),
        ),
      ),
    );
  }
}
