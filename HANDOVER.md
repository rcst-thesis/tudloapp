# Handover — Day Streak / Energy / Dictionary Art / Grade Dialogue session

Written for a fresh agent (Codex) picking this up cold. Read `AGENTS.md`
first for the general project rules; this file only covers what changed in
this session and what's still open. Delete or archive this file once it's
been read/merged into permanent docs if it's no longer useful.

## Next goal for whoever picks this up: fix the lessons

The user's explicit next-step instruction for Codex: **the goal is to fix
the lessons.** No further specifics were given when asked (lesson
dashboard/grid screen vs. actual in-lesson gameplay content vs. something
else) — get clarification from the user directly on what's actually broken
before making changes, rather than guessing scope from this note alone.

## 1. Day-streak feature (new)

**Goal:** a real, working "day streak" — not just a display number — plus a
two-screen celebration flow shown once per day.

### Domain model (`lib/features/learner/domain/`)

- `LearnerProfile.currentStreak` (raw counter) + `effectiveStreak([now])`
  (computed): the streak only *extends* if the last first-completion was
  exactly yesterday; any bigger gap resets it to 1 on the next completion.
  `effectiveStreak()` also catches up reads between completions — if a full
  day's gone by with nothing recorded, it reads as broken (`0`) even before
  the next completion officially resets the stored counter.
- `LearnerProfile.lastStreakCheckInDate` + `needsStreakCheckInToday([now])`:
  gates the celebration flow to once per calendar day.
- `LearnerScope.recordLessonCompletion` (in `learner_scope.dart`) computes
  the streak transition (extend/reset) — see the `nextStreak`/
  `continuesStreak` logic there.
- `LearnerScope.recordStreakCheckIn()` marks today's date, called **before**
  showing the flow (not after finishing it), so an interrupted flow doesn't
  reappear later the same day.

### Screens (`lib/features/me/presentation/screens/`)

- `daily_checkin_screen.dart` — `DailyCheckInScreen`: "day N, happy
  {weekday}!" card. `day N` = calendar days since `LearnerProfile.createdAt`
  (day 1 = creation day), **not** the weekday number — those are two
  independent things that happen to coincide for a Monday-created profile.
  Character art (`assets/images/daily_checkin_day1.png`..`day7.png`) cycles
  through the 7 illustrations in step with `day N`, wrapping via
  `((dayNumber - 1) % 7) + 1` since only 7 exist.
- `daily_streak_screen.dart` — `DailyStreakScreen`: the sun-rays
  celebration. Rays are a `CustomPainter` (`_StreakRaysPainter`) that
  rotates around **Koka's actual measured center** (via a `GlobalKey` +
  `RenderBox.localToGlobal`/`globalToLocal` in `_DailyStreakScreenState`),
  not the screen's geometric center — Koka isn't vertically centered in the
  layout. Also has `_WeekStreakIndicator`: a week-of-circles pill where
  consecutive "done" days merge into one connected white capsule (only
  outer edges rounded) with a single custom-painted checkmark
  (`_CheckMarkPainter` — deliberately not `Icons.check_rounded`, whose
  glyph isn't optically centered) on today's cell only. Uses
  `OnboardingKokaGreeting` (loops the "Hi" wave) instead of the one-shot
  `TudloMascot`.
- `daily_streak_flow.dart` — `DailyStreakFlow`: chains the two screens
  above for the current learner, then calls `onFinished(context)` (passes
  its **own** live context, not whatever context the caller pushed it from
  — that's long gone by the time a learner finishes clicking through).
  Loops `TudloAudioAssets.dailyStreakVoiceOver` via
  `playVoiceOverAndWait` in a `while` loop for as long as it's mounted,
  stops it in `dispose()`. **Has a guard**: a minimum 250ms per-iteration
  wait, because if playback ever fails to start (missing asset, no audio
  backend), `playVoiceOverAndWait` can resolve near-instantly and turn a
  naive loop into a CPU-spinning busy loop. Keep that guard if you touch
  this file.

### Wiring — where it actually triggers

`MainMenuScreen._continue` (main_menu_screen.dart) and
`LoadScreen._confirm`'s real-profile branch (load_screen.dart) both:
1. Switch to the profile.
2. Check `needsStreakCheckInToday()`; if true, call `recordStreakCheckIn()`
   immediately (before showing anything).
3. Navigate to `FourthLoadingScreen`, passing a `homeBuilder` that returns
   `DailyStreakFlow(onFinished: ...)` instead of the default `HomeScreen()`
   when the gate is true. **The order is: loading screen first, then the
   two streak screens, then Home** — not before the loading screen. This
   works because `FourthLoadingScreen.homeBuilder` is exactly what
   `HomeLoadingScreen._buildHome` pushes via `pushReplacement` once loading
   finishes, so `DailyStreakFlow.onFinished` just does one more
   `pushReplacement` to swap in the real `HomeScreen()`.

Background music is already silent through this whole stretch (existing
`stopBackgroundMusic()` calls before leaving Main Menu/Load) and resumes
naturally once `HomeScreen` mounts (its own existing `startBackgroundMusic()`
call) — no extra music handling was needed, just the VO loop.

### Debug boot override (currently OFF)

`lib/main.dart` has `const _debugShowDailyStreakFirst = false;` threaded
through `TudloApp` → `StartupFlow.debugShowDailyStreakFirst`. When `true`,
boot shows `DailyCheckInScreen` → `DailyStreakScreen` before Main Menu, for
quick manual checking without going through Continue/Load. **Leave it
`false`** unless you're actively debugging visuals — it's redundant now that
the real trigger exists, and flipping it doesn't affect any test (default is
`false` everywhere test code constructs `StartupFlow`/`TudloApp`).

### Audio

- `assets/audio/vo_daily_streak.wav` — currently "daily streaks v2.wav"
  (per the user's latest swap). `TudloAudioAssets.dailyStreakVoiceOver` in
  `lib/shared/audio/audio_assets.dart`, with a measured fallback duration
  (117190ms) in `voiceOverDuration()`. If the audio file changes again,
  **recompute the duration** (`python -c "import wave; w=wave.open(path);
  print(w.getnframes()/w.getframerate()*1000)"`) and update that constant —
  it's the fallback used when the native playback-complete event isn't
  delivered (common on Android), so a stale value can cause premature loop
  restarts or overlap.

## 2. Energy system (new — was previously a static display-only number)

**Goal:** genuinely drain 10 energy per lesson, regen 10 every 4 hours,
capped at the parent-configured level (Settings/onboarding's "battery"
picker) — not a hardcoded 100.

- `LearnerProfile.energy` (existing field) is now documented as the
  **parent-set ceiling only** — unchanged semantics, still edited via the
  onboarding/Settings energy picker.
- New: `LearnerProfile.currentEnergy` (nullable int) + `lastEnergyDrainAt`
  (nullable DateTime) + `effectiveEnergy([now])` — same
  compute-fresh-at-read pattern as `effectiveStreak`. `null` fields mean
  "never drained yet, i.e. full".
- `LearnerScope.recordLessonCompletion` now also drains 10 energy on
  **every** completion including replays (catches up any pending regen
  first via `effectiveEnergy`, then subtracts 10, then re-anchors the
  4-hour timer to `completion.completedAt`).
- Display read-sites switched from raw `.energy` to `.effectiveEnergy()`:
  `home_screen.dart` (`_energy` getter → Home's battery indicator + lesson
  availability cap), `devg_lesson_host.dart` (`AppData.configure(energy:
  ...)` → DevG lesson dashboard's energy gate), `settings_screen.dart`
  (`_buildExpandedContent`'s lesson-count preview text).
- **Left alone on purpose**: `settings_screen.dart`'s `initialEnergy:
  controller.profile?.energy` (line ~925, feeds the energy *setter*
  screen) — that's editing the max/set level, not displaying current
  spendable energy.
- Tests: `test/learner_scope_test.dart` has coverage for both the
  drain-per-lesson and the 4-hour-regen-with-cap behavior.

## 3. Dictionary word art (69 of 71 words wired)

Matched a folder of word-image pairs
(`C:\Users\User\OneDrive\Documents\animations stuf\Dictionary\Asset`)
against `lib/features/dictionary/domain/dictionary_words.dart` by
slugified id (lowercase, spaces→hyphens, matching the existing `id:`
field convention). **69 matched and are wired** (`frontCardImage`/
`favThumbImage` set, assets copied to `assets/images/<id>_dictionary.png`
and `<id>_dictionary_fav_thumb.png`). **2 did not match**: `presyo` and
`tagum` have art files sitting in the asset folder but no corresponding
dictionary entry exists at all in `dictionary_words.dart` — nobody has
decided whether to add them as new entries or discard the art. Follow up
with the user on this if it comes up.

The featured tray (`dictionary_bento_grid.dart`) was also fixed to
actually render art at all (it previously showed word-text only, no
image, despite being gated on `favThumbImage != null`) — it now renders
`frontCardImage` and the gate in `dictionary_browse_screen.dart` matches.

## 4. Grade selection screen — merged dialogue boxes

`lib/features/onboarding/presentation/screens/grade_selection_screen.dart`
used to have two separate speech bubbles: a big static "nice to meet you..."
intro bubble and a small bubble with dynamic "Grade N kana subong?" text.
Per explicit request, these are now **one box** (the big one's size/shape
preserved): it shows the intro line until the intro VO has been heard once
(`_showGradeText` flips permanently true right after
`_playIntroVoiceOver` resolves, whether from the automatic first play or a
manual replay tap before that happens), then switches to the grade prompt
via `AnimatedSwitcher` and **stays there** — the same voice button now
always narrates the currently-selected grade, never replays the intro
again. The grade prompt's font size is `16` (bumped up from matching the
intro's `14`, per a follow-up request — the intro text itself is still 14).

Both affected tests in `test/widget_test.dart` were rewritten:
"grade arrows rotate the active card and wrap around" now injects fake
instant VO players (real/default audio timing in a bare widget test is
unpredictable — see the note below) and adds an extra `pump()` before its
first assertion; "the single grade speech bubble narrates the intro once,
then only the selected grade" (renamed from "grade speech bubbles expose
intro and selected-grade VO") replaces the removed
`grade-selection-bubble`/`grade-selection-voice-button` keys and needs
**two** pumps after the intro resolves (`await tester.pump();` then
`await tester.pump(const Duration(milliseconds: 300));`) before the
`AnimatedSwitcher` transition has actually completed in the tree — a single
pump wasn't enough; the `setState` from the VO completion and the
switcher's own fade appear to need separate frames.

## 5. Lesson screen (grid, card art, popups) — from earlier in this session

Smaller, already-settled items, listed for completeness:

- `lessons_screen.dart`'s dashboard is a 2-column scrollable `GridView`
  (was a carousel), inside one `CustomScrollView` with the footer as the
  last sliver (not a fixed `bottomNavigationBar`).
- Card art (`grade1_lesson1_card.png` etc., now 4 lessons total across
  Unit 1/2) renders inside an invisible native `Container` sized to the
  design box with `BoxFit.contain`, not stretched to a hardcoded
  width/height — preserves the PNG's real aspect ratio.
- Locked/unavailable overlay redesigned: dark scrim scoped to the same
  `FittedBox`-scaled design-space `Stack` as the card art (previously it
  covered the outer post-margin box, which had a slightly different aspect
  ratio and made the scrim read taller than the card), plus a custom
  sticker-style circle badge instead of a bare Material icon.
- Unit 2 gets its own play-button colors (`#884830`/`#482518`), its own
  play-triangle SVG (`assets/images/lesson_play_icon_unit2.svg`), and its
  own thumbnail (`assets/images/unit2_thumbnail.png`, scaled `0.8x` via
  `_unitThumbnailScaleForDashboard` — its source PNG has less built-in
  padding than Unit 1's).
- Tapping a card's Play button no longer jumps straight into the lesson —
  it opens `_LessonStartPopup` (dimmed modal) that narrates that one
  lesson's VO and requires tapping "Sugod" to actually start. VO no longer
  auto-plays just from browsing the grid (that stopped making sense once
  multiple cards can be on screen at once).
- `HomeLessonPreview.unitNumber` was added so Home's lesson panel and its
  preview popup pick the right unit's category icon
  (`home_lesson_card.dart`'s `categoryIconForUnit`, reused by
  `home_lesson_preview_dialog.dart`).

## 6. Known test/environment caveats

- **9 pre-existing failures in `test/widget_test.dart`** are unrelated to
  anything in this session — confirmed via `git stash` against the
  untouched `main` branch before any of this work started. Don't chase
  these unless asked; they were already broken.
- **Real audio (`TudloAudioController` with the default `SoloudAudioBackend`)
  can hang indefinitely in a bare widget test** with no platform-channel
  mock — hit this directly trying to test `DailyStreakFlow`'s VO loop (a
  test hung 3+ minutes and had to be killed). This is why
  `GradeSelectionScreen` and other screens expose `introVoiceOverPlayer`/
  `gradeVoiceOverPlayer`-style override params for tests, and why the
  `DailyStreakFlow` VO loop doesn't have automated coverage — only
  `flutter analyze` + code review, matching the already-proven
  `playVoiceOverAndWait`/`stopVoiceOver`/session-cancellation pattern used
  elsewhere. If you add a test that awaits real playback, inject a fake
  player; don't call into the real backend synchronously in a test.
- `flutter test` was run throughout via the Bash tool wrapping
  `flutter test <file>`; nothing exotic in the setup.

## 7. Not done / open threads

- `presyo`/`tagum` dictionary art (see §3) — no LearnerCatalog/dictionary
  entry exists yet for either word.
- Nobody has manually verified the day-streak flow, energy drain/regen, or
  the merged grade dialogue on a real device/emulator this session — all
  changes are `flutter analyze`-clean and covered by the test suites noted
  above, but the user explicitly did not want another emulator-driving
  pass after an earlier one burned a lot of turns chasing a stuck ADB/
  `flutter run` process (see git history around this file's commit for
  context if curious — not worth repeating that approach).
