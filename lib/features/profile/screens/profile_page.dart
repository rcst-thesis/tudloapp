import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/lesson_game/screens/level_game_page.dart';
import 'package:tudloapp/features/profile/screens/profile_selection_screen.dart';
import 'package:tudloapp/features/streak/helpers/streak_helper.dart';

enum _ProfileTab { about, streak, favorites }

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
  _ProfileTab _selectedTab = _ProfileTab.about;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final username = appState.displayUsername;
    final activeProfile = appState.activeProfile;

    return Scaffold(
      backgroundColor: TudloColors.green,
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
                    selectedTab: _selectedTab,
                    onRename: () => _showRenameDialog(context),
                    onAvatarTap: () => _showAvatarPicker(context),
                    // Profile tabs switch the content below the main profile
                    // card between About details and weekly streak details.
                    onTabSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                  const SizedBox(height: 18),
                  if (_selectedTab == _ProfileTab.about)
                    const _AboutCard()
                  else if (_selectedTab == _ProfileTab.streak)
                    const _WeeklyStreakCard()
                  else
                    _FavoritesCard(
                      words: activeProfile?.favoriteWords.toList() ?? const [],
                    ),
                  const SizedBox(height: 28),
                  _ProgressSection(username: username),
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
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: TudloColors.softGreen,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: appState.activeProfile?.avatarAsset == avatar
                              ? TudloColors.green
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
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context) {
    final appState = AppStateScope.of(context);
    final controller = TextEditingController(text: appState.username);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            _profileText(
              context,
              hil: 'Islan ang ngalan sang profile',
              en: 'Rename profile',
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _profileText(context, hil: 'Ngalan', en: 'Name'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _profileText(context, hil: 'Kanselahon', en: 'Cancel'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                appState.setUsername(value);
                Navigator.pop(dialogContext);
              },
              child: Text(_profileText(context, hil: 'Tipigi', en: 'Save')),
            ),
          ],
        );
      },
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
            label: Text(_profileText(context, hil: 'Islan', en: 'Switch')),
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
            label: Text(
              _profileText(context, hil: 'Papasa ang datos', en: 'Clear data'),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: TudloColors.coral),
          ),
        ),
      ],
    );
  }
}

class _MainProfileCard extends StatelessWidget {
  final String username;
  final String gradeLabel;
  final DateTime joinedOn;
  final String avatarAsset;
  final _ProfileTab selectedTab;
  final VoidCallback onRename;
  final VoidCallback onAvatarTap;
  final ValueChanged<_ProfileTab> onTabSelected;

  const _MainProfileCard({
    required this.username,
    required this.gradeLabel,
    required this.joinedOn,
    required this.avatarAsset,
    required this.selectedTab,
    required this.onRename,
    required this.onAvatarTap,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // The profile card keeps permanent user info at the top and switches the
    // lower tab content between ABOUT and Streak.
    final gradeNumber = gradeLabel.replaceFirst('Grade ', '');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: _softCardDecoration(radius: 34),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: onAvatarTap,
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F9EA),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: avatarAsset.trim().isEmpty
                                ? TudloColors.green
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
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
                                  size: 56,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: TudloColors.ink,
                              fontSize: 31,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _profileText(
                              context,
                              hil: 'Grado: $gradeNumber',
                              en: 'Grade: $gradeLabel',
                            ),
                            style: GoogleFonts.nunito(
                              color: TudloColors.forest,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _profileText(
                              context,
                              hil: 'Nagsugod sang ${_formatDate(joinedOn)}',
                              en: 'Joined on ${_formatDate(joinedOn)}',
                            ),
                            style: GoogleFonts.nunito(
                              color: TudloColors.muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: const Color(0xFFF7FAEC),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _ProfileTabButton(
                      label: _profileText(
                        context,
                        hil: 'KAUGALINGON',
                        en: 'ABOUT',
                      ),
                      selected: selectedTab == _ProfileTab.about,
                      onTap: () => onTabSelected(_ProfileTab.about),
                    ),
                    const SizedBox(width: 10),
                    _ProfileTabButton(
                      label: _profileText(
                        context,
                        hil: 'Sunod-sunod',
                        en: 'Streak',
                      ),
                      selected: selectedTab == _ProfileTab.streak,
                      onTap: () => onTabSelected(_ProfileTab.streak),
                    ),
                    const SizedBox(width: 10),
                    _ProfileTabButton(
                      label: _profileText(
                        context,
                        hil: 'Paborito',
                        en: 'Favorites',
                      ),
                      selected: selectedTab == _ProfileTab.favorites,
                      onTap: () => onTabSelected(_ProfileTab.favorites),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton.filled(
            tooltip: _profileText(
              context,
              hil: 'Islan ang profile',
              en: 'Edit profile',
            ),
            onPressed: onRename,
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
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? TudloColors.softGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: selected ? TudloColors.forest : TudloColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
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
        Expanded(
          child: _StatSquare(
            label: _profileText(
              context,
              hil: 'Natapos nga\nAntas',
              en: 'Levels\nComplete',
            ),
            value: '${AppData.completedLevels.length}',
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _StatSquare(
            label: _profileText(context, hil: 'Sunod-sunod', en: 'Streak'),
            value: '$streak',
          ),
        ),
      ],
    );
  }
}

class _StatSquare extends StatelessWidget {
  final String label;
  final String value;

  const _StatSquare({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: _softCardDecoration(radius: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: TudloColors.forest,
              fontSize: 16,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontSize: 58,
              height: .95,
              fontWeight: FontWeight.w900,
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
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCardDecoration(radius: 24),
      child: Row(
        children: List.generate(7, (index) {
          final completed = index < completedDays;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: completed ? TudloColors.green : TudloColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: TudloColors.line),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : Icons.circle_outlined,
                    color: completed ? Colors.white : TudloColors.muted,
                    size: completed ? 22 : 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: GoogleFonts.nunito(
                    color: completed ? TudloColors.forest : TudloColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }),
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
      padding: const EdgeInsets.all(18),
      decoration: _softCardDecoration(radius: 24),
      child: sortedWords.isEmpty
          ? Text(
              _profileText(
                context,
                hil:
                    'Itum-ok ang tagipusuon sa Tinaga subong nga adlaw para matipon diri ang paborito mo nga mga tinaga.',
                en: 'Tap the heart on Daily Word to save favorite words here.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: TudloColors.muted,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            )
          : Column(
              children: [
                for (final word in sortedWords)
                  _FavoriteWordRow(
                    word: word,
                    meaning: _favoriteMeaningFor(word),
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
        color: TudloColors.softGreen,
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
