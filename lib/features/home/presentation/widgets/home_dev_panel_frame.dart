import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The empty visual frame for the developer panel. Its content is added in a
/// later incremental Home step.
class HomeDevPanelFrame extends StatelessWidget {
  const HomeDevPanelFrame({super.key});

  static const double designWidth = 378;
  static const double designHeight = 63;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/home_dev_panel_frame.svg',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
