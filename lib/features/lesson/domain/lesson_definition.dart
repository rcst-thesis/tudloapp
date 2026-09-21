import 'package:tudloapp/features/map/domain/map_location.dart';

/// The display orientation required by an individual lesson session.
///
/// Tudlo remains portrait-first. Only the three Grade 3 source lessons use
/// landscape, and the session route restores the app's portrait policy when
/// it is dismissed.
enum LessonOrientation { portrait, landscape }

/// A stable, Flutter-owned description of one approved DevG lesson flow.
///
/// This intentionally contains no progress, navigation, audio, or Rive
/// state. Those concerns belong to the surrounding Tudlo feature, while this
/// catalog is safe to use from persistence, Home, Map, and the lesson UI.
class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.grade,
    required this.unit,
    required this.lesson,
    required this.title,
    required this.location,
    required this.rewardAsset,
    required this.orientation,
  });

  final String id;
  final int grade;
  final int unit;
  final int lesson;
  final String title;
  final MapLocation location;
  final String rewardAsset;
  final LessonOrientation orientation;

  String get unitLabel => 'Yunit $unit';
  String get lessonLabel => 'Leksiyon $lesson';
}

/// The 12 approved production flows, in the exact guided order per grade.
///
/// Keep IDs stable: they are persisted in a learner profile and are also the
/// IDs in DevG's imported lesson dataset.
class LessonCatalog {
  const LessonCatalog._();

  // Use DevG's original reward artwork rather than the earlier placeholder
  // copies. These paths are also consumed by the preserved reward overlay.
  static const _rewardRoot = 'assets/images/stickers/rewards/home';
  static const _schoolReward = '$_rewardRoot/school-home-sticker.svg';
  static const _parkReward = '$_rewardRoot/park-home-sticker.svg';
  static const _marketReward = '$_rewardRoot/market-home-sticker.svg';
  static const _houseReward = '$_rewardRoot/house-home-sticker.svg';
  static const _motherReward = '$_rewardRoot/mother-home-sticker.svg';
  static const _dogReward = '$_rewardRoot/dog-home-sticker.svg';
  static const _catReward = '$_rewardRoot/cat-home-sticker.svg';
  static const _farmReward = '$_rewardRoot/farm-home-sticker.svg';
  static const _churchReward = '$_rewardRoot/church-home-sticker.svg';

  static const all = <LessonDefinition>[
    LessonDefinition(
      id: 'g1_u1_l1',
      grade: 1,
      unit: 1,
      lesson: 1,
      title: 'Letters A, N, T, Y',
      location: MapLocation.school,
      rewardAsset: _schoolReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g1_u1_l7',
      grade: 1,
      unit: 1,
      lesson: 7,
      title: 'Numbers',
      location: MapLocation.school,
      rewardAsset: _catReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g1_u2_l1',
      grade: 1,
      unit: 2,
      lesson: 1,
      title: 'Family',
      location: MapLocation.house,
      rewardAsset: _motherReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g1_u2_l4',
      grade: 1,
      unit: 2,
      lesson: 4,
      title: 'Greeting',
      location: MapLocation.plaza,
      rewardAsset: _parkReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g2_u1_l1',
      grade: 2,
      unit: 1,
      lesson: 1,
      title: 'New Friend',
      location: MapLocation.school,
      rewardAsset: _dogReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g2_u1_l2',
      grade: 2,
      unit: 1,
      lesson: 2,
      title: 'Birthday',
      location: MapLocation.house,
      rewardAsset: _houseReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g2_u2_l1',
      grade: 2,
      unit: 2,
      lesson: 1,
      title: 'Park Greeting',
      location: MapLocation.plaza,
      rewardAsset: _parkReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g2_u2_l2',
      grade: 2,
      unit: 2,
      lesson: 2,
      title: 'Park Dialogue',
      location: MapLocation.plaza,
      rewardAsset: _catReward,
      orientation: LessonOrientation.portrait,
    ),
    LessonDefinition(
      id: 'g3_u1_l1',
      grade: 3,
      unit: 1,
      lesson: 1,
      title: 'Market Numbers',
      location: MapLocation.market,
      rewardAsset: _marketReward,
      orientation: LessonOrientation.landscape,
    ),
    LessonDefinition(
      id: 'g3_u1_l3',
      grade: 3,
      unit: 1,
      lesson: 3,
      title: 'Shopping',
      location: MapLocation.market,
      rewardAsset: _farmReward,
      orientation: LessonOrientation.landscape,
    ),
    LessonDefinition(
      id: 'g3_u2_l1',
      grade: 3,
      unit: 2,
      lesson: 1,
      title: 'Bantay',
      location: MapLocation.house,
      rewardAsset: _dogReward,
      orientation: LessonOrientation.landscape,
    ),
    LessonDefinition(
      id: 'g3_u2_l2',
      grade: 3,
      unit: 2,
      lesson: 2,
      title: 'Story',
      location: MapLocation.market,
      rewardAsset: _churchReward,
      orientation: LessonOrientation.landscape,
    ),
  ];

  static LessonDefinition? byId(String? id) {
    if (id == null) return null;
    for (final definition in all) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  static List<LessonDefinition> forGrade(int grade) =>
      all.where((definition) => definition.grade == grade).toList();

  static List<LessonDefinition> forLocation({
    required int grade,
    required MapLocation location,
  }) => forGrade(
    grade,
  ).where((definition) => definition.location == location).toList();

  static LessonDefinition? firstForGrade(int grade) {
    final lessons = forGrade(grade);
    return lessons.isEmpty ? null : lessons.first;
  }

  static LessonDefinition? nextAfter(LessonDefinition lesson) {
    final sequence = forGrade(lesson.grade);
    final index = sequence.indexWhere((entry) => entry.id == lesson.id);
    if (index < 0 || index + 1 >= sequence.length) return null;
    return sequence[index + 1];
  }
}
