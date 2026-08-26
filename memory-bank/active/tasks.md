# Task: list shows full catalog when inventory is empty

* Task ID: list-empty-inventory-catalog
* Complexity: Level 2
* Type: simple enhancement

When no manifest entries exist across active modes, default `ai-rizz list` shows the full source catalog (equivalent to `--all`). With any installed item, inventory-only default and footer behavior unchanged.


## Test Plan (TDD)

### Behaviors to Verify

- Fresh init, empty manifests: `cmd_list` → full catalog sections, `○` glyphs, no `available, not shown` footer; output equals `cmd_list --all`.
- One item installed: default `list` hides uninstalled rows and prints footer with hidden count.
- Empty source repo (no catalog files): `cmd_list` prints nothing.
- CLI: `run_ai_rizz list` after init matches `list --all` when nothing installed.

### Test Infrastructure

- Framework: shunit2 (`shunit2` at repo root), helpers in `tests/common.sh`
- Test location: `tests/integration/functions/`, `tests/integration/`
- Conventions: `test_<description>()` in `test_*.test.sh`; function tests source `ai-rizz` and call `cmd_*`
- New test files: none (cases added to existing suites)

## Implementation Plan

### 1. `cmd_list` empty-inventory detection — executable

- Files: `ai-rizz`

1. Stub tests: `test_list_nothing_installed_shows_full_catalog` in `test_list_display.test.sh`; `test_list_fresh_init_shows_catalog` in `test_cli_list_sync.test.sh`
2. Stub interface: none (logic inside `cmd_list`)
3. Write tests and run red: assert catalog + no footer when nothing installed; assertEquals vs `--all`
4. Write code and run green: after flag parse, scan active manifests; if no entries, set `cl_show_all=true` before listing loop

### 2. Docs and persistent patterns — prose/policy

- Files: `docs/user-guide/commands/list.md`, `docs/user-guide/getting-started.md`, `memory-bank/systemPatterns.md`
- No tests: prose/policy artifact

1. Document auto-catalog on empty inventory
2. Getting-started: `ai-rizz list` after init (not `--all`)
3. Surgical systemPatterns list-view update

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing manifest readers (`read_manifest_entries`, `is_mode_active`)
- Prior list inventory default (#51)

## Challenges & Mitigations

- Distinguish empty inventory vs empty source catalog: manifest scan only affects show-all; empty repo still has nothing to list.
- Dual-mode / global-only contexts: scan all *active* manifests, not just one mode.

## Pre-Mortem

- Wrong empty signal (footer heuristic): mitigated by manifest entry scan before listing.
- Regression on mixed inventory view: existing `test_list_default_hides_uninstalled_and_prints_footer` retains coverage.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight (retroactive — plan matched shipped work)
- [x] Build
- [ ] QA
- [ ] Reflect
- [ ] Archive

## Build Notes (completed 2026-08-26)

All implementation steps shipped in commit on `no-empty-list` (PR #53). Function test suite `test_list_display.test.sh`: 25/25 pass. CI on PR: ShellCheck, Unit Tests, Docs strict build — success.
