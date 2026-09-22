# DevG-to-Tudlo canonical lesson migration

## Source of truth

The DevG project at
`C:\Users\User\OneDrive\Documents\animations stuf\DevG\toadlu-v3-devG\toadlu-v3-devG`
contains the lesson product Tudlo must host. Its production-flow entry is
`lib/features/lesson_game/screens/level_game_page.dart`; it selects these
twelve exact flows:

| Grade | Lesson IDs | DevG source flow |
| --- | --- | --- |
| 1 | `g1_u1_l1`, `g1_u1_l7`, `g1_u2_l1`, `g1_u2_l4` | letter, number, family, greeting |
| 2 | `g2_u1_l1`, `g2_u1_l2`, `g2_u2_l1`, `g2_u2_l2` | new friend, birthday, park greeting, park dialogue |
| 3 | `g3_u1_l1`, `g3_u1_l3`, `g3_u2_l1`, `g3_u2_l2` | market numbers, shopping, Bantay, story |

The initial fidelity port keeps DevG's production page and flow parts under
`lib/vendor/devg/`. This is a deliberately
marked **source-preservation bridge**: its game page plus flow parts are over
40,000 lines and retain the original artwork, mechanics, Hiligaynon copy,
reward flow, and voice call sites while Tudlo replaces the incompatible global
application shell around them. It is not the final modular architecture.

New Tudlo adapters stay below 500 lines. The remaining migration work is to
extract each retained flow into focused renderer modules below 500 lines
without rebuilding its child-facing activity or losing asset/voice coverage.
Do not call the raw bridge fully modularized or bypass it with a generic quiz.

## What is retained and what is adapted

| Canonical DevG responsibility | Tudlo migration treatment |
| --- | --- |
| Activity sequence, art layers, hit targets, drag/match mechanics, Hiligaynon copy, feedback states, rewards, and final voice-over | Retain in the source-preservation bridge; extract unchanged behaviour into source-faithful renderer modules |
| `AppData` active level, energy spending/recharging, score/sticker maps, and completion persistence | Replace with `LessonDefinition`, `LessonProgressController`, and `LearnerProfile.lessonProgress` |
| `AppAudioService`, `audioplayers`, and TTS fallback | Replace with `TudloAudioController`; source clips use existing master/music/SFX/voice preferences |
| `AppShell` / source Navigator destinations | Keep Tudlo `FadePageRoute` origin/back behavior |
| DevG map dashboard | Keep Tudlo's existing Rive map; use semantic `MapEventOverrides` only |

## Required renderer contract

Every preserved or extracted flow receives a small host context containing its
`LessonDefinition`, an exit callback, a completion callback, and a Tudlo audio
adapter. It must:

1. Use the staged source assets and source voice clips—not substitutions.
2. Report attempts/score only in memory until the learner claims its reward.
3. Call the host completion callback exactly once after the source flow's real
   completion state.
4. Stop narration and restore orientation on every exit/dispose path.
5. Never reconnect DevG global persistence, source audio engines, or source
   navigation code. The compatibility facades are Tudlo-owned adapters.

The host owns reward persistence and scheduling the next map event; Rive stays
visual/input feedback only.
