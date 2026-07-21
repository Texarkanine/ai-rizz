# Progress

Fix [#40](https://github.com/Texarkanine/ai-rizz/issues/40) and [#41](https://github.com/Texarkanine/ai-rizz/issues/41): in git repos, exclude global from auto mode selection (require `--global`); bare-repo unflagged add must error without writing an invalid manifest; preserve global-only auto-select outside git.

**Complexity:** Level 2

## 2026-07-21 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Intent confirmed for #40 + #41 as one delivery
    - Classified Level 2 (simple enhancement / focused bugfix in mode-selection subsystem)
* Decisions made
    - Level 2 path: plan → preflight → build → qa → reflect → (operator archive)
* Insights
    - Primary lever is `select_mode()`; existing tests in `test_global_mode_detection.test.sh` will need updates for local+global auto-select

## 2026-07-21 - PLAN - COMPLETE

* Work completed
    - TDD plan: behaviors for #40/#41, test file mapping, linear implementation steps
    - Noted existing `test_select_mode_two_modes_local_global` must flip to auto-select local
* Decisions made
    - In git repos, auto-select counts only local+commit; zero repo modes → actionable error (not “multiple modes”)
    - Keep change in `select_mode()` so all callers share policy; out of scope: #42 deinit
* Insights
    - `APP_DIR` in global detection suite is already a git repo — right place for #40/#41 cases

## 2026-07-21 - PREFLIGHT - COMPLETE

* Work completed
    - Validated plan against TDD encoding, conventions, callers, completeness
    - Wrote `.preflight-status` PASS
* Decisions made
    - No plan amendments required
* Insights
    - `select_mode` is only used by `cmd_add_rule` and `cmd_add_ruleset` (narrower blast radius)
