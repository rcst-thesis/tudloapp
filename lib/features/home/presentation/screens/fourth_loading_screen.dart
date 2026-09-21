import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/features/home/presentation/screens/home_loading_screen.dart';
import 'package:tudloapp/features/home/presentation/screens/home_screen.dart';

class FourthLoadingScreen extends StatelessWidget {
  const FourthLoadingScreen({
    this.minimumDisplayDuration = const Duration(seconds: 5),
    this.preparationTimeout = const Duration(seconds: 30),
    this.prepareHome,
    this.precacheHomeAssets,
    this.homeBuilder,
    super.key,
  });

  static const _homeVectorAssets = <String>[
    'assets/images/home_window_back.svg',
    'assets/images/home_window_clouds.svg',
    'assets/images/home_window_hills.svg',
    'assets/images/home_window_frame.svg',
    'assets/images/home_door.svg',
    'assets/images/home_lamp.svg',
    'assets/images/home_energy_indicator.svg',
    'assets/images/home_lesson_more_dots.svg',
    'assets/images/home_lesson_divider.svg',
    'assets/images/home_settings_button.svg',
  ];

  static const _homeRasterAssets = <String>[
    'assets/images/home_nav_home.png',
    'assets/images/home_nav_translate.png',
    'assets/images/home_nav_lessons.png',
    'assets/images/home_bookshelf_outline_white.png',
    'assets/images/home_lesson_category.png',
    'assets/images/home_nav_map.png',
    'assets/images/home_nav_dictionary.png',
    'assets/images/home_nav_me.png',
  ];

  final Duration minimumDisplayDuration;
  final Duration preparationTimeout;
  final Future<void> Function()? prepareHome;
  final Future<void> Function(BuildContext context)? precacheHomeAssets;
  final WidgetBuilder? homeBuilder;

  Future<void> _precacheHomeAssets(BuildContext context) async {
    await Future.wait<void>([
      for (final asset in _homeVectorAssets)
        SvgAssetLoader(asset).loadBytes(context).then<void>((_) {}),
      for (final asset in _homeRasterAssets)
        precacheImage(AssetImage(asset), context),
    ]);
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('fourth-loading-screen'),
      child: HomeLoadingScreen(
        // Inert placeholders: this screen routes straight to `HomeScreen()`
        // below (bypassing HomeLoadingScreen's default WelcomeAboardScreen
        // path, the only place that would use these), and HomeScreen falls
        // back to the saved learner from LearnerScope on its own.
        learnerName: '',
        grade: 1,
        energy: 60,
        minimumDisplayDuration: minimumDisplayDuration,
        preparationTimeout: preparationTimeout,
        prepareHome: prepareHome,
        precacheWelcomeVectors: precacheHomeAssets ?? _precacheHomeAssets,
        homeBuilder: homeBuilder ?? (_) => const HomeScreen(),
        artworkAsset: 'assets/images/koka_red_loading.png',
        artworkIsSvg: false,
        artworkWidthFactor: 1,
        artworkSemanticsLabel: 'Koka fourth loading screen',
      ),
    );
  }
}
