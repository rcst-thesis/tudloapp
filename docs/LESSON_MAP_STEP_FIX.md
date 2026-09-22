# Lesson "go to the map" step — the standard fix

Several preserved DevG lesson flows include a mid-lesson beat where the
learner is told to "tap X on the map" before continuing. In the untouched
source-preservation bridge, every one of these beats used the same
decorative placeholder instead of Tudlo's real interactive map. This is the
most common outstanding issue across the `devg_canonical` flows.

**This is now the standard fix for every flow with this beat.** Applied so
far to `g1_u1_l1` (Letters, targets School) and `g1_u1_l7` (Numbers, targets
Beach) — see "Already fixed" below for the exact files.

## The placeholder pattern (broken)

```dart
return _LessonOneChrome(
  ...,
  child: Stack(
    children: [
      const Positioned.fill(
        child: _LessonBackgroundAsset(
          asset: 'assets/images/level_game/backgrounds/tudlomap.svg',
        ),
      ),
      Positioned(
        right: view.width * .10,
        bottom: view.height * .18,
        width: view.width * .30,
        height: view.width * .30,
        child: GestureDetector(
          onTap: () async {
            await AppAudioService.instance.playCorrect();
            onNext();
          },
          child: const _LessonOneMapDestinationCue(),
        ),
      ),
      ...
    ],
  ),
);
```

Symptoms:

- The "map" is a static `tudlomap.svg` image, not the real `toadlu_map.riv`
  Rive map used everywhere else in the app.
- The blinking pin (`_LessonOneMapDestinationCue`) is positioned by guessed
  percentages, not tied to any real map location's coordinates.
- The tap target advances the lesson unconditionally.
- Never reflects `isUnlocked`/`hasEvent` state, and looks nothing like the
  real Map tab.

## An earlier, still-wrong attempt (rejected)

The first fix attempt replaced the fake image with a *second* hand-built
widget hosting the bare `RiveMapScene` directly — its own
`InteractiveViewer`, its own copy of `MapScreen`'s cropping/scale math, its
own `RiveMapSceneController`. This is **not** the standard fix: it still
duplicates the whole map instead of reusing it, just with the real Rive
asset instead of a fake image. Do not do this. If you find a lesson step
built this way, replace it with the pattern below.

## The standard fix: reuse `MapScreen` itself, plus an instruction dialog

Two parts, both required:

1. Push Tudlo's **actual `MapScreen`** (the same class the Map tab uses —
   full chrome, bottom nav, expand button, real `isUnlocked` state) with a
   **standalone `MapEventOverrides`** scoped to just this lesson step, not
   the app's shared instance from `MapProgressScope`. Only the target
   location gets an override (`PopMapRouteAction`), so it's the only one
   that glows (`hasEvent`) and is reachable regardless of its real unlocked
   state; every other location keeps its normal locked/unlocked behavior
   and normal navigation, since it's the real screen.

   Also pass `temporaryUnlockedLocations: {target}` on that same
   `MapScreen`. **This is required, not optional** — `hasEvent`'s golden
   glow renders "on top of that location's normal unlocked visual" per
   `RiveMapSceneController.setHasEvent`'s own doc comment, so a location
   that's still really locked (hasn't been completed/claimed yet, which is
   exactly the case while its own lesson is what's currently playing) shows
   locked/grey with no visible glow even with `hasEvent` set — `isUnlocked`
   and `hasEvent` are visually independent flags in code, but the Rive
   asset draws the glow conditioned on the unlocked look. This param makes
   the target location render/behave fully unlocked for the life of *this
   pushed instance only* (`MapScreen`'s own `_syncEventVisuals`) — it never
   writes to `MapProgressController.unlockedLocations`, so the permanent
   reward-unlock state (earned only by completing and claiming the lesson)
   is untouched.
2. Before pushing it, show a dialog telling the learner what to do —
   `_showMapBeatInstructionDialog`. The real `MapScreen` has no room for an
   in-scene message card the way the old fake placeholder did, so the
   dialog is the visual instruction. `_speakForStep`'s existing voice-over/
   TTS narration for this step keeps playing independently, unchanged.

```dart
class _FooMapStep extends StatefulWidget {
  final double progress;
  final VoidCallback onExit;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _FooMapStep({
    required this.progress,
    required this.onExit,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_FooMapStep> createState() => _FooMapStepState();
}

class _FooMapStepState extends State<_FooMapStep> {
  // Pushes Tudlo's one real Map screen -- the same MapScreen the Map tab
  // uses -- instead of rebuilding a second map widget around the bare Rive
  // scene. Its own standalone MapEventOverrides (not MapProgressScope's
  // shared instance) glows only <Location> for the length of this push and
  // pops back into this lesson step once <Location> is tapped; every other
  // location keeps its real unlocked/locked behavior untouched.
  final _overrides = tudlo_map.MapEventOverrides()
    ..setOverride(
      tudlo_map.MapLocation.<target>,
      const tudlo_map.PopMapRouteAction(),
    );
  var _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openMap());
  }

  Future<void> _openMap() async {
    if (_opened || !mounted) return;
    _opened = true;
    await _showMapBeatInstructionDialog(
      context,
      message: '<the beat's own instruction line, reused from _speakForStep>',
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      FadePageRoute<void>(
        page: tudlo_map.MapScreen(
          eventOverrides: _overrides,
          temporaryUnlockedLocations: const {tudlo_map.MapLocation.<target>},
        ),
      ),
    );
    if (!mounted) return;
    await AppAudioService.instance.playCorrect();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      child: const SizedBox.shrink(),
    );
  }
}
```

`_showMapBeatInstructionDialog` is defined once, shared library-wide, in
`grade_one_letter_flow.dart` (every flow file is `part of` the same
library, same as `_LessonOneMapDestinationCue`/`_LessonOneChrome`):

```dart
Future<void> _showMapBeatInstructionDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LessonOneMessageCard(message: message),
          const SizedBox(height: 16),
          _LessonOneBlueButton(
            label: 'Sige',
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    ),
  );
}
```

Reuse it as-is; don't reimplement it per flow.

### What makes `PopMapRouteAction` work

- `PopMapRouteAction` (`lib/features/map/domain/map_route_resolver.dart`) is
  a `MapRouteAction` that means "pop this `MapScreen` route" instead of
  navigating onward — added specifically for this pattern.
- `MapScreen._handleLocationTapped`'s switch pops on this action
  (`lib/features/map/presentation/screens/map_screen.dart`).
- `MapTapPolicy.canOpen` (`lib/features/map/domain/map_tap_policy.dart`)
  bypasses the normal `isUnlocked` requirement for `PopMapRouteAction`, the
  same way it already does for `OpenActiveLessonRouteAction` — this beat is
  a temporary in-lesson entrance, not a permanent unlock. (In practice
  `temporaryUnlockedLocations` below already makes the target look/behave
  unlocked, so this rarely matters for the target itself, but it's what
  keeps the beat reachable in general even if a flow ever needs the target
  to look locked while still being tappable.)
- `MapScreen.temporaryUnlockedLocations` (`lib/features/map/presentation/
  screens/map_screen.dart`) makes each listed location render/behave fully
  unlocked for this pushed instance's lifetime only, without touching
  `MapProgressController.unlockedLocations` — required for the target
  location's `hasEvent` glow to actually be visible (see the fix
  description above).
- `tudlo_map` is the shared alias already imported once in
  `level_game_page.dart` (covering `map_location.dart`,
  `map_route_resolver.dart`, and `map_screen.dart`) — every flow file gets
  it for free as a `part of` file; no new per-flow import needed.

## Picking `<target>`

**Do not assume `<target>` is `LessonDefinition.location`.** That field is
the location permanently unlocked when the *whole lesson* is completed and
claimed (see `LESSON_GUIDE.md`'s "Map boundary" section) — it is not
necessarily the same place this one mid-lesson beat's story is about. Read
the step's own dialogue/asset context (and reuse its exact instruction
text for the dialog) to find the real target:

- `g1_u1_l1` (Letters) → beat targets **School** — matches
  `LessonDefinition.location` here.
- `g1_u1_l7` (Numbers, lives in `grade_one_greeting_flow.dart` as
  `_GradeOneUnitOneLessonSevenBeachFlow`) → beat targets **Beach**, even
  though this lesson's `LessonDefinition.location` is School — the
  mid-lesson beat is the beach-themed story ("Init gid ang balas!"), so it
  does **not** match the catalog's completion-unlock location. Confirm the
  intended location with product/the person asking before generalizing
  "beat target == catalog location" to any other flow.

## Already fixed

- `grade_one_letter_flow.dart` — `_LessonOneMapStep` → School
  (`temporaryUnlockedLocations: {MapLocation.school}`). Dialog message:
  "I-tap ang eskwelahan sa mapa. Didto ta mangita." This step passes
  `startExpanded: true` so its real map opens in the expand button's landscape
  view; ordinary Map-tab entry still opens in portrait.
- `grade_one_greeting_flow.dart` — `_BeachMapStep` → Beach
  (`temporaryUnlockedLocations: {MapLocation.beach}`). Dialog message:
  "I-tap ang Beach sa mapa." This step also passes `startExpanded: true`
  so the map opens in the expanded view.

## Still using the fake pin (`_LessonOneMapDestinationCue`)

Check each one's actual in-story target (and its `_speakForStep` copy for
the dialog message) before fixing — do not default to
`LessonDefinition.location` without verifying against the step's dialogue.

- `grade_one_family_flow.dart` (`g1_u2_l1`, catalog location: House)
- `grade_two_new_friend_flow.dart` (`g2_u1_l1`, catalog location: School)
- `grade_two_birthday_flow.dart` (`g2_u1_l2`, catalog location: House)
- `grade_two_park_greeting_flow.dart` (`g2_u2_l1`, catalog location: Plaza)
- `grade_two_park_dialogue_flow.dart` (`g2_u2_l2`, catalog location: Plaza)

`_LessonOneMapDestinationCue` is defined once in `grade_one_letter_flow.dart`
but shared library-wide — update its "still used by" comment there each
time another flow drops it, and do not delete the class until every flow in
that list has been migrated.

## Verification

- `flutter analyze` on every changed file (flow file(s), plus
  `map_route_resolver.dart`/`map_tap_policy.dart`/`map_screen.dart` the
  first time this pattern is introduced — no changes needed there again
  once `PopMapRouteAction` exists).
- `flutter test test/lesson_progress_test.dart test/map_screen_test.dart`.
- `test/devg_lesson_flow_render_test.dart` has pre-existing, unrelated
  flakiness around `g2_u2_l2` layout overflow and offline `google_fonts`
  network fetches — check the failure names the lesson you actually touched
  before assuming a regression.
- Manually confirm: the dialog shows the right instruction, dismissing it
  opens the real Map screen with the target location both unlocked-looking
  and glowing (not locked-with-glow — a real symptom if
  `temporaryUnlockedLocations` is missing), tapping any other location
  behaves exactly as it does on the real Map tab, and tapping the target
  location pops back into the lesson and advances it.
