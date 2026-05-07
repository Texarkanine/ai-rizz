# Active Context

## Current Task

**M1 — slobac-audit-fixes-2** (audit findings 1–14 per [`slobac-audit-2.md`](../../slobac-audit-2.md)).

## Phase

**BUILD — COMPLETE**

## What Was Done

- Implemented M1 test remediation: integration suites (`test_cli_add_remove`, `test_cli_init`, `test_help_and_usage`) and unit suites (`test_deinit_modes`, `test_error_handling`, `test_hook_based_local_mode`, `test_list_display`, `test_ruleset_management`, `test_sync_operations`, `test_command_sync`, `test_command_modes`).
- Invalid-repository integration test clears `${HOME}/.config/ai-rizz/repos` before `add` so the failure path is exercised without relying on a stale clone cache.
- Sourced-hook tests set custom manifest names via `parse_manifest_filename_argument` (CLI `-f` is not wired for sourced `cmd_init`).
- `cmd_sync` / `cmd_list` paths that call `error()` are invoked inside subshells in tests so `exit` does not terminate the shunit2 runner.
- Semantic redundancy: removed overlapping tests from `test_command_modes.test.sh`; kept global ruleset-with-commands case; strengthened `test_command_sync` add paths with explicit exit checks.
- **`make test`** (26 unit + 7 integration suites) passes.

## Next Step

Run **`/niko-qa`** for post-build semantic review. Preflight remains **`PASS WITH ADVISORY`** (optional reflection checklist for redundancy deletions).
