# Tudlo Architecture

## Style

Tudlo uses a small feature-oriented Flutter architecture. Features own their
presentation widgets/private helpers. Load also has a minimal domain model.
Shared controls and infrastructure live in `shared/` and `core/`.

There is no DI container, Provider/BLoC/Riverpod, or router. There is now
exactly one repository -- `LearnerRepository`
(`lib/features/learner/domain/learner_repository.dart`), a thin
`shared_preferences` wrapper for the learner save system (see
`docs/LEARNER_GUIDE.md`). Don't describe a broader repository/backend layer
as present; this is the one, narrow exception.

## Composition Root

```text
main()
└── Flutter initialization + portrait orientation
└── TudloApp
    └── AppAnimationScope (app-wide motion on/off)
        └── LearnerScope (current learner profile -- see LEARNER_GUIDE.md)
            └── AppSettingsScope (device settings outside a learner profile)
                └── TudloAudioScope (one app-owned audio controller)
                    └── MapProgressScope (map event overrides + unlocked locations)
                        └── LessonProgressScope (learner-owned lesson state + event scheduling)
                            └── MaterialApp (Material 3, ComicRelief, green/mint theme)
                                └── StartupFlow
```

App-wide state that needs to be reachable from anywhere without
prop-drilling follows one consistent pattern -- a `ChangeNotifier` (or
`InheritedNotifier`-compatible controller) plus an `InheritedWidget`/
`InheritedNotifier` "Scope" with a static `.of(context)`. The current
examples (`AppAnimationScope`, `LearnerScope`, `AppSettingsScope`,
`TudloAudioScope`, `MapProgressScope`, and `LessonProgressScope`) are
wired once in `TudloApp` and follow this exact shape; add a new one the
same way rather than introducing a different state-management approach.

## State and Feature Communication

- `StartupFlow`: local integer stage and async warm-up callbacks.
- `NameScreen`: text/focus controllers and voice-over busy flag.
- `GradeSelectionScreen`: carousel selection/order and voice-over state.
- `EnergySetterScreen`: energy value and voice-over state.
- Loading screens: one-shot async preparation state.
- `LearnerCardScreen`: immutable learner inputs; nested animation/tilt state;
  `_finish()` is also where a `LearnerProfile` gets created and saved (see
  `docs/LEARNER_GUIDE.md`).
- `LoadScreen`: constant demo saves and local current page (this is the
  save *browser* UI shell -- unrelated to the real learner save system;
  its saves are still just demo data, see `docs/CURRENT_STATUS.md`).
- `TudloAudioController`: app-lifetime owner of the SoLoud engine, cached
  one-shot assets, the single background-music handle, audio channel volume
  rules, native button-click gating, supplied feature-effect playback,
  voice-over completion/cancellation, duration fallback when a native
  completion event is missed, music duck-and-restore behavior, and shutdown.
  Screens send audio intents through `TudloAudioScope`; they never store native
  sources or handles.
- `LessonProgressController`: derives one active lesson event from saved
  learner progression, creates semantic map overrides, and records a result
  only after reward claim. It never writes Rive values.
- Welcome/Home widgets: local interaction and animation controllers.
- `HomeScreen`/`MeScreen`: explicit constructor overrides (mainly for
  tests), falling back to the current learner via `LearnerScope` otherwise.

Onboarding data is passed through constructors:

```text
learnerName: String
grade: int (1, 2, or 3)
energy: int (10–100 in 10-point increments)
```

It now also reaches `LearnerScope`/`LearnerRepository` at the end of
onboarding (`LearnerCardScreen._finish()`), so the current learner (name,
grade, energy, and progression data added since) persists across app
restarts -- see `docs/LEARNER_GUIDE.md` for the full system. The Load
screen's own save list is unrelated and still just demo data.

## Home Structure

```text
Scaffold
└── Column
    ├── Expanded
    │   └── Stack
    │       ├── SingleChildScrollView
    │       │   └── centered scene (max width 720)
    │       │       ├── temporary content/wall
    │       │       ├── InteractiveHomeLamp
    │       │       └── AnimatedHomeWindow
    │       ├── HomeSettingsButton (stationary)
    │       └── HomeEnergyIndicator (stationary)
    └── HomeBottomNavigation (stationary)
```

`HomeBottomNavigation` exposes `ValueChanged<int>? onItemTapped` and an
overridable `backgroundColor` (defaults to the established brown; the Me
screen supplies its own darker tone). `AppBottomTabNavigation`
(`lib/core/navigation/`) is the single source of truth for all six tabs: it
owns the push-away-from-Home / replace-between-siblings / pop-to-Home
decision and each tab's destination widget, so every screen that shows the
bar (`HomeScreen`, `MapScreen`, the Lessons/Translate/Dictionary shells,
`MeScreen`) supplies only its own `currentIndex` instead of re-deriving
router. Translate and Dictionary are `PlaceholderScreen` shells pending real
content; Lessons is the grade-aware lesson catalog and Map is a real
interactive screen (`docs/MAP_GUIDE.md`);
Me is a real (incomplete) screen showing real learner data where loaded.
Sibling tabs replace each other to avoid stacking routes; any tab's Home
action pops to the root Home route.

## Loading Boundaries

- `SecondLoadingScreen` precaches learner-card images, shows a retry action if
  that critical preparation fails, and replaces itself.
- `HomeLoadingScreen` is the Loading 3 engine: minimum display, animated labels,
  onboarding asset eviction, destination-specific preload, timeout/retry, and
  replacement.
- `FourthLoadingScreen` configures that engine with red art, Home preloading,
  and `HomeScreen` as destination.

Loading 3 is reached with `pushAndRemoveUntil(..., false)`. Loading 4 replaces
Main Menu. Both later replace themselves; destination widgets are built after
preparation.

## Navigation Map

```text
StartupFlow
└── MainMenuScreen
    ├── Settings → Settings screen (animation preference)
    ├── Load → LoadScreen
    ├── Start New Koka → Name → Grade → Energy → Loading 2
    │                   → Learner Card → Loading 3 → Welcome
    │                                              ├── Next → tutorial placeholder
    │                                              └── Skip → Home
    └── Continue → Loading 4 → Home

Home
├── Settings → Settings screen (animation preference)
├── Map tab and door → MapScreen (real interactive Rive barangay map --
│   see docs/MAP_GUIDE.md; tap-gated by availability, active events open an
│   exact lesson and mapped defaults open a filtered catalog)
├── Lessons tab and bookshelf → source-faithful grade-aware catalogue →
│   original DevG intro → original DevG activity host
├── Translate/Dictionary tabs → temporary shells
└── Me tab → Me screen (Settings/Edit buttons; shows the real current
    learner via LearnerScope where loaded, see docs/LEARNER_GUIDE.md --
    badge collection UI itself is still a shell)
```

Page navigation uses `FadePageRoute`; dialogs and Startup switching use their
own fades.

## Rendering and Motion

- Rive owns only approved component/character visuals: Main Menu/Home Settings,
  long-button press/display state, and Koka State Machine reactions. Flutter
  owns gestures, navigation, speech copy, accessibility, and application state.

- PNGs use `Image.asset`, usually `BoxFit.contain`.
- SVGs use `SvgPicture.asset`; layered scenes can request raster rendering via
  `vector_graphics`.
- Other motion uses Flutter controllers, transforms, implicit animation,
  sensors, and custom painters.
- Animated components should honor `MediaQuery.disableAnimations`.

## Widget Composition and Rebuild Boundaries

- Split a screen into focused `StatelessWidget` or `StatefulWidget` classes
  when a region has independent state, a distinct lifecycle, an animation, a
  reusable layout contract, or a stable visual responsibility. Keep the
  `StatefulWidget` boundary as close as practical to the state it owns.
- Use helper methods only for small, local structural fragments that depend on
  the same state and are not useful as a separate boundary. A helper method is
  not a rebuild boundary; extracting one mechanically does not improve runtime
  work on its own.
- Use `const` constructors and `const` child widgets whenever their inputs are
  compile-time constants. This lets Flutter reuse the identical widget
  configuration during an ancestor rebuild. Do not remove a needed runtime
  input merely to make a widget `const`.
- Keep fast-changing state local. For example, touch feedback belongs in the
  control that renders it, and ambient animation should rebuild only through a
  narrow `AnimatedBuilder`/`ListenableBuilder` subtree. Supply an invariant
  `child` to those builders when possible.
- A separate widget class improves organization and can create a useful state
  boundary, but it does not automatically prevent its `build` method from
  running when an ancestor supplies a new configuration. Measure before making
  a performance-driven refactor; preserve stable keys, semantics, callbacks,
  and responsive constraints.
- Use `RepaintBoundary` around independently animated or expensive artwork
  only when it limits repaint work without breaking compositing or memory
  behavior. It is a paint optimization, not a substitute for correct rebuild
  boundaries.
- Keep Tudlo-authored source files in the Home, Lesson, and Map features at
  500 lines or fewer, excluding intentionally machine-readable data assets.
  Split by lifecycle/route ownership, persistent domain logic, visual
  composition, or reusable card/control—not arbitrary line ranges. The
  imported `lesson/presentation/devg_canonical/` source-preservation bridge is
  a visible temporary exception while its 12 canonical flows are extracted
  without changing their child-facing behaviour; it must not be extended with
  new Tudlo architecture. Concise comments should explain contracts,
  non-obvious ownership, and why a safeguard exists rather than narrating
  obvious widget syntax.

## Testing

Tests import public API through `lib/tudlo.dart` or focused widgets directly.
Configurable durations/callbacks avoid real audio and long waits. The audio
controller additionally accepts a small fakeable backend, so its loading,
volume, mute/restart, and stop/start ordering rules have no native-plugin test
dependency. Stable keys and semantics support interaction and geometry assertions.

Coverage emphasizes route boundaries, loading/preparation, form logic, fixed vs
scrolling Home content, portrait overflow, Figma placement, animation timing,
and reduced motion.

## Extension Rules

- Add `domain/`, `data/`, or `application/` only when real behavior requires it.
- Define persistence/backend interfaces before extracting demo widget state.
- Keep route ownership in Flutter even when Rive supplies visuals.
- Preserve or replace callback test seams with equally testable abstractions.
- Export new public test-facing types from `lib/tudlo.dart` when appropriate.
- New app-wide state follows the `Controller` + `Scope` pattern (see
  Composition Root above) -- don't introduce Provider/Riverpod/BLoC to solve
  a problem this pattern already covers.
- New persisted learner data extends `LearnerController`
  (`docs/LEARNER_GUIDE.md`) rather than adding a second storage mechanism.

## NEEDS PROJECT CONTEXT

- Backend/NMT interface and error/offline policy.
- Final route/deep-link/back-stack requirements.
- Multi-learner-profile switching UI (storage already supports multiple
  profiles by id; there's no screen for creating/switching between them).
- Load screen's save browser reconciling with the real learner save system
  (it's still independent demo data -- see `docs/LEARNER_GUIDE.md`).
- Whether/when cloud sync is wanted (current persistence is local-only,
  on-device, single learner at a time).
