# Lesson Feature — Developer Guide

The lesson feature is a deliberately narrow adapter around the authorized
DevG curriculum. Tudlo owns learner saves, navigation, accessibility, audio
settings, and map state; it does not import DevG's `AppData`, audio stack,
navigation shell, or progress services.

## Structure

```text
lib/features/lesson/
  domain/
    lesson_definition.dart          # 12 stable lesson definitions and order
    lesson_content.dart             # data-only DevG dataset loader
    lesson_progress.dart            # versioned saved completion records
    lesson_progress_controller.dart # learner save + one active map event
  presentation/
    lesson_catalog_screen.dart      # Lessons tab and mapped-location catalog
    lesson_intro_screen.dart        # route into the preserved DevG intro
    devg_lesson_host.dart           # Tudlo-owned route/progress/audio boundary
    devg_lesson_mapping.dart        # stable ID <-> original DevG level mapping
    devg_canonical/                 # source-preservation bridge; see migration guide
```

`LessonDefinition.id` is the stable curriculum/persistence key. Do not use a
Rive name, visual label, or source route number as an alternative ID.

All Tudlo-authored lesson files stay below 500 lines. The temporarily imported
`devg_canonical/` source is an explicit preservation bridge, not the finished
module boundary: it retains the authorized visual/mechanical flows while they
are extracted into small renderers without changing child-facing behaviour.
See `DEVG_LESSON_MIGRATION.md` before editing it. Comments document boundaries
and safeguards, not ordinary Flutter syntax.

## Progress and persistence

`LearnerProfile.lessonProgress` is versioned and backward-compatible. A save
without this field is intentionally `uninitialized`; on its first app launch,
`LessonProgressController` schedules the first lesson for that learner's
grade. Scheduling creates a temporary map event only; it does **not** unlock
the location. No in-session checkpoint is stored.

The only normal progress write is `completeAndClaim` after the reward is
claimed. It stores score, accuracy, mistakes, duration, completion time, and
reward, then permanently unlocks that completed lesson's map location. The
first completion increments `lessonsFinished` and
`stickersEarned`; a replay can replace a weaker result but does not add either
counter or a second daily streak increment. Energy remains an existing
10–100 display/cap and is never spent or recharged by this feature.

## Map boundary

The progress controller clears the prior event override, then creates exactly
one `OpenActiveLessonRouteAction`. `MapScreen` alone projects the result to
the Rive map's documented `isUnlocked` and `hasEvent` values. The controller
never imports a Rive widget or touches `pressTrigger`.

A lesson's own mid-activity "tap X on the map" beat is a separate concern
from this permanent unlock -- see `LESSON_MAP_STEP_FIX.md` for the fake-pin
issue found across most `devg_canonical` flows and the real-map fix pattern.

Mapped default destinations are School, House, Park/`plaza`, and Market. A
normally locked location stays non-navigating. An active lesson event may be
opened directly even while its location is still physically locked; it is the
one temporary exception. Once a lesson at a location is claimed, ordinary
taps open that location's filtered source catalogue, where completed lessons
remain replayable. House shows the Home-or-House-lessons dialog only without
an active override. Map launches return to Map because the intro/session are
pushed above it. Home and catalog launches return to their original route for
the same reason.

## Content, artwork, and audio

`assets/data/lesson_asset_manifest.md` is the audit record for copied source
assets. Add a row before adding any DevG image or audio file. Do not copy the
source archive/tree wholesale.

The source flows invoke supplied voice asset paths through a small compatibility
adapter backed only by `TudloAudioController`. It applies the learner's
master/voice settings and stops narration on exit. Never reintroduce DevG's
audio service, TTS, or a second audio package.

## Orientation

Grade 1–2 sessions stay portrait with exactly the route's `SafeArea`. Grade 3
sessions request landscape only after leaving the map's fullscreen frame and
restore the original portrait policy on every dispose path, including Back and
abandoned attempts.

## Verification

Run `flutter test test/lesson_progress_test.dart` for the catalog, mapping,
old-save migration, completion/replay accounting, restart restoration, and
catalog-lock coverage. Check portrait sessions at 320×480, 360×640, 412×917,
and 800×1200; check Grade 3 at 800×360 and tablet landscape. Confirm a
session abandoned with the close button leaves the same map event active.
