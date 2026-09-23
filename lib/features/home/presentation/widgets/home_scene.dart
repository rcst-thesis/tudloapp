import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/home/presentation/widgets/animated_glow_border.dart';
import 'package:tudloapp/features/home/presentation/widgets/animated_home_window.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_bookshelf.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_content_footer.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_couch.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_dev_panel_content.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_dev_panel_frame.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_dev_panel_label.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_door.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_drawer.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_energy_indicator.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_koka_mascot.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lily_mat.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_scene_layout.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_settings_button.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_standing_lamp.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_sticker_container.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_word_of_the_day.dart';
import 'package:tudloapp/features/home/presentation/widgets/interactive_home_lamp.dart';

/// Responsive, scrollable Home composition.
///
/// It is deliberately stateless: [HomeScreen] owns navigation, persistence,
/// audio setup, and the scroll controller, while this widget only turns that
/// state into the measured 412-wide scene. Keep new scene coordinates in
/// [HomeSceneLayout], not in this widget.
class HomeScene extends StatelessWidget {
  const HomeScene({
    required this.scrollController,
    required this.learnerName,
    required this.energy,
    required this.wordOfTheDay,
    required this.isWordOfTheDayFavorited,
    required this.lessonPreviews,
    required this.earnedRewardAssets,
    required this.lessonsCollapsed,
    required this.onOpenSettings,
    required this.onOpenMap,
    required this.onOpenLessons,
    required this.onOpenStickers,
    required this.onOpenAbout,
    required this.onWordFavoriteChanged,
    required this.onLessonTap,
    required this.onLessonsCollapsedChanged,
    super.key,
  });

  static const _upperNavigationMaxOpacity = .84;
  static const _upperNavigationRevealStartFraction = .45;

  final ScrollController scrollController;
  final String learnerName;
  final int energy;
  final DictionaryEntry? wordOfTheDay;
  final bool isWordOfTheDayFavorited;
  final List<HomeLessonPreview> lessonPreviews;
  final Set<String> earnedRewardAssets;
  final bool lessonsCollapsed;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenLessons;
  final VoidCallback onOpenStickers;
  final VoidCallback onOpenAbout;
  final ValueChanged<bool> onWordFavoriteChanged;
  final HomeLessonTapCallback onLessonTap;
  final ValueChanged<bool> onLessonsCollapsedChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) {
        final canvasWidth = math.min(viewport.maxWidth, 720.0);
        final canvasSideInset = (viewport.maxWidth - canvasWidth) / 2;
        final topControlScale = (canvasWidth / 460).clamp(.82, 1.12);
        final sceneScale = canvasWidth / HomeSceneLayout.designWidth;
        final lessonPanelHeight = HomeLessonPanel.designHeightForEnergy(
          energy,
          isCollapsed: lessonsCollapsed,
          configuredLessonCount: lessonPreviews.isEmpty
              ? 1
              : lessonPreviews.length,
        );
        final contentEndSceneHeight =
            HomeSceneLayout.footerBottomFor(lessonPanelHeight) * sceneScale;
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                key: const Key('home-content-scroll-view'),
                controller: scrollController,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SizedBox(
                      height: math.max(
                        viewport.maxHeight,
                        contentEndSceneHeight,
                      ),
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, scene) => _SceneCanvas(
                          width: scene.maxWidth,
                          lessonPanelHeight: lessonPanelHeight,
                          learnerName: learnerName,
                          wordOfTheDay: wordOfTheDay,
                          isWordOfTheDayFavorited: isWordOfTheDayFavorited,
                          lessonPreviews: lessonPreviews,
                          earnedRewardAssets: earnedRewardAssets,
                          energy: energy,
                          lessonsCollapsed: lessonsCollapsed,
                          onOpenMap: onOpenMap,
                          onOpenLessons: onOpenLessons,
                          onOpenStickers: onOpenStickers,
                          onOpenAbout: onOpenAbout,
                          onWordFavoriteChanged: onWordFavoriteChanged,
                          onLessonTap: onLessonTap,
                          onLessonsCollapsedChanged: onLessonsCollapsedChanged,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _UpperNavigationBar(
              scrollController: scrollController,
              canvasWidth: canvasWidth,
              height: 108 * topControlScale,
            ),
            Positioned(
              top: 51 * topControlScale,
              right: canvasSideInset + (30 * topControlScale),
              width: 47 * topControlScale,
              height: 49 * topControlScale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: HomeSettingsButton(onTap: onOpenSettings),
              ),
            ),
            Positioned(
              top: 47 * topControlScale,
              left: canvasSideInset + (30 * topControlScale),
              width: 78 * topControlScale,
              height: 52 * topControlScale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: HomeEnergyIndicator(energy: energy),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SceneCanvas extends StatelessWidget {
  const _SceneCanvas({
    required this.width,
    required this.lessonPanelHeight,
    required this.learnerName,
    required this.wordOfTheDay,
    required this.isWordOfTheDayFavorited,
    required this.lessonPreviews,
    required this.earnedRewardAssets,
    required this.energy,
    required this.lessonsCollapsed,
    required this.onOpenMap,
    required this.onOpenLessons,
    required this.onOpenStickers,
    required this.onOpenAbout,
    required this.onWordFavoriteChanged,
    required this.onLessonTap,
    required this.onLessonsCollapsedChanged,
  });

  final double width;
  final double lessonPanelHeight;
  final String learnerName;
  final DictionaryEntry? wordOfTheDay;
  final bool isWordOfTheDayFavorited;
  final List<HomeLessonPreview> lessonPreviews;
  final Set<String> earnedRewardAssets;
  final int energy;
  final bool lessonsCollapsed;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenLessons;
  final VoidCallback onOpenStickers;
  final VoidCallback onOpenAbout;
  final ValueChanged<bool> onWordFavoriteChanged;
  final HomeLessonTapCallback onLessonTap;
  final ValueChanged<bool> onLessonsCollapsedChanged;

  @override
  Widget build(BuildContext context) {
    final scale = width / HomeSceneLayout.designWidth;
    final stickerTop = HomeSceneLayout.stickerContainerTopFor(
      lessonPanelHeight,
    );
    final labelTop = HomeSceneLayout.devPanelLabelTopFor(lessonPanelHeight);
    final panelTop = HomeSceneLayout.devPanelFrameTopFor(lessonPanelHeight);
    return Stack(
      children: [
        const Positioned.fill(child: _HomeWallBackground()),
        Positioned(
          top: HomeSceneLayout.creamFloorBorderTop * scale,
          left: 0,
          right: 0,
          bottom: 0,
          child: const ColoredBox(
            key: Key('home-cream-wall'),
            color: Color(0xFFFBF3E4),
          ),
        ),
        Positioned(
          top: HomeSceneLayout.floorTop * scale,
          left: 0,
          right: 0,
          bottom: 0,
          child: const ColoredBox(
            key: Key('home-floor'),
            color: Color(0xFFB88956),
          ),
        ),
        _item(HomeSceneLayout.lilyMat, scale, const HomeLilyMat()),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 424,
          child: InteractiveHomeLamp(),
        ),
        _item(
          HomeSceneLayout.window,
          scale,
          const AnimatedHomeWindow(key: Key('home-animated-window')),
        ),
        _item(
          HomeSceneLayout.bookshelf,
          scale,
          HomeBookshelf(onTap: onOpenLessons),
        ),
        _item(HomeSceneLayout.couch, scale, const HomeCouch()),
        _item(HomeSceneLayout.standingLamp, scale, const HomeStandingLamp()),
        _item(HomeSceneLayout.drawer, scale, const HomeDrawer()),
        _item(
          HomeSceneLayout.kokaMascot,
          scale,
          HomeKokaMascot(
            key: const Key('home-koka-mascot'),
            learnerName: learnerName,
          ),
        ),
        _item(
          HomeSceneLayout.door,
          scale,
          HomeDoor(key: const Key('home-door'), onTap: onOpenMap),
        ),
        _item(
          HomeSceneLayout.wordOfTheDay,
          scale,
          HomeWordOfTheDay(
            word: wordOfTheDay?.word ?? 'balay',
            example: wordOfTheDay?.example ?? 'naga istar ako sa akong balay',
            isFavorited: isWordOfTheDayFavorited,
            onFavoriteChanged: onWordFavoriteChanged,
          ),
        ),
        _item(
          HomeSceneLayout.lessonPanel,
          scale,
          HomeLessonPanel(
            key: const Key('home-lesson-panel'),
            energy: energy,
            lesson: lessonPreviews.isEmpty
                ? const HomeLessonPreview(
                    unitTitle: 'yunit 1',
                    category: 'MGA LEKSIYON',
                    status: HomeLessonStatus.locked,
                  )
                : lessonPreviews.first,
            additionalLessons: lessonPreviews.skip(1).toList(),
            onLessonTap: onLessonTap,
            onCollapsedChanged: onLessonsCollapsedChanged,
          ),
          height: lessonPanelHeight,
        ),
        _item(
          HomeSceneLayout.stickerContainer,
          scale,
          HomeStickerContainer(
            onOpenStickers: onOpenStickers,
            earnedRewardAssets: earnedRewardAssets,
          ),
          top: stickerTop,
        ),
        _item(
          HomeSceneLayout.devPanelLabel,
          scale,
          const HomeDevPanelLabel(),
          top: labelTop,
        ),
        _item(
          HomeSceneLayout.devPanelFrame,
          scale,
          AnimatedGlowBorder(
            strokeWidth: 1.5 * scale,
            borderRadius: 11 * scale,
            duration: const Duration(seconds: 4),
            gradientColors: const [
              Color(0xFFF9C1CB),
              Color(0xFFCBEAFA),
              Color(0xFF98EF6F),
            ],
            child: Semantics(
              button: true,
              label: 'Open about Tudlo',
              child: GestureDetector(
                key: const Key('home-dev-panel-button'),
                behavior: HitTestBehavior.opaque,
                onTap: onOpenAbout,
                child: const Stack(
                  children: [
                    Positioned.fill(child: HomeDevPanelFrame()),
                    Positioned.fill(child: HomeDevPanelContent()),
                  ],
                ),
              ),
            ),
          ),
          top: panelTop,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: HomeSceneLayout.footerHeight * scale,
          child: const HomeContentFooter(),
        ),
      ],
    );
  }

  Positioned _item(
    HomeSceneItemLayout layout,
    double scale,
    Widget child, {
    double? top,
    double? height,
  }) {
    return Positioned(
      left: layout.left * scale,
      top: (top ?? layout.top) * scale,
      width: layout.width * scale,
      height: (height ?? layout.height) * scale,
      child: child,
    );
  }
}

class _UpperNavigationBar extends StatelessWidget {
  const _UpperNavigationBar({
    required this.scrollController,
    required this.canvasWidth,
    required this.height,
  });

  final ScrollController scrollController;
  final double canvasWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final floorScrollOffset =
                HomeSceneLayout.floorTop *
                (canvasWidth / HomeSceneLayout.designWidth);
            final revealStart =
                floorScrollOffset *
                HomeScene._upperNavigationRevealStartFraction;
            final revealRange = floorScrollOffset - revealStart;
            final scrollOffset = scrollController.hasClients
                ? scrollController.offset
                : 0.0;
            final progress = ((scrollOffset - revealStart) / revealRange).clamp(
              0.0,
              1.0,
            );
            return Opacity(
              key: const Key('home-upper-navigation-bar'),
              opacity: progress * HomeScene._upperNavigationMaxOpacity,
              child: const ColoredBox(color: Color(0xFFB88956)),
            );
          },
        ),
      ),
    );
  }
}

class _HomeWallBackground extends StatelessWidget {
  const _HomeWallBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEADF99),
      child: Column(
        children: [
          SizedBox(key: Key('home-content-top'), height: 1),
          Spacer(),
          SizedBox(key: Key('home-content-bottom'), height: 1),
        ],
      ),
    );
  }
}
