import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tudloapp/core/navigation/app_bottom_tab_navigation.dart';
import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudloapp/features/dictionary/domain/dictionary_words.dart';
import 'package:tudloapp/features/dictionary/domain/word_of_the_day.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_panel.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_lesson_preview_dialog.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_scene.dart';
import 'package:tudloapp/features/learner/domain/learner_scope.dart';
import 'package:tudloapp/features/lesson/domain/lesson_definition.dart';
import 'package:tudloapp/features/lesson/domain/lesson_progress_controller.dart';
import 'package:tudloapp/features/lesson/presentation/lesson_intro_screen.dart';
import 'package:tudloapp/features/placeholder/presentation/placeholder_screen.dart';
import 'package:tudloapp/features/settings/presentation/settings_screen.dart';
import 'package:tudloapp/shared/audio/audio_assets.dart';
import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

/// Home owns learner-aware data and navigation; [HomeScene] owns the measured,
/// responsive visual composition. This keeps state changes cheap and lets the
/// illustration tree stay independently testable.
class HomeScreen extends StatefulWidget {
  const HomeScreen({this.learnerName, this.energy, super.key});

  /// Explicit overrides are kept for tests. App use falls back to the current
  /// learner, then the original empty-name/60-energy presentation defaults.
  final String? learnerName;
  final int? energy;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  bool _lessonsCollapsed = false;
  DictionaryEntry? _wordOfTheDay;
  var _resolvedWordOfTheDay = false;

  String get _learnerName =>
      widget.learnerName ?? LearnerScope.of(context).profile?.name ?? '';
  int get _energy =>
      widget.energy ?? LearnerScope.of(context).profile?.energy ?? 60;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = TudloAudioScope.maybeOf(context);
    if (audio != null) {
      audio.preloadSoundEffect(TudloAudioAssets.homeLampSwitchSoundEffect);
      audio.preloadSoundEffect(TudloAudioAssets.homeDoorSoundEffect);
    }
    if (_resolvedWordOfTheDay) return;
    _resolvedWordOfTheDay = true;
    unawaited(TudloAudioScope.of(context).startBackgroundMusic());

    final controller = LearnerScope.of(context);
    final profile = controller.profile;
    final pool = DictionaryWords.all
        .where((entry) => entry.frontCardImage != null)
        .toList();
    final selection = resolveWordOfTheDay(
      pool: pool.isNotEmpty ? pool : DictionaryWords.all,
      storedId: profile?.wordOfTheDayId,
      storedDate: profile?.wordOfTheDayDate,
      history: profile?.wordOfTheDayHistory ?? const {},
    );
    _wordOfTheDay = selection.entry;
    if (selection.isNew) {
      // Learner persistence notifies listeners, so defer it until after this
      // inherited-widget resolution pass to avoid a reentrant build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          controller.recordWordOfTheDay(
            id: selection.entry.id,
            date: DateTime.now(),
            history: selection.history,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSettings() => Navigator.of(context).push(
    FadePageRoute<void>(page: const SettingsScreen(insideLearnerProfile: true)),
  );

  void _openMap() => Navigator.of(
    context,
  ).push(FadePageRoute<void>(page: AppBottomTabNavigation.destinationFor(3)));

  void _openLessons() => Navigator.of(
    context,
  ).push(FadePageRoute<void>(page: AppBottomTabNavigation.destinationFor(2)));

  void _openLessonIntro(String lessonId) => Navigator.of(
    context,
  ).push(FadePageRoute<void>(page: LessonIntroScreen(lessonId: lessonId)));

  void _openStickerScreen() => Navigator.of(context).push(
    FadePageRoute<void>(
      page: const PlaceholderScreen(
        title: 'Stickers',
        description: 'Temporary sticker screen shell',
        icon: Icons.style_rounded,
      ),
    ),
  );

  void _openAbout() => Navigator.of(context).push(
    FadePageRoute<void>(
      page: const PlaceholderScreen(
        title: 'About',
        description: 'Temporary About screen shell',
        icon: Icons.info_outline_rounded,
      ),
    ),
  );

  List<HomeLessonPreview> _homeLessonPreviews() {
    final grade = LearnerScope.of(context).profile?.grade ?? 1;
    final progress = LessonProgressScope.of(context);
    final definitions = LessonCatalog.forGrade(grade)
      ..sort((left, right) {
        final leftActive = left.id == progress.activeLesson?.id;
        final rightActive = right.id == progress.activeLesson?.id;
        if (leftActive != rightActive) return leftActive ? -1 : 1;
        return 0;
      });
    return definitions
        .map(
          (definition) => HomeLessonPreview(
            lessonId: definition.id,
            unitTitle: definition.unitLabel.toLowerCase(),
            category: definition.title.toUpperCase(),
            status: progress.isComplete(definition)
                ? HomeLessonStatus.completed
                : progress.isUnlocked(definition)
                ? HomeLessonStatus.available
                : HomeLessonStatus.locked,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _showLessonPreview(
    HomeLessonPreview lesson,
    Rect originRect,
  ) async {
    await showHomeLessonPreviewDialog(
      context: context,
      lesson: lesson,
      originRect: originRect,
      onRetry: () {
        Navigator.of(context).pop();
        final id = lesson.lessonId;
        id == null ? _openLessons() : _openLessonIntro(id);
      },
      onStart: () {
        Navigator.of(context).pop();
        final id = lesson.lessonId;
        if (id != null && lesson.status != HomeLessonStatus.locked) {
          _openLessonIntro(id);
        } else {
          _openLessons();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordId = _wordOfTheDay?.id;
    final profile = LearnerScope.of(context).profile;
    return Scaffold(
      key: const Key('home-screen'),
      backgroundColor: const Color(0xFFEADF99),
      bottomNavigationBar: const AppBottomTabNavigation(currentIndex: 0),
      body: HomeScene(
        scrollController: _scrollController,
        learnerName: _learnerName,
        energy: _energy,
        wordOfTheDay: _wordOfTheDay,
        isWordOfTheDayFavorited:
            wordId != null &&
            (profile?.favoritedWords.contains(wordId) ?? false),
        lessonPreviews: _homeLessonPreviews(),
        lessonsCollapsed: _lessonsCollapsed,
        onOpenSettings: _openSettings,
        onOpenMap: _openMap,
        onOpenLessons: _openLessons,
        onOpenStickers: _openStickerScreen,
        onOpenAbout: _openAbout,
        onWordFavoriteChanged: (_) {
          if (wordId != null) {
            LearnerScope.of(context).toggleFavoriteWord(wordId);
          }
        },
        onLessonTap: _showLessonPreview,
        onLessonsCollapsedChanged: (isCollapsed) {
          setState(() => _lessonsCollapsed = isCollapsed);
        },
      ),
    );
  }
}
