import 'package:flutter/material.dart';

class HomeStandingLamp extends StatelessWidget {
  const HomeStandingLamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/home_standing_lamp.png',
      key: const Key('home-standing-lamp'),
      fit: BoxFit.contain,
    );
  }
}
