# Barangay Map — Developer Guide

Practical instructions for working with Koka's interactive barangay map.
For the Rive asset contract itself (artboard/state machine/view model
names), see [`RIVE_INTEGRATION.md`](RIVE_INTEGRATION.md#barangay-map-contract) —
this doc is about using and extending the Flutter side.

## Files

```
lib/features/map/
  domain/
    map_location.dart        # MapLocation enum (house, school, plaza, ...)
    map_route_resolver.dart  # MapDefaultRoutes, MapEventOverrides, route actions
  presentation/
    screens/map_screen.dart          # Owns navigation, tap debounce, camera framing
    widgets/rive_map_scene.dart      # Loads the .riv, unlock/event writes, tap listening
    widgets/map_expand_button.dart   # Fullscreen toggle (portrait -> landscape)
    widgets/map_exit_landscape_button.dart
```

Asset: `assets/images/toadlu_map.riv`.

## Current lesson integration

The app now owns one `LessonProgressController`, wired beside
`MapProgressScope` in `TudloApp`. It restores a learner's active lesson as
exactly one `OpenActiveLessonRouteAction`; it does not access a Rive
controller. `MapScreen` remains the only layer that writes the map's
`isUnlocked`/`hasEvent` values.

- School, Park (`MapLocation.plaza`), and Market defaults push the same
  grade-aware catalog used by the Lessons bottom tab, filtered to that place.
- House's default opens a two-icon popup: Home or its filtered catalog.
- An active event at any of those places, including House, bypasses the
  default and opens its matching lesson intro directly.
- A completion clears the old event before scheduling the one next lesson.
  Closing an intro/session without claiming its reward does not alter it.

Lesson code must use `LessonProgressController.completeAndClaim`; do not call
`MapEventOverrides.setOverride` directly for normal curriculum progression.

## How a tap becomes a navigation

1. `RiveMapScene` doesn't detect taps itself -- **this Rive file does**, via
   its own internal per-location Listener components. `RiveWidget`'s
   built-in hit-testing routes pointer events to them automatically; Flutter
   lays no tap zones over the art.
2. Rive fires `<location>/locationTapped` for every tap it registers,
   **locked or not** -- it already played its own press or locked-shake
   feedback by the time Flutter hears about it. `RiveMapScene` forwards this
   to `MapScreen.onLocationTapped`.
3. `MapScreen._handleLocationTapped` runs:
   - if `RiveMapSceneController.isUnlocked(location)` is `false`, shows a
     brief locked-explanation `SnackBar` and stops -- no navigation,
   - otherwise blocks a second tap while one is in flight (no
     double-navigation),
   - waits ~150ms (so Rive's already-playing press animation is visible),
   - resolves the destination (see next section),
   - navigates.

## Adding a real screen for a location

School, Park, and Market already use the lesson catalog. Farm, Beach, Church,
and Hospital still use their temporary `PlaceholderScreen`. To wire one of
those remaining locations to a real screen, edit `MapDefaultRoutes` in
`lib/features/map/domain/map_route_resolver.dart`:

```dart
static Widget _plaza(BuildContext context) => const PlazaScreen();
```

Just replace the `PlaceholderScreen(...)` body of that location's static
builder method with your real screen. Nothing else needs to change — the
tap-handling flow in `MapScreen` and the availability gating stay the same.

House is different: its default is `ShowHouseChoiceRouteAction()`, which opens
the Home-or-House-lessons dialog. Keep an active lesson as an override rather
than changing this default -- that is what makes the event correctly bypass
the dialog.

## The event/lesson override system

Every location has a **default** route (`MapDefaultRoutes`, above). An
active lesson or event can **temporarily override** where a location goes,
without touching the default. This is what `MapEventOverrides` is for.

### The rule

```
active event's route for this location, if one is set
otherwise
the location's default route
```

That's it — `MapEventOverrides.resolve(location)` implements exactly this.

### Example: a house-specific lesson

```dart
// When the lesson becomes active:
eventOverrides.setOverride(
  MapLocation.house,
  PushScreenRouteAction((context) => const HouseLessonScreen()),
);

// When a one-off custom event ends:
eventOverrides.clearOverride(MapLocation.house);
// House automatically goes back to its Home-or-House-lessons chooser.
```

### Example: a multi-stop event (e.g. "find the dog")

```dart
void startDogFindingEvent(MapEventOverrides overrides) {
  overrides.setOverride(
    MapLocation.market,
    PushScreenRouteAction((context) => const DogFindingMarketStopScreen()),
  );
  overrides.setOverride(
    MapLocation.farm,
    PushScreenRouteAction((context) => const DogFindingFarmStopScreen()),
  );
}

void endDogFindingEvent(MapEventOverrides overrides) {
  overrides.clearOverride(MapLocation.market);
  overrides.clearOverride(MapLocation.farm);
  // Or just overrides.clearAll() if nothing else has an override active.
}
```

Every location not explicitly overridden keeps working normally the whole
time — you only ever touch the locations the event actually affects.

### The visual side: `hasEvent` is temporary; `isUnlocked` is earned

An override makes Rive render the location with its golden event glow while
that override exists. It does **not** permanently unlock the location. On
each synchronization pass `MapScreen` writes only the documented contract:

```
setUnlocked(house, true) // intentional Home destination
for every other location:
  setUnlocked(location, mapProgress.unlockedLocations.contains(location))
for every location:
  setHasEvent(location, overrides.overrideFor(location) != null)
```

The lesson controller creates an `OpenActiveLessonRouteAction` for the one
active lesson. `MapScreen` permits that one action to open even if the visual
location remains locked, so a glowing lesson entrance is reachable. A normal
tap on a locked location remains non-navigating. The permanent unlock happens
only when the learner claims a completed lesson reward; the learner save then
updates `unlockedMapLocations`, which is projected to `isUnlocked` on the
next sync.

When no event is active, every `hasEvent` value is `false`; `isUnlocked` is
exactly the learner-owned location set (plus the intentional always-available
House). An unlocked mapped location opens its filtered lesson catalogue and
completed lessons there can be replayed.

`MapProgressController.unlockedLocations` is an in-memory projection for the
map. `LearnerProfile.unlockedMapLocations` is the persisted source of truth.
`LessonProgressController.completeAndClaim` is the only lesson path allowed
to add a permanent location unlock. Do not call `setHasEvent` or
`setUnlocked` on `RiveMapScene` from feature code.

### Wiring it up — already done, here's how

`AppBottomTabNavigation` builds a fresh `MapScreen()` every time the Map tab
is selected, which would normally mean any override/unlock set while Map
isn't on screen gets lost by the time the player reopens it. That's solved:
`MapScreen` finds the app's one shared `MapProgressController` for itself,
via `MapProgressScope.of(context)`, and uses its `eventOverrides` and
`unlockedLocations`. You don't need to pass anything into `MapScreen` or
touch `app_bottom_tab_navigation.dart` at all.

```
lib/features/map/domain/map_progress.dart
  MapProgressController  -- owns the shared MapEventOverrides + unlockedLocations
  MapProgressScope        -- InheritedWidget making it reachable from anywhere

lib/app/tudlo_app.dart
  Instantiates MapProgressController once, wraps the app in MapProgressScope
  (same pattern as the existing AppAnimationController/AppAnimationScope).
```

To actually trigger an event from your lesson/event system, get the shared
overrides from wherever you have a `BuildContext` and call `setOverride`/
`clearOverride` exactly as shown above:

```dart
final overrides = MapProgressScope.of(context).eventOverrides;
overrides.setOverride(
  MapLocation.house,
  PushScreenRouteAction((context) => const HouseLessonScreen()),
);
// ...and later:
overrides.clearOverride(MapLocation.house);
```

`MapScreen` never disposes `MapProgressController`'s `eventOverrides` (it's
owned by `TudloApp`, not the screen) — this is safe to call from anywhere,
any number of times, across as many Map visits as you like.

`MapScreen`'s own `eventOverrides` constructor parameter still exists, but
it's for tests only (supply an isolated instance instead of reaching into
the shared one). Real app code shouldn't need it.

### What NOT to do

- Don't put per-lesson/per-event navigation logic inside `RiveMapScene` or
  the Rive asset. Rive only renders visuals (locked/unlocked, event glow,
  press/locked-shake feedback, and now tap detection itself); Flutter
  decides what each boolean means and when to set it. Route resolution is
  100% Flutter's job, via `MapEventOverrides`.
- Don't forget to clear an override when its event ends. A forgotten
  override keeps hijacking that location's tap and leaves it glowing; it does
  not, however, grant a permanent unlock.
- Don't hand-roll a second "is there an active event" check elsewhere —
  `MapEventOverrides.resolve()` is the single source of truth Map already
  consults on every tap, and `overrideFor()` is what drives the visual.

## Unlocking (isUnlocked)

Each location's unlocked state is **entirely Flutter-owned** data now
(`<location>/isUnlocked` in the `MapState` view model's `LocationState`
instances) — Rive only renders it (gray/locked vs. full-color/accessible)
and reads it to decide whether a tap plays the locked-shake or the normal
press feedback. Unlike the previous map asset, there's no Rive-side unlock
logic to defer to: a completion/milestone must update the learner-owned
location set through its owning controller so the next `_syncEventVisuals`
pass writes `true` for it. Lesson completion specifically goes through
`LessonProgressController.completeAndClaim`, not directly through the map.

House is the one location whose `isUnlocked` never depends on progression —
`MapScreen._syncEventVisuals` writes `true` for it unconditionally, every
time, from the start of a new game.

Active-event overrides never permanently set `isUnlocked`. They set only
`hasEvent`; claiming the lesson is the normal-progression action that earns
the location. Don't add a second permanent-unlock path.

For **local testing only**, you can force a location unlocked by adding it
to `MapProgressController.unlockedLocations` directly, or by setting its
bound boolean's `.value` directly in `RiveMapScene._load()` (a runtime
write to the view model instance, not an edit to the `.riv` file itself,
so it's safe/reversible):

```dart
// TEMP: force <location> unlocked for testing. Remove when done.
unlockedProps[MapLocation.plaza]?.value = true;
```

Remove it before shipping — it's a debug convenience, not a feature.

## Tap detection

This map asset detects taps itself via internal Listener components per
location — there's nothing to calibrate on the Flutter side (no tap-zone
`Rect`s, unlike the previous map asset). If a future art export changes
which area triggers a location's tap, that's an asset-side change made in
the Rive editor, not a Flutter code change.

## Hot reload vs. restart

Rive loading happens in `RiveMapScene`'s `initState()`, which only runs
once per State instance. **Hot reload will not pick up changes to:**
- the `.riv` asset file itself,
- unlock/event-write logic,
- anything else inside `_load()`.

Use a **full restart** (`R` in `flutter run`, or stop + rerun if a hot
restart doesn't pick up a brand-new/removed asset file) for those. Pure
`build()`-level tweaks (sizes, colors, layout) are fine with a plain hot
reload.
