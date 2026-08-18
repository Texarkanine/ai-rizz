# Progress

Make `ai-rizz list` default to installed inventory, with `-a`/`--all` restoring the full catalog and a single `N available, not shown` footer when items are hidden.

**Complexity:** Level 2

## 2026-08-18 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Confirmed intent: inventory default, `--all` catalog, cumulative footer, omit empty-of-installed section headers
    - Classified as Level 2 (Simple Enhancement)
* Decisions made
    - Level 2: self-contained `cmd_list` enhancement, not a new subsystem
    - Flags (`-a`/`--all`), not a `list installed` subcommand
    - Footer counts omitted top-level glyph-bearing rows only (not ruleset tree children)
* Insights
    - Daily use is inventory; first-run discovery is taught via docs and `--all`
    - `--all` should stay a strict superset of today's list output so existing catalog tests can retarget rather than be rewritten

## 2026-08-18 - PLAN - COMPLETE

* Work completed
    - Wrote Level 2 implementation plan in `tasks.md` (7 steps: tests, flag parse, filter+footer, help, completion, docs, `make test`)
    - Mapped catalog/`○` tests to `--all` retarget; new inventory/footer tests in existing list suites
* Decisions made
    - Keep section titles `Available X:`; header rename out of scope
    - Footer `N` oracle = count of `○` rows in `--all` output
    - No new test files; no new dependencies
* Insights
    - Retargeted `--all` tests stay green on current code (extra args ignored); the red bar is the new default-inventory tests

## 2026-08-18 - PREFLIGHT - COMPLETE

* Work completed
    - Validated implementation plan against codebase and TDD rules
    - Generated preflight report with FAIL status
* Decisions made
    - Blocked build due to TDD Plan Encoding violation in Step 5 (Bash completion)
* Insights
    - Bash completion is executable code and tests for it are behavioral tests, not change-detectors. The plan must either include test-before-code ordering for bash completion or remove the feature.

## 2026-08-18 - PLAN - COMPLETE (rework)

* Work completed
    - Re-entered plan via `/niko-plan` after preflight FAIL
    - Revised step 5: keep `completion.bash` `list)` flags; operator TDD carve-out (inspection); existing name-listing tests unchanged
* Decisions made
    - Not prose/policy: `completion.bash` stays executable
    - Not a new harness: `_ai_rizz_completion` depends on `_init_completion`; COMP_WORDS dispatcher tests are out of scope for a static flag list
    - Not a change-detector: do not grep `completion.bash`
    - Name-listing tests stay because missed rule bodies are the failure mode that earned them
* Insights
    - Preflight's tests-or-remove fork was real; the operator's third path is inspect-by-looking for flags. If TDD encoding cannot represent that, the friction belongs in the preflight skill, not a harness in this task
