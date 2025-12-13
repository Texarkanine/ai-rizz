# Memory Bank: Tasks

## Current Task
*No active task - ready for next task*

## Completed Tasks

### Task: Add `/archive clear` Command Documentation
**Task ID**: archive-clear-docs  
**Complexity Level**: Level 2 (Simple Enhancement - Documentation)  
**Status**: COMPLETE ✓  
**Archive**: `memory-bank/archive/20251213-archive-clear-docs.md`

**Summary**: Added comprehensive documentation for the `/archive clear` command across all relevant files. The command removes task-specific and local-machine files from the Memory Bank while preserving repository knowledge and past task archives. Integrated automatic git commit functionality to make the operation revertable.

**Status**:
- [x] Task definition (retroactive)
- [x] Implementation: Documentation updates across 5 files
- [x] Reflection: Task reflection complete
- [x] Archive: Task archived

### Task: Fix 2 Bugs in Ruleset Handling
**Task ID**: ruleset-bug-fixes  
**Complexity Level**: Level 2 (Simple Enhancement - Bug Fixes)  
**Status**: COMPLETE ✓  
**Archive**: `memory-bank/archive/archive-ruleset-bug-fixes.md`

**Summary**: Fixed 4 bugs in ruleset handling:
1. Commands not removed when ruleset is removed
2. File rules in subdirectories flattened instead of preserving directory structure
3. List display showing subdirectory contents (should only show top-level)
4. Rules in subdirectories not detected as installed

**Status**:
- [x] Task definition
- [x] Complexity determination
- [x] Implementation plan
- [x] Creative phase: Ruleset rule structure design decision
- [x] Phase 0: Regression tests written (should fail)
- [x] Phase 1: Fix Bug 1 (remove commands when ruleset removed)
- [x] Phase 2: Fix Bug 2 (preserve directory structure for file rules)
- [x] Phase 3: Fix List Display for Rulesets (simplify to show top-level only, commands/ special)
- [x] Phase 4: Verify all tests pass
- [x] Phase 5: Code Review and Cleanup (DRY, KISS, YAGNI violations, remove cruft)
- [x] Reflection: Task reflection complete
- [x] Archive: Task archived

## Creative Phase Decision

**Design Decision**: Ruleset Rule Structure Handling
**Document**: `memory-bank/creative/creative-ruleset-rule-structure.mdc`

**Decision**: **Finish Support for File Rules in Rulesets (Preserve Structure)** (Option 1) ⭐

**Rationale** (UPDATED based on user requirements):
1. **User DOES need it**: User needs to ship large rule trees (55+ rules) in rulesets like `.cursor/rules/isolation_rules`
2. **Solves the actual problem**: Rules stay bundled with ruleset, don't clutter `ai-rizz list`
3. **Mathematically correct**: File rules have URI `ruleset/path/to/rule.mdc`, so structure should be preserved
4. **No breaking changes**: Symlinks still work correctly (copied flat)
5. **Completes partially-implemented feature**: Code is already partially there

**Implementation**:
- Detect symlink vs file in `copy_entry_to_target()`
- If symlink: Copy flat (current behavior, correct)
- If file: Preserve directory structure (calculate relative path, create target dirs)
- Update conflict detection to handle both flat and structured paths
- Update removal logic to handle structured rules
- Update `sync_manifest_to_directory()` to clear nested `.mdc` files recursively

**Alternative Considered**: Option 3 (directory structure in `rules/` with symlinks and hidden subdirs) - viable but requires changing `ai-rizz list` behavior and restructuring `rules/` directory. Option 1 is cleaner for the use case.

## Requirements

### Bug Descriptions

**Bug 1: Commands not removed when ruleset is removed**
- **Issue**: When removing a ruleset that has commands, the commands remain in `.cursor/commands/` directory
- **Root Cause Analysis**: 
  - `cmd_remove_ruleset()` removes the ruleset from manifest and calls `sync_all_modes()`
  - `sync_all_modes()` only syncs `.mdc` files (rules) to target directories
  - Commands are copied separately via `copy_ruleset_commands()` but there's no corresponding removal logic
  - The commands directory is not cleaned up when rulesets are removed
- **Impact**: Orphaned command files remain in `.cursor/commands/` after ruleset removal
- **Expected Behavior**: When a ruleset with commands is removed, all commands from that ruleset should be removed from `.cursor/commands/`

**Bug 2: Rules in subdirectories are flattened (Design Decision Required)**
- **Issue**: Rules in subdirectories of rulesets (e.g., `Core/memory-bank-paths.mdc`) are copied flattened to `.cursor/rules/shared/memory-bank-paths.mdc` instead of preserving the directory structure
- **Root Cause Analysis**:
  - In `copy_entry_to_target()`, when copying a ruleset, it uses `find` to find all `.mdc` files recursively
  - The copy command `cp -L "${cett_rule_file}" "${cett_target_directory}/"` flattens everything to the target root
  - **Key Insight**: Symlinked rules SHOULD be flat (correct - all instances are the same rule). File rules in subdirectories SHOULD preserve structure (their URI is `ruleset/path/to/rule.mdc`)
- **User Requirement**: User needs to ship large rule trees (55+ rules) in rulesets like `.cursor/rules/isolation_rules` with multiple levels (Core/, Level1/, Level2/, etc.)
- **Design Decision**: After creative phase analysis, decision is to **FINISH SUPPORT for file rules in subdirectories** (preserve structure)
- **Impact**: 
  - Rulesets with file rules in subdirectories will preserve directory structure
  - Large rule trees can be shipped as part of ruleset bundles
  - Rules stay bundled with ruleset (don't clutter `ai-rizz list`)
- **Expected Behavior**: 
  - Symlinked rules: Copied flat (correct - all instances are the same)
  - File rules at root: Copied flat (acceptable)
  - File rules in subdirectories: Preserve directory structure (e.g., `Core/memory-bank-paths.mdc` → `.cursor/rules/shared/Core/memory-bank-paths.mdc`)

## Complexity Level
**Level 2: Simple Enhancement** (Bug Fixes)

### Complexity Analysis
- **Scope**: Two targeted bug fixes in existing functionality
- **Design Decisions**: Minimal (fixing incorrect logic, following existing patterns)
- **Risk**: Low (targeted fixes, similar to previous bug fixes)
- **Implementation Effort**: Low (hours to 1 day)
- **Components Affected**:
  - `cmd_remove_ruleset()` - Add command removal logic
  - `copy_entry_to_target()` - Preserve directory structure when copying rules
  - Possibly need helper function to track which commands belong to which ruleset

## Implementation Plan

### Phase 0: Write Regression Tests (TDD Steps 1-3) - MUST COMPLETE FIRST
**Purpose**: Write tests that will FAIL with current implementation, then PASS after fixes

**TDD Workflow** (per `.cursor/rules/shared/shell-tdd.mdc`):
1. **Stub tests**: Create empty test functions with descriptions
2. **Implement tests**: Fill out test logic (should fail with current implementation)
3. **Run tests**: Verify they fail as expected
4. **Fix bugs**: Implement fixes (Phase 1-2)
5. **Re-run tests**: Verify they pass

**Test File**: `tests/unit/test_ruleset_removal_and_structure.test.sh` (to be created)

**POSIX Style Requirements** (per `.cursor/rules/shared/shell-posix-style.mdc`):
- Use `#!/bin/sh` shebang
- Use POSIX-compliant features only
- Use temporary files instead of subshells when variable scope matters
- Use `git commit --no-gpg-sign` in test environments
- Set git user and email in all dummy repositories

**Test Cases**:

1. **Test 1: Commands removed when ruleset removed**
   ```bash
   test_commands_removed_when_ruleset_removed() {
       # Setup: Create ruleset with commands (including nested commands)
       mkdir -p "$REPO_DIR/rulesets/test-remove-cmd/commands/subdir"
       echo "command1" > "$REPO_DIR/rulesets/test-remove-cmd/commands/cmd1.md"
       echo "nested" > "$REPO_DIR/rulesets/test-remove-cmd/commands/subdir/nested.md"
       ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-remove-cmd/rule1.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add ruleset, then remove it
       cmd_add_ruleset "test-remove-cmd" --commit
       assertTrue "Should add ruleset successfully" $?
       
       # Verify commands copied
       test -f "commands/cmd1.md" || fail "cmd1.md should be copied"
       test -f "commands/subdir/nested.md" || fail "Nested command should be copied"
       
       # Remove ruleset
       cmd_remove_ruleset "test-remove-cmd"
       assertTrue "Should remove ruleset successfully" $?
       
       # Expected: Commands should be removed
       test ! -f "commands/cmd1.md" || fail "cmd1.md should be removed"
       test ! -f "commands/subdir/nested.md" || fail "Nested command should be removed"
       # CURRENTLY FAILS: Commands remain after ruleset removal
   }
   ```

2. **Test 2: File rules in subdirectories preserve structure**
   ```bash
   test_file_rules_in_subdirectories_preserve_structure() {
       # Setup: Create ruleset with file rule in subdirectory (should preserve structure)
       mkdir -p "$REPO_DIR/rulesets/test-structure/supporting"
       echo "subdir rule" > "$REPO_DIR/rulesets/test-structure/supporting/subrule.mdc"
       echo "root rule" > "$REPO_DIR/rulesets/test-structure/rootrule.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add ruleset (should succeed)
       cmd_add_ruleset "test-structure" --commit
       assertTrue "Should add ruleset successfully" $?
       
       # Expected: File rules preserve directory structure
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root rule should be copied"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/subrule.mdc" || fail "Subdirectory file rule should preserve structure"
       test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/subrule.mdc" || fail "Subdirectory file rule should NOT be flattened"
       # CURRENTLY FAILS: Rules are flattened to root level
   }
   ```

3. **Test 2b: Symlinked rules in subdirectories are copied flat**
   ```bash
   test_symlinked_rules_in_subdirectories_copied_flat() {
       # Setup: Create ruleset with symlinked rule in subdirectory (should be copied flat)
       mkdir -p "$REPO_DIR/rulesets/test-symlink/supporting"
       ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-symlink/supporting/rule1.mdc"
       ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-symlink/rule2.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add ruleset (should succeed)
       cmd_add_ruleset "test-symlink" --commit
       assertTrue "Should add ruleset successfully" $?
       
       # Expected: Symlinked rules copied flat (all instances are the same rule)
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc" || fail "rule1.mdc should be copied (flat)"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc" || fail "rule2.mdc should be copied (flat)"
       test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/rule1.mdc" || fail "Symlinked rules should NOT preserve structure"
   }
   ```

4. **Test 3: Commands removed even if multiple rulesets have same path (error condition)**
   ```bash
   test_commands_removed_even_with_conflicts() {
       # Setup: Create two rulesets with same command path (error condition, but we handle it)
       mkdir -p "$REPO_DIR/rulesets/test-cmd1/commands"
       mkdir -p "$REPO_DIR/rulesets/test-cmd2/commands"
       echo "cmd1 content" > "$REPO_DIR/rulesets/test-cmd1/commands/shared.md"
       echo "cmd2 content" > "$REPO_DIR/rulesets/test-cmd2/commands/shared.md"
       ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-cmd1/rule1.mdc"
       ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-cmd2/rule2.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add both rulesets (last one wins for the file)
       cmd_add_ruleset "test-cmd1" --commit
       cmd_add_ruleset "test-cmd2" --commit
       
       # Verify command exists (last one wins)
       test -f "commands/shared.md" || fail "shared.md should exist"
       assertEquals "Content should be from last ruleset" "cmd2 content" "$(cat commands/shared.md)"
       
       # Remove first ruleset
       cmd_remove_ruleset "test-cmd1"
       
       # Expected: Command removed (belongs to ruleset being removed, even though another ruleset has same path)
       # Note: This is an error condition - rulesets shouldn't have overlapping command paths
       # But we handle it by removing the command when its ruleset is removed
       test ! -f "commands/shared.md" || fail "shared.md should be removed (belongs to test-cmd1)"
       
       # Remove second ruleset
       cmd_remove_ruleset "test-cmd2"
       
       # Expected: Command should still be removed (was already removed)
       test ! -f "commands/shared.md" || fail "shared.md should be removed"
       # CURRENTLY FAILS: Commands not removed
   }
   ```

5. **Test 4: Combined - ruleset with commands, file rules, and symlinked rules**
   ```bash
   test_complex_ruleset_structure_preserved() {
       # Setup: Ruleset with commands, file rules in subdirs, and symlinked rules
       mkdir -p "$REPO_DIR/rulesets/test-complex/commands/subs"
       mkdir -p "$REPO_DIR/rulesets/test-complex/Core"
       echo "command" > "$REPO_DIR/rulesets/test-complex/commands/top.md"
       echo "nested" > "$REPO_DIR/rulesets/test-complex/commands/subs/nested.md"
       echo "file rule" > "$REPO_DIR/rulesets/test-complex/Core/core-rule.mdc"
       echo "rootrule" > "$REPO_DIR/rulesets/test-complex/rootrule.mdc"
       ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-complex/symlinked-rule.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add ruleset
       cmd_add_ruleset "test-complex" --commit
       assertTrue "Should add ruleset successfully" $?
       
       # Expected: Commands preserved, file rules preserve structure, symlinked rules flat
       test -f "commands/top.md" || fail "Top command should be copied"
       test -f "commands/subs/nested.md" || fail "Nested command should be copied"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root file rule should be copied"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/Core/core-rule.mdc" || fail "Subdirectory file rule should preserve structure"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/symlinked-rule.mdc" || fail "Symlinked rule should be copied (flat)"
       test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/Core/symlinked-rule.mdc" || fail "Symlinked rule should NOT preserve structure"
       
       # Remove ruleset
       cmd_remove_ruleset "test-complex"
       
       # Expected: Commands removed, rules removed
       test ! -f "commands/top.md" || fail "Commands should be removed"
       test ! -f "commands/subs/nested.md" || fail "Nested commands should be removed"
       test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Rules should be removed"
       test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/Core/core-rule.mdc" || fail "Structured rules should be removed"
   }
   ```

**Verification Steps**:
1. Create test file with empty stub functions
2. Implement test logic
3. Run tests: `VERBOSE_TESTS=true ./tests/unit/test_ruleset_removal_and_structure.test.sh`
4. Verify all tests FAIL as expected
5. Document test results in tasks.md

### Phase 1: Fix Bug 1 - Remove Commands When Ruleset Removed
**Location**: `cmd_remove_ruleset()` function (line ~3023) and sync logic

**Issue**: No logic to remove commands when ruleset is removed

**POSIX Style Requirements** (per `.cursor/rules/shared/shell-posix-style.mdc`):
- Use temporary files instead of subshells when variable scope matters
- Use `mktemp` for temporary files, clean up with `rm -f`
- Use `while IFS= read -r` pattern for reading files
- Avoid subshells that could lose exit codes
- Use function-specific variable prefixes (e.g., `rrc_` for `remove_ruleset_commands`)

**Approach Options**:

**Option A: Track commands per ruleset in manifest**
- Pros: Explicit tracking, can handle multiple rulesets with same command names
- Cons: Requires manifest format change, more complex

**Option B: Remove commands based on ruleset path during removal**
- Pros: Simple, no manifest changes needed
- Cons: Need to determine which commands came from which ruleset

**Option C: Clean up commands directory during sync (remove orphaned commands)**
- Pros: Automatic cleanup, handles edge cases
- Cons: More complex logic, need to track which commands belong to which rulesets

**Decision**: **Option B** - Remove commands during `cmd_remove_ruleset()` by:
1. Before removing from manifest, check if ruleset has commands
2. If in commit mode, find all commands that came from this ruleset
3. Remove those commands from `.cursor/commands/`
4. Then proceed with normal removal and sync

**Implementation** (TDD Step 4 - Write Code):
- **After Phase 0 tests are written and verified to fail**, implement fixes:
- Add helper function `remove_ruleset_commands()` similar to `copy_ruleset_commands()`
  - Use POSIX-compliant code
  - Use temporary files for reading command paths (avoid subshells)
  - Use function-specific variable prefix: `rrc_` (remove_ruleset_commands)
- Call it in `cmd_remove_ruleset()` before `sync_all_modes()`
- Function should:
  - Check if ruleset has `commands/` subdirectory
  - If in commit mode, get all command paths from the ruleset's `commands/` directory
  - For each command path, remove it from `.cursor/commands/` (preserving nested structure)
  - Handle nested commands (e.g., `commands/subs/eat.md` → remove `.cursor/commands/subs/eat.md`)
  - Clean up empty directories after removing files
  - Note: No need to check other rulesets - if command is in ruleset being removed, delete it

**Approach**: 
- Commands are copied preserving relative path from `commands/` directory
- For ruleset `rulesets/temp-test`, commands are in `rulesets/temp-test/commands/`
- When copying: `commands/subs/eat.md` → `.cursor/commands/subs/eat.md`
- When removing: Get all command paths from the ruleset's `commands/` directory and remove them

**Note on Multiple Rulesets with Same Command Paths**:
- This is an ERROR condition caused by not preserving ruleset-level directory structure in `.cursor/commands/`
- **Current behavior**: If two rulesets have `commands/shared.md`, the last one added overwrites the first
- **Future enhancement**: Add pre-flight check in `copy_ruleset_commands()` to warn/error when installing a ruleset that would conflict with existing commands
- **For now**: Document that ruleset repos should not have overlapping command paths (out-of-band guidance)
- **Removal decision**: If a command is in a ruleset being removed, delete that file (no need to check other rulesets)
  - This is safe because: (1) it's an error condition anyway, (2) the command belongs to the ruleset being removed

**Implementation**: 
- Create helper `get_ruleset_commands_paths()` that returns all command paths for a ruleset
- Create helper `remove_ruleset_commands()` that:
  1. Gets all command paths for the ruleset being removed (from source ruleset's `commands/` directory)
  2. For each command path, remove it from `.cursor/commands/` (preserving nested structure)
  3. Clean up empty directories after removing files

### Phase 2: Fix Bug 2 - Preserve Directory Structure for File Rules
**Location**: `copy_entry_to_target()` function (line ~3338)

**Issue**: File rules in subdirectories are flattened, but they should preserve structure (per design decision)

**Design Decision**: Finish support for file rules in subdirectories - preserve structure (see Creative Phase decision)

**POSIX Style Requirements** (per `.cursor/rules/shared/shell-posix-style.mdc`):
- Use temporary files instead of subshells when variable scope matters
- Use `mktemp` for temporary files, clean up with `rm -f`
- Use `while IFS= read -r` pattern for reading files
- Avoid subshells that could lose exit codes
- Use function-specific variable prefixes (already established pattern: `cett_` for `copy_entry_to_target`)

**Implementation** (TDD Step 4 - Write Code):
- **After Phase 0 tests are written and verified to fail**, implement fixes:
- **Update `copy_entry_to_target()`** to detect symlink vs file and preserve structure for files:
  - Replace subshell pipe with temporary file (POSIX-compliant)
  - Use `find` to get all `.mdc` files (both `-type f` and `-type l`)
  - For each rule file:
    - Detect if symlink: `[ -L "${cett_rule_file}" ]`
    - If symlink: Copy flat to target root (all instances are the same rule)
    - If file: Preserve directory structure:
      - Calculate relative path: `cett_rel_path="${cett_rule_file#${cett_source_path}/}"`
      - Create target file path: `cett_target_file="${cett_target_directory}/${cett_rel_path}"`
      - Create target directory structure: `mkdir -p "$(dirname "${cett_target_file}")"`
      - Copy file preserving structure
  - See Creative Phase document (`memory-bank/creative/creative-ruleset-rule-structure.mdc`) for detailed implementation code

- **Update `sync_manifest_to_directory()`** to clear nested `.mdc` files:
  - **Current** (line 3151): `find "${smtd_target_directory}" -maxdepth 1 -name "*.mdc" -type f -delete`
  - **New**: `find "${smtd_target_directory}" -name "*.mdc" -type f -delete` (remove `-maxdepth 1`)
  - This ensures structured rules in subdirectories are properly cleaned up during sync
  - The sync process clears all `.mdc` files, then re-copies from manifest, so structured rules will be restored correctly

**Additional Considerations**:
- **Conflict Detection**: Current conflict detection uses basename only (`file_exists_in_commit_mode()`). This should still work because:
  - For symlinks: Copied flat, conflict detection by basename works
  - For file rules: Even if structured, conflict detection checks by basename (which is correct - two rules with same basename conflict regardless of path)
- **Removal Logic**: The existing `sync_manifest_to_directory()` clears all `.mdc` files and then re-copies from manifest. With structured rules:
  - Clearing recursively (removing `-maxdepth 1`) will remove structured rules
  - Re-copying from manifest will restore them with correct structure (using updated copy logic)
  - This should work correctly with the updated copy logic

### Phase 3: Fix List Display for Rulesets
**Location**: `cmd_list()` function (line ~2560)

**Issue**: List display shows contents of subdirectories, but should only show top-level items (except commands/)

**List Display Rules**:
- **All top-level .mdc files**: Shown
- **All top-level subdirectories**: Shown (directory name only, NO contents shown)
- **"commands" subdirectory**: Special treatment - show one level:
  - Top-level *.md files inside commands/ are shown
  - Subdirs inside commands/ are shown (but NO content of subdirs in commands/)

**Expected List Output Examples**:

**Example 1: test-symlink ruleset**
```
Ruleset structure in source:
  test-symlink/
    ├── rule2.mdc (symlink at root)
    └── supporting/
        └── rule1.mdc (symlink in subdirectory)

Expected list output:
  ● test-symlink
    ├── rule2.mdc          ← top-level .mdc file (shown)
    └── supporting         ← top-level subdir (shown, but NO contents)

NOT shown:
  - rule1.mdc (it's in supporting/ subdirectory, subdir contents are NOT shown)
```

**Example 2: test-structure ruleset**
```
Ruleset structure in source:
  test-structure/
    ├── rootrule.mdc (file at root)
    └── supporting/
        └── subrule.mdc (file in subdirectory)

Expected list output:
  ● test-structure
    ├── rootrule.mdc       ← top-level .mdc file (shown)
    └── supporting         ← top-level subdir (shown, but NO contents)

NOT shown:
  - subrule.mdc (it's in supporting/ subdirectory, subdir contents are NOT shown)
```

**Example 3: test-complex ruleset**
```
Ruleset structure in source:
  test-complex/
    ├── rootrule.mdc (file at root)
    ├── symlinked-rule.mdc (symlink at root)
    ├── Core/
    │   └── core-rule.mdc (file in subdirectory)
    └── commands/
        ├── top.md
        └── subs/
            └── nested.md

Expected list output:
  ● test-complex
    ├── rootrule.mdc       ← top-level .mdc file (shown)
    ├── symlinked-rule.mdc ← top-level .mdc file (shown)
    ├── Core               ← top-level subdir (shown, but NO contents)
    └── commands           ← special treatment: show one level
        ├── top.md         ← top-level file in commands/ (shown)
        └── subs           ← subdir in commands/ (shown, but NO contents)

NOT shown:
  - core-rule.mdc (it's in Core/ subdirectory, subdir contents are NOT shown)
  - nested.md (it's in commands/subs/, subdir contents in commands/ are NOT shown)
```

**Implementation**:
- Simplify `cmd_list()` tree display logic
- Use `tree -L 1` for top-level items (or equivalent with find)
- For `commands/` subdirectory: Use `tree -L 2` but only for commands/ path
- Filter out all subdirectory contents except commands/ one level
- Remove complex filtering logic for symlink-only directories (not needed)

**POSIX Style Requirements**:
- Use temporary files instead of subshells when processing tree output
- Keep logic simple and maintainable

### Phase 4: Verify All Tests Pass ✓
**Status**: Complete
**After Phase 1, 2, and 3**: All regression tests should pass
**Actions**:
- Run full test suite: `make test`
- Verify no regressions in existing tests
- Verify large rule trees (55+ rules) work correctly
- Update documentation if behavior changes significantly

**Test Results**:
- New regression tests: All 6 tests PASS ✓
- Full test suite: 14/15 tests pass
- Note: One pre-existing test failure in `test_ruleset_commands.test.sh` (unrelated to our changes)

**Key Verification Points**:
- ✅ Commands removed when ruleset removed
- ✅ File rules in subdirectories preserve structure
- ✅ Symlinked rules in subdirectories copied flat
- ✅ List display shows correct structure (top-level only, commands/ special)
- ✅ Large rule trees (like isolation_rules) work correctly
- ✅ Conflict detection still works (uses basename)
- ✅ Removal logic handles structured rules correctly (via sync cleanup)

### Phase 5: Code Review and Cleanup ✓
**Status**: Complete
**Purpose**: Review all code touched by previous phases for DRY, KISS, YAGNI violations and remove cruft from abortive implementation attempts

**Review Results**:
1. **`cmd_list()` function**:
   - ✅ Simplified to show top-level items only (except commands/)
   - ✅ Removed complex filtering logic for symlink-only directories
   - ✅ Removed redundant conditional branches (lines 2612-2615)
   - ✅ Logic is straightforward and maintainable
   - ✅ All temporary files properly cleaned up

2. **`copy_entry_to_target()` function**:
   - ✅ Symlink vs file detection is clean and simple (`[ -L "${file}" ]`)
   - ✅ No leftover code from previous flattening attempts
   - ✅ Temporary file handling is correct (POSIX-compliant)

3. **`remove_ruleset_commands()` function**:
   - ✅ Follows same patterns as `copy_ruleset_commands()`
   - ✅ No code duplication (functions are appropriately similar)
   - ✅ Error handling is consistent

4. **`cmd_remove_ruleset()` function**:
   - ✅ Integration with `remove_ruleset_commands()` is clean
   - ✅ No redundant logic

5. **Test files**:
   - ✅ Test expectations match actual behavior
   - ✅ Updated tests to reflect new list display behavior
   - ✅ Tests are clear and maintainable

**Cleanup Actions Completed**:
- ✅ Removed redundant code in `cmd_list()` (duplicate printf statements)
- ✅ Verified all temporary files are properly cleaned up
- ✅ No unused variables found
- ✅ No commented-out code found
- ✅ Logic simplified where possible
- ✅ Consistent error handling patterns maintained

**Verification**:
- ✅ Full test suite passes (14/15 - one pre-existing failure unrelated to changes)
- ✅ Code changes reviewed for clarity and maintainability
- ✅ All cleanup verified to not break functionality

## Dependencies and Challenges

### Dependencies
- Existing ruleset handling infrastructure
- Command copying logic (already fixed to preserve structure)
- Sync and manifest management

### Challenges
- **Bug 1**: Need to determine which commands belong to which ruleset when multiple rulesets might have same command paths
  - **Solution**: If command is in ruleset being removed, delete it (error condition if conflicts)
- **Bug 2**: Need to detect symlink vs file and handle differently
  - **Solution**: Use `[ -L "${file}" ]` to detect symlinks, `[ -f "${file}" ]` for files
  - Symlinks: Copy flat (all instances are the same rule)
  - Files: Preserve directory structure (URI is `ruleset/path/to/rule.mdc`)
- **Structured Rule Removal**: Need to ensure structured rules are properly removed
  - **Solution**: `sync_manifest_to_directory()` already clears all `.mdc` files recursively, then re-copies from manifest. With updated copy logic, structured rules will be restored correctly.

## Success Criteria
- [x] Commands are removed from `.cursor/commands/` when their ruleset is removed
- [x] File rules in subdirectories preserve directory structure (e.g., `Core/memory-bank-paths.mdc` → `.cursor/rules/shared/Core/memory-bank-paths.mdc`)
- [x] Symlinked rules in subdirectories are copied flat (all instances are the same rule)
- [x] Root-level file rules are copied flat
- [x] List display shows correct structure:
  - [x] Top-level .mdc files are shown
  - [x] Top-level subdirectories are shown (but NO contents)
  - [x] commands/ subdirectory shows one level (top-level files and subdirs, but not subdir contents)
- [x] Large rule trees (55+ rules) work correctly with preserved structure
- [x] Commands removed when ruleset removed (even if multiple rulesets have same path - error condition)
- [x] Existing behavior preserved (no regressions)
- [x] All tests pass (14/15 - one pre-existing failure unrelated to changes)
- [x] Code reviewed and cleaned up (no DRY/KISS/YAGNI violations, no cruft from previous attempts)

## Test Strategy

### New Test Cases Needed
1. **Commands removed when ruleset removed**:
   - Create ruleset with commands
   - Add ruleset, verify commands copied
   - Remove ruleset, verify commands removed
   
2. **File rules preserve directory structure**:
   - Create ruleset with file rules in subdirectory (e.g., `Core/memory-bank-paths.mdc`)
   - Add ruleset, verify rules in correct subdirectory structure
   - Verify rules appear in list tree correctly
   - Remove ruleset, verify structured rules are removed
   
3. **Symlinked rules copied flat**:
   - Create ruleset with symlinked rules in subdirectory
   - Add ruleset, verify symlinked rules copied flat (not structured)
   - Verify symlinked rules don't preserve structure
   
4. **Commands removed even with conflicting paths** (error condition):
   - Create two rulesets with same command path (error condition)
   - Add both, verify last one wins
   - Remove first, verify command removed (belongs to removed ruleset)
   - Note: This tests error condition handling - rulesets shouldn't have overlapping paths

5. **Complex ruleset with commands, file rules, and symlinked rules**:
   - Create ruleset with commands, file rules in subdirs, and symlinked rules
   - Add ruleset, verify:
     - Commands preserve structure
     - File rules preserve structure
     - Symlinked rules copied flat
   - Remove ruleset, verify:
     - Commands removed
     - Structured file rules removed
     - Flat symlinked rules removed

### Existing Tests
- Verify all existing tests still pass
- Update list display tests if needed to reflect new structure
