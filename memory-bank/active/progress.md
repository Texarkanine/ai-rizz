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
