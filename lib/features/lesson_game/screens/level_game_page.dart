import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';
import 'package:tudloapp/core/widgets/word_tooltip.dart';
import 'package:tudloapp/features/energy/widgets/energy_indicator.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';

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
  late final DateTime _levelStartedAt;
  bool _rewardsClaimed = false;
  bool _completeDialogShown = false;

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
      questions = content.quizItems.map(_questionFromQuizItem).toList();
      return content;
    }();
    _levelStartedAt = DateTime.now();
  }

  void _claimRewardsOnce() {
    if (_rewardsClaimed) return;
    _rewardsClaimed = true;

    // Progress is saved only when the learner taps the completion button.
    // This prevents repeated completion interactions from saving twice.
    AppData.saveLevelScore(widget.level, score, questions.length);
    if (AppData.unlockedLevel <= widget.level &&
        widget.level < AppData.maxLevel) {
      AppData.unlockedLevel = widget.level + 1;
    }
    AppStateScope.of(context).saveActiveProfileProgress();
  }

  void _handleQuestionChecked(
    int index,
    bool correct, {
    bool autoComplete = true,
  }) {
    if (_completeDialogShown) return;
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

  void _submitCompletedPage() {
    if (_completeDialogShown) return;
    final allCorrect =
        questions.isNotEmpty &&
        List.generate(
          questions.length,
          (itemIndex) => correctAnswers[itemIndex] == true,
        ).every((correct) => correct);
    if (!allCorrect) return;
    _completeDialogShown = true;
    _showCompleteDialog();
  }

  void _showCompleteDialog() {
    // The completion dialog shows lesson results. Progress updates only after
    // the learner returns to the map.
    final accuracy = questions.isEmpty
        ? 0
        : ((score / questions.length) * 100).round();
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
        mistakes: questions.length - score,
        durationLabel: durationLabel,
        onClaim: () {
          _claimRewardsOnce();
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
            (route) => false,
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
                    const TudloMascot(size: 138),
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
                              // Leave button:
                              // Discards this attempt and returns to the
                              // previous page without saving progress.
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
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
                              // Stay here button:
                              // Closes the popup and resumes the lesson.
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

    if (!mounted || shouldExit != true) return;
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
      return LessonQuestion.matching(
        prompt: item.question,
        leftItems: item.leftItems,
        rightItems: item.rightItems,
        directionLabel: item.id,
      );
    }
    if (item.type == QuizType.fillBlankChoice) {
      return LessonQuestion.fillBlank(
        prompt: item.question,
        answer: item.answer,
        choices: item.choices,
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
        sentenceWords: item.choices,
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
        choices: item.choices,
        imagePath: item.imageAsset ?? '',
        targetPhrase: item.answer,
        targetMeaning: item.answer,
        directionLabel: item.id,
      );
    }
    return LessonQuestion.choice(
      prompt: item.question,
      answer: item.answer,
      choices: item.choices,
      imagePath: item.imageAsset ?? '',
      targetPhrase: item.answer,
      targetMeaning: item.answer,
      directionLabel: item.id,
    );
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
        final progress = questions.isEmpty
            ? 0.0
            : checkedCount / questions.length;
        final alphabetCanSubmit =
            alphabetLesson &&
            questions.isNotEmpty &&
            List.generate(
              questions.length,
              (itemIndex) => correctAnswers[itemIndex] == true,
            ).every((correct) => correct);

        return Scaffold(
          backgroundColor: TudloColors.paper,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                18,
              ),
              child: Column(
                children: [
                  Row(
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: progressHeight,
                            backgroundColor: TudloColors.line,
                            color: TudloColors.green,
                          ),
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
                  const SizedBox(height: 26),
                  Expanded(
                    child: loading || levelContent == null
                        ? const _LessonLoadingCard()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LevelIntroHeader(
                                  level: widget.level,
                                  title: levelContent.title,
                                ),
                                if (alphabetLesson) ...[
                                  const SizedBox(height: 16),
                                  _GradeOneAlphabetLesson(
                                    content: levelContent,
                                    canSubmit: alphabetCanSubmit,
                                    onSubmit: _submitCompletedPage,
                                    onQuizCorrect: (index) =>
                                        _handleQuestionChecked(
                                          index,
                                          true,
                                          autoComplete: false,
                                        ),
                                  ),
                                ] else ...[
                                  if (levelContent.story?.trim().isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 18),
                                    _StoryLessonSection(
                                      content: _displayContent(levelContent),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  _LearningSection(
                                    title: 'Leksiyon',
                                    accentColor: TudloColors.green,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _VoiceMessage(
                                          text: levelContent.lesson,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _LevelQuizCard(
                                        key: ValueKey(
                                          '${widget.level}-${entry.key}-${entry.value.prompt}',
                                        ),
                                        number: entry.key + 1,
                                        question: entry.value,
                                        onChecked: (correct) =>
                                            _handleQuestionChecked(
                                              entry.key,
                                              correct,
                                            ),
                                      ),
                                    );
                                  }),
                                ],
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
            TudloMascot(size: 110),
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

class _GradeOneAlphabetLesson extends StatelessWidget {
  final LevelContent content;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final ValueChanged<int> onQuizCorrect;

  const _GradeOneAlphabetLesson({
    required this.content,
    required this.canSubmit,
    required this.onSubmit,
    required this.onQuizCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final anchors = _alphabetAnchorsFor(content.lessonNumber);
    final targets = _targetLettersFor(content);
    final quizActivities = content.quizItems.asMap().entries.map((entry) {
      final target = _targetLetterForQuiz(entry.value, targets);
      final anchor = _bestAnchorForTarget(
        anchors,
        target,
        prompt: entry.value.question,
      );
      return _AlphabetMiniActivity(
        key: ValueKey('alphabet-quiz-${content.id}-${entry.value.id}'),
        sectionLabel: 'Pagtilaw',
        word: anchor.word,
        meaning: anchor.meaning,
        imageAsset: anchor.imageAsset,
        icon: anchor.icon,
        targetLetters: [target],
        instruction: _instructionForQuiz(entry.value, target),
        mascotMessage: 'Koka: Pamatii, dayon tap-a ang husto nga letra.',
        onCorrect: () => onQuizCorrect(entry.key),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AlphabetGuideCard(content: content),
        const SizedBox(height: 14),
        _AlphabetSectionLabel(title: 'Leksiyon'),
        const SizedBox(height: 10),
        for (final anchor in anchors) ...[
          _AlphabetMiniActivity(
            sectionLabel: 'Leksiyon',
            word: anchor.word,
            meaning: anchor.meaning,
            imageAsset: anchor.imageAsset,
            icon: anchor.icon,
            targetLetters: anchor.targets,
            instruction:
                'Tap-a ang mga letra ${anchor.targets.join(", ")} sa tinaga.',
            mascotMessage:
                'Koka: Ini ang tinaga ${anchor.word}. Tap-a ang kada letra.',
          ),
          const SizedBox(height: 14),
        ],
        _AlphabetSectionLabel(title: 'Mga Halimbawa'),
        const SizedBox(height: 10),
        for (final target in targets) ...[
          Builder(
            builder: (context) {
              final anchor = _bestAnchorForTarget(anchors, target);
              return _AlphabetMiniActivity(
                sectionLabel: 'Gamita Ini',
                word: anchor.word,
                meaning: anchor.meaning,
                imageAsset: anchor.imageAsset,
                icon: anchor.icon,
                targetLetters: [target],
                instruction:
                    'May $target sa ${anchor.word}. Pamatii ang /${target.toLowerCase()}/.',
                mascotMessage:
                    'Koka: Ang letra $target may tingog nga /${target.toLowerCase()}/.',
              );
            },
          ),
          const SizedBox(height: 14),
        ],
        _AlphabetSectionLabel(title: 'Pagtilaw'),
        const SizedBox(height: 10),
        ...quizActivities.expand((card) => [card, const SizedBox(height: 14)]),
        const SizedBox(height: 8),
        _AlphabetSubmitButton(enabled: canSubmit, onPressed: onSubmit),
      ],
    );
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

  String _targetLetterForQuiz(QuizItem item, List<String> targets) {
    final combined = '${item.answer} ${item.question}'.toUpperCase();
    for (final target in targets) {
      if (RegExp('\\b$target\\b').hasMatch(combined) ||
          combined.contains('/$target/')) {
        return target;
      }
    }
    return targets.isEmpty
        ? item.answer.characters.first.toUpperCase()
        : targets.first;
  }

  String _instructionForQuiz(QuizItem item, String target) {
    final question = item.question.trim();
    final soundMatch = RegExp(r'/([^/]+)/').firstMatch(question);
    if (soundMatch != null) {
      return 'Tap the letter that makes /${soundMatch.group(1)}/.';
    }
    if (question.toLowerCase().contains('diin')) return question;
    return 'Pamatii ang tingog kag tap-a ang letra $target.';
  }

  _AlphabetAnchor _bestAnchorForTarget(
    List<_AlphabetAnchor> anchors,
    String target, {
    String prompt = '',
  }) {
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
            meaning: 'mother',
            targets: ['N', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/nanay.png',
            icon: Icons.family_restroom_rounded,
          ),
          _AlphabetAnchor(
            word: 'TATAY',
            meaning: 'father',
            targets: ['T', 'A', 'Y'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/tatay.png',
            icon: Icons.family_restroom_rounded,
          ),
        ];
      case 2:
        return const [
          _AlphabetAnchor(
            word: 'IDO',
            meaning: 'dog',
            targets: ['I', 'D', 'O'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/dog.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 3:
        return const [
          _AlphabetAnchor(
            word: 'MANOK',
            meaning: 'chicken',
            targets: ['M', 'K'],
            icon: Icons.egg_alt_rounded,
          ),
          _AlphabetAnchor(
            word: 'KURING',
            meaning: 'cat',
            targets: ['K', 'U'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/cat.png',
            icon: Icons.pets_rounded,
          ),
        ];
      case 4:
        return const [
          _AlphabetAnchor(
            word: 'BALAY',
            meaning: 'house',
            targets: ['B', 'L'],
            icon: Icons.home_rounded,
          ),
          _AlphabetAnchor(
            word: 'LOLA',
            meaning: 'grandmother',
            targets: ['L'],
            icon: Icons.elderly_woman_rounded,
          ),
          _AlphabetAnchor(
            word: 'ISDA',
            meaning: 'fish',
            targets: ['S'],
            icon: Icons.water_rounded,
          ),
        ];
      case 5:
        return const [
          _AlphabetAnchor(
            word: 'ESKWELAHAN',
            meaning: 'school',
            targets: ['E'],
            icon: Icons.school_rounded,
          ),
          _AlphabetAnchor(
            word: 'GATAS',
            meaning: 'milk',
            targets: ['G'],
            icon: Icons.local_drink_rounded,
          ),
          _AlphabetAnchor(
            word: 'PAMILYA',
            meaning: 'family',
            targets: ['P'],
            icon: Icons.diversity_3_rounded,
          ),
        ];
      case 6:
      default:
        return const [
          _AlphabetAnchor(
            word: 'DOKTOR',
            meaning: 'doctor',
            targets: ['R'],
            icon: Icons.medical_services_rounded,
          ),
          _AlphabetAnchor(
            word: 'HOSPITAL',
            meaning: 'hospital',
            targets: ['H'],
            icon: Icons.local_hospital_rounded,
          ),
          _AlphabetAnchor(
            word: 'KARBAW',
            meaning: 'carabao',
            targets: ['W'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/cow.png',
            icon: Icons.agriculture_rounded,
          ),
          _AlphabetAnchor(
            word: 'CAT',
            meaning: 'cat',
            targets: ['C'],
            imageAsset: 'assets/images/level_game/Grade1/unit1/lesson1/cat.png',
            icon: Icons.pets_rounded,
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
  final IconData icon;

  const _AlphabetAnchor({
    required this.word,
    required this.meaning,
    required this.targets,
    required this.icon,
    this.imageAsset,
  });
}

class _AlphabetGuideCard extends StatelessWidget {
  final LevelContent content;

  const _AlphabetGuideCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final firstLine = content.lesson.split('\n').first.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE4FFD1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TudloColors.green, width: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TudloMascot(size: 86),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Koka nga Manuggiya',
                  style: TextStyle(
                    color: TudloColors.forest,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  firstLine.isEmpty
                      ? 'Pamatii ang tingog kag tap-a ang husto nga letra.'
                      : firstLine,
                  style: const TextStyle(
                    color: TudloColors.ink,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
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

class _AlphabetSectionLabel extends StatelessWidget {
  final String title;

  const _AlphabetSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: TudloColors.forest,
        fontSize: 30,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AlphabetSubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _AlphabetSubmitButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: TudloColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: TudloColors.line,
          disabledForegroundColor: TudloColors.muted,
          elevation: enabled ? 6 : 0,
          shadowColor: TudloColors.forest.withValues(alpha: .30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        child: const Text('IPASA'),
      ),
    );
  }
}

class _AlphabetMiniActivity extends StatefulWidget {
  final String sectionLabel;
  final String word;
  final String meaning;
  final String? imageAsset;
  final IconData icon;
  final List<String> targetLetters;
  final String instruction;
  final String mascotMessage;
  final VoidCallback? onCorrect;

  const _AlphabetMiniActivity({
    super.key,
    required this.sectionLabel,
    required this.word,
    required this.meaning,
    required this.icon,
    required this.targetLetters,
    required this.instruction,
    required this.mascotMessage,
    this.imageAsset,
    this.onCorrect,
  });

  @override
  State<_AlphabetMiniActivity> createState() => _AlphabetMiniActivityState();
}

class _AlphabetMiniActivityState extends State<_AlphabetMiniActivity> {
  int? _selectedIndex;
  bool _correct = false;
  bool _wrong = false;
  bool _reported = false;
  String _feedback = 'Pamatii anay, dayon tap-a ang letra.';
  int _motionKey = 0;

  Set<String> get _targets =>
      widget.targetLetters.map((letter) => letter.toUpperCase()).toSet();

  Future<void> _handleLetterTap(String letter, int index) async {
    await TudloVoiceButton.speak(context, _soundFor(letter), hiligaynon: true);
    final isCorrect = _targets.contains(letter.toUpperCase());
    setState(() {
      _selectedIndex = index;
      _correct = isCorrect;
      _wrong = !isCorrect;
      _feedback = isCorrect
          ? 'Husto! Maayo gid.'
          : 'Sulayi liwat. Pamatii liwat ang tingog.';
      _motionKey++;
    });
    if (isCorrect && !_reported) {
      _reported = true;
      widget.onCorrect?.call();
    }
    if (!isCorrect) {
      Future<void>.delayed(const Duration(milliseconds: 760), () {
        if (!mounted || _correct) return;
        setState(() => _wrong = false);
      });
    }
  }

  String _soundFor(String letter) => '/${letter.toLowerCase()}/';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFAEEBFF), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: TudloColors.ink.withValues(alpha: .06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.sectionLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TudloColors.forest,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TappableWord(
                    word: widget.word,
                    targetLetters: widget.targetLetters,
                    selectedIndex: _selectedIndex,
                    correct: _correct,
                    wrong: _wrong,
                    motionKey: _motionKey,
                    onLetterTap: _handleLetterTap,
                  ),
                  const SizedBox(height: 18),
                  _AlphabetAnchorImage(
                    imageAsset: widget.imageAsset,
                    icon: widget.icon,
                    word: _displayWord(widget.word),
                    meaning: widget.meaning,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FFD8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: TudloColors.green, width: 2),
                    ),
                    child: Row(
                      children: [
                        TudloVoiceButton(
                          message: widget.instruction,
                          tooltip: 'Pamatii ang instruksyon',
                          size: 50,
                          hiligaynon: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.instruction,
                            style: const TextStyle(
                              color: TudloColors.ink,
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7C7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: TudloColors.gold, width: 2),
                    ),
                    child: Text(
                      _correct || _wrong ? _feedback : widget.mascotMessage,
                      style: const TextStyle(
                        color: TudloColors.ink,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -18,
              bottom: 20,
              child: IgnorePointer(child: TudloMascot(size: 92)),
            ),
          ],
        ),
      ),
    );
  }

  String _displayWord(String word) {
    return word.isEmpty
        ? word
        : word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
}

class TappableWord extends StatelessWidget {
  final String word;
  final List<String> targetLetters;
  final int? selectedIndex;
  final bool correct;
  final bool wrong;
  final int motionKey;
  final void Function(String letter, int index) onLetterTap;

  const TappableWord({
    super.key,
    required this.word,
    required this.targetLetters,
    required this.onLetterTap,
    this.selectedIndex,
    this.correct = false,
    this.wrong = false,
    this.motionKey = 0,
  });

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < letters.length; index++)
          _TappableLetterCard(
            key: ValueKey('$word-$index-${letters[index]}-$motionKey'),
            letter: letters[index],
            imageAsset: _letterAssetFor(letters[index]),
            selected: selectedIndex == index,
            correct: selectedIndex == index && correct,
            wrong: selectedIndex == index && wrong,
            onTap: () => onLetterTap(letters[index], index),
          ),
      ],
    );
  }

  String? _letterAssetFor(String letter) {
    return const {
      'A': 'assets/images/level_game/Grade1/unit1/A.png',
      'N': 'assets/images/level_game/Grade1/unit1/N.png',
      'T': 'assets/images/level_game/Grade1/unit1/T.png',
      'Y': 'assets/images/level_game/Grade1/unit1/Y.png',
    }[letter.toUpperCase()];
  }
}

class _TappableLetterCard extends StatelessWidget {
  final String letter;
  final String? imageAsset;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  const _TappableLetterCard({
    super.key,
    required this.letter,
    this.imageAsset,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct
        ? const Color(0xFFE7FFD9)
        : selected
        ? TudloColors.gold
        : const Color(0xFFFFFBEA);
    return _FeedbackMotion(
      correct: correct,
      wrong: wrong,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 58,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: correct
                    ? TudloColors.forest
                    : selected
                    ? TudloColors.orange
                    : TudloColors.line,
                width: 3,
              ),
              boxShadow: correct
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: .72),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: TudloColors.green.withValues(alpha: .28),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: imageAsset == null
                ? Text(
                    letter,
                    style: const TextStyle(
                      color: TudloColors.ink,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AlphabetAnchorImage extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;
  final String word;
  final String meaning;

  const _AlphabetAnchorImage({
    required this.imageAsset,
    required this.icon,
    required this.word,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: TudloColors.green, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
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
          const SizedBox(height: 6),
          Text(
            word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            meaning,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.muted,
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
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

class _LevelQuizCard extends StatefulWidget {
  final int number;
  final LessonQuestion question;
  final ValueChanged<bool> onChecked;

  const _LevelQuizCard({
    super.key,
    required this.number,
    required this.question,
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
    setState(() {
      checked = true;
      lastCorrect = correct;
      answerFeedbackAttempt++;
    });
    if (correct) {
      widget.onChecked(true);
      return;
    }
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
          final expected = _expectedMatch(left);
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

  String _expectedMatch(String left) {
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
      if (matches[left] != _expectedMatch(left)) return false;
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
      'Kumusta ka?': 'How are you',
      'Salamat gid.': 'Thank you',
      'Palihog, gusto ko sang tubig.': 'Please, I want water',
      'Nagkaon ako sang kan-on': 'I am eating rice',
      'Palihog hatag sang tubig': 'Please give the water',
      'Nagabasa ako sang libro': 'I am reading a book',
      'Nagakadto ako sa eskwelahan': 'I am going to school',
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: TudloColors.line, width: 4),
            boxShadow: [
              BoxShadow(
                color: TudloColors.ink.withValues(alpha: .06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
  final int level;
  final String title;

  const _LevelIntroHeader({required this.level, required this.title});

  @override
  Widget build(BuildContext context) {
    final localLevel = ((level - 1) % AppData.unitLevels) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Leksiyon $localLevel',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TudloColors.blue,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TudloColors.ink,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TudloColors.line, width: 4),
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFAEEBFF), width: 4),
      ),
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
        border: Border.all(color: TudloColors.forest, width: 2),
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
    GradeLevel.grade1 =>
      'assets/images/level_game/Grade1/unit1/lesson1/story.png',
    GradeLevel.grade2 =>
      'assets/images/level_game/Grade2/unit1/lesson1/story.png',
    GradeLevel.grade3 =>
      'assets/images/level_game/Grade3/unit1/lesson1/story.png',
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FFE8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD21E), width: 3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: TudloColors.ink,
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VoiceMessage extends StatelessWidget {
  final String text;

  const _VoiceMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: TudloColors.softGreen.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TudloVoiceButton(
            message: text,
            tooltip: 'Pamatii',
            size: 58,
            hiligaynon: true,
          ),
          const SizedBox(width: 14),
          Expanded(
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
            border: Border.all(color: color.withValues(alpha: .68), width: 3),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
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
class _LessonCompleteDialog extends StatelessWidget {
  final int level;
  final int accuracy;
  final int mistakes;
  final String durationLabel;
  final VoidCallback onClaim;

  const _LessonCompleteDialog({
    required this.level,
    required this.accuracy,
    required this.mistakes,
    required this.durationLabel,
    required this.onClaim,
  });

  /// Star count is based on accuracy so the reward screen reflects performance.
  int get starCount {
    if (accuracy >= 90) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy > 0) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final modalWidth = (MediaQuery.sizeOf(context).width * .84)
        .clamp(300.0, 390.0)
        .toDouble();
    final bannerWidth = modalWidth * 1.08;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .92, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: ((value - .92) / .08).clamp(0, 1),
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: SizedBox(
          width: modalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 92),
                padding: const EdgeInsets.fromLTRB(18, 74, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF2),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: TudloColors.green.withValues(alpha: .24),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 28,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _Sparkle(color: TudloColors.green, size: 12),
                    ),
                    Positioned(
                      top: 90,
                      left: 2,
                      child: _Sparkle(color: TudloColors.meadow, size: 9),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TAPOS NA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.forest,
                            fontSize: 29,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const TudloMascot(size: 74),
                        const SizedBox(height: 6),
                        const Text(
                          'Maayo gid!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.forest,
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mistakes == 0
                              ? 'Himpit ang imo leksiyon!'
                              : 'Natapos mo ang leksiyon!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TudloColors.muted,
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RewardStatRow(
                          label: 'ORAS',
                          value: durationLabel,
                          icon: Icons.timer_rounded,
                        ),
                        const SizedBox(height: 10),
                        _RewardStatRow(
                          label: 'SCORE',
                          value: '$accuracy%',
                          icon: Icons.track_changes_rounded,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TudloColors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .3,
                              ),
                            ),
                            onPressed: onClaim,
                            child: const Text('BALIK SA MAPA'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 58,
                child: _RewardBanner(width: bannerWidth, level: level),
              ),
              Positioned(top: 0, child: _RewardStars(count: starCount)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  final double width;
  final int level;

  const _RewardBanner({required this.width, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * .34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/banner.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, .40),
            ),
          ),
          Positioned(
            top: width * .13,
            left: 0,
            right: 0,
            child: Text(
              'LEKSIYON ${((level - 1) % AppData.unitLevels) + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: (width * .045).clamp(16.0, 20.0),
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStars extends StatelessWidget {
  final int count;

  const _RewardStars({required this.count});

  //star size
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 162,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 27,
            child: Transform.rotate(
              angle: -.18,
              child: _RewardStar(active: count >= 1, size: 70),
            ),
          ),
          Positioned(
            right: 6,
            top: 27,
            child: Transform.rotate(
              angle: .18,
              child: _RewardStar(active: count >= 3, size: 70),
            ),
          ),
          Positioned(
            top: 0,
            child: Transform.rotate(
              angle: .05,
              child: _RewardStar(active: count >= 2, size: 90),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStar extends StatelessWidget {
  final bool active;
  final double size;

  const _RewardStar({required this.active, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFFFD84D) : TudloColors.line;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD84D).withValues(alpha: .42),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, color: color, size: size),
          if (active)
            Positioned(
              top: size * .23,
              right: size * .27,
              child: Icon(
                Icons.circle,
                color: Colors.white.withValues(alpha: .72),
                size: size * .12,
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RewardStatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TudloColors.green.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TudloColors.green.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TudloColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TudloColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: TudloColors.forest,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
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
                  border: Border.all(color: TudloColors.forest, width: 2),
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
    return CustomPaint(
      painter: const _ChoiceTitleBubbleTailPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TudloColors.ink, width: 2.5),
        ),
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
      ),
    );
  }
}

class _ChoiceTitleBubbleTailPainter extends CustomPainter {
  const _ChoiceTitleBubbleTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = TudloColors.ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(24, size.height - 2)
      ..lineTo(10, size.height + 14)
      ..lineTo(42, size.height - 2)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TudloColors.line, width: 4),
            boxShadow: [
              BoxShadow(
                color: TudloColors.ink.withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
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
          border: hasWord
              ? Border.all(color: color.withValues(alpha: .72), width: 2.5)
              : Border(
                  bottom: BorderSide(
                    color: TudloColors.muted.withValues(alpha: .55),
                    width: 3,
                  ),
                ),
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
    final borderColor = wrong
        ? TudloColors.coral
        : justMatched
        ? TudloColors.green
        : matched
        ? TudloColors.line
        : active
        ? TudloColors.green
        : TudloColors.line;
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
              border: Border.all(color: borderColor, width: active ? 4 : 3),
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

    return SizedBox(
      height: 520,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 14),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
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
    final borderColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? TudloColors.brightGreen
        : TudloColors.line;
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
            border: Border.all(color: borderColor, width: active ? 4 : 3),
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
    final title = correct ? 'Maayo gid!' : 'Sulayi liwat!';
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
        border: Border.all(color: accent.withValues(alpha: .35), width: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TudloMascot(size: 102),
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
    final borderColor = correct
        ? TudloColors.green
        : wrong
        ? TudloColors.coral
        : active
        ? TudloColors.green
        : TudloColors.line;
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
              border: Border.all(color: borderColor, width: 4),
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
