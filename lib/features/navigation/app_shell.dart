import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/features/dictionary/screens/dictionary_page.dart';
import 'package:tudloapp/features/translation/screens/translation_page.dart';
import 'package:tudloapp/features/home_map/screens/home_map_page.dart';
import 'package:tudloapp/features/profile/screens/profile_page.dart';
import 'package:tudloapp/features/navigation/bottom_nav_bar.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';

/// Main app container after onboarding.
///
/// It keeps the currently selected tab and overlays the floating navigation bar
/// above each feature page. Child screens can open this with `initialIndex` to
/// land on a specific tab.
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _selectedIndex;
  Future<void>? _dictionaryFuture;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (_selectedIndex != 0) _dictionaryFuture = DictionaryData.initialize();
  }

  void switchTo(int index) {
    // Called by the bottom navigation bar.
    setState(() {
      if (index != 0) AppData.mapHelpDone = true;
      if (index != 0) _dictionaryFuture ??= DictionaryData.initialize();
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep page order, icons, and labels aligned by index.
    // Example: index 0 = Map page, Map icon, and "Map" label.
    final pages = [
      // Opens the Home Map where learners choose lesson levels.
      const HomeMapPage(),
      // Opens the translator helper tab.
      const TranslationPage(),
      // Opens the searchable vocabulary dictionary.
      const DictionaryPage(),
      // Opens the user's profile, streak, and progress page.
      const ProfilePage(),
    ];

    final page = _selectedIndex == 0
        ? pages.first
        : FutureBuilder<void>(
            future: _dictionaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Unable to load content.'));
              }
              return pages[_selectedIndex];
            },
          );

    return Scaffold(
      body: Stack(
        children: [
          page,
          if (_selectedIndex == 0 || _selectedIndex == 3)
            const Positioned(
              top: 12,
              left: 16,
              child: SafeArea(child: TudloLanguageToggle()),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 210,
            child: IgnorePointer(
              child: ClipRect(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                    stops: [.42, 1],
                  ).createShader(bounds),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    blendMode: BlendMode.src,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x18FFFFFF),
                            Color(0x48FFFFFF),
                          ],
                          stops: [.42, .72, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating navbar stays above the current page instead of being part
          // of each screen, so tab styling is consistent everywhere.
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: TudloBottomNavBar(
              selectedIndex: _selectedIndex,
              onTap: switchTo,
            ),
          ),
        ],
      ),
    );
  }
}
