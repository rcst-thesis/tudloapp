# Asset Organization

Images are split by whether the app ships them, who owns them, and whether
they are still used by current code.

## Shipped Images

- `assets/images/stickers/rewards/home/`
  - Reward stickers currently assigned by the lesson completion flow.
- `assets/images/level_game/`
  - Lesson gameplay assets that are still shared across multiple grades or
    older lesson flows.
- `assets/images/level_game/grade1/`, `grade2/`, `grade3/`
  - Grade-specific lesson assets.
- `assets/images/dialogue/`, `game_map/`, `navbar/`, `profile/`,
  `word-of-the-day/`, `onbaording/`
  - Feature-owned UI images used outside an individual lesson.

## Non-Shipped Image Archive

- `assets/archive/images/stickers/unused_current/`
  - Current-version sticker artwork that is not referenced by app code.
- `assets/archive/images/stickers/old_versions/`
  - Legacy duplicate sticker locations kept for reference.

Do not add archive folders to `pubspec.yaml`; this keeps unused artwork out of
the Flutter asset bundle.

## Recommended Next Step

As new lesson assets are added, prefer:

`assets/images/levels/grade_<n>/unit_<n>/lesson_<n>/<kind>/`

Examples:

- `assets/images/levels/grade_3/unit_2/lesson_1/animals/`
- `assets/images/levels/grade_3/unit_2/lesson_1/clues/`
- `assets/images/levels/shared/ui/`

Move existing lesson assets gradually when touching those lessons, then update
the hardcoded asset paths in the matching flow file.
