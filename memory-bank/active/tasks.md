# Task: deinit-guard-or-remove-all

* Task ID: deinit-guard-or-remove-all
* Complexity: Level 2
* Type: simple enhancement

Replace `deinit --all` (wipes local+commit+global) with `deinit --both` (local+commit only). Remove the `--all`/`-a` footgun so project deinit cannot destroy global settings. Per [issue #42](https://github.com/Texarkanine/ai-rizz/issues/42).

## Test Plan (TDD)

### Behaviors to Verify

- `--both` removes local+commit: `cmd_deinit --both -y` with local and commit active → both project modes gone; target local/shared dirs removed
- `--both` preserves global: local+commit+global active → `cmd_deinit --both -y` → local/commit gone, global manifest and dirs remain
- `--all` rejected: `cmd_deinit --all -y` → non-zero exit / unknown-argument error; modes untouched
- `-a` rejected: same as `--all`
- `--both` with only one project mode: still succeeds (idempotent for missing sibling mode)
- `--both -y` skips confirmation: exit 0, no interactive prompt required
- Interactive multi-mode prompt offers `both` not `all`: empty/unflagged deinit with multiple modes → prompt text includes `both`, not `all`
- Single-mode flags unchanged: `--local` / `--commit` / `--global` still remove only that mode
- CLI parity: `ai-rizz deinit --both -y` matches function-level behavior (local+commit removed)

### Edge Cases

- No modes active + `--both -y` → succeeds (idempotent; no crash)
- `AI_RIZZ_MODE=both` → treated as `--both` when no flag given
- `AI_RIZZ_MODE=all` → ignored (not accepted); does not wipe global
- Unflagged deinit with only global active → still auto-selects global (existing behavior)
- Manifest-integrity error text that currently suggests `deinit --all` → updated to `deinit --both` (and `--global` if full wipe is still needed)

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh` / `source_ai_rizz` / `run_ai_rizz`
- Test location: `tests/integration/functions/` (direct `cmd_*`) and `tests/integration/` (CLI)
- Conventions: `test_<feature>.test.sh`, `test_<description>()`; run with `make test` or suite path
- New test files: none — extend existing suites

### Test File Mapping

| Behavior | File | Action |
|----------|------|--------|
| `--both` removes local+commit; `-y` skips prompt; single-mode `--both` | `tests/integration/functions/test_deinit_modes.test.sh` | Rename/retarget `test_deinit_all_*` → `test_deinit_both_*`; call `--both` |
| `--both` preserves global | same | **Add** new test with global initialized; assert global separately (`assert_no_modes_exist` only checks local+commit manifests) |
| `--all` / `-a` rejected | same | **Add** rejection tests |
| Interactive prompt mentions `both` | same (+ CLI suite grep) | Update assertions that match `all` in prompt |
| CLI `--both` dual-mode cleanup | `tests/integration/test_cli_deinit.test.sh` | Retarget `test_deinit_all_modes` and related `--all` calls |
| Env fallback `AI_RIZZ_MODE` | `tests/integration/test_envvar_fallbacks.test.sh` | Only if `all`/`both` covered; add/adjust if present |

## Implementation Plan

1. **Failing tests for `--both` + `--all` rejection**
   - Files: `tests/integration/functions/test_deinit_modes.test.sh`, `tests/integration/test_cli_deinit.test.sh`
   - Changes: Convert existing `--all` success tests to `--both` expectations; add global-preservation and `--all`/`-a` rejection cases; update prompt greps from `all` → `both` where appropriate. Run suites — expect fail until implementation.

2. **Implement `cmd_deinit` flag surface**
   - Files: `ai-rizz` (`cmd_deinit`, doc comment ~3008–3011)
   - Changes:
     - Parse `--both` / `-b` → `cd_mode="both"` (short `-b` for parity with `-l`/`-c`/`-g`)
     - Remove `--all`/`-a` case (fall through to unknown argument)
     - Case `both`: set `cd_remove_local` + `cd_remove_commit` only (not global)
     - Validation + error strings: accept `both`, reject `all` with actionable hint (`--both` for project modes; `--global` separately)
     - Interactive prompt: `local/commit/global/both`; typed `all` hits the same invalid-mode path with that hint
     - No-modes default: `both` (was `all`) for project-scoped idempotence
     - `AI_RIZZ_MODE`: accept `both`; stop accepting `all`

3. **Update actionable error that recommends `deinit --all`**
   - Files: `ai-rizz` (`show_manifest_integrity_error` Option 3 ~2178)
   - Changes: Option 3 becomes `ai-rizz deinit --both -y && ai-rizz init` (this error is about divergent local/commit manifests — wiping global was never appropriate)

4. **Docs + help**
   - Files: `docs/user-guide/commands/init-deinit.md`; `ai-rizz` `cmd_help` deinit options; `docs/user-guide/commands/index.md` help mirror
   - Changes: Document `--both`/`-b` under **deinit options** (not general Mode options); describe “local + commit only, not global”; remove `--all`/`-a`

5. **Shell completion**
   - Files: `completion.bash`
   - Changes: Add `deinit` branch completing `--local -l --commit -c --global -g --both -b -y` (deinit currently has no flag completion)

6. **Green + full suite**
   - Run targeted deinit suites, then `make test`

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing `cmd_deinit` removal paths for local/commit/global (reuse; no new cleanup logic)
- Existing test helpers: `assert_no_modes_exist`, `assert_local_mode_exists`, `is_mode_active`, global init helpers in other suites
- Global-preservation test needs a pattern for initializing global in temp HOME (copy from `test_skill_sync.test.sh` / `test_global_*` suites)

## Challenges & Mitigations

- **Global test setup in deinit suites**: Function suite may not currently init global. Mitigation: reuse `HOME` override / `cmd_init --global` patterns from `tests/integration/functions/test_global_mode_detection.test.sh` or skill sync suite.
- **`--all` references outside `cmd_deinit`**: Error text at ~2178 and docs/tests will break or mislead if left stale. Mitigation: grep-driven sweep in step 3–4; plan includes both.
- **Interactive prompt / env `all`**: Users or scripts may still type `all`. Mitigation: reject with clear invalid-mode / unknown-argument message pointing at `--both` and `--global`.
- **Short flag `-b`**: Issue names only `--both`. Mitigation: add `-b` for consistency with other mode shorts; document both.

## Pre-Mortem

- **Plan fails because “remove --all” was interpreted as keep `--all` but exclude global**: That would leave a differently named footgun. Plan response: `--all`/`-a` must error; only `--both` aggregates project modes; full wipe = `--both` then `--global` (or vice versa).
- **Plan fails because tests only cover dual local+commit and never prove global survival**: Already covered by dedicated global-preservation behavior + test mapping row.
- **Plan fails by changing `select_mode()` or other commands’ `--all`**: Out of scope; only `cmd_deinit` (and docs/completion/errors that mention deinit `--all`). Challenge on reference sweep covers this.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [x] Build
- [x] QA

## Preflight Amendments

- Global-preservation asserts must not rely on `assert_no_modes_exist` alone (helper ignores global).
- `--both`/`-b` belongs under deinit-specific help/docs options, not the shared Mode options list.
- Invalid `all` (flag, prompt, or env) should surface an actionable hint toward `--both` / `--global`.
- Integrity Option 3 → `--both` is the correct project reset (not a full-machine wipe).
