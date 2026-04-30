# Progress: fix-global-add-silent-failure

Fix silent failure when `ai-rizz add rule --global` is used without global mode being initialized. `sync_global_repo()` returns 1 with no message, and `set -e` kills the script.

**Complexity:** Level 1

## Build Phase
- Root cause: `sync_global_repo()` line ~1068 returned 1 with no error message when `get_global_source_repo()` returned empty
- Fix: Added `warn` call before `return 1` with actionable message directing user to `ai-rizz init <repo> --global`
- Test: Added integration test `test_add_rule_global_without_init_shows_error` in `test_cli_add_remove.test.sh`
- Full suite: 33/33 tests pass (26 unit + 7 integration)

## QA Phase
- PASS — all semantic constraints satisfied. Minimal, pattern-consistent fix.
