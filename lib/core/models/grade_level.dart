enum GradeLevel { grade1, grade2, grade3 }

class GradeOption {
  final GradeLevel level;
  final String label;

  const GradeOption({required this.level, required this.label});
}

const gradeOptions = [
  GradeOption(level: GradeLevel.grade1, label: 'Grade 1'),
  GradeOption(level: GradeLevel.grade2, label: 'Grade 2'),
  GradeOption(level: GradeLevel.grade3, label: 'Grade 3'),
];

GradeLevel gradeLevelFromLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    'grade 2' => GradeLevel.grade2,
    'grade 3' => GradeLevel.grade3,
    _ => GradeLevel.grade1,
  };
}

extension GradeLevelLabel on GradeLevel {
  String get label {
    return switch (this) {
      GradeLevel.grade1 => 'Grade 1',
      GradeLevel.grade2 => 'Grade 2',
      GradeLevel.grade3 => 'Grade 3',
    };
  }

  int get number {
    return switch (this) {
      GradeLevel.grade1 => 1,
      GradeLevel.grade2 => 2,
      GradeLevel.grade3 => 3,
    };
  }
}
