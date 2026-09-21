# Rive Integration Status and Rules

## Confirmed State

The app uses `rive: ^0.14.10` (resolved to `0.14.11`) with the Flutter Rive
renderer. Runtime assets are stored under `assets/images/`, which is already
declared in `pubspec.yaml`. `main()` initializes `RiveNative` before the app
is shown so the first Rive control does not need to initialize the renderer on
its first interaction.

The current runtime-contract inventory is:

| `.riv` file | Artboard | State machine | Inputs/events/bindings | Flutter owner |
| --- | --- | --- | --- | --- |
| `assets/images/koka_mascot.riv` | Default artboard | `State Machine 1` | Legacy triggers `Hi`, `Curious`, `Annoyed` | `HomeKokaMascot` |
| `assets/images/longbtn.riv` | Default component artboard | Default exported machine | Data Binding: `buttonLabel` string, `activated` trigger; legacy `isPressed` drives press motion | `RiveLongButton` |
| `assets/images/settings_button.riv` | `SettingsButton` | `SettingsButtonStateMachine` | Data Binding: `activated` trigger; legacy `isPressed` drives press and gear rotation | `RiveSettingsButton` |
| `assets/images/settings_button_home.riv` | `SettingsButton` | `SettingsButtonStateMachine` | Home-specific Settings visual; same `activated` and `isPressed` contract | `HomeSettingsButton` |
| `assets/images/settings_button_me.riv` | `SettingsButton` | `SettingsButtonStateMachine` | View Model `SettingsButtonVM` (`activated` trigger); legacy `isPressed` boolean drives press and gear rotation | `MeSettingsButton` |
| `assets/images/green_back_button.riv` | `Artboard` (93 × 44) | `State Machine 1` | View Model `Button` (`pressed` boolean only; no trigger) drives press motion | `RiveBackButton` |
| `assets/images/edit_button_me.riv` | `Artboard` (190 × 198) | `State Machine 1` | View Model `Button` (`down` boolean only; no trigger) drives press motion | `RiveEditButton` (via `MeEditButton`) |
| `assets/images/toadlu_map.riv` | Default artboard (2400 × 1400) | Default state machine + one nested `LocationStateMachine<Name>` per location (internal only, not Flutter-referenced) | View Model `MapState`: per-location (`house`, `school`, `park`, `market`, `farm`, `beach`, `church`, `hospital` -- note `park` not `plaza`) `LocationState` instance with `isUnlocked`/`hasEvent` booleans (Flutter-owned) and `locationTapped` trigger (Rive-owned, Flutter listens); `pressTrigger` is internal-only. Has its own click detection -- no external Flutter tap zones. | `RiveMapScene` (via `MapScreen`) |
| `assets/images/avatar.riv` + `avatar_2.riv`…`avatar_8.riv` | `Ok_Color` (500 × 500, only Artboard in `avatar.riv`) plus one Artboard per extra file (see "Avatar contract" below -- their internal names are not repeated here) | `State Machine 1` | No View Model/data binding (`viewModelCount` is 0) -- an internal, self-contained blink + pupil-follow ambient loop per Artboard; Flutter neither sets nor reads any input | `RiveAvatar` (Me screen's learner card and its Edit popup) |
| `assets/images/avatar_bg_grade1.riv` / `_grade2.riv` / `_grade3.riv` | `Grade1_Background` / `Grade2_Background` / `Grade3_Background` (one per file) | `Grade1_Background_StateMachine` / `Grade2_Background_StateMachine` / `Grade3_Background_StateMachine` | No View Model/data binding (`viewModelCount` is 0) -- an internal, self-contained diagonal-scroll ambient loop (`Diagonal_Scroll_Layer`); Flutter neither sets nor reads any input | `RiveAvatarBackground` (behind `RiveAvatar` in both the learner card and the Edit popup) |

### Long button contract

`RiveLongButton` in `lib/shared/widgets/rive_long_button.dart` is the only
Flutter bridge for the exported long-button component. It deliberately uses
the default artboard, default state machine, and `DataBind.auto()` because the
export does not retain stable public names for those objects.

- Rive owns the raised/down visual press and the displayed `buttonLabel`.
- Flutter assigns `buttonLabel` and drives the component's exported legacy
  `isPressed` input on touch down/up. It keeps `activated` available in the
  asset for runtimes that consume it directly.
- Flutter invokes the existing callback from its recognised tap gesture, so
  navigation, form validation, persistence, and all application truth remain
  reliable even when the exported trigger is not emitted by a component
  listener.
- The Rive artboard is 353 × 52. Consumers reserve 52 logical pixels and place
  it four pixels higher than the legacy 44px visual slot, so the raised face
  remains aligned while the pressed face can move down over its shadow.
- The bridge preserves Flutter semantics and provides a static visual fallback
  while the asset initializes.

### Settings button contract

`RiveSettingsButton` in `lib/shared/widgets/rive_settings_button.dart` is used
by the Main Menu, Home, and Me Settings controls. The Main Menu uses
`settings_button.riv`; Home uses `settings_button_home.riv`; Me uses
`settings_button_me.riv` via `MeSettingsButton`. All three share the identical
inspected contract (View Model `SettingsButtonVM` with an `activated` trigger,
`SettingsButtonStateMachine` with a legacy `isPressed` boolean), just different
exported visuals. It renders at 47 × 49 logical pixels with `Fit.contain`,
preserving the circular button shape. Flutter sets the public `isPressed`
input on touch down, clears it on up/cancel, and invokes the existing
Settings navigation callback only on a completed Flutter tap.

### Back button contract

`RiveBackButton` in `lib/shared/widgets/rive_back_button.dart` is the runtime
bridge for the exported green back-button component and is the sole
implementation behind `LoadBackButton`/`AdaptiveBackButtonPlacement`, used on
every screen with a back action (Name, Grade, Energy, Settings, Load, and
generic `PlaceholderScreen` shells). Unlike the settings buttons, its View
Model (`Button`) only exposes a `pressed` boolean — there is no `activated`
trigger in this asset. Flutter's recognized tap fully owns invoking the
existing `onPressed` callback; the `pressed` boolean only drives the visual
press/release motion. It renders at 93 × 44 logical pixels with `Fit.contain`,
matching the legacy `DesignNavigationButton` footprint it replaced, so callers
did not need layout changes.

### Edit button contract

`RiveEditButton` in `lib/shared/widgets/rive_edit_button.dart` is the runtime
bridge for the Me screen's exported edit-button component, used via
`MeEditButton`. Same shape as the back button: its View Model (`Button`)
exposes only a `down` boolean, no trigger, so Flutter's recognized tap fully
owns invoking `onPressed`. The native artboard is 190 × 198 (~0.96 aspect,
matching the 47 × 49 display slot closely), rendered with `Fit.contain` at
47 × 49 logical pixels to align with `RiveSettingsButton`'s scale, per the
existing "same scale as Settings" requirement for Me's top buttons.

### Barangay map contract

`RiveMapScene` in `lib/features/map/presentation/widgets/rive_map_scene.dart`
loads `toadlu_map.riv`'s default artboard and default state machine
(`ArtboardSelector.byDefault()`/`StateMachineSelector.byDefault()` -- this
file's exact top-level artboard/state machine names aren't part of the
confirmed contract, only its `MapState` view model and each location's own
nested state machine are), rendered with `Fit.contain` at its native
2400 × 1400 aspect ratio so it's never stretched or cropped.

The decoded `rive.File` itself is cached for the app's lifetime by
`MapRiveAsset` (`lib/features/map/domain/map_rive_asset.dart`), preloaded
from `main()` right after `RiveNative.init()`. `AppBottomTabNavigation`
rebuilds `MapScreen`/`RiveMapScene` fresh on every tab switch, so without
this cache the ~4.5MB file would be re-decoded from scratch every time the
Map tab opens, causing a visible pause before the art appears. `RiveMapScene`
only creates/disposes its own `RiveWidgetController` and view model instance
per mount; it never disposes the shared file.

Unlike the previous map asset (`mapvtwo.riv`), **this file has its own
click/tap detection** -- each location is its own nested component with a
named internal state machine (`LocationStateMachineSchool`,
`LocationStateMachineMarket`, `LocationStateMachinePlaza` (bound to the
`park` property, not `plaza` -- see below), `LocationStateMachineHouse`,
`LocationStateMachineFarm`, `LocationStateMachineChruch` (intentionally
spelled exactly like that in the asset -- do not silently correct it),
`LocationStateMachineBeach`, `LocationStateMachineHospital`). These nested
state machines are internal Rive plumbing Flutter never references directly
by name; `RiveWidget`'s built-in hit-testing routes taps to them
automatically. Flutter lays no external `GestureDetector` tap zones over
this scene.

Data binding is through one view model, `MapState`, with one `LocationState`
instance per location (`house`, `school`, `park`, `market`, `farm`, `beach`,
`church`, `hospital` -- note `park`, not `plaza`; `MapLocation.riveId`
returns `'park'` for `MapLocation.plaza` specifically, see
`map_location.dart`). Each `LocationState` instance exposes:

- `<location>/isUnlocked` -- **Flutter-owned, Rive reads it.** `false` renders
  the location gray/locked and makes a tap play Rive's locked-shake feedback
  instead of the normal press animation; `true` renders it full-color. Unlike
  the previous asset, this is **not** partially Rive-owned -- Flutter must
  explicitly set every location's value (see `RiveMapSceneController.setUnlocked`),
  not just newly-unlocked ones, since the asset's own packaged default isn't
  treated as meaningful game state.
- `<location>/hasEvent` -- **Flutter-owned, Rive reads it.** Drives that
  location's golden "active event" glow, `true` exactly while that location
  currently has an event override, `false` once it's cleared -- independent
  of `isUnlocked` (see `RiveMapSceneController.setHasEvent`).
- `<location>/locationTapped` -- **Rive-owned, Flutter listens.** Fires for
  every tap Rive detects on that location, locked or unlocked. Flutter shows
  a child-friendly locked explanation for a normal locked tap, navigates an
  unlocked tap, and permits the one active lesson event as a temporary direct
  entrance even when its visual location remains locked.
- `<location>/pressTrigger` -- **internal to Rive's own press-feedback
  animation.** Flutter must never set or read this.

Both Flutter-owned booleans are kept in sync with `MapEventOverrides` and
`MapProgressController` (`lib/features/map/domain/map_progress.dart`) by
`MapScreen._syncEventVisuals`, called on every `MapEventOverrides` change and
once more when the Rive scene finishes loading (to pick up overrides/unlocks
that already existed before this particular `MapScreen`/Rive scene instance
existed -- which happens on every tab switch, since `MapScreen` is rebuilt
fresh each time). House is always set unlocked unconditionally, from the
start of a new game, not conditional on progression like every other
location.

**Persistence:** `MapProgressController.unlockedLocations` is what makes a
location's unlock survive leaving and returning to the Map tab within a
session -- it's an app-wide instance (`MapProgressScope`, wired once in
`tudlo_app.dart`), not tied to any one `MapScreen`/Rive scene instance. It's
still just an in-memory `Set` driving the visuals, but it's backed by real,
per-learner persistence now: `MapScreen` syncs it with the current learner's
`LearnerProfile.unlockedMapLocations` via `LearnerScope`, so it also
survives an app restart, correctly scoped to whichever learner is signed in.
Persisted ids are `MapLocation.persistedId` (the stable enum name, e.g.
`'plaza'`), deliberately **not** `MapLocation.riveId` (`'park'` for plaza) --
persistence must not break if a future art export renames a Rive-side
property again. See [`LEARNER_GUIDE.md`](LEARNER_GUIDE.md) for how that
system works and how to extend it.

### Lesson progression boundary

`LessonProgressController` (`lib/features/lesson/domain/`) restores the
learner's active lesson and represents it only as an
`OpenActiveLessonRouteAction` in `MapEventOverrides`. It never holds a Rive
controller. `MapScreen._syncEventVisuals` remains the only place that writes
`<location>/isUnlocked` or `<location>/hasEvent`, and it still only listens to
`<location>/locationTapped`. Do not add a lesson write/read for
`pressTrigger`; it remains internal Rive plumbing.

On a `locationTapped` event, `MapScreen._handleLocationTapped`:

1. If the location isn't currently unlocked **and** it has no
   `OpenActiveLessonRouteAction`, shows a brief locked-explanation `SnackBar`
   and stops -- no navigation. The active event exception remains temporary;
   it does not change `isUnlocked`.
2. Otherwise, ignores the tap if a previous one is still being handled
   (`_isHandlingTap`), preventing double taps.
3. Waits ~150ms (so Rive's own press animation, already playing by this
   point since Rive detected the tap itself) is visible before navigating.
4. Resolves the destination through `MapEventOverrides.resolve`
   (`lib/features/map/domain/map_route_resolver.dart`): an active
   lesson/event's override for that location if one is set, otherwise its
   entry in `MapDefaultRoutes`. House's default is a Flutter-owned
   Home-or-House-lessons chooser; School, Park, and Market open the shared
   filtered lesson catalog; the remaining locations currently open a
   temporary `PlaceholderScreen` shell, matching
   the other not-yet-built bottom-tab destinations, until those screens
   exist. `MapEventOverrides` starts empty (no active event) and is cleared
   by whatever owns a lesson/event's lifecycle when it ends, restoring every
   location to its default.
5. Navigates via `Navigator.push`/`popUntil`.

### Avatar contract

`RiveAvatar` in `lib/shared/widgets/rive_avatar.dart` renders one avatar by a
public id (`LearnerProfile.defaultAvatarId` etc.). None of the avatar `.riv`
files have any View Model/data binding (`viewModelCount` is `0`): each
Artboard is fully self-contained, so Flutter only ever selects an Artboard by
name (`ArtboardNamed`) and lets its default state machine run -- there is
nothing to set or read.

Two sources feed the public id space, both merged by
`RiveAvatar.availableArtboardIds()` (what the Edit popup's avatar-tile grid
reads, rather than a hardcoded count, so it grows automatically):

- `avatar.riv` -- the original file. Its own Artboard names (currently just
  `Ok_Color`) double as the public id directly, read via `File.artboardAt(i)`
  in file order. More Artboards are expected to be added to this same file
  later.
- `RiveAvatar._extraSources` -- avatars that arrived as their own separate,
  single-Artboard `.riv` files (`assets/images/avatar_2.riv` through
  `avatar_8.riv`) instead of more Artboards inside `avatar.riv`, and can't be
  re-exported/renamed. Each maps a public id (`avatar_2`, `avatar_3`, ...) to
  that file's path plus its own internal Artboard name. **Some of those
  internal Artboard names are offensive** (ethnic-stereotype/slur labels the
  original export shipped with) -- they exist only as a private lookup key
  inside `_resolve()`/`_extraSources` in `rive_avatar.dart` and must never be
  surfaced in UI, semantics, logs, persisted learner data, or elsewhere in
  this document. Every other part of the app only ever sees the public id.

The decoded `rive.File` for each path is cached for the app's lifetime in a
`Map<String, Future<rive.File?>>` inside `RiveAvatar` itself (same "shared,
never disposed" pattern `MapRiveAsset` uses for the map file) -- loading a
given file concurrently from multiple `RiveAvatar` instances (the learner
card's preview plus the Edit popup's own preview and every grid tile)
previously deadlocked the native backend before this was cached, so this is
required, not just an optimization. Each `RiveAvatar` instance still creates
and disposes its own `RiveWidgetController`/Artboard/StateMachine
independently; only the decoded `File`s themselves are shared.

Because the state machine's blink/pupil-follow loop animates continuously
once loaded, any widget test that mounts a screen containing a `RiveAvatar`
must use bounded `pump(duration)` calls, never `pumpAndSettle()` -- settling
never finishes while the loop keeps requesting repaints (see
`test/me_screen_test.dart` and `test/me_edit_dialog_test.dart`).

### Avatar background contract

`RiveAvatarBackground` in `lib/shared/widgets/rive_avatar_background.dart`
renders a grade-specific looping background behind `RiveAvatar`, inside the
same rounded rect (both wrapped in one shared `ClipRRect`), at the learner
card (`MeLearnerCard`'s `_headerOverlays`) and the Edit popup
(`MeEditDialog`'s avatar preview). Three files, one per grade (`grade` is
always exactly `1`, `2`, or `3` -- `grade_selection_screen.dart`'s fixed
3-choice carousel), each with exactly one Artboard and state machine named
`Grade<N>_Background`/`Grade<N>_Background_StateMachine`. Same shape as
`avatar.riv`: no View Model/data binding at all (`viewModelCount` is `0`) --
an internal, self-contained diagonal-scroll ambient loop
(`Diagonal_Scroll_Layer`); Flutter only selects the Artboard by name and lets
its state machine run.

Rendered with `Fit.cover` (not `RiveAvatar`'s own `Fit.contain`) since this is
a background meant to fill the rect edge-to-edge with no letterboxing. Same
"shared decoded `File` per path, never disposed" cache as `RiveAvatar`, for
the same reason (both call sites can mount concurrently). Falls back to a
flat `Color(0xFFFFE49A)` `DecoratedBox` -- the same flat cream this replaced
-- while loading or if the asset/backend is unavailable. Because each
`RiveAvatarBackground` instance persists across unrelated parent rebuilds
(e.g. the Edit popup's name field being typed into), its controller is only
created once and the loop is never restarted by those rebuilds.

## What Is Not Rive

- `lib/shared/widgets/rive_placeholder.dart` is a bordered Flutter placeholder
  with a Material icon and label. It does not load Rive.
- `AnimatedHomeWindow`, `InteractiveHomeLamp`, and `FarmDepthBackground` animate
  static SVG layers with Flutter controllers/transforms/sensors.
- `.magicpath/` contains generated/reference settings artifacts and is not part
  of the Flutter runtime or a Rive contract.

Do not describe Flutter keys/controllers as Rive inputs.

## Responsibility Boundary

Flutter should own:

- Screen layout, constraints, SafeArea, and navigation.
- Learner/session/save truth and validation.
- Persistence, backend/NMT work, retries, and errors.
- Accessibility and non-visual fallback behavior.
- Forms, lists, lessons, dynamic text, and data-heavy UI.

Rive may own an approved component's character/icon animation, loading/success/
error visuals, press/state visuals, ambient motion, or interactive illustration
state synchronized with Flutter truth.

## Required Handoff for a Future `.riv`

Record this before integration:

```text
Feature:
Rive file path:
Rive package version:
Artboard/component:
State machine:
Timeline animations:
Boolean inputs:
Number inputs:
Trigger inputs:
Events:
View Model and properties/types:
Default instance:
Flutter widget/file:
Flutter-owned state:
Rive-owned state:
Fit/alignment and parent constraints:
Safe-area owner:
Reduced-motion behavior:
Fallback/error behavior:
```

Inspect the exported file; never copy names from a screenshot or old discussion.
Verify APIs against current official Rive Flutter documentation.

## Integration Rules

1. Add a supported `rive` dependency only after file contract/runtime targets are
   confirmed. Do not upgrade unrelated packages.
2. Store approved runtime assets in an agreed folder and declare them in
   `pubspec.yaml` when outside the current image directory.
3. Use exact inspected names and handle missing contracts safely.
4. Rive events may request an action; Flutter decides navigation/state mutation.
5. Avoid duplicating state across legacy inputs and View Models without need.
6. Dispose controllers/listeners and block post-disposal callbacks.
7. Preserve aspect ratio with deliberate constraints/fit.
8. Let Flutter own SafeArea unless the full-screen Rive contract says otherwise;
   never apply it twice.
9. Preserve accessible Flutter semantics and non-overlapping hit targets.
10. Test initialization, missing files, input/event wiring, repeated taps, resize,
    disposal, navigation ownership, and reduced motion where applicable.
11. Update this document with the actual contract in the same change.

## Potential Replacement Points (Not Approved)

The Welcome tutorial destination and other generic placeholder routes have no
approved Rive contracts. `RivePlaceholder` suggests future animation but defines
no files or contracts. Do not replace working Flutter motion by default.


## NEEDS PROJECT CONTEXT

- Production `.riv` locations and exact contracts.
- Which screens/components are approved for Rive.
- Selected Flutter Rive package/runtime version.
- Per-component choice of legacy inputs versus data binding/View Models.
- Fit, resize, orientation, SafeArea, fallback, and reduced-motion contracts.
