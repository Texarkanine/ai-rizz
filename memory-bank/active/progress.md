# Progress: ruleset-skills-cmd-routing

**Complexity:** Level 2

## Chronology

- **Plan / build (retro):** Routed ruleset `*.md` flattening to skip paths under `skills/` so Niko reference markdown under `.cursor-rules` rulesets is not installed as Cursor commands.
- **QA:** `tests/run_tests.sh` — 33/33 passed after change.
- **Reflect:** Backfilled active memory bank and wrote `reflection-ruleset-skills-cmd-routing.md` (operator invoked `/niko-reflect` after archive cleared `active/`).
- **QA (post-reflect):** `/niko-qa` — verified `copy_entry_to_target` excludes `rulesets/<r>/skills/**` from flat command sync; regression test and docs align; 33/33 tests passed.

## Phase status

- Reflect phase: complete for this task.
- QA phase: complete (verification run 2026-04-23).
