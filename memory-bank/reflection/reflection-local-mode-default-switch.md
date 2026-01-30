# Reflection: Make Hook-Based Ignore the Default Local Mode

**Task ID**: local-mode-default-switch  
**Complexity**: Level 2 (Simple Enhancement)  
**Date Completed**: 2026-01-29  
**Branch**: `local-mode-fix`

## Summary

Successfully changed ai-rizz's local mode default from git-exclude (`.git/info/exclude`) to hook-based mode (pre-commit hook). This change was driven by Cursor on Windows now respecting git's ignored state rather than just `.gitignore` presence, making the git-exclude technique ineffective.

**Implementation Approach**: Test-Driven Development (TDD)
- Updated tests first to reflect new behavior
- Implemented code changes
- Fixed discovered issue in lazy initialization path
- All 30 tests passing (23 unit + 7 integration)

## What Went Well

### TDD Process
- **Comprehensive test planning** upfront identified all affected test files and specific behaviors to test
- **Writing tests first** caught a critical bug in the lazy initialization path that wouldn't have been obvious otherwise
- **Test-first approach** gave confidence that the implementation was complete and correct

### Backwards Compatibility
- Successfully maintained backwards compatibility with `--hook-based-ignore` flag (now a no-op)
- Introduced `--git-exclude-ignore` flag for users who need the legacy behavior
- Mode switching logic worked correctly for users wanting to convert existing repos

### Code Organization
- Changes were localized to specific areas (cmd_init, lazy_init_mode, help text)
- Existing hook management functions (`setup_pre_commit_hook`, `remove_pre_commit_hook`) were reusable
- No architectural changes needed

### Problem-Solving
- When tests failed, used systematic troubleshooting (/shared/refresh) to identify root cause
- Discovered the lazy initialization path was the culprit - wouldn't have found this without comprehensive tests
- Fix was straightforward once root cause was identified

## Challenges Encountered

### Challenge 1: Hidden Lazy Initialization Path

**Issue**: 4 tests were failing in `test_initialization.test.sh` even though assertions appeared to pass.

**Root Cause**: The `lazy_init_mode()` function still used `setup_local_mode_excludes()` instead of the new default `setup_pre_commit_hook()`. This path is triggered when:
- User has only commit mode
- User runs `ai-rizz add rule --local`
- ai-rizz lazy-creates local mode

**Why It Was Hard to Find**:
- The lazy init path is not the primary initialization path
- Test output showed passing assertions but tests still failed
- Required systematic debugging to trace through the code

**Solution**: Updated `lazy_init_mode()` to call `setup_pre_commit_hook()` instead of `setup_local_mode_excludes()`

**Lesson**: Code paths that aren't the "happy path" need careful attention during refactoring

### Challenge 2: Test File Updates

**Issue**: Had to update tests across multiple files (4 unit test files + 2 integration test files)

**Why It Was Challenging**:
- Tests were distributed across multiple files
- Some tests tested git-exclude behavior specifically, others tested local mode in general
- Had to decide whether to update tests or use `--git-exclude-ignore` flag in test setup

**Solution**: 
- Tests that were specifically testing git-exclude behavior: Added `--git-exclude-ignore` flag
- Tests that were testing local mode in general: Updated to expect hook-based behavior
- This preserved test coverage for both modes

**Lesson**: When changing default behavior, consider whether tests are testing the feature or the default

## Lessons Learned

### 1. TDD Catches Edge Cases

Writing tests first for the new default behavior immediately revealed that:
- Lazy initialization path existed and needed updating
- Multiple test files were affected
- Both unit and integration tests needed updates

Without TDD, the lazy initialization bug would have been discovered much later, possibly by a user.

### 2. Default Changes Have Wide Impact

Changing a default affects:
- Direct initialization (primary path)
- Lazy initialization (secondary path)
- Re-initialization (mode switching)
- Test expectations across the entire test suite

**Key Insight**: When changing defaults, trace ALL code paths that could create or initialize the affected feature, not just the primary path.

### 3. Systematic Troubleshooting Works

When stuck with failing tests:
1. Step back and re-scope the problem
2. Map the system structure
3. Hypothesize potential causes
4. Systematically investigate with evidence
5. Fix based on confirmed root cause

This approach (via `/shared/refresh`) quickly identified the lazy initialization issue.

### 4. Backwards Compatibility Matters

Even for internal tools, maintaining backwards compatibility:
- Prevents breaking user scripts/workflows
- Allows gradual migration
- Reduces support burden

The `--hook-based-ignore` flag is now a no-op but prevents errors for users who have it in scripts.

## Process Improvements

### What Worked Well

1. **TDD Workflow**: Following strict TDD (tests → code → verify) caught bugs early
2. **Progressive Rule Loading**: Having clear phases (PLAN → BUILD → REFLECT) kept work organized
3. **Memory Bank**: Documenting plan, progress, and active context made it easy to resume work
4. **Systematic Troubleshooting**: The `/shared/refresh` command provided a structured debugging approach

### Potential Improvements

1. **Code Path Discovery**: Could add a step in PLAN phase to map all code paths that touch the feature being changed
2. **Test Impact Analysis**: When changing defaults, could add a checklist to identify all tests that might be affected
3. **Lazy Path Testing**: Could ensure lazy initialization paths are explicitly tested, not just implicitly covered

## Technical Improvements

### Code Quality

- Implementation was clean and localized
- No technical debt introduced
- All tests passing
- Help text updated

### Potential Future Enhancements

1. **Migration Path**: Could add a command to check current mode and recommend migration
2. **Mode Detection**: Could add `ai-rizz status` command to show current local mode (hook-based vs git-exclude)
3. **Performance**: Could consider lazy hook creation (only create hook when files would be staged)

### Documentation Updates Needed

- README should be updated to mention hook-based mode is now default
- Migration guide for existing users might be helpful
- Cursor Windows compatibility should be documented

## Next Steps

1. **Archive Task**: Run `/niko/archive` to finalize documentation
2. **Commit Changes**: Commit all changes with appropriate message
3. **Update Documentation**: Update README with new default behavior
4. **Consider PR**: If this is being shared, create PR with summary of changes

## Metrics

- **Files Changed**: 1 source file (`ai-rizz`) + 4 test files
- **Lines Changed**: ~50 lines modified/added
- **Test Coverage**: 30/30 tests passing (100%)
- **Time to Resolution**: Single session (with troubleshooting phase)
- **Critical Bugs Found**: 1 (lazy initialization path)
