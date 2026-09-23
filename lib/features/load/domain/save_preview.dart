import 'package:flutter/material.dart';

import 'package:tudloapp/features/learner/domain/learner_profile.dart';

enum GradeLevel {
  grade1(
    number: 1,
    frontColor: Color(0xFF42A32E),
    shadowColor: Color(0xFF417836),
    assetPath: 'assets/images/koka_green.png',
  ),
  grade2(
    number: 2,
    frontColor: Color(0xFF235B8F),
    shadowColor: Color(0xFF214668),
    assetPath: 'assets/images/koka_blue.png',
  ),
  grade3(
    number: 3,
    frontColor: Color(0xFF8F2020),
    shadowColor: Color(0xFF560E0E),
    assetPath: 'assets/images/koka_red.png',
  );

  const GradeLevel({
    required this.number,
    required this.frontColor,
    required this.shadowColor,
    required this.assetPath,
  });

  /// The raw grade number (`1`-`3`), for `RiveAvatarBackground(grade: ...)`.
  final int number;
  final Color frontColor;
  final Color shadowColor;
  final String assetPath;
}

class SavePreview {
  const SavePreview({
    required this.name,
    required this.grade,
    required this.avatarId,
    this.profileId,
  });

  final String name;
  final GradeLevel grade;
  final String avatarId;

  /// The real learner this save resumes, or `null` for the one fixed demo
  /// card that isn't backed by any persisted profile.
  final String? profileId;

  bool get isDemo => profileId == null;

  Color get previewColor => grade.frontColor;
  Color get previewShadowColor => grade.shadowColor;
  String get assetPath => grade.assetPath;

  factory SavePreview.fromProfile(LearnerProfile profile) => SavePreview(
    name: profile.name,
    grade: switch (profile.grade) {
      2 => GradeLevel.grade2,
      3 => GradeLevel.grade3,
      _ => GradeLevel.grade1,
    },
    avatarId: profile.avatarId,
    profileId: profile.id,
  );
}
