# Lesson "go to the map" step — fake pin to real Rive map

Several preserved DevG lesson flows include a mid-lesson beat where the
learner is told to "tap X on the map" before continuing. In the untouched
source-preservation bridge, every one of these beats used the same
decorative placeholder instead of Tudlo's real interactive map. This is the
most common outstanding issue across the `devg_canonical` flows — apply this
fix wherever you find the placeholder pattern below.

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
- The tap target advances the lesson unconditionally — tapping the pin
  always "succeeds" regardless of which real location it's near.
- Visually inconsistent with `MapScreen`'s real map, and it never reflects
  `isUnlocked`/`hasEvent` state.

## The fix (real map)

Replace the `StatelessWidget` step with a `StatefulWidget` that hosts the
real Rive map, scoped to this lesson step only:

```dart
class _FooMapStepState extends State<_FooMapStep> {
  // Reuses MapScreen's real map (toadlu_map.riv) and its own default
  // portrait framing constants (Koka's house) -- this is not a second/fake
  // map, just this lesson's narrow "go to <Location>" beat on the one real
  // Rive map, per the migration guide: keep Tudlo's existing Rive map,
  // drive it only through semantic hasEvent/isUnlocked.
  static const _mapWidth = tudlo_map.RiveMapScene.artboardWidth;
  static const _mapHeight = tudlo_map.RiveMapScene.artboardHeight;
  static const _houseCenterX = 2085.0;
  static const _houseCenterY = 1064.5;
  static const _cropWidth = 420.0;
  static const _verticalAnchor = 0.42;

  final _transformationController = TransformationController();
  final _riveMapController = tudlo_map.RiveMapSceneController();
  Size? _viewportSize;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // Nothing is glowing until this beat's own Rive scene finishes loading --
  // the event exists only for this lesson step, never set early and never
  // visible anywhere else on the real map.
  void _onMapReady() {
    _riveMapController.setUnlocked(tudlo_map.MapLocation.<target>, true);
    _riveMapController.setHasEvent(tudlo_map.MapLocation.<target>, true);
  }

  Future<void> _handleLocationTapped(tudlo_map.MapLocation location) async {
    if (location != tudlo_map.MapLocation.<target>) return;
    await AppAudioService.instance.playCorrect();
    widget.onNext();
  }

  Matrix4 _framedOnHouse(Size viewport) { /* crop math, unchanged */ }

  @override
  Widget build(BuildContext context) {
    return _LessonOneChrome(
      progress: widget.progress,
      onExit: widget.onExit,
      onReplay: widget.onReplay,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // frame the viewport on the house, compute min/max scale, then:
          return InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: EdgeInsets.zero,
            minScale: minScale,
            maxScale: maxScale,
            child: RepaintBoundary(
              child: tudlo_map.RiveMapScene(
                controller: _riveMapController,
                onLocationTapped: _handleLocationTapped,
                onReady: _onMapReady,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

`tudlo_map` here is the alias already imported once in `level_game_page.dart`
(`import '.../map_location.dart' as tudlo_map;` and
`import '.../rive_map_scene.dart' as tudlo_map;`) — every flow file is a
`part of` that library, so the alias is available without a new import.

The old placeholder message card (e.g. `_LessonOneMessageCard(message: 'Tap
ang Beach.')`) is dropped; the real map fills the whole step, matching how
`_LessonOneMapStep` already looks.

## Picking `<target>`

**Do not assume `<target>` is `LessonDefinition.location`.** That field is
the location permanently unlocked when the *whole lesson* is completed and
claimed (see `LESSON_GUIDE.md`'s "Map boundary" section) — it is not
necessarily the same place this one mid-lesson beat's story is about. Read
the step's own dialogue/asset context to find the real target:

- `g1_u1_l1` (Letters) → beat targets **School** (`grade_one_letter_flow.dart`,
  `_LessonOneMapStep`) — matches `LessonDefinition.location` here.
- `g1_u1_l7` (Numbers, lives in `grade_one_greeting_flow.dart` as
  `_GradeOneUnitOneLessonSevenBeachFlow`) → beat targets **Beach**
  (`_BeachMapStep`/`_BeachMapStepState`), even though this lesson's
  `LessonDefinition.location` is School — the mid-lesson beat is the
  beach-themed story ("Init gid ang balas!"), so it does **not** match the
  catalog's completion-unlock location. Confirm the intended location with
  product/the person asking before generalizing "beat target == catalog
  location" to any other flow.

## Already fixed

- `grade_one_letter_flow.dart` — `_LessonOneMapStep` → School.
- `grade_one_greeting_flow.dart` — `_BeachMapStep` → Beach.

## Still using the fake pin (`_LessonOneMapDestinationCue`)

Check each one's actual in-story target before fixing — do not default to
`LessonDefinition.location` without verifying against the step's dialogue,
per the caveat above.

- `grade_one_family_flow.dart` (`g1_u2_l1`, catalog location: House)
- `grade_two_new_friend_flow.dart` (`g2_u1_l1`, catalog location: School)
- `grade_two_birthday_flow.dart` (`g2_u1_l2`, catalog location: House)
- `grade_two_park_greeting_flow.dart` (`g2_u2_l1`, catalog location: Plaza)
- `grade_two_park_dialogue_flow.dart` (`g2_u2_l2`, catalog location: Plaza)

`_LessonOneMapDestinationCue` is defined once in `grade_one_letter_flow.dart`
but shared library-wide (every flow file is `part of` the same library) —
update its "still used by" comment there each time another flow drops it, and
do not delete the class until every flow in that list has been migrated.

## Verification

- `flutter analyze` on the changed flow file.
- `flutter test test/lesson_progress_test.dart` and
  `test/devg_lesson_flow_render_test.dart` (the latter has pre-existing,
  unrelated flakiness around `g2_u2_l2` layout overflow and offline
  `google_fonts` network fetches — check the failure names the lesson you
  actually touched before assuming a regression).
- Manually confirm the intended location actually glows (`hasEvent`) and
  that tapping any other location does nothing, per
  `_handleLocationTapped`'s guard.
