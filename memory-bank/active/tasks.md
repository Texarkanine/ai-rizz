# Current Task: fix-list-ruleset-tree-stem

**Complexity:** Level 1

## Fix Summary

- **What broke:** Nested children under last-sibling `commands/` / `skills/` in `ai-rizz list` printed with a hardcoded `│` stem under `└──`, looking like an unterminated tree.
- **Why:** `cmd_list` always used `printf "    │   ..."` for nested items, ignoring whether the parent was last (`└──`) or not (`├──`).
- **What changed:** Derive `cl_nest_stem` (`│   ` vs four spaces) from sibling position alongside `cl_tree_char`; use it in both nested printf paths.
- **Files affected:** `ai-rizz` (`cmd_list`); `tests/integration/functions/test_list_display.test.sh` (four stem-prefix cases).

## Checklist

- [x] Failing tests for last-sibling blank stem (commands + skills)
- [x] Passing regression for middle-sibling `│` stem (commands + skills)
- [x] Minimal fix in `cmd_list`
- [x] Full test suite (`make test`) — 3/3 unit, 34/34 integration
