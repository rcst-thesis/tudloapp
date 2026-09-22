import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:tudloapp/features/lesson/presentation/lesson_catalog_screen.dart';
import 'package:tudloapp/features/map/presentation/screens/map_screen.dart';
import 'package:tudloapp/features/me/presentation/screens/me_screen.dart';
import 'package:tudloapp/features/placeholder/presentation/placeholder_screen.dart';

/// Single source of truth for the six-tab bottom navigation's routing.
///
/// Every screen reachable from the bottom navigation supplies this as its
/// `bottomNavigationBar` with its own tab index. That keeps tab-switch
/// behavior (push away from Home, replace between siblings, clear back to
/// Home) and per-tab color identical everywhere instead of each screen
/// re-deriving its own partial `onItemTapped` switch.
class AppBottomTabNavigation extends StatelessWidget {
  const AppBottomTabNavigation({required this.currentIndex, super.key});

  final int currentIndex;

  static const _defaultNavigationColor = Color(0xFFBD8C57);
  static const _meNavigationColor = Color(0xFFD9BF77);
  static const _meSelectedTileColor = Color(0xFFFFE49A);
  static const _meLabelColor = Color(0xFF664B00);
  static const _mapLabelColor = Color(0xFF000000);
  static const _mapNavigationColor = Color(0xFFD4CA8B);
  static const _mapSelectedTileColor = Color(0xFFD2C15D);
  static const _defaultSelectedTileColor = Color(0xFF966E42);
  static const _dictionaryNavigationColor = Color(0xFFFFB3BA);
  static const _dictionarySelectedTileColor = Color(0xFFED5F74);
  static const _dictionaryLabelColor = Color(0xFF392F5A);
  static const _lessonNavigationColor = Color(0xFF90E0EF);
  static const _lessonSelectedTileColor = Color(0xFF54D3EA);
  static const _lessonLabelColor = Color(0xFF000000);

  static const _lessonTabIndex = 2;
  static const _mapTabIndex = 3;
  static const _dictionaryTabIndex = 4;
  static const _meTabIndex = 5;

  @override
  Widget build(BuildContext context) {
    return HomeBottomNavigation(
      selectedIndex: currentIndex,
      backgroundColor: switch (currentIndex) {
        _meTabIndex => _meNavigationColor,
        _mapTabIndex => _mapNavigationColor,
        _dictionaryTabIndex => _dictionaryNavigationColor,
        _lessonTabIndex => _lessonNavigationColor,
        _ => _defaultNavigationColor,
      },
      selectedTileColor: switch (currentIndex) {
        _meTabIndex => _meSelectedTileColor,
        _mapTabIndex => _mapSelectedTileColor,
        _dictionaryTabIndex => _dictionarySelectedTileColor,
        _lessonTabIndex => _lessonSelectedTileColor,
        _ => _defaultSelectedTileColor,
      },
      labelColor: switch (currentIndex) {
        _meTabIndex => _meLabelColor,
        _mapTabIndex => _mapLabelColor,
        _dictionaryTabIndex => _dictionaryLabelColor,
        _lessonTabIndex => _lessonLabelColor,
        _ => Colors.white,
      },
      onItemTapped: (index) => _navigate(context, index),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final route = FadePageRoute<void>(page: destinationFor(index));
    if (currentIndex == 0) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement<void, void>(route);
    }
  }

  /// The destination screen for [index], each pre-wired with its own
  /// [AppBottomTabNavigation] so the bar keeps working after arrival.
  static Widget destinationFor(int index) {
    switch (index) {
      case 1:
        return const PlaceholderScreen(
          title: 'Translate',
          description: 'Temporary Translate shell',
          icon: Icons.translate_rounded,
          bottomNavigationBar: AppBottomTabNavigation(currentIndex: 1),
        );
      case 2:
        return const LessonCatalogScreen();
      case 3:
        return const MapScreen();
      case 4:
        return const DictionaryScreen();
      case 5:
        return const MeScreen();
      default:
        throw ArgumentError.value(index, 'index', 'Unsupported tab index');
    }
  }
}
