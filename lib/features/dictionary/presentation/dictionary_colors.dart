import 'package:flutter/material.dart';

/// Shared Dictionary screen palette, matching the user-supplied design
/// reference. Centralized here (unlike most screens' local color consts)
/// because these four colors are coordinated across several widget files.
abstract final class DictionaryColors {
  static const ink = Color(0xFF392F5A);
  static const cardBackground = Color(0xFFF4909A);
  static const background = Color(0xFFFFB3BA);
  static const heart = Color(0xFFDE596D);
}
