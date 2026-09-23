# Tudlo Codex Working Guide

This is the primary instruction manual for coding agents working in this
repository. Read it before editing the application, then consult `docs/`.

## Product

Tudlo is a Flutter learning application for Grade 1–3 children. This repository
is currently a UI prototype covering startup, learner onboarding, save-slot
presentation, a welcome scene, and an incrementally built Home screen.

Preserve its playful illustration-led identity, simple interactions, generous
touch areas, and Comic Relief typeface. Do not infer curriculum, backend,
persistence, or production Rive contracts that are absent from the code.

## Start Here

- `docs/PROJECT_OVERVIEW.md` — screens, flows, dependencies, major systems.
- `docs/ARCHITECTURE.md` — organization, communication, navigation, and state.
- `docs/RIVE_INTEGRATION.md` — confirmed Rive status and integration rules.
- `docs/UI_AND_RESPONSIVE_RULES.md` — layout, artwork, and sizing rules.
- `docs/CURRENT_STATUS.md` — completed, partial, placeholder, and unknown work.

## Architecture

```text
lib/
├── app/        # MaterialApp and app-wide setup
├── core/       # Cross-feature navigation and theme primitives
├── features/   # Product features grouped by domain
├── shared/     # Widgets genuinely reused across features
├── main.dart   # Process entry point
└── tudlo.dart  # Public exports used by tests/consumers
```

Feature folders currently contain `presentation/` code and, where needed,
`domain/` models. Keep feature-only code inside its feature. Move code to
`shared/` only after multiple features use it and to `core/` only for app-wide
infrastructure.

There is no dependency-injection framework, router package, state-management
package, persistence layer, network service, or backend client. State is local
to `StatefulWidget`, passed through constructors, or injected as test callbacks.

## Important Files

- `lib/main.dart`: Flutter initialization and portrait orientation request.
- `lib/app/tudlo_app.dart`: Material 3, font/theme, and `StartupFlow`.
- `lib/features/startup/presentation/startup_flow.dart`: timed splashes/preload.
- `lib/features/main_menu/presentation/main_menu_screen.dart`: entry routes.
- `lib/features/onboarding/`: name, grade, energy, Loading 2, learner card.
- `lib/features/home/`: Loading 3/4 and incremental Home.
- `lib/features/load/`: demo save grid and confirmation dialogs.
- `lib/features/welcome/`: responsive welcome scene and depth motion.
- `lib/core/navigation/fade_page_route.dart`: shared 350 ms fade route.
- `lib/core/theme/app_colors.dart`: shared palette.
- `assets/images/`: raster/vector art; `assets/fonts/`: Comic Relief.
- `test/`: widget, responsive, navigation, and animation regressions.

## Naming and Coding Conventions

- Follow Dart style: `snake_case` files, `UpperCamelCase` types, and
  `lowerCamelCase` members.
- Prefer immutable widgets and `const` constructors; the linter enables
  `prefer_const_constructors`.
- Use `package:tudlo/...` imports for application code.
- Preserve stable widget keys and semantics. Tests depend on keys including
  `home-screen`, `home-content-scroll-view`, and `home-bottom-navigation`.
- Dispose animation/text controllers, focus nodes, subscriptions, and resources.
- Respect `MediaQuery.disableAnimations` for ambient/decorative motion.
- Preserve the existing lowercase copy and Hiligaynon/Filipino text unless the
  user explicitly approves copy changes.

## Navigation and State

- Navigation uses Flutter `Navigator` plus `FadePageRoute`; no named routes.
- Use `push` when Back should return to the current screen.
- Use `pushReplacement` for a loading screen replacing itself/destination.
- Use `pushAndRemoveUntil` only for an intentional hard lifecycle boundary.
- Do not construct an expensive destination before its loader finishes. Precache
  during loading, then construct and navigate.
- Preserve constructor-carried `learnerName`, `grade`, and `energy` until an
  approved persistent/application-state architecture replaces them.
- Preserve test seams such as voice-over/preparation callbacks and builders.
- Current save records and SnackBar actions are demo-only, not persistence.

## Responsive Rules

- The established design baseline is 412×917 portrait. It is a measurement
  reference, not permission to stretch artwork.
- Preserve aspect ratios for characters, icons, logos, windows, lamps, buttons,
  and illustration layers using `BoxFit.contain`, `AspectRatio`, and bounds.
- Background fields and intentionally flexible panels may fill/stretch.
- Respect SafeArea exactly once; do not duplicate inset padding.
- Onboarding/load screens scale a 412×917 composition with `FittedBox`; Home and
  Welcome use `LayoutBuilder` with bounded calculations. Preserve the current
  screen's established strategy unless an explicitly requested, tested change
  replaces it.
- Home content scrolls while bottom navigation, energy, and Settings remain
  stationary. Lamp and window belong to the scrolling scene.
- Keep Home content centered and capped at 720 logical pixels on wide layouts.
- Never stretch icons independently on X/Y. Home navigation deliberately uses
  per-icon visual dimensions for optical balance.
- All six Home navigation labels share one computed font size; `dictionary` is
  the limiting label. Do not create inconsistent label sizes to fix overflow.
- Test at 320×480, 360×640, 412×917, and 800×1200 plus reduced motion. The
  product goal mentions orientation safety, but code/platforms are portrait-only.

## Asset Rules

- `pubspec.yaml` declares all of `assets/images/` and Comic Relief fonts.
- Reuse intended assets before substituting Material icons or redrawing art.
- Keep SVG layers separate when Flutter animates them independently.
- Do not delete unreferenced/versioned assets; archival ownership is unknown.
- Preserve referenced filenames. Update all consumers and preload lists together
  if a rename is explicitly approved.
- Add new visual assets under `assets/images/` unless a new structure is agreed.
  Fully restart Flutter after adding assets; hot reload is insufficient.
- Fix parent constraints/fit instead of distorting supplied artwork.

## Rive Rules

There is currently no `rive` dependency and no `.riv` file. `RivePlaceholder`
is Flutter UI, not runtime integration. Flutter-animated SVGs are also not Rive.

Before adding Rive:

1. Inspect the exported file and record file path, artboard, animation/state
   machine, inputs, events, and View Model/data-binding contract. Never guess.
2. Verify the current official Rive Flutter documentation and package API.
3. Keep Flutter responsible for navigation, persistence, backend truth,
   accessibility, and data-heavy layout. Rive owns only agreed visual state.
4. Use responsive Flutter constraints that preserve the art/component ratio.
5. Test initialization, missing assets, resize, repeated interaction, disposal,
   and reduced-motion behavior where relevant.
6. Update `docs/RIVE_INTEGRATION.md` with the actual contract.

Do not replace a working Flutter interaction with Rive without approval.

## Reusable Components

- Reuse `FadePageRoute` for established page transitions.
- Reuse `AdaptiveBackButtonPlacement`/`DesignNavigationButton` for current back
  and pagination controls.
- Reuse `OnboardingBottomActions` for its established primary/secondary geometry.
- Keep Home navigation, energy, Settings, lamp, and window independently testable.
- Do not promote a private widget to shared code without a second real consumer.
- Prefer data-driven collections for navigation, grades, badges, and saves.

## Run and Test

```shell
flutter pub get
dart run rive_native:setup --platform <linux|macos|windows>
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

`rive_native:setup` downloads the host's native Rive library. Skip it and
every widget test that mounts a Rive scene fails with
`Failed to load dynamic library 'librive_native_plugin.so'` -- over a
hundred tests across Home, Settings, Me, Map and the lesson host. It is a
one-time step per machine, not per checkout.

On a distro without Perl's `shasum` (Fedora, for example), that setup step
dies in its checksum check with `ProcessException: No such file or
directory: shasum`. Put a shim early on `PATH` that forwards to coreutils:

```shell
printf '#!/bin/sh\nexec "sha${2}sum" "$3"\n' > /usr/local/bin/shasum
chmod +x /usr/local/bin/shasum
```

Focused Home checks:

```shell
flutter test test/home_screen_shell_test.dart
flutter test test/animated_home_window_test.dart
```

## Workflow

1. Inspect relevant code, tests, assets, and docs before editing.
2. State the files/behavior that will change.
3. Work on one requested feature/problem and preserve completed work.
4. Make the smallest maintainable change; avoid opportunistic rewrites.
5. Add/update tests proportionally and run focused checks.
6. Verify established responsive sizes and overflow behavior.
7. Update documentation when contracts, routes, assets, or status change.
8. Report changed files, checks, limitations, and manual verification steps.

For incremental work, implement one approved step, explain what to inspect, and
stop. Fix that step before advancing.

## Do Not Change Without Asking

- Established visuals, copy, measurements, palette, or 412×917 baseline.
- Portrait-only platform policy.
- Loading durations, preload/release boundaries, retry, or stack semantics.
- Existing route destinations, learner/energy/save/lesson behavior.
- Asset names/layers, animation timing, or per-icon navigation sizing.
- Package versions, app IDs, signing, SDK constraints, exports, or test keys.
- `.magicpath/` artifacts or unused/versioned assets.

Do not refactor for style, add a framework, or assume backend/storage behavior
without an approved architecture.

## Known Limitations

- Settings and Welcome tutorial destinations are placeholders.
- Home is incomplete: shell, navigation/controls, wall, lamp, and window exist;
  lesson/room content does not.
- Home tabs are tappable but lack destinations in `HomeScreen`.
- Continue uses temporary learner defaults and restores no save.
- Save/load/delete are in-memory demo behavior.
- Voice-over callbacks exist but aren't wired to real audio. `flutter_soloud`
  is installed and used for the Maral splash's logo sting and app-wide
  looping background music (`lib/features/startup/presentation/startup_flow.dart`).
- No lessons, backend/NMT, auth, persistence, or durable app state exists.
- No real Rive runtime integration exists.
- Platforms are portrait-only; landscape is unverified.
- Android uses a prototype application ID and debug release signing.
- This managed copy has no local `.git`; use a real clone for independent Codex.

## NEEDS PROJECT CONTEXT

Ask the user rather than inventing:

- Production `.riv` locations and exact runtime contracts.
- Final Settings, tutorial, Translate, Lessons, Map, Dictionary, and Me routes.
- Learner/save persistence schema and which Continue save to restore.
- Backend/NMT/API/auth/offline contracts.
- Lesson model, curriculum, progression, and energy rules.
- Audio assets/scripts/playback/accessibility policy.
- Whether portrait-only remains final or landscape must be added.
- Canonical Figma source and approval to archive old asset versions.

