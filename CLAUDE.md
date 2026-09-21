# Tudlo — Claude Code entry point

Read `AGENTS.md` first — it is the full working guide (product, architecture,
conventions, responsive/asset/Rive rules, workflow, "do not change without
asking", known limitations). This file only adds Claude-Code-specific notes
and points to where deeper detail lives. Don't restate AGENTS.md here; edit
that file instead if a rule changes.

## Deeper docs (read only the one you need, only when relevant)

- `docs/PROJECT_OVERVIEW.md` — screens, flows, dependencies.
- `docs/ARCHITECTURE.md` — organization, communication, navigation, state.
- `docs/RIVE_INTEGRATION.md` — confirmed Rive status/contract.
- `docs/UI_AND_RESPONSIVE_RULES.md` — layout, artwork, sizing rules.
- `docs/CURRENT_STATUS.md` — completed / partial / placeholder / unknown.
- `docs/LEARNER_GUIDE.md`, `docs/MAP_GUIDE.md` — feature-specific guides.

## Working efficiently in a fresh session

- Don't re-read AGENTS.md + every doc up front "just in case." Read AGENTS.md,
  then only the specific doc(s) tied to the feature being touched.
- Prefer `Grep`/`Glob` for targeted lookups over opening whole directories.
- `lib/features/<name>/` is self-contained; you usually only need that folder
  plus `lib/core/` and `lib/shared/` for a given feature change.
- Quick verification loop:
  ```shell
  dart format --output=none --set-exit-if-changed lib test
  flutter analyze
  flutter test
  ```
  Use the focused test files under `test/` instead of the full suite when
  iterating on one screen (see AGENTS.md "Run and Test").
- Keep changes scoped to what was asked (AGENTS.md "Do Not Change Without
  Asking") — avoids extra back-and-forth/review cycles that cost usage.

## Environment

- Windows 11, PowerShell primary shell; Bash tool also available.
- No `.git` issues here — this is a real clone (`git status` works).
