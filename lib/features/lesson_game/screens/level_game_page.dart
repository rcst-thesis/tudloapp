import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/lesson_score.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/services/lesson_number_voice_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/animated_point_finger.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/lesson_asset_glow.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/lesson_game/widgets/reward_overlay.dart';
import 'package:tudloapp/features/lesson/presentation/devg_lesson_host_scope.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

import 'flows/grade_3/grade_three_bantay_flow.dart';
import 'flows/grade_3/grade_three_market_numbers_flow.dart';
import 'flows/grade_3/grade_three_new_student_flow.dart';

part 'flows/grade_1/grade_one_letter_flow.dart';
part 'flows/grade_1/grade_one_number_flow.dart';
part 'flows/grade_1/grade_one_family_flow.dart';
part 'flows/grade_1/grade_one_greeting_flow.dart';
part 'flows/grade_2/grade_two_new_friend_flow.dart';
part 'flows/grade_2/grade_two_birthday_flow.dart';
part 'flows/grade_2/grade_two_park_greeting_flow.dart';
part 'flows/grade_2/grade_two_park_dialogue_flow.dart';
part 'flows/grade_3/grade_three_shop_flow.dart';
part 'flows/grade_3/grade_three_story_flow.dart';

const int _lessonQuizCount = 5;
const Duration _lessonCompletionHold = Duration(seconds: 2);
const String _lessonStickerAssetRoot = 'assets/images/stickers/rewards/home';
const List<String> _lessonHomeStickerAssets = [
  '$_lessonStickerAssetRoot/farm-home-sticker.svg',
  '$_lessonStickerAssetRoot/park-home-sticker.svg',
  '$_lessonStickerAssetRoot/market-home-sticker.svg',
  '$_lessonStickerAssetRoot/church-home-sticker.svg',
  '$_lessonStickerAssetRoot/school-home-sticker.svg',
  '$_lessonStickerAssetRoot/cat-home-sticker.svg',
  '$_lessonStickerAssetRoot/mother-home-sticker.svg',
  '$_lessonStickerAssetRoot/house-home-sticker.svg',
  '$_lessonStickerAssetRoot/dog-home-sticker.svg',
];

String _lessonStickerAssetForLevel(int level) {
  final existing = AppData.lessonStickers[level];
  if (existing != null && _lessonHomeStickerAssets.contains(existing)) {
    return existing;
  }

  final used = AppData.lessonStickers.values.toSet();
  final available = _lessonHomeStickerAssets
      .where((asset) => !used.contains(asset))
      .toList();
  final source = available.isEmpty ? _lessonHomeStickerAssets : available;
  final asset = source[math.Random(level * 7919).nextInt(source.length)];
  AppData.lessonStickers[level] = asset;
  return asset;
}

String _activeLessonStickerAsset() {
  final level = AppData.activeLessonLevel;
  if (level != null) return _lessonStickerAssetForLevel(level);
  return _lessonHomeStickerAssets.first;
}

Map<String, String> _matchingPairsFromItemOrder(QuizItem item) {
  if (item.leftItems.length != item.rightItems.length) return const {};
  return {
    for (var index = 0; index < item.leftItems.length; index++)
      item.leftItems[index]: item.rightItems[index],
  };
}

List<T> _shuffledChoices<T>(Iterable<T> choices) {
  final original = choices.toList();
  if (original.length < 2) return original;
  final shuffled = [...original]..shuffle(math.Random());
  final sameOrder = List.generate(
    shuffled.length,
    (index) => shuffled[index] == original[index],
  ).every((same) => same);
  if (sameOrder) {
    final first = shuffled.removeAt(0);
    shuffled.add(first);
  }
  return shuffled;
}

Future<bool> _showLessonExitConfirmation(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    barrierColor: TudloColors.ink.withValues(alpha: .62),
    builder: (dialogContext) {
      final view = MediaQuery.sizeOf(dialogContext);
      const popupAspect = 1217 / 920;
      final width = math
          .min(
            view.width * .88,
            math.min(500.0, view.height * .62 * popupAspect),
          )
          .toDouble();
      final height = width / popupAspect;
      final closeButtonSize = (width * .095).clamp(38.0, 56.0);
      const assetBase = 'assets/images/level_game/lesson-game-assets';
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  '$assetBase/Tudlo_Exit_Popup_Original_Exact.svg',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                right: width * .012,
                top: -closeButtonSize * .1,
                child: Semantics(
                  button: true,
                  label: 'Magpabilin',
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext, false),
                    child: SizedBox(
                      width: closeButtonSize,
                      height: closeButtonSize,
                      child: SvgPicture.asset(
                        '$assetBase/Tudlo_Exit_X_Button.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width * .18,
                right: width * .18,
                bottom: height * .07,
                child: Row(
                  children: [
                    Expanded(
                      child: _LessonExitPopupButton.asset(
                        label: 'Halin',
                        asset: '$assetBase/Tudlo_Halin_Button.svg',
                        onTap: () => Navigator.pop(dialogContext, true),
                      ),
                    ),
                    SizedBox(width: width * .04),
                    Expanded(
                      child: _LessonExitPopupButton.asset(
                        label: 'Magpabilin',
                        asset: '$assetBase/Tudlo_Magpabilin_Button.svg',
                        onTap: () => Navigator.pop(dialogContext, false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return shouldExit == true;
}

class _LessonExitPopupButton extends StatelessWidget {
  final String label;
  final String asset;
  final VoidCallback onTap;

  const _LessonExitPopupButton.asset({
    required this.label,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: (width * .13).clamp(54.0, 72.0),
          child: SvgPicture.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

Future<void> _exitLessonFromContext(BuildContext context) async {
  final shouldExit = await _showLessonExitConfirmation(context);
  if (!context.mounted || !shouldExit) return;
  await TudloVoiceButton.stop();
  if (!context.mounted) return;
  Navigator.pop(context);
}

class _LessonKokaMascot extends StatefulWidget {
  final double size;
  final KokaMood mood;

  const _LessonKokaMascot({this.size = 118, this.mood = KokaMood.idle});

  @override
  State<_LessonKokaMascot> createState() => _LessonKokaMascotState();
}

class _LessonKokaMascotState extends State<_LessonKokaMascot> {
  bool _waving = false;
  Timer? _waveTimer;

  void _wave() {
    _waveTimer?.cancel();
    setState(() => _waving = true);
    _waveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _waving = false);
    });
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Koka',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _wave,
        child: TudloMascot(
          size: widget.size,
          mood: _waving ? KokaMood.idle : widget.mood,
        ),
      ),
    );
  }
}

/// Main lesson gameplay screen opened from the Home Map.
///
/// A level receives grade-based content and generated questions from
/// LessonBank.
class LevelGamePage extends StatefulWidget {
  final int level;

  const LevelGamePage({super.key, required this.level});

  @override
  State<LevelGamePage> createState() => _LevelGamePageState();
}

class _LessonOrientationCoordinator {
  static int _gradeThreeShellCount = 0;
  static bool _landscapeLocked = false;

  static Future<void> enterGradeThreeLesson() async {
    _gradeThreeShellCount++;
    if (_landscapeLocked) return;
    _landscapeLocked = true;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static Future<void> exitGradeThreeLesson() async {
    if (_gradeThreeShellCount > 0) {
      _gradeThreeShellCount--;
    }
    if (_gradeThreeShellCount == 0) {
      await restorePortrait();
    }
  }

  static Future<void> restorePortrait() async {
    _landscapeLocked = false;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }
}

class _GradeThreeLandscapeCanvas extends StatelessWidget {
  final Widget child;

  const _GradeThreeLandscapeCanvas({required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(width: 960, height: 540, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelGamePageState extends State<LevelGamePage> {
  late final Future<LevelContent> _contentFuture;
  late final bool _gradeThreeOrientationShell;
  List<LessonQuestion> questions = const [];
  final Map<int, String> selectedAnswers = {};
  final Map<int, bool> checkedAnswers = {};
  final Map<int, bool> correctAnswers = {};
  final Map<int, List<String>> builtWords = {};
  final Map<int, Map<String, String>> matches = {};
  final Map<int, _Grade3QuestionAttempt> grade3QuestionAttempts = {};
  final _LessonAttemptTracker _scoreTracker = _LessonAttemptTracker();
  late final DateTime _levelStartedAt;
  bool _rewardsClaimed = false;
  bool _showDailyStreakAfterCompletion = false;
  bool _completeDialogShown = false;
  bool _alphabetPresentationChrome = false;

  int get score => correctAnswers.values.where((correct) => correct).length;

  int get checkedCount =>
      checkedAnswers.values.where((checked) => checked).length;

  @override
  void initState() {
    super.initState();
    AppData.activeLessonLevel = widget.level;
    AppData.lessonDashboardFocusLevel = widget.level;
    _gradeThreeOrientationShell =
        AppData.selectedGradeLevel == GradeLevel.grade3;
    if (_gradeThreeOrientationShell) {
      unawaited(_LessonOrientationCoordinator.enterGradeThreeLesson());
    } else {
      unawaited(_LessonOrientationCoordinator.restorePortrait());
    }
    _contentFuture = () async {
      final contentFuture = LessonBank.loadLevelContentForLevel(widget.level);
      await DictionaryData.initialize();
      final content = await contentFuture;
      await AppAudioService.instance.preloadLessonAudio(content.audioAssets);
      questions = _quizQuestionsFor(content, _quizQuestionCountFor(content));
      _scoreTracker.expectedActivities = questions.length;
      return content;
    }();
    _levelStartedAt = DateTime.now();
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    if (AppData.activeLessonLevel == widget.level) {
      AppData.activeLessonLevel = null;
    }
    if (_gradeThreeOrientationShell) {
      unawaited(_LessonOrientationCoordinator.exitGradeThreeLesson());
    }
    super.dispose();
  }

  bool _claimRewardsOnce() {
    if (_rewardsClaimed) return _showDailyStreakAfterCompletion;
    _rewardsClaimed = true;

    // Progress is saved only when the learner taps the completion button.
    // This prevents repeated completion interactions from saving twice.
    final wasCompleted = AppData.completedLevels.contains(widget.level);
    final previousNextLevel = AppData.firstUnlockedIncompleteLevel;
    AppData.lessonDashboardFocusLevel = widget.level;
    final scoreStats = _buildLessonScoreStats();
    AppData.saveLevelScore(widget.level, scoreStats);
    // The one handoff from the lesson mechanics to Tudlo progress, and only
    // once the learner has claimed the reward UI.
    unawaited(
      DevGLessonHostScope.maybeOf(context)?.claimCompletion(scoreStats) ??
          Future<void>.value(),
    );
    _showDailyStreakAfterCompletion = wasCompleted
        ? false
        : AppData.recordLessonStreakForToday();
    AppData.unlockedLevel = AppData.firstUnlockedIncompleteLevel;
    final unlockedNewLesson =
        AppData.firstUnlockedIncompleteLevel != previousNextLevel;
    unawaited(
      _playCompletionEffects(
        showStar: !wasCompleted,
        unlockedNewLesson: unlockedNewLesson,
      ),
    );
    AppStateScope.of(context).saveActiveProfileProgress();
    return _showDailyStreakAfterCompletion;
  }

  void _recordQuestionAttempt(int index, bool correct) {
    _scoreTracker.recordAttempt(
      activityId: _activityIdForQuestion(index),
      correct: correct,
    );
  }

  String _activityIdForQuestion(int index) {
    final question = index >= 0 && index < questions.length
        ? questions[index]
        : null;
    final label = question?.directionLabel.trim();
    return label == null || label.isEmpty
        ? 'q${index + 1}'
        : 'q${index + 1}-$label';
  }

  LessonScoreStats _buildLessonScoreStats() {
    final lessonId = AppData.lessonIdForLevel(widget.level);
    return _scoreTracker.toStats(
      lessonId: lessonId,
      expectedActivities: questions.length,
      startedAt: _levelStartedAt,
      completedAt: DateTime.now(),
    );
  }

  Future<void> _playCompletionEffects({
    required bool showStar,
    required bool unlockedNewLesson,
  }) async {
    await AppAudioService.instance.playLessonComplete();
    if (showStar) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      await AppAudioService.instance.playStar();
    }
    if (unlockedNewLesson) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      await AppAudioService.instance.playLessonUnlock();
    }
  }

  void _handleQuestionChecked(
    int index,
    bool correct, {
    bool autoComplete = true,
  }) {
    if (_completeDialogShown) return;
    if (!_scoreTracker.hasActivity(_activityIdForQuestion(index))) {
      _recordQuestionAttempt(index, correct);
    }
    setState(() {
      checkedAnswers[index] = correct;
      correctAnswers[index] = correct;
    });

    final allCorrect =
        questions.isNotEmpty &&
        List.generate(
          questions.length,
          (itemIndex) => correctAnswers[itemIndex] == true,
        ).every((correct) => correct);

    if (autoComplete && allCorrect) {
      _completeDialogShown = true;
      Future<void>.delayed(_lessonCompletionHold, () {
        if (mounted) _showCompleteDialog();
      });
    }
  }

  void _showCustomLessonCompleteDialog() {
    if (_completeDialogShown) return;
    _completeDialogShown = true;
    _showCompleteDialog();
  }

  void _handleGradeThreeQuestionCompleted(
    int index, {
    required bool firstAttemptCorrect,
    required int attemptCount,
    required bool usedAudioSupport,
    required bool usedLookBackSupport,
  }) {
    if (_completeDialogShown) return;
    final wrongAttempts = math.max(0, attemptCount - 1);
    for (var i = 0; i < wrongAttempts; i++) {
      _scoreTracker.recordAttempt(
        activityId: _activityIdForQuestion(index),
        correct: false,
      );
    }
    _scoreTracker.recordAttempt(
      activityId: _activityIdForQuestion(index),
      correct: true,
    );
    setState(() {
      checkedAnswers[index] = true;
      correctAnswers[index] = firstAttemptCorrect;
      grade3QuestionAttempts[index] = _Grade3QuestionAttempt(
        lessonId: 'level-${widget.level}',
        questionId: questions[index].directionLabel.isEmpty
            ? 'q$index'
            : questions[index].directionLabel,
        questionType: _grade3QuestionTypeFor(questions[index]),
        firstAttemptCorrect: firstAttemptCorrect,
        attemptCount: attemptCount,
        usedAudioSupport: usedAudioSupport,
        usedLookBackSupport: usedLookBackSupport,
        completedAt: DateTime.now(),
      );
    });
  }

  void _completeGradeThreeLesson() {
    if (_completeDialogShown) return;
    final allCompleted =
        questions.isEmpty ||
        List.generate(
          questions.length,
          (itemIndex) => checkedAnswers[itemIndex] == true,
        ).every((completed) => completed);
    if (!allCompleted) return;
    _completeDialogShown = true;
    _showCompleteDialog();
  }

  void _setAlphabetPresentationChrome(bool value) {
    if (_alphabetPresentationChrome == value) return;
    setState(() => _alphabetPresentationChrome = value);
  }

  void _showCompleteDialog() {
    // The completion dialog shows lesson results. Progress updates only after
    // the learner returns to the map.
    final scoreStats = _buildLessonScoreStats();
    final accuracy = scoreStats.accuracy;
    final durationLabel = _formatDuration(
      DateTime.now().difference(_levelStartedAt),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: TudloColors.ink.withValues(alpha: .62),
      builder: (_) => _LessonCompleteDialog(
        level: widget.level,
        backgroundAsset: _lessonCompleteBackgroundAsset(widget.level),
        accuracy: accuracy,
        mistakes: scoreStats.mistakes,
        durationLabel: durationLabel,
        onClaimXp: _claimRewardsOnce,
        onBackToMap: () {
          _claimRewardsOnce();
          Navigator.pop(context);
          unawaited(_returnToMapAfterPortraitRestore());
        },
        onContinue: () async {
          _claimRewardsOnce();
          Navigator.pop(context);
          if (widget.level >= AppData.maxLevel) {
            await _returnToMapAfterPortraitRestore();
            return;
          }
          final nextLevel = _nextAvailableLevel();
          if (nextLevel == null) {
            await _returnToMapAfterPortraitRestore();
            return;
          }
          final spent = await AppData.spendLessonEnergy();
          if (!mounted) return;
          if (!spent) {
            await showLowEnergyDialog(context);
            return;
          }
          await AppStateScope.of(context).saveActiveProfileProgress();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LevelGamePage(level: nextLevel)),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showPauseMenu() async {
    // Back icon button:
    // Opens a leave confirmation before discarding the current lesson attempt.
    // Exiting from this menu does not save level progress.
    final shouldExit = await _showLessonExitConfirmation(context);
    if (!mounted || !shouldExit) return;
    await _restorePortraitBeforePortraitRoute();
    if (!mounted) return;
    final host = DevGLessonHostScope.maybeOf(context);
    if (host != null) {
      await host.exitIncomplete();
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> _restorePortraitBeforePortraitRoute() async {
    if (_gradeThreeOrientationShell) {
      await _LessonOrientationCoordinator.restorePortrait();
    }
  }

  Future<void> _returnToMapAfterPortraitRestore() async {
    await _restorePortraitBeforePortraitRoute();
    if (!mounted) return;
    // Under a Tudlo lesson host, the host owns where a finished lesson goes
    // back to. Standalone, this page returns to its own lesson dashboard.
    final host = DevGLessonHostScope.maybeOf(context);
    if (host != null) {
      await host.exitAfterCompletion();
      return;
    }
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 2)),
      (route) => false,
    );
  }

  int? _nextAvailableLevel() {
    for (var level = widget.level + 1; level <= AppData.maxLevel; level++) {
      if (AppData.isProductionLessonAvailable(level) &&
          AppData.isLevelUnlocked(level)) {
        return level;
      }
    }
    return null;
  }

  LessonQuestion _questionFromQuizItem(QuizItem item) {
    final choiceTypes = {
      QuizType.multipleChoice,
      QuizType.pictureChoice,
      QuizType.listenAndChoose,
      QuizType.tapCorrectWord,
    };
    if (item.type == QuizType.matching) {
      final matchingPairs = item.matchingPairs.isNotEmpty
          ? item.matchingPairs
          : _matchingPairsFromItemOrder(item);
      return LessonQuestion.matching(
        prompt: item.question,
        leftItems: item.leftItems,
        rightItems: _shuffledChoices(item.rightItems),
        matchingPairs: matchingPairs,
        directionLabel: item.id,
      );
    }
    if (item.type == QuizType.fillBlankChoice) {
      return LessonQuestion.fillBlank(
        prompt: item.question,
        answer: item.answer,
        choices: _shuffledChoices(item.choices),
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    if (item.type == QuizType.arrangeWords) {
      return LessonQuestion.arrangeWords(
        prompt: item.question,
        answer: item.answer,
        sentenceWords: _shuffledChoices(item.choices),
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    if (choiceTypes.contains(item.type)) {
      return LessonQuestion.translationChoice(
        prompt: item.question,
        answer: item.answer,
        choices: _shuffledChoices(item.choices),
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    return LessonQuestion.choice(
      prompt: item.question,
      answer: item.answer,
      choices: _shuffledChoices(item.choices),
      imagePath: item.imageAsset ?? '',
      targetPhrase: item.answer,
      targetMeaning: item.answer,
      directionLabel: item.id,
    );
  }

  int _quizQuestionCountFor(LevelContent content) {
    return content.gradeLevel == 1 &&
            content.unitNumber == 1 &&
            content.lessonNumber == 9
        ? 10
        : _lessonQuizCount;
  }

  List<LessonQuestion> _quizQuestionsFor(LevelContent content, int count) {
    final parsed = content.quizItems.map(_questionFromQuizItem).toList();
    if (parsed.length >= count) {
      return parsed.take(count).toList();
    }
    final result = [...parsed];
    while (result.length < count) {
      final index = result.length;
      final fallback = parsed.isEmpty
          ? LessonQuestion.choice(
              prompt: 'Pili-a ang husto nga sabat.',
              answer: 'Husto',
              choices: const ['Husto', 'Suliton liwat'],
              targetPhrase: content.title,
              targetMeaning: content.title,
              directionLabel: 'generated-q${index + 1}',
            )
          : parsed[index % parsed.length];
      result.add(
        LessonQuestion.choice(
          prompt: fallback.prompt,
          answer: fallback.answer.isEmpty ? 'Husto' : fallback.answer,
          choices: fallback.choices.isEmpty
              ? const ['Husto', 'Suliton liwat']
              : fallback.choices,
          imagePath: fallback.imagePath,
          sentenceMeaning: fallback.sentenceMeaning,
          wordMeanings: fallback.wordMeanings,
          targetPhrase: fallback.targetPhrase,
          targetMeaning: fallback.targetMeaning,
          directionLabel: fallback.directionLabel.isEmpty
              ? 'generated-q${index + 1}'
              : '${fallback.directionLabel}-copy${index + 1}',
        ),
      );
    }
    return result;
  }

  LessonLevelContent _displayContent(LevelContent levelContent) {
    return LessonLevelContent(
      title: levelContent.title,
      storyTitle: levelContent.storyTitle ?? '',
      story: levelContent.story ?? '',
      shortLesson: levelContent.lesson,
      examples: levelContent.examples,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 10.0 : 18.0;
    final backButtonSize = screenWidth < 380 ? 48.0 : 56.0;
    final backIconSize = screenWidth < 380 ? 32.0 : 40.0;
    final progressHeight = screenWidth < 380 ? 14.0 : 18.0;

    return FutureBuilder<LevelContent>(
      future: _contentFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final levelContent = snapshot.data;
        final alphabetLesson =
            levelContent != null && _isGradeOneAlphabetContent(levelContent);
        final unitOneReviewLesson =
            levelContent != null &&
            _isGradeOneUnitOneReviewContent(levelContent);
        final numberLesson =
            levelContent != null && _isGradeOneNumberContent(levelContent);
        final unitOneLessonSeven =
            levelContent != null &&
            levelContent.gradeLevel == 1 &&
            levelContent.unitNumber == 1 &&
            levelContent.lessonNumber == 7;
        final familyLesson =
            levelContent != null && _isGradeOneFamilyContent(levelContent);
        final helperLesson =
            levelContent != null && _isGradeOneHelperContent(levelContent);
        final animalLesson =
            levelContent != null && _isGradeOneAnimalContent(levelContent);
        final placeLesson =
            levelContent != null && _isGradeOnePlaceContent(levelContent);
        final gradeTwoLesson =
            levelContent != null && _isGradeTwoContent(levelContent);
        final gradeTwoNewFriendLesson =
            levelContent != null &&
            levelContent.gradeLevel == 2 &&
            levelContent.unitNumber == 1 &&
            levelContent.lessonNumber == 1;
        final gradeTwoBirthdayLesson =
            levelContent != null &&
            levelContent.gradeLevel == 2 &&
            levelContent.unitNumber == 1 &&
            levelContent.lessonNumber == 2;
        final gradeTwoParkGreetingLesson =
            levelContent != null &&
            levelContent.gradeLevel == 2 &&
            levelContent.unitNumber == 2 &&
            levelContent.lessonNumber == 1;
        final gradeTwoParkDialogueLesson =
            levelContent != null &&
            levelContent.gradeLevel == 2 &&
            levelContent.unitNumber == 2 &&
            levelContent.lessonNumber == 2;
        final gradeThreeLesson =
            levelContent != null && _isGradeThreeContent(levelContent);
        final gradeThreeMarketNumbersLesson =
            levelContent != null && _isGrade3MarketNumbersLesson(levelContent);
        final gradeThreeShoppingLesson =
            levelContent != null && _isGrade3ShoppingLesson(levelContent);
        final gradeThreeNewStudentLesson =
            levelContent != null &&
            levelContent.gradeLevel == 3 &&
            levelContent.unitNumber == 2 &&
            levelContent.lessonNumber == 2;
        final customLessonFlow =
            alphabetLesson ||
            unitOneReviewLesson ||
            unitOneLessonSeven ||
            numberLesson ||
            familyLesson ||
            helperLesson ||
            animalLesson ||
            placeLesson ||
            gradeTwoLesson ||
            gradeThreeLesson;
        final progress = questions.isEmpty
            ? 0.0
            : checkedCount / questions.length;
        final hideStandardChrome = customLessonFlow;
        return Scaffold(
          backgroundColor: hideStandardChrome
              ? const Color(0xFFAEEAB3)
              : TudloColors.paper,
          body: SafeArea(
            left: !hideStandardChrome,
            top: !hideStandardChrome,
            right: !hideStandardChrome,
            bottom: !hideStandardChrome,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                hideStandardChrome ? 0 : horizontalPadding,
                hideStandardChrome ? 0 : 12,
                hideStandardChrome ? 0 : horizontalPadding,
                hideStandardChrome ? 0 : 18,
              ),
              child: Column(
                children: [
                  if (!hideStandardChrome) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: backButtonSize,
                          height: backButtonSize,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            // Back button:
                            // Opens the pause menu before leaving the game.
                            onPressed: _showPauseMenu,
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: TudloColors.blue,
                              size: backIconSize,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth < 380 ? 6 : 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Leksiyon ${AppData.lessonNumberForLevel(widget.level)}',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: TudloColors.blue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: progressHeight,
                                  backgroundColor: TudloColors.line,
                                  color: TudloColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: screenWidth < 380 ? 6 : 12),
                        SizedBox(width: screenWidth < 380 ? 6 : 12),
                        Flexible(
                          flex: 0,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const EnergyIndicator(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: loading || levelContent == null
                        ? const _LessonLoadingCard()
                        : customLessonFlow
                        ? _wrapGradeThreeCanvas(
                            gradeThreeLesson,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: alphabetLesson
                                      ? _GradeOneAlphabetLesson(
                                          content: levelContent,
                                          onExit: _showPauseMenu,
                                          onPresentationChromeChanged:
                                              _setAlphabetPresentationChrome,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : unitOneReviewLesson
                                      ? _GradeOneUnitOneReviewLesson(
                                          content: levelContent,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : unitOneLessonSeven
                                      ? _GradeOneUnitOneLessonSevenBeachFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : numberLesson
                                      ? _GradeOneNumberLesson(
                                          content: levelContent,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : helperLesson
                                      ? _GradeOneHelperLesson(
                                          content: levelContent,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : animalLesson
                                      ? _GradeOneAnimalLesson(
                                          content: levelContent,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : placeLesson
                                      ? _GradeOnePlaceLesson(
                                          content: levelContent,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : gradeTwoNewFriendLesson
                                      ? _GradeTwoUnitOneLessonOneNewFriendFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : gradeTwoBirthdayLesson
                                      ? _GradeTwoUnitOneLessonTwoBirthdayFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : gradeTwoParkGreetingLesson
                                      ? _GradeTwoUnitTwoLessonOneParkGreetingFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : gradeTwoParkDialogueLesson
                                      ? _GradeTwoUnitTwoLessonTwoParkDialogueFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : gradeTwoLesson
                                      ? _GradeTwoTalkBuildSolveLesson(
                                          content: levelContent,
                                          onExit: _showPauseMenu,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : gradeThreeMarketNumbersLesson
                                      ? GradeThreeMarketNumbersFlow(
                                          onExit: _showPauseMenu,
                                          onLessonComplete:
                                              _showCustomLessonCompleteDialog,
                                          rewardStickerAsset:
                                              _activeLessonStickerAsset(),
                                        )
                                      : gradeThreeShoppingLesson
                                      ? _GradeThreeShoppingFlow(
                                          onExit: _showPauseMenu,
                                          rewardStickerAsset:
                                              _activeLessonStickerAsset(),
                                          onBackToMap: () async {
                                            _claimRewardsOnce();
                                            await _returnToMapAfterPortraitRestore();
                                          },
                                          onContinue:
                                              _showCustomLessonCompleteDialog,
                                        )
                                      : gradeThreeLesson &&
                                            levelContent.unitNumber == 2 &&
                                            levelContent.lessonNumber == 1
                                      ? GradeThreeBantayFlow(
                                          onExit: _showPauseMenu,
                                          rewardStickerAsset:
                                              _activeLessonStickerAsset(),
                                          onLessonComplete: () {
                                            _claimRewardsOnce();
                                          },
                                          onBackToMap: () async {
                                            await _returnToMapAfterPortraitRestore();
                                          },
                                          onContinue: () async {
                                            if (widget.level >=
                                                AppData.maxLevel) {
                                              await _returnToMapAfterPortraitRestore();
                                              return;
                                            }
                                            final nextLevel =
                                                _nextAvailableLevel();
                                            if (nextLevel == null) {
                                              await _returnToMapAfterPortraitRestore();
                                              return;
                                            }
                                            final spent =
                                                await AppData.spendLessonEnergy();
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            if (!spent) {
                                              await showLowEnergyDialog(
                                                context,
                                              );
                                              return;
                                            }
                                            await AppStateScope.of(
                                              context,
                                            ).saveActiveProfileProgress();
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => LevelGamePage(
                                                  level: nextLevel,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : gradeThreeNewStudentLesson
                                      ? GradeThreeNewStudentFlow(
                                          onExit: _showPauseMenu,
                                          rewardStickerAsset:
                                              _activeLessonStickerAsset(),
                                          onLessonComplete: () {
                                            _claimRewardsOnce();
                                          },
                                          onBackToMap: () async {
                                            await _returnToMapAfterPortraitRestore();
                                          },
                                          onContinue: () async {
                                            if (widget.level >=
                                                AppData.maxLevel) {
                                              await _returnToMapAfterPortraitRestore();
                                              return;
                                            }
                                            final nextLevel =
                                                _nextAvailableLevel();
                                            if (nextLevel == null) {
                                              await _returnToMapAfterPortraitRestore();
                                              return;
                                            }
                                            final spent =
                                                await AppData.spendLessonEnergy();
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            if (!spent) {
                                              await showLowEnergyDialog(
                                                context,
                                              );
                                              return;
                                            }
                                            await AppStateScope.of(
                                              context,
                                            ).saveActiveProfileProgress();
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => LevelGamePage(
                                                  level: nextLevel,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : gradeThreeLesson
                                      ? _GradeThreeLessonFlow(
                                          content: levelContent,
                                          questions: questions,
                                          onQuestionCompleted:
                                              _handleGradeThreeQuestionCompleted,
                                          onLessonComplete:
                                              _completeGradeThreeLesson,
                                        )
                                      : familyLesson &&
                                            levelContent.lessonNumber == 4
                                      ? _GradeOneUnitTwoLessonFourPicnicFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                                autoComplete: false,
                                              ),
                                          onLessonComplete:
                                              _showCustomLessonCompleteDialog,
                                        )
                                      : familyLesson &&
                                            levelContent.lessonNumber == 3
                                      ? _GradeOneUnitTwoLessonThreePortraitFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : familyLesson &&
                                            levelContent.lessonNumber == 2
                                      ? _GradeOneUnitTwoLessonTwoVisitorFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : familyLesson &&
                                            levelContent.lessonNumber == 1
                                      ? _GradeOneUnitTwoLessonOneFamilyReferenceFlow(
                                          onExit: _showPauseMenu,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        )
                                      : _GradeOneFamilyLesson(
                                          content: levelContent,
                                          onQuizAttempt: _recordQuestionAttempt,
                                          onQuizCorrect: (index) =>
                                              _handleQuestionChecked(
                                                index,
                                                true,
                                              ),
                                        ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LevelIntroHeader(title: levelContent.title),
                                if (levelContent.story?.trim().isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 18),
                                  _StoryLessonSection(
                                    content: _displayContent(levelContent),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _LearningSection(
                                  title: 'Mga Halimbawa',
                                  accentColor: TudloColors.blue,
                                  child: _ExampleCardGrid(
                                    examples: levelContent.examples,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const _QuizSectionHeader(),
                                const SizedBox(height: 12),
                                ...questions.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _LevelQuizCard(
                                      key: ValueKey(
                                        '${widget.level}-${entry.key}-${entry.value.prompt}',
                                      ),
                                      number: entry.key + 1,
                                      question: entry.value,
                                      onAttempt: (correct) =>
                                          _recordQuestionAttempt(
                                            entry.key,
                                            correct,
                                          ),
                                      onChecked: (correct) =>
                                          _handleQuestionChecked(
                                            entry.key,
                                            correct,
                                          ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _wrapGradeThreeCanvas(bool enabled, Widget child) {
    return enabled ? _GradeThreeLandscapeCanvas(child: child) : child;
  }

  bool _isGradeOneAlphabetContent(LevelContent content) {
    return content.gradeLevel == 1 &&
        content.unitNumber == 1 &&
        content.lessonNumber <= 6 &&
        content.title.toLowerCase().contains('letters');
  }

  bool _isGradeOneNumberContent(LevelContent content) {
    return content.gradeLevel == 1 &&
        content.unitNumber == 1 &&
        content.lessonNumber >= 7 &&
        content.lessonNumber <= 8;
  }

  bool _isGradeOneUnitOneReviewContent(LevelContent content) {
    return content.gradeLevel == 1 &&
        content.unitNumber == 1 &&
        content.lessonNumber == 9;
  }

  bool _isGradeOneFamilyContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 2;
  }

  bool _isGradeOneHelperContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 3;
  }

  bool _isGradeOneAnimalContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 4;
  }

  bool _isGradeOnePlaceContent(LevelContent content) {
    return content.gradeLevel == 1 && content.unitNumber == 5;
  }

  bool _isGradeTwoContent(LevelContent content) {
    return content.gradeLevel == 2;
  }

  bool _isGradeThreeContent(LevelContent content) {
    return content.gradeLevel == 3;
  }
}

class _LessonLoadingCard extends StatelessWidget {
  const _LessonLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TudloCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _LessonKokaMascot(size: 126, mood: KokaMood.idle),
            SizedBox(height: 14),
            Text(
              'Ginakuha ang leksiyon...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TudloColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelQuizCard extends StatefulWidget {
  final int number;
  final LessonQuestion question;
  final ValueChanged<bool> onAttempt;
  final ValueChanged<bool> onChecked;

  const _LevelQuizCard({
    super.key,
    required this.number,
    required this.question,
    required this.onAttempt,
    required this.onChecked,
  });

  @override
  State<_LevelQuizCard> createState() => _LevelQuizCardState();
}

class _LevelQuizCardState extends State<_LevelQuizCard> {
  String? selectedAnswer;
  String? selectedMatchLeft;
  String? wrongMatchLeft;
  String? wrongMatchRight;
  Timer? _wrongMatchClearTimer;
  Timer? _matchedPulseTimer;
  int wrongMatchAttempt = 0;
  String? newMatchLeft;
  String? newMatchRight;
  int matchPulseAttempt = 0;
  int answerFeedbackAttempt = 0;
  bool checked = false;
  bool lastCorrect = false;
  final Map<String, String> matches = {};
  final List<String> builtWords = [];

  @override
  void dispose() {
    _wrongMatchClearTimer?.cancel();
    _matchedPulseTimer?.cancel();
    super.dispose();
  }

  LessonQuestion get question => widget.question;

  bool get canCheck {
    return switch (question.type) {
      QuestionType.matching => matches.length == question.leftItems.length,
      QuestionType.fillBlank =>
        builtWords.length >= question.answer.split(' ').length,
      QuestionType.arrangeWords =>
        builtWords.length >= question.answer.split(' ').length,
      QuestionType.buildSentence =>
        builtWords.length >= question.answer.split(' ').length,
      _ => selectedAnswer != null,
    };
  }

  bool get isCorrect {
    return switch (question.type) {
      QuestionType.matching => _matchingCorrect(question),
      QuestionType.fillBlank =>
        _normalizeAnswer(builtWords.join(' ')) ==
            _normalizeAnswer(question.answer),
      QuestionType.arrangeWords =>
        _normalizeAnswer(builtWords.join(' ')) ==
            _normalizeAnswer(question.answer),
      QuestionType.buildSentence =>
        _normalizeAnswer(builtWords.join(' ')) ==
            _normalizeAnswer(question.answer),
      _ => selectedAnswer == question.answer,
    };
  }

  Future<void> _checkAnswer() async {
    if (checked || !canCheck) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }

    final correct = isCorrect;
    widget.onAttempt(correct);
    setState(() {
      checked = true;
      lastCorrect = correct;
      answerFeedbackAttempt++;
    });
    if (correct) {
      unawaited(AppAudioService.instance.playCorrect());
      widget.onChecked(true);
      return;
    }
    unawaited(AppAudioService.instance.playWrong());
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || lastCorrect) return;
      setState(() {
        checked = false;
      });
    });
  }

  String _titleFor(QuestionType type) {
    return switch (type) {
      QuestionType.translationChoice => 'Pili-a ang Husto nga Sabat',
      QuestionType.arrangeWords => 'Ano ini sa Hiligaynon',
      QuestionType.fillBlank => 'Kompletoha',
      QuestionType.choice => 'Pili-a ang Husto nga Sabat',
      QuestionType.matching => 'Ipares ang Tinaga',
      QuestionType.completeSentence => 'Pili-a ang Husto nga Sabat',
      QuestionType.buildSentence => 'Ano ini sa Hiligaynon',
      QuestionType.imageChoice => 'Pili-a ang Laragway',
    };
  }

  Widget _buildQuestionBody(LessonQuestion q) {
    // Pick the exercise widget from the data model. This keeps the main page
    // layout stable while allowing very different interactions inside the body.
    return switch (q.type) {
      QuestionType.fillBlank => _ScenarioFillBlankExercise(
        question: q,
        builtWords: builtWords,
        checked: checked,
        answer: q.answer,
        feedbackAttempt: answerFeedbackAttempt,
        onAdd: (value) {
          if (checked) return;
          if (builtWords.length >= q.answer.split(' ').length) return;
          setState(() => builtWords.add(value));
        },
        onRemove: (index) => setState(() => builtWords.removeAt(index)),
      ),
      QuestionType.translationChoice ||
      QuestionType.choice ||
      QuestionType.completeSentence => _ChoiceList(
        choices: q.choices,
        selected: selectedAnswer,
        checked: checked,
        answer: q.answer,
        feedbackAttempt: answerFeedbackAttempt,
        choiceMeanings: {
          for (final choice in q.choices) choice: translatedMeaningFor(choice),
        },
        onSelected: (value) {
          if (checked && lastCorrect) return;
          TudloVoiceButton.speak(context, value);
          setState(() {
            selectedAnswer = value;
            if (!lastCorrect) checked = false;
          });
        },
      ),
      QuestionType.matching => _MatchingExercise(
        question: q,
        matches: matches,
        selectedLeft: selectedMatchLeft,
        wrongLeft: wrongMatchLeft,
        wrongRight: wrongMatchRight,
        wrongAttempt: wrongMatchAttempt,
        newMatchLeft: newMatchLeft,
        newMatchRight: newMatchRight,
        matchPulseAttempt: matchPulseAttempt,
        onSelectLeft: (left) {
          if (matches.containsKey(left)) return;
          setState(() {
            selectedMatchLeft = selectedMatchLeft == left ? null : left;
            _clearWrongMatch();
          });
        },
        onSelectRight: (right) {
          if (selectedMatchLeft == null || matches.containsValue(right)) {
            return;
          }
          final left = selectedMatchLeft!;
          final expected = _expectedMatch(q, left);
          setState(() {
            if (expected == right) {
              // Correct pairs are stored permanently and briefly pulse green.
              matches[left] = right;
              _clearWrongMatch();
              newMatchLeft = left;
              newMatchRight = right;
              matchPulseAttempt++;
              _scheduleMatchedPulseClear(matchPulseAttempt);
            } else {
              // Wrong pairs shake red, then return to normal after one second.
              wrongMatchLeft = left;
              wrongMatchRight = right;
              wrongMatchAttempt++;
              _scheduleWrongMatchClear(wrongMatchAttempt);
            }
            selectedMatchLeft = null;
          });
        },
      ),
      QuestionType.arrangeWords ||
      QuestionType.buildSentence => _BuildSentenceExercise(
        question: q,
        builtWords: builtWords,
        checked: checked,
        correct: checked && lastCorrect,
        feedbackAttempt: answerFeedbackAttempt,
        onAdd: (word) => setState(() => builtWords.add(word)),
        onRemove: (index) => setState(() => builtWords.removeAt(index)),
      ),
      QuestionType.imageChoice => _ImageChoiceGrid(
        question: q,
        selected: selectedAnswer,
        checked: checked,
        feedbackAttempt: answerFeedbackAttempt,
        onSelected: (value) {
          if (checked) return;
          setState(() => selectedAnswer = value);
        },
      ),
    };
  }

  Widget _questionContentArea(LessonQuestion question) {
    if (_usesChoiceActivityCard(question.type)) {
      return _ChoiceActivityCard(
        title: _titleFor(question.type),
        question: question,
        choices: question.choices,
        selected: selectedAnswer,
        checked: checked,
        answer: question.answer,
        feedbackAttempt: answerFeedbackAttempt,
        choiceMeanings: {
          for (final choice in question.choices)
            choice: translatedMeaningFor(choice),
        },
        onSelected: (value) {
          if (checked && lastCorrect) return;
          TudloVoiceButton.speak(context, value);
          setState(() {
            selectedAnswer = value;
            if (!lastCorrect) checked = false;
          });
        },
      );
    }

    if (question.type == QuestionType.matching ||
        question.type == QuestionType.imageChoice ||
        question.type == QuestionType.fillBlank) {
      return _buildQuestionBody(question);
    }

    if (question.type == QuestionType.buildSentence ||
        question.type == QuestionType.arrangeWords) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptCard(question: question),
          const SizedBox(height: 18),
          _buildQuestionBody(question),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PromptCard(question: question),
        const SizedBox(height: 18),
        _buildQuestionBody(question),
      ],
    );
  }

  bool _usesChoiceActivityCard(QuestionType type) {
    return type == QuestionType.choice ||
        type == QuestionType.translationChoice ||
        type == QuestionType.completeSentence;
  }

  String _expectedMatch(LessonQuestion question, String left) {
    final pair = question.matchingPairs[left];
    if (pair != null) return pair;

    const hiligaynonMatches = {
      'Pangalan': 'ngalan',
      'Katawhan': 'mga karakter',
      'Halamtangan': 'lugar kag tion',
      'Hinabo': 'natabo',
      'Rina': 'Child',
      'Nanay Rowena': 'Mother',
      'Iloilo River': 'River',
      'Plaza Libertad': 'Park',
    };
    final hiligaynonMatch = hiligaynonMatches[left];
    if (hiligaynonMatch != null) return hiligaynonMatch;

    final index = question.leftItems.indexOf(left);
    return index >= 0 && index < question.rightItems.length
        ? question.rightItems[index]
        : left;
  }

  void _clearWrongMatch() {
    _wrongMatchClearTimer?.cancel();
    _wrongMatchClearTimer = null;
    wrongMatchLeft = null;
    wrongMatchRight = null;
  }

  void _scheduleWrongMatchClear(int attempt) {
    _wrongMatchClearTimer?.cancel();
    _wrongMatchClearTimer = Timer(const Duration(seconds: 1), () {
      // Ignore old timers if the user has already made another attempt.
      if (!mounted || attempt != wrongMatchAttempt) return;
      setState(_clearWrongMatch);
    });
  }

  void _clearMatchedPulse() {
    _matchedPulseTimer?.cancel();
    _matchedPulseTimer = null;
    newMatchLeft = null;
    newMatchRight = null;
  }

  void _scheduleMatchedPulseClear(int attempt) {
    _matchedPulseTimer?.cancel();
    _matchedPulseTimer = Timer(const Duration(milliseconds: 650), () {
      // Ignore old timers if a newer matched-pair animation started.
      if (!mounted || attempt != matchPulseAttempt) return;
      setState(_clearMatchedPulse);
    });
  }

  String _normalizeAnswer(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchingCorrect(LessonQuestion q) {
    for (final left in q.leftItems) {
      if (matches[left] != _expectedMatch(q, left)) return false;
    }
    return true;
  }

  String _feedbackPhraseFor(LessonQuestion question) {
    final match = RegExp(r'"([^"]+)"').firstMatch(question.prompt);
    final sentence = match?.group(1) ?? question.prompt;
    if (sentence.contains('___')) {
      return _fillBlanks(sentence, question.answer.split(' '));
    }
    return question.targetPhrase;
  }

  String _fillBlanks(String sentence, List<String> answers) {
    var index = 0;
    return sentence.replaceAllMapped(RegExp(r'_{3,}'), (_) {
      if (index >= answers.length) return answers.last;
      return answers[index++];
    });
  }

  String _feedbackMeaningFor(LessonQuestion question) {
    if (question.sentenceMeaning.trim().isNotEmpty) {
      return question.sentenceMeaning.trim();
    }
    final phrase = _feedbackPhraseFor(question);
    const meanings = {
      'Kumusta ka?': 'Pangamusta',
      'Salamat gid.': 'Pagpasalamat',
      'Palihog, gusto ko sang tubig.': 'Pagpangayo sang tubig',
      'Nagkaon ako sang kan-on': 'Nagakaon sang kan-on',
      'Palihog hatag sang tubig': 'Pagpangayo sang tubig',
      'Nagabasa ako sang libro': 'Nagabasa sang libro',
      'Nagakadto ako sa eskwelahan': 'Nagakadto sa eskwelahan',
    };
    return meanings[_meaningKey(phrase)] ?? question.targetMeaning.trim();
  }

  String _meaningKey(String value) {
    return value.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final feedbackPhrase = _feedbackPhraseFor(question);
    final feedbackMeaning = _feedbackMeaningFor(question);
    final showMeaning = question.type != QuestionType.matching;
    final usesChoiceActivityCard = _usesChoiceActivityCard(question.type);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            crossAxisAlignment: question.type == QuestionType.fillBlank
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.stretch,
            children: [
              if (!usesChoiceActivityCard) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionNumberBadge(number: widget.number),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.type == QuestionType.imageChoice
                            ? question.prompt
                            : _titleFor(question.type),
                        textAlign: question.type == QuestionType.fillBlank
                            ? TextAlign.left
                            : TextAlign.center,
                        style: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              _questionContentArea(question),
              if (checked && !lastCorrect) ...[
                const SizedBox(height: 18),
                _AnswerFeedbackPanel(
                  correct: lastCorrect,
                  phrase: feedbackPhrase,
                  meaning: feedbackMeaning,
                  showDetails: showMeaning,
                ),
              ],
              const SizedBox(height: 18),
              _FeedbackMotion(
                key: ValueKey('check-$answerFeedbackAttempt'),
                correct: checked && lastCorrect,
                wrong: checked && !lastCorrect,
                child: SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: checked
                          ? lastCorrect
                                ? TudloColors.green
                                : TudloColors.coral
                          : TudloColors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: TudloColors.line,
                      disabledForegroundColor: TudloColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: checked || !canCheck ? null : _checkAnswer,
                    child: Text(
                      checked ? 'NAPASA' : 'IPASA',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (checked && lastCorrect)
          Positioned.fill(
            child: IgnorePointer(
              child: _ConfettiBurst(
                key: ValueKey('confetti-$answerFeedbackAttempt'),
                fill: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _LevelIntroHeader extends StatelessWidget {
  final String title;

  const _LevelIntroHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return const SizedBox.shrink();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        cleanTitle,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(
          color: TudloColors.ink,
          fontSize: 31,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LearningSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Color accentColor;

  const _LearningSection({
    required this.title,
    required this.child,
    this.accentColor = TudloColors.coral,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TudloColors.forest,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StoryLessonSection extends StatelessWidget {
  final LessonLevelContent content;

  const _StoryLessonSection({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'Istorya',
                style: TextStyle(
                  color: Color(0xFF259C13),
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TudloVoiceButton(
                  message: '${content.storyTitle}. ${content.story}',
                  tooltip: 'Pamatii ang istorya',
                  size: 54,
                  hiligaynon: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StoryIllustration(imagePath: _storyImagePathForContent(content)),
          const SizedBox(height: 18),
          Text(
            content.storyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF259C13),
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _SpeechBubble(text: content.story),
        ],
      ),
    );
  }
}

class _StoryIllustration extends StatelessWidget {
  final String imagePath;

  const _StoryIllustration({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      decoration: BoxDecoration(
        color: const Color(0xFFF3FFE5),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _LessonPictureAsset(
              asset: imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_) => const _StoryImageFallback(),
            ),
          ),
        ],
      ),
    );
  }
}

const String _g3MarketNumbersLessonImage =
    'assets/images/level_game/grade3/G3_U1_L1.1_Numero_sa_Merkado_SVG_Assets/background/MarketLandscape.svg';
const String _g3MarketShoppingLessonImage =
    'assets/images/level_game/grade3/G3_U1_L1.3_Pagbakal_ni_Koka_sa_Merkado_SVG_Assets/background/MarketLandscape.svg';
const String _g3LostDogLessonImage =
    'assets/images/level_game/backgrounds/grade3_landscape/FarmLandscape 1.svg';
const String _g3NewStudentLessonImage =
    'assets/images/level_game/backgrounds/grade3_landscape/ClassroomLandscape 1.svg';

String _storyImagePathForContent(LessonLevelContent content) {
  return _storyImagePathForTitles(content.title, content.storyTitle);
}

String _storyImagePathForTitles(String title, String? storyTitle) {
  if (AppData.selectedGradeLevel == GradeLevel.grade3) {
    final searchable = '$title ${storyTitle ?? ''}'.toLowerCase();
    if (searchable.contains('numero sa merkado')) {
      return _g3MarketNumbersLessonImage;
    }
    if (searchable.contains('pagbakal') ||
        searchable.contains('koka sa merkado')) {
      return _g3MarketShoppingLessonImage;
    }
    if (searchable.contains('nadula nga ido')) {
      return _g3LostDogLessonImage;
    }
    if (searchable.contains('bag-o nga estudyante')) {
      return _g3NewStudentLessonImage;
    }
  }
  return switch (AppData.selectedGradeLevel) {
    GradeLevel.grade1 => 'assets/images/level_game/empty-poem-page.png',
    GradeLevel.grade2 => 'assets/images/level_game/classroom.png',
    GradeLevel.grade3 => _g3MarketNumbersLessonImage,
  };
}

class _StoryImageFallback extends StatelessWidget {
  const _StoryImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3FFE5),
      child: const Center(
        child: Icon(Icons.image_rounded, color: TudloColors.forest, size: 58),
      ),
    );
  }
}

String _lessonCompleteBackgroundAsset(int level) {
  final grade = AppData.selectedGradeLevel;
  final unit = AppData.unitForLevel(level).number;
  final lesson = AppData.lessonNumberForLevel(level);

  if (grade == GradeLevel.grade1) {
    if (unit == 1 && lesson == 7) {
      return 'assets/images/level_game/backgrounds/beach.svg';
    }
    if (unit == 2) {
      return switch (lesson) {
        4 =>
          'assets/images/level_game/grade1/backgrounds/lesson4-familypicnic.svg',
        _ => 'assets/images/level_game/backgrounds/house.svg',
      };
    }
    if (unit == 4 || unit == 5) {
      return 'assets/images/level_game/backgrounds/garden.svg';
    }
    return 'assets/images/level_game/backgrounds/classroom.svg';
  }

  if (grade == GradeLevel.grade2) {
    if (unit == 1 && lesson == 1) {
      return _g2ClassroomWithoutAnaBackground;
    }
    if (unit == 1 && lesson == 2) {
      return _g2BirthdayWithoutAnaBackground;
    }
    if (unit == 2) {
      return 'assets/images/level_game/grade2/backgrounds/Tudlo_Park_Intro_Background.svg';
    }
    return 'assets/images/level_game/backgrounds/classroom.svg';
  }

  return 'assets/images/level_game/backgrounds/garden.svg';
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.speechBubble,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 42),
            child: Text(
              text,
              style: const TextStyle(
                color: TudloColors.ink,
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCardGrid extends StatelessWidget {
  final List<LessonExample> examples;

  const _ExampleCardGrid({required this.examples});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: examples.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ExampleCard(
            example: entry.value,
            color: _lessonPalette(entry.key),
          ),
        );
      }).toList(),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final LessonExample example;
  final Color color;

  const _ExampleCard({required this.example, required this.color});

  @override
  Widget build(BuildContext context) {
    final category = example.category.isEmpty ? 'Example' : example.category;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Icon(_iconForCategory(category), color: color, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      example.hiligaynon,
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 23,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (example.note.trim().isNotEmpty)
                      Text(
                        example.note,
                        style: const TextStyle(
                          color: TudloColors.muted,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              TudloVoiceButton(
                message: example.hiligaynon,
                tooltip: 'Pamatii ang halimbawa',
                size: 46,
                hiligaynon: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _lessonPalette(int index) {
  const colors = [
    TudloColors.orange,
    TudloColors.blue,
    Color(0xFF8B5CF6),
    TudloColors.green,
    TudloColors.coral,
  ];
  return colors[index % colors.length];
}

IconData _iconForCategory(String category) {
  final text = category.toLowerCase();
  if (text.contains('tawo') || text.contains('person')) {
    return Icons.face_rounded;
  }
  if (text.contains('lugar') || text.contains('place')) {
    return Icons.park_rounded;
  }
  if (text.contains('sapat') || text.contains('animal')) {
    return Icons.cruelty_free_rounded;
  }
  if (text.contains('count')) return Icons.format_list_numbered_rounded;
  if (text.contains('mass')) return Icons.water_drop_rounded;
  if (text.contains('pangalan')) return Icons.star_rounded;
  return Icons.category_rounded;
}

class _QuizSectionHeader extends StatelessWidget {
  const _QuizSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Short Quiz',
      style: TextStyle(
        color: TudloColors.ink,
        fontSize: 34,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _QuestionNumberBadge extends StatelessWidget {
  final int number;

  const _QuestionNumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: TudloColors.softGreen,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: TudloColors.green,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

//scoreboard pop-up
class _LessonCompleteDialog extends StatefulWidget {
  final int level;
  final String backgroundAsset;
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final bool Function() onClaimXp;
  final VoidCallback onBackToMap;
  final FutureOr<void> Function() onContinue;

  const _LessonCompleteDialog({
    required this.level,
    required this.backgroundAsset,
    required this.accuracy,
    required this.mistakes,
    required this.durationLabel,
    required this.onClaimXp,
    required this.onBackToMap,
    required this.onContinue,
  });

  @override
  State<_LessonCompleteDialog> createState() => _LessonCompleteDialogState();
}

class _LessonCompleteDialogState extends State<_LessonCompleteDialog> {
  bool _showStreak = false;
  bool _claimed = false;

  /// Star count is based on accuracy so the reward screen reflects performance.
  int get starCount {
    if (widget.accuracy == 100) return 3;
    if (widget.accuracy >= 90) return 2;
    if (widget.accuracy >= 75) return 1;
    return 0;
  }

  void _claimXp() {
    final showStreak = _claimed ? _showStreak : widget.onClaimXp();
    if (!_claimed) {
      _claimed = true;
    }
    if (showStreak) {
      setState(() => _showStreak = true);
      return;
    }
    unawaited(Future.sync(widget.onContinue));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showStreak
            ? _LessonStreakPage(
                key: const ValueKey('streak'),
                streakDays: AppData.streakDays,
                onCommitted: widget.onContinue,
                onBackToMap: widget.onBackToMap,
              )
            : _LessonResultPage(
                key: const ValueKey('result'),
                backgroundAsset: widget.backgroundAsset,
                accuracy: widget.accuracy,
                mistakes: widget.mistakes,
                durationLabel: widget.durationLabel,
                onBackToMap: widget.onBackToMap,
                onContinue: _claimXp,
              ),
      ),
    );
  }
}

class _LessonResultPage extends StatelessWidget {
  final String backgroundAsset;
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final VoidCallback onBackToMap;
  final FutureOr<void> Function() onContinue;

  const _LessonResultPage({
    super.key,
    required this.backgroundAsset,
    required this.accuracy,
    required this.mistakes,
    required this.durationLabel,
    required this.onBackToMap,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LessonBackgroundAsset(asset: backgroundAsset),
          ColoredBox(color: TudloColors.ink.withValues(alpha: .48)),
          Positioned(
            left: 24,
            top: top + 18,
            child: _PresentationImageButton(
              asset:
                  'assets/images/level_game/lesson-game-assets/exit-page.png',
              size: 54,
              onTap: onBackToMap,
              tooltip: 'Balik',
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, top + 86, 24, 24 + bottom),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -size.height * .035),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _ResultGoldStar(),
                          SizedBox(height: size.height * .035),
                          Text(
                            'Natapos mo na ang Leksyon!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: (size.width * .083).clamp(32.0, 50.0),
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: [
                                Shadow(
                                  color: TudloColors.ink.withValues(alpha: .70),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Maayo gid!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: (size.width * .055).clamp(24.0, 36.0),
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: [
                                Shadow(
                                  color: TudloColors.ink.withValues(alpha: .70),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _ResultPrimaryButton(
                        label: 'MAG BALIK SA MAPA',
                        onTap: onBackToMap,
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ResultPrimaryButton(
                        label: 'PADAYUN KITA',
                        onTap: onContinue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonStreakPage extends StatelessWidget {
  final int streakDays;
  final FutureOr<void> Function() onCommitted;
  final VoidCallback onBackToMap;

  const _LessonStreakPage({
    super.key,
    required this.streakDays,
    required this.onCommitted,
    required this.onBackToMap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    const week = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final completedDays = streakDays.clamp(0, week.length);
    final fireSize = (size.width * .105).clamp(38.0, 50.0);
    final dayFontSize = (size.width * .04).clamp(14.0, 19.0);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(color: Colors.white)),
          Positioned(
            left: 24,
            top: MediaQuery.paddingOf(context).top + 18,
            child: _PresentationImageButton(
              asset:
                  'assets/images/level_game/lesson-game-assets/exit-page.png',
              size: 54,
              onTap: onBackToMap,
              tooltip: 'Balik',
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 30, 24, 24 + bottom),
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Padayona kada adlaw para magdugang ang imo streak!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: TudloColors.forest,
                      fontSize: (size.width * .052).clamp(22.0, 34.0),
                      height: 1.22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _LessonKokaMascot(
                  size: (size.width * .58).clamp(220.0, 340.0),
                  mood: KokaMood.idle,
                ),
                const SizedBox(height: 26),
                Text(
                  '$streakDays',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.green,
                    fontSize: (size.width * .30).clamp(112.0, 180.0),
                    height: .82,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  streakDays == 1 ? 'day streak' : 'day streaks',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.green,
                    fontSize: (size.width * .095).clamp(36.0, 58.0),
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    for (var index = 0; index < week.length; index++)
                      Expanded(
                        child: Center(
                          child: _StreakDayChip(
                            label: week[index],
                            completed: index < completedDays,
                            fireSize: fireSize,
                            labelFontSize: dayFontSize,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 38),
                SizedBox(
                  width: double.infinity,
                  child: _ResultPrimaryButton(
                    label: 'MAGPADAYON SA SUNOD NGA LEKSYON',
                    onTap: onCommitted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultGoldStar extends StatelessWidget {
  static const _asset =
      'assets/images/level_game/lesson-game-assets/Tudlo_Reward_Star_Rays_Exact.svg';

  const _ResultGoldStar();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final size = math.min(width * .84, height * .34).clamp(260.0, 430.0);
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(_asset, fit: BoxFit.contain),
    );
  }
}

class _ResultPrimaryButton extends StatelessWidget {
  final String label;
  final FutureOr<void> Function() onTap;
  final bool outlined;

  const _ResultPrimaryButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(AppAudioService.instance.playTap());
        unawaited(Future.sync(onTap));
      },
      child: Container(
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : TudloColors.green,
          borderRadius: BorderRadius.circular(22),
          border: outlined
              ? Border.all(color: TudloColors.green, width: 4)
              : null,
          boxShadow: [
            BoxShadow(
              color: outlined
                  ? TudloColors.forest.withValues(alpha: .14)
                  : TudloColors.forest.withValues(alpha: .26),
              blurRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: outlined ? TudloColors.green : Colors.white,
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _StreakDayChip extends StatefulWidget {
  final String label;
  final bool completed;
  final double fireSize;
  final double labelFontSize;

  const _StreakDayChip({
    required this.label,
    required this.completed,
    required this.fireSize,
    required this.labelFontSize,
  });

  @override
  State<_StreakDayChip> createState() => _StreakDayChipState();
}

class _StreakDayChipState extends State<_StreakDayChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _showUnlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _scale = Tween<double>(begin: .66, end: 1).animate(curve);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.completed) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showUnlocked = true);
        _controller.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _StreakDayChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.completed && widget.completed) {
      _showUnlocked = false;
      _controller.reset();
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showUnlocked = true);
        _controller.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.completed;
    final asset = completed && _showUnlocked
        ? 'assets/images/level_game/lesson-game-assets/fire-unlocked.png'
        : 'assets/images/level_game/lesson-game-assets/fire-locked.png';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.nunito(
            color: completed ? TudloColors.green : TudloColors.muted,
            fontSize: widget.labelFontSize,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: widget.fireSize * .22),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = completed && _showUnlocked ? _scale.value : 1.0;
            final opacity = completed && _showUnlocked ? _opacity.value : 1.0;
            return Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Image.asset(
            asset,
            key: ValueKey(asset),
            width: widget.fireSize,
            height: widget.fireSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.local_fire_department_rounded,
              color: completed ? TudloColors.green : TudloColors.muted,
              size: widget.fireSize,
            ),
          ),
        ),
      ],
    );
  }
}

class _Sparkle extends StatelessWidget {
  final Color color;
  final double size;

  const _Sparkle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: color.withValues(alpha: .28),
      size: size,
    );
  }
}

class _ChoiceActivityCard extends StatelessWidget {
  final String title;
  final LessonQuestion question;
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final Map<String, String> choiceMeanings;
  final ValueChanged<String> onSelected;

  const _ChoiceActivityCard({
    required this.title,
    required this.question,
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
    required this.choiceMeanings,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotSize = constraints.maxWidth < 380 ? 112.0 : 132.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: mascotSize + 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 8,
                    bottom: 0,
                    child: _LessonKokaMascot(size: mascotSize),
                  ),
                  Positioned(
                    left: mascotSize * .70,
                    right: 6,
                    top: 8,
                    child: _ChoiceTitleBubble(title: title),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF78EA86),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _choicePromptText(question.prompt),
                      textAlign: TextAlign.left,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(
                            color: TudloColors.forest,
                            offset: Offset(1, 1.4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    if (question.imagePath.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Center(
                        child: Container(
                          width: 138,
                          height: 138,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFFF5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.asset(
                            question.imagePath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) =>
                                const _ImageChoiceFallback(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _ChoiceGrid(
                      choices: choices,
                      selected: selected,
                      checked: checked,
                      answer: answer,
                      feedbackAttempt: feedbackAttempt,
                      choiceMeanings: choiceMeanings,
                      onSelected: onSelected,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _choicePromptText(String prompt) {
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    final text = (match?.group(1) ?? prompt).trim();
    if (text.startsWith('"') && text.endsWith('"')) return text;
    return '"$text"';
  }
}

class _ChoiceTitleBubble extends StatelessWidget {
  final String title;

  const _ChoiceTitleBubble({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 22,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final Map<String, String> choiceMeanings;
  final ValueChanged<String> onSelected;

  const _ChoiceGrid({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
    required this.choiceMeanings,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: choices.map((choice) {
            final active = selected == choice;
            final correct = checked && active && choice == answer;
            final wrong = checked && active && choice != answer;
            return SizedBox(
              width: tileWidth,
              child: _ChoicePill(
                label: choice,
                active: active,
                correct: correct,
                wrong: wrong,
                feedbackKey: active ? feedbackAttempt : 0,
                longPressMeaning: choiceMeanings[choice] ?? choice,
                onTap: checked ? null : () => onSelected(choice),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final String longPressMeaning;
  final VoidCallback? onTap;

  const _ChoicePill({
    required this.label,
    required this.active,
    required this.correct,
    required this.wrong,
    required this.feedbackKey,
    required this.longPressMeaning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? const Color(0xFF2BA83A)
        : const Color(0xFFFFF15A);
    final foreground = (active || correct || wrong)
        ? Colors.white
        : TudloColors.forest;

    return WordMeaningTooltipTarget(
      meaning: longPressMeaning,
      child: _FeedbackMotion(
        key: ValueKey('choice-pill-$label-$feedbackKey'),
        correct: correct,
        wrong: wrong,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: foreground,
                  fontSize: 21,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final LessonQuestion question;

  const _PromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    // Shared prompt layout for all Level Game question types.
    // The mascot makes the prompt feel like a spoken message, while the rounded
    // bubble keeps the question readable and consistent across exercises.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 430;
        final bubble = Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 12),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: TudloColors.green,
                  size: 32,
                ),
              ),
              Expanded(child: _PromptText(question: question)),
            ],
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _LessonKokaMascot(size: 148),
              ),
              Transform.translate(offset: const Offset(0, -14), child: bubble),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 142,
              height: 160,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _LessonKokaMascot(size: 150),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8, bottom: 10),
                child: bubble,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PromptText extends StatelessWidget {
  final LessonQuestion question;

  const _PromptText({required this.question});

  @override
  Widget build(BuildContext context) {
    final promptText = _displayPrompt(question.prompt);
    const style = TextStyle(
      color: TudloColors.ink,
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w900,
    );

    // Build-sentence prompts show the whole quoted sentence as one clean text
    // block so quotation marks do not split away from the sentence.
    if (question.type == QuestionType.buildSentence ||
        question.type == QuestionType.arrangeWords) {
      return Text(promptText, style: style);
    }

    // Only render the tap-to-translate behavior when the question defines a
    // target phrase. Otherwise this is plain text.
    if (question.targetPhrase.trim().isEmpty ||
        question.targetMeaning.trim().isEmpty) {
      return Text(promptText, style: style);
    }

    return TapWordMeaningText(
      fullQuestionText: promptText,
      targetPhrase: question.targetPhrase,
      targetMeaning: question.targetMeaning,
      directionLabel: question.directionLabel,
      style: style,
      includeKnownWords: true,
    );
  }

  String _displayPrompt(String prompt) {
    // The bubble only shows the actual phrase/sentence in quotation marks.
    // Example: Complete the sentence "___ ka?" becomes "___ ka?".
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    final quoted = match?.group(1);
    return quoted == null ? _quoteOnce(prompt) : _quoteOnce(quoted);
  }

  String _quoteOnce(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) return trimmed;
    return '"$trimmed"';
  }
}

class _ScenarioFillBlankExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _ScenarioFillBlankExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sentence = _missingSentenceFrom(question.prompt);
    final remaining = [...question.choices];
    for (final word in builtWords) {
      remaining.remove(word);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasImage = question.imagePath.trim().isNotEmpty;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final imageHeight = hasImage
            ? (availableHeight * .32).clamp(180.0, 300.0).toDouble()
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage) ...[
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: imageHeight,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Image.asset(
                    question.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const _ImageChoiceFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ScenarioSentenceText(
                sentence: sentence,
                builtWords: builtWords,
                checked: checked,
                correct:
                    checked &&
                    _normalizeWords(builtWords) ==
                        _normalizeWords(answer.split(' ')),
                wordMeanings: question.wordMeanings,
                onRemove: onRemove,
              ),
            ),
            if (!checked) ...[
              const SizedBox(height: 24),
              _ScenarioWordChoices(
                choices: remaining,
                checked: checked,
                answerWords: answer.split(' '),
                feedbackAttempt: feedbackAttempt,
                wordMeanings: question.wordMeanings,
                onAdd: onAdd,
              ),
            ],
          ],
        );
      },
    );
  }

  String _missingSentenceFrom(String prompt) {
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    return match?.group(1) ?? prompt;
  }

  String _normalizeWords(List<String> words) {
    return words.join(' ').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _ScenarioSentenceText extends StatelessWidget {
  final String sentence;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final Map<String, String> wordMeanings;
  final ValueChanged<int> onRemove;

  const _ScenarioSentenceText({
    required this.sentence,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.wordMeanings,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    var blankIndex = 0;
    final words = sentence.split(RegExp(r'\s+'));
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 9,
      runSpacing: 16,
      children: words.map((word) {
        if (word.contains('___')) {
          final currentBlank = blankIndex;
          final suffix = word.replaceFirst(RegExp(r'_{3,}'), '');
          final selectedWord = blankIndex < builtWords.length
              ? builtWords[blankIndex]
              : '';
          final chip = _ScenarioBlankChip(
            label: selectedWord,
            checked: checked,
            correct: correct,
            onTap: selectedWord.isEmpty || checked
                ? null
                : () => onRemove(currentBlank),
          );
          blankIndex++;
          if (suffix.isEmpty) return chip;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              chip,
              Text(
                suffix,
                style: const TextStyle(
                  color: TudloColors.ink,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        }
        final key = _meaningKeyFor(word);
        final meaning = wordMeanings[key] ?? '';
        final text = Text(
          word,
          style: TextStyle(
            color: TudloColors.ink,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w900,
            decoration: meaning.isEmpty ? null : TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: TudloColors.brightGreen,
            decorationThickness: 2,
          ),
        );
        if (meaning.isEmpty) return text;
        return WordMeaningTooltipTarget(
          meaning: meaning,
          showOnTap: true,
          child: text,
        );
      }).toList(),
    );
  }

  String _meaningKeyFor(String word) {
    return word.replaceAll(RegExp(r'^[^\w-]+|[^\w-]+$'), '');
  }
}

class _ScenarioBlankChip extends StatelessWidget {
  final String label;
  final bool checked;
  final bool correct;
  final VoidCallback? onTap;

  const _ScenarioBlankChip({
    required this.label,
    required this.checked,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasWord = label.trim().isNotEmpty;
    final color = checked
        ? correct
              ? TudloColors.green
              : TudloColors.coral
        : TudloColors.green;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: hasWord ? color.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          hasWord ? label : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: checked && !correct ? TudloColors.coral : TudloColors.ink,
            fontSize: 25,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ScenarioWordChoices extends StatelessWidget {
  final List<String> choices;
  final bool checked;
  final List<String> answerWords;
  final int feedbackAttempt;
  final Map<String, String> wordMeanings;
  final ValueChanged<String> onAdd;

  const _ScenarioWordChoices({
    required this.choices,
    required this.checked,
    required this.answerWords,
    required this.feedbackAttempt,
    required this.wordMeanings,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('scenario-choices-$feedbackAttempt'),
      correct: false,
      wrong: false,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: choices.map((choice) {
          final canRevealMeaning = !answerWords.any(
            (answer) => answer.toLowerCase() == choice.toLowerCase(),
          );
          final chip = ActionChip(
            label: Text(choice),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 11,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: TudloColors.line, width: 2.5),
            ),
            labelStyle: const TextStyle(
              color: TudloColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            onPressed: checked ? null : () => onAdd(choice),
          );
          final meaning = canRevealMeaning ? wordMeanings[choice] ?? '' : '';
          return meaning.isEmpty
              ? chip
              : WordMeaningTooltipTarget(meaning: meaning, child: chip);
        }).toList(),
      ),
    );
  }
}

class _ChoiceList extends StatelessWidget {
  final List<String> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackAttempt;
  final Map<String, String> choiceMeanings;
  final ValueChanged<String> onSelected;

  const _ChoiceList({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackAttempt,
    required this.choiceMeanings,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.map((choice) {
        final active = selected == choice;
        final correct = checked && active && choice == answer;
        final wrong = checked && active && choice != answer;
        return _AnswerTile(
          label: choice,
          active: active,
          correct: correct,
          wrong: wrong,
          feedbackKey: active ? feedbackAttempt : 0,
          longPressMeaning: choiceMeanings[choice] ?? choice,
          onTap: checked ? null : () => onSelected(choice),
        );
      }).toList(),
    );
  }
}

class _MatchingExercise extends StatelessWidget {
  final LessonQuestion question;
  final Map<String, String> matches;
  final String? selectedLeft;
  final String? wrongLeft;
  final String? wrongRight;
  final int wrongAttempt;
  final String? newMatchLeft;
  final String? newMatchRight;
  final int matchPulseAttempt;
  final ValueChanged<String> onSelectLeft;
  final ValueChanged<String> onSelectRight;

  const _MatchingExercise({
    required this.question,
    required this.matches,
    required this.selectedLeft,
    required this.wrongLeft,
    required this.wrongRight,
    required this.wrongAttempt,
    required this.newMatchLeft,
    required this.newMatchRight,
    required this.matchPulseAttempt,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  @override
  Widget build(BuildContext context) {
    // Matched right-side answers are tracked by value so each English meaning
    // can only be used once.
    final usedRight = matches.values.toSet();
    final maxRows = question.leftItems.length > question.rightItems.length
        ? question.leftItems.length
        : question.rightItems.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowWidth = (constraints.maxWidth * .84)
            .clamp(280.0, 560.0)
            .toDouble();
        return Column(
          children: List.generate(maxRows, (index) {
            final left = index < question.leftItems.length
                ? question.leftItems[index]
                : null;
            final right = index < question.rightItems.length
                ? question.rightItems[index]
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: SizedBox(
                  width: rowWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: left == null
                            ? const SizedBox(height: 82)
                            : _MatchTile(
                                label: left,
                                selected: selectedLeft == left,
                                matched: matches.containsKey(left),
                                wrong: wrongLeft == left,
                                justMatched: newMatchLeft == left,
                                shakeKey: wrongLeft == left ? wrongAttempt : 0,
                                jumpKey: newMatchLeft == left
                                    ? matchPulseAttempt
                                    : 0,
                                onTap: () => onSelectLeft(left),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: right == null
                            ? const SizedBox(height: 82)
                            : _MatchTile(
                                label: right,
                                selected: false,
                                matched: usedRight.contains(right),
                                wrong: wrongRight == right,
                                justMatched: newMatchRight == right,
                                shakeKey: wrongRight == right
                                    ? wrongAttempt
                                    : 0,
                                jumpKey: newMatchRight == right
                                    ? matchPulseAttempt
                                    : 0,
                                onTap: () => onSelectRight(right),
                                compact: true,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool matched;
  final bool wrong;
  final bool justMatched;
  final int shakeKey;
  final int jumpKey;
  final bool compact;
  final VoidCallback onTap;

  const _MatchTile({
    required this.label,
    required this.selected,
    required this.matched,
    required this.wrong,
    required this.justMatched,
    required this.shakeKey,
    required this.jumpKey,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Matching tiles have four visual states: default, selected, wrong, and
    // completed. Right-column tiles intentionally stay active until matched.
    final active = selected || matched || wrong || justMatched;
    final textColor = justMatched
        ? TudloColors.green
        : matched
        ? TudloColors.muted
        : wrong
        ? TudloColors.coral
        : TudloColors.ink;
    final backgroundColor = wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : justMatched
        ? TudloColors.green.withValues(alpha: .10)
        : matched
        ? TudloColors.paper
        : active
        ? TudloColors.green.withValues(alpha: .08)
        : Colors.white;
    final shadowColor = wrong ? TudloColors.coral : TudloColors.green;

    return WordMeaningTooltipTarget(
      meaning: translatedMeaningFor(label),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$label-$shakeKey-$jumpKey'),
        tween: Tween(begin: 0, end: (wrong || justMatched) ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final shakeOffset = wrong
              ? math.sin(value * math.pi * 6) * (1 - value) * 9
              : 0.0;
          final jumpOffset = justMatched
              ? -math.sin(value * math.pi) * (1 - value * .25) * 10
              : 0.0;

          return Transform.translate(
            offset: Offset(shakeOffset, jumpOffset),
            child: child,
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: matched ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: .16),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 19 : 21,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildSentenceExercise extends StatelessWidget {
  final LessonQuestion question;
  final List<String> builtWords;
  final bool checked;
  final bool correct;
  final int feedbackAttempt;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _BuildSentenceExercise({
    required this.question,
    required this.builtWords,
    required this.checked,
    required this.correct,
    required this.feedbackAttempt,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Start with all word blocks, then remove the ones already placed in the
    // answer box. This supports repeated words because remove() only removes
    // one matching value at a time.
    final remaining = [...question.sentenceWords];
    for (final word in builtWords) {
      remaining.remove(word);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasImage = question.imagePath.trim().isNotEmpty;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final imageHeight = hasImage
            ? (availableHeight * .28).clamp(150.0, 260.0).toDouble()
            : 0.0;
        const answerHeight = 120.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    maxHeight: imageHeight,
                  ),
                  child: Image.asset(
                    question.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const _ImageChoiceFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _FeedbackMotion(
              key: ValueKey('build-$feedbackAttempt'),
              correct: checked && correct,
              wrong: checked && !correct,
              child: Container(
                width: double.infinity,
                height: answerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: answerHeight * .38,
                      child: _BuildSentenceLine(
                        color: checked && !correct
                            ? TudloColors.coral
                            : TudloColors.line,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: answerHeight * .76,
                      child: _BuildSentenceLine(
                        color: checked && !correct
                            ? TudloColors.coral
                            : TudloColors.line,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 7,
                        children: builtWords.asMap().entries.map((entry) {
                          return ActionChip(
                            label: Text(entry.value),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.white,
                            disabledColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: TudloColors.line,
                                width: 3,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: TudloColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                            onPressed: checked
                                ? () {}
                                : () => onRemove(entry.key),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!checked) ...[
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: remaining.map((word) {
                    return WordMeaningTooltipTarget(
                      meaning: translatedMeaningFor(word),
                      child: ActionChip(
                        label: Text(word),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: TudloColors.line,
                            width: 3,
                          ),
                        ),
                        labelStyle: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                        onPressed: () => onAdd(word),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BuildSentenceLine extends StatelessWidget {
  final Color color;

  const _BuildSentenceLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ImageChoiceGrid extends StatelessWidget {
  final LessonQuestion question;
  final String? selected;
  final bool checked;
  final int feedbackAttempt;
  final ValueChanged<String> onSelected;

  const _ImageChoiceGrid({
    required this.question,
    required this.selected,
    required this.checked,
    required this.feedbackAttempt,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Image activities use Duolingo-style picture cards: four visual choices,
    // each with the Hiligaynon label below the image.
    final cards = question.imageChoices.map((term) {
      final active = selected == term.hil;
      final correct = checked && active && term.hil == question.answer;
      final wrong = checked && active && term.hil != question.answer;
      return _ImageChoiceCard(
        term: term,
        active: active,
        correct: correct,
        wrong: wrong,
        feedbackKey: active ? feedbackAttempt : 0,
        onTap: checked
            ? null
            : () {
                TudloVoiceButton.speak(context, term.hil);
                onSelected(term.hil);
              },
      );
    }).toList();

    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 520,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: .88,
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _ImageChoiceCard extends StatelessWidget {
  final LessonTerm term;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback? onTap;

  const _ImageChoiceCard({
    required this.term,
    required this.active,
    required this.correct,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = correct
        ? TudloColors.green.withValues(alpha: .12)
        : wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : active
        ? TudloColors.softGreen
        : Colors.white;
    final labelColor = active || correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : TudloColors.ink;

    return _FeedbackMotion(
      key: ValueKey('${term.hil}-$feedbackKey'),
      correct: correct,
      wrong: wrong,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (active ? TudloColors.green : TudloColors.ink)
                    .withValues(alpha: active ? .15 : .05),
                blurRadius: active ? 18 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: term.imagePath == null
                        ? const _ImageChoiceFallback()
                        : Image.asset(
                            term.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const _ImageChoiceFallback(),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                term.hil,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 20,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageChoiceFallback extends StatelessWidget {
  const _ImageChoiceFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TudloColors.softGreen,
      child: const Center(
        child: Icon(Icons.image_rounded, color: TudloColors.green, size: 42),
      ),
    );
  }
}

class _AnswerFeedbackPanel extends StatelessWidget {
  final bool correct;
  final String phrase;
  final String meaning;
  final bool showDetails;

  const _AnswerFeedbackPanel({
    required this.correct,
    required this.phrase,
    required this.meaning,
    required this.showDetails,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct ? TudloColors.green : TudloColors.coral;
    final title = correct ? 'Maayo gid!' : 'Suliton liwat!';
    final subtitle = correct
        ? 'Husto ang imo sabat.'
        : 'Tan-awa liwat ang sabat.';

    // Feedback panel shown after checking an answer. Correct answers use a
    // soft green sheet with the mascot and answer details.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: correct
            ? TudloColors.softGreen.withValues(alpha: .92)
            : TudloColors.coral.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LessonKokaMascot(
            size: 102,
            mood: correct ? KokaMood.idle : KokaMood.annoyed,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        phrase,
                        softWrap: true,
                        style: const TextStyle(
                          color: TudloColors.ink,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(Icons.volume_up_rounded, color: accent, size: 32),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;
  final bool wrong;
  final int feedbackKey;
  final String longPressMeaning;
  final VoidCallback? onTap;

  const _AnswerTile({
    required this.label,
    required this.active,
    required this.correct,
    required this.wrong,
    required this.feedbackKey,
    required this.longPressMeaning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = correct
        ? TudloColors.green.withValues(alpha: .10)
        : wrong
        ? TudloColors.coral.withValues(alpha: .08)
        : active
        ? TudloColors.sky.withValues(alpha: .12)
        : Colors.white;
    //Word meaning for long press word option
    return WordMeaningTooltipTarget(
      meaning: longPressMeaning,
      child: _FeedbackMotion(
        key: ValueKey('$label-$feedbackKey'),
        correct: correct,
        wrong: wrong,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: wrong ? TudloColors.coral : TudloColors.ink,
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Animation for button
class _FeedbackMotion extends StatelessWidget {
  final bool correct;
  final bool wrong;
  final Widget child;

  const _FeedbackMotion({
    super.key,
    required this.correct,
    required this.wrong,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (correct || wrong) ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final shakeOffset = wrong
            ? math.sin(value * math.pi * 6) * (1 - value) * 9
            : 0.0;
        final jumpOffset = correct
            ? -math.sin(value * math.pi) * (1 - value * .25) * 10
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, jumpOffset),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _ConfettiBurst extends StatelessWidget {
  final bool fill;

  const _ConfettiBurst({super.key, this.fill = false});

  @override
  Widget build(BuildContext context) {
    final confetti = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _ConfettiPainter(progress: value),
          child: const SizedBox.expand(),
        );
      },
    );

    if (fill) return confetti;

    return SizedBox(height: 86, child: confetti);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({required this.progress});

  static const _colors = [
    TudloColors.green,
    TudloColors.blue,
    TudloColors.gold,
    TudloColors.coral,
    Color(0xFF8B5CF6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .58);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 42; i++) {
      final angle = (-math.pi) + (math.pi * 2) * (i / 41);
      final distance = (24 + (i % 7) * 11) * progress;
      final fall = 34 * progress * progress;
      final position =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance + fall);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = _colors[i % _colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + progress * math.pi);
      final width = 7.0 + (i % 3) * 2;
      final height = 12.0 + (i % 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
