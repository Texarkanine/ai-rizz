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

## 2026-08-18 - PREFLIGHT - COMPLETE (FAIL, rework)

* Work completed
    - Revalidated the revised implementation plan against codebase conventions, consumers, documentation tooling, and mandatory TDD rules
    - Recorded the FAIL gate and a concrete completion-test route that does not require bash-completion or a `COMP_WORDS` dispatcher harness
    - Added `make docs-build` to full verification for the planned documentation changes
* Decisions made
    - Kept the build blocked because Step 5 still schedules executable completion behavior without a test-first step
    - Preserved the operator's no-test decision as the unresolved conflict rather than silently overriding it during preflight
* Insights
    - `_ai_rizz_completion` can be unit-tested by sourcing `completion.bash` and stubbing `_init_completion` to set Bash's dynamically scoped `cur` and `prev` locals
    - Inspection can review a static flag list but cannot satisfy the repository's mandatory TDD gate for executable behavior

## 2026-08-18 - PLAN - COMPLETE (rework 2)

* Work completed
    - Re-entered plan via `/niko-plan`; operator accepted the cheap `_init_completion` stub test
    - Step 5 is now test-first: `test_bash_completion.test.sh` then `list)` arm in `completion.bash`
    - Kept `make docs-build` in step 7
* Decisions made
    - Cheap test is in: source `completion.bash`, stub `_init_completion` to set dynamically scoped `cur`/`prev`, assert `COMPREPLY` has `-a` and `--all`
    - Still no bash-completion package, no `COMP_WORDS` tty harness, no grep change-detector
    - Do not expand this task into testing every completion surface
* Insights
    - Operator: we have been burned on completion before; the stub is worth it for the flag offers too

## 2026-08-18 - PREFLIGHT - COMPLETE (PASS WITH ADVISORY)

* Work completed
    - TDD encoding PASS: step 5 is test-first via the `_init_completion` stub
    - Wrote a full `cmd_list` retarget enumeration into `tasks.md`
    - Added `make docs-build` dependency note: `docs/user-guide/commands/index.md` embeds help verbatim
* Decisions made
    - Advisory (not applied): footer could read `N available, not shown (ai-rizz list --all)` — Requirement 4 pins the exact string, so that stays an operator call
    - Flag parse stays after `ensure_initialized_and_valid` (uninitialized `--bogus` reports no config, not the bad token)
* Insights
    - Empty-section tests must move to `--all` or they pass vacuously after the inventory flip

## 2026-08-18 - BUILD - COMPLETE

* Work completed
    - Implemented inventory default, `-a`/`--all`, footer, omitted empty-of-installed headers
    - Added cheap `_ai_rizz_completion` test and `list)` completion arm
    - Updated help and docs; `make test` passed; `make docs-build` passed
* Decisions made
    - Completion stub feeds `cur`/`prev` through environment variables, not the stub's positional params
    - Advisory footer hint not applied (brief pins `N available, not shown`)
* Insights
    - `_init_completion` is called with no args, so `$1`/`$2` inside the stub are empty; env vars are the cheap path that actually works

## 2026-08-18 - QA - COMPLETE (FAIL)

* Work completed
    - Reviewed the committed build against the project brief, Level 2 implementation plan, established shell patterns, tests, help, and user documentation
    - Confirmed the core inventory/catalog implementation is simple and follows the planned architecture
    - Recorded four blocking completeness and documentation findings in `.qa-validation-status`
* Decisions made
    - Failed QA because the list documentation example reports six hidden items while showing only five
    - Required Build to restore planned default standalone-skill coverage, add the planned empty-catalog assertion, and verify unknown arguments exit nonzero
* Insights
    - Retargeting the whole standalone-skill glyph test to `--all` preserved catalog coverage but silently removed the default-inventory half specified by the plan
    - The executable behavior appears correct by inspection; the blockers are one inaccurate user-facing example and missing planned contract assertions

## 2026-08-18 - BUILD - COMPLETE (QA rework)

* Work completed
    - Fixed list.md footer example 6→5
    - Default `cmd_list` assertions on installed standalone skill vs hidden sibling
    - Empty-catalog prints nothing
    - Unknown-arg tests assert nonzero exit
    - `make test` and `make docs-build` passed
* Decisions made
    - CLI `-a` vs `--all` equality dropped (VERBOSE_TESTS debug prefix made full-output compare fail); both still asserted independently
* Insights
    - Retargeting a mixed installed/uninstalled test entirely to `--all` drops the inventory half unless you add a second `cmd_list` call

## 2026-08-18 - QA - COMPLETE

* Work completed
    - Reviewed the reworked build against the project brief, Level 2 implementation plan, and QA rules
    - Verified that all blocking findings from the previous QA failure were addressed
    - Confirmed tests for empty catalog, unknown arguments, and default inventory standalone skills are present and correct
    - Confirmed the documentation example was corrected
* Decisions made
    - Passed QA
* Insights
    - The rework successfully addressed the missing assertions and documentation error without introducing new complexity
