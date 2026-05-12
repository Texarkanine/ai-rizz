# Task: macOS/BSD Cross-Platform Bug Fixes

* Task ID: mac-compat-bugs
* Complexity: Level 2
* Type: Bug fix (multi-component)

Fix three cross-platform bugs that break ai-rizz on macOS/BSD: GNU-only `find -printf` in completion, locale-sensitive `[A-Z]` character ranges that silently skip `.md` commands, and `find -empty -delete` removing the target root directory.

## Test Plan (TDD)

### Behaviors to Verify

- [Bug 1a] `completion.bash` rule completion: `find` on rules dir with `.mdc` files → basenames returned without `-printf`
- [Bug 1b] `completion.bash` rule completion: `find` on rules dir with `.md` files → basenames returned without `-printf`, uppercase excluded
- [Bug 1c] `completion.bash` ruleset completion: `find` on rulesets dir → directory basenames returned without `-printf`
- [Bug 2a] `ai-rizz` `copy_entry_to_target` line 4762: lowercase `.md` command files (e.g. `pr-feedback-judge.md`) → NOT matched by uppercase skip, correctly copied
- [Bug 2b] `ai-rizz` `copy_entry_to_target` line 4762: uppercase `.md` files (`README.md`, `CHANGELOG.md`) → matched by uppercase skip, correctly skipped
- [Bug 2c] `ai-rizz` ruleset command install line 4897: lowercase `.md` commands → NOT matched by uppercase skip
- [Bug 2d] `ai-rizz` ruleset command install line 4897: uppercase `.md` files → matched by uppercase skip
- [Bug 2e] `completion.bash` line 85: `grep -v` for uppercase filtering → works correctly under non-C locale
- [Bug 3] `sync_manifest_to_directory`: empty commands dir after file cleanup → directory itself NOT deleted
- [Edge case 1] Filenames starting with `a` (the one letter that accidentally passed before) → still work after fix
- [Edge case 2] Filenames with mixed case like `MyTool.md` → correctly skipped (uppercase-initial)

### Test Infrastructure

- Framework: shunit2 (bundled at repo root)
- Test location: `tests/integration/functions/`
- Conventions: `test_<description>()` functions; files named `test_<feature>.test.sh`; function-specific variable prefixes; `source_ai_rizz` to load implementation
- New test files: none — tests added to existing `test_command_sync.test.sh` and `test_ruleset_commands.test.sh`

### Test Placement

**Bug 2 (locale `[A-Z]`):** Add tests to `test_command_sync.test.sh` and `test_ruleset_commands.test.sh`:
- `test_lowercase_md_command_not_skipped_by_uppercase_filter` — creates a lowercase `.md` command, syncs, verifies it is deployed
- `test_uppercase_md_files_ignored_under_utf8_locale` — runs the existing uppercase skip logic under `LC_ALL=en_US.UTF-8` to verify uppercase files are still correctly filtered (regression guard)
- Existing `test_uppercase_md_files_ignored` in `test_ruleset_commands.test.sh` already covers the uppercase case for rulesets

**Bug 3 (empty-delete):** Add test to `test_sync_operations.test.sh`:
- `test_sync_does_not_delete_commands_root_dir` — creates commands dir, removes all command files, runs sync, verifies directory still exists

**Bug 1 (completion `-printf`):** `completion.bash` is a bash script using `_init_completion` and `COMPREPLY` — testing it requires a bash completion framework which the test suite doesn't have. The fix is mechanical (replacing `-printf "%f\n"` with `| sed 's|.*/||'`) and will be verified by code review + the locale fix also applying to the `grep -v` there.

## Implementation Plan

1. **Add `LC_ALL=C; export LC_ALL` to top of `ai-rizz`**
   - Files: `ai-rizz`
   - Changes: Add `LC_ALL=C` and `export LC_ALL` after the shebang/header comment block, before any logic. This makes all `[A-Z]`, `[a-z]`, etc. character ranges use byte-value ordering, immune to locale collation.

2. **Write failing tests for Bug 2 (locale-sensitive `[A-Z]`)**
   - Files: `tests/integration/functions/test_command_sync.test.sh`
   - Changes: Add `test_lowercase_md_command_not_skipped_by_uppercase_filter` — creates a lowercase `.md` file like `pr-feedback-judge.md`, adds it, verifies it lands in `.cursor/commands/`. This test would fail without the `LC_ALL=C` fix if run on a system with UTF-8 locale.

3. **Write failing test for Bug 3 (`find -empty -delete` removing root)**
   - Files: `tests/integration/functions/test_sync_operations.test.sh`
   - Changes: Add `test_sync_does_not_delete_commands_root_dir` — sets up a mode with commands, removes command files manually, runs sync, asserts the commands directory still exists.

4. **Fix Bug 3: Add `-mindepth 1` to `find -empty -delete`**
   - Files: `ai-rizz` line 4478
   - Changes: `find "${smtd_commands_dir}" -type d -empty -delete` → `find "${smtd_commands_dir}" -mindepth 1 -type d -empty -delete`

5. **Fix Bug 1: Replace `find -printf` with portable sed in `completion.bash`**
   - Files: `completion.bash` lines 84, 85, 95
   - Changes:
     - Line 84: `find ... -printf "%f\n" | sed 's/\.mdc$//'` → `find ... | sed -e 's|.*/||' -e 's/\.mdc$//'`
     - Line 85: `find ... -printf "%f\n" | grep -v '^[A-Z]' | sed 's/\.md$//'` → `find ... | sed 's|.*/||' | LC_ALL=C grep -v '^[A-Z]' | sed 's/\.md$//'`
     - Line 95: `find ... -printf "%f\n"` → `find ... | sed 's|.*/||'`

6. **Fix Bug 2e: Add `LC_ALL=C` to `grep -v '^[A-Z]'` in `completion.bash`**
   - Already addressed in step 5 above (`LC_ALL=C grep -v '^[A-Z]'`)

7. **Run all tests, verify everything passes**

## Technology Validation

No new technology - validation not required

## Dependencies

- None

## Challenges & Mitigations

- **`LC_ALL=C` at top of `ai-rizz`**: Could theoretically affect user-visible output (e.g. sorting, error messages). Mitigation: `ai-rizz` is a tool script, not a user-locale-sensitive application. Its output is programmatic, not prose-heavy. The `C` locale is standard practice for POSIX scripts that use character ranges.
- **`completion.bash` is bash, not POSIX sh**: The `LC_ALL=C` applied to `ai-rizz` doesn't help `completion.bash` since it's sourced separately by the user's shell. Mitigation: Use inline `LC_ALL=C` on the specific `grep` call.
- **Testing locale behavior in CI**: The test environment likely uses `C` locale already, so the bug wouldn't reproduce. Mitigation: The tests verify correct behavior regardless; the `LC_ALL=C` fix is defensive and correct by inspection.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Preflight
- [ ] Build
- [ ] QA
