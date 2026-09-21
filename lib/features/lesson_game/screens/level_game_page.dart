import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/lesson_score.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

const int _lessonQuizCount = 5;

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
    barrierColor: TudloColors.ink.withValues(alpha: .55),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          decoration: BoxDecoration(
            color: TudloColors.paper,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: TudloColors.ink.withValues(alpha: .20),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                top: -4,
                child: IconButton(
                  tooltip: 'Magpabilin',
                  onPressed: () => Navigator.pop(dialogContext, false),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: TudloColors.muted,
                    size: 30,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const TudloMascot(size: 138, mood: KokaMood.curious),
                  const SizedBox(height: 12),
                  const Text(
                    'Mahalin ka na?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TudloColors.ink,
                      fontSize: 29,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tapusa ang leksiyon, ukon madula ang imo progreso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TudloColors.muted,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TudloColors.softGreen,
                              foregroundColor: TudloColors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('Halin'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TudloColors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('Magpabilin'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return shouldExit == true;
}

Future<void> _exitLessonFromContext(BuildContext context) async {
  final shouldExit = await _showLessonExitConfirmation(context);
  if (!context.mounted || !shouldExit) return;
  await TudloVoiceButton.stop();
  if (!context.mounted) return;
  Navigator.pop(context);
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

class _LevelGamePageState extends State<LevelGamePage> {
  late final Future<LevelContent> _contentFuture;
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
    super.dispose();
  }

  bool _claimRewardsOnce() {
    if (_rewardsClaimed) return _showDailyStreakAfterCompletion;
    _rewardsClaimed = true;

    // Progress is saved only when the learner taps the completion button.
    // This prevents repeated completion interactions from saving twice.
    final wasCompleted = AppData.completedLevels.contains(widget.level);
    final previousNextLevel = AppData.firstUnlockedIncompleteLevel;
    AppData.saveLevelScore(widget.level, _buildLessonScoreStats());
    _showDailyStreakAfterCompletion = AppData.recordLessonStreakForToday();
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
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _showCompleteDialog();
      });
    }
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
        accuracy: accuracy,
        mistakes: scoreStats.mistakes,
        durationLabel: durationLabel,
        onClaimXp: _claimRewardsOnce,
        onBackToMap: () {
          _claimRewardsOnce();
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
            (route) => false,
          );
        },
        onContinue: () async {
          _claimRewardsOnce();
          Navigator.pop(context);
          if (widget.level >= AppData.maxLevel) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const AppShell(initialIndex: 0),
              ),
              (route) => false,
            );
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
            MaterialPageRoute(
              builder: (_) => LevelGamePage(level: widget.level + 1),
            ),
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
    Navigator.pop(context);
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
        final gradeThreeLesson =
            levelContent != null && _isGradeThreeContent(levelContent);
        final customLessonFlow =
            alphabetLesson ||
            unitOneReviewLesson ||
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
                        ? Column(
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
                                            _handleQuestionChecked(index, true),
                                      )
                                    : unitOneReviewLesson
                                    ? _GradeOneUnitOneReviewLesson(
                                        content: levelContent,
                                        onQuizAttempt: _recordQuestionAttempt,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : numberLesson
                                    ? _GradeOneNumberLesson(
                                        content: levelContent,
                                        onQuizAttempt: _recordQuestionAttempt,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : helperLesson
                                    ? _GradeOneHelperLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : animalLesson
                                    ? _GradeOneAnimalLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : placeLesson
                                    ? _GradeOnePlaceLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      )
                                    : gradeTwoLesson
                                    ? _GradeTwoTalkBuildSolveLesson(
                                        content: levelContent,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
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
                                    : _GradeOneFamilyLesson(
                                        content: levelContent,
                                        onQuizAttempt: _recordQuestionAttempt,
                                        onQuizCorrect: (index) =>
                                            _handleQuestionChecked(index, true),
                                      ),
                              ),
                            ],
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
            TudloMascot(size: 126, mood: KokaMood.curious),
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

typedef _Grade3QuestionCompleted =
    void Function(
      int index, {
      required bool firstAttemptCorrect,
      required int attemptCount,
      required bool usedAudioSupport,
      required bool usedLookBackSupport,
    });

class _Grade3QuestionAttempt {
  final String lessonId;
  final String questionId;
  final String questionType;
  final bool firstAttemptCorrect;
  final int attemptCount;
  final bool usedAudioSupport;
  final bool usedLookBackSupport;
  final DateTime completedAt;

  const _Grade3QuestionAttempt({
    required this.lessonId,
    required this.questionId,
    required this.questionType,
    required this.firstAttemptCorrect,
    required this.attemptCount,
    required this.usedAudioSupport,
    required this.usedLookBackSupport,
    required this.completedAt,
  });
}

class _LessonAttemptTracker {
  final Map<String, _ActivityAttemptDraft> _activities = {};
  int expectedActivities = 0;

  bool hasActivity(String activityId) {
    return _activities.containsKey(activityId);
  }

  void recordAttempt({required String activityId, required bool correct}) {
    final activity = _activities.putIfAbsent(
      activityId,
      () => _ActivityAttemptDraft(activityId: activityId),
    );
    activity.record(correct);
  }

  LessonScoreStats toStats({
    required String lessonId,
    required int expectedActivities,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    final activities =
        _activities.values
            .map((activity) => activity.toScore(startedAt))
            .toList()
          ..sort((a, b) => a.activityId.compareTo(b.activityId));
    final attempts = activities.fold<int>(
      0,
      (total, activity) => total + activity.attempts,
    );
    final mistakes = activities.fold<int>(
      0,
      (total, activity) => total + activity.mistakes,
    );
    final correctAnswers = activities
        .where((activity) => activity.attempts > activity.mistakes)
        .length;
    final accuracy = attempts == 0
        ? 0
        : ((correctAnswers / attempts) * 100).round();

    return LessonScoreStats(
      lessonId: lessonId,
      totalActivities: expectedActivities > 0
          ? expectedActivities
          : this.expectedActivities,
      attempts: attempts,
      correctAnswers: correctAnswers,
      mistakes: mistakes,
      accuracy: accuracy,
      bestAccuracy: accuracy,
      replayCount: 0,
      timeTakenMs: completedAt.difference(startedAt).inMilliseconds,
      completionDate: completedAt,
      completed: true,
      activities: activities,
    );
  }
}

class _ActivityAttemptDraft {
  final String activityId;
  final DateTime startedAt = DateTime.now();
  int attempts = 0;
  int mistakes = 0;
  bool completed = false;
  DateTime? completedAt;

  _ActivityAttemptDraft({required this.activityId});

  void record(bool correct) {
    if (completed && correct) return;
    attempts++;
    if (correct) {
      completed = true;
      completedAt = DateTime.now();
      return;
    }
    mistakes++;
  }

  LessonActivityScore toScore(DateTime lessonStartedAt) {
    final endedAt = completedAt ?? DateTime.now();
    return LessonActivityScore(
      activityId: activityId,
      attempts: attempts,
      mistakes: mistakes,
      correctOnFirstTry: attempts == 1 && mistakes == 0 && completed,
      completionTimeMs: endedAt.difference(startedAt).inMilliseconds,
    );
  }
}

String _grade3QuestionTypeFor(LessonQuestion question) {
  final text = '${question.prompt} ${question.directionLabel}'.toLowerCase();
  if (text.contains('who') || text.contains('sin-o')) return 'who';
  if (text.contains('where') || text.contains('diin')) return 'where';
  if (text.contains('when') || text.contains('san-o')) return 'when';
  if (text.contains('why') || text.contains('ngaa')) return 'why';
  if (text.contains('how many') || text.contains('pila')) return 'howMany';
  if (text.contains('how much') || text.contains('bili')) return 'howMuch';
  if (text.contains('predict') || text.contains('matabo')) return 'prediction';
  if (question.type == QuestionType.matching) return 'sequence';
  if (question.type == QuestionType.imageChoice) return 'imageChoice';
  if (question.type == QuestionType.buildSentence ||
      question.type == QuestionType.arrangeWords) {
    return 'tileBuilder';
  }
  return 'what';
}

enum _Grade3FlowStepType {
  intro,
  warmUp,
  review,
  vocabulary,
  storyPage,
  question,
  productive,
  consolidation,
  completion,
}

class _Grade3FlowStep {
  final _Grade3FlowStepType type;
  final int index;

  const _Grade3FlowStep(this.type, [this.index = -1]);
}

class _Grade3StoryPageData {
  final String id;
  final String imagePath;
  final List<String> sentences;

  const _Grade3StoryPageData({
    required this.id,
    required this.imagePath,
    required this.sentences,
  });
}

class _GradeThreeLessonFlow extends StatefulWidget {
  final LevelContent content;
  final List<LessonQuestion> questions;
  final _Grade3QuestionCompleted onQuestionCompleted;
  final VoidCallback onLessonComplete;

  const _GradeThreeLessonFlow({
    required this.content,
    required this.questions,
    required this.onQuestionCompleted,
    required this.onLessonComplete,
  });

  @override
  State<_GradeThreeLessonFlow> createState() => _GradeThreeLessonFlowState();
}

class _GradeThreeLessonFlowState extends State<_GradeThreeLessonFlow> {
  int _stepIndex = 0;
  final Set<int> _completedQuestions = {};
  late final List<_Grade3StoryPageData> _storyPages = _grade3StoryPagesFor(
    widget.content,
  );

  List<_Grade3FlowStep> get _steps {
    final steps = <_Grade3FlowStep>[
      const _Grade3FlowStep(_Grade3FlowStepType.intro),
      const _Grade3FlowStep(_Grade3FlowStepType.warmUp),
      const _Grade3FlowStep(_Grade3FlowStepType.review),
    ];
    if (widget.content.examples.isNotEmpty) {
      steps.add(const _Grade3FlowStep(_Grade3FlowStepType.vocabulary));
    }
    final maxStorySteps = math.max(_storyPages.length, widget.questions.length);
    for (var index = 0; index < maxStorySteps; index++) {
      if (index < _storyPages.length) {
        steps.add(_Grade3FlowStep(_Grade3FlowStepType.storyPage, index));
      }
      if (index < widget.questions.length) {
        steps.add(_Grade3FlowStep(_Grade3FlowStepType.question, index));
      }
    }
    steps.addAll(const [
      _Grade3FlowStep(_Grade3FlowStepType.productive),
      _Grade3FlowStep(_Grade3FlowStepType.consolidation),
      _Grade3FlowStep(_Grade3FlowStepType.completion),
    ]);
    return steps;
  }

  void _next() {
    final maxIndex = _steps.length - 1;
    if (_stepIndex >= maxIndex) return;
    setState(() => _stepIndex++);
  }

  void _previous() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex--);
  }

  void _completeQuestion(
    int index, {
    required bool firstAttemptCorrect,
    required int attemptCount,
    required bool usedAudioSupport,
    required bool usedLookBackSupport,
  }) {
    if (_completedQuestions.add(index)) {
      widget.onQuestionCompleted(
        index,
        firstAttemptCorrect: firstAttemptCorrect,
        attemptCount: attemptCount,
        usedAudioSupport: usedAudioSupport,
        usedLookBackSupport: usedLookBackSupport,
      );
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = steps[_stepIndex.clamp(0, steps.length - 1)];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('${step.type}-${step.index}-$_stepIndex'),
        child: switch (step.type) {
          _Grade3FlowStepType.intro => _Grade3IntroStep(
            content: widget.content,
            onNext: _next,
          ),
          _Grade3FlowStepType.warmUp => _Grade3SimpleActionStep(
            title: 'Balikid Anay',
            message: _grade3WarmUpText(widget.content),
            icon: Icons.history_edu_rounded,
            buttonLabel: 'Padayon',
            onNext: _next,
          ),
          _Grade3FlowStepType.review => _Grade3SimpleActionStep(
            title: 'Review',
            message: 'Pili-a kag pamatii ang isa ka natun-an nga tinaga.',
            icon: Icons.school_rounded,
            buttonLabel: 'Padayon',
            onNext: _next,
          ),
          _Grade3FlowStepType.vocabulary => _Grade3VocabularyStep(
            examples: widget.content.examples,
            onNext: _next,
          ),
          _Grade3FlowStepType.storyPage => _Grade3StoryScreen(
            page: _storyPages[step.index],
            pageNumber: step.index + 1,
            pageCount: _storyPages.length,
            canGoBack: _stepIndex > 0,
            canGoNext: true,
            onBack: _previous,
            onNext: _next,
          ),
          _Grade3FlowStepType.question => _Grade3QuestionScreen(
            question: widget.questions[step.index],
            questionIndex: step.index,
            storyPage: _evidencePageForQuestion(step.index),
            onCompleted: _completeQuestion,
          ),
          _Grade3FlowStepType.productive => _Grade3SimpleActionStep(
            title: 'Himuon Ta',
            message: 'Basaha liwat ang pinakanami nga linya.',
            icon: Icons.record_voice_over_rounded,
            buttonLabel: 'Nahimo Ko',
            onNext: _next,
          ),
          _Grade3FlowStepType.consolidation => _Grade3SimpleActionStep(
            title: 'Pangitaa ang Sabat',
            message: 'Baliki ang sugilanon kag dumduma ang natun-an.',
            icon: Icons.extension_rounded,
            buttonLabel: 'Tapos Na',
            onNext: _next,
          ),
          _Grade3FlowStepType.completion => _Grade3CompletionStep(
            content: widget.content,
            onComplete: widget.onLessonComplete,
          ),
        },
      ),
    );
  }

  _Grade3StoryPageData _evidencePageForQuestion(int questionIndex) {
    if (_storyPages.isEmpty) {
      return _grade3FallbackStoryPage(widget.content, 0);
    }
    return _storyPages[questionIndex.clamp(0, _storyPages.length - 1)];
  }
}

class _Grade3IntroStep extends StatelessWidget {
  final LevelContent content;
  final VoidCallback onNext;

  const _Grade3IntroStep({required this.content, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TudloMascot(size: 150),
          const SizedBox(height: 18),
          Text(
            'Pamati kag Basaha',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _grade3CleanTitle(content.title),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          _Grade3TipBubble(
            text: 'Basaha anay. Pindoton ang speaker kon gusto mo mamati.',
          ),
          const SizedBox(height: 28),
          _Grade3PrimaryButton(label: 'Sugdi', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3SimpleActionStep extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onNext;

  const _Grade3SimpleActionStep({
    required this.title,
    required this.message,
    required this.icon,
    required this.buttonLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: TudloColors.green, size: 96),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(text: message),
          const SizedBox(height: 28),
          _Grade3PrimaryButton(label: buttonLabel, onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3VocabularyStep extends StatelessWidget {
  final List<LessonExample> examples;
  final VoidCallback onNext;

  const _Grade3VocabularyStep({required this.examples, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final visibleExamples = examples
        .where((example) => example.hiligaynon.trim().isNotEmpty)
        .take(4)
        .toList();
    return _Grade3Stage(
      child: Column(
        children: [
          Text(
            'Bag-o nga Tinaga',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          for (final example in visibleExamples) ...[
            _Grade3VocabularyCard(example: example),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          _Grade3PrimaryButton(label: 'Padayon', onTap: onNext),
        ],
      ),
    );
  }
}

class _Grade3VocabularyCard extends StatelessWidget {
  final LessonExample example;

  const _Grade3VocabularyCard({required this.example});

  @override
  Widget build(BuildContext context) {
    final word = _grade3DisplayText(example.hiligaynon);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              word,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          TudloVoiceButton(
            message: word,
            tooltip: 'Pamatii',
            size: 48,
            hiligaynon: true,
          ),
        ],
      ),
    );
  }
}

class _Grade3StoryScreen extends StatelessWidget {
  final _Grade3StoryPageData page;
  final int pageNumber;
  final int pageCount;
  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final int? highlightedSentenceIndex;

  const _Grade3StoryScreen({
    required this.page,
    required this.pageNumber,
    required this.pageCount,
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
    this.highlightedSentenceIndex,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Sugilanon',
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '$pageNumber / $pageCount',
                style: GoogleFonts.nunito(
                  color: TudloColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const _StoryImageFallback(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < page.sentences.length; index++) ...[
            _Grade3SentenceCard(
              sentence: page.sentences[index],
              highlighted: highlightedSentenceIndex == index,
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          _Grade3PageDots(current: pageNumber - 1, count: pageCount),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Grade3SecondaryButton(
                  label: 'Balik',
                  enabled: canGoBack,
                  onTap: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Grade3PrimaryButton(
                  label: canGoNext ? 'Sunod' : 'Tapos',
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grade3SentenceCard extends StatefulWidget {
  final String sentence;
  final bool highlighted;

  const _Grade3SentenceCard({
    required this.sentence,
    required this.highlighted,
  });

  @override
  State<_Grade3SentenceCard> createState() => _Grade3SentenceCardState();
}

class _Grade3SentenceCardState extends State<_Grade3SentenceCard> {
  bool _usedAudio = false;

  Future<void> _speak() async {
    setState(() => _usedAudio = true);
    await TudloVoiceButton.speak(context, widget.sentence, hiligaynon: true);
    if (mounted) setState(() => _usedAudio = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _speak,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: widget.highlighted
              ? const Color(0xFFFFF3A6)
              : Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.highlighted ? TudloColors.gold : TudloColors.ink)
                  .withValues(alpha: widget.highlighted ? .22 : .07),
              blurRadius: widget.highlighted ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.sentence,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: _usedAudio
                  ? const Icon(
                      Icons.graphic_eq_rounded,
                      key: ValueKey(true),
                      color: TudloColors.green,
                      size: 30,
                    )
                  : const TudloSpeakerIcon(key: ValueKey(false), size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grade3QuestionScreen extends StatefulWidget {
  final LessonQuestion question;
  final int questionIndex;
  final _Grade3StoryPageData storyPage;
  final _Grade3QuestionCompleted onCompleted;

  const _Grade3QuestionScreen({
    required this.question,
    required this.questionIndex,
    required this.storyPage,
    required this.onCompleted,
  });

  @override
  State<_Grade3QuestionScreen> createState() => _Grade3QuestionScreenState();
}

class _Grade3QuestionScreenState extends State<_Grade3QuestionScreen> {
  int _attemptCount = 0;
  int _shakeAttempt = 0;
  bool _usedAudioSupport = false;
  bool _usedLookBackSupport = false;
  bool _showLookBack = false;
  bool _correct = false;
  String? _selected;

  List<String> get _choices {
    final choices = widget.question.choices.isNotEmpty
        ? widget.question.choices
        : [widget.question.answer];
    return choices.toSet().toList();
  }

  Future<void> _speakPrompt() async {
    setState(() => _usedAudioSupport = true);
    await TudloVoiceButton.speak(
      context,
      _grade3QuestionPrompt(widget.question),
      hiligaynon: true,
    );
  }

  Future<void> _choose(String choice) async {
    if (_correct || _showLookBack) return;
    _attemptCount++;
    final correct = choice == widget.question.answer;
    setState(() {
      _selected = choice;
      _correct = correct;
      if (!correct) {
        _shakeAttempt++;
        _usedLookBackSupport = true;
        _showLookBack = true;
      }
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Balikan ta ang sugilanon.',
        hiligaynon: true,
      );
      if (!mounted) return;
      await TudloVoiceButton.speak(
        context,
        widget.storyPage.sentences.first,
        hiligaynon: true,
      );
      return;
    }
    await AppAudioService.instance.playCorrect();
    widget.onCompleted(
      widget.questionIndex,
      firstAttemptCorrect: _attemptCount == 1,
      attemptCount: _attemptCount,
      usedAudioSupport: _usedAudioSupport,
      usedLookBackSupport: _usedLookBackSupport,
    );
  }

  Future<void> _retry() async {
    setState(() {
      _showLookBack = false;
      _selected = null;
    });
    await TudloVoiceButton.speak(
      context,
      'Liwata. Pangitaa ang sabat sa sugilanon.',
      hiligaynon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLookBack) {
      return Column(
        children: [
          Expanded(
            child: _Grade3StoryScreen(
              page: widget.storyPage,
              pageNumber: 1,
              pageCount: 1,
              canGoBack: false,
              canGoNext: true,
              onBack: () {},
              onNext: _retry,
              highlightedSentenceIndex: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _Grade3TipBubble(
              text: 'Liwata. Pangitaa ang sabat sa sugilanon.',
            ),
          ),
        ],
      );
    }

    return _Grade3Stage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pamangkot',
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Pamatii',
                onPressed: _speakPrompt,
                style: IconButton.styleFrom(
                  backgroundColor: TudloColors.softGreen,
                  foregroundColor: TudloColors.green,
                ),
                icon: const TudloSpeakerIcon(size: 26),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(text: _grade3QuestionPrompt(widget.question)),
          const SizedBox(height: 20),
          for (final choice in _choices) ...[
            _Grade3AnswerCard(
              label: _grade3ChoiceLabel(choice),
              selected: _selected == choice,
              correct: _correct && _selected == choice,
              shakeKey: _selected == choice ? _shakeAttempt : 0,
              onTap: () => _choose(choice),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          _Grade3TipBubble(text: 'Kon indi sigurado, baliki ang sugilanon.'),
        ],
      ),
    );
  }
}

class _Grade3AnswerCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final int shakeKey;
  final VoidCallback onTap;

  const _Grade3AnswerCard({
    required this.label,
    required this.selected,
    required this.correct,
    required this.shakeKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('g3-$label-$shakeKey'),
      correct: correct,
      wrong: shakeKey > 0 && !correct,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: correct
                ? TudloColors.green
                : selected
                ? TudloColors.gold
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: correct || selected ? Colors.white : TudloColors.ink,
              fontSize: 23,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _Grade3CompletionStep extends StatelessWidget {
  final LevelContent content;
  final VoidCallback onComplete;

  const _Grade3CompletionStep({
    required this.content,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return _Grade3Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TudloMascot(size: 150),
          const SizedBox(height: 16),
          Text(
            'Maayo Gid!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _Grade3TipBubble(
            text:
                'Na-unlock ang libro: ${_grade3CleanTitle(content.storyTitle ?? content.title)}.',
          ),
          const SizedBox(height: 26),
          _Grade3PrimaryButton(label: 'Kuh-a ang Ganti', onTap: onComplete),
        ],
      ),
    );
  }
}

class _Grade3Stage extends StatelessWidget {
  final Widget child;

  const _Grade3Stage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 22),
                ),
                child: IntrinsicHeight(child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Grade3TipBubble extends StatelessWidget {
  final String text;

  const _Grade3TipBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.questionBubble,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 54, 22),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 21,
                height: 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grade3PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Grade3PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: TudloColors.green,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: TudloColors.forest.withValues(alpha: .22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Grade3SecondaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _Grade3SecondaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: TudloColors.green,
          side: const BorderSide(color: TudloColors.green, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Grade3PageDots extends StatelessWidget {
  final int current;
  final int count;

  const _Grade3PageDots({required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: current == index ? 24 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: current == index ? TudloColors.green : TudloColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

List<_Grade3StoryPageData> _grade3StoryPagesFor(LevelContent content) {
  final imagePath = content.storyImageAsset?.trim().isNotEmpty == true
      ? content.storyImageAsset!.trim()
      : _storyImagePathForActiveGrade();
  final sentences = _grade3SentencesFor(content);
  final pages = <_Grade3StoryPageData>[];
  for (var index = 0; index < sentences.length; index += 2) {
    pages.add(
      _Grade3StoryPageData(
        id: '${content.id}-page-${pages.length + 1}',
        imagePath: imagePath,
        sentences: sentences.skip(index).take(2).toList(),
      ),
    );
  }
  return pages.isEmpty ? [_grade3FallbackStoryPage(content, 0)] : pages;
}

_Grade3StoryPageData _grade3FallbackStoryPage(LevelContent content, int index) {
  return _Grade3StoryPageData(
    id: '${content.id}-fallback-$index',
    imagePath: content.storyImageAsset?.trim().isNotEmpty == true
        ? content.storyImageAsset!.trim()
        : _storyImagePathForActiveGrade(),
    sentences: [_grade3CleanTitle(content.title)],
  );
}

List<String> _grade3SentencesFor(LevelContent content) {
  final source = [
    content.story,
    content.lesson,
    for (final example in content.examples) example.hiligaynon,
  ].whereType<String>().join(' ');
  final quoted = RegExp(r'"([^"]+)"')
      .allMatches(source)
      .map((match) => _grade3DisplayText(match.group(1) ?? ''))
      .where((value) => value.isNotEmpty)
      .toList();
  final rawSentences = quoted.length >= 4
      ? quoted
      : RegExp(r'[^.!?\n]+[.!?]?')
            .allMatches(source)
            .map((match) => _grade3DisplayText(match.group(0) ?? ''))
            .where((value) => value.isNotEmpty)
            .toList();
  final cleaned = rawSentences
      .map(_grade3ShortenSentence)
      .where((value) => value.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return [_grade3CleanTitle(content.title)];
  return cleaned.take(8).toList();
}

String _grade3ShortenSentence(String value) {
  final cleaned = _grade3DisplayText(value)
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'^(Presentation|Warm-up|Productive):\s*'), '')
      .trim();
  final words = cleaned.split(RegExp(r'\s+'));
  if (words.length <= 9) return cleaned;
  return '${words.take(9).join(' ')}.';
}

String _grade3CleanTitle(String value) {
  return _grade3DisplayText(value)
      .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
      .replaceAll(
        RegExp(r'\b(New|Presentation|Productive)\b:?', caseSensitive: false),
        '',
      )
      .trim();
}

String _grade3DisplayText(String value) {
  return value
      .replaceAll('â€œ', '"')
      .replaceAll('â€', '"')
      .replaceAll('â€“', '-')
      .replaceAll('â€”', '-')
      .replaceAll('Â·', '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _grade3WarmUpText(LevelContent content) {
  if (content.unitNumber == 1 && content.lessonNumber == 1) {
    return 'Dumduma ang numero isa tubtob napulo.';
  }
  return 'Dumduma ang natun-an sa nagligad nga leksiyon.';
}

String _grade3QuestionPrompt(LessonQuestion question) {
  final prompt = _grade3DisplayText(question.prompt);
  final quoted = RegExp(r'"([^"]+)"').firstMatch(prompt)?.group(1);
  final text = quoted ?? prompt;
  if (text.toLowerCase().contains('how many')) {
    return text.replaceAll(RegExp('how many', caseSensitive: false), 'Pila');
  }
  if (text.toLowerCase().contains('how much')) {
    return text.replaceAll(
      RegExp('how much', caseSensitive: false),
      'Pila ang bili sang',
    );
  }
  if (text.toLowerCase().startsWith('reverse')) {
    return 'Pamatii kag pili-a ang husto.';
  }
  return text;
}

String _grade3ChoiceLabel(String choice) {
  final cleaned = _grade3DisplayText(choice);
  final number = RegExp(r'\b([0-9]{1,2})\b').firstMatch(cleaned)?.group(1);
  if (number != null) return number;
  return cleaned
      .replaceAll(
        RegExp(r'^(tap|count, tap|tap the)\s+', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s+-\s+.*$'), '')
      .trim();
}

class _GradeTwoTalkBuildSolveLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeTwoTalkBuildSolveLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeTwoTalkBuildSolveLesson> createState() =>
      _GradeTwoTalkBuildSolveLessonState();
}

class _GradeTwoTalkBuildSolveLessonState
    extends State<_GradeTwoTalkBuildSolveLesson> {
  late final _GradeTwoPlan _plan = _gradeTwoPlanFor(widget.content);
  int _step = 0;
  int _reported = 0;
  bool _finished = false;

  void _advance() {
    _reportOne();
    if (!mounted) return;
    if (_step >= 2) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _reportOne() {
    if (_reported >= _lessonQuizCount) return;
    widget.onQuizCorrect(_reported);
    _reported++;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    while (_reported < _lessonQuizCount) {
      widget.onQuizCorrect(_reported);
      _reported++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      widget.content.unitNumber == 1 && widget.content.lessonNumber == 2
          ? _GradeTwoBirthdayCandleCard(plan: _plan, onDone: _advance)
          : _GradeTwoSceneCard(plan: _plan, onDone: _advance),
      _GradeTwoSentenceBuilderCard(plan: _plan, onDone: _advance),
      _GradeTwoDialogueChoiceCard(plan: _plan, onDone: _advance),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_step), child: cards[_step]),
    );
  }
}

class _GradeTwoPlan {
  final String sceneTitle;
  final String sceneLine;
  final String tapInstruction;
  final String phrase;
  final String phraseSpeech;
  final String buildPrompt;
  final String buildQuestion;
  final String? buildCharacterAsset;
  final String buildAnswer;
  final List<String> buildTiles;
  final String choicePrompt;
  final List<String> choices;
  final String answer;
  final String missionTitle;
  final String missionPrompt;
  final List<_GradeTwoMissionChoice> missionChoices;
  final String missionAnswer;
  final String reward;
  final String? imageAsset;
  final IconData icon;
  final Color color;

  const _GradeTwoPlan({
    required this.sceneTitle,
    required this.sceneLine,
    required this.tapInstruction,
    required this.phrase,
    required this.phraseSpeech,
    required this.buildPrompt,
    required this.buildQuestion,
    this.buildCharacterAsset,
    required this.buildAnswer,
    required this.buildTiles,
    required this.choicePrompt,
    required this.choices,
    required this.answer,
    required this.missionTitle,
    required this.missionPrompt,
    required this.missionChoices,
    required this.missionAnswer,
    required this.reward,
    this.imageAsset,
    required this.icon,
    required this.color,
  });
}

class _GradeTwoMissionChoice {
  final String label;
  final String? visualLabel;
  final String? imageAsset;
  final bool isKoka;
  final IconData icon;

  const _GradeTwoMissionChoice({
    required this.label,
    this.visualLabel,
    this.imageAsset,
    this.isKoka = false,
    required this.icon,
  });
}

class _GradeTwoTileVisual {
  final String label;
  final String? imageAsset;
  final bool isKoka;
  final IconData icon;
  final Color color;

  const _GradeTwoTileVisual({
    required this.label,
    this.imageAsset,
    this.isKoka = false,
    required this.icon,
    required this.color,
  });
}

class _GradeTwoSceneCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoSceneCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoSceneCard> createState() => _GradeTwoSceneCardState();
}

class _GradeTwoSceneCardState extends State<_GradeTwoSceneCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.plan.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapScene() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(context, widget.plan.phraseSpeech);
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GradeTwoStage(
      mascotMessage: _tapped
          ? 'Koka: ${widget.plan.phrase}'
          : 'Koka: ${widget.plan.tapInstruction}',
      child: Column(
        children: [
          Text(
            widget.plan.sceneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tapScene,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _GradeTwoArt(plan: widget.plan, size: 270),
                  if (_tapped) const _AnimalSparkles(size: 300),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _GradeTwoSpeechBubble(text: widget.plan.phrase, onTap: _tapScene),
        ],
      ),
    );
  }
}

class _GradeTwoBirthdayCandleCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoBirthdayCandleCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoBirthdayCandleCard> createState() =>
      _GradeTwoBirthdayCandleCardState();
}

class _GradeTwoBirthdayCandleCardState
    extends State<_GradeTwoBirthdayCandleCard> {
  int _candles = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang pito ka kandila pakadto sa cake.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _addCandle() async {
    if (_done) return;
    setState(() => _candles = (_candles + 1).clamp(0, 7));
    if (_candles < 7) return;
    _done = true;
    await TudloVoiceButton.speak(
      context,
      'Husto! Pito ka kandila.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GradeTwoStage(
      mascotMessage: 'Koka: Guyoda ang pito ka kandila pakadto sa cake.',
      child: Column(
        children: [
          Text(
            widget.plan.sceneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          _GradeTwoSpeechBubble(text: 'Pito ka kandila'),
          const SizedBox(height: 12),
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !_done,
            onAcceptWithDetails: (_) => _addCandle(),
            builder: (context, candidates, rejected) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: candidates.isNotEmpty ? 1.04 : 1,
                child: SizedBox(
                  width: 320,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/level_game/cake.png',
                        width: 280,
                        height: 220,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      Positioned(
                        top: 26,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            for (var index = 0; index < _candles; index++)
                              Image.asset(
                                'assets/images/level_game/candle.png',
                                width: 28,
                                height: 54,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.local_fire_department_rounded,
                                  color: TudloColors.coral,
                                  size: 32,
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
          ),
          const SizedBox(height: 12),
          Text(
            '$_candles / 7',
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          if (!_done)
            Draggable<String>(
              data: 'candle',
              feedback: Material(
                color: Colors.transparent,
                child: Image.asset(
                  'assets/images/level_game/candle.png',
                  width: 52,
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: .35,
                child: _CandleButton(color: widget.plan.color),
              ),
              child: _CandleButton(color: widget.plan.color),
            ),
        ],
      ),
    );
  }
}

class _CandleButton extends StatelessWidget {
  final Color color;

  const _CandleButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/level_game/candle.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.local_fire_department_rounded, color: color, size: 52),
      ),
    );
  }
}

class _GradeTwoSentenceBuilderCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoSentenceBuilderCard({
    required this.plan,
    required this.onDone,
  });

  @override
  State<_GradeTwoSentenceBuilderCard> createState() =>
      _GradeTwoSentenceBuilderCardState();
}

class _GradeTwoSentenceBuilderCardState
    extends State<_GradeTwoSentenceBuilderCard> {
  final List<String> _built = [];
  bool _done = false;

  Future<void> _addTile(String tile) async {
    if (_done || _built.contains(tile)) return;
    await TudloVoiceButton.speak(
      context,
      _gradeTwoTileVisualFor(tile).label,
      hiligaynon: true,
    );
    if (!mounted) return;
    setState(() => _built.add(tile));
    if (_normalizedSentence(_built.join(' ')) ==
        _normalizedSentence(widget.plan.buildAnswer)) {
      _done = true;
      await TudloVoiceButton.speak(
        context,
        widget.plan.phraseSpeech,
        hiligaynon: true,
      );
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.plan.buildTiles
        .where((tile) => !_built.contains(tile))
        .toList();
    final focus = _gradeTwoBuildFocusFor(widget.plan);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              Text(
                widget.plan.buildPrompt,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              _GradeTwoQuestionCharacter(
                question: widget.plan.buildQuestion,
                imageAsset: widget.plan.buildCharacterAsset,
                color: widget.plan.color,
              ),
              if (focus != null) ...[
                const SizedBox(height: 10),
                _GradeTwoFocusPicture(visual: focus, color: widget.plan.color),
              ],
              const SizedBox(height: 16),
              _GradeTwoBuildTray(
                words: _built,
                target: widget.plan.buildAnswer,
                color: widget.plan.color,
                onRemove: (index) {
                  if (_done) return;
                  setState(() => _built.removeAt(index));
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in remaining)
                    _GradeTwoTile(
                      label: tile,
                      color: widget.plan.color,
                      onTap: () => _addTile(tile),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoDialogueChoiceCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoDialogueChoiceCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoDialogueChoiceCard> createState() =>
      _GradeTwoDialogueChoiceCardState();
}

class _GradeTwoDialogueChoiceCardState
    extends State<_GradeTwoDialogueChoiceCard> {
  String? _selected;
  int _attempt = 0;

  Future<void> _choose(String choice) async {
    if (_selected == widget.plan.answer) return;
    await TudloVoiceButton.speak(context, choice, hiligaynon: true);
    if (!mounted) return;
    final correct = choice == widget.plan.answer;
    setState(() {
      _selected = choice;
      _attempt++;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pili-a ang husto nga sabat.',
        hiligaynon: true,
      );
      return;
    }
    unawaited(AppAudioService.instance.playCorrect());
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              _GradeTwoSpeechBubble(text: widget.plan.choicePrompt),
              const SizedBox(height: 18),
              _GradeTwoAnswerBubble(text: _selected ?? ''),
              const SizedBox(height: 8),
              const TudloMascot(size: 190),
              const SizedBox(height: 16),
              for (final choice in widget.plan.choices) ...[
                _GradeTwoChoiceButton(
                  key: ValueKey('$choice-$_attempt'),
                  label: choice,
                  selected: _selected == choice,
                  correct: choice == widget.plan.answer,
                  checked: _selected == choice,
                  color: widget.plan.color,
                  onTap: () => _choose(choice),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionCard extends StatefulWidget {
  final _GradeTwoPlan plan;
  final VoidCallback onDone;

  const _GradeTwoMissionCard({required this.plan, required this.onDone});

  @override
  State<_GradeTwoMissionCard> createState() => _GradeTwoMissionCardState();
}

class _GradeTwoMissionCardState extends State<_GradeTwoMissionCard> {
  String? _selected;
  int _attempt = 0;

  Future<void> _choose(_GradeTwoMissionChoice choice) async {
    if (_selected == widget.plan.missionAnswer) return;
    await TudloVoiceButton.speak(context, choice.label);
    if (!mounted) return;
    final correct = choice.label == widget.plan.missionAnswer;
    setState(() {
      _selected = choice.label;
      _attempt++;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Liwata. Tan-awa liwat ang sitwasyon.',
        hiligaynon: true,
      );
      return;
    }
    unawaited(AppAudioService.instance.playCorrect());
    await TudloVoiceButton.speak(
      context,
      'Husto! ${widget.plan.reward}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            children: [
              const TudloMascot(size: 148),
              const SizedBox(height: 12),
              _GradeTwoSpeechBubble(text: widget.plan.missionPrompt),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final choice in widget.plan.missionChoices)
                    _GradeTwoMissionOption(
                      key: ValueKey('${choice.label}-$_attempt'),
                      choice: choice,
                      color: widget.plan.color,
                      selected: _selected == choice.label,
                      correct: choice.label == widget.plan.missionAnswer,
                      checked: _selected == choice.label,
                      onTap: () => _choose(choice),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _GradeTwoStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 260),
                    child: child,
                  ),
                ),
                Positioned(
                  right: -22,
                  bottom: -18,
                  child: IgnorePointer(
                    child: _AlphabetMascotBubble(message: mascotMessage),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GradeTwoArt extends StatelessWidget {
  final _GradeTwoPlan plan;
  final double size;

  const _GradeTwoArt({required this.plan, required this.size});

  @override
  Widget build(BuildContext context) {
    if (plan.imageAsset != null) {
      return Image.asset(
        plan.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _GradeTwoIconArt(plan: plan, size: size),
      );
    }
    return _GradeTwoIconArt(plan: plan, size: size);
  }
}

class _GradeTwoIconArt extends StatelessWidget {
  final _GradeTwoPlan plan;
  final double size;

  const _GradeTwoIconArt({required this.plan, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: plan.color.withValues(alpha: .16),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: .16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(plan.icon, color: plan.color, size: size * .54),
    );
  }
}

class _GradeTwoSpeechBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _GradeTwoSpeechBubble({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 86),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              TudloDialogueAssets.speechBubble,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 25,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return bubble;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: bubble,
      ),
    );
  }
}

class _GradeTwoAnswerBubble extends StatelessWidget {
  final String text;

  const _GradeTwoAnswerBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: hasText
            ? TudloColors.softGreen
            : Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: hasText ? .20 : .10),
            blurRadius: hasText ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            hasText ? text : ' ',
            key: ValueKey(text),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: hasText ? TudloColors.ink : TudloColors.muted,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeTwoQuestionCharacter extends StatelessWidget {
  final String question;
  final String? imageAsset;
  final Color color;

  const _GradeTwoQuestionCharacter({
    required this.question,
    required this.imageAsset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 142,
          height: 178,
          child: imageAsset == null
              ? Icon(Icons.face_rounded, color: color, size: 112)
              : Image.asset(
                  imageAsset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.face_rounded, color: color, size: 112),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _GradeTwoSpeechBubble(text: question)),
      ],
    );
  }
}

class _GradeTwoFocusPicture extends StatelessWidget {
  final _GradeTwoTileVisual visual;
  final Color color;

  const _GradeTwoFocusPicture({required this.visual, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      height: 194,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (visual.isKoka)
            const TudloMascot(size: 132, mood: KokaMood.curious)
          else if (visual.imageAsset != null)
            Image.asset(
              visual.imageAsset!,
              width: 166,
              height: 126,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Icon(visual.icon, color: color, size: 96),
            )
          else
            Icon(visual.icon, color: visual.color, size: 80),
          const SizedBox(height: 6),
          Text(
            visual.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeTwoBuildTray extends StatelessWidget {
  final List<String> words;
  final String target;
  final Color color;
  final ValueChanged<int> onRemove;

  const _GradeTwoBuildTray({
    required this.words,
    required this.target,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final complete =
        _normalizedSentence(words.join(' ')) == _normalizedSentence(target);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: complete
            ? TudloColors.softGreen.withValues(alpha: .90)
            : Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: words.isEmpty
          ? Center(
              child: Text(
                'Ibutang diri ang imo sabat',
                style: GoogleFonts.nunito(
                  color: TudloColors.muted,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < words.length; index++)
                  _GradeTwoBuiltWord(
                    label: words[index],
                    color: color,
                    onTap: () => onRemove(index),
                  ),
              ],
            ),
    );
  }
}

class _GradeTwoTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _gradeTwoTileVisualFor(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: visual.imageAsset == null ? 144 : 138,
          height: visual.imageAsset == null ? 76 : 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .28),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (visual.isKoka) ...[
                const TudloMascot(size: 82, mood: KokaMood.curious),
                const SizedBox(height: 6),
              ] else if (visual.imageAsset != null) ...[
                Image.asset(
                  visual.imageAsset!,
                  width: 72,
                  height: 82,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(visual.icon, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 6),
              ] else if (visual.icon != Icons.text_fields_rounded) ...[
                Icon(visual.icon, color: Colors.white, size: 38),
                const SizedBox(height: 4),
              ],
              FittedBox(
                child: Text(
                  visual.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoBuiltWord extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoBuiltWord({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _gradeTwoTileVisualFor(label);
    return ActionChip(
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: .16),
      side: BorderSide.none,
      label: Text(
        visual.label,
        style: GoogleFonts.nunito(
          color: TudloColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GradeTwoChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool checked;
  final Color color;
  final VoidCallback onTap;

  const _GradeTwoChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.correct,
    required this.checked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = checked && !correct;
    final visual = _gradeTwoTileVisualFor(label);
    final hasArt =
        visual.isKoka ||
        visual.imageAsset != null ||
        visual.icon != Icons.text_fields_rounded;
    final activeColor = wrong
        ? const Color(0xFFE53935)
        : checked && correct
        ? TudloColors.green
        : color;
    return _FeedbackMotion(
      correct: checked && correct,
      wrong: wrong,
      child: SizedBox(
        width: double.infinity,
        height: hasArt ? 102 : 76,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            elevation: selected ? 8 : 4,
            shadowColor: activeColor.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.nunito(
              fontSize: 23,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          child: hasArt
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visual.isKoka)
                      const TudloMascot(size: 58, mood: KokaMood.curious)
                    else if (visual.imageAsset != null)
                      Image.asset(
                        visual.imageAsset!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) =>
                            Icon(visual.icon, color: Colors.white, size: 44),
                      )
                    else
                      Icon(visual.icon, color: Colors.white, size: 42),
                    const SizedBox(width: 14),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(visual.label, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                )
              : FittedBox(
                  child: Text(visual.label, textAlign: TextAlign.center),
                ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionOption extends StatelessWidget {
  final _GradeTwoMissionChoice choice;
  final Color color;
  final bool selected;
  final bool correct;
  final bool checked;
  final VoidCallback onTap;

  const _GradeTwoMissionOption({
    super.key,
    required this.choice,
    required this.color,
    required this.selected,
    required this.correct,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = checked && !correct;
    return _FeedbackMotion(
      correct: checked && correct,
      wrong: wrong,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 168,
          height: 194,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: wrong
                ? const Color(0xFFFFE7E7)
                : checked && correct
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (selected ? color : TudloColors.forest).withValues(
                  alpha: selected ? .22 : .10,
                ),
                blurRadius: selected ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GradeTwoMissionArt(choice: choice, color: color, size: 112),
              const SizedBox(height: 12),
              Text(
                choice.visualLabel ?? choice.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: wrong ? const Color(0xFFE53935) : TudloColors.ink,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTwoMissionArt extends StatelessWidget {
  final _GradeTwoMissionChoice choice;
  final Color color;
  final double size;

  const _GradeTwoMissionArt({
    required this.choice,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (choice.isKoka) {
      return TudloMascot(size: size, mood: KokaMood.curious);
    }
    if (choice.imageAsset != null) {
      return Image.asset(
        choice.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(choice.icon, color: color, size: size * .72),
      );
    }
    return Icon(choice.icon, color: color, size: size * .72);
  }
}

String _normalizedSentence(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[.!?"]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

_GradeTwoTileVisual? _gradeTwoBuildFocusFor(_GradeTwoPlan plan) {
  for (final tile in plan.buildTiles) {
    final visual = _gradeTwoTileVisualFor(tile);
    if ((visual.isKoka || visual.imageAsset != null) &&
        plan.buildAnswer.contains(tile)) {
      return visual;
    }
  }
  for (final tile in plan.buildTiles) {
    final visual = _gradeTwoTileVisualFor(tile);
    if (visual.icon != Icons.text_fields_rounded &&
        plan.buildAnswer.contains(tile)) {
      return visual;
    }
  }
  return null;
}

_GradeTwoTileVisual _gradeTwoTileVisualFor(String value) {
  const grade2 = 'assets/images/level_game';
  final key = value.trim().toLowerCase();
  return switch (key) {
    'my name is' => const _GradeTwoTileVisual(
      label: 'Ako si',
      icon: Icons.badge_rounded,
      color: TudloColors.green,
    ),
    'koka' => const _GradeTwoTileVisual(
      label: 'Koka',
      isKoka: true,
      icon: Icons.face_rounded,
      color: TudloColors.green,
    ),
    'hello' => const _GradeTwoTileVisual(
      label: 'Kumusta',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'kumusta' || 'kumusta!' => const _GradeTwoTileVisual(
      label: 'Kumusta',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'paalam' || 'paalam!' => const _GradeTwoTileVisual(
      label: 'Paalam',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.blue,
    ),
    'goodbye' || 'goodbye!' => const _GradeTwoTileVisual(
      label: 'Paalam',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.blue,
    ),
    'koka ang ngalan ko' || 'koka ang ngalan ko.' => const _GradeTwoTileVisual(
      label: 'Koka ang ngalan ko',
      isKoka: true,
      icon: Icons.face_rounded,
      color: TudloColors.green,
    ),
    'i am' => const _GradeTwoTileVisual(
      label: 'Ako',
      icon: Icons.person_rounded,
      color: TudloColors.green,
    ),
    'seven' => const _GradeTwoTileVisual(
      label: 'pito',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'six' => const _GradeTwoTileVisual(
      label: 'anum',
      icon: Icons.looks_6_rounded,
      color: TudloColors.orange,
    ),
    'years old' => const _GradeTwoTileVisual(
      label: 'ka tuig',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'pito ka tuig ako' || 'pito ka tuig ako.' => const _GradeTwoTileVisual(
      label: 'Pito ka tuig ako',
      imageAsset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    'this is my' => const _GradeTwoTileVisual(
      label: 'Amo ini',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'this is a' => const _GradeTwoTileVisual(
      label: 'Ini ang',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'it is a' => const _GradeTwoTileVisual(
      label: 'Ini ang',
      icon: Icons.text_fields_rounded,
      color: TudloColors.blue,
    ),
    'touch your' => const _GradeTwoTileVisual(
      label: 'Tanduga ang',
      icon: Icons.touch_app_rounded,
      color: TudloColors.coral,
    ),
    'mother' => const _GradeTwoTileVisual(
      label: 'nanay',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'nanay' => const _GradeTwoTileVisual(
      label: 'nanay',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'father' => const _GradeTwoTileVisual(
      label: 'tatay',
      imageAsset: 'assets/images/level_game/people/tatay.png',
      icon: Icons.man_rounded,
      color: TudloColors.green,
    ),
    'tatay' => const _GradeTwoTileVisual(
      label: 'tatay',
      imageAsset: 'assets/images/level_game/people/tatay.png',
      icon: Icons.man_rounded,
      color: TudloColors.green,
    ),
    'amo ini ang akon nanay' ||
    'amo ini ang akon nanay.' => const _GradeTwoTileVisual(
      label: 'Amo ini ang akon nanay',
      imageAsset: 'assets/images/level_game/people/nanay.png',
      icon: Icons.woman_rounded,
      color: TudloColors.blue,
    ),
    'book' => const _GradeTwoTileVisual(
      label: 'libro',
      imageAsset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
    ),
    'libro' => const _GradeTwoTileVisual(
      label: 'libro',
      imageAsset: '$grade2/book.png',
      icon: Icons.menu_book_rounded,
      color: TudloColors.green,
    ),
    'pencil' => const _GradeTwoTileVisual(
      label: 'lapis',
      imageAsset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
    ),
    'lapis' => const _GradeTwoTileVisual(
      label: 'lapis',
      imageAsset: '$grade2/pencil.png',
      icon: Icons.edit_rounded,
      color: TudloColors.gold,
    ),
    'bag' => const _GradeTwoTileVisual(
      label: 'bag',
      imageAsset: '$grade2/bag.png',
      icon: Icons.backpack_rounded,
      color: TudloColors.coral,
    ),
    'chair' => const _GradeTwoTileVisual(
      label: 'pulungkuan',
      imageAsset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
    ),
    'pulungkuan' => const _GradeTwoTileVisual(
      label: 'pulungkuan',
      imageAsset: '$grade2/chair.png',
      icon: Icons.chair_rounded,
      color: TudloColors.blue,
    ),
    'plate' => const _GradeTwoTileVisual(
      label: 'plato',
      imageAsset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
    ),
    'plato' => const _GradeTwoTileVisual(
      label: 'plato',
      imageAsset: '$grade2/plate.png',
      icon: Icons.dinner_dining_rounded,
      color: TudloColors.coral,
    ),
    'glass' => const _GradeTwoTileVisual(
      label: 'baso',
      imageAsset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
    ),
    'baso' => const _GradeTwoTileVisual(
      label: 'baso',
      imageAsset: '$grade2/glass.png',
      icon: Icons.local_drink_rounded,
      color: TudloColors.blue,
    ),
    'spoon' => const _GradeTwoTileVisual(
      label: 'kutsara',
      imageAsset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
    ),
    'kutsara' => const _GradeTwoTileVisual(
      label: 'kutsara',
      imageAsset: '$grade2/spoon.png',
      icon: Icons.restaurant_rounded,
      color: TudloColors.orange,
    ),
    'tree' => const _GradeTwoTileVisual(
      label: 'kahoy',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    'kahoy' => const _GradeTwoTileVisual(
      label: 'kahoy',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    'flower' => const _GradeTwoTileVisual(
      label: 'bulak',
      icon: Icons.local_florist_rounded,
      color: TudloColors.coral,
    ),
    'bulak' => const _GradeTwoTileVisual(
      label: 'bulak',
      icon: Icons.local_florist_rounded,
      color: TudloColors.coral,
    ),
    'rock' => const _GradeTwoTileVisual(
      label: 'bato',
      icon: Icons.landscape_rounded,
      color: TudloColors.muted,
    ),
    'good' => const _GradeTwoTileVisual(
      label: 'maayo',
      icon: Icons.thumb_up_rounded,
      color: TudloColors.green,
    ),
    'maayo man, salamat' || 'maayo man, salamat.' => const _GradeTwoTileVisual(
      label: 'Maayo man, salamat',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    "i'm fine" => const _GradeTwoTileVisual(
      label: 'Maayo man',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    'thank' => const _GradeTwoTileVisual(
      label: 'sala',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'you' => const _GradeTwoTileVisual(
      label: 'mat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'thank you' => const _GradeTwoTileVisual(
      label: 'Salamat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'salamat' || 'salamat.' => const _GradeTwoTileVisual(
      label: 'Salamat',
      icon: Icons.favorite_rounded,
      color: TudloColors.coral,
    ),
    'please' => const _GradeTwoTileVisual(
      label: 'Palihog',
      icon: Icons.volunteer_activism_rounded,
      color: TudloColors.green,
    ),
    'sorry' => const _GradeTwoTileVisual(
      label: 'Pasensya',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: TudloColors.orange,
    ),
    'morning' => const _GradeTwoTileVisual(
      label: 'aga',
      imageAsset: 'assets/images/level_game/sunrise.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'maayong aga' || 'maayong aga!' => const _GradeTwoTileVisual(
      label: 'Maayong aga',
      imageAsset: 'assets/images/level_game/sunrise.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'good morning' => const _GradeTwoTileVisual(
      label: 'Maayong aga',
      imageAsset: 'assets/images/level_game/sunrise.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'evening' => const _GradeTwoTileVisual(
      label: 'gab-i',
      imageAsset: 'assets/images/level_game/moon.png',
      icon: Icons.dark_mode_rounded,
      color: TudloColors.blue,
    ),
    'maayong gab-i' || 'maayong gab-i!' => const _GradeTwoTileVisual(
      label: 'Maayong gab-i',
      imageAsset: 'assets/images/level_game/moon.png',
      icon: Icons.dark_mode_rounded,
      color: TudloColors.blue,
    ),
    'head' || 'ulo' => const _GradeTwoTileVisual(
      label: 'ulo',
      icon: Icons.face_rounded,
      color: TudloColors.coral,
    ),
    'feet' || 'tiil' => const _GradeTwoTileVisual(
      label: 'tiil',
      icon: Icons.directions_walk_rounded,
      color: TudloColors.green,
    ),
    'eyes' || 'mata' => const _GradeTwoTileVisual(
      label: 'mata',
      icon: Icons.visibility_rounded,
      color: TudloColors.blue,
    ),
    'dog' || 'ido' => const _GradeTwoTileVisual(
      label: 'ido',
      imageAsset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.pets_rounded,
      color: TudloColors.orange,
    ),
    'cat' || 'kuring' => const _GradeTwoTileVisual(
      label: 'kuring',
      imageAsset: 'assets/images/level_game/animals/cat.png',
      icon: Icons.pets_rounded,
      color: TudloColors.blue,
    ),
    'pig' || 'baboy' => const _GradeTwoTileVisual(
      label: 'baboy',
      imageAsset: 'assets/images/level_game/animals/pig.png',
      icon: Icons.pets_rounded,
      color: TudloColors.coral,
    ),
    'mat' || 'banig' => const _GradeTwoTileVisual(
      label: 'banig',
      icon: Icons.crop_square_rounded,
      color: TudloColors.green,
    ),
    'fish' || 'isda' => const _GradeTwoTileVisual(
      label: 'isda',
      imageAsset: 'assets/images/level_game/animals/fish.png',
      icon: Icons.water_rounded,
      color: TudloColors.blue,
    ),
    'sun' || 'adlaw' => const _GradeTwoTileVisual(
      label: 'adlaw',
      imageAsset: 'assets/images/level_game/sun.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    'jump' || 'lumpat' => const _GradeTwoTileVisual(
      label: 'lumpat',
      icon: Icons.keyboard_arrow_up_rounded,
      color: TudloColors.coral,
    ),
    'wave' || 'paypay' => const _GradeTwoTileVisual(
      label: 'paypay',
      icon: Icons.waving_hand_rounded,
      color: TudloColors.gold,
    ),
    'turn' || 'liko' => const _GradeTwoTileVisual(
      label: 'liko',
      icon: Icons.rotate_right_rounded,
      color: TudloColors.blue,
    ),
    'happy' || 'malipayon' => const _GradeTwoTileVisual(
      label: 'malipayon',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    'to my' => const _GradeTwoTileVisual(
      label: 'sa akon',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'my' => const _GradeTwoTileVisual(
      label: 'akon',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'sits' => const _GradeTwoTileVisual(
      label: 'nagapungko',
      icon: Icons.event_seat_rounded,
      color: TudloColors.blue,
    ),
    'i can' => const _GradeTwoTileVisual(
      label: 'Maka',
      icon: Icons.directions_run_rounded,
      color: TudloColors.coral,
    ),
    'is' => const _GradeTwoTileVisual(
      label: 'nga',
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
    'merkado' => const _GradeTwoTileVisual(
      label: 'merkado',
      imageAsset: 'assets/images/level_game/tinda.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
    ),
    _ => _GradeTwoTileVisual(
      label: value,
      icon: Icons.text_fields_rounded,
      color: TudloColors.green,
    ),
  };
}

_GradeTwoPlan _gradeTwoPlanFor(LevelContent content) {
  const grade2 = 'assets/images/level_game';

  _GradeTwoPlan plan({
    required String sceneTitle,
    required String sceneLine,
    required String tapInstruction,
    required String phrase,
    required String phraseSpeech,
    required String buildPrompt,
    required String buildQuestion,
    String? buildCharacterAsset,
    required String buildAnswer,
    required List<String> buildTiles,
    required String choicePrompt,
    required List<String> choices,
    required String answer,
    required String missionTitle,
    required String missionPrompt,
    required List<_GradeTwoMissionChoice> missionChoices,
    required String missionAnswer,
    required String reward,
    String? imageAsset,
    required IconData icon,
    required Color color,
  }) {
    return _GradeTwoPlan(
      sceneTitle: sceneTitle,
      sceneLine: sceneLine,
      tapInstruction: tapInstruction,
      phrase: phrase,
      phraseSpeech: phraseSpeech,
      buildPrompt: buildPrompt,
      buildQuestion: buildQuestion,
      buildCharacterAsset: buildCharacterAsset,
      buildAnswer: buildAnswer,
      buildTiles: buildTiles,
      choicePrompt: choicePrompt,
      choices: choices,
      answer: answer,
      missionTitle: missionTitle,
      missionPrompt: missionPrompt,
      missionChoices: missionChoices,
      missionAnswer: missionAnswer,
      reward: reward,
      imageAsset: imageAsset,
      icon: icon,
      color: color,
    );
  }

  return switch ((content.unitNumber, content.lessonNumber)) {
    (1, 1) => plan(
      sceneTitle: 'Bag-o nga Abyan',
      sceneLine: 'May bag-o nga abyan sa eskwelahan.',
      tapInstruction: 'Ipindot ang Kumusta!',
      phrase: 'Kumusta!',
      phraseSpeech: 'Kumusta!',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang ngalan mo?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Koka ang ngalan ko',
      buildTiles: const ['Koka ang ngalan ko', 'Kumusta', 'Paalam'],
      choicePrompt: 'Ano ang imo ngalan?',
      choices: const ['Kumusta!', 'Koka ang ngalan ko.', 'Paalam!'],
      answer: 'Koka ang ngalan ko.',
      missionTitle: 'Kilalaha si Ana',
      missionPrompt: 'Pili-a ang sabat ni Koka.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'Koka ang ngalan ko.',
          isKoka: true,
          icon: Icons.face_rounded,
        ),
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Salamat!', icon: Icons.favorite),
      ],
      missionAnswer: 'Koka ang ngalan ko.',
      reward: 'Abyan na kamo!',
      imageAsset: '$grade2/school-entrance.png',
      icon: Icons.school_rounded,
      color: TudloColors.green,
    ),
    (1, 2) => plan(
      sceneTitle: 'Kaadlawan ni Juan',
      sceneLine: 'Tan-awa ang kandila.',
      tapInstruction: 'Ipindot ang pito ka kandila.',
      phrase: 'Pito ka tuig ako.',
      phraseSpeech: 'Pito ka tuig ako.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Pila ka tuig ka na?',
      buildCharacterAsset: 'assets/images/level_game/people/boy-juan.png',
      buildAnswer: 'Pito ka tuig ako',
      buildTiles: const ['Pito', 'ka tuig', 'ako', 'anum'],
      choicePrompt: 'Pila ka tuig ka na?',
      choices: const [
        'Pito ka tuig ako.',
        'Koka ang ngalan ko.',
        'Maayong aga!',
      ],
      answer: 'Pito ka tuig ako.',
      missionTitle: 'Palupad Lobo',
      missionPrompt: 'Ano ang sabat?',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'Pito ka tuig ako.',
          visualLabel: '7',
          imageAsset: '$grade2/ballons.png',
          icon: Icons.celebration_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'Anum ka tuig ako.',
          visualLabel: '6',
          icon: Icons.looks_6,
        ),
        _GradeTwoMissionChoice(label: 'Kumusta!', icon: Icons.chat_bubble),
      ],
      missionAnswer: 'Pito ka tuig ako.',
      reward: 'Nagsaka ang mga lobo!',
      imageAsset: '$grade2/cake.png',
      icon: Icons.cake_rounded,
      color: TudloColors.coral,
    ),
    (1, 3) => plan(
      sceneTitle: 'Adlaw sang Pamilya',
      sceneLine: 'Kilalaha ang pamilya.',
      tapInstruction: 'Ipindot si Nanay.',
      phrase: 'Amo ini ang akon nanay.',
      phraseSpeech: 'Amo ini ang akon nanay.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Sin-o ini?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Amo ini ang akon nanay',
      buildTiles: const ['Amo ini ang', 'akon nanay', 'akon tatay', 'Paalam'],
      choicePrompt: 'Sin-o ini?',
      choices: const [
        'Amo ini ang akon nanay.',
        'Pito ka tuig ako.',
        'Paalam!',
      ],
      answer: 'Amo ini ang akon nanay.',
      missionTitle: 'Album sang Pamilya',
      missionPrompt: 'Pangitaa si Nanay.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'nanay',
          imageAsset: 'assets/images/level_game/people/nanay.png',
          icon: Icons.woman_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'tatay',
          imageAsset: 'assets/images/level_game/people/tatay.png',
          icon: Icons.man_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'bata',
          imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
          icon: Icons.child_care_rounded,
        ),
      ],
      missionAnswer: 'nanay',
      reward: 'Kompleto ang album.',
      imageAsset: 'assets/images/level_game/people/pamilya.png',
      icon: Icons.family_restroom_rounded,
      color: TudloColors.blue,
    ),
    (2, 1) => plan(
      sceneTitle: 'Adlaw ni Koka',
      sceneLine: 'Magbati sa aga, hapon, kag gab-i.',
      tapInstruction: 'Ipindot ang adlaw.',
      phrase: 'Maayong aga!',
      phraseSpeech: 'Maayong aga!',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Aga na. Ano ang hambalon mo?',
      buildCharacterAsset: 'assets/images/level_game/people/boy-juan.png',
      buildAnswer: 'Maayong aga',
      buildTiles: const ['Maayong', 'aga', 'gab-i', 'Kumusta'],
      choicePrompt: 'Aga na. Ano ang hambalon ni Koka?',
      choices: const ['Maayong aga!', 'Maayong gab-i!', 'Paalam!'],
      answer: 'Maayong aga!',
      missionTitle: 'Batia si Nanay',
      missionPrompt: 'Ano ang bati sa aga?',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Maayong aga!', icon: Icons.wb_sunny),
        _GradeTwoMissionChoice(label: 'Maayong gab-i!', icon: Icons.dark_mode),
        _GradeTwoMissionChoice(
          label: 'Pasensya.',
          icon: Icons.sentiment_dissatisfied,
        ),
      ],
      missionAnswer: 'Maayong aga!',
      reward: 'Maayo nga aga!',
      imageAsset: '$grade2/school-entrance.png',
      icon: Icons.wb_sunny_rounded,
      color: TudloColors.gold,
    ),
    (2, 2) => plan(
      sceneTitle: 'Kamusta Ka?',
      sceneLine: 'Nangamusta si Koka.',
      tapInstruction: 'Ipindot ang malipayon nga nawong.',
      phrase: 'Maayo man, salamat.',
      phraseSpeech: 'Maayo man, salamat.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Kamusta ka?',
      buildCharacterAsset: 'assets/images/level_game/people/girl1.png',
      buildAnswer: 'Maayo man salamat',
      buildTiles: const ['Maayo man', 'salamat', 'Paalam', 'Pasensya'],
      choicePrompt: 'Kamusta ka?',
      choices: const [
        'Maayo man, salamat.',
        'Maayong gab-i!',
        'Koka ang ngalan ko.',
      ],
      answer: 'Maayo man, salamat.',
      missionTitle: 'Magpaalam',
      missionPrompt: 'Magpaalam.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Maayo man.', icon: Icons.mood),
        _GradeTwoMissionChoice(
          label: 'Palihog.',
          icon: Icons.volunteer_activism,
        ),
      ],
      missionAnswer: 'Paalam!',
      reward: 'Nagpaalam ka sing maayo.',
      imageAsset: 'assets/images/level_game/people/girl1.png',
      icon: Icons.mood_rounded,
      color: TudloColors.green,
    ),
    (2, 3) => plan(
      sceneTitle: 'Sa Tinda',
      sceneLine: 'Gamita ang matinahuron nga tinaga.',
      tapInstruction: 'Ipindot ang mangga.',
      phrase: 'Palihog.',
      phraseSpeech: 'Palihog.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ginhatagan ka sang mangga.',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Salamat',
      buildTiles: const ['Salamat', 'Palihog', 'Pasensya', 'Paalam'],
      choicePrompt: 'Ginhatagan ka sang mangga. Ano ang hambalon mo?',
      choices: const ['Salamat.', 'Maayong aga!', 'Koka ang ngalan ko.'],
      answer: 'Salamat.',
      missionTitle: 'Pasensya',
      missionPrompt: 'Magsiling sang pasensya.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'Pasensya.', icon: Icons.favorite),
        _GradeTwoMissionChoice(label: 'Paalam!', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'Maayong gab-i!', icon: Icons.dark_mode),
      ],
      missionAnswer: 'Pasensya.',
      reward: 'Nagpatawad ang tindera.',
      imageAsset: '$grade2/mango.png',
      icon: Icons.storefront_rounded,
      color: TudloColors.orange,
    ),
    (3, 1) => plan(
      sceneTitle: 'Sa Klase',
      sceneLine: 'Pangitaa ang gamit sa klase.',
      tapInstruction: 'Pangitaa ang libro.',
      phrase: 'Ini ang libro.',
      phraseSpeech: 'Ini ang libro.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: 'assets/images/level_game/people/boy-juan.png',
      buildAnswer: 'Ini ang libro',
      buildTiles: const ['Ini ang', 'libro', 'lapis', 'pulungkuan'],
      choicePrompt: 'Pangitaa ang libro.',
      choices: const ['libro', 'lapis', 'bag'],
      answer: 'libro',
      missionTitle: 'Pangitaa ang Butang',
      missionPrompt: 'Pangitaa ang libro.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'libro',
          imageAsset: '$grade2/book.png',
          icon: Icons.menu_book_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'lapis',
          imageAsset: '$grade2/pencil.png',
          icon: Icons.edit_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'bag',
          imageAsset: '$grade2/bag.png',
          icon: Icons.backpack_rounded,
        ),
      ],
      missionAnswer: 'libro',
      reward: 'Nakita mo ang libro.',
      imageAsset: '$grade2/classroom.png',
      icon: Icons.search_rounded,
      color: TudloColors.blue,
    ),
    (3, 2) => plan(
      sceneTitle: 'Sa Lamesa',
      sceneLine: 'Pangitaa ang gamit sa lamesa.',
      tapInstruction: 'Ipindot ang plato.',
      phrase: 'Ini ang plato.',
      phraseSpeech: 'Ini ang plato.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Ini ang plato',
      buildTiles: const ['Ini ang', 'plato', 'baso', 'kutsara'],
      choicePrompt: 'Ano ang ibutang sa lamesa?',
      choices: const ['plato', 'libro', 'bag'],
      answer: 'plato',
      missionTitle: 'Bulig sa Lamesa',
      missionPrompt: 'Pangitaa ang kutsara.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'plato',
          imageAsset: '$grade2/plate.png',
          icon: Icons.dinner_dining,
        ),
        _GradeTwoMissionChoice(
          label: 'baso',
          imageAsset: '$grade2/glass.png',
          icon: Icons.local_drink,
        ),
        _GradeTwoMissionChoice(
          label: 'kutsara',
          imageAsset: '$grade2/spoon.png',
          icon: Icons.restaurant,
        ),
      ],
      missionAnswer: 'kutsara',
      reward: 'Handa na ang lamesa.',
      imageAsset: '$grade2/table.png',
      icon: Icons.table_restaurant_rounded,
      color: TudloColors.green,
    ),
    (3, 3) => plan(
      sceneTitle: 'Himoa ang Parke',
      sceneLine: 'Dugangi ang parke.',
      tapInstruction: 'Ipindot ang kahoy.',
      phrase: 'Ini ang kahoy.',
      phraseSpeech: 'Ini ang kahoy.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ini?',
      buildCharacterAsset: 'assets/images/level_game/people/boy1.png',
      buildAnswer: 'Ini ang kahoy',
      buildTiles: const ['Ini ang', 'kahoy', 'bulak', 'bato'],
      choicePrompt: 'Ano ang nagahatag landong?',
      choices: const ['kahoy', 'baso', 'kutsara'],
      answer: 'kahoy',
      missionTitle: 'Himoa ang Parke',
      missionPrompt: 'Pangitaa ang bulak.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'kahoy', icon: Icons.park_rounded),
        _GradeTwoMissionChoice(label: 'bulak', icon: Icons.local_florist),
        _GradeTwoMissionChoice(label: 'bato', icon: Icons.landscape),
      ],
      missionAnswer: 'bulak',
      reward: 'Nami ang parke.',
      icon: Icons.park_rounded,
      color: TudloColors.forest,
    ),
    (4, 1) => plan(
      sceneTitle: 'Kanta kag Hulag',
      sceneLine: 'Nagakanta kag nagahulag si Koka.',
      tapInstruction: 'Ipindot ang ulo.',
      phrase: 'Tanduga ang imo ulo.',
      phraseSpeech: 'Tanduga ang imo ulo.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang tandugon mo?',
      buildCharacterAsset: 'assets/images/level_game/people/girl1.png',
      buildAnswer: 'Tanduga ang imo ulo',
      buildTiles: const ['Tanduga ang', 'imo ulo', 'imo tiil', 'imo mata'],
      choicePrompt: 'Ano ang imo tandugon?',
      choices: const ['ulo', 'libro', 'merkado'],
      answer: 'ulo',
      missionTitle: 'Tapik sa Ritmo',
      missionPrompt: 'Ipindot ang tambol.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'tambol', icon: Icons.music_note_rounded),
        _GradeTwoMissionChoice(label: 'pulungkuan', icon: Icons.chair_rounded),
        _GradeTwoMissionChoice(label: 'bag', icon: Icons.backpack_rounded),
      ],
      missionAnswer: 'tambol',
      reward: 'Nagsayaw si Koka.',
      imageAsset: '$grade2/microphone.png',
      icon: Icons.music_note_rounded,
      color: TudloColors.coral,
    ),
    (4, 2) => plan(
      sceneTitle: 'Paktakon',
      sceneLine: 'Pamatii ang palatandaan kag sabta.',
      tapInstruction: 'Pamatii ang paktakon.',
      phrase: 'Ido ini.',
      phraseSpeech: 'Ido ini.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang sabat sa paktakon?',
      buildCharacterAsset: 'assets/images/level_game/people/boy2.png',
      buildAnswer: 'Ido ini',
      buildTiles: const ['Ido', 'ini', 'kuring', 'baboy'],
      choicePrompt: 'May apat ka tiil kag nagatahol.',
      choices: const ['ido', 'kuring', 'baboy'],
      answer: 'ido',
      missionTitle: 'Paktakon',
      missionPrompt: 'Pangitaa ang ido.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'ido',
          imageAsset: 'assets/images/level_game/animals/dog.png',
          icon: Icons.pets,
        ),
        _GradeTwoMissionChoice(
          label: 'kuring',
          imageAsset: 'assets/images/level_game/animals/cat.png',
          icon: Icons.pets,
        ),
        _GradeTwoMissionChoice(
          label: 'baboy',
          imageAsset: 'assets/images/level_game/animals/pig.png',
          icon: Icons.pets,
        ),
      ],
      missionAnswer: 'ido',
      reward: 'Nasabat mo ang paktakon.',
      imageAsset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.psychology_rounded,
      color: TudloColors.orange,
    ),
    (4, 3) => plan(
      sceneTitle: 'Mini Konsyerto',
      sceneLine: 'Kantaha ang pagbati.',
      tapInstruction: 'Ipindot ang mikropono.',
      phrase: 'Maayong aga sa akon nanay.',
      phraseSpeech: 'Maayong aga sa akon nanay.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang linya sang kanta?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Maayong aga sa akon nanay',
      buildTiles: const ['Maayong aga', 'sa akon', 'nanay', 'tatay'],
      choicePrompt: 'Sin-o ang ara sa kanta?',
      choices: const ['nanay', 'kutsara', 'pulungkuan'],
      answer: 'nanay',
      missionTitle: 'Konsyerto',
      missionPrompt: 'Ipindot ang manugkanta.',
      missionChoices: const [
        _GradeTwoMissionChoice(
          label: 'manugkanta',
          imageAsset: '$grade2/microphone.png',
          icon: Icons.mic_rounded,
        ),
        _GradeTwoMissionChoice(
          label: 'libro',
          imageAsset: '$grade2/book.png',
          icon: Icons.menu_book,
        ),
        _GradeTwoMissionChoice(
          label: 'mangga',
          imageAsset: '$grade2/mango.png',
          icon: Icons.storefront,
        ),
      ],
      missionAnswer: 'manugkanta',
      reward: 'Nagpalakpak ang klase.',
      imageAsset: '$grade2/school-stage.png',
      icon: Icons.mic_rounded,
      color: TudloColors.green,
    ),
    (5, 1) => plan(
      sceneTitle: 'Binalaybay',
      sceneLine: 'Pamatii ang pareho nga tunog.',
      tapInstruction: 'Ipindot ang kuring.',
      phrase: 'Nagapungko ang kuring.',
      phraseSpeech: 'Nagapungko ang kuring.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang una nga linya?',
      buildCharacterAsset: 'assets/images/level_game/people/girl1.png',
      buildAnswer: 'Nagapungko ang kuring',
      buildTiles: const ['Nagapungko ang', 'kuring', 'ido', 'isda'],
      choicePrompt: 'Ano ang kapareho tunog?',
      choices: const ['banig', 'isda', 'adlaw'],
      answer: 'banig',
      missionTitle: 'Pareho nga Tunog',
      missionPrompt: 'Pili-a ang kapareho tunog.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'banig', icon: Icons.crop_square),
        _GradeTwoMissionChoice(
          label: 'isda',
          imageAsset: 'assets/images/level_game/animals/fish.png',
          icon: Icons.water,
        ),
        _GradeTwoMissionChoice(
          label: 'adlaw',
          imageAsset: '$grade2/sun.png',
          icon: Icons.wb_sunny,
        ),
      ],
      missionAnswer: 'banig',
      reward: 'Pareho ang tunog.',
      imageAsset: 'assets/images/level_game/animals/cat.png',
      icon: Icons.auto_stories_rounded,
      color: TudloColors.blue,
    ),
    (5, 2) => plan(
      sceneTitle: 'Binalaybay nga May Hulag',
      sceneLine: 'Maghulag samtang nagabasa.',
      tapInstruction: 'Ipindot ang bata nga nagalumpat.',
      phrase: 'Makalumpat ako.',
      phraseSpeech: 'Makalumpat ako.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano nga hulag ang himuon?',
      buildCharacterAsset: 'assets/images/level_game/people/boy1.png',
      buildAnswer: 'Makalumpat ako',
      buildTiles: const ['Makalumpat', 'ako', 'paypay', 'liko'],
      choicePrompt: 'Ano nga hulag ang ginpamati?',
      choices: const ['lumpat', 'libro', 'plato'],
      answer: 'lumpat',
      missionTitle: 'Hulaga ang Linya',
      missionPrompt: 'Pili-a ang paypay.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'lumpat', icon: Icons.keyboard_arrow_up),
        _GradeTwoMissionChoice(label: 'paypay', icon: Icons.waving_hand),
        _GradeTwoMissionChoice(label: 'liko', icon: Icons.rotate_right),
      ],
      missionAnswer: 'paypay',
      reward: 'Handa ka na magbasa.',
      imageAsset: 'assets/images/level_game/people/boy1.png',
      icon: Icons.directions_run_rounded,
      color: TudloColors.coral,
    ),
    _ => plan(
      sceneTitle: 'Himoa ang Binalaybay',
      sceneLine: 'Pili tinaga kag basahon ni Koka.',
      tapInstruction: 'Ipindot ang ido.',
      phrase: 'Malipayon ang akon ido.',
      phraseSpeech: 'Malipayon ang akon ido.',
      buildPrompt: 'Ano ang isabat mo?',
      buildQuestion: 'Ano ang imo binalaybay?',
      buildCharacterAsset: 'assets/images/level_game/people/girl-ana.png',
      buildAnswer: 'Malipayon ang akon ido',
      buildTiles: const ['Malipayon ang', 'akon ido', 'kuring', 'masubo'],
      choicePrompt: 'Diin ang pareho sa binalaybay?',
      choices: const [
        'Malipayon ang akon ido.',
        'Pulungkuan kutsara baso.',
        'Paalam merkado.',
      ],
      answer: 'Malipayon ang akon ido.',
      missionTitle: 'Himoa ang Binalaybay',
      missionPrompt: 'Pili-a ang malipayon.',
      missionChoices: const [
        _GradeTwoMissionChoice(label: 'malipayon', icon: Icons.mood),
        _GradeTwoMissionChoice(label: 'pulungkuan', icon: Icons.chair),
        _GradeTwoMissionChoice(label: 'kutsara', icon: Icons.restaurant),
      ],
      missionAnswer: 'malipayon',
      reward: 'Nabasa ni Koka ang imo binalaybay.',
      imageAsset: 'assets/images/level_game/animals/dog.png',
      icon: Icons.auto_stories_rounded,
      color: TudloColors.forest,
    ),
  };
}

String _letterSoundText(String letter) {
  return switch (letter.trim().toUpperCase()) {
    'A' => 'Ah',
    'E' => 'e',
    'I' => 'i',
    'O' => 'o',
    'U' => 'u',
    'N' => 'n',
    'T' => 't',
    'Y' => 'y',
    'D' => 'd',
    'G' => 'g',
    'K' => 'k',
    'L' => 'l',
    'M' => 'm',
    'P' => 'p',
    'R' => 'r',
    'S' => 's',
    'W' => 'w',
    _ => letter.trim().toLowerCase(),
  };
}

String? _unitOneLetterAsset(String letter) {
  return const {
    'A': 'assets/images/level_game/letters/A.png',
    'B': 'assets/images/level_game/letters/B.png',
    'C': 'assets/images/level_game/letters/C.png',
    'D': 'assets/images/level_game/letters/D.png',
    'E': 'assets/images/level_game/letters/E.png',
    'F': 'assets/images/level_game/letters/F.png',
    'G': 'assets/images/level_game/letters/G.png',
    'H': 'assets/images/level_game/letters/H.png',
    'I': 'assets/images/level_game/letters/I.png',
    'K': 'assets/images/level_game/letters/K.png',
    'L': 'assets/images/level_game/letters/L.png',
    'M': 'assets/images/level_game/letters/M.png',
    'N': 'assets/images/level_game/letters/N.png',
    'O': 'assets/images/level_game/letters/O.png',
    'P': 'assets/images/level_game/letters/P-stage.png',
    'R': 'assets/images/level_game/letters/R.png',
    'S': 'assets/images/level_game/letters/S.png',
    'T': 'assets/images/level_game/letters/T.png',
    'U': 'assets/images/level_game/letters/U.png',
    'W': 'assets/images/level_game/letters/W.png',
    'Y': 'assets/images/level_game/letters/Y.png',
  }[letter.toUpperCase()];
}

String? _unitOneNumberAsset(String number) {
  return const {
    '0': 'assets/images/level_game/numbers/0.png',
    '1': 'assets/images/level_game/numbers/1.png',
    '2': 'assets/images/level_game/numbers/2.png',
    '3': 'assets/images/level_game/numbers/3.png',
    '4': 'assets/images/level_game/numbers/4.png',
    '5': 'assets/images/level_game/numbers/5.png',
    '6': 'assets/images/level_game/numbers/6.png',
    '7': 'assets/images/level_game/numbers/7.png',
    '8': 'assets/images/level_game/numbers/8.png',
    '9': 'assets/images/level_game/numbers/9.png',
    '10': null,
  }[number];
}

class _GradeOneAlphabetLesson extends StatefulWidget {
  final LevelContent content;
  final VoidCallback onExit;
  final ValueChanged<bool> onPresentationChromeChanged;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAlphabetLesson({
    required this.content,
    required this.onExit,
    required this.onPresentationChromeChanged,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneAlphabetLesson> createState() =>
      _GradeOneAlphabetLessonState();
}

class _GradeOneAlphabetLessonState extends State<_GradeOneAlphabetLesson> {
  int _stepIndex = 0;
  late final List<String> _quizTargets;
  bool? _lastPresentationChrome;

  @override
  void initState() {
    super.initState();
    final targets = _targetLettersFor(
      widget.content,
    ).map((target) => target.toUpperCase()).toSet().toList();
    _quizTargets = _shuffledChoices(
      targets.isNotEmpty ? targets : const ['A', 'N', 'T', 'Y'],
    );
  }

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() => _stepIndex = next);
    _notifyPresentationChrome(next);
  }

  void _notifyPresentationChrome([int? stepIndex]) {
    final shouldShow = true;
    if (_lastPresentationChrome == shouldShow) return;
    _lastPresentationChrome = shouldShow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPresentationChromeChanged(shouldShow);
    });
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    _lastPresentationChrome = false;
    widget.onPresentationChromeChanged(false);
    super.dispose();
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _finishQuiz() {
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchors = _alphabetAnchorsFor(widget.content.lessonNumber);
    final targets = _targetLettersFor(widget.content);
    var maxIndex = 0;
    final spellingAnchor = anchors.isNotEmpty
        ? anchors.first
        : const _AlphabetAnchor(
            word: 'NANAY',
            meaning: 'nanay',
            targets: ['N', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/people/nanay.png',
            icon: Icons.family_restroom_rounded,
          );
    final secondTarget = _quizTargets.length > 1
        ? _quizTargets[1]
        : _quizTargets.first;
    final secondAnchor = _bestAnchorForTarget(anchors, secondTarget);
    final animalAnchors = anchors
        .where(
          (anchor) =>
              anchor.imageAsset?.contains('/animals/') == true &&
              anchor.targets.isNotEmpty,
        )
        .toList();
    final quizActivities = [
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-tap-${widget.content.id}'),
        prompt: 'Pamatii ang tingog. Pindoton ang husto nga letra.',
        listenText: _letterSoundText(_quizTargets.first),
        showSpeakerHint: widget.content.lessonNumber == 1,
        progress: 1 / _lessonQuizCount,
        choices: _shuffledChoices([
          _quizTargets.first,
          ..._quizTargets.skip(1).take(2),
        ]),
        answer: _quizTargets.first,
        isLetter: true,
        imageAsset: _bestAnchorForTarget(
          anchors,
          _quizTargets.first,
        ).imageAsset,
        icon: _bestAnchorForTarget(anchors, _quizTargets.first).icon,
        onAttempt: (correct) => widget.onQuizAttempt(0, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneSpellingActivity(
        key: ValueKey('unit1-spell-${widget.content.id}'),
        prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
        progress: 2 / _lessonQuizCount,
        word: spellingAnchor.word,
        imageAsset: spellingAnchor.imageAsset,
        icon: spellingAnchor.icon,
        showDragTutorial:
            widget.content.unitNumber == 1 && widget.content.lessonNumber == 1,
        onAttempt: (correct) => widget.onQuizAttempt(1, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneHiddenSearchActivity(
        key: ValueKey('unit1-search-${widget.content.id}'),
        prompt: 'Unahon ta pangitaon ang letra nga mabatian mo.',
        progress: 3 / _lessonQuizCount,
        targetLetters: _quizTargets,
        onAttempt: (correct) => widget.onQuizAttempt(2, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      animalAnchors.length >= 2
          ? _UnitOneSubjectMatchActivity(
              key: ValueKey('unit1-match-${widget.content.id}'),
              prompt: 'Ipares ang sapat sa iya ngalan.',
              progress: 4 / _lessonQuizCount,
              anchors: animalAnchors,
              onAttempt: (correct) => widget.onQuizAttempt(3, correct),
              onDone: () => _advanceAfterCorrect(maxIndex),
            )
          : _UnitOneTapChoiceActivity(
              key: ValueKey('unit1-second-tap-${widget.content.id}'),
              prompt:
                  'Diin ang letra sang ${secondAnchor.meaning}? Pindoton ang $secondTarget.',
              progress: 4 / _lessonQuizCount,
              choices: _shuffledChoices([
                secondTarget,
                ..._quizTargets.where((item) => item != secondTarget).take(2),
              ]),
              answer: secondTarget,
              isLetter: true,
              imageAsset: secondAnchor.imageAsset,
              icon: secondAnchor.icon,
              onAttempt: (correct) => widget.onQuizAttempt(3, correct),
              onDone: () => _advanceAfterCorrect(maxIndex),
            ),
      _UnitOneDragFillActivity(
        key: ValueKey('unit1-drag-${widget.content.id}'),
        prompt: 'Guyoda ang mga letra para matapos ang tinaga.',
        progress: 5 / _lessonQuizCount,
        word: spellingAnchor.word,
        imageAsset: spellingAnchor.imageAsset,
        icon: spellingAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(4, correct),
        onDone: () {
          _finishQuiz();
          _advanceAfterCorrect(maxIndex);
        },
      ),
    ];

    final introTargets = targets
        .map((target) => target.toUpperCase())
        .toSet()
        .map(
          (target) => MapEntry(target, _bestAnchorForTarget(anchors, target)),
        )
        .toList();

    final presentationTargets = introTargets
        .map(
          (entry) => _AlphabetPresentationTarget.fromAnchor(
            letter: entry.key,
            anchor: _presentationAnchorForTarget(entry.key, entry.value),
          ),
        )
        .toList();
    final presentationSlides = [
      for (var index = 0; index < presentationTargets.length; index++) ...[
        _AlphabetPresentationSlideData(
          target: presentationTargets[index],
          type: _AlphabetPresentationSlideType.letter,
        ),
        if (index == 0)
          _AlphabetPresentationSlideData(
            target: presentationTargets[index],
            type: _AlphabetPresentationSlideType.word,
          ),
        _AlphabetPresentationSlideData(
          target: presentationTargets[index],
          type: _AlphabetPresentationSlideType.highlight,
        ),
        if (_shouldShowSingleContinuePrompt(presentationTargets, index))
          _AlphabetPresentationSlideData(
            target: presentationTargets[index],
            type: _AlphabetPresentationSlideType.continuePrompt,
          ),
      ],
    ];

    _notifyPresentationChrome();

    final steps = [
      for (var index = 0; index < presentationSlides.length; index++)
        _AlphabetFadeStep(
          child: _AlphabetPresentationSlide(
            key: ValueKey('alphabet-presentation-${widget.content.id}-$index'),
            data: presentationSlides[index],
            stepNumber: index + 1,
            totalSteps: presentationSlides.length,
            canGoBack: index > 0,
            onExit: widget.onExit,
            onBack: () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizActivities) _AlphabetFadeStep(child: card),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('alphabet-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: activeStep.child,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _shouldShowSingleContinuePrompt(
    List<_AlphabetPresentationTarget> targets,
    int index,
  ) {
    final nanayNIndex = targets.indexWhere(
      (target) =>
          target.word.toUpperCase() == 'NANAY' &&
          target.letter.toUpperCase() == 'N',
    );
    if (nanayNIndex != -1) return index == nanayNIndex;
    return index == 0;
  }

  _AlphabetAnchor _presentationAnchorForTarget(
    String target,
    _AlphabetAnchor fallback,
  ) {
    if (widget.content.lessonNumber == 1 && target.toUpperCase() == 'Y') {
      return const _AlphabetAnchor(
        word: 'NANAY KAG TATAY',
        meaning: 'nanay kag tatay',
        targets: ['Y'],
        imageAsset: null,
        imageAssets: [
          'assets/images/level_game/people/tatay.png',
          'assets/images/level_game/people/nanay.png',
        ],
        icon: Icons.family_restroom_rounded,
      );
    }
    return fallback;
  }

  List<String> _targetLettersFor(LevelContent content) {
    final titleTargets = RegExp(
      r'\b[A-Z]\b',
    ).allMatches(content.title).map((match) => match.group(0)!).toList();
    if (titleTargets.isNotEmpty) return titleTargets;
    return _alphabetAnchorsFor(
      content.lessonNumber,
    ).expand((anchor) => anchor.targets).toSet().toList();
  }

  _AlphabetAnchor _bestAnchorForTarget(
    List<_AlphabetAnchor> anchors,
    String target, {
    String prompt = '',
  }) {
    if (anchors.isEmpty) {
      return const _AlphabetAnchor(
        word: 'NANAY',
        meaning: 'nanay',
        targets: ['N', 'A', 'Y'],
        imageAsset: 'assets/images/level_game/people/nanay.png',
        icon: Icons.family_restroom_rounded,
      );
    }
    final lowerPrompt = prompt.toLowerCase();
    for (final anchor in anchors) {
      if (lowerPrompt.contains(anchor.word.toLowerCase())) return anchor;
    }
    return anchors.firstWhere(
      (anchor) => anchor.word.contains(target),
      orElse: () => anchors.first,
    );
  }

  List<_AlphabetAnchor> _alphabetAnchorsFor(int lessonNumber) {
    switch (lessonNumber) {
      case 1:
        return const [
          _AlphabetAnchor(
            word: 'NANAY',
            meaning: 'nanay',
            targets: ['N', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/people/nanay.png',
            icon: Icons.family_restroom_rounded,
          ),
          _AlphabetAnchor(
            word: 'TATAY',
            meaning: 'tatay',
            targets: ['T', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/people/tatay.png',
            icon: Icons.family_restroom_rounded,
          ),
        ];
      case 2:
        return const [
          _AlphabetAnchor(
            word: 'IDO',
            meaning: 'ido',
            targets: ['I', 'D', 'O'],
            imageAsset: 'assets/images/level_game/animals/dog.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 3:
        return const [
          _AlphabetAnchor(
            word: 'MANOK',
            meaning: 'manok',
            targets: ['M', 'K'],
            imageAsset: 'assets/images/level_game/animals/chicken.png',
            icon: Icons.egg_alt_rounded,
          ),
          _AlphabetAnchor(
            word: 'KURING',
            meaning: 'kuring',
            targets: ['K', 'U'],
            imageAsset: 'assets/images/level_game/animals/cat.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 4:
        return const [
          _AlphabetAnchor(
            word: 'BALAY',
            meaning: 'balay',
            targets: ['B', 'L'],
            imageAsset: 'assets/images/level_game/house.png',
            icon: Icons.home_rounded,
          ),
          _AlphabetAnchor(
            word: 'LOLA',
            meaning: 'lola',
            targets: ['L'],
            icon: Icons.elderly_woman_rounded,
          ),
          _AlphabetAnchor(
            word: 'ISDA',
            meaning: 'isda',
            targets: ['S'],
            imageAsset: 'assets/images/level_game/animals/fish.png',
            icon: Icons.water_rounded,
          ),
        ];
      case 5:
        return const [
          _AlphabetAnchor(
            word: 'ESKWELAHAN',
            meaning: 'eskwelahan',
            targets: ['E'],
            imageAsset: 'assets/images/level_game/eskwelahan.png',
            icon: Icons.school_rounded,
          ),
          _AlphabetAnchor(
            word: 'GATAS',
            meaning: 'gatas',
            targets: ['G'],
            imageAsset: 'assets/images/level_game/milk.png',
            icon: Icons.local_drink_rounded,
          ),
          _AlphabetAnchor(
            word: 'PAMILYA',
            meaning: 'pamilya',
            targets: ['P'],
            imageAsset: 'assets/images/level_game/people/pamilya.png',
            icon: Icons.diversity_3_rounded,
          ),
        ];
      case 6:
      default:
        return const [
          _AlphabetAnchor(
            word: 'DOKTOR',
            meaning: 'doktor',
            targets: ['R'],
            imageAsset: 'assets/images/level_game/people/doktor.png',
            icon: Icons.medical_services_rounded,
          ),
          _AlphabetAnchor(
            word: 'HOSPITAL',
            meaning: 'ospital',
            targets: ['H'],
            imageAsset: 'assets/images/level_game/ospital.png',
            icon: Icons.local_hospital_rounded,
          ),
          _AlphabetAnchor(
            word: 'KARBAW',
            meaning: 'karbaw',
            targets: ['W'],
            imageAsset: 'assets/images/level_game/animals/carabao.png',
            icon: Icons.agriculture_rounded,
          ),
        ];
    }
  }
}

class _AlphabetAnchor {
  final String word;
  final String meaning;
  final List<String> targets;
  final String? imageAsset;
  final List<String> imageAssets;
  final IconData icon;

  const _AlphabetAnchor({
    required this.word,
    required this.meaning,
    required this.targets,
    required this.icon,
    this.imageAsset,
    this.imageAssets = const [],
  });
}

List<_AlphabetAnchor> _unitOneAlphabetAnchorsFor(int lessonNumber) {
  switch (lessonNumber) {
    case 1:
      return const [
        _AlphabetAnchor(
          word: 'NANAY',
          meaning: 'nanay',
          targets: ['N', 'A', 'Y'],
          imageAsset: 'assets/images/level_game/people/nanay.png',
          icon: Icons.family_restroom_rounded,
        ),
        _AlphabetAnchor(
          word: 'TATAY',
          meaning: 'tatay',
          targets: ['T', 'A', 'Y'],
          imageAsset: 'assets/images/level_game/people/tatay.png',
          icon: Icons.family_restroom_rounded,
        ),
      ];
    case 2:
      return const [
        _AlphabetAnchor(
          word: 'IDO',
          meaning: 'ido',
          targets: ['I', 'D', 'O'],
          imageAsset: 'assets/images/level_game/animals/dog.png',
          icon: Icons.pets_rounded,
        ),
      ];
    case 3:
      return const [
        _AlphabetAnchor(
          word: 'MANOK',
          meaning: 'manok',
          targets: ['M', 'K'],
          imageAsset: 'assets/images/level_game/animals/chicken.png',
          icon: Icons.egg_alt_rounded,
        ),
        _AlphabetAnchor(
          word: 'KURING',
          meaning: 'kuring',
          targets: ['K', 'U'],
          imageAsset: 'assets/images/level_game/animals/cat.png',
          icon: Icons.pets_rounded,
        ),
      ];
    case 4:
      return const [
        _AlphabetAnchor(
          word: 'BALAY',
          meaning: 'balay',
          targets: ['B', 'L'],
          imageAsset: 'assets/images/level_game/house.png',
          icon: Icons.home_rounded,
        ),
        _AlphabetAnchor(
          word: 'LOLA',
          meaning: 'lola',
          targets: ['L'],
          icon: Icons.elderly_woman_rounded,
        ),
        _AlphabetAnchor(
          word: 'ISDA',
          meaning: 'isda',
          targets: ['S'],
          imageAsset: 'assets/images/level_game/animals/fish.png',
          icon: Icons.water_rounded,
        ),
      ];
    case 5:
      return const [
        _AlphabetAnchor(
          word: 'ESKWELAHAN',
          meaning: 'eskwelahan',
          targets: ['E'],
          imageAsset: 'assets/images/level_game/eskwelahan.png',
          icon: Icons.school_rounded,
        ),
        _AlphabetAnchor(
          word: 'GATAS',
          meaning: 'gatas',
          targets: ['G'],
          imageAsset: 'assets/images/level_game/milk.png',
          icon: Icons.local_drink_rounded,
        ),
        _AlphabetAnchor(
          word: 'PAMILYA',
          meaning: 'pamilya',
          targets: ['P'],
          imageAsset: 'assets/images/level_game/people/pamilya.png',
          icon: Icons.diversity_3_rounded,
        ),
      ];
    case 6:
    default:
      return const [
        _AlphabetAnchor(
          word: 'DOKTOR',
          meaning: 'doktor',
          targets: ['R'],
          imageAsset: 'assets/images/level_game/people/doktor.png',
          icon: Icons.medical_services_rounded,
        ),
        _AlphabetAnchor(
          word: 'HOSPITAL',
          meaning: 'ospital',
          targets: ['H'],
          imageAsset: 'assets/images/level_game/ospital.png',
          icon: Icons.local_hospital_rounded,
        ),
        _AlphabetAnchor(
          word: 'KARBAW',
          meaning: 'karbaw',
          targets: ['W'],
          imageAsset: 'assets/images/level_game/animals/carabao.png',
          icon: Icons.agriculture_rounded,
        ),
      ];
  }
}

class _AlphabetFadeStep {
  final Widget child;

  const _AlphabetFadeStep({required this.child});
}

class _GradeOneNumberLesson extends StatefulWidget {
  final LevelContent content;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneNumberLesson({
    required this.content,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneNumberLesson> createState() => _GradeOneNumberLessonState();
}

class _GradeOneNumberLessonState extends State<_GradeOneNumberLesson> {
  int _stepIndex = 0;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() => _stepIndex = next);
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _finishQuiz() {
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    var maxIndex = 0;
    final numbers = _numbersForUnitOneLesson(widget.content.lessonNumber);
    final numberValues = numbers.map(int.parse).toList();
    final soloNumbers = numberValues.take(4).toList();
    double quizProgress(int quizIndex) {
      return (quizIndex + 1) / _lessonQuizCount;
    }

    final steps = [
      for (final entry in numbers.asMap().entries)
        _AlphabetFadeStep(
          child: _NumberFruitPresentationSlide(
            number: int.parse(entry.value),
            progress: (entry.key + 1) / numbers.length,
            showSpeakerHint: widget.content.lessonNumber == 1,
            onBack: entry.key == 0
                ? null
                : () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          progress: 0,
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneTapChoiceActivity(
          prompt: 'Pamatii ang numero.',
          listenText: _hiligaynonNumberWord('${soloNumbers[0]}'),
          showSpeakerHint: false,
          progress: quizProgress(0),
          choices: _numberWordChoices(soloNumbers[0], numberValues),
          answer: _hiligaynonNumberWord('${soloNumbers[0]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[0]}'),
          icon: Icons.filter_1_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(0, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneSpellingActivity(
          prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
          progress: quizProgress(1),
          word: _hiligaynonNumberWord('${soloNumbers[1]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[1]}'),
          icon: Icons.filter_2_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneTapChoiceActivity(
          prompt: 'Ano ni siya nga numero?',
          progress: quizProgress(2),
          choices: _numberWordChoices(soloNumbers[2], numberValues),
          answer: _hiligaynonNumberWord('${soloNumbers[2]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[2]}'),
          icon: Icons.filter_3_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(2, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneTapChoiceActivity(
          prompt: 'Pilia ang ngalan sang numero.',
          progress: quizProgress(3),
          choices: _numberWordChoices(soloNumbers[3], numberValues),
          answer: _hiligaynonNumberWord('${soloNumbers[3]}'),
          imageAsset: _unitOneNumberAsset('${soloNumbers[3]}'),
          icon: Icons.filter_4_rounded,
          onAttempt: (correct) => widget.onQuizAttempt(3, correct),
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _UnitOneNumberMatchingActivity(
          prompt: 'Ipares kung ano ang sakto.',
          numbers: numbers.take(5).map(int.parse).toList(),
          progress: 1,
          showHint: widget.content.lessonNumber == 1,
          onAttempt: (correct) => widget.onQuizAttempt(4, correct),
          onDone: () {
            _finishQuiz();
            _advanceAfterCorrect(maxIndex);
          },
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('unit1-number-${widget.content.id}-$_stepIndex'),
        child: steps[_stepIndex.clamp(0, maxIndex)].child,
      ),
    );
  }

  List<String> _numbersForUnitOneLesson(int lessonNumber) {
    return lessonNumber == 8
        ? const ['6', '7', '8', '9', '10']
        : const ['1', '2', '3', '4', '5'];
  }

  List<String> _numberWordChoices(int answer, List<int> pool) {
    return _shuffledChoices([
      _hiligaynonNumberWord('$answer'),
      ...pool
          .where((number) => number != answer)
          .take(2)
          .map((number) => _hiligaynonNumberWord('$number')),
    ]).toList();
  }
}

class _GradeOneUnitOneReviewLesson extends StatefulWidget {
  final LevelContent content;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneUnitOneReviewLesson({
    required this.content,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneUnitOneReviewLesson> createState() =>
      _GradeOneUnitOneReviewLessonState();
}

class _GradeOneUnitOneReviewLessonState
    extends State<_GradeOneUnitOneReviewLesson> {
  static const int _reviewQuizCount = 10;
  static const List<String> _allReviewLetters = [
    'A',
    'N',
    'T',
    'Y',
    'I',
    'D',
    'O',
    'M',
    'K',
    'U',
    'B',
    'L',
    'S',
    'E',
    'G',
    'P',
    'R',
    'H',
    'W',
  ];
  static const List<int> _allReviewNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  int _stepIndex = 0;
  late final List<String> _reviewLetters = _shuffledChoices(_allReviewLetters);
  late final List<int> _reviewNumbers = _shuffledChoices(_allReviewNumbers);

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    unawaited(TudloVoiceButton.stop());
    setState(() => _stepIndex = next);
  }

  @override
  void dispose() {
    unawaited(TudloVoiceButton.stop());
    super.dispose();
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _finishQuiz() {
    for (var index = 0; index < _reviewQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  List<String> _letterChoices(String answer, List<String> pool) {
    return _shuffledChoices([
      answer,
      ...pool.where((letter) => letter != answer).take(2),
    ]).toList();
  }

  List<String> _numberWordChoices(int answer, List<int> pool) {
    return _shuffledChoices([
      _hiligaynonNumberWord('$answer'),
      ...pool
          .where((number) => number != answer)
          .take(2)
          .map((number) => _hiligaynonNumberWord('$number')),
    ]).toList();
  }

  _AlphabetAnchor _anchorForLetter(String letter) {
    final anchors = [
      for (var lesson = 1; lesson <= 6; lesson++)
        ..._unitOneAlphabetAnchorsFor(lesson),
    ];
    final target = letter.toUpperCase();
    return anchors.firstWhere(
      (anchor) =>
          anchor.word.contains(target) || anchor.targets.contains(target),
      orElse: () => anchors.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    var maxIndex = 0;
    final firstLetter = _reviewLetters[0];
    final spellingAnchor = _anchorForLetter(_reviewLetters[1]);
    final hiddenLetters = _reviewLetters.skip(2).take(3).toList();
    final fourthLetter = _reviewLetters[5];
    final dragAnchor = _anchorForLetter(_reviewLetters[6]);
    final firstAnchor = _anchorForLetter(firstLetter);
    final fourthAnchor = _anchorForLetter(fourthLetter);
    final firstNumber = _reviewNumbers[0];
    final spellingNumber = _reviewNumbers[1];
    final thirdNumber = _reviewNumbers[2];
    final fourthNumber = _reviewNumbers[3];
    final matchingNumbers = _reviewNumbers.take(5).toList();
    final steps = [
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-tap-$firstLetter-${widget.content.id}'),
        prompt: 'Pamatii ang tingog. Pindoton ang husto nga letra.',
        listenText: _letterSoundText(firstLetter),
        showSpeakerHint: false,
        progress: 1 / _reviewQuizCount,
        choices: _letterChoices(firstLetter, _allReviewLetters),
        answer: firstLetter,
        isLetter: true,
        imageAsset: firstAnchor.imageAsset,
        icon: firstAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(0, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneSpellingActivity(
        key: ValueKey(
          'unit1-review-spell-${spellingAnchor.word}-${widget.content.id}',
        ),
        prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
        progress: 2 / _reviewQuizCount,
        word: spellingAnchor.word,
        imageAsset: spellingAnchor.imageAsset,
        icon: spellingAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(1, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneHiddenSearchActivity(
        key: ValueKey('unit1-review-search-${widget.content.id}'),
        prompt: 'Unahon ta pangitaon ang letra nga mabatian mo.',
        progress: 3 / _reviewQuizCount,
        targetLetters: hiddenLetters,
        onAttempt: (correct) => widget.onQuizAttempt(2, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey(
          'unit1-review-${fourthAnchor.meaning}-${widget.content.id}',
        ),
        prompt:
            'Diin ang letra sang ${fourthAnchor.meaning}? Pindoton ang $fourthLetter.',
        progress: 4 / _reviewQuizCount,
        choices: _letterChoices(fourthLetter, _allReviewLetters),
        answer: fourthLetter,
        isLetter: true,
        imageAsset: fourthAnchor.imageAsset,
        icon: fourthAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(3, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneDragFillActivity(
        key: ValueKey(
          'unit1-review-drag-${dragAnchor.word}-${widget.content.id}',
        ),
        prompt: 'Guyoda ang mga letra para matapos ang tinaga.',
        progress: 5 / _reviewQuizCount,
        word: dragAnchor.word,
        imageAsset: dragAnchor.imageAsset,
        icon: dragAnchor.icon,
        onAttempt: (correct) => widget.onQuizAttempt(4, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-num-$firstNumber-${widget.content.id}'),
        prompt:
            'Pamatii ang numero. Pindoton ang ${_hiligaynonNumberWord('$firstNumber')}.',
        listenText: _hiligaynonNumberWord('$firstNumber'),
        showSpeakerHint: false,
        progress: 6 / _reviewQuizCount,
        choices: _numberWordChoices(firstNumber, _allReviewNumbers),
        answer: _hiligaynonNumberWord('$firstNumber'),
        imageAsset: _unitOneNumberAsset('$firstNumber'),
        icon: Icons.filter_1_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(5, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneSpellingActivity(
        key: ValueKey('unit1-review-num-$spellingNumber-${widget.content.id}'),
        prompt: 'Pamatia ang tinaga. Pilia ang kulang nga letra.',
        progress: 7 / _reviewQuizCount,
        word: _hiligaynonNumberWord('$spellingNumber'),
        imageAsset: _unitOneNumberAsset('$spellingNumber'),
        icon: Icons.filter_2_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(6, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-num-$thirdNumber-${widget.content.id}'),
        prompt: 'Ano ni siya nga numero?',
        progress: 8 / _reviewQuizCount,
        choices: _numberWordChoices(thirdNumber, _allReviewNumbers),
        answer: _hiligaynonNumberWord('$thirdNumber'),
        imageAsset: _unitOneNumberAsset('$thirdNumber'),
        icon: Icons.filter_3_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(7, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneTapChoiceActivity(
        key: ValueKey('unit1-review-num-$fourthNumber-${widget.content.id}'),
        prompt: 'Pilia ang ngalan sang numero.',
        progress: 9 / _reviewQuizCount,
        choices: _numberWordChoices(fourthNumber, _allReviewNumbers),
        answer: _hiligaynonNumberWord('$fourthNumber'),
        imageAsset: _unitOneNumberAsset('$fourthNumber'),
        icon: Icons.filter_4_rounded,
        onAttempt: (correct) => widget.onQuizAttempt(8, correct),
        onDone: () => _advanceAfterCorrect(maxIndex),
      ),
      _UnitOneNumberMatchingActivity(
        key: ValueKey('unit1-review-match-numbers-${widget.content.id}'),
        prompt: 'Ipares kung ano ang sakto.',
        progress: 1,
        numbers: matchingNumbers,
        onAttempt: (correct) => widget.onQuizAttempt(9, correct),
        onDone: () {
          _finishQuiz();
          _advanceAfterCorrect(maxIndex);
        },
      ),
    ];
    maxIndex = steps.length - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('unit1-review-${widget.content.id}-$_stepIndex'),
        child: steps[_stepIndex.clamp(0, maxIndex)],
      ),
    );
  }
}

class _NumberFruitPresentationSlide extends StatelessWidget {
  final int number;
  final double progress;
  final bool showSpeakerHint;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _NumberFruitPresentationSlide({
    required this.number,
    required this.progress,
    this.showSpeakerHint = false,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final numberWord = _numberWordFor(number);
    return _UnitOneQuizStage(
      prompt: 'Pamatii ang numero',
      mascotMessage: 'Numero $numberWord',
      progress: progress,
      child: _NumberFruitContent(
        number: number,
        showSpeakerHint: showSpeakerHint,
        onBack: onBack,
        onNext: onNext,
      ),
    );
  }
}

class _NumberFruitContent extends StatefulWidget {
  final int number;
  final bool showSpeakerHint;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _NumberFruitContent({
    required this.number,
    required this.showSpeakerHint,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_NumberFruitContent> createState() => _NumberFruitContentState();
}

class _NumberFruitContentState extends State<_NumberFruitContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;
  Timer? _hideHintTimer;
  Timer? _numberPopTimer;
  Timer? _fruitPopTimer;
  late bool _showSpeakerHint = widget.showSpeakerHint;
  bool _showNumber = false;
  bool _showFruits = false;

  @override
  void initState() {
    super.initState();
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    _startContentAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playNumberVoice();
      if (_showSpeakerHint) {
        _hideHintTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showSpeakerHint = false);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NumberFruitContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _startContentAnimation();
    }
  }

  void _startContentAnimation() {
    _numberPopTimer?.cancel();
    _fruitPopTimer?.cancel();
    _showNumber = false;
    _showFruits = false;
    _numberPopTimer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _showNumber = true);
    });
    _fruitPopTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _showFruits = true);
    });
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _numberPopTimer?.cancel();
    _fruitPopTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  Future<void> _playNumberVoice() async {
    final word = _numberWordFor(widget.number);
    await TudloVoiceButton.speak(
      context,
      'Pamatii ang tunog sang numero $word.',
      hiligaynon: true,
    );
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await TudloVoiceButton.speak(context, word, hiligaynon: true);
  }

  Future<void> _replayNumberVoice() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    setState(() => _showSpeakerHint = false);
    await TudloVoiceButton.speak(
      context,
      _numberWordFor(widget.number),
      hiligaynon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final number = widget.number;
    final numberAsset = _unitOneNumberAsset('$number');
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (width * .11).clamp(32.0, 58.0),
          ),
          child: SizedBox(
            height: (width * .5).clamp(198.0, 320.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 11,
                  child: AnimatedScale(
                    scale: _showNumber ? 1 : .35,
                    duration: const Duration(milliseconds: 460),
                    curve: Curves.elasticOut,
                    child: AnimatedOpacity(
                      opacity: _showNumber ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: numberAsset == null
                          ? FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                '$number',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            )
                          : Image.asset(
                              numberAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                    ),
                  ),
                ),
                SizedBox(width: (width * .025).clamp(8.0, 16.0)),
                Expanded(
                  flex: 9,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _AnimatedFruitCount(
                      number: number,
                      start: _showFruits,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _titleCase(_numberWordFor(number)),
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: (width * .155).clamp(58.0, 96.0),
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0xFF459B27),
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PresentationSpeakerHint(
          size: (width * .22).clamp(86.0, 118.0),
          showFinger: _showSpeakerHint,
          tapScale: _tapScale,
          tapOffset: _tapOffset,
          onTap: () => unawaited(_replayNumberVoice()),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: widget.onBack == null ? .35 : 1,
              child: _PresentationImageButton(
                asset:
                    'assets/images/level_game/lesson-game-assets/back-lesson.png',
                size: (width * .18).clamp(70.0, 100.0),
                enabled: widget.onBack != null,
                onTap: widget.onBack ?? () {},
                tooltip: 'Balik',
              ),
            ),
            SizedBox(width: (width * .16).clamp(56.0, 92.0)),
            _PresentationImageButton(
              asset:
                  'assets/images/level_game/lesson-game-assets/next-lesson.png',
              size: (width * .18).clamp(70.0, 100.0),
              onTap: widget.onNext,
              tooltip: 'Padayon',
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _AnimatedFruitCount extends StatefulWidget {
  final int number;
  final bool start;

  const _AnimatedFruitCount({required this.number, required this.start});

  @override
  State<_AnimatedFruitCount> createState() => _AnimatedFruitCountState();
}

class _AnimatedFruitCountState extends State<_AnimatedFruitCount> {
  int _visibleCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.start) {
      _startFruitAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedFruitCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _startFruitAnimation();
      return;
    }
    if (!oldWidget.start && widget.start) {
      _startFruitAnimation();
    }
  }

  void _startFruitAnimation() {
    _timer?.cancel();
    _visibleCount = 0;
    if (!widget.start) {
      if (mounted) setState(() {});
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      if (_visibleCount >= widget.number) {
        timer.cancel();
        return;
      }
      setState(() => _visibleCount++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.number.clamp(1, 10).toInt();
    final columns = count <= 2
        ? count
        : count <= 5
        ? 2
        : 3;
    final rows = (count / columns).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 5.0;
        final maxFruitWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        final maxFruitHeight =
            (constraints.maxHeight - (rows - 1) * spacing) / rows;
        final fruitSize = math
            .min(maxFruitWidth, maxFruitHeight)
            .clamp(44.0, 140.0)
            .toDouble();
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var index = 0; index < count; index++)
                AnimatedScale(
                  scale: index < _visibleCount ? 1 : .35,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.elasticOut,
                  child: AnimatedOpacity(
                    opacity: index < _visibleCount ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: SizedBox(
                      width: fruitSize,
                      height: fruitSize,
                      child: Image.asset(
                        _fruitAssetForNumber(widget.number),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _fruitAssetForNumber(int number) {
  return 'assets/images/level_game/apple.png';
}

String _numberMatchingFruitAsset() {
  return 'assets/images/level_game/apple.png';
}

String _numberWordFor(int number) {
  return _hiligaynonNumberWord('$number');
}

String _hiligaynonNumberWord(String number) {
  return const {
        '1': 'isa',
        '2': 'duwa',
        '3': 'tatlo',
        '4': 'apat',
        '5': 'lima',
        '6': 'anum',
        '7': 'pito',
        '8': 'walo',
        '9': 'siyam',
        '10': 'napulo',
      }[number] ??
      number;
}

class _UnitOneQuizStage extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final String prompt;
  final String mascotMessage;
  final double progress;
  final Widget child;

  const _UnitOneQuizStage({
    required this.prompt,
    required this.mascotMessage,
    this.progress = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final width = view.width;
    final height = view.height;
    final safeTop = MediaQuery.paddingOf(context).top;
    final topButtonSize = math
        .min(width * .13, height * .08)
        .clamp(48.0, 64.0)
        .toDouble();
    final mascotSize = math
        .min(width * .42, height * .26)
        .clamp(148.0, 232.0)
        .toDouble();
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            '$_assetBase/levelgame-bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Positioned(
            left: width * .06,
            top: safeTop + height * .025,
            child: _PresentationImageButton(
              asset: '$_assetBase/exit-page.png',
              size: topButtonSize,
              onTap: () => unawaited(_exitLessonFromContext(context)),
              tooltip: 'Balik',
            ),
          ),
          Positioned(
            left: width * .28,
            right: width * .27,
            top: safeTop + height * .045,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1).toDouble(),
                minHeight: (height * .023).clamp(16.0, 24.0),
                backgroundColor: Colors.white,
                color: TudloColors.green,
              ),
            ),
          ),
          Positioned(
            right: width * .055,
            top: safeTop + height * .026,
            child: Transform.scale(
              scale: .78,
              alignment: Alignment.topRight,
              child: const EnergyIndicator(),
            ),
          ),
          Positioned(
            left: width * .005,
            top: safeTop + height * .115,
            child: TudloMascot(size: mascotSize, mood: KokaMood.idle),
          ),
          Positioned(
            left: width * .31,
            right: width * .035,
            top: safeTop + height * .108,
            child: _PresentationInstructionText(
              message: prompt,
              fontSize: (width * .068).clamp(23.0, 39.0),
              onReplay: () {
                unawaited(
                  TudloVoiceButton.speak(context, prompt, hiligaynon: true),
                );
              },
            ),
          ),
          Positioned(
            left: width * .06,
            right: width * .06,
            top: height * .31,
            bottom: height * .02,
            child: child,
          ),
        ],
      ),
    );
  }
}

bool _isLivingSubjectAsset(String? imageAsset, IconData icon) {
  final asset = imageAsset?.toLowerCase() ?? '';
  if (asset.contains('/people/') || asset.contains('/animals/')) return true;
  return icon == Icons.family_restroom_rounded ||
      icon == Icons.pets_rounded ||
      icon == Icons.egg_alt_rounded ||
      icon == Icons.elderly_woman_rounded ||
      icon == Icons.elderly_rounded;
}

String _subjectQuestionFor(String? imageAsset, IconData icon) {
  return _isLivingSubjectAsset(imageAsset, icon)
      ? 'Sino ni siya?'
      : 'Ano ni siya?';
}

class _SubjectQuestionLabel extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;

  const _SubjectQuestionLabel({required this.imageAsset, required this.icon});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Text(
      _subjectQuestionFor(imageAsset, icon),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: (width * .065).clamp(24.0, 36.0),
        height: 1,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        shadows: const [
          Shadow(color: Color(0xFF459B27), blurRadius: 0, offset: Offset(2, 2)),
          Shadow(color: Colors.white, blurRadius: 1),
        ],
      ),
    );
  }
}

class _UnitOneTapChoiceActivity extends StatefulWidget {
  final String prompt;
  final String? listenText;
  final bool showSpeakerHint;
  final double progress;
  final List<String> choices;
  final String answer;
  final bool isLetter;
  final String? imageAsset;
  final IconData icon;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneTapChoiceActivity({
    super.key,
    required this.prompt,
    this.listenText,
    this.showSpeakerHint = true,
    this.progress = 0,
    required this.choices,
    required this.answer,
    this.isLetter = false,
    this.imageAsset,
    this.icon = Icons.text_fields_rounded,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneTapChoiceActivity> createState() =>
      _UnitOneTapChoiceActivityState();
}

class _UnitOneTapChoiceActivityState extends State<_UnitOneTapChoiceActivity>
    with SingleTickerProviderStateMixin {
  String? _selected;
  bool _wrong = false;
  bool _done = false;
  bool _showSpeakerHint = false;
  Timer? _hideHintTimer;
  Timer? _inactiveHintTimer;
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;

  @override
  void initState() {
    super.initState();
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showHintBriefly();
      unawaited(_playPrompt());
    });
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  void _showHintBriefly() {
    if (!widget.showSpeakerHint || widget.listenText == null || _done) return;
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted) setState(() => _showSpeakerHint = true);
    _hideHintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showSpeakerHint = false);
    });
    _inactiveHintTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  void _hideHintUntilInactive() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (!widget.showSpeakerHint || widget.listenText == null || _done) return;
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  Future<void> _playPrompt() async {
    await TudloVoiceButton.speak(context, widget.prompt);
    if (!mounted || widget.listenText == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    await TudloVoiceButton.speak(context, widget.listenText!, hiligaynon: true);
  }

  Future<void> _replayListenText() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    _hideHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      widget.listenText ?? widget.prompt,
      hiligaynon: true,
    );
  }

  Future<void> _choose(String choice) async {
    if (_done) return;
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    setState(() {
      _selected = choice;
      _wrong = false;
    });
    final spokenChoice = widget.isLetter ? _letterSoundText(choice) : choice;
    unawaited(TudloVoiceButton.speak(context, spokenChoice, hiligaynon: true));
  }

  Future<void> _submit() async {
    if (_done || _selected == null) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = _selected == widget.answer;
    widget.onAttempt(correct);
    setState(() {
      _wrong = !correct;
      _done = correct;
      if (correct) _showSpeakerHint = false;
    });
    unawaited(
      correct
          ? AppAudioService.instance.playCorrect()
          : AppAudioService.instance.playWrong(),
    );
    await TudloVoiceButton.speak(
      context,
      correct ? 'Husto! $_selected.' : 'Suliton liwat.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (correct) {
      _hideHintTimer?.cancel();
      _inactiveHintTimer?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted && _done) widget.onDone();
      });
    } else {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_done) {
          setState(() {
            _selected = null;
            _wrong = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto! Maayo gid.'
          : _wrong
          ? 'Koka: Suliton liwat.'
          : 'Koka: Pindoton ang husto nga sabat.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final imageHeight = (height * .34).clamp(145.0, 205.0);
          final imageWidth = (width * .66).clamp(210.0, 270.0);
          final speakerSize = (width * .20).clamp(72.0, 86.0);
          final choiceSize = (width * .27).clamp(92.0, 112.0);
          return Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.listenText == null) ...[
                        _SubjectQuestionLabel(
                          imageAsset: widget.imageAsset,
                          icon: widget.icon,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Flexible(
                        child: widget.imageAsset == null
                            ? Icon(
                                widget.icon,
                                color: TudloColors.green,
                                size: imageHeight * .84,
                              )
                            : Image.asset(
                                widget.imageAsset!,
                                width: imageWidth,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.icon,
                                  color: TudloColors.green,
                                  size: imageHeight * .74,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.listenText != null)
                SizedBox(
                  height: speakerSize * .98,
                  child: Center(
                    child: _PresentationSpeakerHint(
                      size: speakerSize,
                      showFinger: _showSpeakerHint,
                      tapScale: _tapScale,
                      tapOffset: _tapOffset,
                      onTap: _replayListenText,
                    ),
                  ),
                ),
              SizedBox(height: (height * .035).clamp(14.0, 24.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final choice in widget.choices.take(3))
                    Flexible(
                      child: _UnitOneSymbolButton(
                        label: choice,
                        isLetter: widget.isLetter,
                        assetSize: widget.isLetter ? choiceSize : null,
                        selected: _selected == choice,
                        correct: _selected == choice && _done,
                        wrong: _selected == choice && _wrong,
                        onTap: () => _choose(choice),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              _UnitOneSubmitButton(
                enabled: _selected != null && !_done,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnitOneSubmitButton extends StatelessWidget {
  final bool enabled;
  final FutureOr<void> Function() onPressed;

  const _UnitOneSubmitButton({required this.enabled, required this.onPressed});

  Future<void> _handleTap() async {
    if (!enabled) return;
    await AppAudioService.instance.playTap();
    await onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: 1,
      child: GestureDetector(
        onTap: enabled ? _handleTap : null,
        child: Container(
          width: double.infinity,
          height: 58,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: enabled
                ? TudloColors.blue
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: TudloColors.forest.withValues(alpha: .22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Text(
            'Ipasa',
            style: GoogleFonts.nunito(
              color: enabled ? Colors.white : TudloColors.muted,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitOneNumberMatchingActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final List<int> numbers;
  final bool showHint;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneNumberMatchingActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.numbers,
    this.showHint = false,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneNumberMatchingActivity> createState() =>
      _UnitOneNumberMatchingActivityState();
}

enum _NumberMatchDragSide { left, right }

class _UnitOneNumberMatchingActivityState
    extends State<_UnitOneNumberMatchingActivity>
    with SingleTickerProviderStateMixin {
  late final List<int> _leftNumbers = _shuffledChoices(widget.numbers);
  late final List<int> _rightNumbers = _shuffledChoices(widget.numbers);
  final Map<int, int> _connections = {};
  final GlobalKey _matchAreaKey = GlobalKey();
  _NumberMatchDragSide? _dragSide;
  int? _dragNumber;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _submittedWrong = false;
  bool _done = false;
  late bool _showHint = widget.showHint;
  Timer? _hideHintTimer;
  late final AnimationController _hintController;
  late final Animation<double> _hintScale;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOut,
    );
    _hintScale = Tween<double>(begin: 1, end: .86).animate(curve);
    if (_showHint) {
      _hideHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _hintController.dispose();
    super.dispose();
  }

  bool get _allConnected => _connections.length >= widget.numbers.length;

  bool get _allCorrect =>
      _allConnected &&
      _connections.entries.every((entry) => entry.key == entry.value);

  void _hideHint() {
    _hideHintTimer?.cancel();
    if (_showHint) {
      setState(() => _showHint = false);
    }
  }

  void _connect(int leftNumber, int rightNumber) {
    setState(() {
      _connections.removeWhere(
        (left, right) => left == leftNumber || right == rightNumber,
      );
      _connections[leftNumber] = rightNumber;
      _dragSide = null;
      _dragNumber = null;
      _dragStart = null;
      _dragCurrent = null;
      _submittedWrong = false;
    });
  }

  Offset _toMatchLocal(Offset globalPosition) {
    final box = _matchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition) ?? Offset.zero;
  }

  int? _numberAtY(double y, List<int> numbers, double height) {
    if (numbers.isEmpty || y < 0 || y > height) return null;
    final rawIndex = (y / height * numbers.length).floor();
    final index = rawIndex.clamp(0, numbers.length - 1).toInt();
    return numbers[index];
  }

  void _startDrag({
    required _NumberMatchDragSide side,
    required int number,
    required Offset anchor,
    required Offset globalPosition,
  }) {
    if (_done) return;
    _hideHint();
    unawaited(AppAudioService.instance.playTap());
    setState(() {
      _dragSide = side;
      _dragNumber = number;
      _dragStart = anchor;
      _dragCurrent = _toMatchLocal(globalPosition);
      _submittedWrong = false;
    });
  }

  void _updateDrag(Offset globalPosition) {
    if (_done || _dragStart == null) return;
    setState(() => _dragCurrent = _toMatchLocal(globalPosition));
  }

  void _cancelDrag() {
    if (_done) return;
    setState(() {
      _dragSide = null;
      _dragNumber = null;
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _endDrag(double height) {
    if (_done || _dragSide == null || _dragNumber == null) return;
    final local = _dragCurrent;
    if (local == null) return;
    final side = _dragSide!;
    final number = _dragNumber!;
    final target = side == _NumberMatchDragSide.left
        ? _numberAtY(local.dy, _rightNumbers, height)
        : _numberAtY(local.dy, _leftNumbers, height);
    if (target == null) {
      setState(() {
        _dragSide = null;
        _dragNumber = null;
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }
    if (side == _NumberMatchDragSide.left) {
      _connect(number, target);
    } else {
      _connect(target, number);
    }
  }

  Future<void> _submit() async {
    if (_done || !_allConnected) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }

    final correct = _allCorrect;
    widget.onAttempt(correct);
    if (correct) {
      setState(() => _done = true);
      unawaited(AppAudioService.instance.playCorrect());
      await TudloVoiceButton.speak(context, 'Husto!', hiligaynon: true);
      if (!mounted) return;
      widget.onDone();
      return;
    }

    setState(() => _submittedWrong = true);
    unawaited(AppAudioService.instance.playWrong());
    await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
  }

  double _rowCenterY(int index, int count, double height) {
    return ((index + .5) / count) * height;
  }

  int get _hintTargetNumber {
    return widget.numbers.contains(1) ? 1 : _leftNumbers.first;
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto!'
          : 'Koka: Ipares ang numero kag prutas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wordFont = (width * .082).clamp(29.0, 42.0);
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, area) {
                    final height = area.maxHeight;
                    final leftX = width * .16;
                    final rightX = width * .70;
                    final leftIndexes = {
                      for (var i = 0; i < _leftNumbers.length; i++)
                        _leftNumbers[i]: i,
                    };
                    final rightIndexes = {
                      for (var i = 0; i < _rightNumbers.length; i++)
                        _rightNumbers[i]: i,
                    };
                    final lineEntries = _connections.entries
                        .where(
                          (entry) =>
                              leftIndexes.containsKey(entry.key) &&
                              rightIndexes.containsKey(entry.value),
                        )
                        .map(
                          (entry) => _NumberMatchLine(
                            start: Offset(
                              leftX + width * .10,
                              _rowCenterY(
                                leftIndexes[entry.key]!,
                                _leftNumbers.length,
                                height,
                              ),
                            ),
                            end: Offset(
                              rightX - width * .10,
                              _rowCenterY(
                                rightIndexes[entry.value]!,
                                _rightNumbers.length,
                                height,
                              ),
                            ),
                            colorKey: entry.key,
                            correct: entry.key == entry.value,
                          ),
                        )
                        .toList();
                    final activeLine =
                        _dragStart != null &&
                            _dragCurrent != null &&
                            _dragNumber != null
                        ? _NumberMatchLine(
                            start: _dragStart!,
                            end: _dragCurrent!,
                            colorKey: _dragNumber!,
                            correct: true,
                          )
                        : null;
                    return Stack(
                      key: _matchAreaKey,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _NumberMatchLinePainter(
                              lines: [
                                ...lineEntries,
                                if (activeLine != null) activeLine,
                              ],
                              showCorrectness: _submittedWrong || _done,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          right: width * .58,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final number in _leftNumbers)
                                _NumberMatchWord(
                                  label: _titleCase(
                                    _hiligaynonNumberWord('$number'),
                                  ),
                                  fontSize: wordFont,
                                  selected:
                                      _dragSide == _NumberMatchDragSide.left &&
                                      _dragNumber == number,
                                  connected: _connections.containsKey(number),
                                  wrong:
                                      _submittedWrong &&
                                      _connections[number] != null &&
                                      _connections[number] != number,
                                  onPanStart: (details) => _startDrag(
                                    side: _NumberMatchDragSide.left,
                                    number: number,
                                    anchor: Offset(
                                      leftX + width * .10,
                                      _rowCenterY(
                                        leftIndexes[number]!,
                                        _leftNumbers.length,
                                        height,
                                      ),
                                    ),
                                    globalPosition: details.globalPosition,
                                  ),
                                  onPanUpdate: (details) =>
                                      _updateDrag(details.globalPosition),
                                  onPanEnd: (_) => _endDrag(height),
                                  onPanCancel: () => _cancelDrag(),
                                ),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          left: width * .50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (final number in _rightNumbers)
                                _NumberFruitMatchGroup(
                                  count: number,
                                  selected:
                                      _dragSide == _NumberMatchDragSide.right &&
                                      _dragNumber == number,
                                  connected: _connections.containsValue(number),
                                  wrong:
                                      _submittedWrong &&
                                      _connections.entries.any(
                                        (entry) =>
                                            entry.value == number &&
                                            entry.key != number,
                                      ),
                                  onPanStart: (details) => _startDrag(
                                    side: _NumberMatchDragSide.right,
                                    number: number,
                                    anchor: Offset(
                                      rightX - width * .10,
                                      _rowCenterY(
                                        rightIndexes[number]!,
                                        _rightNumbers.length,
                                        height,
                                      ),
                                    ),
                                    globalPosition: details.globalPosition,
                                  ),
                                  onPanUpdate: (details) =>
                                      _updateDrag(details.globalPosition),
                                  onPanEnd: (_) => _endDrag(height),
                                  onPanCancel: () => _cancelDrag(),
                                ),
                            ],
                          ),
                        ),
                        if (_showHint &&
                            leftIndexes.containsKey(_hintTargetNumber) &&
                            rightIndexes.containsKey(_hintTargetNumber))
                          _NumberMatchGestureHint(
                            scale: _hintScale,
                            start: Offset(
                              leftX,
                              _rowCenterY(
                                leftIndexes[_hintTargetNumber]!,
                                _leftNumbers.length,
                                height,
                              ),
                            ),
                            end: Offset(
                              rightX - width * .14,
                              _rowCenterY(
                                rightIndexes[_hintTargetNumber]!,
                                _rightNumbers.length,
                                height,
                              ),
                            ),
                            size: (width * .16).clamp(54.0, 72.0),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _UnitOneSubmitButton(
                enabled: _allConnected && !_done,
                onPressed: _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberMatchLine {
  final Offset start;
  final Offset end;
  final int colorKey;
  final bool correct;

  const _NumberMatchLine({
    required this.start,
    required this.end,
    required this.colorKey,
    required this.correct,
  });
}

class _NumberMatchLinePainter extends CustomPainter {
  final List<_NumberMatchLine> lines;
  final bool showCorrectness;

  const _NumberMatchLinePainter({
    required this.lines,
    required this.showCorrectness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final color = showCorrectness
          ? line.correct
                ? TudloColors.green
                : TudloColors.coral
          : _numberMatchColor(line.colorKey);
      final paint = Paint()
        ..color = color.withValues(alpha: .92)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(line.start, line.end, paint);
      canvas.drawCircle(line.start, 5, paint);
      canvas.drawCircle(line.end, 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NumberMatchLinePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.showCorrectness != showCorrectness;
  }
}

Color _numberMatchColor(int number) {
  return const [
    Color(0xFFFFD43B),
    Color(0xFF29B6F6),
    Color(0xFFFF7A59),
    Color(0xFFB86BFF),
    Color(0xFF16C784),
  ][number.abs() % 5];
}

class _NumberMatchGestureHint extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final Animation<double> scale;
  final Offset start;
  final Offset end;
  final double size;

  const _NumberMatchGestureHint({
    required this.scale,
    required this.start,
    required this.end,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2200),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            final position = Offset.lerp(start, end, value)!;
            return Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy - size * .18,
                  child: AnimatedBuilder(
                    animation: scale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: scale.value,
                        alignment: Alignment.topLeft,
                        child: child,
                      );
                    },
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: Transform.rotate(
            angle: -.55,
            child: Image.asset(
              '$_assetBase/point-finger.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberMatchWord extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool selected;
  final bool connected;
  final bool wrong;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  const _NumberMatchWord({
    required this.label,
    required this.fontSize,
    required this.selected,
    required this.connected,
    required this.wrong,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color = wrong ? const Color(0xFFFFE2E2) : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.08 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? TudloColors.blue.withValues(alpha: .32)
                : connected
                ? Colors.white.withValues(alpha: .16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: fontSize,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  color: Color(0xFF459B27),
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberFruitMatchGroup extends StatelessWidget {
  final int count;
  final bool selected;
  final bool connected;
  final bool wrong;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  const _NumberFruitMatchGroup({
    required this.count,
    required this.selected,
    required this.connected,
    required this.wrong,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final compact = count > 5;
    final columns = compact ? 5 : math.min(3, count);
    final rows = (count / columns).ceil();
    final fruitSize = compact ? 34.0 : 46.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.08 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected
                ? TudloColors.blue.withValues(alpha: .20)
                : connected
                ? Colors.white.withValues(alpha: .10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: wrong
                  ? TudloColors.coral
                  : selected
                  ? TudloColors.blue
                  : Colors.transparent,
              width: selected || wrong ? 3 : 0,
            ),
          ),
          child: SizedBox(
            width: columns * (fruitSize + 3),
            height: rows * (fruitSize + 3),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 3,
              children: [
                for (var index = 0; index < count; index++)
                  Image.asset(
                    _numberMatchingFruitAsset(),
                    width: fruitSize,
                    height: fruitSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitOneSpellingActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final String word;
  final String? imageAsset;
  final IconData icon;
  final bool showDragTutorial;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneSpellingActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.word,
    this.imageAsset,
    required this.icon,
    this.showDragTutorial = false,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneSpellingActivity> createState() =>
      _UnitOneSpellingActivityState();
}

class _UnitOneSpellingActivityState extends State<_UnitOneSpellingActivity>
    with SingleTickerProviderStateMixin {
  String? _selectedChoice;
  Set<String> _wrongChoices = const {};
  late int _activeMissingIndex;
  final Map<int, String> _filledLetters = {};
  bool _done = false;
  bool _showSpeakerHint = true;
  bool _showDragTutorialHint = false;
  Timer? _hideHintTimer;
  Timer? _inactiveHintTimer;
  Timer? _dragTutorialTimer;
  Timer? _inactiveDragTutorialTimer;
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;

  late final List<String> _letters = () {
    final letters = widget.word
        .replaceAll(RegExp(r'\s+'), '')
        .characters
        .map((letter) => letter.toUpperCase())
        .toList();
    return letters.isEmpty ? ['A'] : letters;
  }();
  late final List<int> _missingIndexes = _buildMissingIndexes();
  late final Set<String> _missingLetters = {
    for (final index in _missingIndexes) _letters[index],
  };

  late final List<String> _choices = _shuffledChoices(
    {
      ..._missingLetters,
      ...const ['A', 'N', 'T', 'Y', 'I', 'D', 'O', 'M', 'K', 'U'],
    }.take(5),
  ).toList();

  @override
  void initState() {
    super.initState();
    _activeMissingIndex = _missingIndexes.first;
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showHintBriefly();
      _queueDragTutorial(const Duration(milliseconds: 850));
      unawaited(TudloVoiceButton.speak(context, widget.prompt));
    });
  }

  void _queueDragTutorial(Duration delay) {
    if (!widget.showDragTutorial || _done) return;
    _dragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer = Timer(delay, () {
      _showDragTutorialBriefly();
    });
  }

  void _showDragTutorialBriefly() {
    if (!mounted || _done || !widget.showDragTutorial) return;
    setState(() => _showDragTutorialHint = true);
    _dragTutorialTimer?.cancel();
    _dragTutorialTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showDragTutorialHint = false);
      _queueDragTutorial(const Duration(seconds: 8));
    });
  }

  List<int> _buildMissingIndexes() {
    if (_letters.isEmpty) return const [0];
    if (_letters.length <= 2) return const [0];
    final shouldUseTwoBlanks =
        _letters.length >= 5 &&
        widget.word.codeUnits.fold<int>(0, (sum, code) => sum + code).isEven;
    final first = _letters.length ~/ 2;
    if (!shouldUseTwoBlanks) return [first];

    final second = math.max(0, _letters.length - 1);
    if (second == first) return [first];
    return [first, second]..sort();
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    _dragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  void _dismissDragTutorial() {
    _dragTutorialTimer?.cancel();
    _inactiveDragTutorialTimer?.cancel();
    if (_showDragTutorialHint && mounted) {
      setState(() => _showDragTutorialHint = false);
    }
    if (!_done) _queueDragTutorial(const Duration(seconds: 8));
  }

  void _showHintBriefly() {
    if (_done) return;
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted) setState(() => _showSpeakerHint = true);
    _hideHintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSpeakerHint = false);
    });
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  void _hideHintUntilInactive() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (_done) return;
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  Future<void> _playWord() async {
    await AppAudioService.instance.playTap();
    if (!mounted) return;
    _dismissDragTutorial();
    _hideHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      widget.word,
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _selectLetter(String letter) async {
    if (_done) return;
    _dismissDragTutorial();
    await AppAudioService.instance.playTap();
    setState(() {
      final targetIndex = _filledLetters.containsKey(_activeMissingIndex)
          ? _firstEmptyMissingIndex() ?? _activeMissingIndex
          : _activeMissingIndex;
      _filledLetters[targetIndex] = letter;
      _selectedChoice = letter;
      _wrongChoices = const {};
      _activeMissingIndex = _firstEmptyMissingIndex() ?? targetIndex;
    });
  }

  int? _firstEmptyMissingIndex() {
    for (final index in _missingIndexes) {
      if (!_filledLetters.containsKey(index)) return index;
    }
    return null;
  }

  void _clearSlot(int index) {
    if (_done) return;
    _dismissDragTutorial();
    setState(() {
      _filledLetters.remove(index);
      _activeMissingIndex = index;
      _selectedChoice = null;
      _wrongChoices = const {};
    });
  }

  Future<void> _submitLetter() async {
    if (_done || _filledLetters.length < _missingIndexes.length) return;
    _dismissDragTutorial();
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = _missingIndexes.every(
      (index) => _filledLetters[index] == _letters[index],
    );
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _wrongChoices = const {};
        _done = true;
        _showSpeakerHint = false;
      });
      _hideHintTimer?.cancel();
      _inactiveHintTimer?.cancel();
      _dragTutorialTimer?.cancel();
      _inactiveDragTutorialTimer?.cancel();
      unawaited(AppAudioService.instance.playCorrect());
      await TudloVoiceButton.speak(
        context,
        '${_titleCase(widget.word)}. Husto!',
        hiligaynon: true,
      );
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted && _done) widget.onDone();
      });
    } else {
      final wrongEntries = _filledLetters.entries
          .where((entry) => entry.value != _letters[entry.key])
          .toList();
      setState(() {
        _wrongChoices = {for (final entry in wrongEntries) entry.value};
        for (final entry in wrongEntries) {
          _filledLetters.remove(entry.key);
        }
        _activeMissingIndex = wrongEntries.isNotEmpty
            ? wrongEntries.first.key
            : _missingIndexes.first;
        _selectedChoice = null;
      });
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrongChoices = const {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Nabuo mo ang ${_titleCase(widget.word)}!'
          : _wrongChoices.isNotEmpty
          ? 'Koka: Suliton liwat.'
          : 'Koka: Pamatia anay ang tinaga, dayon pilia ang kulang nga letra.',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              SizedBox(
                height: 238,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SubjectQuestionLabel(
                        imageAsset: widget.imageAsset,
                        icon: widget.icon,
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: widget.imageAsset == null
                            ? Icon(
                                widget.icon,
                                color: TudloColors.green,
                                size: 145,
                              )
                            : Image.asset(
                                widget.imageAsset!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.icon,
                                  color: TudloColors.green,
                                  size: 140,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      _PresentationSpeakerHint(
                        size: 72,
                        showFinger: false,
                        tapScale: _tapScale,
                        tapOffset: _tapOffset,
                        onTap: _playWord,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _letters.length; i++)
                    if (_missingIndexes.contains(i))
                      DragTarget<String>(
                        onWillAcceptWithDetails: (_) => !_done,
                        onAcceptWithDetails: (details) {
                          _activeMissingIndex = i;
                          unawaited(_selectLetter(details.data));
                        },
                        builder: (context, candidates, rejected) {
                          return AnimatedScale(
                            duration: const Duration(milliseconds: 140),
                            scale: candidates.isNotEmpty ? 1.08 : 1,
                            child: GestureDetector(
                              onTap: () => _clearSlot(i),
                              child: _MissingLetterUnderlineSlot(
                                label: _done
                                    ? _letters[i]
                                    : _filledLetters[i] ?? '',
                                lineColor: _quizLineColorAt(i),
                                active:
                                    candidates.isNotEmpty ||
                                    _activeMissingIndex == i ||
                                    _filledLetters.containsKey(i),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _PlainAnswerLetter(label: _letters[i]),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 0,
                    children: [
                      for (final letter in _choices)
                        Draggable<String>(
                          data: letter,
                          feedback: Material(
                            color: Colors.transparent,
                            child: _UnitOneSymbolButton(
                              label: letter,
                              isLetter: true,
                              assetSize: 82,
                              onTap: () {},
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: .35,
                            child: _UnitOneSymbolButton(
                              label: letter,
                              isLetter: true,
                              assetSize: 82,
                              onTap: () {},
                            ),
                          ),
                          child: _UnitOneSymbolButton(
                            label: letter,
                            isLetter: true,
                            assetSize: 82,
                            selected: _selectedChoice == letter,
                            wrong: _wrongChoices.contains(letter),
                            onTap: () => _selectLetter(letter),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              _UnitOneSubmitButton(
                enabled:
                    _filledLetters.length == _missingIndexes.length && !_done,
                onPressed: _submitLetter,
              ),
            ],
          ),
          if (_showDragTutorialHint && !_done)
            Positioned.fill(
              child: _DragLetterTutorialHint(
                choiceIndex: _choices.indexOf(_letters[_activeMissingIndex]),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitOneHiddenSearchActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final List<String> targetLetters;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneHiddenSearchActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.targetLetters,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneHiddenSearchActivity> createState() =>
      _UnitOneHiddenSearchActivityState();
}

class _DragLetterTutorialHint extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final int choiceIndex;

  const _DragLetterTutorialHint({required this.choiceIndex});

  Offset _choiceAnchor(double width, double height) {
    final index = choiceIndex < 0 ? 0 : choiceIndex;
    final anchors = [
      Offset(width * .20, height * .68),
      Offset(width * .47, height * .68),
      Offset(width * .74, height * .68),
      Offset(width * .34, height * .86),
      Offset(width * .61, height * .86),
    ];
    return anchors[index.clamp(0, anchors.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2600),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              final begin = _choiceAnchor(width, height);
              final end = Offset(width * .48, height * .42);
              final position = Offset.lerp(begin, end, value)!;
              final pulse = math.sin(value * math.pi * 3).abs() * .08;
              return Stack(
                children: [
                  Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: Transform.rotate(
                      angle: -.35,
                      child: Transform.scale(
                        scale: 1 + pulse,
                        alignment: Alignment.topLeft,
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Image.asset(
              '$_assetBase/point-finger.png',
              width: (MediaQuery.sizeOf(context).width * .18).clamp(64.0, 92.0),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          );
        },
      ),
    );
  }
}

class _UnitOneHiddenSearchActivityState
    extends State<_UnitOneHiddenSearchActivity>
    with SingleTickerProviderStateMixin {
  final Set<String> _found = {};
  String? _wrong;
  bool _done = false;
  bool _showSpeakerHint = true;
  Timer? _hideHintTimer;
  Timer? _inactiveHintTimer;
  late final AnimationController _tapHintController;
  late final Animation<double> _tapScale;
  late final Animation<Offset> _tapOffset;

  late final List<String> _targets = widget.targetLetters
      .map((letter) => letter.toUpperCase())
      .toSet()
      .toList();
  late final List<String> _hiddenLetters = _shuffledChoices([
    ..._targets,
    ...const [
      'B',
      'L',
      'S',
      'I',
      'D',
      'O',
      'M',
      'K',
      'U',
    ].where((letter) => !_targets.contains(letter)).take(3),
  ]);

  String? get _currentTarget => _done || _found.length >= _targets.length
      ? null
      : _targets[_found.length];

  @override
  void initState() {
    super.initState();
    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(
      parent: _tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Unahon ta pangitaon ang letra nga mabatian mo.',
          hiligaynon: true,
        ),
      );
      _showHintBriefly();
    });
  }

  @override
  void dispose() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    _tapHintController.dispose();
    super.dispose();
  }

  void _showHintBriefly() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted) setState(() => _showSpeakerHint = true);
    _hideHintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSpeakerHint = false);
    });
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  void _hideHintUntilInactive() {
    _hideHintTimer?.cancel();
    _inactiveHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (_done) return;
    _inactiveHintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_done) _showHintBriefly();
    });
  }

  Future<void> _playCurrentLetter() async {
    await AppAudioService.instance.playTap();
    final target = _currentTarget;
    if (!mounted || target == null) return;
    _hideHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      _letterSoundText(target),
      hiligaynon: true,
    );
  }

  Future<void> _tapHidden(String letter) async {
    if (_done || _found.contains(letter)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = letter == _currentTarget;
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _found.add(letter);
        _wrong = null;
        _done = _found.length == _targets.length;
        _showSpeakerHint = !_done;
      });
      unawaited(AppAudioService.instance.playCorrect());
      if (_done) {
        _hideHintTimer?.cancel();
        _inactiveHintTimer?.cancel();
        await TudloVoiceButton.speak(
          context,
          'Ara na tanan nga letra!',
          hiligaynon: true,
          waitForCompletion: true,
        );
      } else {
        _showHintBriefly();
      }
    } else {
      setState(() => _wrong = letter);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrong = null);
      });
      _showHintBriefly();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Nakita mo sila tanan!'
          : _wrong != null
          ? 'Koka: Indi ina ang ginapangita.'
          : 'Koka: Unahon ta pangitaon ang letra nga mabatian mo.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 290,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                const letterPlacements = [
                  Offset(.00, .18),
                  Offset(.64, .02),
                  Offset(.83, .34),
                  Offset(.18, .56),
                  Offset(.50, .62),
                  Offset(.03, .44),
                  Offset(.68, .68),
                ];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var index = 0; index < _hiddenLetters.length; index++)
                      Positioned(
                        left:
                            width *
                            letterPlacements[index % letterPlacements.length]
                                .dx,
                        top:
                            height *
                            letterPlacements[index % letterPlacements.length]
                                .dy,
                        child: _HiddenLetterButton(
                          letter: _hiddenLetters[index],
                          found: _found.contains(_hiddenLetters[index]),
                          wrong: _wrong == _hiddenLetters[index],
                          onTap: () => _tapHidden(_hiddenLetters[index]),
                        ),
                      ),
                    Positioned(
                      left: -width * .03,
                      top: height * .47,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/tree1.png',
                        width: 154,
                      ),
                    ),
                    Positioned(
                      right: -width * .02,
                      top: height * .16,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/tree2.png',
                        width: 160,
                      ),
                    ),
                    Positioned(
                      left: width * .00,
                      bottom: height * .06,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/grass.png',
                        width: 152,
                      ),
                    ),
                    Positioned(
                      right: width * .02,
                      bottom: height * .10,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/rock.png',
                        width: 126,
                      ),
                    ),
                    Positioned(
                      left: width * .53,
                      top: height * .58,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/grass.png',
                        width: 118,
                      ),
                    ),
                    Positioned(
                      right: width * .16,
                      top: height * .43,
                      child: const _HiddenSceneCover(
                        asset: 'assets/images/game_map/rock.png',
                        width: 92,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          _PresentationSpeakerHint(
            size: 108,
            showFinger: _showSpeakerHint && !_done,
            tapScale: _tapScale,
            tapOffset: _tapOffset,
            onTap: _playCurrentLetter,
          ),
          const SizedBox(height: 0),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              for (final target in _targets)
                _LetterSlot(
                  label: _found.contains(target) ? target : '',
                  large: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _UnitOneSubmitButton(enabled: _done, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _UnitOneSubjectMatchActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final List<_AlphabetAnchor> anchors;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneSubjectMatchActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.anchors,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneSubjectMatchActivity> createState() =>
      _UnitOneSubjectMatchActivityState();
}

class _UnitOneSubjectMatchActivityState
    extends State<_UnitOneSubjectMatchActivity> {
  _AlphabetAnchor? _selected;
  final Set<String> _matched = {};
  bool _wrong = false;
  bool _done = false;

  int get _targetMatchCount => math.min(3, widget.anchors.length);

  Future<void> _selectName(_AlphabetAnchor anchor) async {
    if (_done || _matched.contains(anchor.word)) return;
    setState(() {
      _selected = anchor;
      _wrong = false;
    });
  }

  Future<void> _tapImage(_AlphabetAnchor anchor) async {
    if (_done || _matched.contains(anchor.word) || _selected == null) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = _selected!.word == anchor.word;
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _matched.add(anchor.word);
        _selected = null;
        _wrong = false;
        _done = _matched.length == _targetMatchCount;
      });
      unawaited(AppAudioService.instance.playCorrect());
      if (_done) {
        await TudloVoiceButton.speak(context, 'Husto! Naipares mo tanan.');
      }
    } else {
      setState(() => _wrong = true);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchors = widget.anchors.take(3).toList();
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto tanan!'
          : _wrong
          ? 'Koka: Suliton liwat.'
          : 'Koka: Pili-a ang ngalan, dayon pindoton ang sapat.',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final anchor in anchors)
                _MatchImageTile(
                  anchor: anchor,
                  selected: _selected?.word == anchor.word,
                  matched: _matched.contains(anchor.word),
                  wrong: _wrong && _selected != null,
                  onTap: () => _tapImage(anchor),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final anchor in anchors)
                _MatchNameButton(
                  label: _titleCase(anchor.meaning),
                  selected: _selected?.word == anchor.word,
                  matched: _matched.contains(anchor.word),
                  onTap: () => _selectName(anchor),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _UnitOneSubmitButton(enabled: _done, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _UnitOneDragFillActivity extends StatefulWidget {
  final String prompt;
  final double progress;
  final String word;
  final String? imageAsset;
  final IconData icon;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onDone;

  const _UnitOneDragFillActivity({
    super.key,
    required this.prompt,
    this.progress = 0,
    required this.word,
    this.imageAsset,
    required this.icon,
    required this.onAttempt,
    required this.onDone,
  });

  @override
  State<_UnitOneDragFillActivity> createState() =>
      _UnitOneDragFillActivityState();
}

class _UnitOneDragFillActivityState extends State<_UnitOneDragFillActivity> {
  final List<String> _filled = [];
  String? _wrong;
  bool _done = false;

  late final List<String> _targets = widget.word
      .replaceAll(RegExp(r'\s+'), '')
      .characters
      .map((letter) => letter.toUpperCase())
      .toList();
  late final List<String> _choices = _shuffledChoices(_targets.toSet());

  Future<void> _drop(String value) async {
    if (_done) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final expected = _targets[_filled.length];
    final correct = value == expected;
    widget.onAttempt(correct);
    if (correct) {
      setState(() {
        _filled.add(value);
        _wrong = null;
        _done = _filled.length == _targets.length;
      });
      unawaited(AppAudioService.instance.playCorrect());
      if (_done) {
        await TudloVoiceButton.speak(
          context,
          'Husto! Natapos mo.',
          hiligaynon: true,
          waitForCompletion: true,
        );
      }
    } else {
      setState(() => _wrong = value);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(context, 'Suliton liwat.', hiligaynon: true);
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: widget.prompt,
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Husto! Natapos mo.'
          : _wrong != null
          ? 'Koka: Suliton liwat.'
          : 'Koka: Guyoda ang husto sa kahon.',
      child: Column(
        children: [
          SizedBox(
            height: widget.imageAsset == null ? 142 : 190,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SubjectQuestionLabel(
                  imageAsset: widget.imageAsset,
                  icon: widget.icon,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: widget.imageAsset == null
                      ? Icon(widget.icon, color: TudloColors.green, size: 110)
                      : Image.asset(
                          widget.imageAsset!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Icon(
                            widget.icon,
                            color: TudloColors.green,
                            size: 110,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _targets.length; i++)
                DragTarget<String>(
                  onWillAcceptWithDetails: (_) => !_done,
                  onAcceptWithDetails: (details) => _drop(details.data),
                  builder: (context, candidates, rejected) {
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 140),
                      scale: candidates.isNotEmpty ? 1.08 : 1,
                      child: _LetterSlot(
                        label: i < _filled.length ? _filled[i] : '',
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: [
                  for (final value in _choices)
                    Draggable<String>(
                      data: value,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _UnitOneSymbolButton(
                          label: value,
                          isLetter: true,
                          assetSize: 82,
                          onTap: () {},
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .35,
                        child: _UnitOneSymbolButton(
                          label: value,
                          isLetter: true,
                          assetSize: 82,
                          onTap: () {},
                        ),
                      ),
                      child: _UnitOneSymbolButton(
                        label: value,
                        isLetter: true,
                        assetSize: 82,
                        wrong: _wrong == value,
                        onTap: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _UnitOneSubmitButton(enabled: _done, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _UnitOneSymbolButton extends StatelessWidget {
  final String label;
  final bool isLetter;
  final bool selected;
  final bool correct;
  final bool wrong;
  final double? assetSize;
  final VoidCallback onTap;

  const _UnitOneSymbolButton({
    required this.label,
    required this.onTap,
    this.isLetter = false,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
    this.assetSize,
  });

  @override
  Widget build(BuildContext context) {
    final asset = isLetter ? _unitOneLetterAsset(label) : null;
    final usesAssetChoice = asset != null && isLetter;
    final color = wrong
        ? TudloColors.coral
        : correct
        ? TudloColors.green
        : selected
        ? TudloColors.blue
        : Colors.white;
    final feedbackColor = wrong
        ? TudloColors.coral
        : correct
        ? TudloColors.green
        : selected
        ? TudloColors.blue
        : TudloColors.green;
    final choiceSize =
        assetSize ?? (usesAssetChoice ? 116.0 : (isLetter ? 100.0 : 112.0));
    final choiceHeight =
        assetSize ?? (usesAssetChoice ? 116.0 : (isLetter ? 100.0 : 70.0));
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: selected || correct ? 1.08 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: choiceSize,
            height: choiceHeight,
            alignment: Alignment.center,
            padding: EdgeInsets.all(usesAssetChoice ? 0 : 8),
            decoration: BoxDecoration(
              color: usesAssetChoice ? Colors.transparent : color,
              borderRadius: BorderRadius.circular(24),
              border: usesAssetChoice
                  ? null
                  : Border.all(
                      color: wrong
                          ? TudloColors.coral
                          : correct
                          ? TudloColors.green
                          : selected
                          ? TudloColors.blue
                          : TudloColors.green.withValues(alpha: .28),
                      width: selected || correct || wrong ? 4 : 2,
                    ),
              boxShadow: usesAssetChoice
                  ? [
                      if (selected || correct || wrong)
                        BoxShadow(
                          color: feedbackColor.withValues(alpha: .62),
                          blurRadius: selected ? 34 : 26,
                          spreadRadius: selected ? 9 : 5,
                        ),
                      if (selected)
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .75),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                    ]
                  : [
                      BoxShadow(
                        color: feedbackColor.withValues(
                          alpha: selected || correct || wrong ? .36 : .10,
                        ),
                        blurRadius: selected || correct || wrong ? 22 : 10,
                        spreadRadius: selected ? 3 : 0,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: asset == null
                ? Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: color == Colors.white
                          ? TudloColors.ink
                          : Colors.white,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  )
                : Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Text(
                      label,
                      style: GoogleFonts.nunito(
                        color: wrong ? TudloColors.coral : TudloColors.blue,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LetterSlot extends StatelessWidget {
  final String label;
  final bool large;

  const _LetterSlot({required this.label, this.large = false});

  @override
  Widget build(BuildContext context) {
    final width = large ? 72.0 : 58.0;
    final height = large ? 76.0 : 64.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: label.isEmpty
            ? Colors.white.withValues(alpha: .92)
            : TudloColors.softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: label.isEmpty
              ? TudloColors.green.withValues(alpha: .35)
              : TudloColors.green,
          width: 3,
        ),
      ),
      child: label.isEmpty
          ? const SizedBox.shrink()
          : Text(
              label,
              style: GoogleFonts.nunito(
                color: TudloColors.forest,
                fontSize: large ? 38 : 32,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
    );
  }
}

class _PlainAnswerLetter extends StatelessWidget {
  final String label;

  const _PlainAnswerLetter({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 62,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 46,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0xFF459B27),
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
              Shadow(color: Colors.white, blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingLetterUnderlineSlot extends StatelessWidget {
  final String label;
  final Color lineColor;
  final bool active;

  const _MissingLetterUnderlineSlot({
    required this.label,
    required this.lineColor,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final filled = label.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 60,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: lineColor, width: active ? 7 : 6),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: lineColor.withValues(alpha: .34),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: filled
          ? Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 46,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: const [
                  Shadow(
                    color: Color(0xFF459B27),
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                  Shadow(color: Colors.white, blurRadius: 1),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

Color _quizLineColorAt(int index) {
  const colors = [
    Color(0xFF1EA7FF),
    Color(0xFFFFC928),
    Color(0xFFFF6B57),
    Color(0xFF8C5CFF),
    Color(0xFF00BFA6),
  ];
  return colors[index % colors.length];
}

class _HiddenSceneCover extends StatelessWidget {
  final String asset;
  final double width;

  const _HiddenSceneCover({required this.asset, required this.width});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Image.asset(
        asset,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _HiddenLetterButton extends StatelessWidget {
  final String letter;
  final bool found;
  final bool wrong;
  final VoidCallback onTap;

  const _HiddenLetterButton({
    required this.letter,
    required this.found,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: found ? null : onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: found ? .72 : 1,
          child: AnimatedOpacity(
            opacity: found ? .22 : 1,
            duration: const Duration(milliseconds: 160),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (wrong)
                    BoxShadow(
                      color: TudloColors.coral.withValues(alpha: .36),
                      blurRadius: 22,
                      spreadRadius: 4,
                    )
                  else
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .24),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: _IntroLetterArt(letter: letter, size: 82),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchImageTile extends StatelessWidget {
  final _AlphabetAnchor anchor;
  final bool selected;
  final bool matched;
  final bool wrong;
  final VoidCallback onTap;

  const _MatchImageTile({
    required this.anchor,
    required this.selected,
    required this.matched,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      correct: matched,
      wrong: wrong && selected,
      child: GestureDetector(
        onTap: matched ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 138,
          height: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: matched
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected || matched
                  ? TudloColors.green
                  : TudloColors.line.withValues(alpha: .35),
              width: selected || matched ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.green.withValues(alpha: .12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: anchor.imageAsset == null
              ? Icon(anchor.icon, color: TudloColors.green, size: 92)
              : Image.asset(
                  anchor.imageAsset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(anchor.icon, color: TudloColors.green, size: 92),
                ),
        ),
      ),
    );
  }
}

class _MatchNameButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;

  const _MatchNameButton({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: matched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 132,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: matched || selected ? TudloColors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TudloColors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: TudloColors.green.withValues(alpha: .12),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: matched || selected ? Colors.white : TudloColors.forest,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

enum _AlphabetPresentationSlideType { letter, word, highlight, continuePrompt }

class _AlphabetPresentationTarget {
  final String letter;
  final String word;
  final String meaning;
  final List<String> imageAssets;
  final IconData icon;

  const _AlphabetPresentationTarget({
    required this.letter,
    required this.word,
    required this.meaning,
    required this.imageAssets,
    required this.icon,
  });

  factory _AlphabetPresentationTarget.fromAnchor({
    required String letter,
    required _AlphabetAnchor anchor,
  }) {
    final imageAssets = anchor.imageAssets.isNotEmpty
        ? anchor.imageAssets
        : [if (anchor.imageAsset != null) anchor.imageAsset!];
    return _AlphabetPresentationTarget(
      letter: letter.toUpperCase(),
      word: anchor.word,
      meaning: anchor.meaning,
      imageAssets: imageAssets,
      icon: anchor.icon,
    );
  }

  String get displayWord => _titleCase(word);
  String get speechWord => meaning.isEmpty ? word.toLowerCase() : meaning;
}

class _AlphabetPresentationSlideData {
  final _AlphabetPresentationTarget target;
  final _AlphabetPresentationSlideType type;

  const _AlphabetPresentationSlideData({
    required this.target,
    required this.type,
  });

  String get voiceText {
    final letter = target.letter;
    return switch (type) {
      _AlphabetPresentationSlideType.letter =>
        'Ang tunog sang letra nga $letter amo ang...',
      _AlphabetPresentationSlideType.word =>
        'Abyan, kilala mo kon sin-o ini? Siya si...',
      _AlphabetPresentationSlideType.highlight =>
        'May ara letra nga $letter sa may ${target.speechWord}.',
      _AlphabetPresentationSlideType.continuePrompt =>
        'Maayo gid abyan, padayon kita.',
    };
  }

  String get dialogueText {
    final letter = target.letter;
    final word = target.speechWord;
    return switch (type) {
      _AlphabetPresentationSlideType.letter =>
        'Ang tunog sang letra nga "$letter" amo ang...',
      _AlphabetPresentationSlideType.word =>
        'Abyan, kilala mo kon sin-o ini? Siya si...',
      _AlphabetPresentationSlideType.highlight =>
        'May ara letra nga "$letter" sa may $word',
      _AlphabetPresentationSlideType.continuePrompt =>
        'Maayo gid abyan, padayon kita',
    };
  }

  String get soundText {
    return switch (type) {
      _AlphabetPresentationSlideType.letter => _letterSoundText(target.letter),
      _AlphabetPresentationSlideType.word ||
      _AlphabetPresentationSlideType.highlight => target.speechWord,
      _AlphabetPresentationSlideType.continuePrompt => voiceText,
    };
  }

  bool get darkenCard => type == _AlphabetPresentationSlideType.highlight;
  bool get showWord => type != _AlphabetPresentationSlideType.letter;
  bool get showLetter => type == _AlphabetPresentationSlideType.letter;
  bool get showTapHint => type == _AlphabetPresentationSlideType.highlight;
}

class _AlphabetPresentationSlide extends StatefulWidget {
  final _AlphabetPresentationSlideData data;
  final int stepNumber;
  final int totalSteps;
  final bool canGoBack;
  final VoidCallback onExit;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _AlphabetPresentationSlide({
    super.key,
    required this.data,
    required this.stepNumber,
    required this.totalSteps,
    required this.canGoBack,
    required this.onExit,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_AlphabetPresentationSlide> createState() =>
      _AlphabetPresentationSlideState();
}

class _AlphabetPresentationSlideState extends State<_AlphabetPresentationSlide>
    with SingleTickerProviderStateMixin {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';
  AnimationController? _tapHintController;
  Animation<double>? _tapScale;
  Animation<Offset>? _tapOffset;
  Timer? _hideSpeakerHintTimer;
  Timer? _inactiveSpeakerHintTimer;
  bool _showSpeakerHint = false;

  Animation<double> get _safeTapScale =>
      _tapScale ?? const AlwaysStoppedAnimation<double>(1);

  Animation<Offset> get _safeTapOffset =>
      _tapOffset ?? const AlwaysStoppedAnimation<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();
    final tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _tapHintController = tapHintController;
    final curve = CurvedAnimation(
      parent: tapHintController,
      curve: Curves.easeInOut,
    );
    _tapScale = Tween<double>(begin: 1, end: .86).animate(curve);
    _tapOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-8, -8),
    ).animate(curve);
    _configureSpeakerHint();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) unawaited(_speak());
      });
    });
  }

  @override
  void didUpdateWidget(covariant _AlphabetPresentationSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepNumber != widget.stepNumber ||
        oldWidget.data.type != widget.data.type) {
      _configureSpeakerHint();
    }
  }

  @override
  void dispose() {
    _hideSpeakerHintTimer?.cancel();
    _inactiveSpeakerHintTimer?.cancel();
    _tapHintController?.dispose();
    super.dispose();
  }

  void _configureSpeakerHint() {
    _hideSpeakerHintTimer?.cancel();
    _inactiveSpeakerHintTimer?.cancel();
    final shouldShow = widget.stepNumber == 1;
    _showSpeakerHint = shouldShow;
    if (shouldShow) {
      _hideSpeakerHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSpeakerHint = false);
      });
    }
  }

  void _hideSpeakerHintUntilInactive() {
    _hideSpeakerHintTimer?.cancel();
    _inactiveSpeakerHintTimer?.cancel();
    if (mounted && _showSpeakerHint) {
      setState(() => _showSpeakerHint = false);
    }
    if (widget.stepNumber != 1) return;
    _inactiveSpeakerHintTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() => _showSpeakerHint = true);
      _hideSpeakerHintTimer?.cancel();
      _hideSpeakerHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSpeakerHint = false);
      });
    });
  }

  Future<void> _speak() async {
    await TudloVoiceButton.speak(
      context,
      widget.data.voiceText,
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  Future<void> _speakSoundOnly() async {
    _hideSpeakerHintUntilInactive();
    await TudloVoiceButton.speak(
      context,
      widget.data.soundText,
      hiligaynon: true,
      waitForCompletion: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.sizeOf(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.height;
        final safeTop = MediaQuery.paddingOf(context).top;
        final mascotSize = math
            .min(width * .42, height * .26)
            .clamp(148.0, 232.0)
            .toDouble();
        final topButtonSize = math
            .min(width * .14, height * .075)
            .clamp(48.0, 66.0)
            .toDouble();
        final navButtonSize = math
            .min(width * .27, height * .15)
            .clamp(110.0, 160.0)
            .toDouble();
        final isContinuePrompt =
            data.type == _AlphabetPresentationSlideType.continuePrompt;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  '$_assetBase/levelgame-bg.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                left: width * .06,
                top: safeTop + height * .025,
                child: _PresentationImageButton(
                  asset: '$_assetBase/exit-page.png',
                  size: topButtonSize,
                  onTap: widget.onExit,
                  tooltip: 'Balik',
                ),
              ),
              Positioned(
                left: width * .28,
                right: width * .27,
                top: safeTop + height * .045,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.totalSteps == 0
                        ? 0
                        : widget.stepNumber / widget.totalSteps,
                    minHeight: (height * .023).clamp(16.0, 24.0),
                    backgroundColor: Colors.white,
                    color: TudloColors.green,
                  ),
                ),
              ),
              if (!isContinuePrompt) ...[
                Positioned(
                  left: width * .005,
                  top: safeTop + height * .115,
                  child: TudloMascot(size: mascotSize, mood: KokaMood.idle),
                ),
                Positioned(
                  left: width * .31,
                  right: width * .035,
                  top: safeTop + height * .108,
                  child: _PresentationInstructionText(
                    message: data.dialogueText,
                    fontSize: (width * .073).clamp(26.0, 42.0),
                    onReplay: _speak,
                  ),
                ),
                Positioned(
                  left: width * .04,
                  right: width * .04,
                  top: height * .29,
                  bottom: height * .235,
                  child: _AlphabetPresentationBoard(
                    data: data,
                    showSpeakerHint: _showSpeakerHint,
                    tapScale: _safeTapScale,
                    tapOffset: _safeTapOffset,
                    onReplay: _speakSoundOnly,
                  ),
                ),
              ] else ...[
                Positioned(
                  left: width * .12,
                  right: width * .12,
                  top: height * .285,
                  child: Center(
                    child: _PresentationInstructionText(
                      message: data.dialogueText,
                      fontSize: (width * .078).clamp(28.0, 44.0),
                      textAlign: TextAlign.center,
                      onReplay: _speak,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * .39,
                  child: Center(
                    child: TudloMascot(
                      size: (mascotSize * 1.72).clamp(230.0, 380.0),
                      mood: KokaMood.curious,
                    ),
                  ),
                ),
              ],
              Positioned(
                left: width * .19,
                bottom: height * .09,
                child: _PresentationImageButton(
                  asset: '$_assetBase/back-lesson.png',
                  size: navButtonSize,
                  onTap: widget.onBack,
                  enabled: widget.canGoBack,
                  tooltip: 'Balik',
                ),
              ),
              Positioned(
                right: width * .19,
                bottom: height * .09,
                child: _PresentationImageButton(
                  asset: '$_assetBase/next-lesson.png',
                  size: navButtonSize,
                  onTap: widget.onNext,
                  tooltip: 'Sunod',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresentationImageButton extends StatelessWidget {
  final String asset;
  final double size;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _PresentationImageButton({
    required this.asset,
    required this.size,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .34,
      child: GestureDetector(
        onTap: enabled
            ? () async {
                await AppAudioService.instance.playTap();
                onTap();
              }
            : null,
        child: Tooltip(
          message: tooltip,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              tooltip == 'Balik'
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
              size: size * .74,
              color: TudloColors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresentationInstructionText extends StatelessWidget {
  final String message;
  final double fontSize;
  final TextAlign textAlign;
  final VoidCallback onReplay;

  const _PresentationInstructionText({
    required this.message,
    required this.fontSize,
    this.textAlign = TextAlign.start,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.nunito(
      color: Colors.white,
      fontSize: fontSize,
      height: 1.18,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: .08),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );

    final iconSize = (fontSize * 1.15).clamp(30.0, 44.0);
    return RichText(
      textAlign: textAlign,
      maxLines: 4,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: '$message '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () async {
                await AppAudioService.instance.playTap();
                onReplay();
              },
              child: Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: TudloColors.green,
                  size: (fontSize * .70).clamp(20.0, 30.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlphabetPresentationBoard extends StatelessWidget {
  final _AlphabetPresentationSlideData data;
  final bool showSpeakerHint;
  final Animation<double> tapScale;
  final Animation<Offset> tapOffset;
  final VoidCallback onReplay;

  const _AlphabetPresentationBoard({
    required this.data,
    required this.showSpeakerHint,
    required this.tapScale,
    required this.tapOffset,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final target = data.target;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final stageHeight = constraints.maxHeight;
        final letterSize = math
            .min(stageWidth * .60, stageHeight * .54)
            .clamp(190.0, 310.0)
            .toDouble();
        final artSize = math
            .min(stageWidth * .82, stageHeight * .66)
            .clamp(180.0, 330.0)
            .toDouble();
        final speakerSize = math
            .min(stageWidth * .44, stageHeight * .30)
            .clamp(122.0, 176.0)
            .toDouble();
        return SizedBox(
          width: stageWidth,
          height: stageHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (data.showWord)
                Positioned(
                  top: 0,
                  left: stageWidth * .02,
                  right: stageWidth * .02,
                  child: _PresentationWordTitle(
                    word: target.displayWord,
                    highlightLetter: data.showTapHint ? target.letter : null,
                  ),
                ),
              Align(
                alignment: data.showLetter
                    ? const Alignment(0, -.05)
                    : const Alignment(0, -.10),
                child: data.showLetter
                    ? _PresentationLetterPair(
                        letter: target.letter,
                        color: Colors.white,
                        size: letterSize,
                      )
                    : Padding(
                        padding: EdgeInsets.only(
                          top: data.showWord ? stageHeight * .12 : 0,
                          bottom: stageHeight * .10,
                        ),
                        child: _PresentationAssetArt(
                          target: target,
                          size: artSize,
                          maxWidth: stageWidth * .94,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                child: _PresentationSpeakerHint(
                  size: speakerSize,
                  showFinger: showSpeakerHint,
                  tapScale: tapScale,
                  tapOffset: tapOffset,
                  onTap: () {
                    unawaited(AppAudioService.instance.playTap());
                    onReplay();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresentationWordTitle extends StatelessWidget {
  final String word;
  final String? highlightLetter;

  const _PresentationWordTitle({required this.word, this.highlightLetter});

  @override
  Widget build(BuildContext context) {
    if (highlightLetter != null) {
      return _PresentationOutlinedWord(
        word: word,
        highlightLetter: highlightLetter,
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        word,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: Colors.white.withValues(alpha: .78),
          fontSize: word.length > 11 ? 38 : 52,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          shadows: const [
            Shadow(
              color: Color(0xFF2A6655),
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
            Shadow(color: Colors.white, blurRadius: 1),
          ],
        ),
      ),
    );
  }
}

class _PresentationOutlinedWord extends StatelessWidget {
  final String word;
  final String? highlightLetter;

  const _PresentationOutlinedWord({
    required this.word,
    required this.highlightLetter,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final letter in letters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
              decoration: letter.toUpperCase() == highlightLetter
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: TudloColors.blue,
                          width: word.length > 11 ? 5 : 7,
                        ),
                      ),
                    )
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.transparent, width: 7),
                      ),
                    ),
              child: Text(
                letter,
                style: GoogleFonts.nunito(
                  color: Colors.transparent,
                  fontSize: word.length > 11 ? 34 : 50,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(1.5, 0),
                    ),
                    Shadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresentationLetterPair extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;

  const _PresentationLetterPair({
    required this.letter,
    this.color = const Color(0xFF416F61),
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PresentationOutlinedLetter(
            letter: letter.toUpperCase(),
            size: size,
            color: color,
          ),
          SizedBox(width: size * .12),
          _PresentationOutlinedLetter(
            letter: letter.toLowerCase(),
            size: size,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _PresentationOutlinedLetter extends StatelessWidget {
  final String letter;
  final double size;
  final Color color;

  const _PresentationOutlinedLetter({
    required this.letter,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.nunito(
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    );
    return Stack(
      children: [
        Text(
          letter,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = Colors.white,
          ),
        ),
        Text(
          letter,
          style: style.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresentationSpeakerHint extends StatelessWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final double size;
  final bool showFinger;
  final Animation<double> tapScale;
  final Animation<Offset> tapOffset;
  final VoidCallback onTap;

  const _PresentationSpeakerHint({
    required this.size,
    required this.showFinger,
    required this.tapScale,
    required this.tapOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size * .86,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Image.asset(
              '$_assetBase/speaker.png',
              width: size * .58,
              height: size * .58,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(
                width: size * .58,
                height: size * .58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: TudloColors.green,
                  size: size * .32,
                ),
              ),
            ),
            if (showFinger)
              Positioned(
                right: 0,
                bottom: -size * .04,
                child: AnimatedBuilder(
                  animation: tapScale,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: tapOffset.value,
                      child: Transform.scale(
                        scale: tapScale.value,
                        alignment: Alignment.topLeft,
                        child: child,
                      ),
                    );
                  },
                  child: Transform.rotate(
                    angle: -.35,
                    child: Image.asset(
                      '$_assetBase/point-finger.png',
                      width: size * .56,
                      height: size * .56,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresentationSyllablePractice extends StatefulWidget {
  final List<String> syllables;
  final String fullWord;

  const _PresentationSyllablePractice({
    required this.syllables,
    required this.fullWord,
  });

  @override
  State<_PresentationSyllablePractice> createState() =>
      _PresentationSyllablePracticeState();
}

class _PresentationSyllablePracticeState
    extends State<_PresentationSyllablePractice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleController;
  int _nextIndex = 0;
  int? _wrongIndex;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  Future<void> _tapSyllable(int index) async {
    if (index != _nextIndex) {
      setState(() => _wrongIndex = index);
      _wiggleController.forward(from: 0);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Pindoton ang ${widget.syllables[_nextIndex]} anay.',
        hiligaynon: true,
      );
      return;
    }

    final syllable = widget.syllables[index];
    unawaited(AppAudioService.instance.playSyllableTap());
    setState(() {
      _wrongIndex = null;
      _nextIndex = (_nextIndex + 1).clamp(0, widget.syllables.length);
    });
    await TudloVoiceButton.speak(
      context,
      _titleCase(syllable),
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_nextIndex >= widget.syllables.length) {
      await TudloVoiceButton.speak(context, widget.fullWord, hiligaynon: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < widget.syllables.length; index++) ...[
          Expanded(child: _buildSyllable(index)),
          if (index < widget.syllables.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildSyllable(int index) {
    final selected = index < _nextIndex;
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _tapSyllable(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? TudloColors.green
                : Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .40),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            widget.syllables[index],
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: selected ? Colors.white : TudloColors.ink,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );

    if (_wrongIndex != index) return card;
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        final dx = math.sin(_wiggleController.value * math.pi * 4) * 5;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: card,
    );
  }
}

class _PresentationAssetArt extends StatelessWidget {
  final _AlphabetPresentationTarget target;
  final double size;
  final double? maxWidth;

  const _PresentationAssetArt({
    required this.target,
    required this.size,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (target.imageAssets.length > 1) {
      final pairWidth = math.min(size * 1.18, maxWidth ?? size * 1.18);
      final imageWidth = pairWidth * .55;
      final sideInset = pairWidth * .035;
      return SizedBox(
        width: pairWidth,
        height: size * 1.08,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.bottomCenter,
          children: [
            for (var index = 0; index < target.imageAssets.length; index++)
              Positioned(
                left: index == 0 ? sideInset : null,
                right: index == 0 ? null : sideInset,
                bottom: 0,
                child: Image.asset(
                  target.imageAssets[index],
                  width: imageWidth,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(target.icon, color: Colors.white, size: size * .55),
                ),
              ),
          ],
        ),
      );
    }
    if (target.imageAssets.isEmpty) {
      return Icon(target.icon, color: Colors.white, size: size * .72);
    }
    return Image.asset(
      target.imageAssets.first,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          Icon(target.icon, color: Colors.white, size: size * .72),
    );
  }
}

class _QuizTimeSplash extends StatefulWidget {
  static const _assetBase = 'assets/images/level_game/lesson-game-assets';

  final double progress;
  final VoidCallback onDone;

  const _QuizTimeSplash({this.progress = 0, required this.onDone});

  @override
  State<_QuizTimeSplash> createState() => _QuizTimeSplashState();
}

class _QuizTimeSplashState extends State<_QuizTimeSplash> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final safeTop = MediaQuery.paddingOf(context).top;
        final topButtonSize = math
            .min(width * .14, height * .075)
            .clamp(48.0, 66.0)
            .toDouble();
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                '${_QuizTimeSplash._assetBase}/levelgame-bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                left: width * .06,
                top: safeTop + height * .025,
                child: _PresentationImageButton(
                  asset: '${_QuizTimeSplash._assetBase}/exit-page.png',
                  size: topButtonSize,
                  onTap: () => unawaited(_exitLessonFromContext(context)),
                  tooltip: 'Balik',
                ),
              ),
              Positioned(
                left: width * .28,
                right: width * .27,
                top: safeTop + height * .045,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.progress.clamp(0, 1).toDouble(),
                    minHeight: (height * .023).clamp(16.0, 24.0),
                    backgroundColor: Colors.white,
                    color: TudloColors.green,
                  ),
                ),
              ),
              Positioned(
                right: width * .055,
                top: safeTop + height * .026,
                child: Transform.scale(
                  scale: .78,
                  alignment: Alignment.topRight,
                  child: const EnergyIndicator(),
                ),
              ),
              Positioned(
                left: width * .10,
                right: width * .10,
                top: height * .31,
                child: Text(
                  'Oras na sang Pagtilaw!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: (width * .082).clamp(30.0, 46.0),
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF459B27),
                        blurRadius: 0,
                        offset: Offset(2, 2),
                      ),
                      Shadow(color: Colors.white, blurRadius: 1),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: height * .39,
                child: Center(
                  child: TudloMascot(
                    size: (width * .62).clamp(230.0, 330.0),
                    mood: KokaMood.hi,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlphabetLetterIntroCard extends StatefulWidget {
  final String letter;
  final _AlphabetAnchor anchor;
  final VoidCallback onDone;

  const _AlphabetLetterIntroCard({
    required this.letter,
    required this.anchor,
    required this.onDone,
  });

  @override
  State<_AlphabetLetterIntroCard> createState() =>
      _AlphabetLetterIntroCardState();
}

class _AlphabetLetterIntroCardState extends State<_AlphabetLetterIntroCard> {
  bool _revealed = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Pamatii ang tingog sang ${widget.letter.toUpperCase()}. Pindoton ang ${widget.letter.toUpperCase()}.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleTap() async {
    if (_done) return;
    setState(() => _revealed = true);
    await TudloVoiceButton.speak(
      context,
      '${_letterSoundText(widget.letter)}... ${widget.letter}! May ${widget.letter} sa ${widget.anchor.word}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    _done = true;
    Future<void>.delayed(const Duration(milliseconds: 1050), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter.toUpperCase();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final stageHeight = screenHeight.clamp(620.0, 760.0);
    final mainLetterTop = (stageHeight * .16).clamp(88.0, 126.0).toDouble();
    final bubbleTop = (stageHeight - 285).clamp(398.0, 490.0).toDouble();
    final revealedWordTop = (stageHeight * .22).clamp(146.0, 172.0).toDouble();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: SizedBox(
          height: stageHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: _revealed ? 18 : mainLetterTop,
                child: Center(
                  child: IgnorePointer(
                    ignoring: _revealed,
                    child: GestureDetector(
                      onTap: _handleTap,
                      child: _IntroLetterBounce(
                        active: !_revealed,
                        glow: true,
                        child: _IntroLetterArt(
                          letter: letter,
                          size: _revealed ? 132 : 282,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: revealedWordTop,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: _revealed
                      ? Column(
                          key: const ValueKey('word'),
                          children: [
                            _HighlightedAlphabetWord(
                              word: widget.anchor.word,
                              highlightLetter: letter,
                              letterSize: 104,
                            ),
                            const SizedBox(height: 18),
                            _AlphabetAnchorImage(
                              imageAsset: widget.anchor.imageAsset,
                              icon: widget.anchor.icon,
                              word: _titleCase(widget.anchor.word),
                              meaning: widget.anchor.meaning,
                              voiceMessage: widget.anchor.word,
                              compact: true,
                              height: 176,
                              showVoiceButton: false,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
              Positioned(
                right: -26,
                top: bubbleTop,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(
                    message: _revealed
                        ? 'Koka: May $letter sa ${widget.anchor.word}!'
                        : 'Koka: Pamatii ang tingog. Pindoton ang $letter.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroLetterBounce extends StatelessWidget {
  final bool active;
  final bool glow;
  final Widget child;

  const _IntroLetterBounce({
    required this.active,
    required this.glow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final jump = active ? -math.sin(value * math.pi * 2) * 10 : 0.0;
        return Transform.translate(
          offset: Offset(0, jump),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .36),
                        blurRadius: 42,
                        spreadRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _IntroLetterArt extends StatelessWidget {
  final String letter;
  final double size;

  const _IntroLetterArt({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = const {
      'A': 'assets/images/level_game/letters/A.png',
      'B': 'assets/images/level_game/letters/B.png',
      'C': 'assets/images/level_game/letters/C.png',
      'D': 'assets/images/level_game/letters/D.png',
      'E': 'assets/images/level_game/letters/E.png',
      'F': 'assets/images/level_game/letters/F.png',
      'G': 'assets/images/level_game/letters/G.png',
      'H': 'assets/images/level_game/letters/H.png',
      'I': 'assets/images/level_game/letters/I.png',
      'K': 'assets/images/level_game/letters/K.png',
      'L': 'assets/images/level_game/letters/L.png',
      'M': 'assets/images/level_game/letters/M.png',
      'N': 'assets/images/level_game/letters/N.png',
      'O': 'assets/images/level_game/letters/O.png',
      'P': 'assets/images/level_game/letters/P-stage.png',
      'R': 'assets/images/level_game/letters/R.png',
      'S': 'assets/images/level_game/letters/S.png',
      'T': 'assets/images/level_game/letters/T.png',
      'U': 'assets/images/level_game/letters/U.png',
      'W': 'assets/images/level_game/letters/W.png',
      'Y': 'assets/images/level_game/letters/Y.png',
    }[letter.toUpperCase()];
    if (asset == null) {
      return Text(
        letter,
        style: TextStyle(
          color: TudloColors.blue,
          fontSize: size * .72,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _HighlightedAlphabetWord extends StatelessWidget {
  final String word;
  final String highlightLetter;
  final double letterSize;

  const _HighlightedAlphabetWord({
    required this.word,
    required this.highlightLetter,
    this.letterSize = 82,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final letter in letters) ...[
            SizedBox(
              width: letterSize * .64,
              height: letterSize,
              child: OverflowBox(
                minWidth: 0,
                maxWidth: letterSize,
                minHeight: 0,
                maxHeight: letterSize,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 360),
                  decoration: BoxDecoration(
                    boxShadow: letter.toUpperCase() == highlightLetter
                        ? [
                            BoxShadow(
                              color: TudloColors.green.withValues(alpha: .52),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: _IntroLetterArt(letter: letter, size: letterSize),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlphabetMascotBubble extends StatelessWidget {
  final String message;
  final double scale;

  const _AlphabetMascotBubble({required this.message, this.scale = 1});

  String get _cleanMessage =>
      message.replaceFirst(RegExp(r'^\s*Koka:\s*'), '').trim();

  @override
  Widget build(BuildContext context) {
    final width = 386.0 * scale;
    final height = 260.0 * scale;
    final bubbleWidth = 286.0 * scale;
    final bubbleHeight = 176.0 * scale;
    final mascotSize = 198.0 * scale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 90 * scale,
            top: 0,
            child: SizedBox(
              width: bubbleWidth,
              height: bubbleHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      TudloDialogueAssets.speechBubble,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      28 * scale,
                      22 * scale,
                      28 * scale,
                      40 * scale,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Text(
                              _cleanMessage,
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              style: TextStyle(
                                color: TudloColors.ink,
                                fontSize: 19 * scale,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: TudloMascot(
              size: mascotSize,
              mood: _messageLooksLikeRetry ? KokaMood.annoyed : KokaMood.hi,
            ),
          ),
        ],
      ),
    );
  }

  bool get _messageLooksLikeRetry {
    final message = _cleanMessage.toLowerCase();
    return message.contains('sulayi liwat') ||
        message.contains('suliton liwat') ||
        message.contains('liwata') ||
        message.contains('indi husto');
  }
}

class _AlphabetAnchorImage extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;
  final String word;
  final String meaning;
  final String voiceMessage;
  final bool compact;
  final double? height;
  final bool showVoiceButton;

  const _AlphabetAnchorImage({
    required this.imageAsset,
    required this.icon,
    required this.word,
    required this.meaning,
    required this.voiceMessage,
    this.compact = false,
    this.height,
    this.showVoiceButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? (compact ? 236 : 352),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: imageAsset == null
                ? _AlphabetIconArt(icon: icon)
                : Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => _AlphabetIconArt(icon: icon),
                  ),
          ),
          if (showVoiceButton) ...[
            const SizedBox(height: 8),
            TudloVoiceButton(
              message: voiceMessage,
              tooltip: 'Pamatii ang tingog',
              size: compact ? 60 : 70,
              hiligaynon: true,
              backgroundColor: Colors.white,
              foregroundColor: TudloColors.green,
            ),
          ],
        ],
      ),
    );
  }
}

class _AlphabetIconArt extends StatelessWidget {
  final IconData icon;

  const _AlphabetIconArt({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: TudloColors.forest, size: 74));
  }
}

class _GradeOneFamilyLesson extends StatefulWidget {
  final LevelContent content;
  final void Function(int index, bool correct) onQuizAttempt;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneFamilyLesson({
    required this.content,
    required this.onQuizAttempt,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneFamilyLesson> createState() => _GradeOneFamilyLessonState();
}

class _GradeOneFamilyLessonState extends State<_GradeOneFamilyLesson> {
  int _stepIndex = 0;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _familyWordsFor(widget.content.lessonNumber);
    var maxIndex = 0;
    final quizTargets = words.take(math.min(3, words.length)).toList();
    final nanay = words.firstWhere(
      (word) => word.hil == 'nanay',
      orElse: () => quizTargets.first,
    );
    final reviewTargets = quizTargets.take(2).toList();
    final useVisitorQuiz = widget.content.lessonNumber == 2;
    final usePhotoQuiz = widget.content.lessonNumber == 3;
    final quizCards = [
      _UnitOneTapChoiceActivity(
        key: ValueKey('family-warm-n-${widget.content.id}'),
        prompt: 'Tap the letter of nanay!',
        progress: 1 / _lessonQuizCount,
        choices: _shuffledChoices(const ['N', 'A', 'T']),
        answer: 'N',
        isLetter: true,
        imageAsset: nanay.imageAsset,
        icon: nanay.icon,
        onAttempt: (correct) => widget.onQuizAttempt(0, correct),
        onDone: () {
          widget.onQuizCorrect(0);
          _advanceAfterCorrect(maxIndex);
        },
      ),
      if (usePhotoQuiz)
        _FamilyPhotoQuizActivity(
          key: ValueKey('family-photo-${widget.content.id}'),
          progress: 2 / _lessonQuizCount,
          members: _familyPhotoTargets(words),
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onCorrect: () {
            widget.onQuizCorrect(1);
            _advanceAfterCorrect(maxIndex);
          },
        )
      else if (useVisitorQuiz)
        _FamilyVisitorDoorQuizActivity(
          key: ValueKey('family-visitors-${widget.content.id}'),
          progress: 2 / _lessonQuizCount,
          visitors: _familyVisitorTargets(words),
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onCorrect: () {
            widget.onQuizCorrect(1);
            _advanceAfterCorrect(maxIndex);
          },
        )
      else
        _FamilyHouseWindowQuizActivity(
          key: ValueKey('family-house-${widget.content.id}'),
          progress: 2 / _lessonQuizCount,
          members: _familyHouseTargets(words),
          onAttempt: (correct) => widget.onQuizAttempt(1, correct),
          onCorrect: () {
            widget.onQuizCorrect(1);
            _advanceAfterCorrect(maxIndex);
          },
        ),
      for (var index = 0; index < reviewTargets.length; index++)
        _FamilyQuizCard(
          key: ValueKey(
            'family-quiz-${widget.content.id}-${reviewTargets[index].hil}',
          ),
          target: reviewTargets[index],
          choices: _familyChoicesFor(reviewTargets[index], words, 3),
          onAttempt: (correct) => widget.onQuizAttempt(index + 2, correct),
          onCorrect: () {
            widget.onQuizCorrect(index + 2);
            _advanceAfterCorrect(maxIndex);
          },
        ),
    ];

    final steps = [
      _AlphabetFadeStep(
        child: _FamilyExploreCard(
          key: ValueKey('family-explore-${widget.content.id}'),
          words: quizTargets,
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      for (var index = 0; index < words.length; index++)
        _AlphabetFadeStep(
          child: _FamilyWordLessonCard(
            key: ValueKey(
              'family-lesson-${widget.content.id}-${words[index].hil}',
            ),
            word: words[index],
            canGoBack: index > 0,
            onBack: () => _goToStep(_stepIndex - 1, maxIndex),
            onNext: () => _goToStep(_stepIndex + 1, maxIndex),
          ),
        ),
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizCards) _AlphabetFadeStep(child: card),
      _AlphabetFadeStep(
        child: _FamilyMatchingCard(
          key: ValueKey('family-match-${widget.content.id}'),
          words: quizTargets,
          onAttempt: (word, correct) {
            widget.onQuizAttempt(4, correct);
          },
          onCorrect: () {
            widget.onQuizCorrect(4);
          },
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('family-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FamilyWord {
  final String hil;
  final String eng;
  final String imageAsset;
  final IconData icon;

  const _FamilyWord({
    required this.hil,
    required this.eng,
    required this.imageAsset,
    required this.icon,
  });
}

class _FamilyExploreCard extends StatefulWidget {
  final List<_FamilyWord> words;
  final VoidCallback onDone;

  const _FamilyExploreCard({
    super.key,
    required this.words,
    required this.onDone,
  });

  @override
  State<_FamilyExploreCard> createState() => _FamilyExploreCardState();
}

class _FamilyExploreCardState extends State<_FamilyExploreCard> {
  final Set<String> _tapped = {};
  String _message = 'Koka: Tan-awa ang pamilya. Pindoton sila.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Tan-awa ang pamilya. Pindoton sila.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapWord(_FamilyWord word) async {
    if (_reported) return;
    setState(() {
      _tapped.add(word.hil);
      _message = 'Koka: ${_titleCase(word.hil)}... ${_titleCase(word.eng)}.';
    });
    await TudloVoiceButton.speak(
      context,
      '${word.hil}... ${word.eng}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_tapped.length >= widget.words.length && !_reported) {
      _reported = true;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _message,
      child: SizedBox(
        height: 520,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Opacity(
                opacity: .42,
                child: Image.asset(
                  'assets/images/level_game/house.png',
                  width: 330,
                  height: 240,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.home_rounded,
                    color: TudloColors.forest.withValues(alpha: .32),
                    size: 160,
                  ),
                ),
              ),
            ),
            for (var index = 0; index < widget.words.length; index++)
              Positioned(
                left: _familyExploreOffset(index, widget.words.length).dx,
                top: _familyExploreOffset(index, widget.words.length).dy,
                child: _FamilyExplorePerson(
                  word: widget.words[index],
                  tapped: _tapped.contains(widget.words[index].hil),
                  onTap: () => _tapWord(widget.words[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _familyExploreOffset(int index, int count) {
    if (count <= 2) {
      return index == 0 ? const Offset(42, 210) : const Offset(198, 210);
    }
    return switch (index) {
      0 => const Offset(6, 210),
      1 => const Offset(128, 190),
      _ => const Offset(250, 214),
    };
  }
}

class _FamilyExplorePerson extends StatelessWidget {
  final _FamilyWord word;
  final bool tapped;
  final VoidCallback onTap;

  const _FamilyExplorePerson({
    required this.word,
    required this.tapped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 126,
        height: 218,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: tapped
                  ? Container(
                      key: ValueKey('name-${word.hil}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: TudloColors.green, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: TudloColors.forest.withValues(alpha: .16),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        _titleCase(word.hil),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 19,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty-name'), height: 41),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: tapped ? 1.08 : 1,
              child: Container(
                width: 126,
                height: 169,
                decoration: BoxDecoration(
                  boxShadow: tapped
                      ? [
                          BoxShadow(
                            color: TudloColors.green.withValues(alpha: .36),
                            blurRadius: 28,
                            spreadRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Image.asset(
                  word.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(word.icon, color: TudloColors.forest, size: 96),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeOneHelperLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneHelperLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneHelperLesson> createState() => _GradeOneHelperLessonState();
}

class _GradeOneHelperLessonState extends State<_GradeOneHelperLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpers = _helpersForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final allHelpers = _helpersForLesson(4);
    final helperByHil = {for (final helper in allHelpers) helper.hil: helper};
    final quizCards = _helperQuizCardsForLesson(
      lessonNumber: widget.content.lessonNumber,
      helpers: helpers,
      helperByHil: helperByHil,
      onQuizDone: (index) {
        widget.onQuizCorrect(index);
        _advanceAfterCorrect(maxIndex);
      },
      onLessonDone: _markComplete,
    );
    final steps = [
      for (final helper in helpers) ...[
        _AlphabetFadeStep(
          child: _HelperTapCard(
            key: ValueKey('helper-tap-${widget.content.id}-${helper.hil}'),
            helper: helper,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _HelperWorkplaceDragCard(
            key: ValueKey('helper-work-${widget.content.id}-${helper.hil}'),
            helper: helper,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _HelperToolDragCard(
            key: ValueKey('helper-tool-${widget.content.id}-${helper.hil}'),
            helper: helper,
            choices: _toolChoicesFor(helper, helpers),
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      for (final card in quizCards) _AlphabetFadeStep(child: card),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('helper-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HelperWord {
  final String hil;
  final String eng;
  final String tapSpeech;
  final String workplaceLabel;
  final String workplaceSpeech;
  final String imageAsset;
  final String? workplaceAsset;
  final _HelperTool tool;
  final IconData icon;
  final IconData workplaceIcon;
  final Color color;

  const _HelperWord({
    required this.hil,
    required this.eng,
    required this.tapSpeech,
    required this.workplaceLabel,
    required this.workplaceSpeech,
    required this.imageAsset,
    required this.tool,
    required this.icon,
    required this.workplaceIcon,
    required this.color,
    this.workplaceAsset,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get workplaceInstruction =>
      'Guyoda ang $hil pakadto sa $workplaceLabel.';
  String get retryWorkplace =>
      'Liwata. Guyoda ang $hil pakadto sa $workplaceLabel.';
  String get toolInstruction => 'Guyoda ang gamit pakadto sa $hil.';
  String get toolSuccess => 'Husto! Ang $hil nagagamit sang ${tool.hil}.';
}

class _HelperTool {
  final String hil;
  final IconData icon;
  final Color color;
  final String? imageAsset;

  const _HelperTool({
    required this.hil,
    required this.icon,
    required this.color,
    this.imageAsset,
  });
}

class _HelperTapCard extends StatefulWidget {
  final _HelperWord helper;
  final VoidCallback onDone;

  const _HelperTapCard({super.key, required this.helper, required this.onDone});

  @override
  State<_HelperTapCard> createState() => _HelperTapCardState();
}

class _HelperTapCardState extends State<_HelperTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.helper.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapHelper() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.helper.tool.hil}! ${widget.helper.tapSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? widget.helper.tapSpeech
          : 'Koka: ${widget.helper.tapInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 36 : 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _tapHelper,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (_tapped)
                    Positioned(
                      right: -16,
                      top: 16,
                      child: _ToolArt(tool: widget.helper.tool, size: 92),
                    ),
                  _HelperArt(helper: widget.helper, size: 330),
                  if (_tapped) const _AnimalSparkles(size: 370),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelperWorkplaceDragCard extends StatefulWidget {
  final _HelperWord helper;
  final VoidCallback onDone;

  const _HelperWorkplaceDragCard({
    super.key,
    required this.helper,
    required this.onDone,
  });

  @override
  State<_HelperWorkplaceDragCard> createState() =>
      _HelperWorkplaceDragCardState();
}

class _HelperWorkplaceDragCardState extends State<_HelperWorkplaceDragCard> {
  bool _placed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.helper.workplaceInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_placed) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        widget.helper.retryWorkplace,
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _accept() async {
    if (_placed) return;
    setState(() => _placed = true);
    await TudloVoiceButton.speak(
      context,
      widget.helper.workplaceSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _placed
          ? 'Koka: ${widget.helper.workplaceSpeech}'
          : _retrying
          ? 'Koka: ${widget.helper.retryWorkplace}'
          : 'Koka: ${widget.helper.workplaceInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 445,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -8,
                  top: 18,
                  child: _HelperWorkplaceTarget(
                    helper: widget.helper,
                    size: 260,
                    placed: _placed,
                    onAccept: _accept,
                    onWrongDrop: _retry,
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: 18,
                  child: _placed
                      ? const SizedBox(width: 238, height: 238)
                      : _HelperDraggable(
                          helper: widget.helper,
                          size: 238,
                          onMissed: _retry,
                        ),
                ),
                if (_placed)
                  Positioned(
                    right: 50,
                    top: 104,
                    child: _AnimalBounce(
                      active: true,
                      child: _HelperArt(helper: widget.helper, size: 144),
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

class _HelperToolDragCard extends StatefulWidget {
  final _HelperWord helper;
  final List<_HelperTool> choices;
  final VoidCallback onDone;

  const _HelperToolDragCard({
    super.key,
    required this.helper,
    required this.choices,
    required this.onDone,
  });

  @override
  State<_HelperToolDragCard> createState() => _HelperToolDragCardState();
}

class _HelperToolDragCardState extends State<_HelperToolDragCard> {
  bool _matched = false;
  bool _retrying = false;

  void _retry() {
    if (_matched) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Liwata. Guyoda ang sakto nga gamit pakadto sa ${widget.helper.hil}.',
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _acceptTool(_HelperTool tool) async {
    if (_matched) return;
    if (tool.hil != widget.helper.tool.hil) {
      _retry();
      return;
    }
    setState(() => _matched = true);
    await TudloVoiceButton.speak(
      context,
      widget.helper.toolSuccess,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _matched
          ? 'Koka: ${widget.helper.toolSuccess}'
          : _retrying
          ? 'Koka: Liwata. Pangitaa ang sakto nga gamit.'
          : 'Koka: ${widget.helper.toolInstruction}',
      child: Column(
        children: [
          Text(
            widget.helper.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.helper.upperName.length > 9 ? 34 : 40,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          DragTarget<_HelperTool>(
            onWillAcceptWithDetails: (_) => !_matched,
            onAcceptWithDetails: (details) => _acceptTool(details.data),
            builder: (context, candidates, rejected) {
              return SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _HelperArt(helper: widget.helper, size: 236),
                    if (candidates.isNotEmpty || _matched)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: TudloColors.green.withValues(alpha: .32),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_matched)
                      Positioned(
                        right: 6,
                        bottom: 0,
                        child: _ToolArt(tool: widget.helper.tool, size: 88),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final tool in widget.choices)
                _matched && tool.hil == widget.helper.tool.hil
                    ? const SizedBox(width: 102, height: 102)
                    : _ToolDraggable(tool: tool, size: 102, onMissed: _retry),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelperReviewCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final VoidCallback onDone;

  const _HelperReviewCard({required this.helpers, required this.onDone});

  @override
  State<_HelperReviewCard> createState() => _HelperReviewCardState();
}

class _HelperReviewCardState extends State<_HelperReviewCard> {
  final Set<String> _matched = {};
  String _message =
      'Koka: Guyoda ang kada community helper pakadto sa ila ginatrabahuan.';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang kada community helper pakadto sa ila ginatrabahuan.',
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _handleDrop(_HelperWord target, _HelperWord dragged) async {
    if (_reported || _matched.contains(dragged.hil)) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;

    if (target.hil != dragged.hil) {
      setState(() {
        _message =
            'Koka: Liwata. Pangitaa ang ginatrabahuan sang ${dragged.hil}.';
      });
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pangitaa ang ginatrabahuan sang ${dragged.hil}.',
        hiligaynon: true,
      );
      return;
    }
    setState(() {
      _matched.add(dragged.hil);
      _message = 'Koka: Husto! ${_titleCase(dragged.hil)}.';
    });
    await TudloVoiceButton.speak(
      context,
      dragged.workplaceSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_matched.length == widget.helpers.length && !_reported) {
      _reported = true;
      setState(() {
        _message =
            'Koka: Maayo gid! Kabalo ka na sang mga community helpers kag ila ginahimo!';
      });
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Kabalo ka na sang mga community helpers kag ila ginahimo!',
        hiligaynon: true,
      );
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _message,
      child: Column(
        children: [
          Text(
            'Ipares ang Trabaho',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemCount = widget.helpers.length;
              final gap = itemCount > 2 ? 8.0 : 16.0;
              final itemSize = itemCount == 0
                  ? 0.0
                  : math
                        .min(
                          126.0,
                          (constraints.maxWidth - gap * (itemCount - 1)) /
                              itemCount,
                        )
                        .clamp(0.0, 126.0)
                        .toDouble();
              final dragSize = math.min(126.0, itemSize);

              return Column(
                children: [
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final helper in widget.helpers)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _HelperReviewWorkplace(
                            helper: helper,
                            size: itemSize,
                            matched: _matched.contains(helper.hil),
                            onDrop: (dragged) => _handleDrop(helper, dragged),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final helper in widget.helpers)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _matched.contains(helper.hil)
                              ? SizedBox.square(dimension: dragSize)
                              : _HelperDraggable(
                                  helper: helper,
                                  size: dragSize,
                                  onMissed: () {
                                    setState(() {
                                      _message =
                                          'Koka: Guyoda ang ${helper.hil} pakadto sa iya ginatrabahuan.';
                                    });
                                  },
                                ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoryTapItem {
  final String id;
  final String label;
  final String imageAsset;
  final IconData icon;
  final Color color;
  final String instruction;
  final String successSpeech;

  const _StoryTapItem({
    required this.id,
    required this.label,
    required this.imageAsset,
    required this.icon,
    required this.color,
    required this.instruction,
    required this.successSpeech,
  });
}

List<Widget> _helperQuizCardsForLesson({
  required int lessonNumber,
  required List<_HelperWord> helpers,
  required Map<String, _HelperWord> helperByHil,
  required ValueChanged<int> onQuizDone,
  required VoidCallback onLessonDone,
}) {
  final teacher = helperByHil['manunudlo']!;
  final doctor = helperByHil['doktor']!;
  final nurse = helperByHil['nars']!;
  final police = helperByHil['pulis']!;
  final firefighter = helperByHil['bumbero']!;
  final vendor = helperByHil['tindera']!;
  final farmer = helperByHil['mangunguma']!;
  final fisher = helperByHil['mangingisda']!;

  switch (lessonNumber) {
    case 1:
      return [
        _HelperStoryTapQuizCard(
          key: const ValueKey('helper-story-sick-younger-sibling'),
          title: 'Nagmasakit ang manghod ni Koka!',
          progress: 1 / _lessonQuizCount,
          items: [
            _familyStoryItem(
              id: 'manghod',
              label: 'Manghod',
              imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
              icon: Icons.child_friendly_rounded,
              instruction: 'Ipindot ang manghod ni Koka.',
              successSpeech: 'Husto. Ara ang manghod ni Koka.',
            ),
            _helperStoryItem(
              doctor,
              instruction: 'Ipindot ang doktor para usisaon siya.',
              successSpeech: 'Husto. Gin-usisa siya sang doktor.',
            ),
            _helperStoryItem(
              nurse,
              instruction: 'Ipindot ang nars para sa bulong.',
              successSpeech: 'Husto. Ang nars naghatag sang bulong.',
            ),
            _helperStoryItem(
              teacher,
              instruction:
                  'Balik sa eskwelahan. Ipindot ang manunudlo nga nag-abot sa iya.',
              successSpeech:
                  'Husto. Ginbaton siya liwat sang manunudlo sa eskwelahan.',
            ),
          ],
          onDone: () {
            onQuizDone(0);
            onLessonDone();
          },
        ),
      ];
    case 2:
      return [
        _HelperStoryTapQuizCard(
          key: const ValueKey('helper-story-market-fire'),
          title: 'May kalayo sa tinda!',
          progress: 1 / _lessonQuizCount,
          showGentleFire: true,
          items: [
            _helperStoryItem(
              firefighter,
              instruction: 'Ipindot ang bumbero para mapatay ang kalayo.',
              successSpeech: 'Husto. Ginpatay sang bumbero ang kalayo.',
            ),
            _helperStoryItem(
              police,
              instruction: 'Ipindot ang pulis para magiya sang mga tawo.',
              successSpeech: 'Husto. Ginbuligan sang pulis ang mga tawo.',
            ),
            _helperStoryItem(
              vendor,
              instruction: 'Ipindot ang tindera para buksan liwat ang tinda.',
              successSpeech: 'Husto. Bukas na liwat ang tinda.',
            ),
            _helperStoryItem(
              teacher,
              instruction:
                  'Ipindot ang manunudlo para magsiling sang salamat ang klase.',
              successSpeech:
                  'Husto. Nagsiling ang klase, salamat sa mga helpers!',
            ),
          ],
          onDone: () => onQuizDone(0),
        ),
        _HelperToolSequenceQuizCard(
          key: const ValueKey('helper-tool-emergency-review'),
          progress: 2 / _lessonQuizCount,
          targets: [firefighter, police, vendor],
          onDone: () {
            onQuizDone(1);
            onLessonDone();
          },
        ),
      ];
    case 3:
      return [
        _HelperStoryTapQuizCard(
          key: const ValueKey('helper-story-food-chain'),
          title: 'Diin naghalin ang pagkaon ni Koka?',
          progress: 1 / _lessonQuizCount,
          items: [
            _helperStoryItem(
              farmer,
              instruction: 'Ipindot ang mangunguma. Halin sa iya ang humay.',
              successSpeech: 'Husto. Ang mangunguma nagatanom sang humay.',
            ),
            _helperStoryItem(
              fisher,
              instruction: 'Ipindot ang mangingisda. Halin sa iya ang isda.',
              successSpeech: 'Husto. Ang mangingisda nagakuha sang isda.',
            ),
            _helperStoryItem(
              vendor,
              instruction: 'Ipindot ang tindera. Ginabaligya niya ini.',
              successSpeech: 'Husto. Ang tindera nagabaligya sang pagkaon.',
            ),
            _familyStoryItem(
              id: 'nanay',
              label: 'Nanay',
              imageAsset: 'assets/images/level_game/people/nanay.png',
              icon: Icons.face_3_rounded,
              instruction:
                  'Ipindot si nanay. Siya nagaluto kag nagakaon ang pamilya.',
              successSpeech: 'Husto. Nagluto si nanay para sa pamilya.',
            ),
          ],
          onDone: () {
            onQuizDone(0);
            onLessonDone();
          },
        ),
      ];
    default:
      return [
        _HelperFastReviewQuizCard(
          key: const ValueKey('helper-fast-review'),
          helpers: _shuffledChoices(helperByHil.values).take(8).toList(),
          progress: 1 / _lessonQuizCount,
          onDone: () => onQuizDone(0),
        ),
        _HelperParadeQuizCard(
          key: const ValueKey('helper-thank-you-parade'),
          helpers: _shuffledChoices(helperByHil.values).take(8).toList(),
          progress: 1,
          onDone: () {
            onQuizDone(1);
            onLessonDone();
          },
        ),
      ];
  }
}

_StoryTapItem _helperStoryItem(
  _HelperWord helper, {
  required String instruction,
  required String successSpeech,
}) {
  return _StoryTapItem(
    id: helper.hil,
    label: _titleCase(helper.hil),
    imageAsset: helper.imageAsset,
    icon: helper.icon,
    color: helper.color,
    instruction: instruction,
    successSpeech: successSpeech,
  );
}

_StoryTapItem _familyStoryItem({
  required String id,
  required String label,
  required String imageAsset,
  required IconData icon,
  required String instruction,
  required String successSpeech,
}) {
  return _StoryTapItem(
    id: id,
    label: label,
    imageAsset: imageAsset,
    icon: icon,
    color: TudloColors.green,
    instruction: instruction,
    successSpeech: successSpeech,
  );
}

class _HelperStoryTapQuizCard extends StatefulWidget {
  final String title;
  final double progress;
  final List<_StoryTapItem> items;
  final bool showGentleFire;
  final VoidCallback onDone;

  const _HelperStoryTapQuizCard({
    super.key,
    required this.title,
    required this.progress,
    required this.items,
    required this.onDone,
    this.showGentleFire = false,
  });

  @override
  State<_HelperStoryTapQuizCard> createState() =>
      _HelperStoryTapQuizCardState();
}

class _HelperStoryTapQuizCardState extends State<_HelperStoryTapQuizCard> {
  final Set<String> _doneIds = {};
  int _targetIndex = 0;
  String? _wrongId;
  bool _completed = false;
  int _feedbackKey = 0;

  _StoryTapItem get _target =>
      widget.items[_targetIndex.clamp(0, math.max(0, widget.items.length - 1))];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.items.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _target.instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _tapItem(_StoryTapItem item) async {
    if (_completed || _doneIds.contains(item.id)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }

    final correct = item.id == _target.id;
    setState(() {
      _feedbackKey++;
      _wrongId = correct ? null : item.id;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. ${_target.instruction}',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_completed) setState(() => _wrongId = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _doneIds.add(item.id);
      if (_doneIds.length >= widget.items.length) {
        _completed = true;
      } else {
        _targetIndex++;
      }
    });
    await TudloVoiceButton.speak(
      context,
      item.successSpeech,
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_completed) {
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Natapos ang estorya.',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (mounted) widget.onDone();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _target.instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _completed ? 'Maayo gid!' : _target.instruction,
      progress: widget.progress,
      mascotMessage: _completed
          ? 'Koka: Husto tanan!'
          : 'Koka: ${widget.title}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemSize = (width * .30).clamp(86.0, 118.0);
          return Column(
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: (width * .065).clamp(22.0, 31.0),
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFF459B27), offset: Offset(2, 2)),
                  ],
                ),
              ),
              if (widget.showGentleFire) ...[
                const SizedBox(height: 6),
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: TudloColors.orange,
                  size: 46,
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item in widget.items)
                        _StoryTapTarget(
                          item: item,
                          size: itemSize,
                          done: _doneIds.contains(item.id),
                          wrong: _wrongId == item.id,
                          feedbackKey: _feedbackKey,
                          onTap: () => _tapItem(item),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryTapTarget extends StatelessWidget {
  final _StoryTapItem item;
  final double size;
  final bool done;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback onTap;

  const _StoryTapTarget({
    required this.item,
    required this.size,
    required this.done,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('story-${item.id}-$feedbackKey-$wrong'),
      correct: done,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size + 30,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: done
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(22),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .24),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(item.icon, color: item.color, size: size * .58),
                ),
              ),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFF459B27), offset: Offset(1.5, 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelperToolSequenceQuizCard extends StatefulWidget {
  final double progress;
  final List<_HelperWord> targets;
  final VoidCallback onDone;

  const _HelperToolSequenceQuizCard({
    super.key,
    required this.progress,
    required this.targets,
    required this.onDone,
  });

  @override
  State<_HelperToolSequenceQuizCard> createState() =>
      _HelperToolSequenceQuizCardState();
}

class _HelperToolSequenceQuizCardState
    extends State<_HelperToolSequenceQuizCard> {
  final Set<String> _matched = {};
  int _targetIndex = 0;
  _HelperTool? _wrongTool;
  bool _completed = false;

  _HelperWord get _target =>
      widget.targets[_targetIndex.clamp(
        0,
        math.max(0, widget.targets.length - 1),
      )];

  String get _instruction {
    if (_target.hil == 'pulis') {
      return 'Police officer. Pulis. Guyoda ang badge pakadto sa pulis.';
    }
    return 'Guyoda ang ${_target.tool.hil} pakadto sa ${_target.hil}.';
  }

  List<_HelperTool> get _tools =>
      _shuffledChoices(widget.targets.map((helper) => helper.tool));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.targets.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _acceptTool(_HelperTool tool, _HelperWord helper) async {
    if (_completed || _matched.contains(helper.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = helper.hil == _target.hil && tool.hil == helper.tool.hil;
    if (!correct) {
      setState(() => _wrongTool = tool);
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_completed) setState(() => _wrongTool = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _matched.add(helper.hil);
      if (_matched.length >= widget.targets.length) {
        _completed = true;
      } else {
        _targetIndex++;
      }
    });
    await TudloVoiceButton.speak(
      context,
      helper.toolSuccess,
      hiligaynon: true,
      waitForCompletion: true,
    );
    if (!mounted) return;
    if (_completed) {
      widget.onDone();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _instruction,
      progress: widget.progress,
      mascotMessage: 'Koka: Pamatia kag guyoda ang gamit.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final helperSize = (width * .26).clamp(76.0, 104.0);
          return Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final helper in widget.targets)
                      DragTarget<_HelperTool>(
                        onWillAcceptWithDetails: (_) =>
                            !_matched.contains(helper.hil),
                        onAcceptWithDetails: (details) =>
                            _acceptTool(details.data, helper),
                        builder: (context, candidates, rejected) {
                          return AnimatedScale(
                            duration: const Duration(milliseconds: 140),
                            scale: candidates.isNotEmpty ? 1.07 : 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HelperArt(helper: helper, size: helperSize),
                                const SizedBox(height: 4),
                                if (_matched.contains(helper.hil))
                                  _ToolArt(tool: helper.tool, size: 42),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (final tool in _tools)
                    if (!_matched.any(
                      (hil) =>
                          widget.targets
                              .firstWhere((helper) => helper.hil == hil)
                              .tool
                              .hil ==
                          tool.hil,
                    ))
                      _FeedbackMotion(
                        key: ValueKey(
                          'tool-seq-${tool.hil}-${_wrongTool == tool}',
                        ),
                        correct: false,
                        wrong: _wrongTool == tool,
                        child: _ToolDraggable(
                          tool: tool,
                          size: 86,
                          onMissed: () => unawaited(
                            TudloVoiceButton.speak(
                              context,
                              _instruction,
                              hiligaynon: true,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelperFastReviewQuizCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final double progress;
  final VoidCallback onDone;

  const _HelperFastReviewQuizCard({
    super.key,
    required this.helpers,
    required this.progress,
    required this.onDone,
  });

  @override
  State<_HelperFastReviewQuizCard> createState() =>
      _HelperFastReviewQuizCardState();
}

class _HelperFastReviewQuizCardState extends State<_HelperFastReviewQuizCard> {
  late final List<_HelperWord> _trials = [
    ..._shuffledChoices(widget.helpers),
    ..._shuffledChoices(widget.helpers),
  ].take(10).toList();
  int _index = 0;
  String? _wrongHil;
  bool _completed = false;
  int _feedbackKey = 0;

  _HelperWord get _target =>
      _trials[_index.clamp(0, math.max(0, _trials.length - 1))];

  String get _instruction => _index.isEven
      ? 'Ipindot ang ${_target.hil}.'
      : 'Ipindot ang helper nga may ${_target.tool.hil}.';

  List<_HelperWord> get _choices {
    final choices = <_HelperWord>[_target];
    for (final helper in _shuffledChoices(widget.helpers)) {
      if (choices.length >= 3) break;
      if (!choices.any((choice) => choice.hil == helper.hil)) {
        choices.add(helper);
      }
    }
    return _shuffledChoices(choices);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _trials.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _tapChoice(_HelperWord helper) async {
    if (_completed) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = helper.hil == _target.hil;
    setState(() {
      _feedbackKey++;
      _wrongHil = correct ? null : helper.hil;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_completed) setState(() => _wrongHil = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    if (_index >= _trials.length - 1) {
      setState(() => _completed = true);
      widget.onDone();
      return;
    }
    setState(() => _index++);
    unawaited(TudloVoiceButton.speak(context, _instruction, hiligaynon: true));
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _instruction,
      progress: widget.progress,
      mascotMessage: 'Koka: Dali nga pagtilaw!',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final choices = _choices;
          return Column(
            children: [
              Text(
                '${_index + 1} / ${_trials.length}',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFF459B27), offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_index.isOdd)
                _ToolArt(tool: _target.tool, size: 96)
              else
                Text(
                  _titleCase(_target.hil),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0xFF459B27), offset: Offset(2, 2)),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final helper in choices)
                        _FeedbackMotion(
                          key: ValueKey(
                            'fast-${helper.hil}-$_feedbackKey-${_wrongHil == helper.hil}',
                          ),
                          correct: false,
                          wrong: _wrongHil == helper.hil,
                          child: GestureDetector(
                            onTap: () => _tapChoice(helper),
                            child: _HelperArt(
                              helper: helper,
                              size: (width * .27).clamp(86.0, 116.0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelperParadeQuizCard extends StatefulWidget {
  final List<_HelperWord> helpers;
  final double progress;
  final VoidCallback onDone;

  const _HelperParadeQuizCard({
    super.key,
    required this.helpers,
    required this.progress,
    required this.onDone,
  });

  @override
  State<_HelperParadeQuizCard> createState() => _HelperParadeQuizCardState();
}

class _HelperParadeQuizCardState extends State<_HelperParadeQuizCard> {
  final Set<String> _joined = {};
  int _targetIndex = 0;
  String? _wrongHil;
  bool _completed = false;
  int _feedbackKey = 0;

  _HelperWord get _target =>
      widget.helpers[_targetIndex.clamp(
        0,
        math.max(0, widget.helpers.length - 1),
      )];

  String get _instruction =>
      'Salamat parade! Ipindot ang ${_target.hil} para magsulod sa linya.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.helpers.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _tapHelper(_HelperWord helper) async {
    if (_completed || _joined.contains(helper.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = helper.hil == _target.hil;
    setState(() {
      _feedbackKey++;
      _wrongHil = correct ? null : helper.hil;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_completed) setState(() => _wrongHil = null);
      });
      return;
    }
    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _joined.add(helper.hil);
      if (_joined.length >= widget.helpers.length) {
        _completed = true;
      } else {
        _targetIndex++;
      }
    });
    if (_completed) {
      await TudloVoiceButton.speak(
        context,
        'Salamat sa tanan nga helpers!',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (mounted) widget.onDone();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: _instruction,
      progress: widget.progress,
      mascotMessage: 'Koka: Tawga ang kada helper sa parade.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemSize = (width * .21).clamp(64.0, 86.0);
          return Column(
            children: [
              SizedBox(
                height: 98,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final helper in widget.helpers)
                      if (_joined.contains(helper.hil))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _HelperArt(helper: helper, size: 46),
                        ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final helper in widget.helpers)
                        if (!_joined.contains(helper.hil))
                          _FeedbackMotion(
                            key: ValueKey(
                              'parade-${helper.hil}-$_feedbackKey-${_wrongHil == helper.hil}',
                            ),
                            correct: false,
                            wrong: _wrongHil == helper.hil,
                            child: GestureDetector(
                              onTap: () => _tapHelper(helper),
                              child: _HelperArt(helper: helper, size: itemSize),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelperDraggable extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final VoidCallback onMissed;

  const _HelperDraggable({
    required this.helper,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_HelperWord>(
      data: helper,
      feedback: Material(
        color: Colors.transparent,
        child: _HelperArt(helper: helper, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _HelperArt(helper: helper, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _HelperArt(helper: helper, size: size),
    );
  }
}

class _ToolDraggable extends StatelessWidget {
  final _HelperTool tool;
  final double size;
  final VoidCallback onMissed;

  const _ToolDraggable({
    required this.tool,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_HelperTool>(
      data: tool,
      feedback: Material(
        color: Colors.transparent,
        child: _ToolArt(tool: tool, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _ToolArt(tool: tool, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _ToolArt(tool: tool, size: size),
    );
  }
}

class _HelperWorkplaceTarget extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool placed;
  final VoidCallback onAccept;
  final VoidCallback onWrongDrop;

  const _HelperWorkplaceTarget({
    required this.helper,
    required this.size,
    required this.placed,
    required this.onAccept,
    required this.onWrongDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_HelperWord>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) {
        if (details.data.hil == helper.hil) {
          onAccept();
        } else {
          onWrongDrop();
        }
      },
      builder: (context, candidates, rejected) {
        return _HelperWorkplaceArt(
          helper: helper,
          size: size,
          active: candidates.isNotEmpty,
          matched: placed,
        );
      },
    );
  }
}

class _HelperReviewWorkplace extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool matched;
  final ValueChanged<_HelperWord> onDrop;

  const _HelperReviewWorkplace({
    required this.helper,
    required this.size,
    required this.matched,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_HelperWord>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) {
        return _HelperWorkplaceArt(
          helper: helper,
          size: size,
          active: candidates.isNotEmpty,
          matched: matched,
        );
      },
    );
  }
}

class _HelperArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperArt({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      helper.imageAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _HelperIconArt(helper: helper, size: size),
    );
  }
}

class _HelperIconArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperIconArt({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: helper.color.withValues(alpha: .16),
      ),
      child: Icon(helper.icon, color: helper.color, size: size * .58),
    );
  }
}

class _HelperWorkplaceArt extends StatelessWidget {
  final _HelperWord helper;
  final double size;
  final bool active;
  final bool matched;

  const _HelperWorkplaceArt({
    required this.helper,
    required this.size,
    required this.active,
    required this.matched,
  });

  @override
  Widget build(BuildContext context) {
    final workplace = helper.workplaceAsset == null
        ? _HelperWorkplaceIcon(helper: helper, size: size)
        : Image.asset(
            helper.workplaceAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _HelperWorkplaceIcon(helper: helper, size: size),
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        boxShadow: active || matched
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .24),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Center(child: workplace),
    );
  }
}

class _HelperWorkplaceIcon extends StatelessWidget {
  final _HelperWord helper;
  final double size;

  const _HelperWorkplaceIcon({required this.helper, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * .88,
      height: size * .88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TudloColors.softGreen.withValues(alpha: .82),
      ),
      child: Icon(
        helper.workplaceIcon,
        color: TudloColors.forest,
        size: size * .48,
      ),
    );
  }
}

class _ToolArt extends StatelessWidget {
  final _HelperTool tool;
  final double size;

  const _ToolArt({required this.tool, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tool.color.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: tool.color.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: tool.imageAsset == null
          ? Icon(tool.icon, color: tool.color, size: size * .54)
          : Padding(
              padding: EdgeInsets.all(size * .1),
              child: Image.asset(
                tool.imageAsset!,
                width: size * .8,
                height: size * .8,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    Icon(tool.icon, color: tool.color, size: size * .54),
              ),
            ),
    );
  }
}

List<_HelperTool> _toolChoicesFor(
  _HelperWord target,
  List<_HelperWord> helpers,
) {
  final tools = <_HelperTool>[target.tool];
  for (final helper in helpers) {
    if (helper.tool.hil != target.tool.hil) tools.add(helper.tool);
    if (tools.length == 3) break;
  }
  if (tools.length < 3) {
    for (final helper in _helpersForLesson(4)) {
      if (tools.any((tool) => tool.hil == helper.tool.hil)) continue;
      tools.add(helper.tool);
      if (tools.length == 3) break;
    }
  }
  return tools;
}

List<_HelperWord> _helpersForLesson(int lessonNumber) {
  const teacherTool = _HelperTool(
    hil: 'libro',
    icon: Icons.menu_book_rounded,
    color: TudloColors.blue,
    imageAsset: 'assets/images/level_game/book.png',
  );
  const doctorTool = _HelperTool(
    hil: 'stethoscope',
    icon: Icons.health_and_safety_rounded,
    color: TudloColors.coral,
    imageAsset: 'assets/images/level_game/stetoscope.png',
  );
  const nurseTool = _HelperTool(
    hil: 'thermometer',
    icon: Icons.thermostat_rounded,
    color: TudloColors.orange,
    imageAsset: 'assets/images/level_game/thermometer.png',
  );
  const policeTool = _HelperTool(
    hil: 'whistle',
    icon: Icons.campaign_rounded,
    color: TudloColors.blue,
  );
  const firefighterTool = _HelperTool(
    hil: 'hos',
    icon: Icons.water_drop_rounded,
    color: TudloColors.coral,
  );
  const vendorTool = _HelperTool(
    hil: 'basket sang prutas',
    icon: Icons.shopping_basket_rounded,
    color: TudloColors.gold,
    imageAsset: 'assets/images/level_game/fruits.png',
  );
  const farmerTool = _HelperTool(
    hil: 'gamit pang-uma',
    icon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fisherTool = _HelperTool(
    hil: 'pukot',
    icon: Icons.phishing_rounded,
    color: TudloColors.blue,
  );

  const teacher = _HelperWord(
    hil: 'manunudlo',
    eng: 'manunudlo',
    tapSpeech: 'Manunudlo. Ang manunudlo nagatudlo sa mga bata.',
    workplaceLabel: 'eskwelahan',
    workplaceSpeech: 'Husto! Ang manunudlo nagatrabaho sa eskwelahan.',
    imageAsset: 'assets/images/level_game/people/manunudlo.png',
    workplaceAsset: 'assets/images/level_game/eskwelahan.png',
    tool: teacherTool,
    icon: Icons.school_rounded,
    workplaceIcon: Icons.school_rounded,
    color: TudloColors.blue,
  );
  const doctor = _HelperWord(
    hil: 'doktor',
    eng: 'doktor',
    tapSpeech: 'Doktor. Ang doktor nagabulig sa mga masakiton.',
    workplaceLabel: 'ospital',
    workplaceSpeech: 'Husto! Ang doktor nagatrabaho sa ospital.',
    imageAsset: 'assets/images/level_game/people/doktor.png',
    workplaceAsset: 'assets/images/level_game/ospital.png',
    tool: doctorTool,
    icon: Icons.medical_services_rounded,
    workplaceIcon: Icons.local_hospital_rounded,
    color: TudloColors.coral,
  );
  const nurse = _HelperWord(
    hil: 'nars',
    eng: 'nars',
    tapSpeech: 'Nars. Ang nars nagaatipan sa mga masakiton.',
    workplaceLabel: 'ospital',
    workplaceSpeech: 'Husto! Ang nars nagatrabaho sa ospital.',
    imageAsset: 'assets/images/level_game/people/nars.png',
    workplaceAsset: 'assets/images/level_game/nursing-station.png',
    tool: nurseTool,
    icon: Icons.medical_information_rounded,
    workplaceIcon: Icons.local_hospital_rounded,
    color: TudloColors.orange,
  );
  const police = _HelperWord(
    hil: 'pulis',
    eng: 'pulis',
    tapSpeech: 'Pulis. Ang pulis nagabantay sang katawhayan.',
    workplaceLabel: 'estasyon sang pulis',
    workplaceSpeech: 'Husto! Ang pulis nagatrabaho sa estasyon sang pulis.',
    imageAsset: 'assets/images/level_game/people/pulis.png',
    workplaceAsset: 'assets/images/level_game/estasyon-sang-pulis.png',
    tool: policeTool,
    icon: Icons.local_police_rounded,
    workplaceIcon: Icons.local_police_rounded,
    color: TudloColors.blue,
  );
  const firefighter = _HelperWord(
    hil: 'bumbero',
    eng: 'bumbero',
    tapSpeech: 'Bumbero. Ang bumbero nagapatay sang kalayo.',
    workplaceLabel: 'estasyon sang bumbero',
    workplaceSpeech: 'Husto! Ang bumbero nagatrabaho sa estasyon sang bumbero.',
    imageAsset: 'assets/images/level_game/people/bumbero.png',
    workplaceAsset: 'assets/images/level_game/estasyon-sang-bumbero.png',
    tool: firefighterTool,
    icon: Icons.local_fire_department_rounded,
    workplaceIcon: Icons.local_fire_department_rounded,
    color: TudloColors.coral,
  );
  const vendor = _HelperWord(
    hil: 'tindera',
    eng: 'tindera',
    tapSpeech: 'Tindera. Ang tindera nagabaligya sang mga balaklon.',
    workplaceLabel: 'tinda',
    workplaceSpeech: 'Husto! Ang tindera nagatrabaho sa tinda.',
    imageAsset: 'assets/images/level_game/tindera.png',
    workplaceAsset: 'assets/images/level_game/tinda.png',
    tool: vendorTool,
    icon: Icons.storefront_rounded,
    workplaceIcon: Icons.storefront_rounded,
    color: TudloColors.gold,
  );
  const farmer = _HelperWord(
    hil: 'mangunguma',
    eng: 'mangunguma',
    tapSpeech: 'Mangunguma. Ang mangunguma nagatanom sang humay kag utan.',
    workplaceLabel: 'uma',
    workplaceSpeech: 'Husto! Ang mangunguma nagatrabaho sa uma.',
    imageAsset: 'assets/images/level_game/people/mangunguma.png',
    workplaceAsset: 'assets/images/level_game/uma.png',
    tool: farmerTool,
    icon: Icons.agriculture_rounded,
    workplaceIcon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fisher = _HelperWord(
    hil: 'mangingisda',
    eng: 'mangingisda',
    tapSpeech: 'Mangingisda. Ang mangingisda nagadakop sang isda.',
    workplaceLabel: 'baybay',
    workplaceSpeech: 'Husto! Ang mangingisda nagatrabaho sa baybay.',
    imageAsset: 'assets/images/level_game/people/mangingisda.png',
    workplaceAsset: 'assets/images/level_game/dagat.png',
    tool: fisherTool,
    icon: Icons.sailing_rounded,
    workplaceIcon: Icons.beach_access_rounded,
    color: TudloColors.blue,
  );

  return switch (lessonNumber) {
    1 => const [teacher, doctor, nurse],
    2 => const [police, firefighter, vendor],
    3 => const [farmer, fisher],
    _ => const [
      teacher,
      doctor,
      nurse,
      police,
      firefighter,
      vendor,
      farmer,
      fisher,
    ],
  };
}

class _GradeOnePlaceLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOnePlaceLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOnePlaceLesson> createState() => _GradeOnePlaceLessonState();
}

class _GradeOnePlaceLessonState extends State<_GradeOnePlaceLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _placesForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final reviewPlaces = _placeReviewTargetsFor(widget.content.lessonNumber);
    final steps = [
      _AlphabetFadeStep(
        child: _PlaceOpeningCard(onDone: () => _advanceAfterCorrect(maxIndex)),
      ),
      for (final place in places) ...[
        _AlphabetFadeStep(
          child: _PlaceTapCard(
            key: ValueKey('place-tap-${widget.content.id}-${place.hil}'),
            place: place,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _KokaTravelCard(
            key: ValueKey('place-travel-${widget.content.id}-${place.hil}'),
            place: place,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _PlaceMapGuideCard(
          key: ValueKey('place-guide-${widget.content.id}'),
          places: reviewPlaces,
          onDone: () => _advanceAfterCorrect(maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _PlaceSituationGameCard(
          key: ValueKey('place-situations-${widget.content.id}'),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('place-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceWord {
  final String hil;
  final String eng;
  final String asset;
  final IconData icon;
  final Color color;
  final String introSpeech;
  final String tapSpeech;
  final List<IconData> effects;

  const _PlaceWord({
    required this.hil,
    required this.eng,
    required this.asset,
    required this.icon,
    required this.color,
    required this.introSpeech,
    required this.tapSpeech,
    required this.effects,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get travelInstruction => 'Guyoda si Koka pakadto sa $hil.';
  String get arrivedSpeech => 'Husto! Ari na si Koka sa $hil.';
}

class _PlaceOpeningCard extends StatefulWidget {
  final VoidCallback onDone;

  const _PlaceOpeningCard({required this.onDone});

  @override
  State<_PlaceOpeningCard> createState() => _PlaceOpeningCardState();
}

class _PlaceOpeningCardState extends State<_PlaceOpeningCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Maglibot kita sa aton banwa!',
          hiligaynon: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: 'Koka: Maglibot kita sa aton banwa!',
      child: SizedBox(
        height: 510,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 38,
              child: Image.asset(
                'assets/images/level_game/road2.png',
                width: 350,
                height: 270,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned(top: 118, child: TudloMascot(size: 190)),
            Positioned(
              bottom: 46,
              child: SizedBox(
                width: 260,
                height: 70,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  child: const Text('Lakbay!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTapCard extends StatefulWidget {
  final _PlaceWord place;
  final VoidCallback onDone;

  const _PlaceTapCard({super.key, required this.place, required this.onDone});

  @override
  State<_PlaceTapCard> createState() => _PlaceTapCardState();
}

class _PlaceTapCardState extends State<_PlaceTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.place.introSpeech,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapPlace() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      widget.place.tapSpeech,
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? 'Koka: ${widget.place.tapSpeech}'
          : 'Koka: ${widget.place.tapInstruction}',
      child: Column(
        children: [
          Text(
            widget.place.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: widget.place.upperName.length > 9 ? 36 : 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _tapPlace,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _PlaceArt(place: widget.place, size: 330),
                  if (_tapped) ...[
                    const _AnimalSparkles(size: 360),
                    for (
                      var index = 0;
                      index < widget.place.effects.length;
                      index++
                    )
                      Positioned(
                        right: 16.0 + index * 34,
                        top: index.isEven ? 18 : 72,
                        child: Icon(
                          widget.place.effects[index],
                          color: widget.place.color,
                          size: 42,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KokaTravelCard extends StatefulWidget {
  final _PlaceWord place;
  final VoidCallback onDone;

  const _KokaTravelCard({super.key, required this.place, required this.onDone});

  @override
  State<_KokaTravelCard> createState() => _KokaTravelCardState();
}

class _KokaTravelCardState extends State<_KokaTravelCard> {
  bool _arrived = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.place.travelInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_arrived) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        'Liwata. ${widget.place.travelInstruction}',
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _arrive() async {
    if (_arrived) return;
    setState(() => _arrived = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.place.arrivedSpeech} Welcome!',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _arrived
          ? 'Koka: ${widget.place.arrivedSpeech}'
          : _retrying
          ? 'Koka: Liwata. ${widget.place.travelInstruction}'
          : 'Koka: ${widget.place.travelInstruction}',
      child: SizedBox(
        height: 530,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              right: 6,
              bottom: 88,
              child: Image.asset(
                'assets/images/level_game/road2.png',
                height: 170,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              right: 12,
              top: 18,
              child: DragTarget<String>(
                onWillAcceptWithDetails: (_) => !_arrived,
                onAcceptWithDetails: (_) => _arrive(),
                builder: (context, candidates, rejected) {
                  return _PlaceArt(
                    place: widget.place,
                    size: candidates.isNotEmpty || _arrived ? 246 : 232,
                    glow: candidates.isNotEmpty || _arrived,
                  );
                },
              ),
            ),
            Positioned(
              left: 22,
              bottom: 116,
              child: _arrived
                  ? const SizedBox(width: 132, height: 132)
                  : Draggable<String>(
                      data: widget.place.hil,
                      feedback: const Material(
                        color: Colors.transparent,
                        child: TudloMascot(size: 142),
                      ),
                      childWhenDragging: const Opacity(
                        opacity: .24,
                        child: TudloMascot(size: 132),
                      ),
                      onDragEnd: (details) {
                        if (!details.wasAccepted) _retry();
                      },
                      child: const TudloMascot(size: 132),
                    ),
            ),
            if (_arrived)
              Positioned(
                right: 62,
                top: 110,
                child: Column(
                  children: [
                    const TudloMascot(size: 104),
                    Text(
                      'Welcome!',
                      style: GoogleFonts.nunito(
                        color: TudloColors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapGuideCard extends StatefulWidget {
  final List<_PlaceWord> places;
  final VoidCallback onDone;

  const _PlaceMapGuideCard({
    super.key,
    required this.places,
    required this.onDone,
  });

  @override
  State<_PlaceMapGuideCard> createState() => _PlaceMapGuideCardState();
}

class _PlaceMapGuideCardState extends State<_PlaceMapGuideCard> {
  int _targetIndex = 0;
  String? _arrivedHil;
  bool _reported = false;

  _PlaceWord get _target => widget.places[_targetIndex];
  String get _targetPrompt => 'Buligi ako. Pindoton ang ${_target.hil}.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(context, _targetPrompt, hiligaynon: true),
      );
    });
  }

  Future<void> _tapPlace(_PlaceWord place) async {
    if (_reported) return;
    if (place.hil != _target.hil) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Buligi ako magkadto sa ${_target.hil}.',
        hiligaynon: true,
      );
      return;
    }
    setState(() => _arrivedHil = place.hil);
    await TudloVoiceButton.speak(
      context,
      'Husto! Ari na kita sa ${place.hil}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_targetIndex >= widget.places.length - 1) {
        _reported = true;
        widget.onDone();
      } else {
        setState(() {
          _targetIndex++;
          _arrivedHil = null;
        });
        unawaited(
          TudloVoiceButton.speak(context, _targetPrompt, hiligaynon: true),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: 'Koka: $_targetPrompt',
      child: Column(
        children: [
          Text(
            'Mapa sang Banwa',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 448,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 22,
                  right: 22,
                  top: 58,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/level_game/road2.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Positioned(
                  left: 142,
                  bottom: 16,
                  child: TudloMascot(size: 78),
                ),
                for (var index = 0; index < widget.places.length; index++)
                  Positioned(
                    left: _mapOffset(index, widget.places.length).dx,
                    top: _mapOffset(index, widget.places.length).dy,
                    child: GestureDetector(
                      onTap: () => _tapPlace(widget.places[index]),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _PlaceArt(
                            place: widget.places[index],
                            size: 124,
                            glow: _arrivedHil == widget.places[index].hil,
                          ),
                          if (_arrivedHil == widget.places[index].hil)
                            const Positioned(
                              right: -10,
                              bottom: -8,
                              child: TudloMascot(size: 54),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _mapOffset(int index, int count) {
    final offsets = const [
      Offset(16, 58),
      Offset(238, 58),
      Offset(118, 208),
      Offset(24, 286),
      Offset(232, 286),
    ];
    return offsets[index % offsets.length];
  }
}

class _PlaceSituationGameCard extends StatefulWidget {
  final VoidCallback onDone;

  const _PlaceSituationGameCard({super.key, required this.onDone});

  @override
  State<_PlaceSituationGameCard> createState() =>
      _PlaceSituationGameCardState();
}

class _PlaceSituationGameCardState extends State<_PlaceSituationGameCard> {
  int _index = 0;
  String? _arrivedHil;
  bool _reported = false;
  late final List<List<String>> _choiceOrders;

  final List<_PlaceSituation> _situations = [
    _PlaceSituation(
      prompt: 'May bata nga masakit.',
      answerHil: 'ospital',
      choices: ['ospital', 'eskwelahan', 'uma'],
      imageAsset: 'assets/images/level_game/sick-kid.png',
      icon: Icons.sick_rounded,
    ),
    _PlaceSituation(
      prompt: 'Gutom ang karbaw.',
      answerHil: 'uma',
      choices: ['uma', 'baybay', 'ospital'],
      imageAsset: 'assets/images/level_game/animals/carabao.png',
      icon: Icons.agriculture_rounded,
    ),
    _PlaceSituation(
      prompt: 'Oras na magtuon.',
      answerHil: 'eskwelahan',
      choices: ['eskwelahan', 'baybay', 'tinda'],
      imageAsset: 'assets/images/level_game/book.png',
      icon: Icons.menu_book_rounded,
    ),
  ];

  _PlaceSituation get _current => _situations[_index];

  @override
  void initState() {
    super.initState();
    _choiceOrders = [
      for (final situation in _situations) _shuffledChoices(situation.choices),
    ];
  }

  Future<void> _tapChoice(_PlaceWord place) async {
    if (_reported) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;

    if (place.hil != _current.answerHil) {
      await TudloVoiceButton.speak(
        context,
        'Liwata. Diin kita makadto?',
        hiligaynon: true,
      );
      return;
    }
    setState(() => _arrivedHil = place.hil);
    await TudloVoiceButton.speak(
      context,
      'Husto! Makadto kita sa ${place.hil}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_index >= _situations.length - 1) {
        _reported = true;
        widget.onDone();
      } else {
        setState(() {
          _index++;
          _arrivedHil = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choiceOrders[_index]
        .map(_placeByHil)
        .whereType<_PlaceWord>()
        .toList();
    return _AnimalStage(
      mascotMessage: 'Koka: Diin kita makadto?',
      child: Column(
        children: [
          _PlaceSituationArt(situation: _current, size: 96),
          const SizedBox(height: 8),
          Text(
            _current.prompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final place in choices)
                GestureDetector(
                  onTap: () => _tapChoice(place),
                  child: _PlaceArt(
                    place: place,
                    size: 112,
                    glow: _arrivedHil == place.hil,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          if (_arrivedHil != null) const TudloMascot(size: 118),
        ],
      ),
    );
  }
}

class _PlaceSituation {
  final String prompt;
  final String answerHil;
  final List<String> choices;
  final String? imageAsset;
  final IconData icon;

  const _PlaceSituation({
    required this.prompt,
    required this.answerHil,
    required this.choices,
    this.imageAsset,
    required this.icon,
  });
}

class _PlaceSituationArt extends StatelessWidget {
  final _PlaceSituation situation;
  final double size;

  const _PlaceSituationArt({required this.situation, required this.size});

  @override
  Widget build(BuildContext context) {
    if (situation.imageAsset == null) {
      return Icon(situation.icon, color: TudloColors.green, size: size * .82);
    }
    return Image.asset(
      situation.imageAsset!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          Icon(situation.icon, color: TudloColors.green, size: size * .82),
    );
  }
}

class _PlaceArt extends StatelessWidget {
  final _PlaceWord place;
  final double size;
  final bool glow;

  const _PlaceArt({required this.place, required this.size, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: place.color.withValues(alpha: .34),
                  blurRadius: 26,
                  spreadRadius: 6,
                ),
              ]
            : null,
      ),
      child: Image.asset(
        place.asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(place.icon, color: place.color, size: size * .58),
      ),
    );
  }
}

List<_PlaceWord> _placesForLesson(int lessonNumber) {
  final all = _allPlaces();
  return switch (lessonNumber) {
    1 => [all['balay']!, all['eskwelahan']!, all['simbahan']!],
    2 => [all['tinda']!, all['plasa']!, all['ospital']!],
    3 => [all['uma']!, all['baybay']!],
    _ => [
      all['balay']!,
      all['eskwelahan']!,
      all['tinda']!,
      all['ospital']!,
      all['uma']!,
      all['baybay']!,
      all['plasa']!,
    ],
  };
}

List<_PlaceWord> _placeReviewTargetsFor(int lessonNumber) {
  final all = _allPlaces();
  return switch (lessonNumber) {
    1 => [all['balay']!, all['eskwelahan']!, all['simbahan']!],
    2 => [all['ospital']!, all['tinda']!, all['plasa']!],
    3 => [all['uma']!, all['baybay']!, all['eskwelahan']!],
    _ => [all['ospital']!, all['eskwelahan']!, all['uma']!, all['baybay']!],
  };
}

_PlaceWord? _placeByHil(String hil) => _allPlaces()[hil];

Map<String, _PlaceWord> _allPlaces() {
  const house = _PlaceWord(
    hil: 'balay',
    eng: 'balay',
    asset: 'assets/images/level_game/house.png',
    icon: Icons.home_rounded,
    color: TudloColors.green,
    introSpeech: 'Ini ang balay.',
    tapSpeech: 'Balay. Diri nagapuyo ang pamilya.',
    effects: [Icons.door_front_door_rounded, Icons.pets_rounded],
  );
  const school = _PlaceWord(
    hil: 'eskwelahan',
    eng: 'eskwelahan',
    asset: 'assets/images/level_game/eskwelahan.png',
    icon: Icons.school_rounded,
    color: TudloColors.blue,
    introSpeech: 'Ini ang eskwelahan.',
    tapSpeech: 'Eskwelahan. Diri kita nagatuon.',
    effects: [Icons.notifications_active_rounded, Icons.waving_hand_rounded],
  );
  const church = _PlaceWord(
    hil: 'simbahan',
    eng: 'simbahan',
    asset: 'assets/images/level_game/simbahan.png',
    icon: Icons.church_rounded,
    color: TudloColors.forest,
    introSpeech: 'Ini ang simbahan.',
    tapSpeech: 'Simbahan. Diri nagasimba ang mga tawo.',
    effects: [Icons.notifications_rounded, Icons.door_front_door_rounded],
  );
  const market = _PlaceWord(
    hil: 'tinda',
    eng: 'tinda',
    asset: 'assets/images/level_game/tinda.png',
    icon: Icons.storefront_rounded,
    color: TudloColors.gold,
    introSpeech: 'Ini ang tinda.',
    tapSpeech: 'Tinda. Diri kita nagabakal sang pagkaon.',
    effects: [Icons.shopping_basket_rounded, Icons.local_grocery_store_rounded],
  );
  const plaza = _PlaceWord(
    hil: 'plasa',
    eng: 'plasa',
    asset: 'assets/images/level_game/plaza.png',
    icon: Icons.park_rounded,
    color: TudloColors.green,
    introSpeech: 'Ini ang plasa.',
    tapSpeech: 'Plasa. Diri nagadula kag nagapahuway ang mga tawo.',
    effects: [Icons.celebration_rounded, Icons.air_rounded],
  );
  const hospital = _PlaceWord(
    hil: 'ospital',
    eng: 'ospital',
    asset: 'assets/images/level_game/ospital.png',
    icon: Icons.local_hospital_rounded,
    color: TudloColors.coral,
    introSpeech: 'Ini ang ospital.',
    tapSpeech: 'Ospital. Diri ginabuligan ang mga masakiton.',
    effects: [Icons.medical_services_rounded, Icons.local_hospital_rounded],
  );
  const farm = _PlaceWord(
    hil: 'uma',
    eng: 'uma',
    asset: 'assets/images/level_game/uma.png',
    icon: Icons.agriculture_rounded,
    color: TudloColors.forest,
    introSpeech: 'Ini ang uma.',
    tapSpeech: 'Uma. Diri nagatanom ang mangunguma.',
    effects: [Icons.agriculture_rounded, Icons.grass_rounded],
  );
  const beach = _PlaceWord(
    hil: 'baybay',
    eng: 'baybay',
    asset: 'assets/images/level_game/baybay.png',
    icon: Icons.beach_access_rounded,
    color: TudloColors.blue,
    introSpeech: 'Ini ang baybay.',
    tapSpeech: 'Baybay. Diri nagapangisda ang mangingisda.',
    effects: [Icons.waves_rounded, Icons.water_rounded],
  );
  return const {
    'balay': house,
    'eskwelahan': school,
    'simbahan': church,
    'tinda': market,
    'plasa': plaza,
    'ospital': hospital,
    'uma': farm,
    'baybay': beach,
  };
}

class _FamilyWordLessonCard extends StatelessWidget {
  final _FamilyWord word;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _FamilyWordLessonCard({
    super.key,
    required this.word,
    required this.canGoBack,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: 'Koka: ${_titleCase(word.hil)}.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 458,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  child: _FamilyImage(
                    word: word,
                    size: 350,
                    voiceMessage: word.hil,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 184,
                  child: _PictureArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: canGoBack,
                    onPressed: onBack,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 184,
                  child: _PictureArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: true,
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _titleCase(word.hil),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 40,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PictureArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .36,
      child: Material(
        color: enabled
            ? TudloColors.green.withValues(alpha: .14)
            : TudloColors.line.withValues(alpha: .26),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 66,
            height: 66,
            child: Icon(
              icon,
              color: enabled ? TudloColors.blue : TudloColors.muted,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyQuizCard extends StatefulWidget {
  final _FamilyWord target;
  final List<_FamilyWord> choices;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyQuizCard({
    super.key,
    required this.target,
    required this.choices,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyQuizCard> createState() => _FamilyQuizCardState();
}

class _FamilyQuizCardState extends State<_FamilyQuizCard> {
  String? _selected;
  bool _checked = false;
  bool _correct = false;
  int _feedbackKey = 0;
  late final List<_FamilyWord> _choices;

  @override
  void initState() {
    super.initState();
    _choices = _shuffledChoices(widget.choices);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        unawaited(
          TudloVoiceButton.speak(context, widget.target.hil, hiligaynon: true),
        );
      });
    });
  }

  Future<void> _choose(_FamilyWord choice) async {
    if (_checked && _correct) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;
    await TudloVoiceButton.speak(context, choice.hil, hiligaynon: true);
    final isCorrect = choice.hil == widget.target.hil;
    widget.onAttempt(isCorrect);
    setState(() {
      _selected = choice.hil;
      _checked = true;
      _correct = isCorrect;
      _feedbackKey++;
    });
    if (isCorrect) {
      widget.onCorrect();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || _correct) return;
      setState(() {
        _checked = false;
        _selected = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _checked
          ? (_correct ? 'Husto! Maayo gid.' : 'Suliton liwat.')
          : _cleanFamilyPrompt('Koka: Pili-a ang sakto nga sabat.'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final imageSize = compact ? 238.0 : 258.0;
          final imageGap = compact ? 8.0 : 12.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FamilyImage(
                word: widget.target,
                size: imageSize,
                voiceMessage: widget.target.hil,
                voiceButtonSize: compact ? 60 : 64,
              ),
              SizedBox(height: imageGap),
              _FamilyChoiceGrid(
                choices: _choices,
                selected: _selected,
                checked: _checked,
                answer: widget.target.hil,
                feedbackKey: _feedbackKey,
                onChoose: _choose,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyHouseWindowQuizActivity extends StatefulWidget {
  final double progress;
  final List<_FamilyWord> members;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyHouseWindowQuizActivity({
    super.key,
    required this.progress,
    required this.members,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyHouseWindowQuizActivity> createState() =>
      _FamilyHouseWindowQuizActivityState();
}

class _FamilyHouseWindowQuizActivityState
    extends State<_FamilyHouseWindowQuizActivity> {
  late final List<_FamilyWord> _windowOrder = _shuffledChoices(widget.members);
  final Set<String> _found = {};
  int _targetIndex = 0;
  int? _wrongWindow;
  bool _done = false;
  int _feedbackKey = 0;

  _FamilyWord get _target =>
      widget.members[_targetIndex.clamp(
        0,
        math.max(0, widget.members.length - 1),
      )];

  String get _question => 'Diin si ${_familyQuestionName(_target)}?';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    });
  }

  Future<void> _tapWindow(int index) async {
    if (_done || index < 0 || index >= _windowOrder.length) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final member = _windowOrder[index];
    if (_found.contains(member.hil)) return;
    final correct = member.hil == _target.hil;
    widget.onAttempt(correct);
    setState(() {
      _feedbackKey++;
      _wrongWindow = correct ? null : index;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_question',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 720), () {
        if (mounted && !_done) setState(() => _wrongWindow = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _found.add(member.hil);
      if (_found.length >= widget.members.length) {
        _done = true;
      } else {
        _targetIndex++;
      }
    });
    if (_done) {
      await TudloVoiceButton.speak(
        context,
        'Ara na sila tanan!',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (!mounted) return;
      widget.onCorrect();
    } else {
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: 'Buligi si Koka makita ang iya pamilya sa balay!',
      progress: widget.progress,
      mascotMessage: _done ? 'Koka: Ara na sila tanan!' : 'Koka: $_question',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            children: [
              _PresentationInstructionText(
                message: _question,
                fontSize: (width * .074).clamp(25.0, 36.0),
                textAlign: TextAlign.center,
                onReplay: () => unawaited(
                  TudloVoiceButton.speak(context, _question, hiligaynon: true),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: math.min(width, 360),
                    height: 350,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(child: _FamilyHouseShell()),
                        for (
                          var index = 0;
                          index < _windowOrder.length && index < 3;
                          index++
                        )
                          Positioned(
                            left: 31.0 + index * 105.0,
                            top: 114,
                            child: _FamilyWindowTarget(
                              member: _windowOrder[index],
                              found: _found.contains(_windowOrder[index].hil),
                              wrong: _wrongWindow == index,
                              feedbackKey: _feedbackKey,
                              onTap: () => _tapWindow(index),
                            ),
                          ),
                        if (_done)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: .4, end: 1),
                                duration: const Duration(milliseconds: 620),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0, 1),
                                    child: Transform.scale(
                                      scale: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/level_game/people/pamilya.png',
                                    width: 250,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.family_restroom_rounded,
                                      color: TudloColors.green,
                                      size: 150,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyVisitorDoorQuizActivity extends StatefulWidget {
  final double progress;
  final List<_FamilyWord> visitors;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyVisitorDoorQuizActivity({
    super.key,
    required this.progress,
    required this.visitors,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyVisitorDoorQuizActivity> createState() =>
      _FamilyVisitorDoorQuizActivityState();
}

class _FamilyVisitorDoorQuizActivityState
    extends State<_FamilyVisitorDoorQuizActivity> {
  late final List<_FamilyWord> _visitorOrder = _shuffledChoices(
    widget.visitors,
  );
  final Set<String> _found = {};
  int _targetIndex = 0;
  String? _wrong;
  bool _done = false;
  int _feedbackKey = 0;

  _FamilyWord get _target =>
      widget.visitors[_targetIndex.clamp(
        0,
        math.max(0, widget.visitors.length - 1),
      )];

  String get _question =>
      'Kilala mo si ${_familyQuestionName(_target)}? Tap-tapa siya!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    });
  }

  Future<void> _tapVisitor(_FamilyWord visitor) async {
    if (_done || _found.contains(visitor.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }
    final correct = visitor.hil == _target.hil;
    widget.onAttempt(correct);
    setState(() {
      _feedbackKey++;
      _wrong = correct ? null : visitor.hil;
    });
    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_question',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 720), () {
        if (mounted && !_done) setState(() => _wrong = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _found.add(visitor.hil);
      if (_found.length >= widget.visitors.length) {
        _done = true;
      } else {
        _targetIndex++;
      }
    });
    if (_done) {
      await TudloVoiceButton.speak(
        context,
        'Husto! Kilala mo sila tanan.',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (!mounted) return;
      widget.onCorrect();
    } else {
      unawaited(TudloVoiceButton.speak(context, _question, hiligaynon: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: 'May bisita sa balay ni Koka!',
      progress: widget.progress,
      mascotMessage: _done ? 'Koka: Maayo gid!' : 'Koka: $_question',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            children: [
              _PresentationInstructionText(
                message: _question,
                fontSize: (width * .066).clamp(23.0, 32.0),
                textAlign: TextAlign.center,
                onReplay: () => unawaited(
                  TudloVoiceButton.speak(context, _question, hiligaynon: true),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      top: 8,
                      child: _FamilyDoorShape(
                        width: math.min(width * .56, 210),
                        height: 270,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final visitor in _visitorOrder)
                            _FamilyVisitorTarget(
                              visitor: visitor,
                              found: _found.contains(visitor.hil),
                              wrong: _wrong == visitor.hil,
                              feedbackKey: _feedbackKey,
                              onTap: () => _tapVisitor(visitor),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyPhotoPlacement {
  final _FamilyWord member;
  final String place;
  final Alignment alignment;

  const _FamilyPhotoPlacement({
    required this.member,
    required this.place,
    required this.alignment,
  });
}

class _FamilyPhotoQuizActivity extends StatefulWidget {
  final double progress;
  final List<_FamilyWord> members;
  final ValueChanged<bool> onAttempt;
  final VoidCallback onCorrect;

  const _FamilyPhotoQuizActivity({
    super.key,
    required this.progress,
    required this.members,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyPhotoQuizActivity> createState() =>
      _FamilyPhotoQuizActivityState();
}

class _FamilyPhotoQuizActivityState extends State<_FamilyPhotoQuizActivity> {
  late final List<_FamilyPhotoPlacement> _placements = _familyPhotoPlacements(
    widget.members,
  );
  late final List<_FamilyWord> _choices = _shuffledChoices(
    _placements.map((placement) => placement.member),
  );
  final Map<String, _FamilyWord> _placedByHil = {};
  int _targetIndex = 0;
  String? _wrongHil;
  bool _done = false;
  bool _flash = false;
  int _feedbackKey = 0;

  _FamilyPhotoPlacement get _target =>
      _placements[_targetIndex.clamp(0, math.max(0, _placements.length - 1))];

  String get _instruction =>
      'Ibutang si ${_familyQuestionName(_target.member)} sa ${_target.place}!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _placements.isEmpty) return;
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    });
  }

  Future<void> _placeMember(
    _FamilyPhotoPlacement slot,
    _FamilyWord member,
  ) async {
    if (_done || _placedByHil.containsKey(slot.member.hil)) return;
    final spent = await AppData.spendQuestionEnergy();
    if (!mounted) return;
    if (!spent) {
      await showLowEnergyDialog(context);
      return;
    }

    final correct =
        member.hil == _target.member.hil &&
        slot.member.hil == _target.member.hil;
    widget.onAttempt(correct);
    setState(() {
      _feedbackKey++;
      _wrongHil = correct ? null : member.hil;
    });

    if (!correct) {
      unawaited(AppAudioService.instance.playWrong());
      await TudloVoiceButton.speak(
        context,
        'Suliton liwat. $_instruction',
        hiligaynon: true,
      );
      Future<void>.delayed(const Duration(milliseconds: 720), () {
        if (mounted && !_done) setState(() => _wrongHil = null);
      });
      return;
    }

    unawaited(AppAudioService.instance.playCorrect());
    setState(() {
      _placedByHil[slot.member.hil] = member;
      if (_placedByHil.length >= _placements.length) {
        _done = true;
        _flash = true;
      } else {
        _targetIndex++;
      }
    });

    if (_done) {
      unawaited(
        AppAudioService.instance.playSoundEffect(
          AppAudioService.tap,
          volume: .60,
          allowRapidRepeat: true,
        ),
      );
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _flash = false);
      });
      await TudloVoiceButton.speak(
        context,
        'Husto! Kumpleto na ang photo sang pamilya!',
        hiligaynon: true,
        waitForCompletion: true,
      );
      if (!mounted) return;
      widget.onCorrect();
    } else {
      unawaited(
        TudloVoiceButton.speak(context, _instruction, hiligaynon: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UnitOneQuizStage(
      prompt: 'Photo sang pamilya!',
      progress: widget.progress,
      mascotMessage: _done
          ? 'Koka: Kumpleto na ang photo!'
          : 'Koka: $_instruction',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final frameWidth = math.min(width * .90, 342.0);
          final frameHeight = math.min(338.0, constraints.maxHeight * .58);
          final avatarSize = (frameWidth * .25).clamp(70.0, 92.0);
          return Column(
            children: [
              _PresentationInstructionText(
                message: _instruction,
                fontSize: (width * .064).clamp(22.0, 31.0),
                textAlign: TextAlign.center,
                onReplay: () => unawaited(
                  TudloVoiceButton.speak(
                    context,
                    _instruction,
                    hiligaynon: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _flash
                              ? Colors.white
                              : Colors.white.withValues(alpha: .86),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: TudloColors.forest,
                            width: 6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TudloColors.forest.withValues(alpha: .18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6DE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE9C77E),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (final placement in _placements)
                      Align(
                        alignment: placement.alignment,
                        child: _FamilyPhotoSlot(
                          placement: placement,
                          placed: _placedByHil[placement.member.hil],
                          avatarSize: avatarSize,
                          onAccept: (member) => _placeMember(placement, member),
                        ),
                      ),
                    if (_done)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: _flash ? .72 : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final member in _choices)
                        if (!_placedByHil.containsKey(member.hil))
                          _FamilyPhotoDraggable(
                            member: member,
                            size: (width * .19).clamp(64.0, 84.0),
                            wrong: _wrongHil == member.hil,
                            feedbackKey: _feedbackKey,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyPhotoSlot extends StatelessWidget {
  final _FamilyPhotoPlacement placement;
  final _FamilyWord? placed;
  final double avatarSize;
  final ValueChanged<_FamilyWord> onAccept;

  const _FamilyPhotoSlot({
    required this.placement,
    required this.placed,
    required this.avatarSize,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlaced = placed != null;
    return DragTarget<_FamilyWord>(
      onWillAcceptWithDetails: (_) => !hasPlaced,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: candidates.isNotEmpty ? 1.08 : 1,
          child: Container(
            width: avatarSize + 22,
            height: avatarSize + 28,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hasPlaced
                  ? TudloColors.softGreen
                  : Colors.white.withValues(alpha: .70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: candidates.isNotEmpty
                    ? TudloColors.blue
                    : hasPlaced
                    ? TudloColors.green
                    : const Color(0xFFE8D59B),
                width: 4,
              ),
            ),
            child: hasPlaced
                ? _FamilyPhotoPerson(member: placed!, size: avatarSize)
                : Icon(
                    Icons.person_add_alt_1_rounded,
                    color: TudloColors.forest.withValues(alpha: .45),
                    size: avatarSize * .55,
                  ),
          ),
        );
      },
    );
  }
}

class _FamilyPhotoDraggable extends StatelessWidget {
  final _FamilyWord member;
  final double size;
  final bool wrong;
  final int feedbackKey;

  const _FamilyPhotoDraggable({
    required this.member,
    required this.size,
    required this.wrong,
    required this.feedbackKey,
  });

  @override
  Widget build(BuildContext context) {
    final child = _FeedbackMotion(
      key: ValueKey('photo-choice-${member.hil}-$feedbackKey-$wrong'),
      correct: false,
      wrong: wrong,
      child: _FamilyPhotoPerson(member: member, size: size),
    );
    return Draggable<_FamilyWord>(
      data: member,
      feedback: Material(
        color: Colors.transparent,
        child: _FamilyPhotoPerson(member: member, size: size * 1.05),
      ),
      childWhenDragging: Opacity(opacity: .30, child: child),
      child: child,
    );
  }
}

class _FamilyPhotoPerson extends StatelessWidget {
  final _FamilyWord member;
  final double size;

  const _FamilyPhotoPerson({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        member.imageAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(member.icon, color: TudloColors.forest, size: size * .76),
      ),
    );
  }
}

class _FamilyHouseShell extends StatelessWidget {
  const _FamilyHouseShell();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FamilyHouseShellPainter());
  }
}

class _FamilyHouseShellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final roof = Path()
      ..moveTo(size.width * .08, size.height * .34)
      ..lineTo(size.width * .50, size.height * .06)
      ..lineTo(size.width * .92, size.height * .34)
      ..close();
    paint.color = const Color(0xFFFFA94D);
    canvas.drawPath(roof, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = TudloColors.forest.withValues(alpha: .75);
    canvas.drawPath(roof, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF5D8);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .10,
        size.height * .28,
        size.width * .80,
        size.height * .58,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(body, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = TudloColors.forest;
    canvas.drawRRect(body, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFC68144);
    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .43,
        size.height * .57,
        size.width * .14,
        size.height * .29,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(door, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FamilyWindowTarget extends StatelessWidget {
  final _FamilyWord member;
  final bool found;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback onTap;

  const _FamilyWindowTarget({
    required this.member,
    required this.found,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('window-${member.hil}-$feedbackKey-$wrong'),
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 88,
          height: 106,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: found ? Colors.white : const Color(0xFFC7F2FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: found ? TudloColors.green : TudloColors.blue,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .20),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: found
              ? Image.asset(
                  member.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(member.icon, color: TudloColors.forest, size: 52),
                )
              : Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1DC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1DC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FamilyDoorShape extends StatelessWidget {
  final double width;
  final double height;

  const _FamilyDoorShape({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TudloColors.forest, width: 6),
      ),
      child: Center(
        child: Container(
          width: width * .58,
          height: height * .72,
          decoration: BoxDecoration(
            color: const Color(0xFFC68144),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF8F5D2D), width: 5),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.only(right: width * .08),
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: TudloColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyVisitorTarget extends StatelessWidget {
  final _FamilyWord visitor;
  final bool found;
  final bool wrong;
  final int feedbackKey;
  final VoidCallback onTap;

  const _FamilyVisitorTarget({
    required this.visitor,
    required this.found,
    required this.wrong,
    required this.feedbackKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FeedbackMotion(
      key: ValueKey('visitor-${visitor.hil}-$feedbackKey-$wrong'),
      correct: found,
      wrong: wrong,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 108,
          height: 178,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            color: found
                ? TudloColors.softGreen
                : Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: found ? TudloColors.green : Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  visitor.imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(visitor.icon, color: TudloColors.forest, size: 74),
                ),
              ),
              Text(
                found ? _titleCase(visitor.hil) : '?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 18,
                  height: 1,
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

class _FamilyMatchingCard extends StatefulWidget {
  final List<_FamilyWord> words;
  final void Function(_FamilyWord word, bool correct) onAttempt;
  final VoidCallback onCorrect;

  const _FamilyMatchingCard({
    super.key,
    required this.words,
    required this.onAttempt,
    required this.onCorrect,
  });

  @override
  State<_FamilyMatchingCard> createState() => _FamilyMatchingCardState();
}

class _FamilyMatchingCardState extends State<_FamilyMatchingCard> {
  String? _selectedHil;
  String? _wrongHil;
  String? _wrongImageHil;
  final Set<String> _matched = {};
  bool _reported = false;
  int _feedbackKey = 0;
  late final List<_FamilyWord> _imageOrder;

  @override
  void initState() {
    super.initState();
    _imageOrder = _shuffledChoices(widget.words);
  }

  Future<void> _selectWord(_FamilyWord word) async {
    if (_matched.contains(word.hil) || _reported) return;
    await TudloVoiceButton.speak(context, word.hil, hiligaynon: true);
    if (!mounted) return;
    setState(() {
      _selectedHil = _selectedHil == word.hil ? null : word.hil;
      _wrongHil = null;
      _wrongImageHil = null;
    });
  }

  Future<void> _selectImage(_FamilyWord word) async {
    if (_selectedHil == null || _matched.contains(word.hil) || _reported) {
      return;
    }
    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;
    final selected = _selectedHil!;
    final correct = selected == word.hil;
    widget.onAttempt(word, correct);
    setState(() {
      _feedbackKey++;
      if (correct) {
        _matched.add(word.hil);
        _selectedHil = null;
        _wrongHil = null;
        _wrongImageHil = null;
      } else {
        _wrongHil = selected;
        _wrongImageHil = word.hil;
        _selectedHil = null;
      }
    });
    if (correct && _matched.length == widget.words.length && !_reported) {
      _reported = true;
      widget.onCorrect();
      return;
    }
    if (!correct) {
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (!mounted || _reported) return;
        setState(() {
          _wrongHil = null;
          _wrongImageHil = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FamilyStage(
      mascotMessage: _matched.length == widget.words.length
          ? 'Husto! Maayo gid.'
          : 'Koka: Ipares ang pareho.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final word in widget.words) ...[
                    _matchWordButton(word),
                    if (word != widget.words.last) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final word in _imageOrder) ...[
                    _matchImageButton(word),
                    if (word != _imageOrder.last) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchWordButton(_FamilyWord word) {
    final selected = _selectedHil == word.hil;
    final matched = _matched.contains(word.hil);
    final wrong = _wrongHil == word.hil;
    return _FeedbackMotion(
      key: ValueKey('word-${word.hil}-$_feedbackKey-$selected-$matched'),
      correct: matched,
      wrong: wrong,
      child: SizedBox(
        height: 122,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _selectWord(word),
          style: ElevatedButton.styleFrom(
            backgroundColor: matched
                ? TudloColors.green
                : selected
                ? TudloColors.blue
                : const Color(0xFF49CC55),
            foregroundColor: Colors.white,
            elevation: selected || matched ? 7 : 4,
            shadowColor: TudloColors.forest.withValues(alpha: .20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: FittedBox(child: Text(_titleCase(word.hil))),
        ),
      ),
    );
  }

  Widget _matchImageButton(_FamilyWord word) {
    final matched = _matched.contains(word.hil);
    final wrong = _wrongImageHil == word.hil;
    return _FeedbackMotion(
      key: ValueKey('image-${word.hil}-$_feedbackKey-$matched'),
      correct: matched,
      wrong: wrong,
      child: GestureDetector(
        onTap: () => _selectImage(word),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 122,
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: matched
                ? const Color(0xFFE8FFD8)
                : wrong
                ? const Color(0xFFFFEEEE)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: matched
                ? [
                    BoxShadow(
                      color: TudloColors.green.withValues(alpha: .20),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRect(
            child: Transform.scale(
              scale: 1.18,
              child: Image.asset(
                word.imageAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) =>
                    Icon(word.icon, color: TudloColors.forest, size: 72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;

  const _FamilyStage({required this.child, required this.mascotMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 555,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: _StageContentScaler(child: child),
                ),
              ),
              Positioned(
                right: -18,
                top: 510,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(message: mascotMessage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageContentScaler extends StatelessWidget {
  final Widget child;

  const _StageContentScaler({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
        );
      },
    );
  }
}

class _FamilyImage extends StatelessWidget {
  final _FamilyWord word;
  final double size;
  final String voiceMessage;
  final double voiceButtonSize;

  const _FamilyImage({
    required this.word,
    required this.size,
    required this.voiceMessage,
    this.voiceButtonSize = 70,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Image.asset(
              word.imageAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  Icon(word.icon, color: TudloColors.forest, size: size * .56),
            ),
          ),
          const SizedBox(height: 8),
          TudloVoiceButton(
            message: voiceMessage,
            tooltip: 'Pamatii',
            size: voiceButtonSize,
            hiligaynon: true,
          ),
        ],
      ),
    );
  }
}

class _FamilyChoiceGrid extends StatelessWidget {
  final List<_FamilyWord> choices;
  final String? selected;
  final bool checked;
  final String answer;
  final int feedbackKey;
  final ValueChanged<_FamilyWord> onChoose;

  const _FamilyChoiceGrid({
    required this.choices,
    required this.selected,
    required this.checked,
    required this.answer,
    required this.feedbackKey,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChoices = choices.take(3).toList();
    final topChoices = visibleChoices.take(2).toList();
    final bottomChoice = visibleChoices.length > 2 ? visibleChoices[2] : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 10.0 : 14.0;
        final buttonHeight = constraints.maxWidth < 360 ? 64.0 : 68.0;
        final bottomWidth = math.min(188.0, constraints.maxWidth * .54);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (var index = 0; index < topChoices.length; index++) ...[
                  Expanded(
                    child: _button(topChoices[index], height: buttonHeight),
                  ),
                  if (index == 0) SizedBox(width: gap),
                ],
              ],
            ),
            if (bottomChoice != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: bottomWidth,
                child: _button(bottomChoice, height: buttonHeight),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _button(_FamilyWord choice, {required double height}) {
    final active = selected == choice.hil;
    final correct = checked && active && choice.hil == answer;
    final wrong = checked && active && choice.hil != answer;
    return _FeedbackMotion(
      key: ValueKey('${choice.hil}-$feedbackKey-$active'),
      correct: correct,
      wrong: wrong,
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: () => onChoose(choice),
          style: ElevatedButton.styleFrom(
            backgroundColor: wrong
                ? const Color(0xFFE53935)
                : correct
                ? TudloColors.green
                : const Color(0xFF49CC55),
            foregroundColor: Colors.white,
            elevation: active ? 8 : 3,
            shadowColor: TudloColors.forest.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: FittedBox(child: Text(_titleCase(choice.hil))),
        ),
      ),
    );
  }
}

List<_FamilyWord> _familyWordsFor(int lessonNumber) {
  const nanay = _FamilyWord(
    hil: 'nanay',
    eng: 'nanay',
    imageAsset: 'assets/images/level_game/people/nanay.png',
    icon: Icons.woman_rounded,
  );
  const tatay = _FamilyWord(
    hil: 'tatay',
    eng: 'tatay',
    imageAsset: 'assets/images/level_game/people/tatay.png',
    icon: Icons.man_rounded,
  );
  const bata = _FamilyWord(
    hil: 'bata',
    eng: 'bata',
    imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
    icon: Icons.child_care_rounded,
  );
  const lola = _FamilyWord(
    hil: 'lola',
    eng: 'lola',
    imageAsset: 'assets/images/level_game/people/lola.png',
    icon: Icons.elderly_woman_rounded,
  );
  const lolo = _FamilyWord(
    hil: 'lolo',
    eng: 'lolo',
    imageAsset: 'assets/images/level_game/people/lolo.png',
    icon: Icons.elderly_rounded,
  );
  const magulang = _FamilyWord(
    hil: 'magulang',
    eng: 'magulang',
    imageAsset: 'assets/images/level_game/people/bata-nga-lalaki.png',
    icon: Icons.escalator_warning_rounded,
  );
  const manghod = _FamilyWord(
    hil: 'manghod',
    eng: 'manghod',
    imageAsset: 'assets/images/level_game/people/bata-nga-babayi.png',
    icon: Icons.child_friendly_rounded,
  );

  return switch (lessonNumber) {
    1 => const [nanay, tatay, bata],
    2 => const [lola, lolo, nanay],
    3 => const [magulang, manghod, lola, tatay],
    _ => const [nanay, tatay, bata, lola, lolo, magulang, manghod],
  };
}

List<_FamilyWord> _familyChoicesFor(
  _FamilyWord target,
  List<_FamilyWord> words,
  int count,
) {
  final pool = words.isEmpty ? [target] : words;
  final selected = <_FamilyWord>[];
  if (count == 2) {
    final distractor = pool.firstWhere(
      (word) => word.hil != target.hil,
      orElse: () => target,
    );
    selected.addAll([distractor, target]);
  } else {
    selected.addAll(pool.take(count));
    if (!selected.any((word) => word.hil == target.hil)) {
      selected[selected.length - 1] = target;
    }
  }
  return selected;
}

List<_FamilyWord> _familyHouseTargets(List<_FamilyWord> words) {
  final targets = ['nanay', 'tatay', 'bata']
      .map((name) => _familyWordByHil(words, name))
      .whereType<_FamilyWord>()
      .toList();
  if (targets.length >= 3) return targets.take(3).toList();
  return words.take(math.min(3, words.length)).toList();
}

List<_FamilyWord> _familyVisitorTargets(List<_FamilyWord> words) {
  final targets = ['lola', 'lolo', 'nanay']
      .map((name) => _familyWordByHil(words, name))
      .whereType<_FamilyWord>()
      .toList();
  if (targets.length >= 3) return targets.take(3).toList();
  return words.take(math.min(3, words.length)).toList();
}

List<_FamilyWord> _familyPhotoTargets(List<_FamilyWord> words) {
  final targets = ['magulang', 'manghod', 'lola', 'tatay']
      .map((name) => _familyWordByHil(words, name))
      .whereType<_FamilyWord>()
      .toList();
  if (targets.length >= 4) return targets.take(4).toList();
  final fallback = [...targets];
  for (final word in words) {
    if (fallback.length >= 4) break;
    if (!fallback.any((item) => item.hil == word.hil)) fallback.add(word);
  }
  return fallback;
}

List<_FamilyPhotoPlacement> _familyPhotoPlacements(List<_FamilyWord> words) {
  const defaults = [
    ('magulang', 'wala', Alignment(-.58, -.40)),
    ('manghod', 'tuo', Alignment(.58, -.40)),
    ('lola', 'ubos nga wala', Alignment(-.58, .44)),
    ('tatay', 'ubos nga tuo', Alignment(.58, .44)),
  ];
  final placements = <_FamilyPhotoPlacement>[];
  for (final item in defaults) {
    final word = _familyWordByHil(words, item.$1);
    if (word == null) continue;
    placements.add(
      _FamilyPhotoPlacement(member: word, place: item.$2, alignment: item.$3),
    );
  }
  if (placements.isNotEmpty) return placements;

  const fallbackAlignments = [
    Alignment(-.58, -.40),
    Alignment(.58, -.40),
    Alignment(-.58, .44),
    Alignment(.58, .44),
  ];
  const fallbackPlaces = ['wala', 'tuo', 'ubos nga wala', 'ubos nga tuo'];
  return [
    for (var index = 0; index < words.length && index < 4; index++)
      _FamilyPhotoPlacement(
        member: words[index],
        place: fallbackPlaces[index],
        alignment: fallbackAlignments[index],
      ),
  ];
}

_FamilyWord? _familyWordByHil(List<_FamilyWord> words, String hil) {
  for (final word in words) {
    if (word.hil == hil) return word;
  }
  return null;
}

String _familyQuestionName(_FamilyWord word) {
  return switch (word.hil) {
    'nanay' => 'mother',
    'tatay' => 'father',
    'bata' => 'child',
    'lola' => 'grandmother',
    'lolo' => 'grandfather',
    'magulang' => 'older sibling',
    'manghod' => 'younger sibling',
    _ => word.hil,
  };
}

String _cleanFamilyPrompt(String prompt) {
  return prompt
      .replaceAll('â€¦', '...')
      .replaceAll('…', '...')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _GradeOneAnimalLesson extends StatefulWidget {
  final LevelContent content;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAnimalLesson({
    required this.content,
    required this.onQuizCorrect,
  });

  @override
  State<_GradeOneAnimalLesson> createState() => _GradeOneAnimalLessonState();
}

class _GradeOneAnimalLessonState extends State<_GradeOneAnimalLesson> {
  int _stepIndex = 0;
  bool _reportedComplete = false;

  void _goToStep(int index, int maxIndex) {
    final next = index.clamp(0, maxIndex);
    if (next == _stepIndex) return;
    setState(() => _stepIndex = next);
  }

  void _advanceAfterCorrect(int maxIndex) {
    final completedStep = _stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _stepIndex != completedStep) return;
      _goToStep(completedStep + 1, maxIndex);
    });
  }

  void _markComplete() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    for (var index = 0; index < _lessonQuizCount; index++) {
      widget.onQuizCorrect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animals = _animalsForLesson(widget.content.lessonNumber);
    var maxIndex = 0;
    final steps = [
      for (final animal in animals) ...[
        _AlphabetFadeStep(
          child: _AnimalTapCard(
            key: ValueKey('animal-tap-${widget.content.id}-${animal.hil}'),
            animal: animal,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
        _AlphabetFadeStep(
          child: _AnimalHomeDragCard(
            key: ValueKey('animal-drag-${widget.content.id}-${animal.hil}'),
            animal: animal,
            onDone: () => _advanceAfterCorrect(maxIndex),
          ),
        ),
      ],
      _AlphabetFadeStep(
        child: _QuizTimeSplash(
          onDone: () => _goToStep(_stepIndex + 1, maxIndex),
        ),
      ),
      _AlphabetFadeStep(
        child: _AnimalReviewCard(
          key: ValueKey('animal-review-${widget.content.id}'),
          animals: animals.take(3).toList(),
          onDone: _markComplete,
        ),
      ),
    ];
    maxIndex = steps.length - 1;
    final activeStep = steps[_stepIndex.clamp(0, maxIndex)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(390.0, constraints.maxWidth);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                reverseDuration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  key: ValueKey('animal-step-$_stepIndex'),
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: width, child: activeStep.child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimalWord {
  final String hil;
  final String eng;
  final String soundText;
  final String tapSpeech;
  final String dragHomeLabel;
  final String? imageAsset;
  final String? homeAsset;
  final IconData icon;
  final IconData homeIcon;
  final Color color;

  const _AnimalWord({
    required this.hil,
    required this.eng,
    required this.soundText,
    required this.tapSpeech,
    required this.dragHomeLabel,
    required this.icon,
    required this.homeIcon,
    required this.color,
    this.imageAsset,
    this.homeAsset,
  });

  String get upperName => hil.toUpperCase();
  String get tapInstruction => 'Ipindot ang $hil.';
  String get dragInstruction => 'Guyoda ang $hil pakadto sa $dragHomeLabel.';
  String get retryInstruction =>
      'Liwata. Guyoda ang $hil pakadto sa $dragHomeLabel.';
  String get successSpeech => 'Husto! Ara na ang $hil sa $dragHomeLabel.';
}

class _SpacedLessonWord extends StatelessWidget {
  final String word;
  final Color color;
  final double fontSize;
  final double spacing;

  const _SpacedLessonWord({
    required this.word,
    required this.color,
    required this.fontSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < letters.length; index++) ...[
            Text(
              letters[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: color,
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            if (index != letters.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

class _AnimalTapCard extends StatefulWidget {
  final _AnimalWord animal;
  final VoidCallback onDone;

  const _AnimalTapCard({super.key, required this.animal, required this.onDone});

  @override
  State<_AnimalTapCard> createState() => _AnimalTapCardState();
}

class _AnimalTapCardState extends State<_AnimalTapCard> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.animal.tapInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  Future<void> _tapAnimal() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.animal.soundText}! ${widget.animal.tapSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _tapped
          ? widget.animal.tapSpeech
          : 'Koka: ${widget.animal.tapInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SpacedLessonWord(
            word: widget.animal.upperName,
            color: TudloColors.forest,
            fontSize: 48,
            spacing: 10,
          ),
          const SizedBox(height: 42),
          GestureDetector(
            onTap: _tapAnimal,
            child: _AnimalBounce(
              active: _tapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 374,
                    height: 374,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tapped
                          ? widget.animal.color.withValues(alpha: .18)
                          : Colors.transparent,
                      boxShadow: _tapped
                          ? [
                              BoxShadow(
                                color: widget.animal.color.withValues(
                                  alpha: .34,
                                ),
                                blurRadius: 34,
                                spreadRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  _AnimalArt(animal: widget.animal, size: 352),
                  if (_tapped) const _AnimalSparkles(size: 390),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHomeDragCard extends StatefulWidget {
  final _AnimalWord animal;
  final VoidCallback onDone;

  const _AnimalHomeDragCard({
    super.key,
    required this.animal,
    required this.onDone,
  });

  @override
  State<_AnimalHomeDragCard> createState() => _AnimalHomeDragCardState();
}

class _AnimalHomeDragCardState extends State<_AnimalHomeDragCard> {
  bool _placed = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          widget.animal.dragInstruction,
          hiligaynon: true,
        ),
      );
    });
  }

  void _retry() {
    if (_placed) return;
    setState(() => _retrying = true);
    unawaited(
      TudloVoiceButton.speak(
        context,
        widget.animal.retryInstruction,
        hiligaynon: true,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _retrying = false);
    });
  }

  Future<void> _accept() async {
    if (_placed) return;
    setState(() => _placed = true);
    await TudloVoiceButton.speak(
      context,
      '${widget.animal.soundText}! ${widget.animal.successSpeech}',
      hiligaynon: true,
    );
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _placed
          ? 'Koka: ${widget.animal.successSpeech}'
          : _retrying
          ? 'Koka: ${widget.animal.retryInstruction}'
          : 'Koka: ${widget.animal.dragInstruction}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.animal.upperName,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final targetSize = math.min(236.0, width * .62);
              final animalSize = math.min(214.0, width * .56);
              final placedAnimalSize = math.min(142.0, targetSize * .58);

              return SizedBox(
                height: 390,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: 0,
                      top: 8,
                      child: _AnimalHomeTarget(
                        animal: widget.animal,
                        size: targetSize,
                        placed: _placed,
                        onAccept: _accept,
                        onWrongDrop: _retry,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 10,
                      child: _placed
                          ? SizedBox(width: animalSize, height: animalSize)
                          : _AnimalDraggable(
                              animal: widget.animal,
                              size: animalSize,
                              onMissed: _retry,
                            ),
                    ),
                    if (_placed)
                      Positioned(
                        right: (targetSize - placedAnimalSize) / 2,
                        top: 76,
                        child: _AnimalBounce(
                          active: true,
                          child: _AnimalArt(
                            animal: widget.animal,
                            size: placedAnimalSize,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimalReviewRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const _AnimalReviewRow({required this.children, required this.gap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _AnimalReviewSizedSlot extends StatelessWidget {
  final double size;
  final Widget child;

  const _AnimalReviewSizedSlot({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

class _AnimalReviewCard extends StatefulWidget {
  final List<_AnimalWord> animals;
  final VoidCallback onDone;

  const _AnimalReviewCard({
    super.key,
    required this.animals,
    required this.onDone,
  });

  @override
  State<_AnimalReviewCard> createState() => _AnimalReviewCardState();
}

class _AnimalReviewCardState extends State<_AnimalReviewCard> {
  final Set<String> _matched = {};
  String _message = 'Koka: Guyoda ang kada sapat pakadto sa iya puluy-an.';
  late final List<_AnimalWord> _homeOrder;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _homeOrder = _shuffledHomeOrder(widget.animals);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        TudloVoiceButton.speak(
          context,
          'Guyoda ang kada sapat pakadto sa iya puluy-an.',
          hiligaynon: true,
        ),
      );
    });
  }

  List<_AnimalWord> _shuffledHomeOrder(List<_AnimalWord> animals) {
    final shuffled = [...animals];
    if (shuffled.length < 2) return shuffled;

    shuffled.shuffle(math.Random());
    final sameOrder = List.generate(
      shuffled.length,
      (index) => shuffled[index].hil == animals[index].hil,
    ).every((same) => same);
    if (sameOrder) {
      final first = shuffled.removeAt(0);
      shuffled.add(first);
    }
    return shuffled;
  }

  Future<void> _handleDrop(_AnimalWord target, _AnimalWord dragged) async {
    if (_reported || _matched.contains(dragged.hil)) return;

    final spent = await AppData.spendQuestionEnergy();
    if (!spent) {
      if (mounted) await showLowEnergyDialog(context);
      return;
    }
    if (!mounted) return;

    if (target.hil != dragged.hil) {
      setState(() {
        _message = 'Koka: Liwata. Pangitaa ang puluy-an sang ${dragged.hil}.';
      });
      await TudloVoiceButton.speak(
        context,
        'Liwata. Pangitaa ang puluy-an sang ${dragged.hil}.',
        hiligaynon: true,
      );
      return;
    }

    setState(() {
      _matched.add(dragged.hil);
      _message = 'Koka: Husto! ${_titleCase(dragged.hil)}.';
    });
    await TudloVoiceButton.speak(
      context,
      '${dragged.soundText}! Husto! Ara na ang ${dragged.hil} sa ${dragged.dragHomeLabel}.',
      hiligaynon: true,
    );
    if (!mounted) return;
    if (_matched.length == widget.animals.length && !_reported) {
      _reported = true;
      setState(() {
        _message = 'Koka: Maayo gid! Kabalo ka na sang mga sapat sa palibot!';
      });
      await TudloVoiceButton.speak(
        context,
        'Maayo gid! Kabalo ka na sang mga sapat sa palibot!',
        hiligaynon: true,
      );
      if (mounted) widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalStage(
      mascotMessage: _message,
      maxWidth: 430,
      mascotScale: 1.13,
      mascotTop: 430,
      mascotRight: -30,
      child: Column(
        children: [
          Text(
            'Ipares ang Puluy-an',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 76),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemCount = widget.animals.length;
              final gap = itemCount > 2 ? 8.0 : 16.0;
              final itemSize = itemCount == 0
                  ? 0.0
                  : math
                        .min(
                          136.0,
                          (constraints.maxWidth - gap * (itemCount - 1)) /
                              itemCount,
                        )
                        .clamp(0.0, 136.0)
                        .toDouble();
              final dragSize = math.min(132.0, itemSize);

              return Column(
                children: [
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final animal in _homeOrder)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _ReviewHomeTarget(
                            animal: animal,
                            matched: _matched.contains(animal.hil),
                            size: itemSize,
                            onDrop: (dragged) => _handleDrop(animal, dragged),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _AnimalReviewRow(
                    gap: gap,
                    children: [
                      for (final animal in widget.animals)
                        _AnimalReviewSizedSlot(
                          size: itemSize,
                          child: _matched.contains(animal.hil)
                              ? SizedBox.square(dimension: dragSize)
                              : _AnimalDraggable(
                                  animal: animal,
                                  size: dragSize,
                                  onMissed: () {
                                    setState(() {
                                      _message =
                                          'Koka: Guyoda ang ${animal.hil} pakadto sa iya puluy-an.';
                                    });
                                  },
                                ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimalStage extends StatelessWidget {
  final Widget child;
  final String mascotMessage;
  final double maxWidth;
  final double mascotScale;
  final double mascotTop;
  final double mascotRight;

  const _AnimalStage({
    required this.child,
    required this.mascotMessage,
    this.maxWidth = 390,
    this.mascotScale = 1,
    this.mascotTop = 500,
    this.mascotRight = -18,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: 760,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 550,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: _StageContentScaler(child: child),
                ),
              ),
              Positioned(
                right: mascotRight,
                top: mascotTop,
                child: IgnorePointer(
                  child: _AlphabetMascotBubble(
                    message: mascotMessage,
                    scale: mascotScale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalDraggable extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final VoidCallback onMissed;

  const _AnimalDraggable({
    required this.animal,
    required this.size,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_AnimalWord>(
      data: animal,
      feedback: Material(
        color: Colors.transparent,
        child: _AnimalArt(animal: animal, size: size * 1.08),
      ),
      childWhenDragging: Opacity(
        opacity: .24,
        child: _AnimalArt(animal: animal, size: size),
      ),
      onDragEnd: (details) {
        if (!details.wasAccepted) onMissed();
      },
      child: _AnimalArt(animal: animal, size: size),
    );
  }
}

class _AnimalHomeTarget extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final bool placed;
  final VoidCallback onAccept;
  final VoidCallback onWrongDrop;

  const _AnimalHomeTarget({
    required this.animal,
    required this.size,
    required this.placed,
    required this.onAccept,
    required this.onWrongDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AnimalWord>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) {
        if (details.data.hil == animal.hil) {
          onAccept();
        } else {
          onWrongDrop();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return _AnimalHomeArt(
          animal: animal,
          size: size,
          active: candidateData.isNotEmpty,
          matched: placed,
          showLabel: false,
        );
      },
    );
  }
}

class _ReviewHomeTarget extends StatelessWidget {
  final _AnimalWord animal;
  final bool matched;
  final double size;
  final ValueChanged<_AnimalWord> onDrop;

  const _ReviewHomeTarget({
    required this.animal,
    required this.matched,
    required this.size,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AnimalWord>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        return _AnimalHomeArt(
          animal: animal,
          size: size,
          active: candidateData.isNotEmpty,
          matched: matched,
          showLabel: false,
        );
      },
    );
  }
}

class _AnimalArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalArt({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    if (animal.imageAsset != null) {
      return Image.asset(
        animal.imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            _AnimalIconArt(animal: animal, size: size),
      );
    }
    return _AnimalIconArt(animal: animal, size: size);
  }
}

class _AnimalIconArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalIconArt({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: animal.color.withValues(alpha: .18),
        boxShadow: [
          BoxShadow(
            color: animal.color.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(animal.icon, color: animal.color, size: size * .58),
    );
  }
}

class _AnimalHomeArt extends StatelessWidget {
  final _AnimalWord animal;
  final double size;
  final bool active;
  final bool matched;
  final bool showLabel;

  const _AnimalHomeArt({
    required this.animal,
    required this.size,
    required this.active,
    required this.matched,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final home = animal.homeAsset == null
        ? _AnimalHomeIcon(animal: animal, size: size)
        : Image.asset(
            animal.homeAsset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _AnimalHomeIcon(animal: animal, size: size),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: showLabel ? size + 42 : size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        boxShadow: active || matched
            ? [
                BoxShadow(
                  color: TudloColors.green.withValues(alpha: .24),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Center(child: home),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              _titleCase(animal.dragHomeLabel),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: TudloColors.ink,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimalHomeIcon extends StatelessWidget {
  final _AnimalWord animal;
  final double size;

  const _AnimalHomeIcon({required this.animal, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * .88,
      height: size * .88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TudloColors.softGreen.withValues(alpha: .82),
      ),
      child: Icon(animal.homeIcon, color: TudloColors.forest, size: size * .48),
    );
  }
}

class _AnimalBounce extends StatelessWidget {
  final bool active;
  final Widget child;

  const _AnimalBounce({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final jump = -math.sin(value * math.pi) * 34;
        return Transform.translate(
          offset: Offset(0, jump),
          child: Transform.scale(scale: 1 + value * .04, child: child),
        );
      },
      child: child,
    );
  }
}

class _AnimalSparkles extends StatelessWidget {
  final double size;

  const _AnimalSparkles({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: const [
          Positioned(
            top: 18,
            right: 42,
            child: _Sparkle(color: TudloColors.gold, size: 18),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: _Sparkle(color: TudloColors.green, size: 13),
          ),
          Positioned(
            bottom: 48,
            right: 24,
            child: _Sparkle(color: TudloColors.gold, size: 15),
          ),
          Positioned(
            bottom: 30,
            left: 56,
            child: _Sparkle(color: TudloColors.green, size: 11),
          ),
        ],
      ),
    );
  }
}

List<_AnimalWord> _animalsForLesson(int lessonNumber) {
  const dog = _AnimalWord(
    hil: 'ido',
    eng: 'ido',
    soundText: 'aw aw',
    tapSpeech: 'Ido. Ang ido nagatahol.',
    dragHomeLabel: 'iya balay',
    imageAsset: 'assets/images/level_game/animals/dog.png',
    homeAsset: 'assets/images/level_game/dog-house.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_rounded,
    color: TudloColors.orange,
  );
  const cat = _AnimalWord(
    hil: 'kuring',
    eng: 'kuring',
    soundText: 'ngiyaw',
    tapSpeech: 'Kuring. Ang kuring nagingiyaw.',
    dragHomeLabel: 'iya balay',
    imageAsset: 'assets/images/level_game/animals/cat.png',
    homeAsset: 'assets/images/level_game/cat-house.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_rounded,
    color: TudloColors.coral,
  );
  const chicken = _AnimalWord(
    hil: 'manok',
    eng: 'manok',
    soundText: 'tok tok',
    tapSpeech: 'Manok. Ang manok nagapotok.',
    dragHomeLabel: 'tangkal',
    imageAsset: 'assets/images/level_game/animals/chicken.png',
    homeAsset: 'assets/images/level_game/chicken-house.png',
    icon: Icons.egg_alt_rounded,
    homeIcon: Icons.home_work_rounded,
    color: TudloColors.gold,
  );
  const pig = _AnimalWord(
    hil: 'baboy',
    eng: 'baboy',
    soundText: 'oynk oynk',
    tapSpeech: 'Baboy. Ang baboy naga-ukoy.',
    dragHomeLabel: 'iya kulungan',
    imageAsset: 'assets/images/level_game/animals/pig.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.home_work_rounded,
    color: TudloColors.coral,
  );
  const cow = _AnimalWord(
    hil: 'baka',
    eng: 'baka',
    soundText: 'moo',
    tapSpeech: 'Baka. Ang baka nagangaaw.',
    dragHomeLabel: 'hilamunan',
    imageAsset: 'assets/images/level_game/animals/cow.png',
    icon: Icons.agriculture_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.blue,
  );
  const carabao = _AnimalWord(
    hil: 'karbaw',
    eng: 'karbaw',
    soundText: 'ngaa',
    tapSpeech: 'Karbaw. Ang karbaw nagahuni.',
    dragHomeLabel: 'palayan',
    imageAsset: 'assets/images/level_game/animals/carabao.png',
    icon: Icons.agriculture_rounded,
    homeIcon: Icons.agriculture_rounded,
    color: TudloColors.forest,
  );
  const fish = _AnimalWord(
    hil: 'isda',
    eng: 'isda',
    soundText: 'bulubula',
    tapSpeech: 'Isda. Ang isda nagalangoy.',
    dragHomeLabel: 'tubig',
    imageAsset: 'assets/images/level_game/animals/fish.png',
    icon: Icons.water_rounded,
    homeIcon: Icons.water_rounded,
    color: TudloColors.blue,
  );
  const bird = _AnimalWord(
    hil: 'pispis',
    eng: 'pispis',
    soundText: 'tsirit tsirit',
    tapSpeech: 'Pispis. Ang pispis nagahuni.',
    dragHomeLabel: 'iya pugad',
    imageAsset: 'assets/images/level_game/animals/bird.png',
    icon: Icons.flutter_dash_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.green,
  );
  const goat = _AnimalWord(
    hil: 'kanding',
    eng: 'kanding',
    soundText: 'mee mee',
    tapSpeech: 'Kanding. Ang kanding nagame.',
    dragHomeLabel: 'hilamunan',
    imageAsset: 'assets/images/level_game/animals/goat.png',
    icon: Icons.pets_rounded,
    homeIcon: Icons.park_rounded,
    color: TudloColors.meadow,
  );

  return switch (lessonNumber) {
    1 => const [dog, cat, chicken],
    2 => const [pig, cow, carabao],
    3 => const [fish, bird, goat],
    _ => const [dog, cat, chicken, pig, cow, carabao, fish, bird, goat],
  };
}

String _titleCase(String value) {
  if (value.trim().isEmpty) return value;
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        final letters = word.characters.toList();
        if (letters.isEmpty) return '';
        return '${letters.first.toUpperCase()}${letters.skip(1).join().toLowerCase()}';
      })
      .join(' ');
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
          _StoryIllustration(imagePath: _storyImagePathForActiveGrade()),
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
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const _StoryImageFallback(),
            ),
          ),
        ],
      ),
    );
  }
}

String _storyImagePathForActiveGrade() {
  return switch (AppData.selectedGradeLevel) {
    GradeLevel.grade1 => 'assets/images/level_game/empty-poem-page.png',
    GradeLevel.grade2 => 'assets/images/level_game/classroom.png',
    GradeLevel.grade3 => 'assets/images/level_game/empty-poem-page.png',
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
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final bool Function() onClaimXp;
  final VoidCallback onBackToMap;
  final FutureOr<void> Function() onContinue;

  const _LessonCompleteDialog({
    required this.level,
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
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final VoidCallback onBackToMap;
  final FutureOr<void> Function() onContinue;

  const _LessonResultPage({
    super.key,
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
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/level_game/lesson-game-assets/quiz-bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          Container(color: Colors.white.withValues(alpha: .24)),
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
            padding: EdgeInsets.fromLTRB(24, 26, 24, 24 + bottom),
            child: Column(
              children: [
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(
                      left: 26,
                      top: 82,
                      child: _ResultSparkle(),
                    ),
                    const Positioned(
                      right: 36,
                      top: 42,
                      child: _ResultSparkle(),
                    ),
                    const Positioned(
                      right: 24,
                      bottom: 42,
                      child: _ResultSparkle(),
                    ),
                    TudloMascot(
                      size: (size.width * .62).clamp(230.0, 360.0),
                      mood: KokaMood.hi,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'Natapos mo na ang Leksyon!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: (size.width * .083).clamp(32.0, 50.0),
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  accuracy == 100 ? 'Take a bow!' : 'Maayo gid!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: (size.width * .055).clamp(24.0, 36.0),
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(flex: 1),
                Row(
                  children: [
                    Expanded(
                      child: _ResultStatBox(
                        label: 'KAHUSTOAN',
                        value: '$accuracy%',
                        icon: Icons.track_changes_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultStatBox(
                        label: 'ORAS',
                        value: durationLabel,
                        icon: Icons.timer_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultStatBox(
                        label: 'SA PAG LIWAT',
                        value: '$mistakes',
                        icon: Icons.refresh_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
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
                TudloMascot(
                  size: (size.width * .58).clamp(220.0, 340.0),
                  mood: KokaMood.curious,
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

class _ResultSparkle extends StatelessWidget {
  const _ResultSparkle();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: TudloColors.meadow.withValues(alpha: .78),
      size: 36,
    );
  }
}

class _ResultStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultStatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.nunito(
                color: TudloColors.forest,
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: TudloColors.forest, size: 30),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                      color: TudloColors.forest,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
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
                    child: TudloMascot(size: mascotSize),
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
                child: TudloMascot(size: 148),
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
                child: TudloMascot(size: 150),
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
          TudloMascot(
            size: 102,
            mood: correct ? KokaMood.hi : KokaMood.annoyed,
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
