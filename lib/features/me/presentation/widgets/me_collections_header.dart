import 'package:flutter/material.dart';

/// "Koka's collections" heading above the (not yet built) badges grid.
class MeCollectionsHeader extends StatelessWidget {
  const MeCollectionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Koka's collections",
      key: Key('me-collections-header'),
      style: TextStyle(
        fontFamily: 'ComicRelief',
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: Color(0xFF2A2A2A),
      ),
    );
  }
}
