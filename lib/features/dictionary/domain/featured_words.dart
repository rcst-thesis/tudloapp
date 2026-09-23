import 'dart:math';

import 'package:tudloapp/features/dictionary/domain/dictionary_entry.dart';

/// The result of [resolveFeatured]: which entries to show in the featured
/// tray, and whether that's a fresh pick the caller needs to persist
/// ([isNew]) or just the same ids already recorded for today ([isNew]
/// false, nothing to do).
class FeaturedSelection {
  const FeaturedSelection({
    required this.ids,
    required this.isNew,
    required this.history,
  });

  final List<String> ids;
  final bool isNew;

  /// The rotation history to persist when [isNew] is true (unchanged,
  /// included for convenience, when [isNew] is false).
  final Set<String> history;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Fades old interest so the featured tray tracks *recent* popularity
/// rather than accumulating forever -- a category the learner searched a
/// lot last month shouldn't still dominate today just because the number
/// never went down. Call this once per day, right before folding in
/// whatever picks that day's refresh, so counts halve roughly once a day:
/// a count of 10 becomes 5, then 2, then 1, then drops out entirely once it
/// rounds to 0.
Map<String, int> decayCategorySearchCounts(
  Map<String, int> counts, {
  double factor = 0.5,
}) {
  final decayed = <String, int>{};
  for (final entry in counts.entries) {
    final value = (entry.value * factor).floor();
    if (value > 0) decayed[entry.key] = value;
  }
  return decayed;
}

/// Weighted-random ordering of [categories] by [categoryCounts] (every
/// category gets a `+1` baseline weight so a never-searched category can
/// still come up, just rarely) -- higher counts are *more likely* to sort
/// first, not guaranteed to. This is deliberately not a strict
/// highest-count-wins sort: a strict sort means whichever category is on
/// top stays on top forever once it has a lead, so the tray would settle
/// into showing the same category's words every single day. Weighted
/// randomness keeps it statistically favoring genuinely popular
/// categories while still varying what shows up day to day.
List<String> _weightedCategoryOrder(
  List<String> categories,
  Map<String, int> categoryCounts,
  Random random,
) {
  final weights = {for (final c in categories) c: (categoryCounts[c] ?? 0) + 1};
  final remaining = List<String>.from(categories);
  final ordered = <String>[];
  while (remaining.isNotEmpty) {
    final totalWeight = remaining.fold<int>(0, (sum, c) => sum + weights[c]!);
    var roll = random.nextInt(totalWeight);
    var picked = remaining.first;
    for (final c in remaining) {
      roll -= weights[c]!;
      if (roll < 0) {
        picked = c;
        break;
      }
    }
    ordered.add(picked);
    remaining.remove(picked);
  }
  return ordered;
}

/// Picks today's featured-tray entries from [pool] (already caller-filtered
/// to art-eligible entries -- this function doesn't know about art), given
/// what's already recorded on the learner profile ([storedIds],
/// [storedDate], [history]), how much interest this learner has shown in
/// each category ([categoryCounts]), and the current moment ([now] --
/// defaults to [DateTime.now], overridable for tests).
///
/// One selection per real calendar date: if [storedDate] is today and every
/// id in [storedIds] still exists in [pool], those same entries are
/// returned ([isNew] false). Otherwise a fresh selection is built by
/// weighted-randomly ordering [pool]'s categories by [categoryCounts] (see
/// [_weightedCategoryOrder] -- higher counts are favored, not guaranteed)
/// and walking them, preferring entries not yet in [history]; if that
/// doesn't fill [slotCount], backfill from any not-in-history entries
/// regardless of category, then if still short, reset the history and pull
/// from the full pool. The final picks are shuffled before returning. Pass
/// [random] to make the pick deterministic in tests.
FeaturedSelection resolveFeatured({
  required List<DictionaryEntry> pool,
  required Map<String, int> categoryCounts,
  required List<String>? storedIds,
  required DateTime? storedDate,
  required Set<String> history,
  int slotCount = 5,
  DateTime? now,
  Random? random,
}) {
  // A real (non-`assert`) check: `assert` is stripped in release builds, so
  // relying on it here would mean an empty pool fails loudly in debug/tests
  // but silently misbehaves (or throws a much less clear error deep inside
  // this function) in release -- exactly the kind of gap that stays
  // invisible until a future caller forgets to pre-check emptiness
  // themselves.
  if (pool.isEmpty) {
    throw ArgumentError.value(
      pool,
      'pool',
      'resolveFeatured requires a non-empty pool',
    );
  }
  final today = now ?? DateTime.now();
  final poolIds = pool.map((e) => e.id).toSet();

  if (storedIds != null &&
      storedIds.isNotEmpty &&
      storedDate != null &&
      _isSameDay(storedDate, today) &&
      storedIds.every(poolIds.contains)) {
    return FeaturedSelection(ids: storedIds, isNew: false, history: history);
  }

  final rng = random ?? Random();
  final categories = _weightedCategoryOrder(
    {for (final e in pool) e.category}.toList(),
    categoryCounts,
    rng,
  );

  var effectiveHistory = history;
  var eligible = pool.where((e) => !effectiveHistory.contains(e.id)).toList();
  if (eligible.isEmpty) {
    // Whole pool already featured this cycle -- reset and reshuffle.
    effectiveHistory = const {};
    eligible = pool.toList();
  }

  final picked = <DictionaryEntry>[];
  for (final category in categories) {
    if (picked.length >= slotCount) break;
    for (final entry in eligible) {
      if (picked.length >= slotCount) break;
      if (entry.category == category && !picked.contains(entry)) {
        picked.add(entry);
      }
    }
  }
  // Backfill across categories if the ranked walk didn't fill every slot.
  for (final entry in eligible) {
    if (picked.length >= slotCount) break;
    if (!picked.contains(entry)) picked.add(entry);
  }

  picked.shuffle(rng);
  final ids = picked.map((e) => e.id).toList();

  return FeaturedSelection(
    ids: ids,
    isNew: true,
    history: {...effectiveHistory, ...ids},
  );
}
