import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/profile/screens/profile_selection_screen.dart';
import 'package:tudloapp/features/streak/helpers/streak_helper.dart';

String _profileText(
  BuildContext context, {
  required String hil,
  required String en,
}) {
  return AppStateScope.of(context).isHiligaynon ? hil : en;
}

const _profileAvatars = [
  'assets/images/profile/profile.jpg',
  'assets/images/profile/profile2.jpg',
  'assets/images/profile/profile3.jpg',
];
const _profileNotSetAsset = 'assets/images/profile/profile-notset.jpg';

/// Profile dashboard screen.
///
/// It shows the saved onboarding info, editable username, streak summary, and
/// per-unit learning progress from AppData.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final username = appState.displayUsername;
    final activeProfile = appState.activeProfile;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 37, 125, 24),
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 126),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MainProfileCard(
                    username: username,
                    gradeLabel: appState.gradeLabel,
                    joinedOn: appState.joinedOn,
                    avatarAsset: activeProfile?.avatarAsset ?? '',
                    onRename: () => _showRenameDialog(context),
                    onAvatarTap: () => _showAvatarPicker(context),
                  ),
                  const SizedBox(height: 16),
                  const _ProfileProgressRail(),
                  const SizedBox(height: 22),
                  const _AboutCard(),
                  const SizedBox(height: 18),
                  const _WeeklyStreakCard(),
                  const SizedBox(height: 28),
                  _FavoritesCard(
                    words: activeProfile?.favoriteWords.toList() ?? const [],
                  ),
                  const SizedBox(height: 28),
                  _ProgressSection(username: username),
                  const SizedBox(height: 18),
                  const _AudioSettingsCard(),
                  if (AppData.developerMode) ...[
                    const SizedBox(height: 18),
                    const _DeveloperModePanel(),
                  ],
                  const SizedBox(height: 28),
                  _ProfileManagementRow(
                    onSwitch: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSelectionScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    onClear: () => _confirmClearProfile(context),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 12,
            right: 16,
            child: SafeArea(child: _DeveloperModeToggleButton()),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearProfile(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _profileText(
            context,
            hil: 'Papas ang progreso?',
            en: 'Clear progress?',
          ),
        ),
        content: Text(
          _profileText(
            context,
            hil:
                'Magapabilin ang profile pero ma-reset ang levels, scores, stars, kag energy.',
            en: 'This keeps the profile but resets levels, scores, stars, and energy.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_profileText(context, hil: 'Kanselahon', en: 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppStateScope.of(context).clearActiveProfileData();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(_profileText(context, hil: 'Papas', en: 'Clear')),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    final appState = AppStateScope.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: TudloColors.forest, width: 3),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final avatar in _profileAvatars)
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            await appState.setProfileAvatar(avatar);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: TudloColors.softGreen,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color:
                                    appState.activeProfile?.avatarAsset ==
                                        avatar
                                    ? Color.fromARGB(255, 37, 125, 24)
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(avatar, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: IconButton(
                    tooltip: _profileText(context, hil: 'Sirad-i', en: 'Close'),
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TudloColors.forest,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final appState = AppStateScope.of(context);
    final isHiligaynon = appState.isHiligaynon;
    final messenger = ScaffoldMessenger.of(context);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (_) {
        return _RenameProfileDialog(
          initialName: appState.username,
          title: isHiligaynon ? 'Islan ang ngalan' : 'Rename profile',
          subtitle: isHiligaynon
              ? 'Ibutang ang bag-o nga ngalan sang profile.'
              : 'Enter the new profile name.',
          nameLabel: isHiligaynon ? 'Ngalan' : 'Name',
          cancelLabel: isHiligaynon ? 'Kanselahon' : 'Cancel',
          saveLabel: isHiligaynon ? 'Tipigi' : 'Save',
        );
      },
    );
    if (!mounted || updatedName == null || updatedName.trim().isEmpty) return;
    if (appState.isUsernameTaken(
      updatedName,
      exceptProfileId: appState.activeProfileId,
    )) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Username is taken')),
      );
      return;
    }
    appState.setUsername(updatedName);
  }
}

class _RenameProfileDialog extends StatefulWidget {
  final String initialName;
  final String title;
  final String subtitle;
  final String nameLabel;
  final String cancelLabel;
  final String saveLabel;

  const _RenameProfileDialog({
    required this.initialName,
    required this.title,
    required this.subtitle,
    required this.nameLabel,
    required this.cancelLabel,
    required this.saveLabel,
  });

  @override
  State<_RenameProfileDialog> createState() => _RenameProfileDialogState();
}

class _RenameProfileDialogState extends State<_RenameProfileDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: TudloColors.green.withValues(alpha: .18),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: GoogleFonts.nunito(
                  color: TudloColors.muted,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                cursorColor: TudloColors.green,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  labelText: widget.nameLabel,
                  labelStyle: GoogleFonts.nunito(
                    color: TudloColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                  filled: true,
                  fillColor: TudloColors.cloud,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: TudloColors.blue.withValues(alpha: .45),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: TudloColors.blue,
                      width: 3,
                    ),
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final canSave = value.text.trim().isNotEmpty;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileAssetActionButton(
                        asset: 'assets/images/profile/cancel.png',
                        fallbackIcon: Icons.close_rounded,
                        tooltip: widget.cancelLabel,
                        foregroundColor: const Color(0xFFE91B2D),
                        backgroundColor: const Color(
                          0xFFFFE7E7,
                        ).withValues(alpha: .95),
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 22),
                      _ProfileAssetActionButton(
                        asset: 'assets/images/profile/check.png',
                        fallbackIcon: Icons.check_rounded,
                        tooltip: widget.saveLabel,
                        enabled: canSave,
                        foregroundColor: Colors.white,
                        backgroundColor: TudloColors.green,
                        onTap: _save,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAssetActionButton extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final String tooltip;
  final VoidCallback onTap;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool enabled;

  const _ProfileAssetActionButton({
    required this.asset,
    required this.fallbackIcon,
    required this.tooltip,
    required this.onTap,
    required this.foregroundColor,
    required this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const size = 70.0;
    const iconSize = 48.0;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1 : .42,
          child: Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            elevation: enabled ? 5 : 0,
            shadowColor: TudloColors.forest.withValues(alpha: .24),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: Image.asset(
                    asset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Icon(
                      fallbackIcon,
                      color: foregroundColor,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileManagementRow extends StatelessWidget {
  final VoidCallback onSwitch;
  final VoidCallback onClear;

  const _ProfileManagementRow({required this.onSwitch, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSwitch,
            icon: const Icon(Icons.people_rounded),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_profileText(context, hil: 'Islan', en: 'Switch')),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9A520),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.cleaning_services_rounded),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _profileText(
                  context,
                  hil: 'Papasa ang datos',
                  en: 'Clear data',
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: TudloColors.coral),
          ),
        ),
      ],
    );
  }
}

class _AudioSettingsCard extends StatelessWidget {
  const _AudioSettingsCard();

  @override
  Widget build(BuildContext context) {
    final audio = AppAudioService.instance;
    final appState = AppStateScope.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profileText(context, hil: 'Tunog', en: 'Audio'),
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsSwitchTile(
            icon: Icons.touch_app_rounded,
            label: _profileText(
              context,
              hil: 'Sound effects',
              en: 'Sound effects',
            ),
            listenable: audio.soundEffectsEnabledNotifier,
            onChanged: audio.setSoundEffectsEnabled,
          ),
          _SettingsSwitchTile(
            icon: Icons.music_note_rounded,
            label: _profileText(
              context,
              hil: 'Background music',
              en: 'Background music',
            ),
            listenable: audio.musicEnabledNotifier,
            onChanged: audio.setMusicEnabled,
          ),
          _SettingsSwitchTile(
            icon: Icons.record_voice_over_rounded,
            label: _profileText(context, hil: 'Voice-over', en: 'Voice-over'),
            listenable: audio.voiceOverEnabledNotifier,
            onChanged: audio.setVoiceOverEnabled,
          ),
          const Divider(),
          Text(
            _profileText(context, hil: 'Translation', en: 'Translation'),
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsSwitchTile(
            icon: Icons.shield_rounded,
            label: _profileText(
              context,
              hil: 'Profanity filter',
              en: 'Profanity filter',
            ),
            listenable: AppData.profanityFilterEnabledNotifier,
            onChanged: appState.setProfanityFilterEnabled,
          ),
          _SettingsSwitchTile(
            icon: Icons.menu_book_rounded,
            label: _profileText(
              context,
              hil: 'Dictionary fallback',
              en: 'Dictionary fallback',
            ),
            listenable: AppData.dictionaryFallbackEnabledNotifier,
            onChanged: appState.setDictionaryFallbackEnabled,
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final ValueListenable<bool> listenable;
  final Future<void> Function(bool enabled) onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.listenable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, enabled, _) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, color: TudloColors.green),
          title: Text(
            label,
            style: GoogleFonts.nunito(
              color: TudloColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          activeThumbColor: TudloColors.green,
          value: enabled,
          onChanged: (value) async {
            await AppAudioService.instance.playTap();
            await onChanged(value);
          },
        );
      },
    );
  }
}

class _MainProfileCard extends StatelessWidget {
  final String username;
  final String gradeLabel;
  final DateTime joinedOn;
  final String avatarAsset;
  final VoidCallback onRename;
  final VoidCallback onAvatarTap;

  const _MainProfileCard({
    required this.username,
    required this.gradeLabel,
    required this.joinedOn,
    required this.avatarAsset,
    required this.onRename,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradeNumber = gradeLabel.replaceFirst('Grade ', '');
    return Column(
      children: [
        SizedBox(
          width: 166,
          height: 166,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onAvatarTap,
                  child: Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TudloColors.softGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: TudloColors.forest.withValues(alpha: .18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipOval(
                      child: Image.asset(
                        avatarAsset.trim().isEmpty
                            ? _profileNotSetAsset
                            : avatarAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: Color(0xFFF6F9EA),
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: TudloColors.green,
                                size: 74,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: IconButton.filled(
                  tooltip: _profileText(
                    context,
                    hil: 'Islan ang litrato',
                    en: 'Change avatar',
                  ),
                  onPressed: onAvatarTap,
                  style: IconButton.styleFrom(
                    backgroundColor: TudloColors.gold,
                    foregroundColor: TudloColors.forest,
                    side: const BorderSide(color: Colors.white, width: 4),
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: _profileText(
                context,
                hil: 'Islan ang ngalan',
                en: 'Rename profile',
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRename,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _profileText(
            context,
            hil: 'Grado $gradeNumber • ${_formatDate(joinedOn)}',
            en: '$gradeLabel • ${_formatDate(joinedOn)}',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: TudloColors.cloud,
            fontSize: 16,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProfileProgressRail extends StatelessWidget {
  const _ProfileProgressRail();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: AppData.overallProgress,
            minHeight: 18,
            color: TudloColors.blue,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _profileText(
            context,
            hil:
                '${AppData.completedLevelCount} sa ${AppData.maxLevel} ka leksiyon natapos',
            en: '${AppData.completedLevelCount} of ${AppData.maxLevel} lessons complete',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: TudloColors.cloud,
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final streak = StreakHelper.current().days;
    return Row(
      children: [
        const Spacer(),
        Expanded(
          flex: 3,
          child: _ProfileStatCircle(
            value: '${AppData.completedLevels.length}',
            label: _profileText(context, hil: 'Leksiyon', en: 'Lessons'),
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          flex: 3,
          child: _ProfileStatCircle(
            value: '$streak',
            label: _profileText(context, hil: 'Streak', en: 'Streak'),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _ProfileStatCircle extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatCircle({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TudloColors.softGreen,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.nunito(
                color: TudloColors.forest,
                fontSize: 30,
                height: .95,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 13,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperModeToggleButton extends StatelessWidget {
  const _DeveloperModeToggleButton();

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final enabled = AppData.developerMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          await AppAudioService.instance.playTap();
          if (!context.mounted) return;
          await appState.setDeveloperMode(!enabled);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : TudloColors.softGreen,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: TudloColors.forest, width: 3),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                color: enabled ? TudloColors.green : TudloColors.muted,
                size: 28,
              ),
              const SizedBox(width: 4),
              Text(
                'DEV',
                style: GoogleFonts.nunito(
                  color: enabled ? TudloColors.forest : TudloColors.muted,
                  fontSize: 14,
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

class _DeveloperModePanel extends StatelessWidget {
  const _DeveloperModePanel();

  Future<void> _changeDailyWordOffset(BuildContext context, int delta) async {
    await AppAudioService.instance.playTap();
    if (!context.mounted) return;
    await AppStateScope.of(
      context,
    ).setDailyWordDemoOffset(AppData.dailyWordDemoOffset + delta);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final demoDate = AppData.dailyWordNow();
    final month = demoDate.month.toString().padLeft(2, '0');
    final day = demoDate.day.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _softCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_mode_rounded,
                color: TudloColors.forest,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dev Mode',
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Switch(
                value: AppData.developerMode,
                activeThumbColor: TudloColors.green,
                onChanged: (value) => appState.setDeveloperMode(value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'All lessons unlocked, all features open, and energy is unlimited.',
            style: GoogleFonts.nunito(
              color: TudloColors.muted,
              fontSize: 15,
              height: 1.18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TudloColors.softGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                IconButton.filled(
                  tooltip: 'Previous daily word',
                  onPressed: () => _changeDailyWordOffset(context, -1),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TudloColors.forest,
                  ),
                  icon: const Icon(Icons.chevron_left_rounded, size: 34),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Daily Word Demo',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 18,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Offset ${AppData.dailyWordDemoOffset >= 0 ? '+' : ''}${AppData.dailyWordDemoOffset} day • $month/$day/${demoDate.year}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: TudloColors.muted,
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Next daily word',
                  onPressed: () => _changeDailyWordOffset(context, 1),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TudloColors.forest,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 34),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStreakCard extends StatelessWidget {
  const _WeeklyStreakCard();

  @override
  Widget build(BuildContext context) {
    final completedDays = StreakHelper.current().completedDaysThisWeek;
    final labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: _softCardDecoration(radius: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileText(
                    context,
                    hil: '${StreakHelper.current().days} ka adlaw',
                    en: '${StreakHelper.current().days} Days',
                  ),
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(7, (index) {
                    final completed = index < completedDays;
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            labels[index],
                            style: GoogleFonts.nunito(
                              color: completed
                                  ? TudloColors.forest
                                  : TudloColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Image.asset(
                            completed
                                ? 'assets/images/level_game/lesson-game-assets/fire-unlocked.png'
                                : 'assets/images/level_game/lesson-game-assets/fire-locked.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.local_fire_department_rounded,
                              color: completed
                                  ? TudloColors.green
                                  : TudloColors.muted,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesCard extends StatelessWidget {
  final List<String> words;

  const _FavoritesCard({required this.words});

  @override
  Widget build(BuildContext context) {
    final sortedWords = [...words]..sort();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: TudloColors.softGreen,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _profileText(context, hil: 'Koleksyon', en: 'Collection'),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedWords.isEmpty)
            Text(
              _profileText(
                context,
                hil:
                    'Itum-ok ang tagipusuon sa Tinaga subong nga adlaw para matipon diri ang paborito mo nga mga tinaga.',
                en: 'Press the heart on Daily Word to save favorite words here.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.muted,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            Column(
              children: [
                for (final word in sortedWords)
                  _FavoriteWordRow(
                    word: word,
                    meaning: _favoriteMeaningFor(word),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _favoriteMeaningFor(String word) {
    final dictionaryMeaning = DictionaryData.meaningFor(word);
    if (dictionaryMeaning.isEmpty) return '';
    return dictionaryMeaning[0].toUpperCase() + dictionaryMeaning.substring(1);
  }
}

class _FavoriteWordRow extends StatelessWidget {
  final String word;
  final String meaning;

  const _FavoriteWordRow({required this.word, required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: TudloColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word,
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (meaning.isNotEmpty &&
                    !AppStateScope.of(context).isHiligaynon)
                  Text(
                    meaning,
                    style: GoogleFonts.nunito(
                      color: TudloColors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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

class _ProgressSection extends StatefulWidget {
  final String username;

  const _ProgressSection({required this.username});

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    // The progress card starts with three units and expands to all units when
    // the user taps "View all".
    final units = AppData.units.map((unit) => unit.number).toList();
    final visibleUnits = expanded ? units : units.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _profileText(
              context,
              hil: 'Progreso ni ${widget.username}',
              en: "${widget.username}'s Progress",
            ),
            style: GoogleFonts.nunito(
              color: TudloColors.cloud,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 203, 253, 159),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const _OverallProgressSummary(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                    bottom: Radius.circular(24),
                  ),
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: Column(
                    children: visibleUnits
                        .map(
                          (unit) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UnitProgressTile(unit: unit),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                // View all button:
                // Expands the progress card to show every unit instead of the
                // first three only.
                onTap: () => setState(() => expanded = !expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _profileText(
                          context,
                          hil: 'Tan-awa tanan',
                          en: 'View all',
                        ),
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: TudloColors.forest,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverallProgressSummary extends StatelessWidget {
  const _OverallProgressSummary();

  @override
  Widget build(BuildContext context) {
    final percent = AppData.overallProgressPercent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: TudloColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _profileText(
                    context,
                    hil: 'Kabug-osan nga Progreso',
                    en: 'Overall Progress',
                  ),
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 21,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.nunito(
                  color: TudloColors.forest,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: AppData.overallProgress,
              minHeight: 18,
              color: TudloColors.green,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _profileText(
              context,
              hil:
                  '${AppData.completedLevelCount} sa ${AppData.maxLevel} ka leksiyon natapos',
              en: '${AppData.completedLevelCount} of ${AppData.maxLevel} lessons complete',
            ),
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitProgressTile extends StatelessWidget {
  final int unit;

  const _UnitProgressTile({required this.unit});

  @override
  Widget build(BuildContext context) {
    final appUnit = AppData.unitForNumber(unit);
    final start = appUnit.startLevel;
    final end = appUnit.endLevel;
    final count = AppData.completedLevels
        .where((level) => level >= start && level <= end)
        .length;
    final progress = count / appUnit.lessonCount;
    final playLevel = start + count.clamp(0, appUnit.lessonCount - 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yunit $unit',
                  style: GoogleFonts.nunito(
                    color: TudloColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 16,
                    color: TudloColors.green,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _profileText(
                    context,
                    hil: '$count sa ${appUnit.lessonCount} ka leksiyon natapos',
                    en: '$count of ${appUnit.lessonCount} leksiyon done',
                  ),
                  style: GoogleFonts.nunito(
                    color: TudloColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          IconButton.filled(
            tooltip: _profileText(
              context,
              hil: 'Sugdi ang sunod nga leksiyon',
              en: 'Play next lesson',
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelGamePage(level: playLevel),
                ),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: TudloColors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(58, 58),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 34),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ProfileBackgroundPainter());
  }
}

class _ProfileBackgroundPainter extends CustomPainter {
  const _ProfileBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = TudloColors.green);

    final lower = Path()
      ..moveTo(0, size.height * .52)
      ..lineTo(size.width, size.height * .46)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      lower,
      Paint()..color = TudloColors.green.withValues(alpha: .82),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _softCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: TudloColors.line),
    boxShadow: [
      BoxShadow(
        color: TudloColors.forest.withValues(alpha: .08),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
