import 'package:flutter/material.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank.dart';

class DailyWordsPage extends StatefulWidget {
  const DailyWordsPage({super.key});

  @override
  State<DailyWordsPage> createState() => _DailyWordsPageState();
}

class _DailyWordsPageState extends State<DailyWordsPage> {
  late final Future<LessonTerm> _wordFuture = _dailyWord();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LessonTerm>(
      future: _wordFuture,
      builder: (context, snapshot) {
        final word = snapshot.data;
        if (word == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final appState = AppStateScope.of(context);
        final saved = appState.isFavoriteWord(word.hil);
        final exampleHil =
            word.exampleSentenceHiligaynon?.trim().isNotEmpty == true
            ? word.exampleSentenceHiligaynon!
            : 'Ang ${word.hil} nami.';
        final exampleEng = word.exampleSentenceEnglish ?? word.eng;

        return Scaffold(
          backgroundColor: TudloColors.meadow,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                final mascotSize = compact ? 76.0 : 104.0;
                final titleSize = compact ? 34.0 : 40.0;
                final wordSize = compact ? 38.0 : 46.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 18, 22, compact ? 28 : 36),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 54).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: TudloColors.forest,
                                size: 48,
                                weight: 900,
                              ),
                            ),
                            const Spacer(),
                            const TudloLanguageToggle(),
                          ],
                        ),
                        SizedBox(height: compact ? 4 : 10),
                        TudloMascot(size: mascotSize),
                        SizedBox(height: compact ? 8 : 12),
                        Text(
                          'Daily Word',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TudloColors.ink,
                            fontSize: titleSize,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 22),
                        Container(
                          padding: EdgeInsets.all(compact ? 18 : 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: const Color.fromARGB(255, 12, 105, 37),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  15,
                                  119,
                                  22,
                                ).withValues(alpha: .16),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton.filled(
                                  tooltip: saved
                                      ? 'Remove favorite'
                                      : 'Save favorite',
                                  onPressed: () =>
                                      appState.toggleFavoriteWord(word.hil),
                                  style: IconButton.styleFrom(
                                    backgroundColor: saved
                                        ? TudloColors.coral
                                        : TudloColors.softGreen,
                                    foregroundColor: saved
                                        ? Colors.white
                                        : TudloColors.forest,
                                  ),
                                  icon: Icon(
                                    saved
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 34,
                                  ),
                                ),
                              ),
                              Container(
                                width: compact ? 88 : 108,
                                height: compact ? 88 : 108,
                                decoration: const BoxDecoration(
                                  color: TudloColors.gold,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  color: TudloColors.coral,
                                  size: compact ? 52 : 62,
                                ),
                              ),
                              SizedBox(height: compact ? 18 : 24),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  word.hil,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: TudloColors.ink,
                                    fontSize: wordSize,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Meaning',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: TudloColors.muted,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                word.eng,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: TudloColors.blue,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: compact ? 14 : 18),
                              TudloVoiceButton(
                                message: '${word.hil}. ${word.eng}',
                                tooltip: 'Play daily word',
                                size: compact ? 56 : 64,
                              ),
                              SizedBox(height: compact ? 20 : 28),
                              _ExampleBox(
                                hiligaynon: exampleHil,
                                english: exampleEng,
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
          ),
        );
      },
    );
  }

  Future<LessonTerm> _dailyWord() async {
    final terms = (await LessonBank.loadTermsForActiveGrade())
        .where((term) => term.hil.split(' ').length <= 3)
        .toList();
    final day = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    return terms[day.abs() % terms.length];
  }
}

class _ExampleBox extends StatelessWidget {
  final String hiligaynon;
  final String english;

  const _ExampleBox({required this.hiligaynon, required this.english});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TudloColors.softGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            hiligaynon,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            english,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TudloColors.muted,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
