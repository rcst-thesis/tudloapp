import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeCouch extends StatelessWidget {
  const HomeCouch({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/home_couch.svg',
      key: const Key('home-couch'),
      fit: BoxFit.contain,
    );
  }
}
