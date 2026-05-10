---
task_id: issue-30-ruleset-list-root-skill-dir-filtering
complexity_level: 2
date: 2026-05-09
status: completed
---

# TASK ARCHIVE: Ruleset list hides unsupported root-level skill-like directories

## SUMMARY

`cmd_list` ruleset tree output now includes only supported top-level entries: `.mdc` files, the magic directories `commands` and `skills`, and other directories that contain deployable `.mdc` rules (detected recursively). Unsupported root-level skill-like paths such as `rulesets/<r>/<name>/SKILL.md` outside `skills/` no longer appear as installable tree content. Integration tests, full suite verification, and `docs/rule-authoring/rulesets.md` were updated so list behavior matches the documented contract.

## REQUIREMENTS

- Exclude unsupported top-level directories from ruleset list trees while preserving supported entries (`.mdc`, `commands`, `skills`, directories with nested `.mdc`).
- Preserve POSIX-shell patterns and existing tree rendering after filtering inputs.
- Cover the issue with integration tests and align documentation with list-display semantics.

## IMPLEMENTATION

- **Runtime (`ai-rizz`):** Ruleset top-level discovery for list was tightened from “all directories” to supported-entry filtering only, feeding the existing sorted tree-print path so ordering and glyphs stayed stable.
- **Tests:** `tests/integration/functions/test_ruleset_list_display.test.sh` — asserts unsupported root-level `SKILL.md` directories are absent from output while `skills/<skill>` and directories containing `.mdc` remain visible.
- **Docs:** `docs/rule-authoring/rulesets.md` — clarifies supported list contract and that root-level embedded-skill layouts outside `skills/` are unsupported for display purposes.

## TESTING

- Targeted integration suite during iteration; full `make test` and strict docs build (`make docs-build`) succeeded before task completion.
- Level 2 QA completed with PASS (semantic review: implementation matches plan and docs; no substantive defects). QA status was recorded in ephemeral `.qa-validation-status` (removed at archive).

## LESSONS LEARNED

The following is inlined from the final reflection (ephemeral `reflection-issue-30-ruleset-list-root-skill-dir-filtering.md` removed with archive).

- **Summary:** List filtering now matches supported/deployable semantics; tests and docs stayed aligned; QA passed without rework.
- **Requirements vs outcome:** All planned requirements delivered; no dropped scope or unintended feature creep.
- **Plan accuracy:** Linear TDD plan (existing integration suite, `cmd_list` filter, docs) matched execution; over-filtering risk was addressed by allowing directories that contain `.mdc` deployables.
- **Build and QA:** Red/green loop after tests landed; targeted then full test runs and docs build succeeded.
- **Technical:** List output should follow the same supported-entry rules users rely on, not raw top-level directory presence.
- **Process:** Extending the existing ruleset-list integration suite gave strong regression coverage with low maintenance cost.
- **Deeper design note:** A shared “supported ruleset top-level entries” helper reused by list (and future validation or docs checks) would keep behavior consistent from the start.

## PROCESS IMPROVEMENTS

- When fixing list UX, pair code changes with integration assertions that encode the supported vs unsupported layout contract explicitly.

## TECHNICAL IMPROVEMENTS

- Optional: extract shared enumeration for supported ruleset top-level entries for reuse across list, validation, and documentation cross-checks.

## NEXT STEPS

None required for this task. Optional shared-helper extraction is advisory only.
