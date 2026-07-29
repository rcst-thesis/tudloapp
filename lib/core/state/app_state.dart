import 'package:flutter/material.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/core/models/learner_profile.dart';
import 'package:tudloapp/features/profile/services/profile_storage.dart';

/// App-wide onboarding/profile state.
///
/// This is intentionally small and simple: screens update it through setters,
/// and any widget that reads `AppStateScope.of(context)` rebuilds when it
/// changes because this class extends [ChangeNotifier].
class AppState extends ChangeNotifier {
  static const int profilesPerSelectionPage = 4;

  String username = '';
  String gradeLevel = 'Grade 1';
  String appLanguage = 'Hiligaynon';
  final DateTime joinedOn = DateTime.now();
  final List<LearnerProfile> profiles = [];
  String? activeProfileId;

  String get displayUsername {
    final value = username.trim();
    if (value.isEmpty) return 'Friend';
    return value[0].toUpperCase() + value.substring(1);
  }

  String get gradeLabel => gradeLevel;
  bool get isHiligaynon => appLanguage == 'Hiligaynon';
  bool get canCreateProfile => true;

  String _normalizedName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  bool isUsernameTaken(String value, {String? exceptProfileId}) {
    final normalized = _normalizedName(value);
    if (normalized.isEmpty) return false;
    return profiles.any(
      (profile) =>
          profile.id != exceptProfileId &&
          _normalizedName(profile.name) == normalized,
    );
  }

  LearnerProfile? get activeProfile {
    for (final profile in profiles) {
      if (profile.id == activeProfileId) return profile;
    }
    return null;
  }

  Future<void> loadProfiles() async {
    final data = decodeProfiles(await ProfileStorage.read());
    profiles
      ..clear()
      ..addAll(data.profiles);
    activeProfileId = data.activeProfileId;
    final selected = activeProfile;
    if (selected != null) _applyProfile(selected);
    notifyListeners();
  }

  Future<void> addProfile({required String name, required String grade}) async {
    if (isUsernameTaken(name)) {
      throw StateError('Username is taken');
    }
    final profile = LearnerProfile.newProfile(name: name, gradeLevel: grade);
    profiles.add(profile);
    _applyProfile(profile);
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> selectProfile(String profileId) async {
    await saveActiveProfileProgress();
    final profile = profiles.firstWhere((profile) => profile.id == profileId);
    _applyProfile(profile);
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String profileId) async {
    profiles.removeWhere((profile) => profile.id == profileId);
    if (activeProfileId == profileId) {
      activeProfileId = profiles.isEmpty ? null : profiles.first.id;
      final selected = activeProfile;
      if (selected == null) {
        username = '';
        gradeLevel = 'Grade 1';
        AppData.clearLearningProgress();
      } else {
        _applyProfile(selected);
      }
    }
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> clearActiveProfileData() async {
    final profile = activeProfile;
    if (profile == null) return;
    AppData.clearLearningProgress();
    _replaceActiveProfile(
      profile.copyWith(
        unlockedLevel: 1,
        streakDays: 0,
        currentEnergy: AppData.maxEnergy,
        levelStars: {},
        lessonScores: {},
        completedLevels: {},
        mapHelpDone: false,
      ),
    );
    await _saveProfiles();
    notifyListeners();
  }

  /// Saves the typed username from onboarding or the Profile edit dialog.
  void setUsername(String value) {
    username = value.trim();
    final profile = activeProfile;
    if (profile != null) {
      _replaceActiveProfile(profile.copyWith(name: username));
      _saveProfiles();
    }
    notifyListeners();
  }

  /// Saves the selected grade level for grade-based lesson content.
  void setGradeLevel(String value) {
    gradeLevel = value.trim().isEmpty ? 'Grade 1' : value.trim();
    AppData.selectedGradeLevel = gradeLevelFromLabel(gradeLevel);
    final profile = activeProfile;
    if (profile != null) {
      _replaceActiveProfile(profile.copyWith(gradeLevel: gradeLevel));
      _saveProfiles();
    }
    notifyListeners();
  }

  bool isFavoriteWord(String word) {
    return activeProfile?.favoriteWords.contains(word) ?? false;
  }

  Future<void> toggleFavoriteWord(String word) async {
    final profile = activeProfile;
    if (profile == null || word.trim().isEmpty) return;
    final updatedWords = Set<String>.from(profile.favoriteWords);
    if (!updatedWords.add(word.trim())) {
      updatedWords.remove(word.trim());
    }
    _replaceActiveProfile(profile.copyWith(favoriteWords: updatedWords));
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> setProfileAvatar(String asset) async {
    final profile = activeProfile;
    if (profile == null || asset.trim().isEmpty) return;
    _replaceActiveProfile(profile.copyWith(avatarAsset: asset));
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    final profile = activeProfile;
    if (profile == null || profile.hasSeenOnboarding) return;
    _replaceActiveProfile(profile.copyWith(hasSeenOnboarding: true));
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> markMapHelpSeen() async {
    final profile = activeProfile;
    AppData.mapHelpDone = true;
    if (profile == null || profile.mapHelpDone) return;
    _replaceActiveProfile(profile.copyWith(mapHelpDone: true));
    await _saveProfiles();
    notifyListeners();
  }

  void setAppLanguage(String value) {
    appLanguage = value == 'English' ? 'English' : 'Hiligaynon';
    notifyListeners();
  }

  void toggleAppLanguage() {
    appLanguage = isHiligaynon ? 'English' : 'Hiligaynon';
    notifyListeners();
  }

  Future<void> setDeveloperMode(bool enabled) async {
    await AppData.setDeveloperMode(enabled);
    notifyListeners();
  }

  Future<void> setDailyWordDemoOffset(int offset) async {
    await AppData.setDailyWordDemoOffset(offset);
    notifyListeners();
  }

  Future<void> setProfanityFilterEnabled(bool enabled) async {
    await AppData.setProfanityFilterEnabled(enabled);
    notifyListeners();
  }

  Future<void> setDictionaryFallbackEnabled(bool enabled) async {
    await AppData.setDictionaryFallbackEnabled(enabled);
    notifyListeners();
  }

  Future<void> saveActiveProfileProgress() async {
    final profile = activeProfile;
    if (profile == null) return;
    _replaceActiveProfile(AppData.snapshotForProfile(profile));
    await _saveProfiles();
  }

  void _applyProfile(LearnerProfile profile) {
    activeProfileId = profile.id;
    username = profile.name;
    gradeLevel = profile.gradeLevel;
    AppData.applyProfile(profile);
  }

  void _replaceActiveProfile(LearnerProfile updated) {
    final index = profiles.indexWhere((profile) => profile.id == updated.id);
    if (index == -1) return;
    profiles[index] = updated;
  }

  Future<void> _saveProfiles() {
    return ProfileStorage.write(encodeProfiles(profiles, activeProfileId));
  }
}

/// Makes [AppState] available below `MaterialApp` without passing it manually.
///
/// This is the app's lightweight alternative to Provider/Riverpod. Put values
/// that many screens need here; keep screen-only state inside that screen.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
