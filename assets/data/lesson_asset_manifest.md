# Canonical DevG lesson asset manifest

DevG is the canonical source for the twelve production lessons. This manifest
records the complete, non-archival source asset set staged in Tudlo so migrated
renderers can preserve their exact artwork, rewards, feedback sounds, and final
voice-over clips. The target copies are additive: no existing Tudlo asset was
overwritten.

| Target path | DevG source path | Files | Purpose |
| --- | --- | ---: | --- |
| `assets/data/tudlo_updated_lesson_dataset.json` | `assets/data/tudlo_updated_lesson_dataset.json` | 1 | lesson IDs, Hiligaynon copy, examples, and source data |
| `assets/data/ilonggo_dictionary_dataset.json` | `assets/data/ilonggo_dictionary_dataset.json` | 1 | source language lookup data referenced by lesson chrome |
| `assets/data/ilonggo-dictionary-formatted.json` | `assets/data/ilonggo-dictionary-formatted.json` | 1 | formatted source language lookup data |
| `assets/images/level_game/` | `assets/images/level_game/` | 309 | exact production activity backgrounds, characters, props, SVG scenes, Grade 1–3 artwork, and story/map visuals |
| `assets/images/game_map/` | `assets/images/game_map/` | 8 | Grade 1 greeting-flow map decorations |
| `assets/images/dialogue/` | `assets/images/dialogue/` | 5 | shared dialogue/chrome artwork used by lesson presentation |
| `assets/images/stickers/rewards/home/` | `assets/images/stickers/rewards/home/` | 9 | canonical lesson reward stickers |
| `assets/audio/effects/` | `assets/audio/effects/` | 7 | tap, correct, wrong, unlock, completion, and star feedback |
| `assets/audio/VO-final/` | `assets/audio/VO-final/` | 284 | final Grade 1–3 lesson narration and numbered clips |
| `assets/audio/VO/` | `assets/audio/VO/` | 34 | recorded language-helper clips referenced by lesson chrome |

**Staging total:** 659 copied source files, about 506 MiB. The copies exclude
DevG archives and unrelated app-shell assets.

All migrated renderers must play these clips through `TudloAudioController`.
They must never restore DevG's `audioplayers`, TTS, global audio service, or
source persistence. A renderer is not considered migrated merely because its
asset is present: it must reference the source artwork and voice clips during
the actual interaction flow.
