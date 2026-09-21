# Learner Save System — Developer Guide

The app's one persistence layer: who the current learner is, and everything
about their progress. If you're adding a screen or feature that needs to
read or remember something about the player, this is almost certainly where
it belongs — read this before reaching for `shared_preferences` yourself or
inventing a second state mechanism.

## TL;DR

```dart
// Read the current learner from anywhere with a BuildContext:
final learner = LearnerScope.of(context).profile;   // LearnerProfile? -- null if none loaded yet
learner?.name
learner?.grade
learner?.lessonsFinished

// Write to it (always goes through the controller, never construct/save a
// LearnerProfile yourself):
await LearnerScope.of(context).unlockMapLocation('market');
```

## Files

```
lib/features/learner/domain/
  learner_profile.dart    -- LearnerProfile: the data itself (name, grade, energy,
                              lessonsFinished, stickersEarned, badgesEarned,
                              currentStreak, unlockedMapLocations, and versioned
                              lessonProgress). Plain and JSON-serializable;
                              it has no Flutter/widget dependency.
  learner_repository.dart -- LearnerRepository: the on-device storage (shared_preferences).
                              Nothing else in the app should touch shared_preferences
                              for learner data directly -- go through the controller.
  learner_scope.dart       -- LearnerController (owns the current profile, the only
                              thing allowed to create/mutate/save one) + LearnerScope
                              (an InheritedNotifier making it reachable from any
                              BuildContext without prop-drilling).
```

Wired once, app-wide, in `lib/app/tudlo_app.dart`:

```dart
final _learnerController = LearnerController();

@override
void initState() {
  super.initState();
  unawaited(_learnerController.loadSaved());   // restores the last learner, if any
}

// ...in build():
LearnerScope(
  controller: _learnerController,
  child: MaterialApp(...),
)
```

Same pattern as `AppAnimationScope` (`lib/core/motion/app_animation_controller.dart`)
and `MapProgressScope` (`lib/features/map/domain/map_progress.dart`) — if you've
worked with either of those, this works identically.

## The data model

```dart
class LearnerProfile {
  final String id;                        // generated once, stable for this learner
  final String name;
  final int grade;
  final int energy;
  final DateTime createdAt;
  final int lessonsFinished;
  final int stickersEarned;
  final int badgesEarned;
  final int currentStreak;
  final Set<String> unlockedMapLocations; // raw location ids (see Map integration below)
  final LessonProgress lessonProgress;    // active lesson + claimed results
}
```

It's immutable — there's a `copyWith` for the fields that change over time
(`lessonsFinished`, `stickersEarned`, `badgesEarned`, `currentStreak`,
`unlockedMapLocations`, and `lessonProgress`). `id`, `name`, `grade`, `energy`, `createdAt` are set
once at creation and don't change through `copyWith` (grade/name changes,
if ever needed, aren't wired up yet -- ask before adding them, there's no
edit-profile flow today).

## Reading learner data in a screen

Every screen that displays learner data follows the same pattern — an
explicit constructor override for tests, falling back to `LearnerScope` for
real use. Copy this shape for any *new* screen that needs learner data:

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({this.someField, super.key});
  final int? someField;   // nullable = "override me in tests", null = "use the real learner"

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int get _someField =>
      widget.someField ?? LearnerScope.of(context).profile?.someField ?? /* sane default */;
}
```

`HomeScreen` and `MeScreen` are the reference implementations of this
pattern — read them if you want a concrete example. Note it's a *getter*,
not a field computed once: `LearnerScope.of(context)` needs to be called
during build (or `didChangeDependencies`), and re-reading it live is what
makes the screen rebuild automatically when the learner profile changes
elsewhere in the app.

**Why nullable + fallback, not just reading `LearnerScope` directly?** So
every existing test that constructs `HomeScreen(energy: 10)` or similar
keeps working unchanged — explicit constructor values always win. Don't
remove this pattern to "simplify" a screen; it's what keeps tests from
needing `LearnerScope` boilerplate for scenarios that don't care about it.

## Writing learner data

Never construct or mutate a `LearnerProfile` directly, and never touch
`LearnerRepository`/`shared_preferences` from outside
`lib/features/learner/`. Always go through `LearnerController` via
`LearnerScope.of(context)`:

```dart
final learner = LearnerScope.of(context);

// Onboarding finishing (already wired, see learner_card_screen.dart):
await learner.createAndSave(name: 'Maya', grade: 2, energy: 80);

// Recording a map location unlock (already wired, see map_screen.dart):
await learner.unlockMapLocation('market');
```

If you need to track something new (e.g. `lessonsFinished` incrementing
when a real lesson completes), **add a method to `LearnerController`** that
does the `copyWith` + `notifyListeners()` + best-effort save, the same shape
as `unlockMapLocation`:

```dart
Future<void> completeLesson() async {
  final current = _profile;
  if (current == null) return;
  final updated = current.copyWith(lessonsFinished: current.lessonsFinished + 1);
  _profile = updated;
  notifyListeners();
  try {
    await _repository.save(updated);
  } catch (_) {
    // best-effort, same as every other write here
  }
}
```

Don't add a second, parallel way to persist progress data (a new
`SharedPreferences` key elsewhere, a separate controller) — extend
`LearnerController` instead, so there's exactly one place that knows what a
learner's saved state looks like.

## Lesson progression

Lesson-specific coordination lives in
`lib/features/lesson/domain/lesson_progress_controller.dart`, but persistence
still goes through `LearnerController`. A backward-compatible profile with no
`lessonProgress` field receives a grade's first active lesson when
`LessonProgressController` starts. `recordLessonCompletion` is the only
normal completion write: it updates a stored result, first-completion counters,
one-per-local-day streak progress, the next active lesson, and affected map
location ids in one learner save. A replay may improve a result but never
duplicates lesson or sticker counts.

## Error handling: storage can fail, and that's fine

Every read/write in `LearnerController` is wrapped so a storage failure
(missing plugin in a test, disk error, corrupt data) never crashes the
caller — it just means that read/write silently no-ops and the app keeps
running on in-memory state. **Keep this pattern** if you add new methods:
update `_profile` and call `notifyListeners()` synchronously first (so the
app behaves correctly for the rest of this session even if the disk write
fails), then attempt the actual persistence in a `try`/`catch` that swallows
errors. This matters concretely: this project's tests don't mock
`shared_preferences`, and `SharedPreferences.getInstance()` throws
`MissingPluginException` in that environment -- without this pattern, adding
a learner-data write to a screen's real code path will break its tests.

## Map integration (earned unlocks and temporary lesson events)

`lib/features/map/domain/map_progress.dart`'s `MapProgressController` holds
an app-wide, in-memory *view* of which locations are unlocked
(`unlockedLocations`, a `Set<MapLocation>`), used to drive the Rive map's
visuals. `MapScreen` is what bridges it to the real, persisted source of
truth in `LearnerProfile.unlockedMapLocations`:

- On load, it seeds `MapProgressController` from
  `LearnerScope.of(context).profile?.unlockedMapLocations`.
- A scheduled active lesson only supplies a temporary `hasEvent` glow and a
  direct lesson entrance. It never writes a permanent unlock.
- `LessonProgressController.completeAndClaim()` owns the permanent lesson
  effect: it records the claimed completion and writes that lesson's location
  into the learner profile. The controller then rebuilds the map projection.

The two are deliberately separate types (`MapLocation` enum vs. raw
`String` ids in `LearnerProfile`) so `map`'s domain and `learner`'s domain
don't depend on each other — `MapLocation.fromPersistedId(String)` is the
conversion point, and `MapScreen` (presentation, allowed to know about both
features) is the only thing that bridges them. Don't have `learner` import
`map`'s types or vice versa.

## Onboarding → learner flow

```
NameScreen (collects name)
  -> GradeSelectionScreen (collects grade)
    -> EnergySetterScreen (collects energy)
      -> SecondLoadingScreen (asset warmup only)
        -> LearnerCardScreen  <-- _finish() creates + saves the LearnerProfile here
          -> HomeLoadingScreen -> WelcomeAboardScreen -> HomeScreen
```

`LearnerCardScreen._finish()` is the single point where a new learner comes
into existence. If you're changing onboarding (adding a field to collect,
changing the flow order), that's the method to look at — everything
upstream of it is just constructor-param relay with no persistence
involved, same as before this system existed.

Two things worth knowing if you touch this flow:
- The relay chain **does not** validate that grade/energy actually reach
  `LearnerCardScreen` intact if you insert a new screen in the middle --
  double check your new screen forwards every param it receives.
- `LearnerCardScreen`'s `onContinue` constructor param (used by some tests
  to intercept "finish" instead of letting it navigate) **skips learner
  creation entirely** when supplied -- that's intentional, so tests using it
  don't need `shared_preferences` mocking. Don't rely on a learner having
  been created if you're testing through `onContinue`.

## What's NOT built yet

- **No profile switching / multiple learners UI.** Storage supports it
  (`LearnerRepository` stores every profile by its own `id`, keyed
  separately from "which one is current"), but there's no screen for
  creating a second learner or switching between them. Don't build that
  without checking it's actually wanted first -- it's a real feature, not a
  quick addition.
- **No profile editing.** Once created, `name`/`grade`/`energy` never
  change (`MeScreen`'s edit button still opens a `PlaceholderScreen`).
- **No cloud sync / backend.** Purely local, on-device, per-install. If
  cross-device sync is ever wanted, that's a much bigger addition (accounts,
  networking, conflict resolution) -- don't back into it by quietly changing
  `LearnerRepository`'s internals.
