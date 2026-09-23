import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/home_drawer.svg',
      key: const Key('home-drawer'),
      fit: BoxFit.contain,
    );
  }
}
