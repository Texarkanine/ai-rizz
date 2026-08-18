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
