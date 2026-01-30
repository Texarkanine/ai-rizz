# TASK ARCHIVE: Make Hook-Based Ignore the Default Local Mode

## METADATA

- **Task ID**: local-mode-default-switch
- **Complexity**: Level 2 (Simple Enhancement)
- **Start Date**: 2026-01-29
- **Completion Date**: 2026-01-29
- **Branch**: `local-mode-fix`
- **Status**: Complete

## SUMMARY

Changed ai-rizz's local mode default behavior from git-exclude (`.git/info/exclude`) to hook-based mode (pre-commit hook). This change addresses a compatibility issue where Cursor on Windows now respects git's ignored state rather than just `.gitignore` presence, making the git-exclude technique ineffective for Windows users.

The implementation maintained full backwards compatibility by:
- Introducing a new `--git-exclude-ignore` flag for users who need the legacy behavior
- Keeping the `--hook-based-ignore` flag as a no-op for existing scripts
- Supporting mode switching via re-initialization

## REQUIREMENTS

### Problem Statement
Cursor on Windows now ignores files based on git ignored state, not just .gitignore presence. This means the `.git/info/exclude` exclusion technique doesn't work for Cursor users on Windows.

### Success Criteria
1. ✅ Hook-based mode is default for `init --local`
2. ✅ `--git-exclude-ignore` flag available for legacy behavior
3. ✅ `--hook-based-ignore` flag accepted as no-op (backwards compatibility)
4. ✅ Users can run `init --local` to convert existing git-exclude mode to hook-based
5. ✅ All existing tests updated for new defaults
6. ✅ New tests for `--git-exclude-ignore` flag
7. ✅ Help text updated with correct flag names

## IMPLEMENTATION

### Code Changes

**File**: `ai-rizz` (main script)

1. **Changed default flag value** (line ~2491):
   ```bash
   # Before:
   ci_hook_based=false
   
   # After:
   ci_hook_based=true
   ```

2. **Added `--git-exclude-ignore` flag** (line ~2510):
   ```bash
   --git-exclude-ignore)
       ci_hook_based=false
       shift
       ;;
   ```

3. **Made `--hook-based-ignore` a no-op** (line ~2512):
   ```bash
   --hook-based-ignore)
       # No-op: hook-based is now the default
       # Flag kept for backwards compatibility
       shift
       ;;
   ```

4. **Updated lazy initialization** (line ~1685):
   ```bash
   # Before:
   setup_local_mode_excludes "${lim_target_dir}"
   
   # After:
   setup_pre_commit_hook "${lim_target_dir}"
   ```

5. **Fixed "same mode re-init" logic** (line ~2640):
   - Updated to properly handle hook-based mode during idempotent re-initialization
   - Ensures correct setup function is called based on `ci_hook_based` flag

6. **Updated help text** (line ~4588):
   ```bash
   # Before:
   --hook-based-ignore    local mode: use pre-commit hook instead of .git/info/exclude
   
   # After:
   --git-exclude-ignore   local mode: use .git/info/exclude (legacy mode)
                          Default is pre-commit hook (recommended for Cursor on Windows)
   ```

### Test Updates

**Unit Tests** (4 files):
- `test_hook_based_local_mode.test.sh` - Updated existing tests, added 2 new tests for flags
- `test_initialization.test.sh` - Updated assertions to expect hook-based behavior
- `test_deinit_modes.test.sh` - Updated tests using `--git-exclude-ignore` flag
- `tests/common.sh` - No changes needed (assertion helpers work for both modes)

**Integration Tests** (2 files):
- `test_cli_init.test.sh` - Updated to expect hook-based behavior by default
- `test_cli_deinit.test.sh` - Updated to expect hook-based behavior in preserved local mode

### Approach

Followed strict Test-Driven Development (TDD):
1. **Phase 1**: Updated existing tests to reflect new behavior
2. **Phase 2**: Ran tests to verify they fail (confirming tests are testing the right thing)
3. **Phase 3**: Implemented code changes
4. **Phase 4**: Ran tests to verify they pass
5. **Troubleshooting**: Used systematic debugging to find lazy initialization bug

## TESTING

### Test Results
- **Unit Tests**: 23/23 passed
- **Integration Tests**: 7/7 passed
- **Total**: 30/30 passed (100% success rate)

### Critical Bug Found During Testing

**Issue**: 4 tests failing despite assertions appearing to pass

**Root Cause**: The `lazy_init_mode()` function was still using `setup_local_mode_excludes()` instead of the new default `setup_pre_commit_hook()`. This path is triggered when:
- User has only commit mode initialized
- User runs `ai-rizz add rule --local`
- ai-rizz lazy-creates local mode

**Fix**: Updated `lazy_init_mode()` to use `setup_pre_commit_hook()` for local mode initialization

**Lesson**: Code paths that aren't the "happy path" need careful attention during refactoring. Comprehensive testing caught this edge case that would have been missed in manual testing.

### Test Coverage

**New Tests Added**:
1. `test_git_exclude_ignore_flag_creates_git_exclude` - Verifies new `--git-exclude-ignore` flag works
2. `test_hook_based_ignore_flag_is_noop` - Verifies legacy `--hook-based-ignore` flag doesn't error

**Updated Tests**:
- All local mode initialization tests now expect hook-based behavior by default
- Tests that specifically test git-exclude behavior use `--git-exclude-ignore` flag
- Mode switching tests updated to use correct flags

## LESSONS LEARNED

### Key Takeaways

1. **TDD Catches Edge Cases**: Writing tests first revealed the lazy initialization bug that wouldn't have been obvious otherwise

2. **Default Changes Have Wide Impact**: Changing a default affects:
   - Primary initialization path
   - Lazy initialization (secondary path)
   - Re-initialization (mode switching)
   - Test expectations across the entire test suite

3. **Systematic Troubleshooting Works**: Using structured debugging approach (via `/shared/refresh`) quickly identified root cause when tests failed

4. **Backwards Compatibility Matters**: Even for internal tools, maintaining backwards compatibility prevents breaking user scripts and reduces support burden

### Process Improvements

**What Worked Well**:
- TDD workflow caught bugs early
- Progressive phases (PLAN → BUILD → REFLECT → ARCHIVE) kept work organized
- Memory Bank documentation made it easy to track progress and resume work
- Systematic troubleshooting provided structured debugging approach

**Potential Improvements**:
- Add explicit code path mapping in PLAN phase
- Create checklist for identifying all tests affected by default changes
- Ensure lazy initialization paths are explicitly tested

### Technical Insights

**Code Quality**:
- Implementation was clean and localized (~50 lines changed)
- No technical debt introduced
- All tests passing
- Documentation updated

**Future Enhancements**:
- Migration helper command to check current mode and recommend migration
- `ai-rizz status` command to show current local mode
- Performance optimization: lazy hook creation (only create when needed)

## REFERENCES

- **Reflection Document**: `memory-bank/reflection/reflection-local-mode-default-switch.md`
- **Task Plan**: Documented in this archive (originally in `memory-bank/tasks.md`)
- **Branch**: `local-mode-fix`

## FILES CHANGED

### Source Code (1 file)
- `ai-rizz` - Main script (~50 lines modified/added)

### Tests (6 files)
- `tests/unit/test_hook_based_local_mode.test.sh` - Updated + 2 new tests
- `tests/unit/test_initialization.test.sh` - Updated assertions
- `tests/unit/test_deinit_modes.test.sh` - Updated test setup
- `tests/integration/test_cli_init.test.sh` - Updated assertions
- `tests/integration/test_cli_deinit.test.sh` - Updated assertions

### Documentation (1 file)
- Help text updated in `ai-rizz` script

## IMPACT

### User Impact
- **Windows Cursor Users**: Local mode now works correctly (no longer need workarounds)
- **Existing Users**: Can continue using git-exclude mode via `--git-exclude-ignore` flag
- **Scripts**: Scripts using `--hook-based-ignore` continue working (no-op)

### Codebase Impact
- Minimal changes (~50 lines)
- No breaking changes
- Full backwards compatibility maintained
- All tests passing

### Future Maintenance
- Hook-based mode is now the recommended default
- Git-exclude mode is legacy but still supported
- Clear migration path for existing users
