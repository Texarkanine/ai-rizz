# Memory Bank: Tasks

## Current Task
Fix 2 bugs in ruleset handling:
1. Removing a ruleset with commands does not remove the commands from `.cursor/commands/`
2. Rules in subdirectories of rulesets are flattened instead of preserving directory structure

## Status
- [x] Task definition
- [ ] Complexity determination
- [ ] Implementation plan
- [ ] Phase 0: Regression tests written (should fail)
- [ ] Phase 1: Fix Bug 1 (remove commands when ruleset removed)
- [ ] Phase 2: Fix Bug 2 (preserve directory structure for rules)
- [ ] Phase 3: Verify all tests pass

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

**Bug 2: Rules in subdirectories are flattened**
- **Issue**: Rules in subdirectories of rulesets (e.g., `supporting/cursor-conversation-transcript.mdc`) are copied flattened to `.cursor/rules/shared/cursor-conversation-transcript.mdc` instead of preserving the directory structure
- **Root Cause Analysis**:
  - In `copy_entry_to_target()`, when copying a ruleset, it uses `find` to find all `.mdc` files recursively
  - The copy command `cp -L "${cett_rule_file}" "${cett_target_directory}/"` flattens everything to the target root
  - Directory structure is not preserved (unlike commands which we fixed to preserve structure)
- **Impact**: 
  - Rules from subdirectories don't show up correctly in the list (they're flattened)
  - Directory structure within rulesets is lost
  - Rules that should be in `supporting/` subdirectory are flattened to root level
- **Expected Behavior**: Rules should preserve their directory structure within the ruleset (e.g., `supporting/cursor-conversation-transcript.mdc` → `.cursor/rules/shared/supporting/cursor-conversation-transcript.mdc`)

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

2. **Test 2: Rules preserve directory structure**
   ```bash
   test_rules_preserve_directory_structure() {
       # Setup: Create ruleset with rules in subdirectory
       mkdir -p "$REPO_DIR/rulesets/test-structure/supporting"
       echo "subdir rule" > "$REPO_DIR/rulesets/test-structure/supporting/subrule.mdc"
       echo "root rule" > "$REPO_DIR/rulesets/test-structure/rootrule.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add ruleset
       cmd_add_ruleset "test-structure" --commit
       assertTrue "Should add ruleset successfully" $?
       
       # Expected: Rules should preserve directory structure
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root rule should be copied"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/subrule.mdc" || fail "Subdirectory rule should preserve structure"
       test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/subrule.mdc" || fail "Subdirectory rule should NOT be flattened"
       # CURRENTLY FAILS: Rules are flattened to root level
   }
   ```

3. **Test 3: Commands removed even if multiple rulesets have same path (error condition)**
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

4. **Test 4: Combined - ruleset with commands and subdirectory rules**
   ```bash
   test_complex_ruleset_structure_preserved() {
       # Setup: Ruleset with commands and rules in subdirectories
       mkdir -p "$REPO_DIR/rulesets/test-complex/commands/subs"
       mkdir -p "$REPO_DIR/rulesets/test-complex/supporting"
       echo "command" > "$REPO_DIR/rulesets/test-complex/commands/top.md"
       echo "nested" > "$REPO_DIR/rulesets/test-complex/commands/subs/nested.md"
       echo "subrule" > "$REPO_DIR/rulesets/test-complex/supporting/subrule.mdc"
       echo "rootrule" > "$REPO_DIR/rulesets/test-complex/rootrule.mdc"
       
       # Commit and initialize
       cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
       cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
       
       # Action: Add ruleset
       cmd_add_ruleset "test-complex" --commit
       assertTrue "Should add ruleset successfully" $?
       
       # Expected: Both structures preserved
       test -f "commands/top.md" || fail "Top command should be copied"
       test -f "commands/subs/nested.md" || fail "Nested command should be copied"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root rule should be copied"
       test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/subrule.mdc" || fail "Subdirectory rule should preserve structure"
       
       # Remove ruleset
       cmd_remove_ruleset "test-complex"
       
       # Expected: Commands removed, rules removed
       test ! -f "commands/top.md" || fail "Commands should be removed"
       test ! -f "commands/subs/nested.md" || fail "Nested commands should be removed"
       # CURRENTLY FAILS: Multiple issues
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

### Phase 2: Fix Bug 2 - Preserve Directory Structure for Rules
**Location**: `copy_entry_to_target()` function (line ~3338)

**Issue**: Rules in subdirectories are flattened to target root

**POSIX Style Requirements** (per `.cursor/rules/shared/shell-posix-style.mdc`):
- Use temporary files instead of subshells when variable scope matters
- Use `mktemp` for temporary files, clean up with `rm -f`
- Use `while IFS= read -r` pattern for reading files
- Avoid subshells that could lose exit codes
- Use function-specific variable prefixes (already established pattern: `cett_` for `copy_entry_to_target`)

**Fix**: Similar to how we fixed command copying, preserve directory structure

**Implementation** (TDD Step 4 - Write Code):
- **After Phase 0 tests are written and verified to fail**, implement fixes:
- **Current code** (line 3341-3354) - uses subshell with pipe:
  ```bash
  find "${cett_source_path}" -name "*.mdc" -type f -o -name "*.mdc" -type l | \
      while IFS= read -r cett_rule_file; do
      # ... subshell loses exit codes ...
  done
  ```

- **New code**: Use temporary file (POSIX-compliant) and preserve structure:
  ```bash
  # Use temporary file to avoid subshell exit code issues (per POSIX style guide)
  cett_temp_file=$(mktemp)
  find "${cett_source_path}" -name "*.mdc" \( -type f -o -type l \) > "${cett_temp_file}" 2>/dev/null
  cett_find_status=$?
  
  if [ ${cett_find_status} -eq 0 ]; then
      while IFS= read -r cett_rule_file; do
          if [ -n "${cett_rule_file}" ] && ([ -f "${cett_rule_file}" ] || [ -L "${cett_rule_file}" ]); then
              # Calculate relative path from ruleset root to preserve structure
              cett_rel_path="${cett_rule_file#${cett_source_path}/}"
              cett_target_file="${cett_target_directory}/${cett_rel_path}"
              
              # Create target directory structure if needed
              cett_target_dir=$(dirname "${cett_target_file}")
              if [ ! -d "${cett_target_dir}" ]; then
                  if ! mkdir -p "${cett_target_dir}"; then
                      warn "Failed to create directory for: ${cett_rel_path}"
                      continue
                  fi
              fi
              
              # Skip if file would conflict with commit mode (commit wins)
              cett_filename=$(basename "${cett_rule_file}")
              if [ "${cett_is_local_sync}" = "true" ] && file_exists_in_commit_mode "${cett_filename}"; then
                  continue  # Skip this file
              fi
              
              # Copy the file (following symlinks to get actual content)
              if ! cp -L "${cett_rule_file}" "${cett_target_file}"; then
                  warn "Failed to copy rule file: ${cett_rel_path}"
              fi
          fi
      done < "${cett_temp_file}"
  fi
  
  rm -f "${cett_temp_file}"
  ```

**Note**: Conflict detection uses basename, which might need adjustment for subdirectories. For now, keep existing conflict logic (it checks by filename, which should still work).

**Additional Consideration**: The `sync_manifest_to_directory()` function clears `.mdc` files with `find "${smtd_target_directory}" -maxdepth 1 -name "*.mdc"` which only clears top-level files. This needs to be updated to clear all `.mdc` files recursively to handle subdirectories.

**Update `sync_manifest_to_directory()`**:
- **Current** (line 3151): `find "${smtd_target_directory}" -maxdepth 1 -name "*.mdc" -type f -delete`
- **New**: `find "${smtd_target_directory}" -name "*.mdc" -type f -delete` (remove `-maxdepth 1`)

### Phase 3: Verify All Tests Pass
**After Phase 1 and 2**: All regression tests should pass
**Actions**:
- Run full test suite: `make test`
- Verify no regressions in existing tests
- Update documentation if behavior changes significantly

## Dependencies and Challenges

### Dependencies
- Existing ruleset handling infrastructure
- Command copying logic (already fixed to preserve structure)
- Sync and manifest management

### Challenges
- **Bug 1**: Need to determine which commands belong to which ruleset when multiple rulesets might have same command paths
  - **Solution**: Check all remaining rulesets before removing a command
- **Bug 2**: Conflict detection uses basename - need to verify it still works with subdirectories
  - **Solution**: Keep existing conflict logic (checks by filename, should work)
- **Sync cleanup**: Need to update `sync_manifest_to_directory()` to clear nested `.mdc` files
  - **Solution**: Remove `-maxdepth 1` from find command

## Success Criteria
- [ ] Commands are removed from `.cursor/commands/` when their ruleset is removed
- [ ] Rules in subdirectories preserve directory structure (e.g., `supporting/cursor-conversation-transcript.mdc` → `.cursor/rules/shared/supporting/cursor-conversation-transcript.mdc`)
- [ ] Rules from subdirectories appear correctly in list output
- [ ] Commands removed when ruleset removed (even if multiple rulesets have same path - error condition)
- [ ] Existing behavior preserved (no regressions)
- [ ] All tests pass

## Test Strategy

### New Test Cases Needed
1. **Commands removed when ruleset removed**:
   - Create ruleset with commands
   - Add ruleset, verify commands copied
   - Remove ruleset, verify commands removed
   
2. **Rules preserve directory structure**:
   - Create ruleset with rules in subdirectory
   - Add ruleset, verify rules in correct subdirectory structure
   - Verify rules appear in list correctly
   
3. **Commands removed even with conflicting paths** (error condition):
   - Create two rulesets with same command path (error condition)
   - Add both, verify last one wins
   - Remove first, verify command removed (belongs to removed ruleset)
   - Note: This tests error condition handling - rulesets shouldn't have overlapping paths

4. **Complex ruleset with commands and subdirectory rules**:
   - Create ruleset with both commands and rules in subdirectories
   - Add ruleset, verify both structures preserved
   - Remove ruleset, verify commands removed and rules removed

### Existing Tests
- Verify all existing tests still pass
- Update list display tests if needed to reflect new structure
