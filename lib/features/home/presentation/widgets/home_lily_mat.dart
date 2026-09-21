import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeLilyMat extends StatelessWidget {
  const HomeLilyMat({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/home_lily_mat.svg',
      key: const Key('home-lily-mat'),
      fit: BoxFit.contain,
    );
  }
}
