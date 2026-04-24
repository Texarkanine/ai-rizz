---
task_id: ruleset-skills-cmd-routing
complexity_level: 2
date: 2026-04-23
status: completed
---

# TASK ARCHIVE: Ruleset skill markdown must not become slash-commands

## SUMMARY

ai-rizz was flattening every `*.md` under a ruleset into `.cursor/commands/`, which duplicated Niko and other skill reference markdown that should only live under the embedded skill tree (`.cursor/skills/...`). The fix excludes `rulesets/<r>/skills/**` from the ruleset-wide flat `*.md` pass in `copy_entry_to_target()`. A regression test and `memory-bank/systemPatterns.md` updates document the behavior. Full `tests/run_tests.sh` (33/33) passed, with `/niko-qa` semantic review.

## REQUIREMENTS

- `copy_entry_to_target` must skip `skills/**` for the ruleset-wide `*.md` flattening step.
- A regression test must show reference markdown stays under the skill tree and is not installed as a flat command.
- Full test suite must pass.

## IMPLEMENTATION

- **Routing / sync:** `copy_entry_to_target()` in `ai-rizz` — the ruleset branch that enumerates `*.md` for flat command deploy now omits paths under the ruleset’s `skills/` subtree, so the earlier `find`-style flatten does not race or duplicate the dedicated `cp -rL` skill deploy.
- **Tests:** `tests/unit/test_ruleset_commands.test.sh` — `test_md_under_skills_dir_not_deployed_as_flat_commands` builds a ruleset with `skills/niko/references/core/memory-bank-init.md` and asserts the file appears under `.cursor/skills/...` but not as a top-level command.
- **Docs:** `memory-bank/systemPatterns.md` — “magic” `skills/` behavior and `copy_entry_to_target` ownership clarified for future readers.

## TESTING

- `tests/run_tests.sh` — 33/33 passed.
- `/niko-qa` (2026-04-23): implementation aligned with `projectbrief`; `PASS` recorded in ephemeral QA status (inlined in this archive via TESTING/QA narrative above; status file removed at archive time).

## LESSONS LEARNED

The following is inlined from the final reflection (ephemeral `reflection-ruleset-skills-cmd-routing.md` removed with archive).

- **Ordering and ownership:** When one deploy path uses a broad glob on `*.md` and another path owns a subtree (`skills/`), the broad pass must explicitly exclude the subtree or the same file gets two roles (e.g. slash-command plus skill reference). Documenting “magic dirs” in `systemPatterns` helps the next maintainer see why the skip exists.
- **Build & QA:** Small localized guard plus one shunit2 test; suite stayed green; no rework loop.
- **Process:** Memory-bank `active/*` is easier to trust if updated during the build, not only at reflect—otherwise audit trail lags until backfill. Accept backfill in lean sessions, or keep `projectbrief`/`progress` current during work.
- **Deeper design note:** If command discovery had been explicit (e.g. only ruleset root + `commands/**` as slash-commands) instead of “all `*.md` with exceptions,” the bug might not have appeared. The exclusion fix is the minimal, compatibility-preserving tradeoff; a broader contract change would be separate work.

## PROCESS IMPROVEMENTS

- Prefer updating `memory-bank/active/projectbrief.md` and `memory-bank/active/progress.md` as phases complete during a task, not only at reflect, when `/niko` tracking is in use.

## TECHNICAL IMPROVEMENTS

- **Optional future:** Narrow slash-command discovery to explicit roots (e.g. ruleset root and/or `commands/**` only) instead of legacy “flatten all `*.md` with subtree exceptions”—would be a behavior contract change for unusual layouts; not required for this fix.
- **None** otherwise mandatory beyond what was shipped.

## NEXT STEPS

None. Optional research above is advisory only.
