import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "my dictionary" title art (`assets/images/dictionary_title.svg`),
/// preserving its own 272x55 design ratio.
class DictionaryHeader extends StatelessWidget {
  const DictionaryHeader({this.width = 272, super.key});

  final double width;

  static const _designWidth = 272.0;
  static const _designHeight = 55.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'my dictionary',
      child: ExcludeSemantics(
        child: SizedBox(
          key: const Key('dictionary-header'),
          width: width,
          height: width * (_designHeight / _designWidth),
          child: SvgPicture.asset(
            'assets/images/dictionary_title.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
