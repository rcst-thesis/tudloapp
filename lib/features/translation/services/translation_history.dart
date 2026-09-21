import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One committed translation pair shown as a result card.
@immutable
class TranslationEntry {
  final String source;
  final String target;
  final bool fromEnglish;

  const TranslationEntry({
    required this.source,
    required this.target,
    required this.fromEnglish,
  });

  String get sourceLanguage => fromEnglish ? 'English' : 'Hiligaynon';
  String get targetLanguage => fromEnglish ? 'Hiligaynon' : 'English';

  Map<String, Object> toJson() => {
    'source': source,
    'target': target,
    'fromEnglish': fromEnglish,
  };

  static TranslationEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final source = raw['source'];
    final target = raw['target'];
    if (source is! String || target is! String) return null;
    return TranslationEntry(
      source: source,
      target: target,
      fromEnglish: raw['fromEnglish'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TranslationEntry &&
      other.source.trim().toLowerCase() == source.trim().toLowerCase() &&
      other.fromEnglish == fromEnglish;

  @override
  int get hashCode => Object.hash(source.trim().toLowerCase(), fromEnglish);
}

/// Shared translate-page state: the result cards on the page and favorites.
///
/// Recents live only in memory and expire after [recentTtl]. Favorites are
/// persisted in preferences; storage failures (e.g. tests without a
/// preferences mock) are ignored so the store keeps working in memory.
class TranslationHistory extends ChangeNotifier {
  TranslationHistory({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  static final instance = TranslationHistory();

  static const _favoritesKey = 'tudlo.app.translation.favorites';
  static const maxRecents = 20;
  static const recentTtl = Duration(minutes: 30);

  final DateTime Function() _now;
  final List<({TranslationEntry entry, DateTime addedAt})> _recents = [];
  List<TranslationEntry> _favorites = const [];
  Timer? _expiry;
  Future<void>? _loading;

  /// Newest first, with expired entries dropped.
  List<TranslationEntry> get recents {
    _purgeExpired();
    return [for (final r in _recents) r.entry];
  }

  List<TranslationEntry> get favorites => _favorites;

  bool isFavorite(TranslationEntry entry) => _favorites.contains(entry);

  Future<void> load() => _loading ??= _read();

  void addRecent(TranslationEntry entry) {
    if (entry.source.trim().isEmpty || entry.target.trim().isEmpty) return;
    _recents
      ..removeWhere((r) => r.entry == entry)
      ..insert(0, (entry: entry, addedAt: _now()));
    if (_recents.length > maxRecents) _recents.removeLast();
    _scheduleExpiry();
    notifyListeners();
  }

  void removeRecent(TranslationEntry entry) {
    final before = _recents.length;
    _recents.removeWhere((r) => r.entry == entry);
    if (_recents.length == before) return;
    _scheduleExpiry();
    notifyListeners();
  }

  /// Swipe-to-save: add to favorites; the recent card stays on the page.
  void promoteToFavorite(TranslationEntry entry) {
    if (_favorites.contains(entry)) return;
    _favorites = [entry, ..._favorites];
    _write();
    notifyListeners();
  }

  void toggleFavorite(TranslationEntry entry) {
    _favorites = _favorites.contains(entry)
        ? _favorites.where((e) => e != entry).toList()
        : [entry, ..._favorites];
    _write();
    notifyListeners();
  }

  void _purgeExpired() {
    final cutoff = _now().subtract(recentTtl);
    _recents.removeWhere((r) => r.addedAt.isBefore(cutoff));
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    if (_recents.isEmpty) return;
    final oldest = _recents.last.addedAt;
    final wait = oldest.add(recentTtl).difference(_now());
    _expiry = Timer(wait.isNegative ? Duration.zero : wait, () {
      _purgeExpired();
      notifyListeners();
      _scheduleExpiry();
    });
  }

  Future<void> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites = _decode(prefs.getString(_favoritesKey));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _write() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _favoritesKey,
        jsonEncode(_favorites.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static List<TranslationEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map(TranslationEntry.fromJson).nonNulls.toList();
    } catch (_) {
      return const [];
    }
  }

  @visibleForTesting
  void reset() {
    _expiry?.cancel();
    _recents.clear();
    _favorites = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }
}
