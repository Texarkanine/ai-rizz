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
