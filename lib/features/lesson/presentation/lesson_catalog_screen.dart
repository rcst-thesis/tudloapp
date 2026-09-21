import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host.dart';
import 'package:tudloapp/features/map/domain/map_location.dart';

/// Tudlo's Lessons destination, rendered by the preserved DevG card page.
///
/// [location] records a real-map entry point. The source-faithful page keeps
/// its card carousel and narration; its compatibility host uses the same
/// Tudlo-owned progress rules as Home and Rive-map launches.
class LessonCatalogScreen extends StatelessWidget {
  const LessonCatalogScreen({
    this.location,
    this.showBottomNavigation = true,
    super.key,
  });

  final MapLocation? location;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('lesson-catalog-screen'),
    body: DevGLessonCatalogHost(location: location),
    bottomNavigationBar: showBottomNavigation
        ? const AppBottomTabNavigation(currentIndex: 2)
        : null,
  );
}
