# Reflection: Global Mode + Command Support

**Task ID**: global-mode-command-support
**Complexity**: Level 4 (Architectural change with multiple components)
**Duration**: Single day (2026-01-25)
**PR**: https://github.com/Texarkanine/ai-rizz/pull/15
**Final Status**: All 31 tests pass, draft PR ready for review

---

## Summary

This task added a third mode (`--global`) to ai-rizz and unified command (`*.md`) handling across all modes. A critical bug (cache isolation) was discovered during implementation and fixed before PR submission.

**Scope**:
- 7 implementation phases
- 8 new test files (12 tests for cache isolation alone)
- ~1100 lines of changes across 7 files
- 3 creative phase design documents

---

## What Went Well

### 1. TDD Approach Proved Valuable

Following strict TDD (tests first, then implementation) caught issues early and provided confidence throughout. The test suite grew to 31 tests, all passing before PR submission.

**Example**: The cache isolation bug was caught because tests for global mode operations failed when `GLOBAL_REPO_DIR` wasn't properly set.

### 2. Creative Phase Design Decisions

The creative phase exploration for cache isolation (Option 2E: Gated Cross-Mode Operations) was well-reasoned. Multiple options were evaluated with clear pros/cons, leading to a solution that:
- Preserved the core local ↔ commit transition feature
- Fixed the bug with minimal refactoring
- Used simple, deterministic naming (`_ai-rizz.global`)

### 3. Phased Implementation

Breaking the work into 7 phases made the large architectural change manageable:
1. Global Mode Infrastructure
2. Command Support Infrastructure
3. List Display Updates
4. Mode Transition Warnings
5. Deinit and Cleanup
6. Global-Only Context
7. Cache Isolation Bug Fix

Each phase was independently testable and could be committed atomically.

### 4. Design Evolution Was Embraced

**Original assumption**: Commands can't have local mode because Cursor has no `.cursor/commands/local/` split.

**Reality**: Subdirectories in `.cursor/commands/` work fine. The user's 2+ months real-world validation enabled a massive simplification - deleted all command/ruleset restrictions.

The willingness to challenge assumptions led to a cleaner, more uniform architecture.

### 5. Bug Discovery Before Merge

The cache isolation bug was discovered during Phase 6 testing, before the PR was merged. This validates the value of comprehensive testing even on "complete" features.

---

## Challenges Encountered

### 1. Cache Isolation Bug

**Problem**: Two related issues in global mode:
- `get_repo_dir()` used `basename $(pwd)` when outside git repos → different caches for same global mode
- Single `REPO_DIR` variable couldn't represent both global and local/commit source repos

**Root Cause**: The architectural assumption of "one repo per session" was embedded throughout the codebase. Adding global mode (which can coexist with local/commit and use a different source repo) violated this assumption.

**Resolution**: Added `GLOBAL_REPO_DIR` as a separate variable with fixed cache path `_ai-rizz.global`.

### 2. Test Infrastructure Updates

The existing test setup (`source_ai_rizz` in `common.sh`) assumed a single `REPO_DIR`. Global mode testing required:
- Overriding `get_global_repo_dir()` to return test paths
- Setting `GLOBAL_REPO_DIR` in test setup
- Adding `sync_global_repo()` mock

### 3. repos_match() Initial Bug

The initial implementation of `repos_match()` compared `SOURCE_REPO` with `get_global_source_repo()`. But `SOURCE_REPO` is overwritten by `parse_manifest_metadata()` for each manifest, so after parsing global manifest, both values were the same!

**Fix**: Created `get_local_commit_source_repo()` to read directly from manifest files rather than relying on cached variables.

### 4. Scope Creep Management

The task grew from "add global mode + command support" to include:
- Mode transition warnings
- Global-only context (outside git repos)
- Help documentation updates
- Cache isolation bug fix

Each addition was justified but required discipline to complete the full scope.

---

## Lessons Learned

### Technical Lessons

1. **Audit shared state when adding modes**: When adding a new "dimension" (like global mode), systematically review all cached/shared state. The `REPO_DIR` assumption was deeply embedded.

2. **Read from source when comparing**: When comparing values that may be cached, read from the source (manifest files) rather than relying on potentially-stale cached variables.

3. **Test infrastructure needs to evolve**: As the system grows, test infrastructure (`common.sh`) needs corresponding updates. Don't assume existing mocks cover new features.

4. **Fixed paths for global state**: Global/user-wide features should use deterministic paths that don't depend on current directory or context.

### Process Lessons

1. **Challenge assumptions early**: The "commands can't have local mode" assumption was wrong. Earlier validation would have simplified the initial design.

2. **Creative phase pays off**: The structured creative phase for cache isolation led to a well-reasoned solution. The Option 2E design document served as implementation spec.

3. **Bug discovery is success**: Finding the cache isolation bug during testing (not in production) validates the investment in comprehensive tests.

4. **Scope management**: Even with phased implementation, scope grew significantly. Consider breaking large tasks into separate PRs.

---

## Process Improvements

### For Future Architectural Changes

1. **State Audit Checklist**: When adding modes/dimensions, create explicit checklist:
   - [ ] Global variables (like `REPO_DIR`)
   - [ ] Cached metadata
   - [ ] Path computation functions
   - [ ] Test infrastructure assumptions

2. **Earlier Integration Testing**: Add tests for cross-mode scenarios earlier (e.g., "global and local both active with different repos").

3. **PR Size Limits**: Consider splitting large features into multiple PRs (e.g., separate PR for cache isolation fix).

### For TDD Process

1. **Test infrastructure first**: When adding new test scenarios (like global mode outside git), update test infrastructure before writing feature code.

2. **Test for what shouldn't work**: Add tests for invalid scenarios (e.g., "global mode should not use PWD-based cache name").

---

## Technical Improvements Made

### Code Quality

- Added comprehensive function documentation with Globals, Arguments, Outputs, Returns
- Used consistent variable prefixes for function scope (`ggrd_`, `rm_`, etc.)
- Kept backward compatibility (optional `repo_dir` parameter in `check_repository_item()`)

### Architecture

- Separated concerns: `GLOBAL_REPO_DIR` vs `REPO_DIR`
- Mode-aware helper functions: `get_repo_dir_for_mode()`, `get_local_commit_source_repo()`
- Fixed naming convention: `_ai-rizz.global` cannot conflict with git repo names

### Testing

- 8 new test files covering all new functionality
- 12 dedicated tests for cache isolation
- Updated test infrastructure for global mode support
- All 31 tests pass

---

## Metrics

| Metric | Value |
|--------|-------|
| Total phases | 7 |
| New test files | 8 |
| Tests added | ~50 new tests |
| Final test count | 31 (24 unit + 7 integration) |
| Lines changed | ~1100 |
| Files modified | 7 |
| Creative docs | 3 |
| Bugs caught | 1 (critical - cache isolation) |
| Design options evaluated | 5 (for cache isolation) |

---

## Next Steps

1. **PR Review**: Draft PR ready at https://github.com/Texarkanine/ai-rizz/pull/15
2. **Manual Testing**: Complete remaining manual test items:
   - [ ] Manual testing of global mode initialization
   - [ ] Manual testing of commands in local mode
   - [ ] Manual testing outside git repository
3. **Merge**: After review approval

---

## Conclusion

This was a successful Level 4 implementation that delivered a significant architectural enhancement (three-mode system + unified command support) while maintaining backward compatibility. The TDD approach and structured creative phase proved valuable, particularly in discovering and fixing the cache isolation bug before merge.

The key insight is that adding new "modes" or "dimensions" to a system requires systematic audit of all shared state assumptions. The `REPO_DIR` assumption was so fundamental that it wasn't initially questioned, leading to a bug that was only caught through comprehensive testing.

**Recommendation**: For future mode-like additions, create an explicit "shared state audit" as part of the design phase.
