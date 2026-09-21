import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';

/// The result of [resolveWordOfTheDay]: which entry to show, and whether
/// that's a fresh pick the caller needs to persist ([isNew]) or just the
/// same one already recorded for today ([isNew] false, nothing to do).
class WordOfTheDaySelection {
  const WordOfTheDaySelection({
    required this.entry,
    required this.isNew,
    required this.history,
  });

  final DictionaryEntry entry;
  final bool isNew;

  /// The rotation history to persist when [isNew] is true (unchanged,
  /// included for convenience, when [isNew] is false).
  final Set<String> history;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Picks today's word of the day from [pool], given what's already
/// recorded on the learner profile ([storedId], [storedDate],
/// [history]) and the current moment ([now] -- defaults to [DateTime.now],
/// overridable for tests).
///
/// One word per real calendar date: if [storedDate] is today and
/// [storedId] still exists in [pool], that same entry is returned
/// ([isNew] false). Otherwise a new entry is picked from whichever pool
/// entries aren't in [history] yet; once the whole pool has been shown,
/// the history resets and a fresh cycle starts.
WordOfTheDaySelection resolveWordOfTheDay({
  required List<DictionaryEntry> pool,
  required String? storedId,
  required DateTime? storedDate,
  required Set<String> history,
  DateTime? now,
}) {
  // A real (non-`assert`) check: `assert` is stripped in release builds, so
  // relying on it here would mean an empty pool fails loudly in debug/tests
  // but silently misbehaves (or throws a much less clear error, deep inside
  // `.first`) in release -- exactly the kind of gap that stays invisible
  // until a future caller forgets to pre-check emptiness themselves.
  if (pool.isEmpty) {
    throw ArgumentError.value(
      pool,
      'pool',
      'resolveWordOfTheDay requires a non-empty pool',
    );
  }
  final today = now ?? DateTime.now();

  if (storedId != null && storedDate != null && _isSameDay(storedDate, today)) {
    for (final entry in pool) {
      if (entry.id == storedId) {
        return WordOfTheDaySelection(
          entry: entry,
          isNew: false,
          history: history,
        );
      }
    }
  }

  var candidates = pool.where((e) => !history.contains(e.id)).toList();
  var nextHistory = history;
  if (candidates.isEmpty) {
    // Whole pool already shown this cycle -- reset and reshuffle.
    candidates = pool.toList();
    nextHistory = const {};
  }
  candidates.shuffle();
  final picked = candidates.first;

  return WordOfTheDaySelection(
    entry: picked,
    isNew: true,
    history: {...nextHistory, picked.id},
  );
}
