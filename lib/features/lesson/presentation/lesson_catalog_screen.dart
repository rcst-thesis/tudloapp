import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host.dart';
import 'package:tudloapp/features/map/domain/map_location.dart';

/// Tudlo's Lessons destination, rendered by the preserved DevG card page.
///
/// [location] records a real-map entry point. The source-faithful page keeps
/// its card carousel and narration; its compatibility host uses the same
/// Tudlo-owned progress rules as Home and Rive-map launches.
class LessonCatalogScreen extends StatefulWidget {
  const LessonCatalogScreen({
    this.location,
    this.initialLessonId,
    this.showBottomNavigation = true,
    super.key,
  });

  final MapLocation? location;
  final String? initialLessonId;
  final bool showBottomNavigation;

  @override
  State<LessonCatalogScreen> createState() => _LessonCatalogScreenState();
}

class _LessonCatalogScreenState extends State<LessonCatalogScreen> {
  bool _activityRunning = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('lesson-catalog-screen'),
    body: DevGLessonCatalogHost(
      location: widget.location,
      initialLessonId: widget.initialLessonId,
      onActivityChanged: (running) {
        if (mounted) setState(() => _activityRunning = running);
      },
    ),
    bottomNavigationBar: widget.showBottomNavigation && !_activityRunning
        ? const AppBottomTabNavigation(currentIndex: 2)
        : null,
  );
}
