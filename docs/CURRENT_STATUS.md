# Current Implementation Status

This status is based only on current code and tests.

## Completed in the Prototype

### Shell and Startup

- `TudloApp` theme, Comic Relief, Material 3, and portrait request.
- Maral/Tudlo timed splashes, immediate-destination asset warm-up, fade
  switching, and retry for critical preparation failures.

### Main Menu

- Reference composition with accessible hit targets.
- Rive long-button controls and Rive Settings button, with Flutter retaining
  gesture recognition and navigation ownership.
- Start New Koka, Continue, Load, and Settings taps.
- Continue uses Loading 4 as a hard navigation boundary.

### New Learner

- Required trimmed name.
- Animated three-grade wraparound carousel and active-card continuation.
- Energy in 10% steps, bounded 10–100%.
- Voice-over callback seams and busy protection; the bundled Load-screen,
  load-confirmation, and delete-confirmation voice-overs play only while
  their owning route/dialog is visible and temporarily duck the non-muted
  background music through the shared audio controller.
- Shared app buttons use the supplied button-press sound. Sound Effects can
  enable/disable it (and a zero Master or Sound Effects value mutes it); the
  Sound Effects slider controls its loudness.
- The main-menu Continue button and the Yes button in a load confirmation
  use the supplied map-unlock cue instead.
- The Me edit avatar tiles and map location taps use their supplied custom
  effects instead: one tile cue plus distinct locked and unlocked map cues.
- Tapping the Home ceiling lamp plays its supplied light-switch cue.
- Tapping the Home door plays its supplied door cue before opening the Map.
- Loading 2 minimum duration/learner-card preload.
- Learner card with learner data, progress/counters, badges, touch tilt,
  rays/holofoil motion, reset confirmation, and reduced motion.

### Loading 3 and Welcome

- Loading 3 animated lowercase labels and Koka artwork.
- Five-second minimum, 30-second timeout, retry, asset eviction/preload, and
  replacement navigation.
- Responsive normal/wide Welcome SVG scene, touch depth, ambient sky, and
  reduced-motion support.
- Welcome Skip route to Home.

### Loading 4

- Main Menu Continue removes Main Menu and opens Loading 4.
- Red Koka SVG using Loading 3's animated label/lifecycle engine.
- Home SVG/PNG precache; Home constructed after preparation.
- Loading 4 replaces itself with Home.

### Load UI

- Grade-aware `SavePreview` model.
- Seven demo saves, four per page, two-column cards, pagination.
- Load/delete confirmation dialogs and SnackBar feedback.

### Barangay Map

- Real interactive Rive map (`toadlu_map.riv`), pan/zoom framed on Koka's
  house by default, fullscreen landscape toggle.
- Rive-side tap detection (this asset has its own internal Listener
  components per location, unlike the previous map asset); Flutter reacts to
  `locationTapped`. A normal locked tap shows an explanation instead of
  navigating; the one active lesson event is a temporary direct entrance;
  unlocked locations resolve their normal destination.
- Active-event system: an event can temporarily override a location's
  destination (`MapEventOverrides`) and marks it `hasEvent` (golden glow
  visual) for the override's duration. A claimed lesson completion—not an
  event—permanently earns its location's `isUnlocked` state.
- Full details, including how to trigger an event and add a real screen for
  a location: `docs/MAP_GUIDE.md`. Rive asset contract: `docs/RIVE_INTEGRATION.md`.

### Learner Save System

- `LearnerProfile`/`LearnerController`/`LearnerScope`
  (`lib/features/learner/`) persist the current learner (name, grade,
  energy, lessons/stickers/badges/streak counts, unlocked map locations) to
  on-device storage (`shared_preferences`), keyed by a generated learner id.
- Created at the real end of onboarding (`LearnerCardScreen._finish()`);
  restored on app startup (`TudloApp`); `HomeScreen`/`MeScreen` read from it
  automatically when no explicit override is supplied.
- Local-only, single active learner at a time; no cloud sync, no
  profile-switcher UI yet (storage already supports multiple profiles by
  id). Full details: `docs/LEARNER_GUIDE.md`.

### Lessons

- Twelve authorized DevG lesson definitions and the grade-guided sequence are
  available through the Lessons tab, Home cards, and mapped Map locations.
- `LessonProgressController` restores a legacy learner's first event, keeps
  exactly one active map event, persists claimed completions/results, unlocks
  the completed lesson's location only after reward claim, and prevents
  replayed stickers/lesson counts.
- Grade 1 Unit 1 Lessons 1 and 7 show their matching Home sticker as a
  floating tap-to-claim reward, followed by a full-screen result with gallery
  and next-lesson popup actions.
- The source Hiligaynon dataset is imported through an audited manifest.
  The complete canonical DevG production lesson visual, reward, sound-effect,
  and final voice-over asset set is staged under `assets/` (see
  `assets/data/lesson_asset_manifest.md`). The preserved DevG card page,
  intro, and activity flows now run behind Tudlo-owned progress/navigation/
  audio adapters. The raw source-preservation bridge still needs its planned
  sub-500-line extraction and complete interactive verification; do not call
  this final modular parity yet.

### Home Increment

- Scrollable centered scene, max width 720.
- Stationary navigation and top controls.
- Six navigation items with optical icon sizes/shared label size; Home selected.
- Wall `#EADF99`, 60% indicator, and Settings button.
- Scroll-bound lamp with toggleable beam.
- Scroll-bound layered window at the 412-wide reference location.
- Ten-second sun/cloud animation and reduced motion.
- Furniture, door-to-Map action, bookshelf-to-Lessons action, word-of-the-day,
  sticker container, developer panel, and scroll footer.
- Rive Koka mascot reactions with Flutter speech bubbles and repeated-tap
  escalation.
- Energy-derived lesson availability, expandable/collapsible lesson cards, and
  a Flutter lesson-preview dialog.

## Partial

- Home scene height/content is temporary verification structure.
- Home energy defaults to 60 when no learner is loaded (`LearnerScope`),
  same as before this constructor-carried default existed -- see Learner
  Save System above.
- All six bottom-navigation tabs now reach a destination via the centralized
  `AppBottomTabNavigation` router. Map and Lessons are real screens (see
  above); Translate and Dictionary are still `PlaceholderScreen` shells;
  Me is a real screen shell showing real learner data where
  loaded (Settings/Edit buttons functional; Edit opens a real popup that
  renames the learner and picks a Koka avatar from `assets/images/avatar.riv`
  -- persisted via `LearnerController.updateName`/`updateAvatar` -- badge
  collection UI is still incomplete).
- The Name, Grade, Energy, Learner Card, and Welcome Aboard introductions
  auto-play their bundled production clips once on screen entry; existing
  speaker buttons replay the Name, Grade, and Energy clips. Grade card clips
  play as each card reaches the front; Energy, Learner Card, and Welcome Aboard
  retain callback seams for isolated widget tests.
- Hardware sensor support exists but Welcome disables it in favor of touch.
- Onboarding data now persists via the Learner Save System (above), but
  only the current learner -- no profile switching, no cloud sync.

## Placeholder-Only

- Welcome Next/tutorial destination.
- `RivePlaceholder` visuals in generic placeholder screens.

## Not Implemented

- The Load screen's save browser is still demo data, unconnected to the
  real Learner Save System (above) -- no actual load/delete mutation there.
- Multi-learner profile switching UI (storage supports multiple profiles
  by id; there's no screen to create/switch between them).
- Backend, NMT, APIs, auth, synchronization, or offline/cloud storage --
  the Learner Save System is local-only, on-device.
- Real Translate and Dictionary content (still shells); Me's
  badge collection UI. (Me's name/avatar profile editing is now real -- see
  Partial above.)
- The canonical DevG activity source is currently retained through a
  source-preservation bridge behind Tudlo adapters. It is not yet split into
  its final sub-500-line renderer modules, and complete manual interaction
  verification of every flow remains required before this can be called a
  finished migration.
- Final accessibility policy for lesson narration (captions and replay
  affordances).
- Release identity/signing: Android is `com.maralmt.tudlo_prototype` and release
  currently uses debug signing.

## Tests

- `test/widget_test.dart`: startup, menu, onboarding, loading, learner card,
  Load, Welcome, and portrait overflow.
- `test/home_screen_shell_test.dart`: Home scrolling/fixed layout, responsive
  overflow, room placement, Settings, energy/lesson cards, lamp, and navigation.
- `test/animated_home_window_test.dart`: window timing and reduced motion.
- `test/home_word_of_the_day_test.dart`: word-of-the-day presentation.
- `test/long_button_contract_test.dart`: long-button Data Binding and Flutter
  action reachability.
- `test/koka_mascot_contract_test.dart`: Koka State Machine contract and
  escalating interaction behavior.
- `test/me_screen_test.dart`: Me screen's tabs, progress counts, and daily
  streak card.
- `test/map_screen_test.dart`: map viewport safety and the locked versus
  active-event tap policy.
- `test/lesson_progress_test.dart`: 12-definition catalog, location filtering,
  old-save migration, claim/replay accounting, event restoration, and the
  preserved source card host.
- `test/devg_lesson_flow_render_test.dart`: initial mount of all 12 preserved
  DevG activity entries under Tudlo adapters.
- `test/feature_source_file_budget_test.dart`: 500-line budget for
  Tudlo-authored Home, Lesson, and Map code; the documented raw source bridge
  is excluded until its planned extraction.

Standard checks are `flutter analyze` and `flutter test`; release work should
also include manual source-flow interaction checks at the supported portrait
and Grade 3 landscape sizes.

## Repository and Platform Limitations

- This managed directory has no local `.git`; Git can resolve unrelated parent
  metadata and fail. Open a real clone/repository root in standalone Codex.
- `sources/` and `tool/` are empty at this audit.
- `.magicpath/` is reference/generated content, not Flutter runtime.
- The application baseline is portrait; the Map fullscreen view and Grade 3
  lesson session use their documented, temporary landscape paths.
- Web metadata still has generic prototype name/description/colors.

## NEEDS PROJECT CONTEXT

1. Final Settings, tutorial, Translate, and Dictionary routes; unmapped Map
   locations still use `PlaceholderScreen` shells via `MapDefaultRoutes`.
2. Multi-learner profile switching / Load screen reconciling with the real
   Learner Save System (schema and single-learner persistence already exist
   -- see `docs/LEARNER_GUIDE.md`); Continue selection among saves.
3. Approval order for extracting the preserved DevG flows into their final
   per-activity renderer modules without changing visuals, mechanics, or VO.
4. Backend/NMT/API/auth/offline contracts.
5. Production `.riv` files and exact runtime contracts.
6. Audio files/scripts/service and accessibility behavior.
7. Portrait-only versus landscape requirements.
8. Canonical Figma file/frame and asset archival policy.
9. Remaining Home implementation order after wall, lamp, and window.
