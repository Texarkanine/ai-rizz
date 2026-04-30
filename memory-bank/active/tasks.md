# Tasks: fix-global-add-silent-failure

## What broke
`ai-rizz add rule <name> --global` silently exited with code 1 and no output when global mode wasn't initialized.

## Why
`sync_global_repo()` returned 1 with no message when `get_global_source_repo()` returned empty (no global manifest). Combined with `set -e`, the script terminated before any user-facing output.

## What changed
- `ai-rizz` line ~1068: Added `warn` call before `return 1` in `sync_global_repo()` when source repo is empty, producing: "Global mode is not initialized. Run 'ai-rizz init <repo> --global' to set up global mode."
- `tests/integration/test_cli_add_remove.test.sh`: Added `test_add_rule_global_without_init_shows_error` integration test

## Files affected
- `ai-rizz` (1 line added)
- `tests/integration/test_cli_add_remove.test.sh` (test case added)
